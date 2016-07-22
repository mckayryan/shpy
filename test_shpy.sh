#!/bin/bash

########
# Scripts for testing output shpy.pl
########

subset=$1
test_prog='shpy.pl'
i='0'

#file_names=('hello_world' 'ls' 'ls-l' 'pwd' 'single' 'truth0' 'variables0')

while [ "$i" -le "$subset" ]
do
    echo *******TESTING: SUBSET $i*******
    path="examples/$i"
    for sh_file in $path/*.sh
    do
        py_file="`echo "$sh_file" | sed 's/sh/py/'`"
        echo
        echo $sh_file
        echo "shell file name:........$sh_file"
        echo "python file name:........$py_file"
        ## test python code output vs python examples
        ./$test_prog $sh_file > tmp_out.py
        diff -yw --suppress-common-lines tmp_out.py "$py_file"
        if [ $? -ne 0 ]; then
            echo "$test_prog $sh_file..... python ouput...... failed test"
        else
            echo "$test_prog $sh_file..... python ouput...... passed!!!"
        fi
        ## test produced python code output vs original shell output
        chmod 700 tmp_out.py
        chmod 700 "$sh_file"
        python tmp_out.py > tmp_py_out
        ./"$sh_file" > tmp_sh_out
        diff -yw --suppress-common-lines tmp_sh_out tmp_py_out
        if [ $? -ne 0 ]; then
            echo "Produced python does not match $sh_file output........ failed test"
        else
            echo "Produced python matches $sh_file output........ Passed!!!"
        fi
    done
    i=$(( i+1 ))
    cat | echo
done

rm tmp_sh_out
rm tmp_py_out
rm tmp_out.py
