;;******************************************************************
;;	string.s - string lib
;;
;;	written by lian
;;	begin on 2001/04/12
;;
;;*******************************************************************
	include	h/id.h
	include	h/gmud.h
	include	h/func.mac
	include	h/mud_funcs.h

	public	format_string
	public	show_one_line
	public	show_string
	public	show_box
	public	message_box
	public	message_box_more
	public	message_box_for_pyh

	extrn	write_one_char

	extrn	divid_ax
	extrn	block_draw
	extrn	square_draw
	extrn	wait_cr_key
	extrn	wait_key

CatBuf		equ	img_buf
OutBuf		equ	ScreenBuffer
MAX_TYPE	equ	15
BCD_LEN		equ	5
PAT_LEN		equ	10	;max:4294967295
;---------------------------------------------
;	format (string_ptr) ==> OutBuf
;input: string_ptr
;output: string_ptr
;destroy: a1 a2 a3(类型) OutBuf
;
; format:
;	db	'金钱:',4	;文字,变量类型
;	dw	man_money,0	;变量地址(0结束)
;变量类型(0-15)
;	0:	NULL
;	1:	1byte整数
;	2:	2byte整数
;	3:	1byte整数,填充3空白
;	4:	4byte整数
;	5:	2byte整数,填充5空白
;	6:	字符地址
;	7:	字符串地址
;	8:	字符串地址指针
;	9:	数量+字符串地址指针
;特殊变量地址(0-10)
;	0:	结束 + 换行符
;	10:	结束
;文本取代类型
;	符号	说明		控制变量
;	$$:	$
;	$r:	return
;	$o:	npc_name
;	$N:	self		obj_flag
;	$n:	other		obj_flag
;	$w:	weapon		obj_flag
;	$l$1:	limbs		limb_flag
;	$t:	quest_type	task_buf
;	$q:	quest		task_buf+1
;	$k:	kf_name		kf_id
;	$p:	perform_name	perform_id
;	$g:	goods_name	goods_id
;---------------------------------------------
format_string:
	lda	#0
	tay		;string_ptr
	tax		;OutBuf

item_loop:
	lda	(string_ptr),y
	bne	msg_loop
	sta	OutBuf,x
	lm2	string_ptr,#OutBuf
	rts

msg_loop:
	lda	(string_ptr),y
	iny
	cmp	#MAX_TYPE+1
	bcc	value_init

	sta	OutBuf,x
	inx
	jmp	msg_loop
	
value_init:
	sta	a3
	lda	a3
	beq	set_item

value_loop:
	lda	(string_ptr),y
	sta	a1
	iny
	lda	(string_ptr),y
	sta	a1h
	iny

	lda	a1h
	bne	value_address
	lda	a1
	beq	set_item
	cmp	#10
	beq	item_loop

value_address:
	tya
	pha
	push	a3

	lda	a3
	cmp	#4
	jeq	is_digit4
	cmp	#6
	jeq	is_char
	cmp	#7
	jeq	is_string
	cmp	#8
	jeq	is_string_ptr
	cmp	#9
	jeq	is_string_num

	ldy	#0
	lda	(a1),y
	sta	a2
	iny
	lda	(a1),y
	sta	a2h
	lm2	binbuf,a2

	lda	a3
	cmp	#1
	jeq	is_one_byte
	cmp	#2
	jeq	is_two_byte
	cmp	#3
	jeq	is_digit3
	cmp	#5
	jeq	is_digit5
	SSTOP	6

;--------------------------------
set_item:
	lda	#0
	sta	OutBuf,x
	inx
	jmp	item_loop

;---------------------------------------------
; address type
;---------------------------------------------
is_one_byte:
	lm	binbuf+1,#0
is_two_byte:
	txa
	pha
	BREAK_FUN	_Bbin2bcd
	pla
	tax
	jsr	write_digit
	jmp	type_end

is_digit3:
	lm	binbuf+1,#0
	lda	#3
	bne	$+4
is_digit5:
	lda	#5

	pha
	txa
	pha
	BREAK_FUN	_Bbin2bcd
	pla
	tax
	pla
	jsr	write_digit5
	jmp	type_end

is_digit4:
	ldy	#0
	lda	(a1),y
	pha
	iny
	lda	(a1),y
	pha
	iny
	lda	(a1),y
	sta	a2
	iny
	lda	(a1),y
	sta	a2h
	iny
	pla
	sta	a1h
	pla
	sta	a1
	txa
	pha
	jsr	bin4pat
	pla
	tax
	jsr	write_digit4
	jmp	type_end

is_char:
	ldy	#0
	lda	(a1),y
	sta	OutBuf,x
	sta	a2
	inx
	bit	a2
	bpl	type_end
	iny
	lda	(a1),y
	sta	OutBuf,x
	inx
	jmp	type_end

is_string_num:
	ldy	#0
	lda	(a1),y
	sta	a3
	iny
	lda	(a1),y
	sta	a2
	iny
	lda	(a1),y
	sta	a2h
	ldy	#0
	lda	(a2),y
	sta	a1
	iny
	lda	(a2),y
	sta	a1h
	ldy	#0
string_num_loop:
	lda	(a1),y
	sta	OutBuf,x
	inx
	iny
	dbne	a3,string_num_loop
	jmp	type_end

is_string_ptr:
	ldy	#0
	lda	(a1),y
	sta	a2
	iny
	lda	(a1),y
	sta	a2h
	lm2	a1,a2

is_string:
	lda	a1
	ora	a1h
	beq	type_end

	ldy	#0
write_string:
	lda	(a1),y
	beq	type_end
	cmp	#0ffh
	beq	type_end
	sta	OutBuf,x
	inx
	iny
	jmp	write_string

type_end:
	pull	a3
	pla
	tay
	jmp	value_loop

;------------------------------------------------------------------
; input: binbuf(2bytes) Xreg
; output: Xreg
;------------------------------------------------------------------
write_digit:

	ldy	#0ffh
check_loop:
	iny
	cpy	#BCD_LEN-1
	bcs	put_it
	lda	bcdbuf,y
	cmp	#'0'
	beq	check_loop

put_it:
	lda	bcdbuf,y
	sta	OutBuf,x
	iny
	inx
	cpy	#BCD_LEN
	bcc	put_it
	rts

;------------------------------------------------------------------
; input: bcdbuf(5bytes) Areg(=total) Xreg
; output: Xreg
;------------------------------------------------------------------
write_digit5:

	pha
	ldy	#0ffh
check_loop5:
	iny
	cpy	#BCD_LEN-1
	bcs	put_it5_init
	lda	bcdbuf,y
	cmp	#'0'
	beq	check_loop5
put_it5_init:
	pla
	sty	a1
	clc
	adc	a1
	sec
	sbc	#BCD_LEN
	pha
put_it5:
	lda	bcdbuf,y
	sta	OutBuf,x
	iny
	inx
	cpy	#BCD_LEN
	bcc	put_it5

	pla
	tay
	beq	digit5_rts
put_empty5:
	lda	#' '
	sta	OutBuf,x
	inx
	dey
	bne	put_empty5
digit5_rts:
	rts

;------------------------------------------------------------------
; input: patbuf(10bytes) Xreg
; output: Xreg
;------------------------------------------------------------------
write_digit4:
	ldy	#0ffh
check_loop4:
	iny
	cpy	#PAT_LEN-1
	bcs	put_it4
	lda	patbuf,y
	cmp	#'0'
	beq	check_loop4
put_it4:
	lda	patbuf,y
	sta	OutBuf,x
	iny
	inx
	cpy	#PAT_LEN
	bcc	put_it4
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;convert (a1 a2) to patbuf
;input:  a1 a2(4bytes)
;output: patbuf(10bytes) (ascii码)
;destroy: Areg,Xreg,Yreg
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
bin4pat:
	ldx	#0
b1o:	ldy	#0ffh
b2o:	iny
	sec
	lda	a1
	sbc	t1000l,x
	sta	a1
	lda	a1+1
	sbc	t1000h,x
	sta	a1+1
	lda	a2
	sbc	u1000l,x
	sta	a2
	lda	a2+1
	sbc	u1000h,x
	sta	a2+1
	bcs	b2o
	lda	a1
	adc	t1000l,x
	sta	a1
	lda	a1+1
	adc	t1000h,x
	sta	a1+1
	lda	a2
	adc	u1000l,x
	sta	a2
	lda	a2+1
	adc	u1000h,x
	sta	a2+1
	tya
	ora	#30h
	sta	patbuf,x
	inx
	cpx	#PAT_LEN
	bcc	b1o
	rts

;------------------------------
;1000000000=3b9aca00h
;100000000=5f5e100h
;10000000=989680h
;1000000=0f4240h
;100000=186a0h
;10000=2710h
;1000=3e8h
;100=64h
;10=0ah
;1=1h

t1000l	db	0h
	db	0h
	db	80h
	db	40h
	db	0a0h
	db	10h
	db	0e8h
	db	64h
	db	0ah
	db	1h

t1000h	db	0cah
	db	0e1h
	db	96h
	db	42h
	db	86h
	db	27h
	db	3h
	db	0h
	db	0h
	db	0h

u1000l	db	9ah
	db	0f5h
	db	98h
	db	0fh
	db	1h
	db	0h
	db	0h
	db	0h
	db	0h
	db	0h

u1000h	db	3bh
	db	5h
	db	0h
	db	0h
	db	0h
	db	0h
	db	0h
	db	0h
	db	0h
	db	0h

;---------------------------------------------------------------
;	show message at box 
; input: x0 y0 x1 y1 string_ptr
; ouput: lcdbuf
;---------------------------------------------------------------
message_box:
	jsr	show_box
	jmp	wait_cr_key

;--------------------------------
;cursor flash box
;--------------------------------
message_box_more:
	push2	x0
	push2	x1
	jsr	show_box
	pull2	x1
	pull2	x0
	bcc	to_wait_end

	lda	x1
	mlsr	a,3
	sta	cursor_posx
	dec	cursor_posx
	lm	cursor_posy,y0
	inc	cursor_posy
	inc	cursor_posy
	lm	cursor_mode,#FLASH_FLAG
to_wait_more:
	jsr	wait_key
	cmp	#CR_KEY
	beq	message_box_more
	bne	to_wait_more
to_wait_end:
	lm	cursor_mode,#0
	jsr	wait_key
	cmp	#CR_KEY
	bne	to_wait_end
more_end:
	lm	cursor_mode,#0
	rts

;--------------------------------
;output:
;	sec: ESC_KEY
;	clc: CR_KEY
;--------------------------------
message_box_for_pyh:
	jsr	show_box
	ldx	x0
	ldy	y0
	lm2	string_ptr,#box_tip
	jsr	show_one_line

pyh_key_loop:
	jsr	wait_key
	cmp	#ESC_KEY
	beq	pyh_box_rts
	cmp	#CR_KEY
	bne	pyh_key_loop
	clc
	rts
pyh_box_rts
	sec	
	rts

	if	scode
box_tip	db	'([输入]确认,[跳出]放弃)',0
	else
box_tip	db	'([块]絋粄,[铬]斌)',0
	endif
;-----------------------------------
; input: x0 y0 x1 y1
;-----------------------------------
show_box:
	dec	x0
	inc	x1
	lm	lcmd,#0
	jsr	block_draw
	lm	lcmd,#1
	jsr	square_draw
	inc	x0

	;;char_row
	push	char_row	;!!be care,keep
	push	char_col

	lda	char_height
	lsr	a
	tax
	lda	x1
	jsr	divid_ax
	sta	char_row
	lm	char_col,y1

	lda	char_height
	lsr	a
	tax
	lda	x0
	jsr	divid_ax
	tax
	ldy	y0
	iny
	iny
	lda	#6
	jsr	show_string

	pull	char_col
	pull	char_row
	rts

;---------------------------------------------------------------
;	write multi lines
; input: Areg(line_num) Xreg Yreg string_ptr (same as show_one_line)
; output: C (clc: text end; sec: screen end)
; destry: x0 y0 r0
;---------------------------------------------------------------
show_string:
	sta	r0
	stx	x0
	sty	y0
	lda	r0
	bne	message_line
	lm	r0,#0ffh
message_line:
	ldx	x0
	ldy	y0
	jsr	show_one_line
	beq	message_end

	tya
	adda2	string_ptr

	dec	r0
	beq	message_rts

	add1	y0,char_height
	cmp	char_col
	bcc	message_line

message_rts:
	ldy	#0
	lda	(string_ptr),y
	beq	message_end

	sec
	rts

message_end:
	clc
	rts

;----------------------------------------------------------------------
;	write one line
; input: Xreg Yreg string_ptr
;	x :	0--19 big char 0--25 small char
;	y :     0--79 row position for LCD160*80 
;	string_ptr: string address
; output: Yreg: write byte number
; destroy: r1
;----------------------------------------------------------------------
show_one_line:
	stx	x1
	sty	y1
	lm	r1,#0
char_loop:
	ldy	r1
	lda	(string_ptr),y
	sta	fccode
	beq	up_line_rts1
	cmp	#0ffh
	beq	up_line_rts1
	bpl	to_write_char

	iny
	lda	(string_ptr),y
	sta	fccode+1
	ldx	x1
	inx
	cpx	char_row
	bcs	up_line_rts2

to_write_char:
	ldx	x1
	ldy	y1
	cpx	char_row
	bcs	up_line_rts2

	jsr	write_one_char

	inc	x1
	inc	r1
	bit	fccode
	bpl	char_loop
	inc	x1
	inc	r1
	jmp	char_loop

up_line_rts1:
	inc2	string_ptr
up_line_rts2:
	ldy	r1
	rts
	
;---------------------------------------------------------------
	end
