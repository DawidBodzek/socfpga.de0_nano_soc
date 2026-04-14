FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI:append := " \
    file://bootcmd.cfg \
    file://de0_nano_soc.rbf \
    file://hps_isw_handoff \
    file://u-boot.txt \
    file://0001-include-configs-socfpga_common-support-for-netboot-a.patch \
"

do_compile:prepend() {
    python3 ${WORKDIR}/git/arch/arm/mach-socfpga/cv_bsp_generator/cv_bsp_generator.py \
        -i ${UNPACKDIR}/hps_isw_handoff/de0_nano_soc_hps \
        -o ${WORKDIR}/git/board/altera/cyclone5-socdk/qts

    mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Cyclone5 script" \
        -d  ${UNPACKDIR}/u-boot.txt ${WORKDIR}/u-boot.scr
}

do_deploy:append() {
    install -m 644 ${UNPACKDIR}/de0_nano_soc.rbf ${DEPLOYDIR}
    install -m 644 ${WORKDIR}/u-boot.scr ${DEPLOYDIR}
}
