#!/bin/bash -e

if [[ -z ${ROOTDIR} ]]; then
    echo "ERROR: environment not initialized"
    exit 1
fi

cd ${ROOTDIR}/hw/fpga
git clean -fXd .

quartus_sh --flow compile de0_nano_soc
quartus_cpf -c de0_nano_soc.cof
