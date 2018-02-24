INCLUDE "gbhw.inc" ; hardware defs from devrs.com
INCLUDE "ibmpc1.inc" ; ASCII chars from devrs.com


SECTION "Vblank", ROM0[$0040]
	reti
SECTION "LCDC", ROM0[$0048]
	reti
SECTION "Timer_Overflow", ROM0[$0050]
	reti
SECTION "Serial", ROM0[$0058]
	reti
SECTION "p1thru4", ROM0[$0060]
	reti

SECTION "start", ROM0[$0100]
nop
jp	begin ; jump over rom header to beginning

;ROM HEADER
	NINTENDO_LOGO ; macro from gbhw
	DB "PROJECT",0,0,0,0,0,0,0,0 ; cart name
	DB 0 
	DB 0,0 ; licensee code
	DB 0 ; SGB support indicator
	DB 0 ; cart type
	DB 0 ; ROM Size 
	DB 0 ; RAM Size
	DB 1 ; Destination code
	DB $33 ; Old Licensee code
	DB 0 ; Mask ROM version
	DB 0 ; Complement check
	DW 0 ; Checksum
;END ROM HEADER

INCLUDE "memory.asm" ; tools for copying to/from RAM from devrs.com
 
TileData:
	chr_IBMPC1	1,8 

begin:
	di ; disable interrupts
	ld	sp, $ffff ; set stack pointer to highest mem location +1
init:
	ld	a, %11100100 ; load bg pallet into a
	ld	[rBGP], a ; load pallet from a to rBGP
	ld	a,0 ; load 0 into a
	ld 	[rSCX], a ; load 0 from a to scroll X
	ld	[rSCY], a ; load 0 from a to scroll Y
	call	StopLCD ; turn off LCD so we can write to vRAM 
	ld	hl, TileData ; load character set into hl
	ld	de, _VRAM ; load vRAM location in`to de 
	ld	bc, 8*256 ; load size of the character set into bc
	call	mem_CopyMono ; call mem_CopyMono, hl - source, de - destination, bc - size
	;turn LCD back on 
	ld	a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ16|LCDCF_OBJOFF 
	ld	[rLCDC], a

	ld	a, 32 ; load ' ' into a 
	ld	hl, _SCRN0 ; load SCRN0 location into hl
	ld	bc, SCRN_VX_B * SCRN_VY_B ; load bytecount into bc 
	call	mem_SetVRAM ; call setVRAM a - value, hl - memory, bc - bytecount
	
	ld	hl, Title ; load title into hl
	ld	de, _SCRN0+3+(SCRN_VY_B*7) ; load location into de
	ld	bc, TitleEnd-Title ; load bytecount into bc 
	call	mem_CopyVRAM ; call to copyVRAM, hl - source, de - destination, bc - bytecount

; jump to an infite loop 
wait:
	call	ReadJoy
	ld	bc,$0fff
	call	Delay
	nop
	jr	wait

;label for title
Title:
	DB	"HECK THE WORLD!"
TitleEnd:

ScrollLEFT:
	ld	a, [rSCX]
	inc	a
	ld	[rSCX], a
	jp	ScrollLeftRet

ScrollRIGHT:
	ld	a, [rSCX]
	dec	a
	ld	[rSCX], a
	jp	ScrollRightRet


ScrollDOWN:
	ld	a, [rSCY]
	inc	a
	ld	[rSCY], a
	jp	ScrollDownRet

ScrollUP:
	ld	a, [rSCY]
	dec	a
	ld	[rSCY], a
	jp	ScrollUpRet

ReadJoy:
	push	bc
	ld	a, P1F_5 ;get joypad
	ld	[rP1], a ;save to a 
	ld	a, [rP1] ;read keypress reg multiple times 
	ld	a, [rP1] 
	ld	a, [rP1]
	cpl	; invert
	ld	b, a 
	;test Right Key
	and	$01
	cp	$01 
	jr	z, ScrollRIGHT
ScrollRightRet:
	;test left key
	ld	a, b
	and	$02
	cp	$02
	jr	z, ScrollLEFT
ScrollLeftRet:
	;test down key
	ld	a, b
	and	$04
	cp	$04
	jr	z, ScrollDOWN
ScrollDownRet:
	;test up key
	ld	a, b
	and	$08
	cp	$08
	jr	z, ScrollUP
ScrollUpRet:
	pop	bc
	ret

;turn off the LCD
StopLCD:
	ld	a, [rLCDC] ;load LCDC into a
	rlca	; rotate a left 1 bit, high bit is put into carry flag 
	ret	nc ;return if carry flag is 0, meaning LCD is off 

.wait:
	ld	a, [rLY] ; load rLY into a 
	cp	145 ; compare a with 145, flag bits are set
	jr	nz, .wait ; if the flag bits aren't 0, go back to .wait
	ld	a, [rLCDC] ; load rLCDC into a
	res	7, a	; reset bit 7
	ld	[rLCDC], a ; load a back into rLCDC
	ret	; return

Delay:
	dec	bc
	ld	a,b
	or	c
	jr	nz,Delay
	ret
