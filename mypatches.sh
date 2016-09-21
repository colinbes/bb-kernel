#!/bin/sh
DIR=$PWD

cd ${DIR}/KERNEL

patch -p 1 < ${DIR}/mypatches/tsc-patch/tsc.patch
patch -p 1 < ${DIR}/mypatches/tsc-patch/tsc-sysfs.patch

cd $DIR

echo "Completed mypatches" 
