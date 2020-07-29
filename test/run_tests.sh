#!/usr/bin/env bash

# credit to https://github.com/w0rp/ale for script ideas and the color vader
# output function.

# Say Hi
echo -en "Starting $(basename $0) for VimWiki\n"

# For windows: Cmder bash is appending busybox to the path and
#   and a smlll vim is included, so that override the windows path vim
if [[ -v OLD_PATH ]]; then
    echo "Setting path from OLD_PATH : $OLD_PATH"
    export PATH="$OLD_PATH"
fi

printHelp() {
    cat << '        EOF' | sed -e 's/^        //'
        Usage: bash run_tests.sh [OPTIONS]

        Runs Vimwiki Vader tests or Vint in a Docker container

        -h (Help) Print help message

        -n (versioN) Specify vim/nvim version to run tests for.
           Specify "local" to run on your current vim install
           for example on Windows.
           Multiple versions can be specified by quoting the value and
           separating versions with a space. E.g. -n "vim1 vim2".
           Default is all available versions.

        -f (File) Comma seperated list of tests to run.
           E.g. -o "list_margin,command_toc"

        -l (List) list available versions that can be used with the '-n' option

        -t (Type) Select test type: 'vader', 'vint', or 'all'

        -v (Verbose) Turn on verbose output.

        E.g. On Linux
        bash run_tests.sh -v -t vader -n "vim_7.4.1099 vim_8.1.0519" -f link_creation.vader,issue_markdown.vader
        E.g. On Windows
        bash run_tests.sh -v -t vader -n local -f z_success.vader | cat
        EOF

    exit 0
}

printVersions() {
    # Print the names of all vim/nvim versions
    getVers
    exit 0
}

runVader() {
    # Run Vader tests
    echo -e "\nStarting Vader tests."
    local err=0

    # Parse tests files to execute
    if [[ -z $file_test ]]; then
       ind="test/independent_runs/*.vader" 
       res="test/*"
    else
        IFS=',' read -ra TEST <<< "$file_test"
        for i in "${TEST[@]}"; do
            if [[ -f "$i" ]]; then
                res="$res test/${i}"
            elif [[ -f "${i}.vader" ]]; then
                res="$res test/${i}.vader"
            elif [[ -f "independent_runs/${i}" ]]; then
                ind="$ind test/independent_runs/${i}"
            elif [[ -f "independent_runs/${i}.vader" ]]; then
                ind="$ind test/independent_runs/${i}.vader"
            else
                printf "WARNING: Test \"%s\" not found.\n", "$i"
            fi
        done
    fi
    echo "Vader: will run files: $res and independently $ind"

    # Run tests for each specified version
    for v in $vers; do
        echo -e "\nRunning version: $v"

        # Set local environment variables
        if [[ "$v" == "local" ]]; then
            # Save HOME var
            home_save="$HOME"

            # Create temporary root
            mkdir -p $tmp_dir/vader_wiki
            mkdir -p $tmp_dir/vader_wiki/home
            mkdir -p $tmp_dir/vader_wiki/home/test
            mkdir -p $tmp_dir/vader_wiki/testplugin

            # Set vars
            export ROOT="$tmp_dir/vader_wiki/"
            export HOME="$tmp_dir/vader_wiki/home"
            vim="vim"
            vim_opt="-u ~/test/vimrc -i NONE"
        else
            # Only set dockerized vars
            export ROOT="/"  # So no if in vimrc
            vim="/vim-build/bin/$v"
            vim_opt="-u test/vimrc -i NONE"
        fi

        set -o pipefail

        # Copy the resources to temporary directory
        if [[ "$v" == "local" ]]; then
            # flags=(--rm -v "$PWD/../:/testplugin" -v "$PWD/../test:/home" -w /testplugin vimwiki)
            echo -e "\nCopying resources to $ROOT"
            # Copy testplugin
            cp -rf $wiki_path/* $ROOT/testplugin/
            # Copy home
            cp -rf $script_path/* $HOME/test/
            # Copy rtp.vim
            cp -rf $script_path/resources/rtp_local.vim $ROOT/rtp.vim
            # Copy vader <- internet
            echo 'Cloning Vader (git, do not care the fatal)'
            git clone --depth 10 https://github.com/junegunn/vader.vim /tmp/vader_wiki/vader 2>&1
        fi

        # Run batch of tests
        if [[ "$v" == "local" ]]; then
            pushd $tmp_dir/vader_wiki/testplugin

            # Run the tests
            echo -e "\nStarting vim with Vader"
            "$vim" $vim_opt "+Vader! ${res}" 2>&1
            err=$(( $err | $? ))

            popd
        else  # In docker
            echo -e "\nStarting docker with vim with Vader"
            docker run -a stderr -e VADER_OUTPUT_FILE=/dev/stderr "${flags[@]}" \
              "$v" $vim_opt "+Vader! ${res}" 2>&1 | vader_filter | vader_color
            err=$(( $err | $? ))
        fi

        # Run Tests that must be run in individual vim instances
        # see README.md for more information
        test_cmd="for VF in ${ind}; do $vim $vim_opt \"+Vader! \$VF\"; done"
        if [[ "$v" == "local" ]]; then
            pushd $tmp_dir/vader_wiki/testplugin

            echo "Starting vim with Vader"
            bash -c "$test_cmd" 2>&1
            err=$(( $err | $? ))

            popd
        else  # In docker
            echo "Starting docker with vim with Vader"
            docker run -a stderr -e VADER_OUTPUT_FILE=/dev/stderr "${flags[@]}" \
              /bin/bash -c "$test_cmd" 2>&1 | vader_filter | vader_color
            err=$(( $err | $? ))
        fi

        set +o pipefail

        # Restore what must (I know it should be refactored in a while)
        if [[ "$v" == "local" ]]; then
            export HOME=$home_save
        fi
    done
    return $err
}

runVint() {
    local err=0
    cmd="vint -s . && vint -s test/vimrc"
    if echo "$vers" | grep "local" > /dev/null; then
        echo -e "\nRunning Vint: $cmd : in $wiki_path"
        pushd $wiki_path > /dev/null
        $cmd
        err=$(( $err | $? ))
        popd > /dev/null
    else
        echo -e "\nStarting Docker container and running Vint: $cmd"
        docker run -a stdout "${flags[@]}" bash -c "$cmd"
        err=$(( $err | $? ))
    fi
    return $err
}

getVers() {
    sed -n 's/.* -name \([^ ]*\) .*/\1/p' ../Dockerfile
}

vader_filter() {
    # Filter Vader Stdout
    local err=0
    while read -r; do
        # Print only possible error cases
        if [[ "$verbose" == 0 ]]; then
            if [[ "$REPLY" = *'docker:'* ]] || \
               [[ "$REPLY" = *'Starting Vader:'* ]] || \
               [[ "$REPLY" = *'Vader error:'* ]] || \
               [[ "$REPLY" = *'Vim: Error '* ]]; then
                echo "$REPLY"
            elif [[ "$REPLY" = *'[EXECUTE] (X)'* ]] || \
                [[ "$REPLY" = *'[ EXPECT] (X)'* ]]; then
                echo "$REPLY"
                err=1
            elif [[ "$REPLY" = *'Success/Total:'* ]]; then
                success="$(echo -n "$REPLY" | grep -o '[0-9]\+/' | head -n1 | cut -d/ -f1)"
                total="$(echo -n "$REPLY" | grep -o '/[0-9]\+' | head -n1 | cut -d/ -f2)"
                if [ "$success" -lt "$total" ]; then
                    err=1
                fi
                echo "$REPLY"
            fi
        else
            # just print everything
            echo "$REPLY"
        fi
    done

    if [[ "$err" == 1 ]]; then
        echo ""
        echo "!---------Failed tests detected---------!"
        echo "Run with the '-v' flag for verbose output"
        echo ""
    fi
    return $err
}


red='\033[0;31m'
green='\033[0;32m'
nc='\033[0m'
vader_color() {
    while read -r; do
        if [[ "$REPLY" = *'[EXECUTE] (X)'* ]] || \
            [[ "$REPLY" = *'[ EXPECT] (X)'* ]] || \
            [[ "$REPLY" = *'Vim: Error '* ]] || \
            [[ "$REPLY" = *'Vader error:'* ]]; then
            echo -en "$red"
        elif [[ "$REPLY" = *'[EXECUTE]'* ]] || [[ "$REPLY" = *'[  GIVEN]'* ]]; then
            echo -en "$nc"
        fi

        if [[ "$REPLY" = *'Success/Total'* ]]; then
            success="$(echo -n "$REPLY" | grep -o '[0-9]\+/' | head -n1 | cut -d/ -f1)"
            total="$(echo -n "$REPLY" | grep -o '/[0-9]\+' | head -n1 | cut -d/ -f2)"

            if [ "$success" -lt "$total" ]; then
                echo -en "$red"
            else
                echo -en "$green"
            fi

            echo "$REPLY"
            echo -en "$nc"
        else
            echo "$REPLY"
        fi
    done

    echo -en "$nc"
}

# path of the script, supposing no spaces
script_file="$(dirname $0)"
script_path="$( realpath $script_file )"
wiki_path="$( realpath $script_path/.. )"
tmp_dir=$(dirname $(mktemp -u))

# list of vim/nvim versions
vers="$(getVers)"

# type of tests to run - vader/vint/all
type="all"

# verbose output flag
verbose=0

# only run these tests
file_test=""

# docker flags
flags=(--rm -v "$PWD/../:/testplugin" -v "$PWD/../test:/home" -w /testplugin vimwiki)

while getopts ":hvn:lt:f:" opt; do
    case ${opt} in
        h )
            printHelp
            ;;
        n )
            vers="$OPTARG"
            ;;
        v )
            verbose=1
            ;;
        l )
            printVersions
            ;;
        t )
            type="$OPTARG"
            ;;
        f )
            file_test="$OPTARG"
            ;;
        \? )
            echo "Invalid option: $OPTARG" 1>&2
            exit 1
            ;;
        : )
            echo "Invalid option: $OPTARG requires an argument" 1>&2
            exit 1
            ;;
    esac
done

# shift out processed parameters
shift $((OPTIND -1))

# error handling for non-option arguments
if [[ $# -ne 0 ]]; then
    echo "Error: Got $# non-option arguments." 1>&2
    exit 1
fi

# stop tests on ctrl-c or ctrl-z
trap exit 1 SIGINT SIGTERM

# Global error return of the script
o_error=0

# select which tests should run
case $type in
    "vader" )
        runVader ; err=$?
        echo "Vader: returned $err"
        o_error=$(( $err | $o_error ))
        ;;
    "vint" )
        runVint ; err=$?
        echo "Vint: returned $err"
        o_error=$(( $err | $o_error ))
        ;;
    "all" )
        runVint ; err=$?
        echo "Vint: returned $err"
        o_error=$(( $err | $o_error ))
        runVader ; err=$?
        echo "Vader: returned $err"
        o_error=$(( $err | $o_error ))
        ;;
    * )
        echo "Error: invalid type - '$type'" 1>&2
        exit 1
esac

# Exit
echo "Script $(basename $0) exiting: $o_error"
exit $o_error
