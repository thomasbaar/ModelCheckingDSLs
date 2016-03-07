#!/bin/sh 


####
#### Input files to run the script on (assumend in folder src)
####
INPUTFILEBASE='lastGenerated'  


INPUTFILE=${INPUTFILEBASE}.pml
TRAILFILE='TRAIL_'${INPUTFILEBASE}'.txt'

SCRIPTPATH_AS_LINUX=`echo "$0" | sed 's/\\\\/\//g'`
WORKDIR=`dirname ${SCRIPTPATH_AS_LINUX}`

###
###
###

cd ${WORKDIR}

cat <<EOT


.... working in `pwd` 

.... taking src-gen/${INPUTFILE} as input


EOT





rm -rf tmp
mkdir tmp

cp src-gen/${INPUTFILE} tmp
cd tmp


## 1) invoke spin
spin -a ${INPUTFILE}

## tweak pan.c due to a MinGW bug
sed -i '1s/^/#define random rand\n#define srandom srand\n\n/' pan.c


###  -DBFS causes breadth-first and is much faster
gcc pan.c -DBFS -DREACH -DSAFETY -o file.pml.exe

file.pml.exe -i > out_shortest

spin -t $INPUTFILE > $TRAILFILE

if grep SOLVED ${TRAILFILE} >> /dev/null; then
	sed -n -e '/^ /,/ *SOLVED */ p' ${TRAILFILE}  ## assumes that solution starts with " "
	echo   ## empty line
	cat out_shortest | grep 'elapsed time'  ## show the time taken
else
	echo 'NOT SOLVED :-('
	cat $TRAILFILE # show the whole trailfile
fi	




cat <<EOT


Press <ENTER> to finish `basename ${SCRIPTPATH_AS_LINUX}` :
EOT
read a 

