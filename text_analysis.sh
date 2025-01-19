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
    tr -cs '[:alpha:]' '\n' < "$filename" | tr '[:upper:]' '[:lower:]' | grep -v " " | sort | uniq -c | sort -nr
}

# function to count character frequencies (case-insensitive)
count_char_frequencies() {
    echo "---Count of Character Frequencies---"
    # grep outputs (-o) only the matching part of the input (one character per line because . matches one character) and -v " " allows us to find lines not corresponding to spaces
    # uniq -c prefixes each character with count
    tr -cs '[:alpha:]' '\n' < "$filename" | tr '[:upper:]' '[:lower:]' | grep -o . | grep -v " " | sort | uniq -c | sort -nr
}

# functions to generate histograms
generate_char_histogram() {
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

generate_word_histogram() {
    echo "---Word Frequency Historgram---"
    total_words=$(wc -w < "$filename")
    largest_frequency=$(tr -cs '[:alpha:]' '\n' < "$filename" | tr '[:upper:]' '[:lower:]'| grep -v " " | sort | uniq -c | sort -nr | head -n 1 | awk '{print $1}')
    scale=$(echo "$largest_frequency / ($total_words * 20)" | bc -l)

    tr -cs '[:alpha:]' '\n' < "$filename" | tr '[:upper:]' '[:lower:]' | grep -v " " | sort | uniq -c | sort -nr | awk -v scale="$scale" -v total_words="$total_words" '{
        num_hashes = int(($1 / (scale * total_words)) + 0.5)
        printf "%-3s | ", $2;
        for (i = 0; i < num_hashes; i++) printf "#";
        printf " (%d)\n", $1;
    }'

}

export_results() {
    echo "Exporting results to $output_file"
    case $output_format in 
        "txt")
            echo "$results" > "$output_file"
            ;;
        "csv")
            echo "$results" | awk '{print $2","$1}' > "$output_file"
            ;;
        "json")
            echo "$results" | awk 'BEGIN {print "{"} {printf " \"%s\": %d,\n", $2, $1} END {print "}"}' > "$output_file"
            ;;
        *)
            echo "Unsupported format: $output_format"
            exit 1
            ;;
    esac
    echo "Results saved to $output_file!"
}

# Main: Prompt the user for analysis options
echo "Choose an analysis type"
echo "1. Character analysis"
echo "2. Word Analysis"
echo "3. Both"
read -p "Choice(1/2/3): " analysis_choice

# Perform the chosen analysis (character or word or both)
number_chars=$(wc -m $filename | awk '{print $1}')
number_lines=$(wc -l $filename | awk '{print $1}')
echo "There are $number_chars characters in this file."
echo "The file has $number_lines lines."

most_frequent_char=$(tr -cs '[:alpha:]' '\n' < "$filename" | tr '[:upper:]' '[:lower:]' | grep -o . | grep -v " " | sort | uniq -c | sort -nr | head -n 1 | awk '{print $2}')
most_frequent_word=$(tr -cs '[:alpha:]' '\n' < "$filename" | tr '[:upper:]' '[:lower:]'| grep -v " " | sort | uniq -c | sort -nr | head -n 1 | awk '{print $2}')
num_unique_words=$(count_unique_words)


if [ "$analysis_choice" = "1" ]; then
    echo "Character Analysis chosen..."
    echo "The most frequently occurring character in this file is: $most_frequent_char."
    results=$(count_char_frequencies)

elif [ "$analysis_choice" = "2" ]; then
    echo "Word Analysis chosen..."
    echo "The most frequently occurring word in this file is: $most_frequent_word."
    echo "There are $num_unique_words unique words in this file."
    results=$(count_word_frequencies)

elif [ "$analysis_choice" = "3" ]; then
    echo "Both analyses chosen..."
    echo "The most frequently occurring character in this file is: $most_frequent_char."
    echo "The most frequently occurring word in this file is: $most_frequent_word."
    echo "There are $num_unique_words unique words in this file."
    results="$(count_word_frequencies)
    $(printf '\n\n\n')
    $(count_char_frequencies)"
else
    echo "Invalid choice: $analysis_choice"
    exit 1
fi



# Show results 
echo "$results"

# Ask user if they want a Histogram 
read -p "Create a histogram (y/n)?" histogram_choice
if [ "$histogram_choice" = "y" ]; then
    if [ "$analysis_choice" = "1" ]; then
        generate_char_histogram
    elif [ "$analysis_choice" = "2" ]; then
        generate_word_histogram
    elif [ "$analysis_choice" = "3" ]; then
        generate_char_histogram
        printf '\n\n\n'
        generate_word_histogram
    fi
fi

read -p "Do you want to export the result? (y/n): " export_choice
if [ "$export_choice" = "y" ]; then
    echo "Choose an export file format:"
    echo "1. Plain text (.txt)"
    echo "2. Comma-Separated Value (.csv)"
    echo "3. Javascript Object Notation (.json)"
    read -p "Choice(1/2/3): " format_choice

    case $format_choice in
        1) output_format="txt" ;;
        2) output_format="csv" ;;
        3) output_format="json" ;;
        *) echo "Invalid format choice. Exiting program." ; exit 1 ;;
    esac

    read -p "Enter the output file name (without extension): " out_file
    output_file="$out_file.$output_format"

    export_results
fi
