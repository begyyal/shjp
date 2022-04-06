#!/bin/bash

tag_name=$1
repo_url=$2

LF=$'\\n'
text="SHJP updated to ${tag_name}${LF}${repo_url}${LF}#Shell #Bash"

echo -n "{\"text\":\"${text}\"}"