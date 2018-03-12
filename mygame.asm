INCLUDE "gbhw.inc" ; hardware defs from devrs.com 

;sprite constants 
_SPR0_Y		EQU	_OAMRAM
_SPR0_X		EQU	_OAMRAM+1
_SPR0_NUM	EQU	_OAMRAM+2
_SPR0_ATT	EQU	_OAMRAM+3

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
	ld	b, 32 ; bytes to copy(2 tiles) 
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
;	ld	a, [_SPR0_Y]
;	ld	hl, _MOVY
;	add	a, [hl]
;	ld	hl, _SPR0_Y
;	ld	[hl], a
;	cp	152
;	jr	z, .dec_y
;	cp	16
;	jr	z, .inc_y
;	jr	.end_y
;.dec_y:
;	ld	a, -1
;	ld	[_MOVY], a
;	jr	.end_y
;.inc_y:
;	ld	a, 1
;	ld	[_MOVY], a
;.end_y:
;	ld	a, [_SPR0_X]
;	ld	hl, _MOVX
;	add	a, [hl]
;	ld	hl, _SPR0_X
;	ld	[hl], a
;	cp	160
;	jr	z, .dec_x
;	cp	8
;	jr	z, .inc_x
;	jr	.end_x
;.dec_x:
;	ld	a, -1
;	ld	[_MOVX],a
;	jr	.end_x
;.inc_x:
;	ld	a, -1
;	ld	[_MOVX], a
;	jr	.end_x
;.end_x:
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
	jr	z, MoveLeft
MoveLeftRet:
	;test down key
	ld	a, b
	and	$04
	cp	$04
	jr	z, MoveDown
MoveDownRet:
	;test up key
	ld	a, b
	and	$08
	cp	$08
	jr	z, MoveUp
MoveUpRet:
	pop	bc ;return bc from stack
	ret 

MoveRight:
	ld	a, [_SPR0_X]
	inc	a
	ld	[_SPR0_X], a
	jr	MoveRightRet

MoveLeft:
	ld	a, [_SPR0_X]
	dec	a
	ld	[_SPR0_X],a
	jr	MoveLeftRet

MoveDown:
	ld	a, [_SPR0_Y]
	dec	a
	ld	[_SPR0_Y],a
	jr	MoveDownRet

MoveUp:
	ld	a, [_SPR0_Y]
	inc	a
	ld	[_SPR0_Y],a
	jr	MoveUpRet

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
	DB $AA, $00, $44, $00, $AA, $00, $11, $00
	;sprite
	DB $00, $00, $42, $42, $42, $42, $00, $00 
	DB $18, $18, $99, $99, $66, $66, $00, $00
EndTiles:
