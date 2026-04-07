;;******************************************************************
;;	digit.s - show graph digit
;;
;;	written by lian
;;	begin on 2001/04/06
;;	finish on 2001/04/06
;;
;;*******************************************************************
	include	h/gmud.h

	public	show_digit
	public	show_line
	public	show_block

	extrn	mul2
	extrn	divid42
	extrn	square_draw
	extrn	lcd_start_addr_tbl

BCD_LEN		equ	5

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	将入口的数字用不同的格式显示
;Input: Xreg Yreg
;	binbuf: value
;	bcdbuf: max_value
;	Areg:	graph lenght
;
;show_digit:数字 show_heart:心 show_line:条 show_block:块
;
;Output:  直接写屏
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
; eg: 12/34 if max !=0
;	12 if max = 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
show_digit:
	txa
	mlsr	a,3		;a/8
	sta	x0
	sty	y0

	push2	bcdbuf
	;real value
	ldy	#0
	jsr	set_digit	;!!dont destroy Yreg
	pull2	bcdbuf
	lda	bcdbuf
	ora	bcdbuf+1
	beq	digit_write

	;write separate line
	lda	#10
	sta	patbuf,y
	iny

	;max value
	lm2	binbuf,bcdbuf
	jsr	set_digit	;!!dont destroy Yreg
digit_write:
	tya
	and	#01h
	beq	is_good
	;--------------------------------------
	;数字字体为 4x5,写屏时同时写2个字
	;所以字数要为偶数个,奇数时加一个空白
	;--------------------------------------
	lda	#11
	sta	patbuf,y
	iny
is_good:	
	jsr	write_digit
	rts

;---------------------------------------------------
;	write digit to patbuf
; input: binbuf Yreg
; output: patbuf Yreg
;---------------------------------------------------
set_digit:
	tya
	pha

	BREAK_FUN	_Bbin2bcd

	pla
	tay

	ldx	#0ffh
check_loop:
	inx
	cpx	#BCD_LEN-1
	bcs	put_it
	lda	bcdbuf,x
	cmp	#'0'
	beq	check_loop

put_it:
	lda	bcdbuf,x
	eor	#'0'
	sta	patbuf,y
	iny
	inx
	cpx	#BCD_LEN
	bcc	put_it
	rts

;---------------------------------------------------
;; input: x0 y0 
;;	  patbuf Yreg
;;	patbuf: data
;;	Yreg:	data count
;;
;; output: (lcdbuf_ptr)
;---------------------------------------------------
write_digit:
	sty	r0
	ldy	#0
get_digit_addr:
	;;sourse address
	lda	patbuf,y
	asl	a
	tax
	lm20x	a1,digit_tbl
	iny
	lda	patbuf,y
	asl	a
	tax
	lm20x	a2,digit_tbl
	iny

	tya
	pha

	;;destion address
	lda	y0
	asl	a
	tax
	lm20x	intc,lcd_start_addr_tbl
	add	intc,lcdbuf_ptr

	ldx	#0
w_4x5:	
	;;merge (a1) (a2) to Areg
	txa
	tay
	lda	(a1),y
	masl	a,4
	ora	(a2),y
	ldy	x0
	sta	(intc),y

	lda	#CPR
	adda2	intc
	inx
	cpx	#5
	bcc	w_4x5

	inc	x0

	pla
	tay
	cpy	r0
	bcc	get_digit_addr
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;; show real line and max line
;; eg: -------
;;     -------------
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
show_line:
	jsr	init_digit

	;write value line
	ldy	#3
	jsr	show_line0

	;write max line
	inc	y0
	ldx	r0
	ldy	#1
	jsr	show_line0
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;; show block and frame
;; eg: ■■■■■■■
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
show_block:
	jsr	init_digit

	;write block
	ldy	#6
	jsr	show_line0

	;write frame
	sec
	lda	y0
	sta	y1
	sbc	#7
	sta	y0
	clc
	lda	x0
	masl	a,3		;a*8
	sta	x0
	adc	r0
	sta	x1
	lm	lcmd,#1
	jsr	square_draw
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; input: Areg Xreg Yreg binbuf bcdbuf
;; output: x0 y0 
;;	   Xreg: number
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
init_digit:
	sta	r0
	stx	x0
	sty	y0

	lda	x0
	mlsr	a,3		;a/8
	sta	x0

	lda	binbuf
	ora	binbuf+1
	beq	is_zero
	cmp2	binbuf,bcdbuf
	bcs	is_max

	push2	bcdbuf
	lm2	a1,binbuf
	lm	a2,r0
	lm	a2h,#0
	jsr	mul2
	pull2	a3

	jsr	divid42
	ldx	a1
	bne	$+3
	inx
	rts

;-------------------------
is_zero:
	pla
	pla
	rts
is_max:
	ldx	r0
	rts

;----------------------------------------
; input: Xreg: width
;	Yreg: heigh
;	x0 y0
;----------------------------------------
show_line0:
	txa
	lsr	a
	lsr	a
	lsr	a
	sta	a1
	sty	a1h
	stx	a2

	lda	y0
	asl	a
	tax
	lm20x	intc,lcd_start_addr_tbl
	add	intc,lcdbuf_ptr

line_w:
	ldy	x0
	lda	#0ffh
	ldx	a1
	beq	last_one_byte
block_w:
	sta	(intc),y
	iny
	dex
	bne	block_w		;!!don't destroy Xreg

last_one_byte:
	lda	a2
	and	#7
	beq	next_byte
	tax
	lda	byte_tbl,x
	sta	(intc),y

next_byte:
	lda	#CPR
	adda2	intc
	inc	y0

	dec	a1h
	bne	line_w

	rts

byte_tbl	db	0h,80h,0c0h,0e0h,0f0h,0f8h,0fch,0feh

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	if	0		;!!show_heart例程没使用
show_heart:
	jsr	init_digit

	lm2	a1,#empty_heart
	jsr	put_patbuf	;!!don't destroy Xreg
heart_w:
	txa
	pha
	jsr	write_it
	pla
	tax
	dex
	bne	heart_w
	rts

empty_heart:	
	db	036h,049h,041h,041h,041h,022h,014h,008h		;空心
full_heart:	
	db	036h,07Fh,07Fh,07Fh,07Fh,03Eh,01Ch,008h		;实心
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;;	put 8x8
;; input: a1
;; output: patbuf
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
put_patbuf:
	ldy	#0
patbuf_loop:
	lda	(a1),y
	sta	patbuf,y
	iny
	cpy	#8
	bcc	patbuf_loop
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;;	write 8x8
;; input: x0 y0 
;;	  patbuf
;; output: x0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
write_it:
	lda	y0
	asl	a
	tax
	lm20x	intc,lcd_start_addr_tbl
	add	intc,lcdbuf_ptr

	ldx	#0
	ldy	x0
w_8x8:	lda	patbuf,x
	sta	(intc),y
	lda	#CPR
	adda2	intc
	inx
	cpx	#8
	bcc	w_8x8
	inc	x0
	rts
	endif		;!!show_heart例程没使用

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

digit_tbl:
	dw	digit0
	dw	digit1
	dw	digit2
	dw	digit3
	dw	digit4
	dw	digit5
	dw	digit6
	dw	digit7
	dw	digit8
	dw	digit9
	dw	sepa_line	;10
	dw	empty_digit	;11
digit0:
	db	00001110b
	db	00001010b
	db	00001010b
	db	00001010b
	db	00001110b
digit1:
	db	00000100b
	db	00001100b
	db	00000100b
	db	00000100b
	db	00000100b
digit2:
	db	00001110b
	db	00000010b
	db	00001110b
	db	00001000b
	db	00001110b
digit3:
	db	00001110b
	db	00000010b
	db	00001110b
	db	00000010b
	db	00001110b
digit4:
	db	00001010b
	db	00001010b
	db	00001110b
	db	00000010b
	db	00000010b
digit5:
	db	00001110b
	db	00001000b
	db	00001110b
	db	00000010b
	db	00001110b
digit6:
	db	00001110b
	db	00001000b
	db	00001110b
	db	00001010b
	db	00001110b
digit7:
	db	00001110b
	db	00000010b
	db	00000010b
	db	00000010b
	db	00000010b
digit8:
	db	00001110b
	db	00001010b
	db	00001110b
	db	00001010b
	db	00001110b
digit9:
	db	00001110b
	db	00001010b
	db	00001110b
	db	00000010b
	db	00001110b
sepa_line:
	db	00000000b
	db	00000010b
	db	00000100b
	db	00001000b
	db	00000000b
empty_digit:
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
;----------------------------------------------------------------
	end
