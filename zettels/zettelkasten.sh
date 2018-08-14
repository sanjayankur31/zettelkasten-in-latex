#!/bin/bash

MY_EDITOR="vimx --servername $(pwgen 8 1)"
timenow="$(date +%G%m%d%H%M)"
template_file="zettelkasten-template.tex"
note_heading=""
filename=""

add_entry ()
{
    filename="$timenow-$note_heading.tex"
    cp "$template_file" "$filename"

    if [ -n "$TMUX" ]
    then
        echo "Setting tmux buffer for your convenience."
        tmux set-buffer "$zettel"
    else
        echo "Not using a tmux session. Not setting buffer."
    fi

}

edit_latest ()
{
    newest_zettel=$(ls -- *tex | tail -1)
    $MY_EDITOR "$newest_zettel"
}


clean ()
{
    echo "Cleaning up.."
    rm -fv -- *.aux *.bbl *.blg *.log *.nav *.out *.snm *.toc *.dvi *.vrb *.bcf *.run.xml *.cut *.lo* *.brf*
    latexmk -c
}

usage ()
{
    cat << EOF
    usage: $0 options

    Master script file that provides functions to maintain a journal using LaTeX.

    OPTIONS:
    -h  Show this message and quit

    -n  <note heading>
        Add new zettel with note heading

    -e open latest zettel in \$MY_EDITOR

    -c clean temporary latex files

EOF

}

if [ "$#" -eq 0 ]; then
    usage
    exit 0
fi

while getopts "n:hce" OPTION
do
    case $OPTION in
        n)
            note_heading=$OPTARG
            add_entry
            exit 0
            ;;
        c)
            clean
            exit 0
            ;;
        h)
            usage
            exit 0
            ;;
        ?)
            usage
            exit 0
            ;;
    esac
done
