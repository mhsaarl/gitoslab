#!/bin/bash

pass_file="$1"

while  read   line; do
 
   zipname=$(echo "$line" | grep -oE '^test[123]')
   pass=$(echo "$line" | grep -oE '<[^<>]{8,20}>' | sed 's/[<>]//g')
  
  if [[ -n "$zipname" && -n "$pass" ]]; then 
   echo "$pass"
   zipfile="${zipname}.zip"
     
    if [[ -f "$zipfile" ]]; then
      extdir="./$zipname"
      unzip -P "$pass" "$zipfile" -d "$extdir"
      find "$extdir" -type f ! -name "*.txt" -exec rm {} +
      fi
  fi
 
 


done < "$pass_file"
