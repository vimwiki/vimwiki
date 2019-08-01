# Vimwiki Tests

This directory contains a test framework used to automatically test/verify
Vimwiki functionality. It is based on the following tools:

- [vim-testbed](https://github.com/tweekmonster/vim-testbed)
- [Vader](https://github.com/junegunn/vader.vim)
- [Vint](https://github.com/Kuniwak/vint)

## Resources

- [Vim patches](http://ftp.vim.org/pub/vim/patches/)
- Example test cases:
    - [vim-easy-align](https://github.com/junegunn/vim-easy-align/tree/master/test)
    - [vim-plug](https://github.com/junegunn/vim-plug/tree/master/test)
    - [ale](https://github.com/w0rp/ale/tree/master/test)
    - [Other projects](https://github.com/junegunn/vader.vim/wiki/Projects-using-Vader)

## Building Docker Image

To build the Docker image run `docker build -t vimwiki .` from the Vimwiki
repository root (same location as the Dockerfile).

## Running Tests

### Manual Steps

Starting in the test directory run this command:

```sh
docker run -it --rm -v $PWD/../:/testplugin -v $PWD/../test:/home vimwiki vim_7.4.1099 -u test/vimrc -i NONE
```

This will open a vim instance in the docker container and then all tests
can be run with `:Vader test/*` or individual tests can be run.

**Note:** Substitute `vim_7.4.1099` for any of the vim versions in the Dockerfile.

### Automated Tests

The script in the `test/` directory named `run_test.sh` can be used to
automatically run all tests for all installed vim versions. The vim/nvim
versions are parsed from the Dockerfile. This script will also run `Vint` for all
plugin source files. For more information run `./run_tests.sh -h`.

## Known Issues

1. neovim v0.2.x does not work correctly with Vader output from the docker
   container. No test results are printed and an error message saying
   `Vim: Error reading input, exiting...`
    - Probably need to look into this more and determine if the issue is Vader,
      Neovim, or Docker.
