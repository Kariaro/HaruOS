# HaruOS

This is a two stage bootloader

## Setup

Install nasm and elf tools on windows
```
https://www.nasm.us/pub/nasm/releasebuilds/2.16.03/
```

```
https://github.com/lordmilko/i686-elf-tools/releases/tag/13.2.0
```

## Building

```shmingw64-x86_64-gcc-g++ 
./scripts/build.sh
```

This will generate a FAT32 image with the first and second stage bootloaders
