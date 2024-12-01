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

RUN install_vim -tag v7.4.2367 -name vim_7.4.2367 -build
RUN install_vim -tag v8.2.5172 -name vim_8.2.5172 -build
RUN install_vim -tag v9.0.2190 -name v9.0.2190 -build
RUN install_vim -tag v9.1.0786 -name v9.1.0786 -build

# TODO: This one doesn't build - vim-testbed seems way out of date:
# TODO: tag neovim:v0.10.2, name nvim_0.10.2
# (Format as install_vim instances above.)
