#!/bin/bash
# csv_compare.sh
# Inputs: pairs of csv filename and column to use for that file.
# Currently configured to work with 3 files - modify the declared arrays below to work with more files, or change the combinations to be checked.
# Output: comparison files for the pairs of files initialised below, using the columns specified, along with a report of number of lines for each.
# WARNING: zero protection against malicious inputs!

# Initialise the input files and columns to loop for data cleaning.
declare -a aInputFiles=($1 $3 $5)
declare -a aInputNames=("A" "B" "C")
declare -a aInputColumnToUse=($2 $4 $6)
iInputs=${#aInputFiles[@]}

#Initalise the combinations to be checked - each round of the loop, we will check the combination of same indexed element from both arrays.
declare -a aPairsToCompare1=("A" "A" "B" "AB" "AC" "BC")
declare -a aPairsToCompare2=("B" "C" "C" "C" "B" "A")
iOutputs=${#aPairsToCompare1[@]}

#Initialise the files wanted in the final report.
declare -a aFilesToPrint=("A" "B" "C" "AB" "AnotB" "BnotA" "AC" "AnotC" "CnotA" "BC" "BnotC" "CnotB" "ABC" "ABnotC" "CnotAB" "ACnotB" "BnotAC" "BCnotA" "AnotBC")

#Make a fresh output folder.
rm -rf CompareOutput
mkdir -p CompareOutput

# Loop the input files, get only the needed column, and sort. Put into the output folder as final "A", "B", "C" files.
for (( i=0; i<$iInputs; i++ ))
do
   sFinalFileName="CompareOutput/${aInputNames[$i]}.txt"
   sTempFileName="CompareOutput/${aInputNames[$i]}.tmp"
   awk -F"," -v col="${aInputColumnToUse[$i]}" '{print $col}' ${aInputFiles[$i]} > $sTempFileName
   sort $sTempFileName > $sFinalFileName
   rm -f $sTempFileName
done

# Loop the pairs, do a diff that shows the three possibilities (in both, in file1 only, in file2 only), then split this into the three needed output files.
sTempDiffFile="CompareOutput/diff.txt"
for (( i=0; i<$iOutputs; i++ ))
do
   sInputFile1="CompareOutput/${aPairsToCompare1[$i]}.txt"
   sInputFile2="CompareOutput/${aPairsToCompare2[$i]}.txt"
   sOutputFileAB="CompareOutput/${aPairsToCompare1[$i]}${aPairsToCompare2[$i]}.txt"
   sOutputFileAnotB="CompareOutput/${aPairsToCompare1[$i]}not${aPairsToCompare2[$i]}.txt"
   sOutputFileBnotA="CompareOutput/${aPairsToCompare2[$i]}not${aPairsToCompare1[$i]}.txt"

   # do the diff and extract three outputs
   diff $sInputFile1 $sInputFile2 --unchanged-line-format='= %L' --old-line-format='< %L' --new-line-format='> %L' > $sTempDiffFile
   grep ">" $sTempDiffFile | sed 's/^> //g' > $sOutputFileBnotA
   grep "<" $sTempDiffFile | sed 's/^< //g' > $sOutputFileAnotB
   grep "=" $sTempDiffFile | sed 's/^= //g' > $sOutputFileAB

   # remove the temp file
   rm -f $sTempDiffFile
done

#print summary
for i in "${aFilesToPrint[@]}"
do
   sFile="CompareOutput/${i}.txt"
   iLines=`wc -l < $sFile`
   sPrint="${i}\t:\t${iLines}"	
   echo -e $sPrint
done
