FROM tweekmonster/vim-testbed:latest

ENV PACKAGES="\
    bash \
    git \
    python \
    py-pip \
"
RUN apk --update add $PACKAGES && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

RUN pip install vim-vint
RUN git clone https://github.com/junegunn/vader.vim vader

RUN install_vim -tag v7.4.1099 -build \
                -tag v8.0.0027 -build \
                -tag v8.1.0519 -build
