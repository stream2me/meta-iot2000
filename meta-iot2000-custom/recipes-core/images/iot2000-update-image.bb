DESCRIPTION = "iot2000 custom update image"

DEPENDS += "iot2000-custom-image-swu"

SRC_URI = "file://sw-description"

IMAGE_DEPENDS = "iot2000-custom-image-swu"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

SWUPDATE_IMAGES = "iot2000-custom-image-swu bzImage"

SWUPDATE_IMAGES_FSTYPES[iot2000-custom-image-swu] = ".ext4.gz"
SWUPDATE_IMAGES_NOAPPEND_MACHINE[bzImage] = "1"

inherit swupdate
