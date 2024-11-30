#!/bin/bash

passfile="$1"

while read  line; do  
  zipname=$(echo "$line" | grep -oE '^test[123]')
  pass=$(echo "$line" | grep -oE '<[^<>]{8,20}>' | sed 's/[<>]//g')

  if [[ -n "$zipname" && -n "$pass" ]]; then
     echo "$zipname" ":" "$pass"
     zipfile="${zipname}.zip"
      
   fi

done < "$passfile"

