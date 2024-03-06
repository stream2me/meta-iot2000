require recipes-core/images/core-image-minimal.bb
require recipes-core/images/core-image-iot2000.inc
require iot2000-custom-image.inc

mount_sdcard () {
    cat >> ${IMAGE_ROOTFS}/etc/fstab <<EOF
# Mount SDcard's FAT partition
/dev/mmcblk0p2	/media/card/	vfat	utf8,gid=100,umask=002	0 0

EOF
} 

create_extra_dirs() {
  mkdir -p ${IMAGE_ROOTFS}/media/card
  mkdir -p ${IMAGE_ROOTFS}/usr/libexec/mc/extfs.d
}

patch_00core() {
  sed -i '36,37 s/^/#/' ${IMAGE_ROOTFS}/etc/default/volatiles/00_core
}

#Zeitzone ändern
set_tz() {
  rm -rf ${IMAGE_ROOTFS}/etc/localtime
  ln -s /usr/share/zoneinfo/Europe/Berlin ${IMAGE_ROOTFS}/etc/localtime
}

add_cronjobs() {
  cat >> ${IMAGE_ROOTFS}/var/spool/cron/root <<EOF
@reboot (/bin/echo "*** $(uptime -s) System gestartet ***"; /bin/echo "Systemauslastung: "; top -b -i -n 1;) | tee -a /media/card/backup/system.log
@weekly (/bin/echo "*** $(date +\%F' '\%T) Systemauslastung: ***"; top -b -i -n 1;) | tee -a /media/card/backup/system.log

EOF
}

IMAGE_PREPROCESS_COMMAND += " \
			mount_sdcard; \
			patch_00core; \
			add_cronjobs; \
			set_tz; \
			create_extra_dirs; \
"
