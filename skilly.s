;;******************************************************************
;;	skills.s - process man kf module
;;
;;		function		object
;;	learn	: 向别人请教		师父
;;	study	: 从秘笈或其他物品自学	物品
;;	practice: 练习专业技能		练功房
;;	dazuo	: 运气练功		打气室
;;	enforce	: 使出几点内力伤敌
;;
;;	written by lian
;;	begin on 2001/04/27
;;	finish on 2001/06/27
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

	public	show_perform

	public	query_skill
	public	check_skill
	public	get_basic_kf
	public	get_weapon_kf
	public	get_kf_name
	public	get_pf_name
	public	get_kf_attr
	public	random_kf_action
	
	extrn	kf_name_tbl
	extrn	kf_attr_tbl
	extrn	pf_name_tbl
	extrn	pf_attr_tbl
	extrn	find_kf
	extrn	pop_menu
	extrn	get_goods_attr
	extrn	get_text_data
	extrn	find_name

PERFORM_X0	equ	40
PERFORM_Y0	equ	40

;----------------------------------------------------------------
; input:
; output:
;----------------------------------------------------------------
show_perform:
	PushMenu
	lm2	a1,#dmenu_buf
	jsr	get_all_perform
	lm2	kf_ptr,a1
	lm2	menu_ptr,#perform_menu
	ldx	#PERFORM_X0
	ldy	#PERFORM_Y0
	jsr	pop_menu
	lda	#0ffh
	rts

;---------------------------------
select_it:
	PullMenu
	ldy	menu_set
	iny
	lda	(kf_ptr),y
	rts

;-------------------------------------------
; input: a1
; output: a1
;-------------------------------------------
get_all_perform:
	lm2	a2,a1
	ldy	#0
	lda	man_usekf
	bit	man_weapon
	bpl	is_bare_pf

	lda	man_usekf+1
	bpl	no_weapon_pf
	and	#7fh
	jsr	check_skill
	ldy	#0
	bcc	no_weapon_pf
	lda	man_usekf+1

is_bare_pf:
	jsr	get_perform_loop	;action
no_weapon_pf:
	lda	man_usekf+2
	jsr	get_perform_loop	;dodge
	lda	man_usekf+3
	jsr	get_perform_loop	;force

	tya
	ldy	#0
	sta	(a2),y
	lm2	a1,a2
	rts

;in:Areg Xreg
get_perform_loop:
	cmp	#80h
	bcc	get_perform_rts
	and	#7fh
	sta	kf_id
	ldx	#0ffh
next_pf:
	inx
	lda	pf_attr_tbl,x
	cmp	#0ffh
	beq	get_perform_rts
	cmp	kf_id
	bne	next_pf
	txa
	iny
	sta	(a2),y
	jmp	next_pf
get_perform_rts:
	rts

;----------------------------------------------------------------------
; input: kf_type
; output: skill_level(2byte eff_level)
;----------------------------------------------------------------------
query_skill:
	lm2	skill_level,#0
	lda	kf_type
	jsr	get_basic_kf
	jsr	find_kf
	bcc	query_rts

	lda	man_kf+1,y
	lsr	a
	sta	skill_level

	ldy	kf_type
	lda	man_usekf,y
	bpl	query_rts
	and	#7fh
	jsr	check_skill
	bcc	query_rts
	ldy	kf_type
	lda	man_usekf,y
	and	#7fh
	jsr	find_kf
	bcc	query_rts

	lda	man_kf+1,y
	adda2	skill_level
query_rts:
	rts

;----------------------------------------------------------------------
;	check skill useage condition
; input: Areg(=kf_id)
; output: cy (sec: suc clc: fail) Areg(BASIC_KF:suc err_no: fail)
;	err_no 0: basic_kf error 1: weapon error
; destroy: a1
;----------------------------------------------------------------------
check_skill:
	jsr	get_kf_attr
	ldy	#0
	lda	(a1),y
	cmp	#HAND_KF
	beq	check_hand
	cmp	#WEAPON_KF
	beq	check_weapon
	cmp	#DODGE_KF
	beq	check_dodge
	cmp	#FORCE_KF
	beq	check_force

	sec
	rts

check_hand:
	bit	man_weapon
	bmi	invalid_weapon
	lda	#BASIC_BARE_KF
	jsr	find_kf
	bcc	invalid_base

	sec
	rts

check_weapon:
	bit	man_weapon
	bpl	invalid_weapon

	ldy	#1
	lda	(a1),y
	pha
	lda	man_weapon
	and	#7fh
	jsr	get_goods_attr
	pla
	ldy	#1
	cmp	(a1),y
	bne	invalid_weapon

	tax
	lda	weapon_basic_tbl,x
	jsr	find_kf
	bcc	invalid_base

	sec
	rts

check_dodge:
	lda	#BASIC_DODGE_KF
	jsr	find_kf
	bcc	invalid_base

	sec
	rts

check_force
	lda	#BASIC_FORCE_KF
	jsr	find_kf
	bcc	invalid_base

	sec
	rts

invalid_weapon:
	lda	#1
	clc
	rts
invalid_base:
	lda	#0
	clc
	rts

;---------------------------------------------
; input: Areg (kf_type bit7:0 man 1:npc)
; output: Areg(basic_kf)
;---------------------------------------------
get_basic_kf:
	ldy	man_weapon
	cmp	#80h
	bcc	is_man_basic
	ldy	npc_weapon
	and	#7fh
is_man_basic:
	tax
	tya
	cpx	#WEAPON_KF
	beq	get_weapon_kf
	lda	kf_basic_tbl,x
	rts

get_weapon_kf:
	and	#7fh
	jsr	get_goods_attr
	ldy	#1
	lda	(a1),y
	tax
	lda	weapon_basic_tbl,x
	rts

kf_basic_tbl:
	db	BASIC_BARE_KF,BASIC_SWORD_KF,BASIC_DODGE_KF
	db	BASIC_FORCE_KF,BASIC_PARRY_KF
weapon_basic_tbl
	;矛 刀 棍棒 斧
	db	0ffh,BASIC_BLADE_KF,BASIC_CLUB_KF,0ffh
	;叉 锤 剑 杖杆
	db	0ffh,0ffh,BASIC_SWORD_KF,BASIC_STAFF_KF
	;暗器 鞭
	db	0ffh,BASIC_WHIP_KF

;---------------------------------------------------
; input: kf_id perform_flag
; output: struct action 
; destroy: a1 a1h
;
; struct action {
;	byte	damage_type
;	byte[2]	skill_force
;	byte[2]	damage_point
;	point	string_ptr
; }
;notice: 在功夫库里有 HAND_KF WEAPON_KF DODGE_KF
;---------------------------------------------------
random_kf_action:
	lm	text_class,#KF_TEXT
	lm	text_id,kf_id
	jsr	get_text_data
	rts

;------------------------------------
; input: Areg (=kf_id or perform_id)
; output: a1(name address)
;------------------------------------
get_kf_name:
	lm2	a1,#kf_name_tbl,x
	jsr	find_name
	rts
get_pf_name:
	lm2	a1,#pf_name_tbl,x
	jsr	find_name
	rts

;--------------------------------------
;input: Areg (=kf_id)
;output:a1 a1h
;--------------------------------------
get_kf_attr:
	sta	a1
	lm	a1h,#0
	asl	a1
	rol	a1h

	add	a1,#kf_attr_tbl
	rts

;-------------------------------------
perform_menu:
	db	10011010b
	db	80h
	db	10110001b
	db	ARROW_MENU
	dw	select_it
	dw	pf_name_tbl
;----------------------------------------------------------------
	end
