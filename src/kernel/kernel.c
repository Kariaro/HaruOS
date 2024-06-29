#include "kernel.h"

char* c_helloWorld = "Hello, World!";

void kernel_main(uint8_t a_bootDrive)
{
	uint8_t* vgaBuffer = (uint8_t*)(0xb8000);


	for(int i = 0; i < 12; i++)
	{
		vgaBuffer[i * 2 + 0] = c_helloWorld[i];
		vgaBuffer[i * 2 + 1] = 0;
	}
}
