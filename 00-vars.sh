#!/bin/bash

set -e

ROOT=`pwd`
UBOOT="${ROOT}/uboot"
BUILD="${ROOT}/output"
LINUX="${ROOT}/kernel"
EXTER="${ROOT}/external"
SCRIPTS="${ROOT}/scripts"
DEST="${BUILD}/rootfs"
UBOOT_BIN="$BUILD/uboot"
PACK_OUT="${BUILD}/pack/"

CORES=$(nproc --ignore=1)

ARCH="arm"
CHIP="RDA"
TOOLS=${ROOT}/toolchain/gcc-linaro-1.13.1-2012.02-x86_64_arm-linux-gnueabi/bin/arm-linux-gnueabi-
BOARD="2G-iot"
KERNEL_NAME="linux3.10.62"
DISTRO="xenial"
DISTRO_NUM="16.04.6"
OS="ubuntu"
IMAGETYPE="server"
VER="v0.0.4"
IMAGENAME="OrangePi_${BOARD}_${OS}_${DISTRO}_${IMAGETYPE}_${KERNEL_NAME}_${VER}"
IMAGE="${BUILD}/images/$IMAGENAME.img"
