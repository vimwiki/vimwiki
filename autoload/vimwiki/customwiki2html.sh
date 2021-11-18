#!/usr/bin/env bash

#
# This script converts markdown into html, to be used with vimwiki's
# "customwiki2html" option.  Experiment with the two proposed methods by
# commenting / uncommenting the relevant lines below.
#
#   NEW!  An alternative converter was developed by Jason6Anderson, and can
#   be located at https://github.com/vimwiki-backup/vimwiki/issues/384
#
#
# To use this script, you must have the Discount converter installed.
#
#   http://www.pell.portland.or.us/~orc/Code/discount/
#
# To verify your installation, check that the commands markdown and mkd2html,
# are on your path.
#
# Also verify that this file is executable.
#
# Then, in your .vimrc file, set:
#
#   g:vimwiki_custom_wiki2html=$HOME.'/.vim/autoload/vimwiki/customwiki2html.sh'
#
# On your next restart, Vimwiki will run this script instead of using the
# internal wiki2html converter.
#

MKD2HTML=mkd2html


# shellcheck disable=SC2034  # FORCE appears unused
FORCE="$1"
SYNTAX="$2"
EXTENSION="$3"
OUTPUTDIR="$4"
INPUT="$5"
CSSFILE="$6"


[[ "$SYNTAX" == "markdown" ]] || { echo "Error: Unsupported syntax"; exit 2; };

OUTPUT="$OUTPUTDIR/$(basename "$INPUT" ."$EXTENSION").html"

# # Method 1:
# FORCEFLAG=
# (( "$FORCE" == 0 )) || { FORCEFLAG="-f"; };
# MARKDOWN=markdown
#
# # markdown [-d] [-T] [-V] [-b url-base] [-C prefix] [-F bitmap] [-f flags] [-o file] [-s text] [-t text] [textfile]
#
# URLBASE=http://example.com
# $MARKDOWN -T -b $URLBASE -o $OUTPUT  $INPUT


# Method 2:
# mkd2html [-css file] [-header string] [-footer string] [file]

$MKD2HTML -css "$CSSFILE" "$INPUT"
OUTPUTTMP=$(dirname "$INPUT")/$(basename "$INPUT" ."$EXTENSION").html
mv -f "$OUTPUTTMP" "$OUTPUT"
