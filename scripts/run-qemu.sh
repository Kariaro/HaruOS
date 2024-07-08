# Set running directory to parent folder to prevent wrong working space
cd $(dirname $(realpath "$0"))/..

export PATH="/d/msys64/mingw64/bin:${PATH}"

./scripts/build.sh

qemu-system-x86_64 \
	-S -s \
	-drive index=0,format=raw,if=floppy,file=bin/bootloader.img \
	-drive index=1,format=raw,if=floppy,file=bin/fat32.img &

gdb -ex 'target remote localhost:1234' \
    -ex 'set architecture i8086' \
    -ex 'break *0x7c02' \
    -ex 'layout asm'
