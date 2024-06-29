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


## Booting

Steps of STAGE1
1. Set CS to `0x0000:0x7C00`
1. Set stack to `0x0000:0xFFFF`
1. Read `STAGE2.BIN` to `0x0000:0x0600`

Steps of STAGE2
1. Enter protected mode
1. Read sectors of KERNEL.BIN
1. ??????
1. Enter long mode
1. ??????
1. Jump to `kernel_main` from long mode
