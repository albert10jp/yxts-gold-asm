;;******************************************************************
;;	input.s - user login
;;
;;	written by lian
;;******************************************************************
	include	h/gmud.h
	include	h/id.h
	include	h/func.mac
	include	h/mud_funcs.h

	public	input_digit

;------------------------
	extrn	bin2digit
	extrn	random_it
	extrn	square_draw
	extrn	write_block0
	extrn	divid_ax

	extrn	wait_key
	extrn	write_one_char
;------------------------

_Msqr	macro	px0,py0,px1,py1
	lm	x0,px0
	lm	y0,py0
	lm	x1,px1
	lm	y1,py1
	jsr	square_draw
	endm

;for input
game_over_flag	equ	ScreenBuffer+159

;for digit
__base	equ	ScreenBuffer+160
	define	1,digit_x0
	define	1,digit_y0
	define	1,cur_x0
	define	2,restore_val
	define	2,cur_val
	define	2,max_val
	define	5,digit_buf

INIT_X0		equ	20
INIT_Y0		equ	28
IMG_W		equ	16
IMG_H		equ	15
IMG_SEP		equ	35
MAX_MAN		equ	3
MAX_ATTR	equ	4

PWD_X0		equ	4
PWD_Y0		equ	30

BCD_LEN		equ	5
;------------------------------------------------------------------
;input: Xreg Yreg a1(2bytes) a2(2bytes)
;output: a1(2bytes)
;------------------------------------------------------------------
input_digit:
	jsr	init_digit
	jsr	show_digit

dwait_key:
	jsr	wait_key
	SWITCH	#t_menu_len,t_menu_tbl
	lda	game_over_flag
	beq	dwait_key
	lm2	a2,max_val
	rts

t_menu_tbl:
	db	'0bnmghjtyu'
	db	ESC_KEY
	db	CR_KEY
	db	F2_KEY
	db	UP_KEY
	db	DOWN_KEY
t_menu_len	equ	$-t_menu_tbl
t_menu_proc:
	dw	proc_digit_key
	dw	proc_digit_key
	dw	proc_digit_key
	dw	proc_digit_key
	dw	proc_digit_key
	dw	proc_digit_key
	dw	proc_digit_key
	dw	proc_digit_key
	dw	proc_digit_key
	dw	proc_digit_key
	dw	proc_esc_key
	dw	proc_cr_key
	dw	proc_del_key
	dw	proc_up_key
	dw	proc_down_key

proc_up_key:
	lda	cur_val
	ora	cur_val+1
	beq	proc_rts
	dec2	cur_val
	jmp	show_digit

proc_down_key:
	cmp2	cur_val,max_val
	bcs	proc_rts
	inc2	cur_val
	jmp	show_digit

proc_del_key:
	move	digit_buf,digit_buf+1,#BCD_LEN-1
	jmp	get_digit

proc_rts:
	rts

proc_digit_key:
	ldx	#0
insert_next:
	lda	digit_buf+1,x
	sta	digit_buf,x
	inx
	cpx	#BCD_LEN-1
	bcc	insert_next

	tya
	eor	#'0'
	sta	digit_buf+BCD_LEN-1
	jmp	get_digit

proc_esc_key:
	lm2	a1,restore_val
	lm	game_over_flag,#1
	rts
proc_cr_key:
	cmp2	max_val,cur_val
	bcs	cr_next
	lm2	cur_val,max_val
cr_next:
	lm2	a1,cur_val
	lm	game_over_flag,#2
	rts

get_digit:
	move	digit_buf+1,bcdbuf,#BCD_LEN-1
	BREAK_FUN	_Bbcd4bin
	lm2	cur_val,a1
	jmp	show_digit

;----------------------------------------------------
;input: x0 y0
;ouput: digit_x0 digit_y0
;----------------------------------------------------
init_digit:
	stx	digit_x0
	sty	digit_y0
	lm2	restore_val,a1
	lm2	cur_val,a1
	lm2	max_val,a2

	lm2	fccode,#img_spin
	BREAK_FUN	_Bwrite_block

	inc	digit_x0
	lda	#6
	tax
	lda	digit_x0
	jsr	divid_ax
	sta	digit_x0
	inc	digit_y0

	lm	game_over_flag,#0
	rts

;----------------------------------------------------
;input: cur_val digit_x0 digit_y0
;----------------------------------------------------
show_digit:
	lm2	binbuf,cur_val
	BREAK_FUN	_Bbin2bcd
	move	bcdbuf,digit_buf,#BCD_LEN
	lm	cur_x0,digit_x0

	ldy	#0ffh
check_loop:
	iny
	cpy	#BCD_LEN-1
	bcs	put_it
	lda	digit_buf,y
	cmp	#'0'
	bne	put_it
	lda	#0
	jsr	write_digit
	jmp	check_loop

put_it:
	lda	digit_buf,y
	jsr	write_digit
	iny
	cpy	#BCD_LEN
	bcc	put_it
	rts

;-------------------------------------
;input: Areg cur_x0
;output: cur_x0
;-------------------------------------
write_digit:
	sta	fccode
	tya
	pha
	ldx	cur_x0
	ldy	digit_y0
	jsr	write_one_char
	inc	cur_x0
	pla
	tay
	rts

img_spin:
	db	42,14
	db	0ffh,0ffh,0ffh,0ffh,0ffh,0c0h
	db	080h,000h,000h,000h,040h,040h
	db	080h,000h,000h,000h,040h,040h
	db	080h,000h,000h,000h,044h,040h
	db	080h,000h,000h,000h,04eh,040h
	db	080h,000h,000h,000h,05fh,040h
	db	080h,000h,000h,000h,040h,040h
	db	080h,000h,000h,000h,07fh,0c0h
	db	080h,000h,000h,000h,040h,040h
	db	080h,000h,000h,000h,05fh,040h
	db	080h,000h,000h,000h,04eh,040h
	db	080h,000h,000h,000h,044h,040h
	db	080h,000h,000h,000h,040h,040h
	db	0ffh,0ffh,0ffh,0ffh,0ffh,0c0h
;------------------------------------------------------------------
	end
