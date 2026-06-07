#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
ROOTFS=${OUTDIR}/rootfs
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
TRIPLE=aarch64-none-linux-gnu
CROSS_COMPILE=${TRIPLE}-
#arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu
TOOLCHAIN_VERSION=15.2.rel1
TOOLCHAIN=arm-gnu-toolchain-${TOOLCHAIN_VERSION}-x86_64-${TRIPLE}
SYSROOT=${OUTDIR}/${TOOLCHAIN}/${TRIPLE}
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

echo "Setting up Toolchain"
if [ ! -d "${SYSROOT}" ]; then
	echo "Installating ${TOOLCHAIN} into ${OUTDIR}"
	wget https://developer.arm.com/-/media/Files/downloads/gnu/${TOOLCHAIN_VERSION}/binrel/${TOOLCHAIN}.tar.xz
	mkdir -p ${SYSROOT}
	tar xJf ${TOOLCHAIN}.tar.xz -C . # ${SYSROOT}
	export PATH=${SYSROOT}:$PATH
fi

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
if [ -d "${ROOTFS}" ]
then
    echo "Deleting rootfs directory at ${ROOTFS} and starting over"
    sudo rm -rf ${ROOTFS}
    sudo rm -f ${OUTDIR}/${INITRAM_FILE}.gz
fi

# 1.e: Create necessary base directories
mkdir -p ${ROOTFS}
mkdir -p ${ROOTFS} ${ROOTFS}/bin ${ROOTFS}/dev ${ROOTFS}/etc ${ROOTFS}/home ${ROOTFS}/lib ${ROOTFS}/lib64 ${ROOTFS}/proc ${ROOTFS}/sbin ${ROOTFS}/sys ${ROOTFS}/tmp ${ROOTFS}/usr ${ROOTFS}/var ${ROOTFS}/usr/bin ${ROOTFS}/usr/sbin ${ROOTFS}/usr/lib ${ROOTFS}/var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
	attempts=0
	max_attempts=5

	until [ $attempts -ge $max_attempts ] || git clone git://busybox.net/busybox.git # https://git.busybox.net/busybox.git #git://busybox.net/busybox.git
	do
	    attempts=$((attempts+1))
	    echo "Attempt $attempts failed. Retrying..."
	    sleep 2
	done

	# Verify why the loop terminated
	if [ $attempts -ge $max_attempts ]; then
	    echo "Failed to clone busybox after $max_attempts attempts."
	    exit 1
	fi
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
# sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
# grep -q "CONFIG_STATIC=y" .config || echo "CONFIG_STATIC=y" >> .config

cd "${ROOTFS}"
echo "PWD: " $(pwd)
${CROSS_COMPILE}readelf -a ./bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ./bin/busybox | grep "Shared library"

# Add library dependencies to rootfs
# cd ${SYSROOT}
# echo "PWD: " $(pwd)
# this list is hardcoded ... prefer automatic gen from above grep commands
# for f in ld-linux-aarch64.so.1 libm.so.6 libresolv.so.2 libc.so.6 ; do
# 	cp --parents $(find ${SYSROOT} -type f -name "$f") ${ROOTFS}
# done
for f in ld-linux-aarch64.so.1 libm.so.6 libresolv.so.2 libc.so.6 ; do
	cp --parents $(find ${SYSROOT} -type f -name "$f") "${ROOTFS}"
done

# TODO: Make device nodes (is this really necessary for assigment 3p2?)

# 1.f: Clean and build the writer utility
cd ${FINDER_APP_DIR}
echo "PWD: $(pwd)"
make clean
make CROSS_COMPILE=${CROSS_COMPILE} writer
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
