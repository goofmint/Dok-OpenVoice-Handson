FROM continuumio/miniconda3

ARG CHECKPOINT=checkpoints_v2_0417.zip

ENV CONDA_DEFAULT_ENV=openvoice
ENV PATH=/opt/conda/envs/openvoice/bin:$PATH

# conda環境と依存パッケージのインストール
RUN conda create -n openvoice python=3.9 -y && \
    conda clean -afy && \
    apt-get update && \
    apt-get install -y ffmpeg unar && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /app /opt/artifact

WORKDIR /app
COPY . .

# conda環境内で pip install を実行
RUN pip install -e . && \
    pip install argparse boto3 git+https://github.com/myshell-ai/MeloTTS.git && \
    python -m unidic download && \
    wget https://myshell-public-repo-host.s3.amazonaws.com/openvoice/${CHECKPOINT} && \
    unar ${CHECKPOINT} && \
    rm ${CHECKPOINT} && \
    chmod +x docker-entrypoint.sh

# Dockerコンテナー起動時に実行するスクリプトを指定して実行
ENTRYPOINT ["/app/docker-entrypoint.sh"]
