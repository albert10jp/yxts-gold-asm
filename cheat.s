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

	public	cheat

	extrn	find_kf
	extrn	kf_name_tbl
	extrn	kf_attr_tbl

	extrn	pop_menu
	extrn	list_menu
	extrn	show_menu_txt
	extrn	scroll_to_lcd

	extrn	clear_nline2
	extrn	format_string
	extrn	show_one_line
	extrn	wait_key

LEARN_X0	equ	80
LEARN_Y0	equ	FRAME_Y0+8
PERFORM_X0	equ	40
PERFORM_Y0	equ	40
MAX_DESC	equ	50
;---------------------------------------------------------------
; list show skills
;---------------------------------------------------------------
cheat:
	PushMenu	1
	jsr	scroll_to_lcd
	ldx	#MAIN_X0
	ldy	#MAIN_Y0
	lm2	menu_ptr,#main_menu
	jsr	pop_menu
	jsr	scroll_to_lcd
	rts
	
main_menu:
	db	00000000b	;格式
	db	2		;菜单总数
	db	10000100b	;格式
	db	ARROW_MENU	;菜单方式
	dw	show_value
	dw	show_skills

	if	scode
	db	'查看',0ffh
	db	'技能',0ffh
	else
	db	'琩',0ffh
	db	'м',0ffh
	endif
;--------------------------------------------------------------
show_value:
	ldx	#10
	ldy	#15
	lm2	menu_ptr,#fight_menu
	jsr	pop_menu
	jsr	scroll_to_lcd
	rts

add_money:
	lm2	value_msg+1,#man_money
	lm	value_msg,#4
	jmp	add_com
add_exp:
	lm2	value_msg+1,#man_exp
	lm	value_msg,#4
	jmp	add_com
add_pot:
	lm2	value_msg+1,#man_pot
	lm	value_msg,#2
	jmp	add_com
add_daode:
	lm2	value_msg+1,#man_daode
	lm	value_msg,#1
	jmp	add_com
add_fp:
	lm2	value_msg+1,#man_maxfp
	lm	value_msg,#2
	jmp	add_com
add_sikill:
	lm2	value_msg+1,#si_kill
	lm	value_msg,#1
	jmp	add_com
add_guankill:
	lm2	value_msg+1,#guan_kill
	lm	value_msg,#1
	jmp	add_com
add_kill:
	lm2	value_msg+1,#npc_kill
	lm	value_msg,#1
	jmp	add_com
add_gender:
	lm2	value_msg+1,#man_gender
	lm	value_msg,#1
	jmp	add_com
add_per:
	lm2	value_msg+1,#man_per
	lm	value_msg,#1
	jmp	add_com
add_age:
	lm2	value_msg+1,#mud_age
	lm	value_msg,#4
	jmp	add_com
add_time:
	lm2	value_msg+1,#game_hour
	lm	value_msg,#2
	jmp	add_com
add_dance:
	lm2	value_msg+1,#top_dance
	lm	value_msg,#2
	jmp	add_com
add_ball:
	lm2	value_msg+1,#top_ball
	lm	value_msg,#2
add_com:
	CLS_NLINE2 #66,#13
	lm2	string_ptr,#value_msg
	jsr	format_string
	ldx	#8
	ldy	#66
	jsr	show_one_line
	jsr	wait_key
	cmp	#ESC_KEY
	beq	add_rts
	SWITCH	#cmd_len,cmd
	jmp	add_com
add_rts:	
	CLS_NLINE2 #66,#13
	rts

add_1:
	lm2	a1,value_msg+1
	ldy	#0
	lda	(a1),y
	clc
	adc	#1
	sta	(a1),y
	rts
add_10h:
	lm2	a1,value_msg+1
	ldy	#0
	lda	(a1),y
	clc
	adc	#10h
	sta	(a1),y
	rts
add_100h:
	lda	value_msg
	cmp	#2
	bcc	add_100rts
	lm2	a1,value_msg+1
	ldy	#1
	lda	(a1),y
	clc
	adc	#1
	sta	(a1),y
add_100rts:	
	rts
add_1000h:
	lda	value_msg
	cmp	#2
	bcc	add_100rts
	lm2	a1,value_msg+1
	ldy	#1
	lda	(a1),y
	clc
	adc	#10h
	sta	(a1),y
	rts
add_10000h:
	lda	value_msg
	cmp	#3
	bcc	add_100rts
	lm2	a1,value_msg+1
	ldy	#2
	lda	(a1),y
	clc
	adc	#1
	sta	(a1),y
	rts

cmd:
	db	'qwert'
cmd_len	equ	$-cmd	
	dw	add_10000h
	dw	add_1000h
	dw	add_100h
	dw	add_10h
	dw	add_1

fight_menu:
	db	00000000b	;格式
	db	14		;菜单总数
	db	00010000b	;格式
	db	ICON_MENU	;菜单方式
	dw	add_money	;程序地址
	dw	add_exp		;程序地址
	dw	add_pot
	dw	add_fp
	dw	add_daode
	dw	add_sikill
	dw	add_guankill
	dw	add_kill
	dw	add_gender
	dw	add_per
	dw	add_age
	dw	add_time
	dw	add_dance
	dw	add_ball

	if	scode
	db	'金钱',0ffh
	db	'经验',0ffh
	db	'潜能',0ffh
	db	'内力',0ffh
	db	'名声',0ffh
	db	'杀手',0ffh
	db	'捕快',0ffh
	db	'屠杀',0ffh
	db	'性别',0ffh
	db	'容貌',0ffh
	db	'年龄',0ffh
	db	'时间',0ffh
	db	'跳舞',0ffh
	db	'投篮',0ffh

	else
	db	'窥',0ffh
	db	'竒喷',0ffh
	db	'肩',0ffh
	db	'ず',0ffh
	db	'羘',0ffh
	db	'炳も',0ffh
	db	'е',0ffh
	db	'監炳',0ffh
	db	'┦',0ffh
	db	'甧华',0ffh
	db	'闹',0ffh
	db	'丁',0ffh
	db	'铬籖',0ffh
	db	'щ屡',0ffh
	endif
value_msg:
	db	1
	dw	varbuf,0
	db	0
;--------------------------------------------------------------
show_skills:
	lm2	menu_ptr,#left_menu
	ldx	#FRAME_X0
	ldy	#FRAME_Y0
	jsr	list_menu
	jsr	scroll_to_lcd
	rts

;---------------------------------------------------------------
deal_kf:
	PushMenu
	jsr	init_skills_menu
	lm	menu_set,#0
	jsr	pop_menu
	rts

show_kf:
	jsr	clear_right
	jsr	init_skills_menu
	jsr	show_menu_txt
	rts

clear_right:
	extrn	clean_list_right
	jsr	clean_list_right

	clc
	lda	list_y1
	adc	#2
	sta	a1
	CLS_NLINE2     a1,#13
	rts

;---------------------------------------------------------------
; input: list_x0 list_y0 menu_item
; outpu: a1 menu_ptr Xreg Yreg
;---------------------------------------------------------------
init_skills_menu:
	lm	kf_type,menu_set
	lda	#0ffh
	sta	kf_id
	lm2	a1,#dmenu_buf
	jsr	set_kf
	lm2	kf_ptr,a1

	lm2	menu_ptr,#right_menu
	clc
	lda	list_x0
	adc	#5
	tax
	ldy	list_y0
	rts

;------------------------------------------------------
;	man_kf ==> (a1) (Type == Areg)
; input: kf_Type kf_id a1
; output: a1 menu_set
; Destroy: tmp1 tmp2 a2
;------------------------------------------------------
set_kf:
	lm2	a2,a1
	lm	tmp1,kf_id
	ldy	#0
	ldx	#0ffh
	stx	tmp2

set_kf_l:
	inc	tmp2
	lda	tmp2
	cmp	man_kfnum
	bcs	set_kf_ok

	masl	a,2
	tax
	lda	man_kf,x
	sta	kf_id
	jsr	get_kf_attr
	lda	kf_type
	ldx	#0
	cmp	(a1,x)
	bne	set_kf_l

	lda	kf_id
	iny
	sta	(a2),y
	jmp	set_kf_l

set_kf_ok:
	tya
	ldy	#0
	sta	(a2),y
	lm2	a1,a2
	rts

;---------------------------------------------------------------
; input: menu_set
; output: kf_id
;---------------------------------------------------------------
show_desc:
	ldy	menu_set
	iny
	lda	(kf_ptr),y
	sta	kf_id

	jsr	find_kf
	lda	man_kf+1,y
	sta	varbuf

	lm2	string_ptr,#desc_msg
	jsr	format_string
	ldx	#8
	ldy	list_y1
	iny
	iny
	iny
	jsr	show_one_line
	rts

desc_msg:
	db	3
	dw	varbuf,0
	db	0

;---------------------------------------------------------------
; input: kf_id
; output:
;---------------------------------------------------------------
use_skills:
	lda	kf_id
	jsr	find_kf
	lda	man_kf+1,y
	clc
	adc	#5
	bcc	$+4
	lda	#0ffh
	sta	man_kf+1,y
	rts

;-------------------------------------
left_menu:
	db	01010000b
	db	6
	db	01010001b
	db	NORMAL_MENU
	dw	deal_kf,show_kf
	if	scode
	db	'拳脚',0ffh
	db	'兵刃',0ffh
	db	'轻功',0ffh
	db	'内功',0ffh
	db	'招架',0ffh
	db	'知识',0ffh
	else
	db	'竲',0ffh
	db	'',0ffh
	db	'淮',0ffh
	db	'ず',0ffh
	db	'┷琜',0ffh
	db	'醚',0ffh
	endif

right_menu:
	db	11011010b
	db	80h
	db	01011001b
	db	BOX_MENU
	dw	use_skills,show_desc
	dw	kf_name_tbl

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
;----------------------------------------------------------------
	end
