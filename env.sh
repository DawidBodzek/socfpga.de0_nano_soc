#!/bin/bash -e

export ROOTDIR=$(pwd)

if [[ ! -d ${ROOTDIR}/sw/buildtools ]]; then
    ${ROOTDIR}/sw/poky/scripts/install-buildtools --dir ${ROOTDIR}/sw/buildtools
fi

export QUARTUS_ROOTDIR=/opt/altera_lite/25.1std/quartus
export PATH=${ROOTDIR}/tools:${QUARTUS_ROOTDIR}/bin:${PATH}

cd ${ROOTDIR}/sw

. buildtools/environment-setup-x86_64-pokysdk-linux
. poky/oe-init-build-env build

if [[ ! -e conf/site.conf ]]; then
    cat <<-EOF > conf/site.conf
DISTRO = "asicsagh-poky"
MACHINE = "de0-nano-soc"
DL_DIR = "\${TOPDIR}/../downloads"
SSTATE_DIR = "\${TOPDIR}/../sstate_cache"
EOF

    cat <<-EOF >> conf/bblayers.conf
BBLAYERS += " \\
    \${TOPDIR}/../meta-asicsagh \\
    \${TOPDIR}/../meta-intel-fpga \\
    \${TOPDIR}/../meta-openembedded/meta-oe \\
    \${TOPDIR}/../meta-openembedded/meta-python \\
"
EOF
fi
