#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

./RootStock-NG.sh -c ledscape-debian-jessie-console-v4.4

 debian_jessie_console="debian-8.8-console-ledscape-armhf-${time}"

archive="xz -z -2 -v"

beaglebone="--dtb beaglebone --bbb-old-bootloader-in-emmc --hostname ledscape-bbb"

beaglebone_console="--dtb beaglebone --bbb-old-bootloader-in-emmc \
--hostname ledscape-bbb"

bb_blank_flasher_console="--dtb bbb-blank-eeprom --bbb-old-bootloader-in-emmc \
--hostname ledscape-bbb"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

archive_base_rootfs () {
        if [ -d ./\${base_rootfs} ] ; then
                rm -rf \${base_rootfs} || true
        fi
        if [ -f \${base_rootfs}.tar ] ; then
                ${archive} \${base_rootfs}.tar && sha256sum \${base_rootfs}.tar.xz > \${base_rootfs}.tar.xz.sha256sum &
        fi
}

extract_base_rootfs () {
        if [ -d ./\${base_rootfs} ] ; then
                rm -rf \${base_rootfs} || true
        fi

        if [ -f \${base_rootfs}.tar.xz ] ; then
                tar xf \${base_rootfs}.tar.xz
        else
                tar xf \${base_rootfs}.tar
        fi
}

archive_img () {
	#prevent xz warning for 'Cannot set the file group: Operation not permitted'
	sudo chown \${UID}:\${GROUPS} \${wfile}.img
        if [ -f \${wfile}.img ] ; then
                if [ ! -f \${wfile}.bmap ] ; then
                        if [ -f /usr/bin/bmaptool ] ; then
                                bmaptool create -o \${wfile}.bmap \${wfile}.img
                        fi
                fi
                ${archive} \${wfile}.img && sha256sum \${wfile}.img.xz > \${wfile}.img.xz.sha256sum &
        fi
}

generate_img () {
        cd \${base_rootfs}/
        sudo ./setup_sdcard.sh \${options}
        mv *.img ../
        mv *.job.txt ../
        cd ..
}

###console images: (also single partition)
base_rootfs="${debian_jessie_console}" ; blend="console" ; extract_base_rootfs

options="--img-2gb BBB-eMMC-flasher-\${base_rootfs} ${beaglebone_console} --emmc-flasher" ; generate_img
options="--img-2gb bone-\${base_rootfs} ${beaglebone_console}" ; generate_img

###archive *.tar
base_rootfs="${debian_jessie_console}" ; blend="console" ; archive_base_rootfs

blend="console"
wfile="BBB-eMMC-flasher-${debian_jessie_console}-2gb" ; archive_img
wfile="bone-${debian_jessie_console}-2gb" ; archive_img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh
