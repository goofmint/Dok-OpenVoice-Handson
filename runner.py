import os
import torch
from openvoice import se_extractor
from openvoice.api import ToneColorConverter
import argparse
import nltk
import boto3

nltk.download('averaged_perceptron_tagger_eng')

arg_parser = argparse.ArgumentParser()

arg_parser.add_argument(
    '--output',
    default='/opt/artifact',
    help='出力先ディレクトリを指定します。',
)
arg_parser.add_argument(
    '--text',
    default='',
    help='読み上げる文章',
)
arg_parser.add_argument(
    '--id',
    default='',
    help='タスクIDを指定します。',
)
arg_parser.add_argument(
    '--lang',
    default='JP',
    help='読み上げる言語を指定',
)
arg_parser.add_argument(
    '--reference',
    default='resources/example_reference.mp3',
    help='リファレンスの音声',
)

arg_parser.add_argument('--s3-bucket', help='S3のバケットを指定します。')
arg_parser.add_argument('--s3-endpoint', help='S3互換エンドポイントのURLを指定します。')
arg_parser.add_argument('--s3-secret', help='S3のシークレットアクセスキーを指定します。')
arg_parser.add_argument('--s3-token', help='S3のアクセスキーIDを指定します。')

args = arg_parser.parse_args()

s3 = None
if args.s3_token and args.s3_secret and args.s3_bucket:
    # S3クライアントの作成
    s3 = boto3.client(
        's3',
        endpoint_url=args.s3_endpoint if args.s3_endpoint else None,
        aws_access_key_id=args.s3_token,
        aws_secret_access_key=args.s3_secret)

ckpt_converter = 'checkpoints_v2/converter'
device = "cuda:0" if torch.cuda.is_available() else "cpu"
output_dir = args.output

tone_color_converter = ToneColorConverter(f'{ckpt_converter}/config.json', device=device)
tone_color_converter.load_ckpt(f'{ckpt_converter}/checkpoint.pth')

os.makedirs(output_dir, exist_ok=True)

reference_speaker = args.reference
target_se, audio_name = se_extractor.get_se(reference_speaker, tone_color_converter, vad=True)

from melo.api import TTS

src_path = f'{output_dir}/tmp.wav'

speed = 1.0

model = TTS(language=args.lang, device=device)
speaker_ids = model.hps.data.spk2id

for speaker_key in speaker_ids.keys():
    speaker_id = speaker_ids[speaker_key]
    speaker_key = speaker_key.lower().replace('_', '-')
    source_se = torch.load(f'checkpoints_v2/base_speakers/ses/{speaker_key}.pth', map_location=device)
    model.tts_to_file(args.text, speaker_id, src_path, speed=speed)
    save_path = f'{args.output}/{args.id}_{speaker_key}.wav'
    # Run the tone color converter
    encode_message = "@MyShell"
    tone_color_converter.convert(
        audio_src_path=src_path, 
        src_se=source_se, 
        tgt_se=target_se, 
        output_path=save_path,
        message=encode_message)
    if s3 is not None:
        s3.upload_file(
            Filename=save_path,
            Bucket=args.s3_bucket,
            Key=os.path.basename(save_path))
