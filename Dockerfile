FROM python:3.9.19-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        sudo \
	      wget \
        libatomic1 \
        gcc \
        nodejs \
        build-essential \
        libldap2-dev libsasl2-dev slapd ldap-utils tox \
        lcov valgrind \
        curl tree htop ncdu zsh tmux fzf zoxide lua5.4 ripgrep lsof \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*


RUN wget https://github.com/neovim/neovim/releases/download/v0.10.2/nvim-linux64.tar.gz -O /tmp/nvim-linux64.tar.gz && \
    tar xzvf /tmp/nvim-linux64.tar.gz -C /opt/ && \
    ln -s /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim

RUN git clone https://github.com/hjkl01/dotfiles ~/.dotfiles && cd ~/.dotfiles && cp env .env &&  \
    sed -i 's/execute_function InstallNeovim//g' installer.sh \
    && sed -i 's/execute_function Installasdf//g' installer.sh \
    && bash ./installer.sh

RUN ln -s ~/.dotfiles/nvim ~/.config/nvim
RUN nvim --headless "+Lazy! sync" +qa
RUN nvim --headless "+Mason! sync" +qa
RUN nvim --headless "+MasonInstallAll! sync" +qa

RUN pip install -U pip && \
    pip install pylint black neovim

COPY ./requirements.txt /root/requirements.txt
COPY ./odoo_requirements.txt /root/odoo_requirements.txt

RUN pip install -r /root/requirements.txt
RUN pip install -r /root/odoo_requirements.txt


WORKDIR /home/

ARG RELEASE_TAG='openvscode-server-v1.95.2'
ARG RELEASE_ORG="gitpod-io"
ARG OPENVSCODE_SERVER_ROOT="/home/.openvscode-server"

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

WORKDIR /root/

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    EDITOR=code \
    VISUAL=code \
    GIT_EDITOR="code --wait" \
    OPENVSCODE_SERVER_ROOT=${OPENVSCODE_SERVER_ROOT}

RUN /home/.openvscode-server/bin/remote-cli/code --install-extension ms-python.python
RUN /home/.openvscode-server/bin/remote-cli/code --install-extension esbenp.prettier-vscode
RUN /home/.openvscode-server/bin/remote-cli/code --install-extension eamodio.gitlens
RUN /home/.openvscode-server/bin/remote-cli/code --install-extension asvetliakov.vscode-neovim
RUN /home/.openvscode-server/bin/remote-cli/code --install-extension llam4u.nerdtree

# Default exposed port if none is specified
EXPOSE 3000

ENTRYPOINT [ "/bin/sh", "-c", "exec ${OPENVSCODE_SERVER_ROOT}/bin/openvscode-server --host 0.0.0.0 --without-connection-token \"${@}\"", "--" ]
