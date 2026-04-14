FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI:append := " \
    file://defconfig \
    file://0001-arch-arm-boot-dts-socfpga_cyclone5_de0_nano_soc-fpga.patch \
"

unset KBUILD_DEFCONFIG
KERNEL_DEFCONFIG = "${WORKDIR}/defconfig"
