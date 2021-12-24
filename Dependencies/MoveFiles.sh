#!/usr/bin/bash
RootPath=$1
BeadNum=$2 

DataPath="$RootPath$BeadNum/_Data"
ls $RootPath | grep "$BeadNum"

echo $RootPath
echo $DataPath
echo $BeadNum
echo $(command)
