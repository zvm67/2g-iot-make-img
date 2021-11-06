#!/bin/bash

# проверка на root права
if [[ "${EUID}" != 0 ]]
then
	echo " "
        echo -e "\e[1;31m This script requires root privileges, trying to use sudo \e[0m"
	exit $?
fi

source 00-vars.sh

make -C $LINUX ARCH=${ARCH} CROSS_COMPILE=$TOOLS menuconfig
