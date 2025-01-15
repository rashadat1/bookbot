#!/bin/bash

# check if file provided
if [ -z "$1" ]; then
    echo "Usage: $0 <file>"
    exit 1
fi

filename="$1"

# check if provided file exists
if [ ! -f "$filename" ]; then
    echo "File not found: $filename"
    exit 1
fi

# function to count word frequencies
count_word_frequencies() {
    echo "---Count of Word Frequencies---"
    tr -cs '[:alpha]' '\n' < "$filename" | sort | uniq -c | sort -nr 
}

# function to count character frequencies (case-insensitive)
count_char_frequencies() {:
    echo "---Count of Character Frequencies---"
    # grep outputs only the matching part of the input (one character per line because . matches one character)
    # uniq -c prefixes each character with count
    tr -cs '[:alpha]' '\n' < "$filename" | tr '[:upper:]' '[:lower:]' | grep -o . | sort | uniq -c | sort -nr
}


