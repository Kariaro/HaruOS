
# Set running directory to parent folder to prevent wrong working space
cd $(dirname $(realpath "$0"))/..

# Clear build directory
rm -rf bin/*
mkdir -p bin
mkdir -p bin/fat32

# Setup python venv
if [ ! -d ".venv" ]; then
	python -m venv .venv
	source .venv/scripts/activate
	pip install -r requirements.txt
fi
source .venv/scripts/activate

# Start by compiling the bootloader
./nasm/nasm.exe -f bin src/bios/stage1.asm -o bin/bootloader.img
./nasm/nasm.exe -f bin src/bios/stage2.asm -o bin/stage2.bin

# dd if=/dev/zero of=bin/fat32.img bs=128K count=2
python scripts/build-fs.py
