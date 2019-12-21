# Vimwiki Tests

This directory contains a test framework used to automatically test/verify
Vimwiki functionality. It is based on the following tools:

- [vim-testbed GitHub](https://github.com/tweekmonster/vim-testbed) or on [testbed/vim dockerhub](https://hub.docker.com/r/testbed/vim)
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

## Inside the container

- `$USER` -> `vimtest` : unprivileged => very hard to mess up things
- `$HOME` -> `/home/vimtest` : but it is readonly !
- `$PWD` -> `/testplugin` : mapped to vimwiki plugin root directory

For more information, read the [base docker image](https://github.com/tweekmonster/vim-testbed)

## Known Issues

1. neovim v0.2.x does not work correctly with Vader output from the docker
   container. No test results are printed and an error message saying
   `Vim: Error reading input, exiting...`
    - Probably need to look into this more and determine if the issue is Vader,
      Neovim, or Docker.
2. Vader does not play nice with the location list. Tests that use the location
   list should be placed in `independent_runs/`.
    - [Vader Issue #199](https://github.com/junegunn/vader.vim/issues/199)

## Notable Vim patches

- `v7.3.831` `getbufvar` added a default value
- `v7.4.236` add ability to check patch with has("patch-7.4.123")
- `v7.4.279` added the option to for `globpath()` to return a list
- `v7.4.1546` sticky type checking removed (allow a variables type to change)
- `v7.4.1989` `filter()` accepts a Funcref
- `v7.4.2044` lambda support added - see `:h expr-lambda`
- `v7.4.2120` Added function "closure" argument
- `v7.4.2137` add `funcref()`
- `v8.0` async jobs and timers
