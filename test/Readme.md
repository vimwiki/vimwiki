# Vimwiki Tests

This directory contains a test framework used to automatically test/verify
Vimwiki functionality. It is based on the following tools:

- [vim-testbed](https://github.com/tweekmonster/vim-testbed)
- [Vader](https://github.com/junegunn/vader.vim)

## Resources

- [Vim patches](http://ftp.vim.org/pub/vim/patches/)
- Example test cases:
    - [vim-easy-align](https://github.com/junegunn/vim-easy-align/tree/master/test)
    - [vim-plug](https://github.com/junegunn/vim-plug/tree/master/test)
    - [ale](https://github.com/w0rp/ale/tree/master/test)
    - [Other projects](https://github.com/junegunn/vader.vim/wiki/Projects-using-Vader)

## Manual Steps

To build the Docker image run `docker build -t vimwiki` from the Vimwiki
repository root (same location as the Dockerfile).

To start the tests run `docker run -it --rm -v $PWD:/testplugin -v $PWD/test:/home vimwiki vim-v7.4.1099 -u test/vimrc -i NONE '+Vader! test/*'`
also from the repository root.

    - Substitute `vim-v7.4.1099` for any of the vim versions in the Dockerfile.
