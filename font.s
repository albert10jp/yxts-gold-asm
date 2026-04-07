;;******************************************************************
;;	font.s - 12x12 font lib
;;
;;	written by lian
;;	begin on 2001/04/09
;;	finish on
;;
;;	lcdch: 26x6+4=160
;; 	lcdcv: 13x6+2=80	0,12,24,36,48,60
;;	lcdch 0--25 lcdcv 0--12
;;
;;lcdch change(bit2-bit0): 000 -> 110 -> 100 -> 010 -> 000
;;*******************************************************************
	include	h/gmud.h
	include	h/mud_funcs.h

	public	write_one_char
	public	flash_cursor

	extrn	mul_ax

;0  0  0  0 ======== 8x8  ASCII extend code
;0  0  0  1 ======== 8x16 ASCII extend code
;0  0  1  x ======== 16x16 Chinese 
;0  1  x  x ======== 24x24 Chinese
;1  x  x  x ======== 6x12 ASCII or 12x12 Chinese

;------------------------------------------------------------------
;write one char(English) or word(Chinese) at any position of LCD
;input : x ,y ,char_mode ,fccode,sccode
;	x :	char position
;		0--19 big char 0--25 small char
;	y :     0--79 row position for LCD160*80 
;	fccode :	if Chinese ,must use fccode & sccode
;			if English ,use fccode
; 	char_mode:
;		equ	00000000b	display special char 
;			b7 ================ 1 convert display 
;		     	b3 b2 b1 b0
;			0  0  0  0 ======== 8x8  ASCII extend code
;			0  0  0  1 ======== 8x16 ASCII extend code
;			0  0  1  x ======== 16x16 Chinese 
;			0  1  x  x ======== 24x24 Chinese
;			1  x  x  x ======== 6x12 ASCII or 12x12 Chinese
;
; 8x16 & 16x16 char_mode 会自动调整, 以适应系统调用
;
;NOTE : (1) fccode, char_mode, lcdch ,scrncv arn't destoried
;	(2) destory register a ,x ,y ,char_mode
;------------------------------------------------------------------
write_one_char:
	lda	fccode
	pha
	lda	char_mode
	pha
	lda	scrncv
	pha
	lda	lcdch
	pha

	stx	lcdch
	sty	scrncv
	cpy	#VDPS
	bcs	char_end

	lda	char_mode
	and	#0fh
	beq	to_write_char
	cmp	#04h
	bcs	char_end

	lda	char_mode
	and	#0f0h
	ora	#01h
	bit	fccode
	bpl	$+4
	ora	#02h
	sta	char_mode

to_write_char:
	lda	fccode
	BREAK_FUN	_Bwrite_one_char

char_end:
	pla
	sta	lcdch
	pla	
	sta	scrncv
	pla	
	sta	char_mode
	pla	
	sta	fccode
	rts

;*************************************************************************

;------------------------------------------------------------
;cursor_mode	equ	00000000b
;			b7 ===================== 1 enable cursor
;					         0 disable cursor
;			    b3 b2 b1 b0 ======== 16 cursor type
;			    0  0  0  0    8x8 shape
;			    0  0  0  1    8x16 shape
;			    0  0  1  0    16x16 shape
;			    0  1  0  0    24x24 shape
;			    1  x  x  x    underline
; add by lian:
;			b5 ===================== 1 arrow cursor
;			b6 ===================== 1 set arrow
;						 0 clear arrow
;-------------------------------------------------------------------
;----------------------------------------
; input: cursor_posx cursor_posy cursor_mode
; cursor_posx : 0--19 lcdbuf
; cursor_posy : 0--79 lcdbuf
;---------------------------------------
flash_cursor:
	ldx	cursor_posx
	ldy	cursor_posy
	lda	cursor_mode
	bpl	fcu_end
	cpx	#CPR
	bcs	fcu_end
	cpy	#VDPS
	bcs	fcu_end

	bbs5	cursor_mode,arrow_cursor

	if	0		;!!系统闪烁光标,GOD空间紧,去掉
	lda	cursor_mode
	and	#0fh
	tax
	lda	cursor_tbl_1,x
	sta	a2			;height
	lda	cursor_tbl_2,x
	sta	a2h			;width

	tya				;垂直
	ldx	#CPR
	jsr	mul_ax
	add	a1,#lcdbuf
	ldy	cursor_posx		;水平
fcu1:
	lda	#0ffh
	cpy	#0
	bne	fcu2			;不是左边第一字节
	lda	#07fh			;是
fcu2:	
	eor	(a1),y			;must modified icon
	sta	(a1),y
	
	lda	a2h			;显示横向,汉字两个字节
	beq	fcu3
	pha
	tya	
	pha
fcu4:
	iny
	lda	(a1),y
	eor	#0ffh
	sta	(a1),y
	dec	a2h
	bne	fcu4

	pla
	tay
	pla
	sta	a2h
fcu3:
	lda	#CPR
	adda2	a1
	dbne	a2,fcu1
	endif

fcu_end:
	rts

;------------------------------------
;------------------------------------
arrow_cursor:
	tya				;垂直
	ldx	#CPR
	jsr	mul_ax
	add	a1,#lcdbuf

	ldx	#0
	ldy	cursor_posx		;水平
w_8x6:	lda	mess_arrow,x
	bit	cursor_mode
	bvs	$+4
	lda	#0
	sta	a2
	lda	(a1),y
	and 	#01h
	ora	a2
	sta	(a1),y
	lda	#CPR
	adda2	a1
	inx
	cpx	#4
	bcc	w_8x6

	lda	cursor_mode
	eor	#01000000b
	sta	cursor_mode

	rts

;--------------------
cursor_tbl_1:
	;db	08,16,16,16,24,24,24,24,2,2,2,2,2,2,2,2
cursor_tbl_2:
	;db	0,0,1,1,2,2,2,2,0,0,1,1,1,1,1,1

mess_arrow:
	db	11111110b
	db	01111100b
	db	00111000b
	db	00010000b

;---------------------------------------------------------------
	end
