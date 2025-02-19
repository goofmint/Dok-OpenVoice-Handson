FROM continuumio/miniconda3

# conda create
RUN conda create -n openvoice python==3.9
SHELL ["conda", "run", "-n", "openvoice", "/bin/bash", "-c"]
# RUN conda activate openvoice
RUN apt-get update && \
    apt-get install -y ffmpeg && \
    mkdir /app /opt/artifact
# install conda package

WORKDIR /app
COPY . .
RUN pip install -e . && \
  pip install argparse && \
  pip install boto3 && \
  pip install git+https://github.com/myshell-ai/MeloTTS.git && \
  python -m unidic download

RUN chmod +x /app/docker-entrypoint.sh

# Dockerコンテナー起動時に実行するスクリプトを指定して実行
CMD ["/bin/bash", "/app/docker-entrypoint.sh"]
