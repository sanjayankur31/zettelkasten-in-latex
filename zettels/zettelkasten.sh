#!/bin/bash

MY_EDITOR="vimx --servername $(pwgen 8 1)"
timenow="$(date +%G%m%d%H%M)"
template_file="zettelkasten-template.tex"
note_title=""
filename=""
entry_to_compile=""
kw_regex_to_search=""

add_entry ()
{
    filename="$timenow-$note_title.tex"
    cp "$template_file" "$filename"

    echo "Created $filename"

    if [ -n "$TMUX" ]
    then
        echo "Setting tmux buffer for your convenience."
        tmux set-buffer "$filename"
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
    echo "Compiling all entries. This may take a while."
    sleep 2
    for i in *.tex ; do
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
    rm -fr _minted*
    rm -fr *.synctex.gz
    latexmk -c
}

find_keywords()
{
    regex="Keywords:.*$kw_regex_to_search"
    if command -v ag >/dev/null 2>&1; then
        ag -i --tex "$regex"
    else
        echo "ag not found. Falling back on to grep"
        grep -Ei "$regex" -- *.tex
    fi

}

compile_specific ()
{
    if  [ ! -f  "$entry_to_compile" ];
    then
        echo "File $entry_to_compile could not be found."
        exit -1
    fi

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

    Helper script that provides functions to maintain a zettelkasten using LaTeX.

    OPTIONS:
    -h  Show this message and quit

    -n  <note title>
        Create new zettel file with note title

        Please avoid spaces in this---some LaTeX packages do not deal well with
        them.

    -e open latest zettel in \$MY_EDITOR

    -c clean temporary LaTeX files

    -p compile all entries

    -s <entry> entry to compile

    -g <regex>
        this is passed to the 'ag' command:
        ag -i --tex 'Keywords: <regex>'

        An example regex that will search for two keywords is: (keyword1|keyword2)
        ag -i --tex 'Keywords: (keyword1|keyword2)>'

        ag can be obtained here: https://github.com/ggreer/the_silver_searcher
        If ag is not found, it falls back to using grep.

    Written by Ankur Sinha mainly for personal use. However, comments for
    improvements are always welcome.
    https://github.com/sanjayankur31/zettelkasten-in-latex

EOF

}

if [ "$#" -eq 0 ]; then
    usage
    exit 0
fi

while getopts "s:n:hcepg:" OPTION
do
    case $OPTION in
        n)
            note_title=$OPTARG
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
        g)
            kw_regex_to_search=$OPTARG
            find_keywords
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
