;===========================================================
;
;	npc身上的quest
;	
;	writen by : pyh		2001/9/10
;
;
;===========================================================
;struct{
;		char 	*msg[2];
;		int	give_id;
;		int	give_count;
;		int	receive_id;
;	}npc_quest;
;aqing:		
;	dw	aqing_msg
;	db	0ffh,0ffh,0ffh
;	共5个字节,

	include	h/gmud.h
	include	h/id.h
	include	h/mud_funcs.h

GIVE_OFF	equ	2
RECEIVE_OFF	equ	4
STRUCT_NUMBER	equ	5		;结构总字节数

__base	equ	game_buf
	define	1,msg_number
	define	2,msg_addr
	define	1,give_id
	define	1,give_count
	define	1,receive_id
	
	define	1,tmp1
	define	1,tmp2
	define	1,tmp3

	public	npc_quest

;-------------------
	extrn	random_it
	extrn	mul_ax
	extrn	scroll_to_lcd
	extrn	find_goods
	extrn	message_box_for_pyh
	extrn	add_goods
	extrn	show_talk_msg
	extrn	wait_key

	extrn	set_get_buf
;-------------------


;*********************************************
;	input:A(located_id)
;*********************************************
npc_quest:
	sta	tmp1
	jsr	find_id
	bcc	have_quest
	sec
	rts

have_quest:
	tya
	ldx	#STRUCT_NUMBER
	jsr	mul_ax
		;最大: 255 / STRUCT_NUMBER(5) (个)quest,超过就有错误
		;如果想增加数量,可以用双字节
	jsr	get_quest_data
	ldy	#0
	lda	data_read_buf,y
	sta	msg_number
	sta	range
	lm	range+1,#0
	jsr	random_it
	tax
	lm2	a1,#data_read_buf
	jsr	get_n_msg
	jsr	move_text
	jsr	show_talk_msg		;说了第一句话

	cmp1	give_id,#0ffh
	bne	have_give_id
npc_quest_rts:
	jsr	scroll_to_lcd
	clc
	rts

have_give_id:
	lm	goods_id,give_id
	jsr	find_goods
	bcc	npc_quest_rts			;not find goods
	lda	man_goods+1,x
	cmp	give_count
	bcc	npc_quest_rts			;数量不对

	lm2	a1,#data_read_buf
	ldx	msg_number
	jsr	get_n_msg
	jsr	move_text
	lm	x0,#6
	lm	y0,#0
	lm	x1,#6+12*12
	lm	y1,#50
	jsr	message_box_for_pyh		;bcc : confirm
	bcs	npc_quest_rts
	jsr	scroll_to_lcd

	lm	goods_id,give_id
	jsr	find_goods
	lda	man_goods+1,x
	sec
	sbc	give_count
	sta	man_goods+1,x
	lm	goods_id,receive_id
	jsr	add_goods
	
	inc	msg_number
	lm2	a1,#data_read_buf
	ldx	msg_number
	jsr	get_n_msg
	jsr	move_text
	jsr	show_talk_msg
	jmp	npc_quest_rts

;======================================================
;	查找是否有相应的id
;	cy=1 (not find) cy=0 (find) 
;	Yreg (position)
;======================================================
find_id:
	lda	#NPC_ID
	asl	a
	tay
	lm	bank_no,#1
	lda	txt_class_tbl,y
	sta	bank_data_ptr
	lda	txt_class_tbl+1,y
	sta	bank_data_ptr+1
	jsr	set_get_buf
	ldy	#0ffh
find_id_loop:
	iny
	lda	data_read_buf,y
	cmp	#NONE_NPC
	beq	find_not
	cmp	tmp1
	bne	find_id_loop
find_id_rts:
	clc
find_not:	
	rts

;======================================================
;	取第几句话
;	input:Xreg,msg_addr
;	output:a1(n_msg_addr)
;======================================================
get_n_msg:
	stx	tmp1
	inc2	a1			;skip msg_number
	lda	tmp1
	beq	get_msg_rts
	lm	tmp2,#0
get_msg_loop:
	jsr	skip_one_msg
	inc	tmp2
	cmp1	tmp2,tmp1
	bne	get_msg_loop
get_msg_rts:
	rts

;======================================================
;	跳过一条msg,连续遇到两个0,表示一句话结束
;	input:a1
;	output:a1
;======================================================
skip_one_msg:
	ldy	#0
skip_loop:
	lda	(a1),y
	beq	check_next_zero
	iny
	bne	skip_loop
check_next_zero:
	iny
	lda	(a1),y
	beq	skip_one_rts
	iny	
	bne	skip_loop
skip_one_rts:
	iny
	tya
	adda2	a1
	rts
;======================================================
;	input:a1
;	output:string_ptr
;	destroy:bank_text,Yreg
;======================================================
move_text:
	ldy	#0
move_text_loop:
	lda	(a1),y
	sta	bank_text,y
	iny
	cpy	#200
	bcc	move_text_loop
	lm2	string_ptr,#bank_text
	rts
;======================================================
;	得到结构中的数据
;	input:Yreg,ncp_quest_tbl
;	output:	msg_addr,give_id,give_count,
;		receive_id,receive_count
;======================================================
get_quest_data:
	pha
	lda	#NPC_QUEST
	asl	a
	tay
	lm	bank_no,#1
	lda	txt_class_tbl,y
	sta	bank_data_ptr
	lda	txt_class_tbl+1,y
	sta	bank_data_ptr+1
	jsr	set_get_buf
	pla
	tay
	
	ldx	#0
get_data_loop:
	lda	data_read_buf,y
	sta	msg_addr,x
	inx
	iny
	cpy	#STRUCT_NUMBER
	bne	get_data_loop
	lm2	bank_data_ptr,msg_addr
	jsr	set_get_buf
	rts
;------------------------------------------------------------
	end
