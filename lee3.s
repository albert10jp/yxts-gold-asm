	include	h/gmud.h
	include	h/id.h
	
	public	find_kf
	public	list_menu
	public	clean_list_right

	extrn	pop_menu
	extrn	mul_ax
	extrn	block_draw
	extrn	square_draw
	extrn	line_draw
	
find_kf:
	ldy	#0
	ldx	#0
	cpx	man_kfnum
	beq	no_find
to_find:
	cmp	man_kf,y
	beq	find_it
	rept	4
	iny
	endr
	inx
	cpx	man_kfnum
	bcc	to_find
no_find:
	clc
	rts
find_it:
	sec
	rts
	
LEFT_CHAR	equ	4
TOTAL_CHAR	equ	18
HEIGHT_CHAR	equ	5
;---------------------------------------------------------------
;	list left menu and clear right
; input: Xreg Yreg menu_ptr
; output: x0 y0 x1 y1 (right frame)
;---------------------------------------------------------------
list_menu:
	txa
	pha
	tya
	pha
	jsr	draw_list_frame

	pla
	tay
	pla
	tax
	jsr	pop_menu
	rts
	
;---------------------------------------------------------------
; input: x y
; output:  list_x0(4bytes)
;---------------------------------------------------------------
draw_list_frame:
	dey
	dey
	stx	x0
	sty	y0
	dec	x0
	dec	x0
	lda	char_height
	lsr	a
	ldx	#TOTAL_CHAR
	jsr	mul_ax
	clc
	adc	x0
	sta	x1

	lda	#HEIGHT_CHAR
	ldx	char_height
	jsr	mul_ax
	clc
	adc	y0
	adc	#3
	sta	y1

	push	x1
	push	y1
	lm	lcmd,#0
	jsr	block_draw
	lm	lcmd,#1
	jsr	square_draw

	lda	char_height
	lsr	a
	ldx	#LEFT_CHAR
	jsr	mul_ax
	clc
	adc	x0
	adc	#3
	sta	x0
	sta	x1

	jsr	line_draw
	pull	y1
	pull	x1

	inc	x0
	inc	y0
	inc	y0
	dec	x1
	dec	y1
	move	x0,list_x0,#4
	rts
	
;---------------------------------------------------------------
;	clean list menu right
; input: list_x0(4bytes)
; output: x0 y0 x1 y1 (right frame)
;---------------------------------------------------------------
clean_list_right:
	move	list_x0,x0,#4
	lm	lcmd,#0
	jsr	block_draw
	rts
	
	end
