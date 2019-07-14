#!/bin/bash
cd mkbootimg
./mkboot boot.img boot
cd boot
mv kernel ~/tools/a1to5x/images.gz-dtb
cd ~/tools/a1to5x
./split-appended-dtb images.gz-dtb
dtc -I dtb -O dts -o dtbdump_1.dts dtbdump_1.dtb
