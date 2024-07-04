# Calculate sectors

def get_from_mem(values):
	value = values[0]
	for i in range(1, len(values)):
		value = value * 512 + values[i]

	value = value * 4096
	if ((value >> 47) & 1) > 0:
		value = value | (~1 << 47)

	value = value & (2 ** 64 - 1)
	return value

def get_from_addr(value):
	# Get pages
	value = value // 4096

	values = []
	values.insert(0, value & 511)
	value = value >> 9
	values.insert(0, value & 511)
	value = value >> 9
	values.insert(0, value & 511)
	value = value >> 9
	values.insert(0, value & 511)
	return values



print(get_from_addr(0xffff_ffff_8000_0000))
print(hex(get_from_mem([511, 510, 0, 0])))
