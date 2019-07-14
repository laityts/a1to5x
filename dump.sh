#!/bin/bash
if [ -f images.gz-dtb ]; then
    rm images.gz-dtb
    rm kernel
fi
rm -rf mkbootimg/boot
rm mkbootimg/boot.img
mv *tissot*.zip payload_dumper
cd payload_dumper
if [ -d output ]; then
    rm -rf output
    mkdir output
else
    mkdir output
fi
mkdir zipout
unzip *tissot*.zip -d zipout
mv zipout/payload.bin payload.bin
mv *tissot*.zip ~/tools/a1to5x
rm -rf zipout
python3 payload_dumper.py payload.bin
cp output/boot.img ~/tools/a1to5x/mkbootimg
cd ~/tools/a1to5x/mkbootimg
./mkboot boot.img boot
cd boot
mv kernel ~/tools/a1to5x/images.gz-dtb
cd ~/tools/a1to5x
./split-appended-dtb images.gz-dtb
if [ -d dtbs ]; then
    rm -rf output
    mkdir dtbs
else
    mkdir dtbs
fi
if [ -f dtbdump_2.dtb ]; then
dtc -I dtb -O dts -o dtbs/dtbdump_1.dts dtbdump_1.dtb
dtc -I dtb -O dts -o dtbs/dtbdump_2.dts dtbdump_2.dtb
dtc -I dtb -O dts -o dtbs/dtbdump_3.dts dtbdump_3.dtb
dtc -I dtb -O dts -o dtbs/dtbdump_4.dts dtbdump_4.dtb
dtc -I dtb -O dts -o dtbs/dtbdump_5.dts dtbdump_5.dtb
else
dtc -I dtb -O dts -o dtbs/dtbdump_1.dts dtbdump_1.dtb
fi
rm *.dtb
