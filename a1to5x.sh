#!/bin/bash
shopt -s extglob

#path
path="$(cd "$(dirname "$0")";pwd)"
echo $path

if [ -d ramdisk ]; then
    rm -rf ramdisk
    rm -rf __MACOSX
fi
if [ -f image.gz-dtb ]; then
    rm image.gz-dtb
fi
rm -rf old
rm -rf output
mkdir output
mkdir zipout
unzip *.zip -d zipout
if [ -f zipout/payload.bin ]; then
    mv zipout/payload.bin payload_dumper
    rm -rf zipout
    cd payload_dumper
    if [ -d output ]; then
        rm -rf output
    fi
    mkdir output
    python3 payload_dumper.py payload.bin
    cd $path
    mv payload_dumper/output/boot.img mkbootimg
    mv payload_dumper/output/system.img ./
    rm payload_dumper/payload.bin
else
    mv zipout/boot.img mkbootimg
    mv zipout/system.img ./
    rm -rf zipout
fi

rm -rf mkbootimg/boot

cd $path/mkbootimg
./mkboot boot.img boot
cd ..

mkdir system
sudo mount system.img system
mkdir ramdisk
sudo mv system/!(system) ramdisk/.
mkdir ramdisk/system
rm -rf mkbootimg/boot/ramdisk/
mv ramdisk mkbootimg/boot/ramdisk
sudo mv system/system/* system/.

cd system
fstab="vendor/etc/fstab.qcom"
echo "fstab patching..."
sudo sed -i 's/,slotselect//g' $fstab
sudo sed -i 's/,verify//g' $fstab
sudo sed -i 's/forceencrypt/encryptable/g' $fstab
cp vendor/etc/fstab.qcom $path/output/
cd ..
sudo umount system
sudo rm -rf system

cd mkbootimg
sed -i 's/veritykeyid=id:\w*//g' boot/img_info

cp boot/img_info  $path/output/
mv boot/kernel boot/image.gz-dtb
mv boot/image.gz-dtb $path/image.gz-dtb
cd ..
echo "split..."
./split-appended-dtb image.gz-dtb
rm image.gz-dtb
if [ -f dtbdump_2.dtb ]; then
    echo "5 dtb"
    dtc -I dtb -O dts -o dtbdump_1.dts dtbdump_1.dtb
    dtc -I dtb -O dts -o dtbdump_2.dts dtbdump_2.dtb
    dtc -I dtb -O dts -o dtbdump_3.dts dtbdump_3.dtb
    dtc -I dtb -O dts -o dtbdump_4.dts dtbdump_4.dtb
    dtc -I dtb -O dts -o dtbdump_5.dts dtbdump_5.dtb
else
    echo "1 dtb"
    dtc -I dtb -O dts -o dtbdump_1.dts dtbdump_1.dtb
fi

rm *.dtb
sed -i '/parts/{n;d}' *.dts
sed -i '/vbmeta/d' *.dts
sed -i '/android,system/{n;d}' *.dts
sed -i '/android,system/{n;d}' *.dts
sed -i '/android,system/{n;d}' *.dts
sed -i '/android,system/d' *.dts
sed -i 'N;/\n.*,slotselect/!P;D' *.dts
sed -i '/,slotselect/{n;d}' *.dts
sed -i '/,slotselect/{n;d}' *.dts
sed -i '/,slotselect/d' *.dts
sed -i '/,fstab/a\				system {\
					compatible = "android,system";\
					dev = "/dev/block/platform/soc/7824900.sdhci/by-name/system";\
					type = "ext4";\
					mnt_flags = "ro,barrier=1,discard";\
					fsmgr_flags = "wait";\
					status = "ok";\
				};' *.dts
sed -i '/,fstab/a\\' *.dts
sed -i '/android,firmware/{n;d}' *.dts
sed -i 's/,avb//g' *.dts
sed -i '/,slotselect/{n;s/disable/ok/;}' *.dts
sed -i 's/,slotselect//g' *.dts

if [ -f dtbdump_2.dts ]; then
    echo "5 dts"
    dtc -I dts -O dtb -o dtbdump_1.dtb dtbdump_1.dts
    dtc -I dts -O dtb -o dtbdump_2.dtb dtbdump_2.dts
    dtc -I dts -O dtb -o dtbdump_3.dtb dtbdump_3.dts
    dtc -I dts -O dtb -o dtbdump_4.dtb dtbdump_4.dts
    dtc -I dts -O dtb -o dtbdump_5.dtb dtbdump_5.dts
else
    echo "1 dts"
    dtc -I dts -O dtb -o dtbdump_1.dtb dtbdump_1.dts
fi

mv *.dts output/
cat kernel *.dtb > image.gz-dtb
mv image.gz-dtb mkbootimg/boot/kernel
rm kernel
rm *.dtb
cd mkbootimg
sudo ./mkboot boot boot-new.img
cd ..
mv mkbootimg/boot-new.img output/boot.img
mv system.img output/system.img
cp -r template/* output/
cd output
zip -x *.dts -x fstab.qcom -x img_info -q -r tissot.zip *
cd ..
sudo rm -rf mkbootimg/boot
rm -rf mkbootimg/boot.img
if [ ! -d "old" ]; then
  mkdir old
fi
mv *.zip old/
cd old
fullname=*.zip
filename=$(basename $fullname)
cd ..
cd output
mv tissot.zip "[port]"$filename
cd ..
if [ -d "system" ]; then
  sudo umount system
  sudo rm -rf system
fi
