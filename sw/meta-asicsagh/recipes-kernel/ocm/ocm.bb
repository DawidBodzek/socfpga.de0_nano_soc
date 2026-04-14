LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI:append := " \
    file://Makefile \
    file://ocm.c \
"

S = "${UNPACKDIR}"

inherit module
