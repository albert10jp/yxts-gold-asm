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

	public	show_skills
	public	show_perform
	public	study_cmd
	public	practice_cmd
	public	dazuo_cmd
	public	improve_skill
	public	setup_attr
	public	get_skill_desc
	
	public	query_skill
	public	check_skill
	public	get_basic_kf
	public	get_weapon_kf
	public	add_kf
	public	get_kf_name
	public	get_pf_name
	public	get_kf_attr
	
	extrn	kf_name_tbl
	extrn	kf_attr_tbl
	extrn	pf_name_tbl
	extrn	pf_attr_tbl
	extrn	find_kf
	extrn	pop_menu
	extrn	list_menu
	extrn	show_menu_txt
	extrn	scroll_to_lcd
	extrn	show_process
	extrn	get_goods_attr
	extrn	format_string
	extrn	get_text_data
	extrn	show_one_line
	extrn	find_name

	extrn	mul_ax
	extrn	divid_ax
	extrn	divid2
	extrn	clear_nline2
        extrn 	pyh_practice
	extrn	dazuo
	extrn	master1

LEARN_X0	equ	80
LEARN_Y0	equ	FRAME_Y0+8
PERFORM_X0	equ	40
PERFORM_Y0	equ	40
MAX_DESC	equ	50
;----------------------------------------------------------------
; input: a1(book struct)
; output:
;----------------------------------------------------------------
study_cmd:
	lda	goods_id
	cmp	#BAODIAN
	bne	study_1
	lda	man_gender
	cmp	#2
	beq	study_1
	lm2	string_ptr,#book_bao_msg
	jsr	to_show_study
	cmp	#'y'
	bne	study_rts
	lm2	string_ptr,#book_bao_msg2
	jsr	to_show_study
	cmp	#'y'
	bne	study_rts
	lm	man_gender,#2
	bne	study_rts
study_1:
	lm2	string_ptr,#book_fail1_msg
	lda	#LITERATE_KF
	jsr	find_kf
	jcc	to_show_study

	lm2	string_ptr,#book_fail2_msg
	lda	man_pai
	cmp	#NONE_PAI
	beq	study_2
	cmp	#XIAOYAO_PAI
	jne	to_show_study
study_2:
	lm	man_pai,#XIAOYAO_PAI
	ldy	#4
study_cmd1:	
	lda	(a1),y
	sta	npc_kfnum,y
	dey
	bpl	study_cmd1

	PullMenu	1
	jsr	scroll_to_lcd
	jsr	master1
	jsr	scroll_to_lcd
study_rts:	
	rts

to_show_study:
	CLS_NLINE2    #VDPS-14,#13
	ldx	#0
	sec
	lda	#VDPS-1
	sbc	char_height
	tay
	jsr	show_one_line
	extrn	wait_key
	jsr	wait_key
	rts
;----------------------------------------------------------------
; input:
; output:
;----------------------------------------------------------------
practice_cmd:	;练习
	lm2	a1,#dmenu_buf
	jsr	get_pra_kf
	lm2	kf_ptr,a1
	lm2	menu_ptr,#practice_menu
	lm2	a1,kf_ptr
	ldx	#LEARN_X0
	ldy	#LEARN_Y0
	jsr	pop_menu
	jsr	scroll_to_lcd
	rts

practice_it:
        ldy     menu_set
        iny
        lda     (kf_ptr),y
	and	#7fh
        sta     kf_id

        ldxy    #practice_tbl
	smb7	busy_flag
        jsr     show_process
	rmb7	busy_flag
        jsr     scroll_to_lcd
        rts

practice_tbl:
        db      32,1                    ;x0,y0
        dw      pra_set_line,pra_set_digit      ;ouput:binbuf bcdbuf
        dw      400                    ;单位:ms
        dw      pra_inc_continue            ;program
pra_set_line:
        lda     kf_id
        jsr     find_kf
        lda     man_kf+1,y
        tax
        jsr	mul_ax
        lm2     bcdbuf,a1
        lda     man_kf+2,y
        sta     binbuf
        lda     man_kf+3,y
        sta     binbuf+1
        rts
pra_set_digit:
        lda     kf_id
        jsr     find_kf
        lda     man_kf+1,y
        sta     bcdbuf
        lm      bcdbuf+1,#0
        lda     man_kf+2,y
        sta     binbuf
        lda     man_kf+3,y
        sta     binbuf+1
        rts
pra_inc_continue:
        jsr 	pyh_practice
        rts


;--------------------------------------
;input: a1
;output: a1
;--------------------------------------
get_pra_kf:
	ldy	#0
	ldx	#0
get_pra_l:
	lda	man_usekf,x
	bpl	get_pra_n
	iny
	sta	(a1),y
get_pra_n:
	inx
	cpx	#3
	bcc	get_pra_l

	tya
	ldy	#0
	sta	(a1),y
	rts
	
;----------------------------------------------------------------
; input:
; output:
;----------------------------------------------------------------
dazuo_cmd:	;练功
	ldxy	#dazuo_tbl
	smb7	busy_flag
	jsr	show_process
	rmb7	busy_flag
	jsr	scroll_to_lcd
	rts

dazuo_tbl:
	db	32,1			;x0,y0
	dw	set_line,set_digit	;ouput:binbuf bcdbuf
	dw	400			;单位:ms
	dw	inc_continue		;program

;---------------------
set_line:
	lm2	binbuf,man_fp
	lm2	bcdbuf,man_maxfp
	asl2	bcdbuf
	rts
set_digit:
	lm2	binbuf,man_fp
	lm2	bcdbuf,man_maxfp
	rts

;---------------------
inc_continue:
	jsr	dazuo
	rts

	if	0
dazuo_msg:	db	'你坐下来运气用功，一股内息开始在体内流动',0
	endif
;----------------------------------------------------------------
; input: kf_id a1(点数)
; output: cy (sec:level++ clc:pot=+a1)
;----------------------------------------------------------------
improve_skill:
	lda	kf_id
	jsr	find_kf
	clc
	lda	man_kf+2,y
	adc	a1
	sta	man_kf+2,y
	lda	man_kf+3,y
	adc	a1h
	sta	man_kf+3,y

	lda	man_kf+1,y
	sta	my_skill
	tax
	inx
	txa
	jsr	mul_ax
	lda	man_kf+2,y
	sta	a2
	lda	man_kf+3,y
	sta	a2h
	cmp2	a2,a1
	bcc	improve_rts

	;skill_pot >= (level+1)*(level+1)
	inc	my_skill
	lda	my_skill
	sta	man_kf+1,y
	lda	#0
	sta	man_kf+2,y
	sta	man_kf+3,y
	jsr	setup_attr
	sec
improve_rts:
	rts

;----------------------------------------------------------------
;	calculate user attribute
; man_str=attr_str+skill("unarmed")/10
; man_dex=attr_dex+skill("dodge")/10
; man_int=attr_int+skill("literate")/10
; man_con=attr_con+skill("force")/10
; man_per=attr_per+skill("looks")/10
;----------------------------------------------------------------
setup_attr:
	;后天属性
	lda	#BASIC_BARE_KF
	jsr	find_kf
	bcc	next_attr1
	lda	man_kf+1,y
	ldx	#10
	jsr	divid_ax
	clc
	adc	attr_str
	sta	man_str
next_attr1:
	lda	#BASIC_DODGE_KF
	jsr	find_kf
	bcc	next_attr2
	lda	man_kf+1,y
	ldx	#10
	jsr	divid_ax
	clc
	adc	attr_dex
	sta	man_dex
next_attr2:
	lda	#LITERATE_KF
	jsr	find_kf
	bcc	next_attr3
	lda	man_kf+1,y
	ldx	#10
	jsr	divid_ax
	clc
	adc	attr_int
	sta	man_int
next_attr3:
	lda	#BASIC_FORCE_KF
	jsr	find_kf
	bcc	next_attr4
	lda	man_kf+1,y
	ldx	#10
	jsr	divid_ax
	clc
	adc	attr_con
	sta	man_con
next_attr4:
	lda	#LOOKS_KF
	jsr	find_kf
	bcc	next_attr5
	lda	man_kf+1,y
	ldx	#10
	jsr	divid_ax
	clc
	adc	attr_per
	sta	man_per
next_attr5:
	rts

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

;---------------------------------------------------------------
; list show skills
;---------------------------------------------------------------
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
	jsr	pop_menu
	rts

show_kf:
	jsr	clear_right
	jsr	init_skills_menu
	jsr	show_menu_txt
	rts

deal_knowledge:
	PushMenu
	jsr	init_skills_menu1
	jsr	pop_menu
	rts

show_knowledge:
	jsr	clear_right
	jsr	init_skills_menu1
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
	ldx	kf_type
	lda	man_usekf,x
	bmi	$+4
	lda	#0ffh
	and	#7fh
	sta	kf_id
	lm2	a1,#dmenu_buf
	jsr	set_kf
	lm2	kf_ptr,a1

	lda	kf_type
	cmp	#PARRY_KF
	bne	not_parry
	jsr	if_parry
not_parry:
	lm2	menu_ptr,#right_menu
	clc
	lda	list_x0
	adc	#5
	tax
	ldy	list_y0
	rts

;---------------------------------------------------------------
; input: list_x0 list_y0 menu_item
; outpu: a1 menu_ptr Xreg Yreg
;---------------------------------------------------------------
init_skills_menu1:
	lm	kf_type,menu_set
	lda	#0ffh
	sta	kf_id
	lm2	a1,#dmenu_buf
	jsr	set_kf
	lm2	kf_ptr,a1

	lm2	menu_ptr,#right_menu1
	clc
	lda	list_x0
	adc	#5
	tax
	ldy	list_y0
	rts

;------------------------------------------------------
;	parry kf is special
; input: a1
; output: a1,menu_set
;------------------------------------------------------
if_parry:
	lm	menu_set,#0ffh
	ldy	#0
	lda	(a1),y
	tay

	lda	man_usekf
	bpl	parry_next
	cmp	man_usekf+4
	bne	$+4
	sty	menu_set
	and	#7fh
	iny
	sta	(a1),y
parry_next:
	lda	man_usekf+1
	bpl	parry_rts
	cmp	man_usekf+4
	bne	$+4
	sty	menu_set
	and	#7fh
	iny
	sta	(a1),y
parry_rts:

	tya
	ldy	#0
	sta	(a1),y
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
	stx	menu_set
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
	cmp	tmp1
	bne	$+4
	sty	menu_set
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
	jsr	skill_desc
	lm2	varbuf,a1

	lda	kf_id
	jsr	find_kf
	lda	man_kf+1,y
	sta	varbuf+2
	lda	man_kf+2,y
	sta	varbuf+3
	lda	man_kf+3,y
	sta	varbuf+4

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
	db	9
	dw	char_desc,10
	db	' ',3
	dw	varbuf+2,10
	db	'/',5
	dw	varbuf+3,0
	db	0
char_desc:
	db	8
	dw	varbuf

;---------------------------------------------------------------
; input: kf_id
; output: a1
;---------------------------------------------------------------
skill_desc:
	lda	kf_id
	jsr	find_kf
	lda	man_kf+1,y
	ldx	#5
	jsr	divid_ax

	cmp	#MAX_DESC
	bcc	$+4
	lda	#MAX_DESC-1
	sta	a1
	lm	a1h,#0
	rept	3
	asl	a1
	rol	a1h
	endr
	add	a1,#skill_level_desc
	rts

;---------------------------------------------------------------
; input: kf_id
; output:
;---------------------------------------------------------------
use_skills:
	lda	kf_id
	cmp	#BASIC_KF_NUM
	bcs	$+3
	rts
	jsr	find_kf
	bcs	enable_it
	SSTOP	4

;--------------------------------------
;input:kf_type kf_id
;output:
;--------------------------------------
enable_it:
	ldx	kf_type
	lda	man_usekf,x
	bpl	enable_con
	and	#7fh
	cmp	kf_id
	beq	disable_it
enable_con:
	lda	kf_id
	ora	#80h
	sta	man_usekf,x

	PullMenu
	rts

;input: Xreg
;-----------------
disable_it:
	lda	#0
	sta	man_usekf,x
	PullMenu
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

;----------------------------------------------------------------
; input: kf_id
; output: C (sec: fail clc: succ)
;----------------------------------------------------------------
add_kf:
	lda	kf_id
	jsr	find_kf
	bcs	inc_it
	cpx	#MAX_KF
	bcc	ins_it
	clc
	rts

ins_it:
	lda	kf_id
	sta	man_kf,y
	lda	#0
	sta	man_kf+1,y
	sta	man_kf+2,y
	sta	man_kf+3,y
	inc	man_kfnum

inc_it:
	sec
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

;-------------------------------------------
; get pointer of skill and damage desc
; input: obj_ptr, func_buf
; ouput: a1 a2
;-------------------------------------------
get_skill_desc:
	;**** skill *****
	;(attack + ((dodge+parry)/2) )/3
	ldx	#HAND_KF
	ldy	#WEAPON_OFF
	lda	(obj_ptr),y
	bpl	$+4
	ldx	#WEAPON_KF
	txa
	sta	kf_type
	jsr	func_buf+QUERY_FUNC
	lm2	a9,skill_level
	lda	#DODGE_KF
	sta	kf_type
	jsr	func_buf+QUERY_FUNC
	lm2	a8,skill_level
	lda	#PARRY_KF
	sta	kf_type
	jsr	func_buf+QUERY_FUNC
	add	a8,skill_level
	lsr2	a8
	add	a9,a8,a1
	lm2	a2,#3
	jsr	divid2
	lm2	a2,#5
	jsr	divid2
	asl2	a1
	asl2	a1
	asl2	a1
	add	a1,#skill_level_desc
	push2	a1

	;**** damage *****
	ldy	#STR_OFF
	lda	(obj_ptr),y
	sta	damage_point
	lm	damage_point+1,#0
	ldy	#DAMAGE_OFF
	lda	(obj_ptr),y
	adda2	damage_point
	ldy	#FORCE_OFF
	lda	(obj_ptr),y
	lsr	a
	adda2	damage_point
	lm2	a1,damage_point
	lm2	a2,#20
	jsr	divid2

	lda	a1
	cmp	#5
	bcc	$+4
	lda	#5
	masl	a,2
	sta	a1
	add	a1,#strong_lev_desc

	lm2	a2,a1
	pull2	a1
	rts

;-------------------------------------
left_menu:
	db	01000000b
	db	6
	db	01010001b
	db	NORMAL_MENU
	dw	deal_kf,show_kf
	dw	deal_kf,show_kf
	dw	deal_kf,show_kf
	dw	deal_kf,show_kf
	dw	deal_kf,show_kf
	dw	deal_knowledge,show_knowledge
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
	db	CHECK_MENU
	dw	use_skills,show_desc
	dw	kf_name_tbl
right_menu1:
	db	11011010b
	db	80h
	db	01010001b
	db	BOX_MENU
	dw	0,show_desc
	dw	kf_name_tbl

practice_menu:
	db	10011010b
	db	80h
	db	10110001b
	db	RADIO_MENU
	dw	practice_it
	dw	kf_name_tbl

perform_menu:
	db	10011010b
	db	80h
	db	10110001b
	db	ARROW_MENU
	dw	select_it
	dw	pf_name_tbl
;-------------------------------------

	if	scode
book_fail1_msg	db	'你还是个文盲',0
book_fail2_msg	db	'还是先练好本门武功吧',0
book_bao_msg	db	'真的要修练吗(Y/N)?',0
book_bao_msg2	db	'不后悔吗(Y/N)?',0
	else
book_fail1_msg	db	'临琌ゅ',0
book_fail2_msg	db	'临琌絤セ猌',0
book_bao_msg	db	'痷璶絤盾(Y/N)?',0
book_bao_msg2	db	'ぃ盾(Y/N)?',0
	endif

;-------------------------------------
	if	scode
skill_level_desc:
	db	'不堪一击'
	db	'毫不足虑'
	db	'不足挂齿'
	db	'初学乍练'
	db	'勉勉强强'
	db	'初窥门径'
	db	'初出茅庐'
	db	'略知一二'
	db	'普普通通'
	db	'平平常常'
	db	'平淡无奇'
	db	'粗通皮毛'
	db	'半生不熟'
	db	'登堂入室'
	db	'略有小成'
	db	'已有小成'
	db	'鹤立鸡群'
	db	'驾轻就熟'
	db	'青出於蓝'
	db	'融会贯通'
	db	'心领神会'
	db	'炉火纯青'
	db	'了然於胸'
	db	'略有大成'
	db	'已有大成'
	db	'豁然贯通'
	db	'非比寻常'
	db	'出类拔萃'
	db	'罕有敌手'
	db	'技冠群雄'
	db	'神乎其技'
	db	'出神入化'
	db	'傲视群雄'
	db	'登峰造极'
	db	'无与伦比'
	db	'所向披靡'
	db	'一代宗师'
	db	'精深奥妙'
	db	'神功盖世'
	db	'举世无双'
	db	'惊世骇俗'
	db	'撼天动地'
	db	'震古铄今'
	db	'超凡入圣'
	db	'威镇寰宇'
	db	'空前绝后'
	db	'天人合一'
	db	'深藏不露'
	db	'深不可测'
	db	'返璞归真'
strong_lev_desc:
	db	'极轻'
	db	'很轻'
	db	'不轻'
	db	'不重'
	db	'很重'
	db	'极重'
	else
skill_level_desc:
	db	'ぃ臭阑'
	db	'睝ぃì納'
	db	'ぃì珽睛'
	db	'厩絤'
	db	'玧玧眏眏'
	db	'縮畖'
	db	'璗胒'
	db	'菠'
	db	'炊炊硄硄'
	db	'キキ盽盽'
	db	'キ睭礚'
	db	'彩硄ブを'
	db	'ネぃ剪'
	db	'祅绑'
	db	'菠ΤΘ'
	db	'ΤΘ'
	db	'舃ミ蔓竤'
	db	'緍淮碞剪'
	db	'獵屡'
	db	'磕穦砮硄'
	db	'み烩穦'
	db	'膌獵'
	db	'礛'
	db	'菠ΤΘ'
	db	'ΤΘ'
	db	'僚礛砮硄'
	db	'獶ゑ碝盽'
	db	'摸┺笛'
	db	'╱Τ寄も'
	db	'м玜竤动'
	db	'ㄤм'
	db	'て'
	db	'镀跌竤动'
	db	'祅畃硑伐'
	db	'礚籔ゑ'
	db	'┮┸名'
	db	'﹙畍'
	db	'弘瞏而М'
	db	'籠'
	db	'羭礚蛮'
	db	'佩纀玌'
	db	'举ぱ笆'
	db	'綺培さ'
	db	'禬竧'
	db	'马救'
	db	'玡荡'
	db	'ぱ'
	db	'瞏旅ぃ臩'
	db	'瞏ぃ代'
	db	'縗耴痷'
strong_lev_desc:
	db	'伐淮'
	db	'淮'
	db	'ぃ淮'
	db	'ぃ'
	db	''
	db	'伐'
	endif

;----------------------------------------------------------------
	end
