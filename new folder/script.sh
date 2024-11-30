#!/bin/bash

if [[ -z "$1" ]]; then
echo "enter"
exit 1
fi

password_file="$1"

if [[ ! -f "password_file" ]]; then
echo "not found"
exit 1
fi


while IFS= read -r line; do
zip_name=$(echo "$line" | grep -oE '^(text[123])')
pass=$(echo "$line" | grep -oE '<[^<>]{8,20}>' | sed 's/[<>]//g')

if [[ -n "$zip_name" && -n "$pass" ]]; then
echo "$pass"
fi 

done < "$password_file"
