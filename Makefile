project.gb: project.o
	rgblink -o project.gb project.o
	rgbfix -v -p 0 project.gb
project.o: project.asm
	rgbasm -o project.o project.asm

