#!bin/bash
BeadNum=$1
F=$(ls | grep "B$BeadNum")
outPath = B$BeadNum_Data

mv $F $outPath
