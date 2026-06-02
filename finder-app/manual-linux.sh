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

echo "Adding the Image in outdir"
# 1.d: cp built files (per 1.c above) into OUTDIR (if not already done in 1.c)

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
    echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# 1.e: Create necessary base directories
ROOTFS=${OUTDIR}/rootfs
mkdir -p ${ROOTFS} ${ROOTFS}/bin ${ROOTFS}/dev ${ROOTFS}/etc ${ROOTFS}/home ${ROOTFS}/lib ${ROOTFS}/lib64 ${ROOTFS}/proc ${ROOTFS}/sbin ${ROOTFS}/sys ${ROOTFS}/tmp ${ROOTFS}/usr ${ROOTFS}/var ${ROOTFS}/usr/bin ${ROOTFS}/usr/sbin ${ROOTFS}/usr/lib ${ROOTFS}/var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}

    # Configure & build busybox
    make distclean
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
    # make install # necessary???
else
    cd busybox
fi

# Install busybox
cp ${OUTDIR}/busybox/busybox ${OUTDIR}/bin


echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs

# TODO: Make device nodes (is necessary for assigment 3p2?)

# TODO 1.f: Clean and build the writer utility

# TODO 1.f: Copy the finder related scripts and executables to the /home directory
# on the target rootfs

# TODO 1.g: cp `autorun-qemu.sh` into OUTDIR/rootfs/home

# TODO: Chown the root directory

# TODO 1.h: Create initramfs.cpio.gz
