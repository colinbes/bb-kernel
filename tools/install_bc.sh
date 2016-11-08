#!/bin/sh
#script to be run from insertable SD card to update linux kernel to bone68a patched kernel.

KERNEL_UTS="3.8.13-bone68b"
valid_kernel="3.8.13-bone68a"

#DIR=$PWD
DIR='/media/runner'
LCD='/dev/tty0'

unset current_kernel
current_kernel=$(grep uname_r /boot/uEnv.txt | grep -v '#' | awk -F"=" '{print $2}' || true)

broadcast () {
	if [ "x${message}" != "x" ] ; then
		echo "${message}"
	    echo "${message}" > $LCD || true
    fi
}

message="Current Kernel $current_kernel";broadcast

if [ $current_kernel != $valid_kernel ]; then
        message="Invalid Kernel found, exiting...";broadcast
        exit 1
fi

mmc_write_rootfs () {
	message="Installing ${KERNEL_UTS}-modules.tar.gz";broadcast

	if [ -d "/lib/modules/${KERNEL_UTS}" ] ; then
		sudo rm -rf "/lib/modules/${KERNEL_UTS}" || true
	fi

	sudo tar xf "${DIR}/deploy/${KERNEL_UTS}-modules.tar.gz" -C "/"
	sync

	if [ -f "${DIR}/deploy/config-${KERNEL_UTS}" ] ; then
		if [ -f "/boot/config-${KERNEL_UTS}" ] ; then
			sudo rm -f "/boot/config-${KERNEL_UTS}" || true
		fi
		sudo cp -v "${DIR}/deploy/config-${KERNEL_UTS}" "/boot/config-${KERNEL_UTS}"
		sync
	fi
	message="update initramfs";broadcast
	sudo update-initramfs -ck ${KERNEL_UTS}
	message="info: [${KERNEL_UTS}] now installed...";broadcast
}

mmc_write_boot_uname () {
	message="Installing ${KERNEL_UTS}";broadcast

	if [ -f "${location}/vmlinuz-${KERNEL_UTS}_bak" ] ; then
		sudo rm -f "${location}/vmlinuz-${KERNEL_UTS}_bak" || true
	fi

	if [ -f "${location}/vmlinuz-${KERNEL_UTS}" ] ; then
		sudo mv "${location}/vmlinuz-${KERNEL_UTS}" "${location}/vmlinuz-${KERNEL_UTS}_bak"
	fi

	sudo cp -v "${DIR}/deploy/${KERNEL_UTS}.zImage" "${location}/vmlinuz-${KERNEL_UTS}"

	if [ -f "${location}/initrd.img-${KERNEL_UTS}" ] ; then
		sudo rm -rf "${location}/initrd.img-${KERNEL_UTS}" || true
	fi

	if [ -f "${DIR}/deploy/${KERNEL_UTS}-dtbs.tar.gz" ] ; then
		if [ -d "${location}/dtbs/${KERNEL_UTS}_bak/" ] ; then
			sudo rm -rf "${location}/dtbs/${KERNEL_UTS}_bak/" || true
		fi

		if [ -d "${location}/dtbs/${KERNEL_UTS}/" ] ; then
			sudo mv "${location}/dtbs/${KERNEL_UTS}/" "${location}/dtbs/${KERNEL_UTS}_bak/" || true
		fi

		sudo mkdir -p "${location}/dtbs/${KERNEL_UTS}/"

		message="Installing ${KERNEL_UTS}-dtbs.tar.gz to ${location}/dtbs/${KERNEL_UTS}";broadcast
		sudo tar xf "${DIR}/deploy/${KERNEL_UTS}-dtbs.tar.gz" -C "${location}/dtbs/${KERNEL_UTS}/"
		sync
	fi

	unset older_kernel
	older_kernel=$(grep uname_r "${location}/uEnv.txt" | grep -v '#' | awk -F"=" '{print $2}' || true)

	if [ ! "x${older_kernel}" = "x" ] ; then
		if [ ! "x${older_kernel}" = "x${KERNEL_UTS}" ] ; then
			sudo sed -i -e 's:uname_r='${older_kernel}':uname_r='${KERNEL_UTS}':g' "${location}/uEnv.txt"
		fi
		message="info: /boot/uEnv.txt: `grep uname_r ${location}/uEnv.txt`";broadcast
	fi
}

if [ -f "/boot/uEnv.txt" ] ; then
	location="/boot/"
	mmc_write_boot_uname
	location=""
	mmc_write_rootfs
	sync
else
	message="ERROR, /boot/uEnv.txt not found!";broadcast
	exit 1
fi



