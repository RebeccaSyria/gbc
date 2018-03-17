INCLUDE "gbhw.inc" ; hardware defs from devrs.com 

;sprite constants 
_SPR0_Y		EQU	_OAMRAM
_SPR0_X		EQU	_OAMRAM+1
_SPR0_NUM	EQU	_OAMRAM+2
_SPR0_ATT	EQU	_OAMRAM+3

_SPR1_Y		EQU	_OAMRAM+4
_SPR1_X		EQU	_OAMRAM+5
_SPR1_NUM	EQU	_OAMRAM+6
_SPR1_ATT	EQU	_OAMRAM+7

;when to move the sprite 
_MOVX	EQU	_RAM
_MOVY	EQU	_RAM+1

;Start program 
SECTION "start", ROM0[$0100]
nop 
jp	begin ;jump over rom header to beginning 

;ROM HEADER 
	NINTENDO_LOGO ; macro from gbhw 
	DB "MYGAME",0,0,0,0,0,0,0,0,0 ; cart name 
	DB 0
	DB 0,0 ; licensee code 
	DB 0 ; SGB support indicator  
	DB 0 ; cart type
	DB 0 ; ROM Size
	DB 1 ; Destination Code 
	DB $33 ; Old Licensee code 
	DB 0 ; Mask ROM version 
	DB 0 ; Complement check 
	DW 0 ; Checksum 
;END ROM HEADER 

begin:
	nop 
	di ; disable interupts 
	ld	sp, $ffff ; set stack pointer to highest mem loc + 1 
init:
	ld	a, %11100100 ; color pallet: 11, 10, 01, 00 
	ld	[rBGP], a ; load pallet from a to rBGP 
	ld	[rOBP0], a ; 
	ld	a, 0
	ld	[rSCX], a ; set scroll x to 0 
	ld	[rSCY], a ; set scroll y to 0 
	call	StopLCD ; turn off LCD 

	ld	hl, Tiles
	ld	de, _VRAM 
	ld	b, 48 ; bytes to copy(3 tiles) 
.load_loop:
	ld	a, [hl]
	ld	[de], a
	dec	b
	jr	z, .end_load_loop
	inc	hl
	inc	de
	jr	.load_loop
.end_load_loop:

	ld	hl, _SCRN0
	ld	de, 32*32
.clear_screen:
	ld	a, 0
	ld	[hl], a
	dec	de 
	ld	a, d
	or	e
	jp	z, .end_clear_screen
	inc	hl
	jp	z, .clear_screen
.end_clear_screen 

	ld	a, 30
	ld	[_SPR0_Y], a
	ld	a, 30
	ld	[_SPR0_X], a
	ld	a, 1
	ld	[_SPR0_NUM], a
	ld	a, 0 
	ld	[_SPR0_ATT], a

	ld	a, 50
	ld	[_SPR1_Y], a
	ld	a, 50
	ld	[_SPR1_X], a
	ld	a, 2
	ld	[_SPR1_NUM], a
	ld	a, 0
	ld	[_SPR1_ATT], a
	
	ld	a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON
	ld	[rLCDC], a

	ld	a, 1
	ld	[_MOVX], a
	ld	[_MOVY], a

animation: 
.wait:
	ld	a, [rLY]
	cp	145
	jr	nz, .wait
	call	ReadJoy
	ld	bc, $0fff
	call Delay
	jr animation


ReadJoy:
	push	bc ;save bc to stack 
	ld	a, P1F_5 ;get joypad, macro from devrs
	ld	[rP1], a
	ld	a, [rP1] ;get keypress multple times to account for hardware 
	ld	a, [rP1]
	ld	a, [rP1]
	ld	a, [rP1]
	cpl	;invert 
	ld	b, a
	;test Right Key
	and	$01
	cp	$01
	jr	z, MoveRight
MoveRightRet:
	;test Left key
	ld	a, b
	and	$02
	cp	$02
	jp	z, MoveLeft
MoveLeftRet:
	;test down key
	ld	a, b
	and	$04
	cp	$04
	jp	z, MoveDown
MoveDownRet:
	;test up key
	ld	a, b
	and	$08
	cp	$08
	jp	z, MoveUp
MoveUpRet:
	pop	bc ;return bc from stack
	ret 

MoveRight:
	ld	a, [_SPR0_X]
	cp	160 ;compare with right side of screen
	jr	z, MoveRightRet ;don't move if on edge
	ld	a, [_SPR1_X]
	sub	8
	ld	[hl], a
	ld	a, [_SPR0_X]
	cp	[hl]
	jr	z, TestRightCol
TestRightColRet:
	ld	a, [_SPR0_X]
	inc	a
	ld	[_SPR0_X], a
	jr	MoveRightRet

PushRight:
	ld	a, [_SPR1_X]
	cp	160
	jp	z, MoveRightRet
	inc	a
	ld	[_SPR1_X], a
	jp	TestRightColRet

TestRightCol:
	ld	a, [_SPR0_Y]
	ld	c, a ; sprite 0 Y into c
	ld	a, [_SPR1_Y]
	add	7
	ld	d, a ;sprite 1 Y plus 8 into d
	ld	b, 15
.RightColLoop:
	dec	d
	ld	a, d
	cp	c ;compare d(in a) with c
	jr	z, PushRight ;push the box if colliding in y 
	dec	b ; decrement b
	jr	z, TestRightColRet
	jr	.RightColLoop ;if not 0 loop back 
	
MoveLeft:
	ld	a, [_SPR0_X]
	cp	8 ;compare with left side of screen
	jp	z, MoveLeftRet ;don't move if on edge 
	ld	a, [_SPR1_X]
	add	8
	ld	[hl], a
	ld	a, [_SPR0_X]
	cp	[hl]
	jr	z, TestLeftCol
TestLeftColRet:
	ld	a, [_SPR0_X]
	dec	a
	ld	[_SPR0_X],a
	jp	MoveLeftRet

PushLeft:
	ld	a, [_SPR1_X]
	cp	7
	jp	z, MoveLeftRet
	dec	a
	ld	[_SPR1_X], a
	jr	TestLeftColRet

TestLeftCol:
	ld	a, [_SPR0_Y]
	ld	c, a
	ld	a, [_SPR1_Y]
	add	7
	ld	d, a
	ld	b, 14
.LeftColLoop:
	dec	d
	ld	a, d
	cp	c
	jr	z, PushLeft
	dec	b
	jr	z, TestLeftColRet
	jr	.LeftColLoop
	
MoveDown:
	ld	a, [_SPR0_Y]
	cp	16 ;compare with bottom of screen
	jp	z, MoveDownRet ;don't move if on edge
	ld	a, [_SPR1_Y]
	add	7
	ld	[hl], a
	ld	a, [_SPR0_Y]
	cp	[hl]
	jr	z, TestDownCol
TestDownColRet:
	ld	a, [_SPR0_Y]
	dec	a
	ld	[_SPR0_Y],a
	jp	MoveDownRet

PushDown:
	ld	a, [_SPR1_Y]
	cp	15
	jp	z, MoveDownRet
	dec	a
	ld	[_SPR1_Y], a
	jr	TestDownColRet


TestDownCol:
	ld	a, [_SPR0_X]
	ld	c, a
	ld	a, [_SPR1_X]
	add	7
	ld	d, a
	ld	b, 13
.DownColLoop:
	dec	d
	ld	a, d
	cp	c
	jr	z, PushDown
	dec	b
	jr	z, TestDownColRet
	jr	.DownColLoop
	
MoveUp:
	ld	a, [_SPR0_Y]
	cp	152 ;compare with top of screen 
	jp	z, MoveUpRet ;don't move if on edge 
	ld	a, [_SPR1_Y]
	sub	7
	ld	[hl], a
	ld	a, [_SPR0_Y]
	cp	[hl]
	jr	z, TestUpCol
TestUpColRet:
	ld	a, [_SPR0_Y]
	inc	a
	ld	[_SPR0_Y],a
	jp	MoveUpRet

PushUp:
	ld	a, [_SPR1_Y]
	cp	152
	jp	z, MoveUpRet
	inc	a
	ld	[_SPR1_Y], a
	jr	TestUpColRet

TestUpCol:
	ld	a, [_SPR0_X]
	ld	c, a
	ld	a, [_SPR1_X]
	add	7
	ld	d, a
	ld	b, 12
.UpColLoop:
	dec	d
	ld	a, d
	cp	c
	jr	z, PushUp
	dec	b
	jr	z, TestUpColRet
	jr	.UpColLoop
	
;delay, parameter in bc 
Delay:
	dec	bc
	ld	a,b
	or	c
	jr	nz, Delay
	ret

StopLCD:
	ld	a, [rLCDC]
	rlca	; rotate 1 bit left, high bit into carry flag 
	ret	nc ;return if carry flag = 0, meaning LCD off 
.wait_Vblank:
	ld	a, [rLY]
	cp	145 ; compare with 145, set flag bits
	jr	nz, .wait_Vblank ;if flag bits not zero, go back
	ld	a, [rLCDC]
	res	7, a ;reset bit 7 
	ld	[rLCDC], a ;load a back into rLCDC 
	ret	;return 

Tiles:
	;bg tile
	DB $00, $00, $00, $00, $00, $00, $00, $00
	DB $00, $00, $00, $00, $00, $00, $00, $00
	;DB $AA, $14, $55, $28, $AA, $51, $55, $A2, $AA, $45, $55, $8A, $55, $8A, $AA, $14
	;DB $00, $00, $80, $01, $80, $01, $80, $01, $80, $01, $80, $01, $80, $01, $00, $FF
	;sprite
	DB $00, $00, $42, $42, $42, $42, $00, $00 
	DB $18, $18, $99, $99, $66, $66, $00, $00
	DB $FF, $FF, $BF, $C1, $9F, $E1, $8F, $F1 
	DB $87, $F9, $83, $FD, $81, $FF, $FF, $FF
EndTiles:
