FROM tweekmonster/vim-testbed:latest

ENV PACKAGES="\
    bash \
    git \
    python3 \
"
RUN apk --update add $PACKAGES && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

RUN pip3 install --upgrade pip setuptools
RUN pip3 install vim-vint
RUN git clone https://github.com/junegunn/vader.vim vader

RUN install_vim -tag v7.3.429 -name vim_7.3.429 -build \
                -tag v7.4.1099 -name vim_7.4.1099 -build \
                -tag v7.4.1546 -name vim_7.4.1546 -build \
                -tag v8.0.0027 -name vim_8.0.0027 -build \
                -tag v8.1.0519 -name vim_8.1.0519 -build \
                -tag neovim:v0.3.8 -name nvim_0.3.8 -build \
