<<<<<<< HEAD
FROM testbed/vim:latest

# Add packages
RUN apk --no-cache add bash
RUN apk --no-cache add git
RUN apk --no-cache add python3

# Get vint for linting
RUN pip3 install vim-vint

# Get vader for unit tests
=======
FROM testbed/vim:17

# add packages
RUN apk --no-cache add bash=~5.0
RUN apk --no-cache add git=~2.22
RUN apk --no-cache add python3=~3.7

# get vint for linting
RUN pip3 install vim-vint==0.3.21

# get vader for unit tests
>>>>>>> Bump version number – release 2.5
RUN git clone -n https://github.com/junegunn/vader.vim /vader
WORKDIR /vader
RUN git checkout de8a976f1eae2c2b680604205c3e8b5c8882493c

<<<<<<< HEAD
# Build vim and neovim versions we want to test
# TODO add nvim tag
=======
# build vim and neovim versions we want to test
# TODO uncomment nvim tag
>>>>>>> Bump version number – release 2.5
WORKDIR /
RUN install_vim -tag v7.3.429 -name vim_7.3.429 -build \
                -tag v7.4.1099 -name vim_7.4.1099 -build \
                -tag v7.4.1546 -name vim_7.4.1546 -build \
                -tag v8.0.0027 -name vim_8.0.0027 -build \
                -tag v8.1.0519 -name vim_8.1.0519 -build \
<<<<<<< HEAD
+               -tag neovim:v0.2.2 -name nvim_0.2.2 -build \
+               -tag neovim:v0.3.8 -name nvim_0.3.8 -build \
=======
>>>>>>> Bump version number – release 2.5
