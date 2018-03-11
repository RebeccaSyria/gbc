project.gb: project.o
	rgblink -o mygame.gb mygame.o
	rgbfix -v -p 0 mygame.gb
project.o: project.asm
	rgbasm -o mygame.o mygame.asm

