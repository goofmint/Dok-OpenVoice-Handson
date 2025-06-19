#!/bin/bash
 
set -ue
shopt -s nullglob

export TZ=${TZ:-Asia/Tokyo}

# アウトプット先ディレクトリ（自動付与）
if [ -z "${SAKURA_ARTIFACT_DIR:-}" ]; then
	echo "Environment variable SAKURA_ARTIFACT_DIR is not set" >&2
	exit 1
fi

# DOKのタスクID（自動付与）
if [ -z "${SAKURA_TASK_ID:-}" ]; then
	echo "Environment variable SAKURA_TASK_ID is not set" >&2
	exit 1
fi

# 読み上げるテキスト
if [ -z "${TEXT:-}" ]; then
	TEXT="Hello, I am John Doe. This is an example voice."
fi

# 言語
if [ -z "${LANG:-}" ]; then
	LANG="EN"
fi

# リファレンスの音声
LOCAL_REFERENCE="/tmp/reference.mp3"
if [ -z "${REFERENCE:-}" ]; then
	# 指定がなければデフォルトの音声
	cp "resources/example_reference.mp3" "${LOCAL_REFERENCE}"
elif [[ "${REFERENCE}" =~ ^https://drive\.google\.com/file/d/([^/]+) ]]; then
	# Google Driveの共有リンクなら、直接ダウンロードできるURLに変換
	FILE_ID="${BASH_REMATCH[1]}"
	wget "https://drive.usercontent.google.com/download?export=download&id=${FILE_ID}" -O "${LOCAL_REFERENCE}"
else
	# それ以外なら普通にダウンロード
	wget "${REFERENCE}" -O "${LOCAL_REFERENCE}"
fi

echo "TEXT: ${TEXT}"
echo "LANG: ${LANG}"
echo "REFERENCE: ${LOCAL_REFERENCE}"

cd /app
conda run -n openvoice python3 runner.py \
	--id="${SAKURA_TASK_ID}" \
	--output="${SAKURA_ARTIFACT_DIR}" \
	--text="${TEXT}" \
	--lang="${LANG}" \
	--reference="${LOCAL_REFERENCE}" \
	--s3-bucket="${S3_BUCKET:-}" \
	--s3-endpoint="${S3_ENDPOINT:-}" \
	--s3-secret="${S3_SECRET:-}" \
	--s3-token="${S3_TOKEN:-}"
