DISTRO_VERSION_MAJOR ?= "1"
DISTRO_VERSION_MINOR ?= "0"
DISTRO_VERSION_PATCH ?= "0"
DISTRO_VERSION = "${DISTRO_VERSION_MAJOR}.${DISTRO_VERSION_MINOR}.${DISTRO_VERSION_PATCH}"

DISTRO_FEATURES:append = " \
    systemd \
    usrmerge \
"
DISTRO_FEATURES_BACKFILL_CONSIDERED:append = " \
    sysvinit \
"

PREFERRED_PROVIDER_virtual/kernel = "linux-socfpga-lts"
PREFERRED_VERSION_linux-socfpga-lts = "6.1%"

PREFERRED_PROVIDER_virtual/bootloader = "u-boot-socfpga"
PREFERRED_VERSION_u-boot-socfpga = "v2023.04%"

VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = "systemd-compat-units"
VIRTUAL-RUNTIME_login_manager = "shadow-base"
VIRTUAL-RUNTIME_dev_manager = "systemd"
