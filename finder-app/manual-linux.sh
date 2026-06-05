#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
SYSROOT=/opt/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu
INITRAM_FILE=initramfs.cpio

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
	# 1.c(i)(1): Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # 1.c: Build kernel
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} Image
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

# 1.d: cp built files (per 1.c above) into OUTDIR (if not already done in 1.c)
echo "Adding the Image in outdir"
cd "$OUTDIR"
cp linux-stable/arch/${ARCH}/boot/Image .

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
    echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
    rm ${OUTDIR}/${INITRAM_FILE}.gz
fi

# 1.e: Create necessary base directories
ROOTFS=${OUTDIR}/rootfs
mkdir -p ${ROOTFS} ${ROOTFS}/bin ${ROOTFS}/dev ${ROOTFS}/etc ${ROOTFS}/home ${ROOTFS}/lib ${ROOTFS}/lib64 ${ROOTFS}/proc ${ROOTFS}/sbin ${ROOTFS}/sys ${ROOTFS}/tmp ${ROOTFS}/usr ${ROOTFS}/var ${ROOTFS}/usr/bin ${ROOTFS}/usr/sbin ${ROOTFS}/usr/lib ${ROOTFS}/var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
    git clone git://busybox.net/busybox.git # https://git.busybox.net/busybox.git #git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
else
    cd busybox
fi

# Configure & build busybox
make distclean
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${ROOTFS} ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "Library dependencies"
cd "$ROOTFS"
echo "PWD: " $(pwd)
${CROSS_COMPILE}readelf -a ./bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ./bin/busybox | grep "Shared library"

# Add library dependencies to rootfs
cd ${SYSROOT}/libc
# this list is hardcoded ... prefer automatic gen from above grep commands
for f in lib/ld-linux-aarch64.so.1 lib64/libm.so.6 lib64/libresolv.so.2 lib64/libc.so.6 ; do
	cp --parents $f ${ROOTFS}
done

# TODO: Make device nodes (is this really necessary for assigment 3p2?)

# 1.f: Clean and build the writer utility
cd ${FINDER_APP_DIR}
echo "PWD: $(pwd)"
make clean
make writer
make DEST=${ROOTFS}/home install

# 1.f: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
# 1.g: cp `autorun-qemu.sh` into OUTDIR/rootfs/home
mkdir -p ${ROOTFS}/home/conf
for f in start-qemu-app.sh start-qemu-terminal.sh finder-test.sh autorun-qemu.sh conf/username.txt conf/assignment.txt ; do
	cp --parents $f ${ROOTFS}/home
done

# Chown the root directory
cd ${ROOTFS}
sudo chown -R root:root *

# 1.h: Create initramfs.cpio.gz
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/${INITRAM_FILE}
cd ${OUTDIR}
gzip -f ${INITRAM_FILE}
