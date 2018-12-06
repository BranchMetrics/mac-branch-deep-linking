#!/bin/bash
set -euo pipefail

function show_help() {
cat <<HELP
make-fat  -  make fat universal binaries.

usage:

TODO:
  Write help
  Make universal dSYM
HELP
}

if (( $# < 2 ))
then
    show_help
    exit 0
fi


input_file="$(resolvepath "$1")"
framework_name="$(basename "$input_file")"
framework_name="${framework_name%.*}"

# output_file="$(resolvepath "${@: -1}")"
output_file="${@: -1}"
mkdir -p "$(dirname "$output_file")"
output_file="$(resolvepath "$output_file")"

ditto "$input_file" "$output_file"

input_files=()
while (( $# > 1 ))
do
    input_file="$(resolvepath "$1")"
    input_file="$input_file"/"$framework_name"
    input_files+=("$input_file")
    shift 1
done

lipo  -create ${input_files[*]}  -output "$output_file"/"$framework_name"

file "$output_file"/"$framework_name" 1>&2
