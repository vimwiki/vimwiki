FROM testbed/vim:latest

# Add packages
RUN apk --no-cache add bash
RUN apk --no-cache add git
RUN apk --no-cache add python3
RUN apk --no-cache add py3-pip

# Get vint for linting
RUN pip3 install vim-vint

# Get vader for unit tests
RUN git clone -n https://github.com/junegunn/vader.vim /vader
WORKDIR /vader
RUN git checkout de8a976f1eae2c2b680604205c3e8b5c8882493c

# Build vim and neovim versions we want to test
WORKDIR /

RUN install_vim -tag v7.3.429 -name vim_7.3.429 -build
RUN install_vim -tag v7.4.1099 -name vim_7.4.1099 -build
RUN install_vim -tag v7.4.1546 -name vim_7.4.1546 -build
RUN install_vim -tag v8.0.0027 -name vim_8.0.0027 -build
RUN install_vim -tag v8.1.0519 -name vim_8.1.0519 -build
RUN install_vim -tag v9.0.1396 -name v9.0.1396 -build
RUN install_vim -tag neovim:v0.3.8 -name nvim_0.3.8 -build
