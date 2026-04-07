;;******************************************************************
;;	input.s - user login
;;
;;	written by lian
;;******************************************************************
	include	h/gmud.h
	include	h/id.h
	include	h/func.mac
	include	h/mud_funcs.h

	public	input_new
	public	check_pwd

;------------------------
	extrn	bin2digit
	extrn	random_it
	extrn	square_draw
	extrn	write_block0
	extrn	wait_key
	extrn	get_img_data
	extrn	show_one_line
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
__base	equ	ScreenBuffer+160
	define	1,select_mode
	define	1,max_man
	define	1,tmp_man
	define	1,pointer
	define	1,spare_pot

	define	2*MAX_PASS+1,pwd_buf
	define	MAX_PASS+1,win_buf
	define	1,last_key
	define	1,passwd_len


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
;**********************************************************
;	input user data
; input: none
; output: man_picid man_name man_pwd man_gender attr_str
; 	cy: (suc: sec fail: clc)
;**********************************************************
input_new:
	BREAK_FUN	_Bclrscreen

	jsr	input_name
	cmp	#ESC_KEY
	jeq	input_error
	lda	scrbuf
	jeq	input_error
	move	scrbuf,man_name,#MAX_NAME
to_in_pass:
	jsr	input_pass
	cmp	#ESC_KEY
	beq	input_error
	move	scrbuf,man_pwd,#MAX_PASS
	jsr	check_input
	bcc	to_in_pass
	move	man_pwd,pwd_buf,#MAX_PASS
	jsr	trans
	move	pwd_buf,man_pwd,#MAX_PASS
	
	BREAK_FUN	_Bclrscreen
	jsr	adjust_attr
	lda	game_over_flag
	cmp	#2
	beq	input_error

	ldx	#0
	cmp1	attr_str,#16
	bcs	set_gender
	inx
set_gender:	
	stx	man_gender

	lm2	range,#21
	jsr	random_it
	clc
	adc	#30
	sbc	attr_str
	sta	attr_per

	lm2	range,#21
	jsr	random_it
	clc
	adc	#10
	sta	attr_kar
	move	attr_str,man_str,#6

	sec
	rts

input_error:
	clc
	rts

;-------------------------------------------------------
; input: none
; ouput: scrbuf
;-------------------------------------------------------
input_name:
	move	#0,scrbuf+2*CPR,#CPR
	move	name_msg,scrbuf+2*CPR,#6
	lm	inp_hint,#0
	ldxy	#name_input_tbl
	BREAK_FUN	_Binput
	cmp	#HELP_KEY
	beq	input_name

	pha
	move	scrbuf+2*CPR+6,scrbuf,#CPR-6
	pla
	rts

;-------------------------------------------------------
; input: none
; ouput: scrbuf
;-------------------------------------------------------
input_pass:
	move	#0,scrbuf+3*CPR,#CPR
	move	pass_msg,scrbuf+3*CPR,#6
	lm	inp_hint,#0
	ldxy	#pass_input_tbl
	BREAK_FUN	_Binput
	cmp	#HELP_KEY
	beq	input_pass

	pha
	move	scrbuf+3*CPR+6,scrbuf,#CPR-6
	pla
	rts

	if	scode
name_msg	db	'ÐÕÃû: '
pass_msg	db	'ÃÜÂë: '
	else
name_msg	db	'©m¦W: '
pass_msg	db	'±K½X: '
	endif

name_input_tbl:
	db	2*CPR+6
	db	MAX_NAME
	db	21h
pass_input_tbl:
	db	3*CPR+6
	db	MAX_PASS
	db	81h

;-------------------------------------------------------
; input: man_pwd
; ouput: clc(fail) sec(suc)
;-------------------------------------------------------
check_input:
	ldx	#0
l_check:
	lda	man_pwd,x
	beq	l_next
	cmp	#'.'
	beq	l_next
	cmp	#' '
	beq	l_next
	cmp	#'a'
	bcc	pass_error
	cmp	#'z'+1
	bcs	pass_error
l_next:
	inx
	cpx	#MAX_PASS
	bcc	l_check

	sec
	rts

pass_error
	clc
	rts

;------------------------------------------------------------------
; input:
; output: cy(suc: sec, fail: clc)
;	attr_str attr_dex attr_int attr_con attr_per attr_kar
;------------------------------------------------------------------
adjust_attr:
	move	#20,attr_str,#6

	jsr	init_attr

	lm	spare_pot,#0
	lm	pointer,#1
	lm	game_over_flag,#0
	lm21	binbuf,spare_pot
	BREAK_FUN	_Bdisp_bcd
adjust_loop:
	lm2	line_mode,#8700h
	lm2	lcd_mode,#7800h
	UPDATELCD0
	jsr	wait_key
	SWITCH	#key_len,key_tbl
	lda	game_over_flag
	beq	adjust_loop
	rts

key_tbl:
	db	UP_KEY
	db	DOWN_KEY
	db	LEFT_KEY
	db	RIGHT_KEY
	db	CR_KEY
	db	ESC_KEY
key_len	equ	$-key_tbl
	dw	up_func
	dw	down_func
	dw	left_func
	dw	right_func
	dw	enter_func
	dw	esc_func

;------------------------------------------------
up_func:
	ldy	pointer
	dec	pointer
	lda	pointer
	bne	mov_pointer
	lm	pointer,#MAX_ATTR
	jmp	mov_pointer

;------------------------------------------------
down_func:
	ldy	pointer
	inc	pointer
	lda	pointer
	cmp	#MAX_ATTR+1
	bcc	mov_pointer
set_pointer:
	lm	pointer,#1

mov_pointer:
	jsr	put_pointer
	rts

;------------------------------------------------
right_func:
	jsr	get_pot
	cmp	#10
	beq	pot_rts	
	tax
	dex
	txa
	inc	spare_pot
	jmp	mov_pot

;------------------------------------------------
left_func:
	lda	spare_pot
	beq	pot_rts
	jsr	get_pot
	cmp	#30
	beq	pot_rts	
	tax
	inx
	txa
	dec	spare_pot
	jmp	mov_pot

pot_rts:
	rts

mov_pot:
	jsr	save_pot
	jsr	put_pot
	rts

;------------------------------------------------
enter_func:
	lda	spare_pot
	bne	enter_rts
	lm	game_over_flag,#1
enter_rts:
	rts

;------------------------------------------------
esc_func:
	lm	game_over_flag,#2
	rts

;------------------------------------------------
; in: Yreg pointer
put_pointer:
	lda	line_tbl,y
	tay
	ldx	pointer
	lda	line_tbl,x
	tax
	lda	scrbuf+1,y
	sta	scrbuf+1,x
	lda	#0
	sta	scrbuf+1,y
	
	lda	scrbuf+2,y
	sta	scrbuf+2,x
	lda	#0
	sta	scrbuf+2,y
	rts

;------------------------------------------------
; in: pointer
; out: Areg
get_pot:
	ldx	pointer
	dex
	lda	attr_str,x
	rts

;------------------------------------------------
; in: Areg pointer
save_pot:
	ldx	pointer
	dex
	sta	attr_str,x
	rts

;------------------------------------------------
; in: Areg pointer
put_pot:
	jsr	bin2digit
	pha
	ldx	pointer
	lda	line_tbl,x
	tax
	tya
	sta	scrbuf+13,x
	pla
	sta	scrbuf+14,x

	lm21	binbuf,spare_pot
	BREAK_FUN	_Bdisp_bcd
	rts

line_tbl:
	db	0,CPR,2*CPR,3*CPR,4*CPR,5*CPR

;--------------------------------------------
; init adjust screen
;--------------------------------------------
init_attr:
	lm	cursor_posy,#0ffh
	lm	lcmd,#1
	_Msqr	#3,#2,#157,#77
	_Msqr	#5,#4,#155,#75

	move	#0,scrbuf,#CPR
	move	input_scr,scrbuf+CPR,#4*CPR
	rts

input_scr:
	if	scode
	db	8eh,0f8h,0c0h,'ëöÁ¦:   ',17,16,'20    ',8eh
	db	8eh,'  Ãô½Ý:   ',17,16,'20    ',8eh
	db	8eh,'  ÎòÐÔ:   ',17,16,'20    ',8eh
	db	8eh,'  ¸ù¹Ç:   ',17,16,'20    ',8eh
	else
	db	8eh,0fah,05fh,'»M¤O:   ',17,16,'20    ',8eh
	db	8eh,'  ±Ó±¶:   ',17,16,'20    ',8eh
	db	8eh,'  ®©©Ê:   ',17,16,'20    ',8eh
	db	8eh,'  ®Ú°©:   ',17,16,'20    ',8eh
	endif

;------------------------------------------------------------------
; input: man_pwd
; output: cy(suc: sec, fail: clc)
;------------------------------------------------------------------
check_pwd:
	BREAK_FUN	_Bclrscreen
	jsr	passwd_in
	bcc	check_fail
	
	jsr	trans
	ldx	#MAX_PASS-1
cmp_l:
	lda	super_pass,x
	cmp	pwd_buf,x
	bne	check_super_man
	dbpl	x,cmp_l
	sec
	rts
check_super_man:
	ldx	#MAX_PASS-1
cmp_l2:
	lda	super_man,x
	cmp	pwd_buf,x
	bne	to_check
	dbpl	x,cmp_l2
	inc	cheat_mode
	sec
	rts

to_check:
	ldx	#MAX_PASS-1
cmp_loop:
	lda	man_pwd,x
	cmp	pwd_buf,x
	bne	check_fail
	dbpl	x,cmp_loop
	sec
	rts

check_fail:
	clc
	rts

trans:
	clc
	ldx	#MAX_PASS-1
trans1:
	lda	pwd_buf,x
	eor	xor_word,x
	adc	adc_word,x
	sta	pwd_buf,x
	sta	pwd_buf+MAX_PASS,x
	dex
	bpl	trans1
	ldx	#0
trans2:
	lda	pwd_buf,x
	adc	pwd_buf+1,x
	eor	pwd_buf+2,x
	adc	pwd_buf+3,x
	eor	pwd_buf+4,x
	sta	pwd_buf,x
	inx
	cpx	#MAX_PASS
	bcc	trans2
	rts

xor_word:
	db	'½ðÔ¶¼û'
adc_word:
	db	'ÎÄÇúÐÇ'

super_pass:
	db	33h,5ah,1,0c2h,0eeh,82h
super_man:
	db	0e3h,1dh,2dh,37h,38h,7dh
;------------------------------------------------------------------
; input: 
; output:pwd_buf cy (sec:suc)
;------------------------------------------------------------------
passwd_in:
	move	pwd_msg,bank_text,#pwd_msg_len
	ldx	#PWD_X0
	ldy	#PWD_Y0
	lm2	string_ptr,#bank_text
	jsr	show_one_line

	move	#0,pwd_buf,#MAX_PASS+1
	move	#0,win_buf,#MAX_PASS+1
	lm	passwd_len,#0
passwd_in_loop:
	jsr	wait_key
	sta	last_key
	cmp	#ESC_KEY
	beq	exit_passwd
	cmp	#CR_KEY
	beq	rts_passwd_in
	cmp	#LEFT_KEY
	beq	del_secret_in
	cmp	#F2_KEY
	beq	del_secret_in

	ldx	passwd_len
	sta	pwd_buf,x
	inx
	stx	passwd_len
	cpx	#MAX_PASS
	bcs	rts_passwd_in
	bcc	com_passwd_in

del_secret_in:
	ldx	passwd_len
	beq	com_passwd_in
	dex
	lda	#0
	sta	pwd_buf,x
	stx	passwd_len

com_passwd_in:
	jsr	disp_passwd
	jmp	passwd_in_loop

rts_passwd_in:
	sec
	rts
exit_passwd:
	clc
	rts

;--------------------------------------------
disp_passwd:
	ldy	#0
	ldx	passwd_len
	beq	disp_pwd1
	ldx	#0
disp_passwd_loop:
	lda	#'x'
	sta	win_buf,y
	iny
	inx
	cpx	passwd_len		
	bcc	disp_passwd_loop
	cpx	#MAX_PASS
	bcs	rts_disp_passwd
disp_pwd1:
	lda	#'.'
	sta	win_buf,y
disp_passwd_loop1:
	inx
	iny
	cpx	#MAX_PASS
	bcc	disp_passwd_loop1
rts_disp_passwd:
	ldx	#PWD_X0+8
	ldy	#PWD_Y0
	lm2	string_ptr,#win_buf
	jsr	show_one_line
	rts

	if	scode
pwd_msg	db      'ÃÜ  Âë: ......',0
pwd_msg_len	equ	$-pwd_msg
	else
pwd_msg	db      '±K  ½X: ......',0
pwd_msg_len	equ	$-pwd_msg
	endif

;------------------------------------------------------------------
	end
