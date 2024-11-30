#!bin/bash

password_file="$1"


while IFS= read -r line; do
    
    zip_name=$(echo "$line" | grep -oE '^(test[123])')
    password=$(echo "$line" | grep -oE '<[^<>]{8,20}>' | sed 's/[<>]//g')

  if [[ -n "$zip_name" && -n "$password" ]]; then
          echo "فایل زیپ: ${zip_name}.zip - رمز: $password"
    fi
done < "$password_file"

