#!/bin/bash

# проверка на root права
if [[ "${EUID}" != 0 ]]
then
	echo " "
        echo -e "\e[1;31m This script requires root privileges, trying to use sudo \e[0m"
	exit $?
fi

source 00-vars.sh

if [ ! -d ${BUILD}/images ]; then
	mkdir -p ${BUILD}/images
fi


uboot_position=256	#block - смещение на диске для расположения загрузчика u-boot
boot_size=50		#MiB - размер загрузочного раздела
part_position=2048	#KiB - расположения загрузочного раздела от начала диска

# полный путь к образу u-boot
uboot=${BUILD}/uboot/u-boot.rda

# Create beginning of disk
dd if=/dev/zero bs=1M count=$((part_position/1024)) of="$IMAGE"

# Create boot file system (VFAT)
dd if=/dev/zero bs=1M count=${boot_size} of=${IMAGE}1
mkfs.ext2 -L BOOT ${IMAGE}1

# скопировать загрузчик u-boot в начало диска
dd if="${uboot}" conv=notrunc seek=${uboot_position} of="${IMAGE}"

# скопировать параметры загрузки на загрузочный диск
[ -d /tmp/tmp ] || mkdir -p /tmp/tmp
mount -t ext2 ${IMAGE}1 /tmp/tmp
cp -rf ${EXTER}/chips/RDA/bootarg/* /tmp/tmp
cp -rf ${BUILD}/kernel/zImage /tmp/tmp
sync
umount /tmp/tmp

# вычисление размера диска от объёма rootfs
disk_size=$[(`du -s $DEST | awk 'END {print $1}'`+part_position)/1024+400+boot_size]

if [ "$disk_size" -lt 60 ]; then
	echo "Disk size must be at least 60 MiB"
	exit 2
fi

echo "Creating image $IMAGE of size $disk_size MiB ..."

# скопировать загрузочный раздел на диск
dd if=${IMAGE}1 conv=notrunc oflag=append bs=1M seek=$((part_position/1024)) of="$IMAGE"
rm -f ${IMAGE}1

# Create additional ext4 file system for rootfs
dd if=/dev/zero bs=1M count=$((disk_size-boot_size-part_position/1024)) of=${IMAGE}2
mkfs.ext4 -O ^metadata_csum -F -b 4096 -E stride=2,stripe-width=1024 -L rootfs ${IMAGE}2

# скопировать rootfs на второй раздел
if [ ! -d /media/tmp ]; then
	mkdir -p /media/tmp
fi

mount -t ext4 ${IMAGE}2 /media/tmp
# Add rootfs into Image
cp -rfa $DEST/* /media/tmp
umount /media/tmp

# скопировать второй раздел с rootfs в образ
dd if=${IMAGE}2 conv=notrunc oflag=append bs=1M seek=$((part_position/1024+boot_size)) of="$IMAGE"
rm -f ${IMAGE}2

if [ -d /media/tmp ]; then
	rm -rf /media/tmp
fi

# Add partition table
#  - создать новую пустую DOS таблицу разделов
#  - создать новый раздел 1 по смещению 4096 размером 50Mb и установить тип Linux
#  - создать новый раздел 2 по смещению 106496 размером до конца диска и установить тип Linux
cat <<EOF | fdisk "$IMAGE"
o
n
p
1
$((part_position*2))
+${boot_size}M
t
83
n
p
2
$((part_position*2 + boot_size*1024*2))

t
2
83
w
EOF

# посчитать сумму md5 и упаковать в архив образ
cd ${BUILD}/images/ 
rm -f ${IMAGENAME}.tar.gz
md5sum ${IMAGENAME}.img > ${IMAGENAME}.img.md5sum
tar czvf  ${IMAGENAME}.tar.gz $IMAGENAME.img*
rm -f *.md5sum
sync

echo "Создан образ $IMAGE ..."
