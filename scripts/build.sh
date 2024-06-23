
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

# dd if=/dev/zero of=bin/fat32.img bs=128K count=2
python scripts/build-fs.py

# Start by compiling the bootloader
./nasm/nasm.exe -f bin src/bootloader.asm -o bin/bootloader.img
