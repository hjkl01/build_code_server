FROM gitpod/openvscode-server:latest

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
        make cmake\
        git \
        sudo \
	      wget \
        libatomic1 \
        gcc \
        build-essential \
        lcov valgrind \
        ncdu \
        lsof \
        htop \
        tree \
        zsh tmux fzf zoxide neovim lua5.4 ripgrep \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

# RUN wget https://ghp.ci/https://github.com/neovim/neovim/releases/download/v0.10.2/nvim-linux64.tar.gz -O /tmp/nvim-linux64.tar.gz && \
RUN wget https://github.com/neovim/neovim/releases/download/v0.10.2/nvim-linux64.tar.gz -O /tmp/nvim-linux64.tar.gz && \
    tar xzvf /tmp/nvim-linux64.tar.gz -C /opt/ && \
    rm /tmp/nvim-linux64.tar.gz
RUN ln -s /opt/nvim-linux64/bin/nvim  /usr/local/bin/nvim && \
    ln -s /opt/nvim-linux64/bin/nvim  /usr/local/bin/vim && \
    ln -s /opt/nvim-linux64/bin/nvim  /usr/local/bin/vi

RUN chown -R openvscode-server:openvscode-server -R /home/workspace
USER openvscode-server

# RUN git clone https://ghp.ci/https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1
ENV PATH=/root/.asdf/shims:/root/.asdf/bin:$PATH

RUN echo ". $HOME/.asdf/asdf.sh" >> ~/.bashrc && \
    echo ". $HOME/.asdf/completions/asdf.bash" >> ~/.bashrc
# RUN which asdf
RUN ~/.asdf/bin/asdf plugin add python && \
    ~/.asdf/bin/asdf install python 3.9.19 && \
    ~/.asdf/bin/asdf global python 3.9.19

RUN RUN ln -s ~/.asdf/shims/python /usr/local/bin/python

# RUN ~/.asdf/shims/python -m pip install --no-cache-dir -U pip -i https://mirrors.aliyun.com/pypi/simple/ && \
#     ~/.asdf/shims/python -m pip install --no-cache-dir pylint black -i https://mirrors.aliyun.com/pypi/simple/
RUN ~/.asdf/shims/python -m pip install --no-cache-dir -U pip
    ~/.asdf/shims/python -m pip install --no-cache-dir pylint black

COPY ./requirements.txt /root/requirements.txt
COPY ./odoo_requirements.txt /root/odoo_requirements.txt

# RUN ~/.asdf/shims/python -m pip install --no-cache-dir -r /root/requirements.txt -i https://mirrors.aliyun.com/pypi/simple/
# RUN ~/.asdf/shims/python -m pip install --no-cache-dir -r /root/odoo_requirements.txt -i https://mirrors.aliyun.com/pypi/simple/
RUN ~/.asdf/shims/python -m pip install --no-cache-dir -r /root/requirements.txt
RUN ~/.asdf/shims/python -m pip install --no-cache-dir -r /root/odoo_requirements.txt

RUN git clone https://ghp.ci/https://github.com/hjkl01/dotfiles ~/.dotfiles && \
    cd ~/.dotfiles && cp env .env && bash ./installer.sh link && \
    nvim --headless "+Lazy! sync" +qa
