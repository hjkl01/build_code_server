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
    ln -s /opt/nvim-linux64/bin/nvim  /usr/local/bin/vi

RUN pip install -U pip && \
    pip install pylint black

COPY ./requirements.txt /root/requirements.txt
COPY ./odoo_requirements.txt /root/odoo_requirements.txt

RUN pip install -r /root/requirements.txt
RUN pip install -r /root/odoo_requirements.txt

WORKDIR /home/

ARG RELEASE_TAG="openvscode-server-v1.95.2"
ARG RELEASE_ORG="gitpod-io"
ARG OPENVSCODE_SERVER_ROOT="/home/coder"

# Downloading the latest VSC Server release and extracting the release archive
# Rename `openvscode-server` cli tool to `code` for convenience
RUN if [ -z "${RELEASE_TAG}" ]; then \
        echo "The RELEASE_TAG build arg must be set." >&2 && \
        exit 1; \
    fi && \
    arch=$(uname -m) && \
    if [ "${arch}" = "x86_64" ]; then \
        arch="x64"; \
    elif [ "${arch}" = "aarch64" ]; then \
        arch="arm64"; \
    elif [ "${arch}" = "armv7l" ]; then \
        arch="armhf"; \
    fi && \
    wget https://github.com/${RELEASE_ORG}/openvscode-server/releases/download/${RELEASE_TAG}/${RELEASE_TAG}-linux-${arch}.tar.gz && \
    tar -xzf ${RELEASE_TAG}-linux-${arch}.tar.gz && \
    mv -f ${RELEASE_TAG}-linux-${arch} ${OPENVSCODE_SERVER_ROOT} && \
    cp ${OPENVSCODE_SERVER_ROOT}/bin/remote-cli/openvscode-server ${OPENVSCODE_SERVER_ROOT}/bin/remote-cli/code && \
    rm -f ${RELEASE_TAG}-linux-${arch}.tar.gz

ARG USERNAME=coder
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Creating the user and usergroup
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USERNAME -m -s /bin/bash $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

RUN chmod g+rw /home && \
    mkdir -p /home/coder && \
    chown -R $USERNAME:$USERNAME /home/coder && \
    chown -R $USERNAME:$USERNAME ${OPENVSCODE_SERVER_ROOT}

USER $USERNAME

WORKDIR /home/coder/

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    HOME=/home/coder \
    EDITOR=code \
    VISUAL=code \
    GIT_EDITOR="code --wait" \
    OPENVSCODE_SERVER_ROOT=${OPENVSCODE_SERVER_ROOT}

# Default exposed port if none is specified
EXPOSE 3000

ENTRYPOINT [ "/bin/sh", "-c", "exec ${OPENVSCODE_SERVER_ROOT}/bin/openvscode-server --host 0.0.0.0 --without-connection-token \"${@}\"", "--" ]
