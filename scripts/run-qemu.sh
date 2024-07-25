# Set running directory to parent folder to prevent wrong working space
cd $(dirname $(realpath "$0"))/..

export PATH="/d/msys64/mingw64/bin:${PATH}"

./scripts/build.sh

qemu-system-x86_64 \
    -nodefaults \
    -display gtk,show-tabs=on \
	-chardev stdio,id=char0 -mon chardev=char0,mode=readline \
    -vga std \
	-boot a \
    -serial vc \
	-drive format=raw,if=floppy,file=bin/bootloader.img \
	-drive index=0,format=raw,if=ide,file=bin/fat32.img
#   -debugcon stdio \
#	-usb -device usb-kbd -device usb-mouse
#	-S -s

exit

export PATH="/d/msys64/mingw64/bin:${PATH}"
gdb -ex 'target remote localhost:1234' \
    -ex 'break *0x7c00' \
	-ex 'continue' \
	-ex 'continue'


#    -ex 'layout asm'
