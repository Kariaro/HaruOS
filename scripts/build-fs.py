from pyfatfs import PyFat
import fs

from os import listdir
from os.path import isfile, join
from pathlib import Path
import subprocess
import shutil

f = open("bin/fat32.img", "wb+")
f.close()

fat = PyFat.PyFat()
fat.mkfs(
	filename="bin/fat32.img",
	fat_type=fat.FAT_TYPE_FAT32,
	size=34 * 1024 * 1024, # 34 mB
	sector_size=512,
	number_of_fats=2,
	label='FAT32',
	volume_id=0,
	media_type=248)
fat.close()

# Compile assembly files in src/fat32
fat32_path = 'src/fat32'
fat32_files = [f for f in listdir(fat32_path) if isfile(join(fat32_path, f))]

fat32_image = fs.open_fs("fat://bin/fat32.img")
for file in fat32_files:
	if file.endswith('.bin'):
		raise Exception('.bin Names not allowed right now')
	elif file.endswith('.asm'):
		result_path = "bin/fat32/" + Path(file).stem + ".bin"
		result_name = Path(file).stem + ".bin"
		subprocess.run(["nasm/nasm.exe", "-f", "bin", fat32_path + "/" + file, "-o", result_path])
	else:
		result_path = "bin/fat32/" + file
		result_name = file
		shutil.copyfile(fat32_path + "/" + file, result_path)
	print(file, '->', result_path)
	fs.copy.copy_file("bin/fat32", result_name, fat32_image, result_name.upper())

fat32_image.close()

# with open("bin/fat32.img", "wb") as f:
# 	for i in range(1024 * 64):
# 		test = [((i + 1) // 256 ** x) % 256 for x in range(4)]
# 		f.write(bytearray(test))
# 		f.write(bytearray([0] * (512 - len(test))))
