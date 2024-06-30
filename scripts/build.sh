
# Set running directory to parent folder to prevent wrong working space
cd $(dirname $(realpath "$0"))/..

# Create tools directory
mkdir -p .tools

# Clear build directory
rm -rf bin/*
mkdir -p bin
mkdir -p bin/fat32
mkdir -p bin/gcc

# Setup python venv
if [ ! -d ".tools/.venv" ]; then
	echo "Setting up Python venv"
	python -m venv .tools/.venv
	source .tools/.venv/scripts/activate
	pip install -r requirements.txt
fi
source .tools/.venv/scripts/activate

export PATH=".tools/nasm:${PATH}"
export PATH=".tools/gcc/bin:${PATH}"
# export PATH="d/msys64/mingw64/bin:${PATH}"

# Start by compiling the bootloader
set -x
nasm -f bin src/bios_legacy/stage1.asm -o bin/bootloader.img
nasm -f bin src/bios_legacy/stage2.asm -o bin/stage2.bin -Isrc/bios_legacy
nasm -f bin src/bios_legacy/boot_test.asm -o bin/stage3.bin -Isrc/bios_legacy

x86_64-elf-gcc -c src/kernel/kernel.c -o bin/gcc/kernel.o -ffreestanding -nostdlib -nostdinc
# strip -O elf64-little -o bin/gcc/kernel_elf64.o bin/gcc/kernel.o

# ld -vvv -m i386ep -o bin/gcc/kernel_ld.o -Ttext 0x1000 bin/gcc/kernel.o
# ld -m elf64-little -T src/bios/link.ld -o kernel

python scripts/build-fs.py
