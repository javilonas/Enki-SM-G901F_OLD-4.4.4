#!/bin/sh
# Build Script: Javilonas, 23-01-2015
# Javilonas <admin@lonasdigital.com>
#
start_time=`date +'%d/%m/%y %H:%M:%S'`
echo "#################### Eliminando Restos ####################"
./clean.sh > /dev/null 2>&1
echo "#################### Preparando Entorno ####################"
export KERNELDIR=`readlink -f .`
export RAMFS_SOURCE=`readlink -f $KERNELDIR/ramdisk`
export TOOLBASE="/home/lonas/Kernel_Lonas/Enki-SM-G901F/buildtools"
export USE_SEC_FIPS_MODE=true

if [ "${1}" != "" ];then
  export KERNELDIR=`readlink -f ${1}`
fi

TOOLCHAIN="/home/lonas/Kernel_Lonas/toolchains/arm-eabi-4.8/bin/arm-eabi-"
TOOLCHAIN_PATCH="/home/lonas/Kernel_Lonas/toolchains/arm-eabi-4.8/bin"
ROOTFS_PATH="/home/lonas/Kernel_Lonas/Enki-SM-G901F/ramdisk"
RAMFS_TMP="/home/lonas/Kernel_Lonas/tmp/ramfs-source-sgs5"

export KERNEL_VERSION="Enki-0.1"
export VERSION_KL="SM-G901F"
export REVISION="RC"

export KBUILD_BUILD_VERSION="1"

export KCONFIG_NOTIMESTAMP=true
export ARCH=arm

export BOARD_VENDOR=samsung
export TARGET_ARCH=arm
export TARGET_NO_BOOTLOADER=true
export TARGET_BOARD_PLATFORM=apq8084
export TARGET_CPU_ABI=armeabi-v7a
export TARGET_CPU_ABI2=armeabi
export TARGET_ARCH_VARIANT=armv7-a-neon
export TARGET_CPU_VARIANT=krait
export ARCH_ARM_HAVE_TLS_REGISTER=true
export TARGET_BOARD_PLATFORM_GPU=qcom-adreno420
export TARGET_BOOTLOADER_BOARD_NAME=APQ8084
export TARGET_CPU_SMP=true
export TARGET_GLOBAL_CFLAGS=-mfpu=neon-vfpv4
export TARGET_GLOBAL_CFLAGS=-mfloat-abi=softfp
export TARGET_GLOBAL_CPPFLAGS=-mfpu=neon-vfpv4
export TARGET_GLOBAL_CPPFLAGS=-mfloat-abi=softfp

export COMMON_GLOBAL_CFLAGS=-DQCOM_HARDWARE


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
chmod 750 $ROOTFS_PATH/sbin/adbd*
chmod 750 $ROOTFS_PATH/sbin/healthd

find . -type f -name '*.h' -exec chmod 644 {} \;
find . -type f -name '*.c' -exec chmod 644 {} \;
find . -type f -name '*.py' -exec chmod 755 {} \;
find . -type f -name '*.sh' -exec chmod 755 {} \;
find . -type f -name '*.pl' -exec chmod 755 {} \;

chmod 700 $ROOTFS_PATH/sbin/post-boot.sh

echo "ramfs_tmp = $RAMFS_TMP"

echo "#################### Eliminando build anterior ####################"
make ARCH=arm CROSS_COMPILE=$TOOLCHAIN -j`grep 'processor' /proc/cpuinfo | wc -l` mrproper
make ARCH=arm CROSS_COMPILE=$TOOLCHAIN -j`grep 'processor' /proc/cpuinfo | wc -l` clean

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

echo "#################### Make defconfig ####################"
make ARCH=arm CROSS_COMPILE=$TOOLCHAIN apq8084_lonas_defconfig KCONFIG_VARIANT= KCONFIG_DEBUG= KCONFIG_LOG_SELINUX= KCONFIG_SELINUX= KCONFIG_TIMA= KCONFIG_DMVERITY= 
#make ARCH=arm CROSS_COMPILE=$TOOLCHAIN apq8084_sec_defconfig VARIANT_DEFCONFIG=apq8084_sec_kccat6_eur_defconfig DEBUG_DEFCONFIG=apq8084_sec_userdebug_defconfig TIMA_DEFCONFIG=tima_defconfig DMVERITY_DEFCONFIG=dmverity_defconfig SELINUX_LOG_DEFCONFIG=selinux_log_defconfig SELINUX_DEFCONFIG=selinux_defconfig

#nice -n 10 make -j7 ARCH=arm CROSS_COMPILE=$TOOLCHAIN || exit -1

nice -n 10 make -j6 ARCH=arm CROSS_COMPILE=$TOOLCHAIN >> compile.log 2>&1 || exit -1

make -j`grep 'processor' /proc/cpuinfo | wc -l` ARCH=arm CROSS_COMPILE=$TOOLCHAIN >> compile.log 2>&1 || exit -1

#make -j`grep 'processor' /proc/cpuinfo | wc -l` ARCH=arm CROSS_COMPILE=$TOOLCHAIN || exit -1


#if [ ! -d $ROOTFS_PATH/system/lib/modules ]; then
#        mkdir -p $ROOTFS_PATH/system/lib/modules
#fi

find . -name "*.ko" -exec mv {} . \;
#find . -name '*.ko' -exec cp -av {} $ROOTFS_PATH/system/lib/modules/ \;
#unzip $KERNELDIR/proprietary-modules/proprietary-modules.zip -d $ROOTFS_PATH/system/lib/modules/
${CROSS_COMPILE}strip --strip-unneeded ./*.ko
#${CROSS_COMPILE}strip --strip-unneeded $ROOTFS_PATH/system/lib/modules/*.ko

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

cd $KERNELDIR

nice -n 10 make -j6 ARCH=arm CROSS_COMPILE=$TOOLCHAIN zImage-dtb || exit 1

echo "#################### Generar nueva dt image ####################"

$TOOLBASE/dtbTool -o $KERNELDIR/arch/arm/boot/dt.img -s 4096 -p $KERNELDIR/scripts/dtc/ $KERNELDIR/arch/arm/boot/dts/
chmod a+r $KERNELDIR/arch/arm/boot/dt.img

echo "#################### Generar nuevo boot.img ####################"

$TOOLBASE/mkbootimg --base 0x00000000 --kernel $KERNELDIR/arch/arm/boot/zImage-dtb --kernel_offset 0x00008000 --ramdisk $RAMFS_TMP.cpio.gz --cmdline 'console=ttyHSL0,115200,n8 androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x37 ehci-hcd.park=3 dwc3_msm.cpu_to_affin=1' --ramdisk_offset 0x02200000 --tags_offset 0x02000000 --pagesize 4096 --dt $KERNELDIR/arch/arm/boot/dt.img -o $KERNELDIR/boot.img

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
rm -rf /home/lonas/Kernel_Lonas/tmp/ramfs-source-sgs5 > /dev/null 2>&1
rm /home/lonas/Kernel_Lonas/tmp/ramfs-source-sgs5.cpio.gz > /dev/null 2>&1
echo "#################### Terminado ####################"
