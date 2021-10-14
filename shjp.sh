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

if [ $# -eq 0 ]; then
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
[ -f ${tmp}targets ] && flg_direct=1 || :

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

    if [ -n "$flg_direct" ]; then
        if [ "$flg_target" = 1 ]; then
            echo $key >> ${tmp}answer
            echo $1 >> ${tmp}answer
        else : 
        fi
    else
        if [ "$flg_on_read" = 1 -o "$flg_on_read" = 2 ]; then
            key_prefix=1
        elif [ "$flg_on_read" = 3 ]; then
            key_prefix=3
        elif [ "$flg_on_read" = 4 ]; then
            key_prefix=2
        fi
        echo ${key_prefix}${key} >> ${tmp}answer
        if [ "$flg_on_read" = 3 ]; then
            output=$(r4process "$obj_value" "$key" $tmp $flg_direct)
            if [ $? -ne 0 ]; then
                [ -n "$output" ] && echo "$output" || :
                end 1
            fi
        else
            echo "$1" | awk '{print "4" $0}' >> ${tmp}answer
        fi
        [ "$key_prefix" = 2 -o "$key_prefix" = 3 ] && echo ${key_prefix}${key} >> ${tmp}answer || :
    fi
    flg_on_read=''
    flg_target=''
    key=''
}

function readNumValue(){
    
    if [ -n "$flg_end" ]; then
        [[ "$char" =~ ^[0-9]+$ ]] || invalidFormatError || :
        last_idx=$(($i-$marked_idx+1))
    else
        if [[ "$char" =~ ^[0-9]+$ ]]; then
            return 0
        else
            [ "$char" != ',' ] && invalidFormatError || :
            [ -n "$1" ] flg_force=1 || :
        fi
        last_idx=$(($i-$marked_idx))
        flg_state=''
        flg_on_read=''
    fi

    num_value=${json_value:(($marked_idx-1)):$last_idx}
    [ -n "$1" ] && echo $num_value || record $num_value
}

function identifyClosingBracket(){

    if [ "$char" = '"' ]; then
        if [ -z "$flg_escape4reading" ]; then
            flg_escape4reading=1
        elif [ "${json_value:(($i-2)):1}" != '\' ]; then
            flg_escape4reading=''
        fi
        flg_continue=1
        return 0
    elif [ -n "$flg_escape4reading" ]; then
        flg_continue=1
        return 0 
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

    if [ -n "$depth_counter" ]; then
        flg_continue=1
        return 0
    fi
}

function processAarray(){

    flg_force='' # 1-dbq/2-comma
    flg_state=1 # 1-distinguish value/2-extract value
    flg_on_read='' # 1-str/2-num/3-array or obj
    flg_target=''
    flg_end=''
    marked_idx=0
    key=''

    flg_escape4reading=''
    depth_counter=''

    for i in `seq 1 ${#json_value}`; do
    
        char=${json_value:(($i-1)):1}
        [ "$i" = "${#json_value}" ] && flg_end=1 || :

        if [ "$flg_on_read" != 1 -a "a$char" = "a " ]; then
            continue

        elif [ -n "$flg_force" ]; then

            if [ "$flg_force" = 1 ]; then
                [ "$char" != '"' ] && invalidFormatError || :
                flg_force=''
                flg_on_read=1
                marked_idx=$i
            elif [ "$flg_force" = 2 ]; then
                [ "$char" != ',' ] && invalidFormatError || :
                flg_force=''
                flg_state=1
            fi
        
        elif [ "$flg_state" = 1 ]; then
            
            marked_idx=$i
            flg_state=2
            
            if [ "$char" = '"' ]; then
                flg_on_read=1
            elif [[ "$char" =~ ^[0-9]+$ ]]; then
                readNumValue 1
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

            flg_force=2
            flg_state=''
            echo "$str_value"
            
        elif [ "$flg_on_read" = 2 ]; then
            
            readNumValue 1

        elif [ "$flg_on_read" = 3 ]; then

            flg_continue=''
            identifyClosingBracket
            [ -n "$flg_continue" ] && continue || :
            
            flg_on_read=''
            obj_value=${json_value:(($marked_idx-1)):(($i-$marked_idx+1))}

            if [ "$flg_state" = 2 ]; then
                flg_force=2
                flg_state=''
            fi

            # 配列内の配列及びオブジェクトのパースは
            # 呼び出し元でのループ処理における随時的なjsonパースを想定しているため、考慮しない
            echo "$obj_value"
        fi
    done
    [ -z "$flg_end" ] && invalidFormatError || :
}

function r4process(){
    
    json_value=$1
    layer=$2
    tmp=$3
    flg_direct=$4

    char_start=${json_value:0:1}
    char_end=${json_value: -1}
    json_value=${json_value:1:((${#json_value}-2))}

    if [ "$char_start" = '{' ]; then
        [ "$char_end" != '}' ] && invalidFormatError || :
    elif [ "$char_start" = '[' ]; then
        [ "$char_end" = ']' ] && flg_array=1 || invalidFormatError
    fi

    [ -z "$json_value" ] && return 0 || :
    if [ -n "$flg_array" ]; then
        processAarray
        return 0
    fi

    flg_force=1 # 1-dbq/2-comma/3-colon
    flg_state=1 # 1-extract key/2-distinguish value/3-extract value
    flg_on_read='' # 1-str/2-num/3-obj/4-array
    flg_target='' # 1-this is the target./2-including the target as children.
    flg_end=''
    marked_idx=0
    key=''

    flg_escape4reading=''
    depth_counter=''

    for i in `seq 1 ${#json_value}`; do
    
        char=${json_value:(($i-1)):1}
        [ "$i" = "${#json_value}" ] && flg_end=1 || :

        if [ "$flg_on_read" != 1 -a "a$char" = "a " ]; then
            continue
        
        elif [ -n "$flg_force" ]; then

            if [ "$flg_force" = 1 ]; then
                [ "$char" != '"' ] && invalidFormatError || :
                flg_force=''
                flg_on_read=1
                marked_idx=$i
            elif [ "$flg_force" = 2 ]; then
                [ "$char" != ',' ] && invalidFormatError || :
                flg_state=1
                flg_force=1
            elif [ "$flg_force" = 3 ]; then
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
                flg_on_read=4
                depth_counter='['
            else
                invalidFormatError
            fi

        elif [ "$flg_on_read" = 1 ]; then
            [ "$char" != '"' -o "${json_value:(($i-2)):1}" = '\' ] && continue || :

            str_value=${json_value:$marked_idx:(($i-$marked_idx-1))}

            if [ "$flg_state" = 1 ]; then
                flg_force=3
                flg_on_read=''
                [ "$layer" = 'root' ] && key=$str_value || key=${layer}.${str_value}
                if [ -n "$flg_direct" ]; then
                    flg_target="$(cat ${tmp}targets | 
                        awk '{
                            if(end){
                            }else if($0=="'$key'"){
                                print "1";
                                end=1
                            }else if($0 ~ /^('$key').+$/)){
                                print "2";
                                end=1;
                            }}')"
                fi
            elif [ "$flg_state" = 3 ]; then
                flg_force=2
                flg_state=''
                record "$str_value"
            fi

        elif [ "$flg_on_read" = 2 ]; then
            
            readNumValue

        elif [ "$flg_on_read" = 3 -o "$flg_on_read" = 4 ]; then

            flg_continue=''
            identifyClosingBracket
            [ -n "$flg_continue" ] && continue || :
            
            obj_value=${json_value:(($marked_idx-1)):(($i-$marked_idx+1))}

            # コンパイル形式の配列
            # 直指定で対象を子に持つオブジェクト
            # 直指定の配列
            if [ -z "$flg_direct" -a "$flg_on_read" = 4 -o \
                 "$flg_on_read" = 3 -a "$flg_target" = 2 -o \
                 "$flg_on_read" = 4 -a "$flg_target" = 1 ]; then
                output=$(r4process "$obj_value" "$key" $tmp $flg_direct)
                if [ $? -ne 0 ]; then
                    [ -n "$output" ] && echo "$output" || :
                    end 1
                fi
                [ "$flg_on_read" = 4 ] && obj_value="$output" || :
            fi

            if [ "$flg_state" = 3 ]; then
                flg_force=2
                flg_state=''
            fi

            # コンパイル形式のオブジェクトのみ、record内で再帰する
            record "$obj_value"
        fi
    done
    [ -z "$flg_end" ] && invalidFormatError || :
}

r4process $(echo "$json_value_origin" | tr -d ' ') root $tmp $flg_direct

if [ -n "$flg_direct" ]; then
    cat ${tmp}answer | awk 'NR%2==1' | sort > ${tmp}answered_targets
    cat ${tmp}targets | sort |
    while read line; do
        if [ -z "$(cat ${tmp}answered_targets | grep $line)" ]; then
            echo "$line is not found."
            exit 1
        fi
    done
    [ $? -ne 0 ] && end 1 || :
fi

cat ${tmp}answer

end 0
