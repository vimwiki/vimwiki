#!/usr/bin/env bash

# credit to https://github.com/w0rp/ale for script ideas and the color vader
# output function.

# Global error return of the script
o_error=0

printHelp() {
    cat << '        EOF' | sed -e 's/^        //'
        Usage: bash run_tests.sh [OPTIONS]

        Runs Vimwiki Vader tests or Vint in a Docker container

        -h (Help) Print help message

        -n (versioN) Specify vim/nvim version to run tests for.
           Multiple versions can be specified by quoting the value and
           separating versions with a space. E.g. -n "vim1 vim2".
           Default is all available versions.

        -f (File) Comma seperated list of tests to run.
           E.g. -o "list_margin,command_toc"

        -l (List) list available versions that can be used with the '-n' option

        -t (Type) Select test type: 'vader', 'vint', or 'all'

        -v (Verbose) Turn on verbose output.

        E.g. bash run_tests.sh -v -t vader -n "vim_7.4.1099 vim_8.1.0519" -f link_creation.vader,issue_markdown.vader
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
    echo "Starting Docker container and Vader tests."

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
    echo "Vader: running files: $res and independantly $ind"

    # Run tests for each specified version
    for v in $vers; do
        echo -e "\nRunning version: $v"
        vim="/vim-build/bin/$v -u test/vimrc -i NONE"
        test_cmd="for VF in ${ind}; do $vim \"+Vader! \$VF\"; done"

        set -o pipefail

        # Run Fast tests
        docker run -a stderr -e VADER_OUTPUT_FILE=/dev/stderr "${flags[@]}" \
          "$v" -u test/vimrc -i NONE "+Vader! ${res}" 2>&1 | vader_filter | vader_color
        o_error=$(( $o_error | $? ))

        # Run Tests that must be run in individual vim instances
        # see README.md for more information
        docker run -a stderr -e VADER_OUTPUT_FILE=/dev/stderr "${flags[@]}" \
          /bin/bash -c "$test_cmd" 2>&1 | vader_filter | vader_color
        o_error=$(( $o_error | $? ))

        set +o pipefail
    done
    return $o_error
}

runVint() {
    echo "Starting Docker container and running Vint."

    docker run -a stdout "${flags[@]}" vint -s .
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
        o_error=1
        echo ""
        echo "!---------Failed tests detected---------!"
        echo "Run with the '-v' flag for verbose output"
        echo ""
    fi
    return $o_error
}

# Say Hi
echo -en "Starting $(basename $0) for VimWiki\n"


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
        echo "Vint: returned $?"
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
