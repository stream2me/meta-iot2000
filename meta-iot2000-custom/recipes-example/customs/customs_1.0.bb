SUMMARY = "Make custom changes in file system"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${IOT2000_MIT_LICENSE};md5=838c366f69b72c5df05c96dff79b35f2"

inherit update-rc.d

SRC_URI = " \
	file://installFlow.sh \
        file://99-usb-auto-mount.rules \
        file://resolv.conf \
        "

FILES_${PN} += " \
        ${sysconfdir}/init.d/installFlow.sh \
	${sysconfdir}/udev/rules.d/99-usb-auto-mount.rules \
	${sysconfdir}/resolv.conf \
"

INITSCRIPT_NAME = "installFlow.sh"

do_install() {
	install -d ${D}${sysconfdir}/init.d
	install -m 0755 ${WORKDIR}/installFlow.sh ${D}${sysconfdir}/init.d/installFlow.sh

	install -d ${D}${sysconfdir}/udev/rules.d
	install -m 0644 ${WORKDIR}/99-usb-auto-mount.rules ${D}${sysconfdir}/udev/rules.d/99-usb-auto-mount.rules

	install -d ${D}{sysconfdir}
	install -m 0644 ${WORKDIR}/resolv.conf ${D}${sysconfdir}/resolv.conf
}
