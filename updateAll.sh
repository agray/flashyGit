#!/bin/sh

ls -l -d */ > temp.txt

while read line          
do          
    gawk '{print $NF}' | sed s/.$//
done < temp.txt > out.txt
rm temp.txt
echo "Updating the following repos:"
less out.txt

while read line
do
    cd $line
    git pull
    cd ..
done < out.txt
rm out.txt
