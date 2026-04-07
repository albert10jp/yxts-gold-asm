;;******************************************************************
;;	goods.s - process goods
;;
;;		function		object
;;	use_goods			使用物品
;;	wield_weapon			装备武器
;;	wear_armor			装备防具
;;
;;	written by lian
;;	begin on 2001/04/28
;;
;;     ┏━━━━━━━━━━━━━━━━━━━━━━┓
;;     ┃	死不是生的对立面,而是生的一部分      ┃
;;     ┗━━━━━━━━━━━━━━━━━━━━━━┛
;;
;;******************************************************************
	include	h/gmud.h
	include	h/id.h
	include	h/func.mac
	include	h/mud_funcs.h
	
	public	show_goods

	public	find_goods
	public	get_goods_name
	public	get_goods_attr

	extrn	goods_name_tbl
	extrn	goods_attr_tbl
	extrn	pop_menu
	extrn	list_menu
	extrn	show_menu_txt
	extrn	scroll_to_lcd
	extrn	find_name
	extrn	clean_list_right

;---------------------------------------------------------------
; list show food
;---------------------------------------------------------------
show_goods:
	lm	key,#CR_KEY|80h
	lm2	menu_ptr,#goods_menu
	ldx	#FRAME_X0
	ldy	#FRAME_Y0
	jsr	list_menu
	jsr	scroll_to_lcd
	rts

;-----------------*** deal right functiong ***-------------------
show_food:
	jsr	clean_list_right
	lm	goods_type,#DRUG_WU
	lm2	a1,#dmenu_buf
	jsr	set_goods
	lm2	goods_ptr,a1
	jsr	init_goods_menu
	jsr	show_menu_txt
	rts

deal_food:
	PushMenu
	jsr	init_goods_menu
	jsr	pop_menu
	lm	key,#ESC_KEY|80h
	rts

;-----------------*** deal right functiong ***-------------------

;---------------------------------------------------------------
;	init dynamic goods menu
; input: list_x0 list_y0
; outpu: a1 menu_ptr Xreg Yreg
;---------------------------------------------------------------
init_goods_menu:
	lm2	a1,goods_ptr
	lm2	menu_ptr,#right_menu
	clc
	lda	list_x0
	adc	#5
	tax
	ldy	list_y0
	rts

;------------------------------------------------------
;	goods_num man_goods ==> (a1)
; input: goods_type a1
; output: a1
; Destroy: tmp1 tmp2 a2
;------------------------------------------------------
set_goods:
	lm2	a2,a1
	lda	#0
	sta	tmp1	; index of goods
	sta	tmp2	; goods_num
	tay

set_goods_l:
	ldx	tmp1
	lda	man_goods+1,x
	beq	set_goods_next

	lda	man_goods,x
	and	#7fh
	jsr	get_goods_attr
	lda	goods_type
	ldx	#0
	cmp	(a1,x)
	bne	set_goods_next

	inc	tmp2
	ldx	tmp1
	lda	man_goods,x
	iny
	sta	(a2),y

is_num_goods:
	lda	man_goods+1,x
	iny
	sta	(a2),y

set_goods_next:
	inc	tmp1
	inc	tmp1
	cmp1	tmp1,#MAX_GOODS*2
	bcc	set_goods_l

	lda	tmp2
	ldx	#0
	sta	(a2,x)
	lm2	a1,a2
	rts

;---------------------------------------------------------------
; input: goods_id
; output: 
;---------------------------------------------------------------
use_goods:
	lda	goods_id
	jsr	find_goods
	lda	goods_id
	and	#7fh
	jsr	get_goods_attr
to_use_drug:
	jsr	use_drug
	PullMenu
	rts

;--------------------------------------
;input:goods_type goods_id a1 Xreg
;--------------------------------------
use_drug:
	ldy	#1
	lda	(a1),y
	beq	improve_effhp
	cmp	#1
	beq	improve_maxhp
	rts

improve_effhp:
	cmp2	man_effhp,man_maxhp
	bcs	effhp_rts
	dec	man_goods+1,x

	lm2	a2,man_maxhp
	lsr2	a2
	ldy	#2
	lda	(a1),y
	beq	improve_1
	lsr2	a2
improve_1:	
	add	man_effhp,a2
	cmp2	man_maxhp,man_effhp
	bcs	effhp_rts
	lm2	man_effhp,man_maxhp
effhp_rts:
	rts

improve_maxhp
	dec	man_goods+1,x
	ldy	#2
	lda	(a1),y
	adda2	man_maxfp
	rts

;------------------------------------
; input: Areg(goods_id)
; output: a1(name address)
;------------------------------------
get_goods_name:
	lm2	a1,#goods_name_tbl,x
	jsr	find_name
	rts

;--------------------------------------
;input: Areg (=goods_id)
;output:a1 a1h=Areg*8+goods_attr_tbl
;--------------------------------------
get_goods_attr:
	sta	a1
	lm	a1h,#0
	rept	3
	asl	a1
	rol	a1h
	endr

	add	a1,#goods_attr_tbl
	rts

;----------------------------------------------------
; input: Areg (=goods_id)
; output: C(sec:find, sec:no find) Xreg
; Destry:
;----------------------------------------------------
find_goods:
	ldx	#0
to_find:
	ldy	man_goods+1,x
	beq	to_find_next
	cmp	man_goods,x
	beq	find_it
to_find_next:
	inx
	inx
	cpx	#MAX_GOODS*2
	bcc	to_find
	clc
	rts

find_it:
	sec
	rts

;---------------------------------------------------------------
goods_menu:
	db	01000000b
	db	1
	db	00000001b
	db	NORMAL_MENU
	dw	deal_food,show_food
	if	scode
	db	'药物',0ffh
	else
	db	'媚',0ffh
	endif

right_menu:
	db	11111010b
	db	80h
	db	01010001b
	db	BOX_MENU
	dw	use_goods,show_desc
	dw	goods_name_tbl
show_desc:
	lda	menu_set
	asl	a
	tay
	iny
	lda	(kf_ptr),y
	sta	goods_id
	rts

;-------------------------------------------------------------------
	end
