#!/bin/bash

source 00-vars.sh

if [[ "${EUID}" != 0 ]]
then
	echo " "
        echo -e "\e[1;31m This script requires root privileges, trying to use sudo \e[0m"
	exit $?
fi

# компиляция ядра

if [ ! -d $BUILD ]; then
	mkdir -p $BUILD
fi

if [ ! -d $BUILD/kernel ]; then
	mkdir -p $BUILD/kernel
fi

make -C $LINUX ARCH=${ARCH} CROSS_COMPILE=$TOOLS -j${CORES} zImage
# Install zImage and modules 
cp -rfa ${LINUX}/arch/arm/boot/zImage ${BUILD}/kernel

# компиляция модулей

if [ ! -d $BUILD/lib ]; then
    mkdir -p $BUILD/lib
else
    rm -rf $BUILD/lib/*
fi

make -C $LINUX ARCH="${ARCH}" CROSS_COMPILE=$TOOLS -j${CORES} modules
make -C $LINUX ARCH="${ARCH}" CROSS_COMPILE=$TOOLS -j${CORES} modules_install INSTALL_MOD_PATH=$BUILD
