# This software is released under the MIT License

# Copyright (c) 2021 begyyal

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#!/bin/bash

if [ $# -le 1 ]; then
    echo "Arguments lack."
    exit 1
fi

tmp_dir='/tmp/cmdbbt/'
timestamp=$(date +%Y%m%d%H%M%S)
tmp_id=$(ls -l $tmp_dir | grep $timestamp | wc -l)
tmp=${tmp_dir}${timestamp}'_'${tmp_id}'/'
mkdir -p $tmp

readonly input=$1
shift

while [ -n "$1" ]; do
    echo $1 >> ${tmp}targets
    shift
done

if [ -f $input ]; then
    json_value_origin=$(cat $input | tr -d '\r' | tr -d '\n')
else
    json_value_origin=$input
fi

touch ${tmp}answer

function end(){
    rm -rdf ${tmp}
    exit $1
}

function invalidFormatError(){
    # TODO 気が向いたら該当箇所表示する
    echo 'This json has invalid format.'
    echo $json_value
    end 1
}

function record(){
    if [ -n "$flg_target" ]; then
        echo $key >> ${tmp}answer
        echo $1 >> ${tmp}answer
        flg_target=''
    fi
    key=''
}

function forceCommma(){
    [ "$char" != ',' ] && invalidFormatError || :
    flg_state=1
    flg_force=1
}

function readNumValue(){
    
    if [ -n "$flg_end" ]; then
        [[ "$char" =~ ^[0-9]+$ ]] || invalidFormatError || :
        last_idx=$(($i-$marked_idx+1))
    else
        [[ "$char" =~ ^[0-9]+$ ]] && continue || forceCommma
        last_idx=$(($i-$marked_idx))
        flg_state=''
        flg_on_read=''
    fi

    num_value=${json_value:(($marked_idx-1)):$last_idx}
    record $num_value
}

function r4process(){
    
    json_value=$1
    layer=$2
    tmp=$3

    char_start=${json_value:0:1}
    char_end=${json_value: -1}
    
    if [ "$char_start" = '{' ]; then
        [ "$char_end" != '}' ] && invalidFormatError || :
    elif [ "$char_start" = '[' ]; then
        [ "$char_end" = ']' ] && return 0 || invalidFormatError
    fi

    json_value=${json_value:1:((${#json_value}-2))}
    [ -z $json_value ] && return 0 || :

    flg_force=1 # 1-dbq/2-comma/3-colon
    flg_state=1 # 1-extract key/2-distinguish value/3-extract value
    flg_on_read='' # 1-str/2-num/3-obj or array
    flg_target=''
    flg_end=''
    marked_idx=0
    key=''

    flg_read3_escaped=''
    depth_counter=''

    for i in `seq 1 ${#json_value}`; do
    
        char=${json_value:(($i-1)):1}
        [ "$i" = "${#json_value}" ] && flg_end=1 || :

        if [ -n "$flg_force" ]; then

            if [ "$flg_force" = 1 ]; then
                [ "$char" != '"' ] && invalidFormatError || :
                flg_force=''
                flg_on_read=1
                marked_idx=$i
            elif [ "$flg_force" = 2 ]; then
                forceCommma
            elif [ "$flg_force" = '3' ]; then
                [ "$char" != ':' ] && invalidFormatError || :
                flg_force=''
                flg_state=2
            fi
        
        elif [ "$flg_state" = 2 ]; then
            
            marked_idx=$i
            flg_state=3
            
            if [ "$char" = '"' ]; then
                flg_on_read=1
            elif [[ "$char" =~ ^[0-9]+$ ]]; then
                readNumValue
                flg_on_read=2
            elif [ "$char" = '{' ]; then
                flg_on_read=3
                depth_counter='{'
            elif [ "$char" = '['  ]; then
                flg_on_read=3
                depth_counter='['
            else
                invalidFormatError
            fi

        elif [ "$flg_on_read" = 1 ]; then
            [ "$char" != '"' -o "${json_value:(($i-2)):1}" = '\' ] && continue || :

            flg_on_read=''
            str_value=${json_value:$marked_idx:(($i-$marked_idx-1))}

            if [ "$flg_state" = 1 ]; then
                flg_force=3
                [ "$layer" = 'root' ] && key=$str_value || key=${layer}.${str_value}
                [ -n "$(cat ${tmp}targets | awk '$0=="'$key'"')" ] && flg_target=1 || :
            elif [ "$flg_state" = 3 ]; then
                flg_force=2
                flg_state=''
                record $str_value
            elif [ -n "$flg_end" ]; then
                record $str_value
            fi

        elif [ "$flg_on_read" = 2 ]; then
            
            readNumValue

        elif [ "$flg_on_read" = 3 ]; then

            if [ "$char" = '"' ]; then
                if [ -z "$flg_read3_escaped" ]; then
                    flg_read3_escaped=1
                elif [ "${json_value:(($i-2)):1}" != '\' ]; then
                    flg_read3_escaped=''
                fi
                continue
            elif [ -n "$flg_read3_escaped" ]; then
                continue 
            fi

            if [ "$char" = '{' ]; then
                depth_counter=$depth_counter'{'
            elif [ "$char" = '['  ]; then
                depth_counter=$depth_counter'['
            elif [ "$char" = '}'  ]; then
                if [ "${depth_counter: -1}" = '{' ]; then
                    depth_counter=${depth_counter:0:((${#depth_counter}-1))}
                else 
                    invalidFormatError
                fi
            elif [ "$char" = ']'  ]; then
                if [ "${depth_counter: -1}" = '[' ]; then
                    depth_counter=${depth_counter:0:((${#depth_counter}-1))}
                else 
                    invalidFormatError
                fi
            fi

            [ -n "$depth_counter" ] && continue || :
            
            flg_on_read=''
            obj_value=${json_value:(($marked_idx-1)):(($i-$marked_idx+1))}

            if [ -n "$(cat ${tmp}targets | awk '$0 ~ /^('$key').+$/')" ]; then
                # 再帰時の変数住み分けのため子プロセスで実行
                output=$(r4process "$obj_value" "$key" $tmp)
                if [ $? -ne 0 ]; then
                    [ -n "$output" ] && echo "$output" || :
                    end 1
                fi
            fi

            if [ "$flg_state" = 3 ]; then
                flg_force=2
                flg_state=''
            fi
            record $obj_value
        fi
    done
    [ -z "$flg_end" ] && invalidFormatError || :
}

r4process $(echo "$json_value_origin" | tr -d ' ') root $tmp

cat ${tmp}answer | awk 'NR%2==1' | sort > ${tmp}answered_targets
cat ${tmp}targets | sort |
while read line; do
    if [ -z "$(cat ${tmp}answered_targets | grep $line)" ]; then
        echo "$line is not found."
        exit 1
    fi
done
[ $? -ne 0 ] && end 1 || :

cat ${tmp}answer

end 0
