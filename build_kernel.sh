#!/bin/sh
# Build Script: Javilonas, 11-01-2015
# Javilonas <admin@lonasdigital.com>
start_time=`date +'%d/%m/%y %H:%M:%S'`
echo "#################### Eliminando Restos ####################"
./clean.sh > /dev/null 2>&1
echo "#################### Preparando Entorno ####################"
export KERNELDIR=`readlink -f .`
export RAMFS_SOURCE=`readlink -f $KERNELDIR/ramdisk`
export TOOLBASE="/home/lonas/Kernel_Lonas/Enki-SM-G901F/buildtools"

if [ "${1}" != "" ];then
  export KERNELDIR=`readlink -f ${1}`
fi

ROOTFS_PATH="/home/lonas/Kernel_Lonas/Enki-SM-G901F/ramdisk"
RAMFS_TMP="/home/lonas/Kernel_Lonas/tmp/ramfs-source-sgs5"

export KERNEL_VERSION="Enki-0.1"
export VERSION_KL="SM-G901F"
export REVISION="RC"

export KBUILD_BUILD_VERSION="1"

export ARCH=arm

#make apq8084_sec_defconfig VARIANT_DEFCONFIG=apq8084_sec_kccat6_eur_defconfig SELINUX_DEFCONFIG=selinux_defconfig

#cp .config arch/arm/configs/apq8084_lonas_defconfig

cp arch/arm/configs/apq8084_lonas_defconfig .config

. $KERNELDIR/.config

echo "#################### Aplicando Permisos correctos ####################"
chmod 644 $ROOTFS_PATH/*.rc
chmod 750 $ROOTFS_PATH/init*
chmod 640 $ROOTFS_PATH/fstab*
chmod 644 $ROOTFS_PATH/default.prop
chmod 771 $ROOTFS_PATH/data
chmod 755 $ROOTFS_PATH/dev

if [ -f $ROOTFS_PATH/system/lib/modules ]; then
        chmod 755 $ROOTFS_PATH/system/lib/modules
        chmod 644 $ROOTFS_PATH/system/lib/modules/*
fi

chmod 755 $ROOTFS_PATH/proc
chmod 750 $ROOTFS_PATH/sbin
chmod 750 $ROOTFS_PATH/sbin/*
if [ -f $ROOTFS_PATH/res/ext/99SuperSUDaemon ]; then
        chmod 755 $ROOTFS_PATH/res/ext/99SuperSUDaemon
fi
chmod 755 $ROOTFS_PATH/sys
chmod 755 $ROOTFS_PATH/system

find . -type f -name '*.h' -exec chmod 644 {} \;
find . -type f -name '*.c' -exec chmod 644 {} \;
find . -type f -name '*.py' -exec chmod 755 {} \;
find . -type f -name '*.sh' -exec chmod 755 {} \;
find . -type f -name '*.pl' -exec chmod 755 {} \;

echo "ramfs_tmp = $RAMFS_TMP"

echo "#################### Eliminando build anterior ####################"

find -name '*.ko' -exec rm -rf {} \;
rm -rf $KERNELDIR/arch/arm/boot/zImage > /dev/null 2>&1
rm -rf $KERNELDIR/arch/arm/boot/zImage-dtb > /dev/null 2>&1
rm -rf $KERNELDIR/arch/arm/boot/dt.img > /dev/null 2>&1
rm -rf $KERNELDIR/arch/arm/boot/*.img > /dev/null 2>&1
rm -rf $KERNELDIR/arch/arm/boot/dts/*.dtb > /dev/null 2>&1
rm -rf $KERNELDIR/arch/arm/boot/dts/*.reverse.dts > /dev/null 2>&1
rm $KERNELDIR/zImage > /dev/null 2>&1
rm $KERNELDIR/zImage-dtb > /dev/null 2>&1
rm $KERNELDIR/boot.dt.img > /dev/null 2>&1
rm $KERNELDIR/boot.img > /dev/null 2>&1
rm $KERNELDIR/*.ko > /dev/null 2>&1
rm $KERNELDIR/*.img > /dev/null 2>&1

echo "#################### Update Ramdisk ####################"
rm -f $KERNELDIR/releasetools/tar/$KERNEL_VERSION-$REVISION$KBUILD_BUILD_VERSION-$VERSION_KL.tar > /dev/null 2>&1
rm -f $KERNELDIR/releasetools/zip/$KERNEL_VERSION-$REVISION$KBUILD_BUILD_VERSION-$VERSION_KL.zip > /dev/null 2>&1
cp -f $KERNELDIR/arch/arm/boot/zImage . > /dev/null 2>&1
cp -f $KERNELDIR/arch/arm/boot/zImage-dtb . > /dev/null 2>&1

rm -rf $RAMFS_TMP > /dev/null 2>&1
rm -rf $RAMFS_TMP.cpio > /dev/null 2>&1
rm -rf $RAMFS_TMP.cpio.gz > /dev/null 2>&1
rm -rf $KERNELDIR/*.cpio > /dev/null 2>&1
rm -rf $KERNELDIR/*.cpio.gz > /dev/null 2>&1
cd $ROOTFS_PATH
cp -ax $ROOTFS_PATH $RAMFS_TMP
find $RAMFS_TMP -name .git -exec rm -rf {} \;
find $RAMFS_TMP -name EMPTY_DIRECTORY -exec rm -rf {} \;
find $RAMFS_TMP -name .EMPTY_DIRECTORY -exec rm -rf {} \;
rm -rf $RAMFS_TMP/tmp/* > /dev/null 2>&1
rm -rf $RAMFS_TMP/.hg > /dev/null 2>&1

echo "#################### Build Ramdisk ####################"

cd $RAMFS_TMP
find . | fakeroot cpio -o -H newc > $RAMFS_TMP.cpio 2>/dev/null
ls -lh $RAMFS_TMP.cpio
gzip -9 -f $RAMFS_TMP.cpio

echo "#################### Compilar Kernel ####################"

#compile kernel
cd $KERNELDIR

nice -n 10 make -j12 >> compile.log 2>&1 || exit -1

echo "#################### Generar nueva dt image ####################"

$TOOLBASE/dtbTool -o $KERNELDIR/arch/arm/boot/dt.img -s 4096 -p $KERNELDIR/scripts/dtc/ $KERNELDIR/arch/arm/boot/dts/
chmod a+r $KERNELDIR/arch/arm/boot/dt.img

echo "#################### Generar nuevo boot.img ####################"

$TOOLBASE/mkbootimg --base 0x0 --kernel $KERNELDIR/arch/arm/boot/zImage-dtb --ramdisk $RAMFS_TMP.cpio.gz --cmdline 'console=null androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x37 ehci-hcd.park=3' --ramdisk_offset 0x2000000 --tags_offset 0x1e00000 --pagesize 4096 --dt $KERNELDIR/arch/arm/boot/dt.img -o $KERNELDIR/boot.img

if [ ! -d $ROOTFS_PATH/system/lib/modules ]; then
        mkdir -p $ROOTFS_PATH/system/lib/modules
fi

find . -name "*.ko" -exec mv {} . \;
find . -name '*.ko' -exec cp -av {} $ROOTFS_PATH/system/lib/modules/ \;
unzip $KERNELDIR/proprietary-modules/proprietary-modules.zip -d $ROOTFS_PATH/system/lib/modules/
${CROSS_COMPILE}strip --strip-unneeded ./*.ko
${CROSS_COMPILE}strip --strip-unneeded $ROOTFS_PATH/system/lib/modules/*.ko

echo "Started  : $start_time"
echo "Finished : `date +'%d/%m/%y %H:%M:%S'`"
find . -name "boot.img"
find . -name "*.ko"

echo "#################### Preparando flasheables ####################"

cp boot.img $KERNELDIR/releasetools/zip
cp boot.img $KERNELDIR/releasetools/tar

cd $KERNELDIR
cd releasetools/zip
zip -0 -r $KERNEL_VERSION-$REVISION$KBUILD_BUILD_VERSION-$VERSION_KL.zip *
cd ..
cd tar
tar cf $KERNEL_VERSION-$REVISION$KBUILD_BUILD_VERSION-$VERSION_KL.tar boot.img && ls -lh $KERNEL_VERSION-$REVISION$KBUILD_BUILD_VERSION-$VERSION_KL.tar

echo "#################### Eliminando restos ####################"

rm $KERNELDIR/releasetools/zip/boot.img > /dev/null 2>&1
rm $KERNELDIR/releasetools/tar/boot.img > /dev/null 2>&1
#rm $KERNELDIR/boot.img > /dev/null 2>&1
#rm $KERNELDIR/zImage > /dev/null 2>&1
#rm $KERNELDIR/zImage-dtb > /dev/null 2>&1
#rm $KERNELDIR/boot.dt.img > /dev/null 2>&1
#rm $KERNELDIR/arch/arm/boot/dt.img > /dev/null 2>&1
rm -rf /home/lonas/Kernel_Lonas/tmp/ramfs-source-sgs5 > /dev/null 2>&1
rm /home/lonas/Kernel_Lonas/tmp/ramfs-source-sgs5.cpio.gz > /dev/null 2>&1
echo "#################### Terminado ####################"
