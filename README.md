# socfpga.de0_nano_soc

## Clone repository
```bash
git clone --recursive git@github.com:asicsagh/socfpga.de0_nano_soc.git
```

## Environment initialization
```bash
. env.sh
```

## FPGA bitfile generation
```bash
hw_generator.sh
```

## System image generation
```bash
bitbake asicsagh-image-minimal
```

## Device programming

### SD card preparation
To prepare an SD card, download a generated system image file
(`sw/build/tmp/deploy/images/de0-nano-soc/asicsagh-image-minimal-de0-nano-soc.rootfs.wic`)
on your local machine using e.g. `scp`. Then write this file to the SD card using
[_Win32 Disk Imager_](http://sourceforge.net/projects/win32diskimager/) or `dd`.

### Board preparation
Before powering up a device, confirm that `MSEL` pins (`SW10`) are set to `6'b0`. Then plug-in the
SD card and connect a USB cable to the `J4` connector (it enables serial port data transmission).

### Linux login prompt
You can access the Linux prompt via serial connection using username `root`. Password is not
required.
