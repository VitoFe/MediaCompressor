#!/bin/bash

display_help() {
    echo "Usage: $0 [options] input_folder output_folder"
    echo
    echo "Compress media files in a given input folder and copy them to a given output folder."
    echo
    echo "Options:"
    echo "  -h, --help      Show this help message and exit"
    echo "  -q, --quality   Set the quality value for compression (default: 75)"
    echo "  -s, --scale     Scale by a certain ratio (default: 1)"
    echo
}

# Default options
quality=75
max_processes=4
scale_ratio=1

# Parse the command-line options using getopts
while getopts ":hq:-:" opt; do
    case "$opt" in
        h) # Display help message and exit
            display_help
            exit 0
            ;;
        q) # Set the quality 0-100
            quality="$OPTARG"
            ;;
        p) # Set the max number of processes to spawn
            max_processes="$OPTARG"
            ;;
        s) # Set the quality 0-100
            scale_ratio="$OPTARG"
            ;;
        -) # Handle long options
            case "$OPTARG" in
                help)
                    display_help
                    exit 0
                    ;;
                quality=*)
                    quality="${OPTARG#*=}"
                    ;;
                max_processes=*)
                    max_processes="${OPTARG#*=}"
                    ;;
                scale_ratio=*)
                    scale_ratio="${OPTARG#*=}"
                    ;;
                *) # Invalid option
                    echo "Error: Invalid option: --$OPTARG" >&2
                    display_help >&2
                    exit 1
                    ;;
            esac
            ;;
        \?) # Invalid option
            echo "Error: Invalid option: -$OPTARG" >&2
            display_help >&2
            exit 1
            ;;
        :) # Missing argument
            echo "Error: Missing argument for -$OPTARG" >&2
            display_help >&2
            exit 1
            ;;
    esac
done

shift $((OPTIND - 1))

if [ $# -ne 2 ]; then
    echo "Error: Missing input_folder or output_folder" >&2
    display_help >&2
    exit 1
fi

input_folder="$1"
output_folder="$2"

# Create output folder if it does not exist
mkdir -p "$output_folder"

start_time=$(date +%s)

function convert_files() {
    for item in "$1"/*; do
        if [[ -d "$item" ]]; then
            mkdir -p "$output_folder/${item#$input_folder/}"
            convert_files "$item"
        elif [[ -f "$item" ]]; then
            case "${item##*.}" in
                jpg|jpeg|png|gif)
                    printf "Converting %s\n" "$item"
                    # Check if scale_ratio is set and lower than 1
                    if [[ -n "$scale_ratio" && "$scale_ratio" < 1 ]]; then
                        # Scale the image by the ratio
                        convert -quality "$quality" -resize "$scale_ratio%" "$item" "$output_folder/${item#$input_folder/}" &
                    else
                        # Keep the original size
                        convert -quality "$quality" "$item" "$output_folder/${item#$input_folder/}" &
                    fi
                    ;;
                mp4|avi|mov|mkv)
                    printf "Compressing %s\n" "$item"
                    crf=$((51 - quality / 2))
                    # Check if scale_ratio is set and lower than 1
                    if [[ -n "$scale_ratio" && "$scale_ratio" < 1 ]]; then
                        # Scale the video by the ratio
                        ffmpeg -i "$item" -vcodec libx264 -crf "$crf" -vf "scale=iw*$scale_ratio:ih*$scale_ratio" "$output_folder/${item#$input_folder/}" &
                    else
                        # Keep the original size
                        ffmpeg -i "$item" -vcodec libx264 -crf "$crf" "$output_folder/${item#$input_folder/}" &
                    fi
                    ;;
            esac

            # Limit number of processes
            while (( $(jobs -r -p | wc -l) >= $max_processes )); do
                sleep 0.1
            done
        fi
    done
}

convert_files "$input_folder"

wait

size_before=$(find "$input_folder" -type f -exec du -b {} + | awk '{total += $1} END {print total}')
size_after=$(find "$output_folder" -type f -exec du -b {} + | awk '{total += $1} END {print total}')
space_saved=$((size_before - size_after))
saved=$(numfmt --to=iec-i --suffix=B $space_saved)
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))

echo "Done. Compressed files are copied to $output_folder in $elapsed_time seconds. Saved $saved"
