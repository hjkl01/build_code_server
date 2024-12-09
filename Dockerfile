FROM python:3.9.20

# RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        sudo \
	      wget \
        libatomic1 \
        gcc \
        build-essential \
        libldap2-dev libsasl2-dev slapd ldap-utils tox \
        lcov valgrind \
        ncdu \
        lsof \
        htop \
        tree \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

RUN wget https://github.com/neovim/neovim/releases/download/v0.10.2/nvim-linux64.tar.gz -O /tmp/nvim-linux64.tar.gz && \
    tar xzvf /tmp/nvim-linux64.tar.gz -C /opt/ && \
    rm /tmp/nvim-linux64.tar.gz
RUN ln -s /opt/nvim-linux64/bin/nvim  /usr/local/bin/nvim && \
    ln -s /opt/nvim-linux64/bin/nvim  /usr/local/bin/vim && \
    ln -s /opt/nvim-linux64/bin/nvim  /usr/local/bin/vi && \
    nvim --headless "+Lazy! sync" +qa

RUN pip install --no-cache-dir -U pip && \
    pip install --no-cache-dir pylint black

COPY ./requirements.txt /root/requirements.txt
COPY ./odoo_requirements.txt /root/odoo_requirements.txt

RUN pip install --no-cache-dir -r /root/requirements.txt
RUN pip install --no-cache-dir -r /root/odoo_requirements.txt

# set version label
ARG BUILD_DATE='241209'
ARG VERSION='4.95.3'
ARG CODE_RELEASE='4.95.3'
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV HOME="/config"

RUN \
  echo "**** install runtime dependencies ****" && \
  apt-get update && \
  apt-get install -y \
    git \
    libatomic1 \
    nano \
    net-tools \
    sudo && \
  echo "**** install code-server ****" && \
  if [ -z ${CODE_RELEASE+x} ]; then \
    CODE_RELEASE=$(curl -sX GET https://api.github.com/repos/coder/code-server/releases/latest \
      | awk '/tag_name/{print $4;exit}' FS='[""]' | sed 's|^v||'); \
  fi && \
  mkdir -p /app/code-server && \
  curl -o \
    /tmp/code-server.tar.gz -L \
    "https://github.com/coder/code-server/releases/download/v${CODE_RELEASE}/code-server-${CODE_RELEASE}-linux-amd64.tar.gz" && \
  tar xf /tmp/code-server.tar.gz -C \
    /app/code-server --strip-components=1 && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** clean up ****" && \
  apt-get clean && \
  rm -rf \
    /config/* \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# add local files
COPY /root /

# ports and volumes
EXPOSE 8443
