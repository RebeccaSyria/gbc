mygame.gb: mygame.o
	rgblink -o mygame.gb mygame.o
	rgbfix -v -p 0 mygame.gb
mygame.o: mygame.asm
	rgbasm -o mygame.o mygame.asm

