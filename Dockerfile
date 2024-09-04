FROM gitpod/openvscode-server

RUN add-apt-repository ppa:deadsnakes/ppa -y && \
apt update -y && \
apt install python3.8 python3.8-dev python3.8-venv -y

RUN pip install black neovim
# CMD ["python3"]


# ports and volumes
EXPOSE 3000
