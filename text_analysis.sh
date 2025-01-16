#!/bin/bash

# check if file provided
if [ -z "$1" ]; then
    echo "Usage: $0 <file>"
    exit 1
fi

# check if provided file exists
if [ ! -f "$1" ]; then
    echo "File not found: $1"
    exit 1
fi

filename="$1"

# function to count the number of unique words
count_unique_words() {
    tr -cs '[:alpha:]' '\n' < "$filename" | sort | uniq | wc -l
}
# function to count word frequencies
count_word_frequencies() {
    echo "---Count of Word Frequencies---"
    tr -cs '[:alpha]' '\n' < "$filename" | sort | uniq -c | sort -nr
}

# function to count character frequencies (case-insensitive)
count_char_frequencies() {
    echo "---Count of Character Frequencies---"
    # grep outputs (-o) only the matching part of the input (one character per line because . matches one character) and -v " " allows us to find lines not corresponding to spaces
    # uniq -c prefixes each character with count
    tr -cs '[:alpha]' '\n' < "$filename" | tr '[:upper:]' '[:lower:]' | grep -o . | grep -v " " | sort | uniq -c | sort -nr
}

# function to generate a histogram
generate_histogram() {
    echo "---Character Frequency Histogram---"
    total_chars=$(wc -m < "$filename")
    largest_frequency=$(tr -cs '[:alpha:]' '\n' < "$filename" | tr '[:upper:]' '[:lower:]' | grep -o . | grep -v " " | sort | uniq -c | sort -nr | head -n 1 | awk '{print $1}')
    scale=$(echo "$largest_frequency / ($total_chars * 20)" | bc -l)

    tr -cs '[:alpha:]' '\n' < "$filename" | tr '[:upper:]' '[:lower:]' | grep -o . | grep -v " " | sort | uniq -c | sort -nr | awk -v scale="$scale" -v total_chars="$total_chars" '{
        num_hashes = int(($1 / (scale * total_chars)) + 0.5)
        printf "%-3s | ", $2;
        for (i = 0; i < num_hashes; i++) printf "#";
        printf " (%d)\n", $1;

    }'
}

generate_histogram
