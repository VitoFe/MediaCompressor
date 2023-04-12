## Media Compressor 🎥🎵

This is a simple bash script that compresses media files in a given input folder and copies them to a given output folder. It uses ffmpeg to perform the compression and supports various formats such as mp4, mp3, jpg, png, etc.

### Usage 🚀

To run the script, you need to have ffmpeg installed on your system.

Execute the script as follows:

`./compress.sh [options] input_folder output_folder`

The script will scan the input folder recursively and compress any media files it finds. It will preserve the original folder structure and file names in the output folder.

You can also specify some options to customize the compression process:

- `-h` or `--help`: Show a help message and exit
- `-q` or `--quality`: Set the quality value for compression in the 0-100 range (default: 75). Higher values mean better quality but larger file size.
- `-p` or `--max_processes`: Set the maximum number of processes to spawn for parallel compression (default: 4). Higher values mean faster compression but more CPU usage.

For example, to compress all media files in ~/Pictures with a quality of 90 and use 8 processes, you can run:

`./compress.sh -q 90 -p 8 ~/Pictures ~/Compressed_Pictures`
