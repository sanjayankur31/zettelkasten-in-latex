#!/bin/bash

MY_EDITOR="vimx --servername $(pwgen 8 1)"
timenow="$(date +%G%m%d%H%M)"
template_file="zettelkasten-template.tex"
note_heading=""
filename=""
entry_to_compile=""

add_entry ()
{
    filename="$timenow-$note_heading.tex"
    cp "$template_file" "$filename"

    echo "Created $filename"

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
    newest_zettel=$(ls -- 2*tex | tail -1)
    $MY_EDITOR "$newest_zettel"
}

compile_all ()
{
    echo "Compiling all entries."
    for i in "*.tex" ; do
      if ! latexmk -pdf -recorder -pdflatex="pdflatex -interaction=nonstopmode --shell-escape -synctex=1" -use-make -bibtex "$i"; then
            echo "Compilation failed. Exiting."
            clean
            exit -1
        fi
      clean
    done
}

clean ()
{
    echo "Cleaning up.."
    rm -fv -- *.aux *.bbl *.blg *.log *.nav *.out *.snm *.toc *.dvi *.vrb *.bcf *.run.xml *.cut *.lo* *.brf*
    latexmk -c
}

compile_specific ()
{
    echo "Compiling $entry_to_compile"
    if ! latexmk -pdf -recorder -pdflatex="pdflatex -interaction=nonstopmode --shell-escape -synctex=1" -use-make -bibtex "$entry_to_compile"; then
        echo "Compilation failed. Exiting."
        clean
        exit -1
    fi
    clean
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

    -p compile all entries

    -s <entry> entry to compile

EOF

}

if [ "$#" -eq 0 ]; then
    usage
    exit 0
fi

while getopts "s:n:hcep" OPTION
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
        e)
            edit_latest
            exit 0
            ;;
        p)
            compile_all
            exit 0
            ;;
        s)
            entry_to_compile=$OPTARG
            compile_specific
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
