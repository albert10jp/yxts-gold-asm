;;******************************************************************
;;	gmud.s - ggv MUD engine
;;
;;	written by lian
;;	begin on 2001/03/13
;;	finish on
;;
;;     ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
;;     ┃ 	高尚是高尚者的墓志铭,卑鄙是卑鄙者的通行证      ┃
;;     ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
;;
;;*******************************************************************
	include	h/gmud.h
	include	h/id.h

	public	get_player_img
	public	get_player
	public	get_img_data
	public	get_img_data_fast
	public	scroll_to_lcd
	public	lcd_to_scroll

	extrn	speed_read
	extrn	speed_read_2

	extrn	mul_ax

;;************************************************************************
;-------------------------------------------------------
;功能	: 取出人物的图象
;
;Input	: Areg
;
;Output	: fccode
;Destroy: bank_text
;-------------------------------------------------------
get_player_img:
	asl	a
	sta	a1
	lm	a1h,#0
	add	a1,#player_img_tbl
get_player:
	lm	bank_no,#1
	ldy	#0
	lda	(a1),y
	sta	SeekOffset
	iny
	lda	(a1),y
	sta	SeekOffset+1
	lm2	DataBufPtr,#img_buf+2
	lm2	DataCount,#192
	jsr	speed_read
	lda	#32
	sta	img_buf
	lda	#48
	sta	img_buf+1
	lm2	fccode,#img_buf
	rts
;-------------
player_img_tbl:
l	=	0a600h+3*0c0h
	rept	9
	dw	l
l	=	l+0c0h
	endr

l	=	0a600h
	rept	3
	dw	l
l	=	l+0c0h
	endr

;-------------------------------------------------------
;说明: 	id为两字节,高字节四位表示属性,id用12位,表示范围
;	最大为4096,对于目前的wqx游戏,包括物品,背景,人物
;	的所有id已经足够了,如果想扩展,就缩小属性位的范围
;
;功能:	从rom中取出指定id的数据,数据肯能存放在n个bank中
;	取出的数据放于img_buf中
;
;注意:  为提高速度,程序已经只适合取32x32的图象
;input:	img_id,G_img_cmd
;output: fccode (数据存放位置指针)
;	 item_width 
;	 item_height
;destroy: intc
;-------------------------------------------------------
get_img_data:
	lm	item_width,#32
	sta	G_img_buf
	lm	item_height,#32
	sta	G_img_buf+1

	lm2	fccode,#G_img_buf
get_img_data_fast:
	lda	G_img_cmd
	bne	get_fast1
	lm2	DataBufPtr,#G_img_buf+2
	lm2	DataCount,#32*4
	jsr	get_img_attr
	jsr	speed_read
	rts
get_fast1:
	ldx	fast_and
	cmp	#3
	bne	get_fast4
	ldx	fast_or
get_fast4:
	stx	get_fast3	;指令的动态修改 LEE!!!
	lm2	DataBufPtr,#G_and_or
	lm2	DataCount,#32*4
	jsr	get_img_attr
	jsr	speed_read
	ldx	#127
get_fast2:	
	lda	G_img_buf+2,x
get_fast3:	
	and	G_and_or,x
	sta	G_img_buf+2,x
	dex
	bpl	get_fast2
	rts
fast_and:
	and	G_and_or,x
fast_or:
	ora	G_and_or,x

;-------------------------------------------------------
;	get img_ID 的相关参数
;
; input: item_id item_class
; output: fccode item_width item_height
; destroy: a1 a1h
;
; struct img_ID {
;	byte item_width,
;	byte item_height,
;	void *fccode 
; 	}
;-------------------------------------------------------
get_img_attr:
	lm	a1,#0
	lm	a1h,item_id

	;a1 * 128
	lda	item_id+1
	lsr	a
	ror	a1h
	ror	a1
	clc
	adc	#2
	sta	bank_no

	lm2	SeekOffset,a1
	rts

;---------------------------------------
; 将scroll_buf ==> lcdbuf 
; 总共 CPR*VDPS bytes
;---------------------------------------
lcd_to_scroll:
	lm2	a1,#lcdbuf
	lm2	a2,#scroll_buf
	ldx	#VDPS
	bne	to_lcd_begin1
scroll_to_lcd:
	lm2	a1,#scroll_buf
	lm2	a2,#lcdbuf
	ldx	#VDPS

to_lcd_begin1:
	ldy	#0
	lda	(a1),y
	and	#7fh		;清除icon	Lee 2003.2.25
	sta	(a2),y
	iny
to_lcd_begin2:
	lda	(a1),y
	sta	(a2),y
	iny
	cpy	#CPR
	bcc	to_lcd_begin2

	dex
	beq	to_lcd_rts

	lda	#CPR
	adda2	a1
	lda	#CPR
	adda2	a2
	jmp	to_lcd_begin1

to_lcd_rts:
	rts

;---------------------------------------------------------------
	end
