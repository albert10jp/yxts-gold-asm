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
	public	add_goods

	public	find_goods
	public	set_all_goods
	public	get_goods_name
	public	get_goods_attr

	extrn	goods_name_tbl
	extrn	goods_attr_tbl
	extrn	study_cmd
	extrn	pop_menu
	extrn	list_menu
	extrn	show_menu_txt
	extrn	scroll_to_lcd
	extrn	find_name
	extrn	show_one_line
	extrn	write_one_char
	extrn	wait_key
	extrn	clean_list_right

	extrn	clear_nline2
	extrn	set_get_buf

;---------------------------------------------------------------
; list show food
;---------------------------------------------------------------
show_goods:
	lm2	menu_ptr,#goods_menu
	ldx	#FRAME_X0
	ldy	#FRAME_Y0
	jsr	list_menu
	jsr	scroll_to_lcd
	rts

;-----------------*** deal right functiong ***-------------------
show_all:
	jsr	clear_right
	lm2	a1,#dmenu_buf
	jsr	set_all_goods
	jmp	show_food1
	
deal_diu:
	PushMenu
	jsr	init_goods_menu
	lm2	menu_ptr,#right_menu3
	jsr	pop_menu
	rts

show_food:
	jsr	clear_right
	lm	goods_type,menu_set
	lm2	a1,#dmenu_buf
	jsr	set_goods
show_food1:	
	lm2	goods_ptr,a1
	jsr	init_goods_menu
	jsr	show_menu_txt
	rts

deal_food:
deal_other:
	PushMenu
	jsr	init_goods_menu
	jsr	pop_menu
	rts

show_equip:
	jsr	clear_right
	lm	goods_type,menu_set
	lm2	a1,#dmenu_buf
	jsr	set_goods
	lm2	goods_ptr,a1
	jsr	init_goods_menu
	lm2	menu_ptr,#right_menu1
	jsr	show_menu_txt
	rts

deal_equip:
	PushMenu
	jsr	init_goods_menu
	lm2	menu_ptr,#right_menu1
	jsr	pop_menu
	rts

show_other:
	jsr	clear_right
	lm2	a1,#dmenu_buf
	jsr	set_other_goods
	jmp	show_food1

	if	0
deal_other:
	PushMenu
	jsr	init_goods_menu
	jsr	pop_menu
	;CLS_NLINE2	#79-13,#13
	rts
	endif

clear_right:
	jsr	clean_list_right
	clc
	lda	list_y1
	adc	#2
	sta	a1
	CLS_NLINE2     a1,#13
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
; input: a1
; ouput: a1
; type: BOOK_WU OTHER_WU
;------------------------------------------------------
set_other_goods:
	lm	goods_type,#BOOK_WU
	jsr	set_goods
	lm	goods_type,#OTHER_WU
	lm	tmp1,#0
	jsr	set_goods_l
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

	lda	goods_type
	cmp	#WEAPON_WU
	beq	set_goods_next
	cmp	#EQUIP_WU
	beq	set_goods_next
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

;------------------------------------------------------
;	all goods ==> (a1)
; input: a1
; output: a1
; Destroy:
;------------------------------------------------------
set_all_goods:
	lda	#0
	tax
	tay

all_goods_l:
	lda	man_goods+1,x
	beq	all_goods_next

	lda	man_goods,x
	cmp	#SANJIAO
	beq	all_goods_next
	iny
	sta	(a1),y
	lda	man_goods+1,x
	iny
	sta	(a1),y
all_goods_next:
	inx
	inx
	cpx	#MAX_GOODS*2
	bcc	all_goods_l

	tya
	lsr	a
	ldy	#0
	sta	(a1),y
	rts

;---------------------------------------------------------------
; input: menu_set
; output: goods_id
;---------------------------------------------------------------
show_desc1:
	lda	menu_set
	jmp	to_show_desc
show_desc2:
	lda	menu_set
	asl	a
to_show_desc:
	tay
	iny
	lda	(kf_ptr),y
	sta	goods_id
	and	#7fh
	jsr	get_goods_desc

desc_loop:
	clc
	lda	list_y1
	adc	#2
	sta	a1
	CLS_NLINE2	a1,#13
	ldx	#0
	ldy	list_y1
	iny
	iny
	iny
	dec	char_row
	jsr	show_one_line
	inc	char_row
	lda	(string_ptr),y
	beq	desc_rts

	tya
	adda2	string_ptr
	lm	fccode,#'>'
	ldx	#25
	ldy	list_y1
	iny
	iny
	iny
	jsr	write_one_char
	jsr	wait_key
	cmp	#RIGHT_KEY
	beq	desc_loop
	ora	#80h
	sta	key
desc_rts:
	rts

;---------------------------------------------------------------
; input: Areg
; output: string_ptr
; destroy: Areg Xreg Yreg
;---------------------------------------------------------------
get_goods_desc:
	pha
	lm	bank_no,#1
	lda	#GOODS_DESC
	asl	a
	tay
	lda	txt_class_tbl,y
	sta	bank_data_ptr
	lda	txt_class_tbl+1,y
	sta	bank_data_ptr+1
	pla
	asl	a
	tay
	jsr	set_get_buf
	sta	bank_data_ptr
	iny
	lda	data_read_buf,y
	sta	bank_data_ptr+1
	jsr	set_get_buf
	lm2	a1,#data_read_buf
	ldy     #0ffh
desc_l:
        iny
        lda     (a1),y
	sta	img_buf,y
        bne     desc_l
	iny
	sta	img_buf,y
	lm2	string_ptr,#img_buf
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
	ldy	#0
	lda	(a1),y
	sta	goods_type
	cmp	#FOOD_WU
	beq	to_use_food
	cmp	#DRUG_WU
	beq	to_use_drug
	cmp	#WEAPON_WU
	beq	to_use_weapon
	cmp	#EQUIP_WU
	beq	to_use_equip
	cmp	#BOOK_WU
	beq	to_use_book
	cmp	#OTHER_WU
	beq	to_use_other
	SSTOP	7

to_use_food:
	jsr	use_food
	PullMenu
	rts

to_use_drug:
	jsr	use_drug
	PullMenu
	rts

to_use_weapon:
	jsr	use_weapon
	PullMenu
	rts

to_use_equip:
	jsr	use_equip
	PullMenu
	rts

to_use_book:
	jsr	use_book
	rts

to_use_other:
	PullMenu
	rts
;---------------------------------------------------------------

;--------------------------------------
;input:goods_type goods_id a1 Xreg
;--------------------------------------
use_food:
	cmp2	man_food,man_maxfood
	bcs	food_rts
	dec	man_goods+1,x

	ldy	#2
	lda	(a1),y
	adda2	man_food

	iny
	lda	(a1),y
	adda2	man_water
food_rts:
	rts
	
diu_goods:
	lda	goods_id
	jsr	find_goods
	lda	man_goods,x
	bmi	diu_goods1
	dec	man_goods+1,x
diu_goods1:	
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

;--------------------------------------
;input:goods_type goods_id a1 Xreg
;--------------------------------------
use_weapon:
	bit	man_weapon
	bpl	wield_weapon
	bit	goods_id
	bmi	unwield_weapon
	rts

wield_weapon:
	lda	goods_id
	eor	#80h
	sta	man_goods,x
	sta	man_weapon

	ldy	#2
	clc
	lda	man_damage
	adc	(a1),y
	bcc	$+4
	lda	#0ffh
	sta	man_damage
	jmp	wield_goods

unwield_weapon:
	lda	goods_id
	eor	#80h
	sta	man_goods,x
	sta	man_weapon

	ldy	#2
	sec
	lda	man_damage
	sbc	(a1),y
	bcs	$+4
	lda	#0
	sta	man_damage
	jmp	unwield_goods

;--------------------------------------
;input:goods_type goods_id a1 Xreg
;--------------------------------------
use_equip:
	ldy	#1
	lda	(a1),y
	tay
	lda	man_equip,y
	bpl	wield_equip
	bit	goods_id
	bmi	unwield_equip
	rts

wield_equip:
	lda	goods_id
	eor	#80h
	sta	man_goods,x
	sta	man_equip,y

	ldy	#2
	clc
	lda	man_armor
	adc	(a1),y
	bcc	$+4
	lda	#0ffh
	sta	man_armor
	jmp	wield_goods

unwield_equip:
	lda	goods_id
	eor	#80h
	sta	man_goods,x
	sta	man_equip,y

	ldy	#2
	sec
	lda	man_armor
	sbc	(a1),y
	bcs	$+4
	lda	#0
	sta	man_armor
	jmp	unwield_goods

wield_goods:
	iny
	clc
	lda	man_attack
	adc	(a1),y
	bpl	$+4
	lda	#0
	sta	man_attack

	iny
	clc
	lda	man_defense
	adc	(a1),y
	bpl	$+4
	lda	#0
	sta	man_defense
	rts

unwield_goods:
	iny
	sec
	lda	man_attack
	sbc	(a1),y
	bpl	$+4
	lda	#0
	sta	man_attack

	iny
	sec
	lda	man_defense
	sbc	(a1),y
	bpl	$+4
	lda	#0
	sta	man_defense
	rts

;--------------------------------------
;input:goods_type goods_id a1 Xreg
;--------------------------------------
use_book:
	ldy	#2
	lda	(a1),y
	tax
	iny
	lda	(a1),y
	stx	a1
	sta	a1h
	jsr	study_cmd
	rts

;------------------------------------
; input: goods_id
; output: cy (sec: suc clc: fail)
;------------------------------------
add_goods:
	lda	goods_id
	jsr	find_goods
	bcc	to_empty

	lda	goods_id
	jsr	get_goods_attr
	ldy	#0
	lda	(a1),y
	cmp	#WEAPON_WU
	beq	to_empty
	cmp	#EQUIP_WU
	beq	to_empty
	bne	inc_it
ins_it:
	sta	man_goods,x
inc_it:
	inc	man_goods+1,x
	sec
	rts

to_empty:
	lda	goods_id
	ldx	#0
find_empty:
	ldy	man_goods+1,x
	beq	ins_it
	inx
	inx
	cpx	#MAX_GOODS*2
	bcc	find_empty
	clc
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
	db	6
	db	01010001b
	db	NORMAL_MENU
	dw	deal_food,show_food
	dw	deal_food,show_food
	dw	deal_equip,show_equip
	dw	deal_equip,show_equip
	dw	deal_other,show_other
	dw	deal_diu,show_all
	if	scode
	db	'食物',0ffh
	db	'药物',0ffh
	db	'武器',0ffh
	db	'装备',0ffh
	db	'其它',0ffh
	db	'丢弃',0ffh
	else
	db	'',0ffh
	db	'媚',0ffh
	db	'猌竟',0ffh
	db	'杆称',0ffh
	db	'ㄤウ',0ffh
	db	'メ斌',0ffh
	endif

right_menu:
	db	11111010b
	db	80h
	db	01010001b
	db	BOX_MENU
	dw	use_goods,show_desc2
	dw	goods_name_tbl
right_menu1:
	db	11011000b
	db	80h
	db	01010001b
	db	CHECK_MENU1
	dw	use_goods,show_desc1
	dw	goods_name_tbl
right_menu3:
	db	11111010b
	db	80h
	db	01010001b
	db	BOX_MENU
	dw	diu_goods,show_desc2
	dw	goods_name_tbl

;-------------------------------------------------------------------
	end
