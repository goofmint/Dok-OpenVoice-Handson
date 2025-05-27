FROM continuumio/miniconda3

# conda環境を作る
RUN conda create -n openvoice python=3.9

# activateできるように準備
SHELL ["/bin/bash", "-c"]

# パッケージインストールは conda環境内で行う
RUN echo "conda activate openvoice" >> ~/.bashrc
ENV PATH /opt/conda/envs/openvoice/bin:$PATH

RUN apt-get update && \
	apt-get install -y ffmpeg && \
	mkdir /app /opt/artifact

WORKDIR /app
COPY . .

# ここから conda環境前提でpip実行！
RUN source ~/.bashrc && conda activate openvoice && \
	pip install -e . && \
	pip install argparse boto3 git+https://github.com/myshell-ai/MeloTTS.git && \
	python -m unidic download

RUN chmod +x /app/docker-entrypoint.sh

# Dockerコンテナー起動時に実行するスクリプトを指定して実行
ENTRYPOINT ["/app/docker-entrypoint.sh"]
