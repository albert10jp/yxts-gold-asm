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

	public	cat_string
	public	format_string
	public	show_one_line
	public	show_string
	public	show_box
	public	message_box
	public	message_box_more
	public	message_box_for_pyh
	public	get_text_data

	extrn	get_goods_name
	extrn	get_kf_name
	extrn	get_pf_name
	extrn	get_npc_name
	extrn	get_kf_attr
	extrn	write_one_char
	extrn	set_get_buf

	extrn	random_it
	extrn	divid_ax
	extrn	block_draw
	extrn	square_draw
	extrn	find_kf
	extrn	wait_cr_key
	extrn	wait_key

CatBuf		equ	img_buf
OutBuf		equ	ScreenBuffer
MAX_TYPE	equ	15
BCD_LEN		equ	5
PAT_LEN		equ	10	;max:4294967295
;---------------------------------------------
;	(string_ptr)+(a1) ==> CatBuf
; input: a1 string_ptr
; output: string_ptr
; destroy: img_buf
;---------------------------------------------
cat_string:
	lda	#0ffh
	tay		;string_ptr
	tax		;CatBuf
cat_loop1:
	iny
	inx
	lda	(string_ptr),y
	sta	CatBuf,x
	bne	cat_loop1

	ldy	#0ffh
cat_loop2:
	iny
	inx
	lda	(a1),y
	sta	CatBuf,x
	bne	cat_loop2
	inx
	sta	CatBuf,x
	lm2	string_ptr,#CatBuf
	rts

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
	cmp	#'$'
	beq	to_replace1

	sta	OutBuf,x
	inx
	jmp	msg_loop
to_replace1:
	lm2	a1,string_ptr
	jsr	replace_string
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
; input: a1 Xreg Yreg
;	obj_flag - bit7:1 man 0:npc
; output: Xreg Yreg
; destroy: a3
;---------------------------------------------
replace_string:
	lda	(a1),y
	sta	a3
	iny
	tya
	pha
	push2	a1
	push2	string_ptr

	lda	a3
	cmp	#'$'
	beq	is_is_is
	cmp	#'r'
	beq	is_return_sym
	cmp	#'N'
	beq	is_self_sym
	cmp	#'n'
	beq	is_other_sym
	cmp	#'w'
	beq	is_weapon_sym
	cmp	#'l'
	beq	is_limbs_sym
	cmp	#'1'
	beq	is_limbs_sym
	cmp	#'t'
	jeq	is_type_sym
	cmp	#'q'
	jeq	is_quest_sym
	cmp	#'g'
	jeq	is_goods_sym
	cmp	#'k'
	jeq	is_kf_sym
	cmp	#'p'
	jeq	is_pf_sym
	cmp	#'o'
	jeq	is_npc_replace
	SSTOP	9

is_is_is:
	sta	OutBuf,x
	inx
	jmp	replace_end
is_return_sym:
	lda	#0
	sta	OutBuf,x
	inx
	jmp	replace_end

is_self_sym:
	bit	obj_flag
	bmi	is_self_replace
	jmp	is_npc_replace
is_other_sym:
	bit	obj_flag
	bpl	is_self_replace
	jmp	is_npc_replace
is_weapon_sym:
	lda	man_weapon
	bit	obj_flag
	jmi	is_goods_replace
	lda	npc_weapon
	jmp	is_goods_replace
is_limbs_sym:
	lda	limb_flag
	asl	a
	asl	a
	tay
	lm	a3,#4
	lm2	a1,#limbs_data
	jmp	char_replace_loop
is_type_sym:
	lda	task_buf
	asl	a
	tay
	lda	type_char,y
	sta	OutBuf,x
	inx
	lda	type_char+1,y
	sta	OutBuf,x
	inx
	jmp	replace_end
is_quest_sym:
	lda	task_buf+1
	ldy	task_buf
	cpy	#QUEST_NPC
	beq	task_npc_replace
	cpy	#QUEST_KILL
	beq	task_npc_replace
	cpy	#QUEST_HOME
	beq	is_home_replace
	bne	is_goods_replace
is_goods_sym:
	lda	goods_id
	jmp	is_goods_replace
is_kf_sym:
	lda	kf_id
	jmp	is_kf_replace
is_pf_sym:
	lda	perform_id
	jmp	is_pf_replace

is_self_replace:
	lda	you_char
	sta	OutBuf,x
	inx
	lda	you_char+1
	sta	OutBuf,x
	inx
	jmp	replace_end
task_npc_replace:
	stx	a3
	jsr	get_npc_name
	ldx	a3
	ldy	#0
	jmp	msg_replace_loop
is_npc_replace:
	lm2	a1,#npc_name
	ldy	#0
	jmp	msg_replace_loop
is_home_replace
	asl	a
	asl	a
	tay
	lm	a3,#4
	lm2	a1,#home_char
	jmp	char_replace_loop
is_goods_replace:
	stx	a3
	and	#7fh
	jsr	get_goods_name
	ldx	a3
	ldy	#0
	jmp	msg_replace_loop
is_kf_replace:
	stx	a3
	and	#7fh
	jsr	get_kf_name
	ldx	a3
	ldy	#0
	jmp	msg_replace_loop
is_pf_replace:
	stx	a3
	jsr	get_pf_name
	ldx	a3
	ldy	#0
	jmp	msg_replace_loop

char_replace_loop:
	lda	(a1),y
	sta	OutBuf,x
	inx
	iny
	dbne	a3,char_replace_loop
	beq	replace_end
msg_replace_loop:
	lda	(a1),y
	beq	replace_end
	cmp	#0ffh
	beq	replace_end
	cmp	#' '		;just for replace
	beq	replace_end
	sta	OutBuf,x
	inx
	iny
	bne	msg_replace_loop

replace_end:
	pull2	string_ptr
	pull2	a1
	pla
	tay
	rts

	if	scode
you_char	db	'你'
type_char	db	'杀寻运送去'
home_char	db	'扫地辟柴挑水'
limbs_data:
	db	'头部','颈部','胸口','後心','左肩','右肩','左臂','右臂'
	db	'左手','右手','腰间','小腹','左腿','右腿','左脚','右脚'
	else
you_char	db	''
type_char	db	'炳碝笲癳'
home_char	db	'苯笯珼'
limbs_data:
	db	'繷场','繴场','','み','オ','','オ羥','羥'
	db	'オも','も','竬丁','浮','オ籐','籐','オ竲','竲'
	endif

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
	cmp	#'$'
	beq	to_replace2
	sta	OutBuf,x
	inx
	iny
	jmp	write_string
to_replace2:
	iny
	jsr	replace_string
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
; input: text_class text_id
; output: string_ptr
; destry: a1
;---------------------------------------------------------------
get_text_data:
	lm	bank_no,#1		;text数据bank

	lda	text_class
	asl	a
	tay
	lda	txt_class_tbl,y
	sta	bank_data_ptr
	lda	txt_class_tbl+1,y
	sta	bank_data_ptr+1		;table address

	;******** text_id >127
	lm21	a1,text_id
	asl2	a1
	add	bank_data_ptr,a1
	;******** text_id >127

	ldy	#0
	jsr	set_get_buf
	sta	a1
	iny
	lda	data_read_buf,y
	sta	a1h		;text address
	lm2	bank_data_ptr,a1
	lm2	string_ptr,#img_buf

	lda	text_class
	cmp	#NPC_NAME
	jeq	is_other_text
	cmp	#NPC_DATA
	beq	is_npc_data
	cmp	#KF_TEXT
	beq	is_kf_data
	cmp	#OTHER_TEXT
	jeq	is_other_text
	SSTOP	14

;-----------------------------------------------
is_npc_data:
	ldy	#0
	jsr	set_get_buf
npc_loop:	
	lda	data_read_buf,y
	sta	npc_state,y
	iny
	cpy	#NPC_DATA_LEN		;get npc_kfnum
	bcc	npc_loop

	lda	npc_kfnum
	asl	a
	tax
	beq	is_desc_text
skill_loop:
	lda	data_read_buf,y
	sta	npc_state,y
	iny
	dbne	x,skill_loop
is_desc_text:
	lm	vendor_goods,#0
	lda	npc_pai
	cmp	#TRADE_PAI
	bne	no_vendor

	lda	data_read_buf,y
	sta	vendor_goods
	iny
	tax
	beq	no_vendor
vendor_loop:
	lda	data_read_buf,y
	sta	vendor_goods,x
	iny
	dbne	x,vendor_loop

no_vendor:
	tya
	adda2	bank_data_ptr
	lm2	string_ptr,#npc_desc
	jmp	is_other_text

;-----------------------------------------------
is_kf_data:
	ldy	#0
	jsr	set_get_buf
	bit	perform_flag
	jmi	is_pf_data

	sta	range
	lm	range+1,#0
	jsr	random_it
	pha

check_kf_type:
	lda	text_id
	jsr	get_kf_attr
	ldy	#0
	lda	(a1),y
	cmp	#DODGE_KF
	beq	is_dodge_msg
	lda	text_id
	cmp	#BASIC_KF_NUM
	bcc	is_basic_msg

	;*************Aregx12 + 2
	pla

	;******* 对攻击功夫有等级限制 *************
	lda	text_id
	jsr	new_random	;i: Areg(=text_id) o:Areg
	;******* 对攻击功夫有等级限制 *************
is_action_kf:
	asl	a
	asl	a
	sta	a1
	asl	a
	clc
	adc	a1
	tay
	iny
	iny
	;*************
	ldx	#0
kf_loop:
	lda	data_read_buf,y
	sta	kf_data,x
	iny
	inx
	cpx	#12
	bcc	kf_loop
	lm2	bank_data_ptr,kf_desc
	jmp	is_other_text

is_basic_msg:
	;*************Aregx3 + 2
	pla
	sta	a1
	asl	a
	clc
	adc	a1
	tay
	iny
	iny
	lda	data_read_buf,y
	sta	damage_type
	iny
	lm2	kf_damage,#0
	lm2	kf_force,#0
	jmp	set_kf_desc
	;*************Aregx3 + 2
is_dodge_msg:
	;*************Aregx2 + 2
	pla
	asl	a
	tay
	iny
	iny
	;*************Aregx2 + 2
set_kf_desc:
	lda	data_read_buf,y
	sta	kf_desc
	iny
	lda	data_read_buf,y
	sta	kf_desc+1
	lm2	bank_data_ptr,kf_desc
	jmp	is_other_text

is_pf_data:
	;*************Aregx12 + 2
	asl	a
	asl	a
	sta	a1
	asl	a
	clc
	adc	a1
	tay
	iny
	iny
	;*************Aregx12 + 2
	lda	data_read_buf,y
	sta	a1
	iny
	lda	data_read_buf,y
	sta	a1h
	lm2	bank_data_ptr,a1

	lda	perform_flag
	and	#7fh
	sta	perform_flag
	jmp	is_action_kf

;-------------------------------------------------
;i: Areg(有level限制的功夫) 每个action 12bytes
;o: Areg(action索引号)
;destroy: a1 a2
;-------------------------------------------------
new_random:

	;*************** npc & man ********
	bit	obj_flag	;bit7 1:man 0:npc
	bpl	is_npc_kf
	jsr	find_kf
	lda	man_kf+1,y
	jmp	to_set_lvl
is_npc_kf:
	jsr	find_npc_kf
	lda	npc_kf+1,y
	;*************** npc & man ********
to_set_lvl:
	sta	a2		;level
	ldy	#0
	lda	data_read_buf,y
	sta	a2h

	ldx	#0
	ldy	#2
new_loop:
	lda	a2
	cmp	data_read_buf,y
	bcc	new_rts
	cpx	a2h
	bcs	new_rts

	tya
	clc
	adc	#12
	tay
	inx
	jmp	new_loop

new_rts:
	stx	range
	lm	range+1,#0
	jsr	random_it
	rts
	
find_npc_kf:
	ldx	#0
	ldy	#0
	cpx	npc_kfnum
	beq	no_find
to_find:
	cmp	npc_kf,y
	beq	find_it
	iny
	iny
	inx
	cpx	npc_kfnum
	bcc	to_find
no_find:
	clc
	rts
find_it:
	sec
	rts
;-----------------------------------------------
is_other_text:
	ldy	#0
next_char0:	
	jsr	set_get_buf
next_char:	
	lda	data_read_buf,y
	sta	(string_ptr),y
	beq	get_text_rts
	iny
	bne	next_char
	inc	bank_data_ptr+1
	inc	string_ptr+1
	bne	next_char0
	SSTOP	8

get_text_rts:
	iny
	sta	(string_ptr),y
	lm2	string_ptr,#img_buf
	rts

;---------------------------------------------------------------
	end
