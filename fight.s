;;******************************************************************
;;	fight.s - mud fight(npc vs man)
;;
;;	written by lian
;;	begin on 2001/04/02
;;	finish on
;;
;;     ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
;;     ┃	在人的所有造物中,语言或许是最奇妙的东西	       ┃
;;     ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
;;
;;*******************************************************************
	include	h/gmud.h
	include	h/id.h
	include	h/mud_funcs.h
	include	h/func.mac

	public	fight
	public	attack_npc
	public	attack_man
	public	skill_power
	public	skill_npc_power
	public	show_fight_msg
	public	final_fight

	extrn	show_goods
	extrn	show_string
	extrn	show_perform

	extrn	scroll_to_lcd
	extrn	lcd_to_scroll

	extrn	message_box
	extrn	format_string
	extrn	pop_menu
	extrn	random_kf_action
	extrn	query_skill
	extrn	query_npc_skill
	extrn	check_skill
	extrn	get_weapon_kf
	extrn	get_img_data
	extrn	CommunicateExit

	extrn	mul2
	extrn	mul4
	extrn	divid42
	extrn	divid2
	extrn	random_it
	extrn	perform_random_it
	extrn	percent
	extrn	clear_nline
	extrn	write_block0
	extrn	show_line
	extrn	show_digit
	extrn	get_py_action
	extrn	get_result_msg
	extrn	init_ptemp
	extrn	call_out
	extrn	recover
	extrn	perform
	extrn	block_draw
	extrn	square_draw
	extrn	getms
	extrn	wait_cr_key
	extrn	find_kf
	extrn	find_npc_kf
	extrn	get_player_img

MAN_X0		equ	10
MAN_Y0		equ	0
NPC_X0		equ	107
NPC_Y0		equ	0
MAN_HP_X0	equ	16
MAN_HP_Y0	equ	35
MAN_FP_X0	equ	MAN_HP_X0
MAN_FP_Y0	equ	MAN_HP_Y0+9
NPC_HP_X0	equ	90+20
NPC_HP_Y0	equ	35
NPC_FP_X0	equ	NPC_HP_X0
NPC_FP_Y0	equ	NPC_HP_Y0+9

MAIN_MENU_X0	equ	40	;40
MAIN_MENU_Y0	equ	50
NEILI_X0	equ	50
NEILI_Y0	equ	50
;--------------------------------------------------------------------
final_fight:
	lda	endx
	asl	a
	tax
	lda	boss_tbl,x
	sta	string_ptr
	lda	boss_tbl+1,x
	sta	string_ptr+1
	jsr	show_talk_msg
	lda	endx
	cmp	#2
	beq	final_3
	jsr	wait_cr_key
	jmp	to_fight
final_3:	
	jsr	wait_key
	cmp	#'b'
	beq	final_4
	cmp	#'n'
	bne	final_3
to_fight:
	smb7	busy_flag
	jsr	fight
	rmb7	busy_flag
	lda	exit_code
	rts
final_4:
	lm	exit_code,#2
	rts
	
;--------------------------------------------------------------------
; input: located_id
; output:
;--------------------------------------------------------------------
fight:
	PushMenu	1
	jsr	init_fight
	BREAK_FUN	_Bclrscreen
	UPline	#11,#13,vs
	jsr	lcd_to_scroll

	;第一回合谁先发招由RANDOM决定
	if	lee_test
	jmp	show_fight
	endif
	jsr	getms
	and	#1h
	beq	show_fight

	jsr	refresh_fight
	jsr	attack_man
show_fight:
	PullMenu	1
	jsr	refresh_fight

	ldx	#MAIN_MENU_X0
	ldy	#MAIN_MENU_Y0
	lm2	menu_ptr,#fight_menu
	jsr	pop_menu
	jmp	show_fight

	if	scode
vs:	db	'ＶＳ',0
	else
vs:	db	'⑨',0
	endif

;------------------------------------------
init_fight:
	lm	escape_factor,#20
	lm	man_busy,#0
	lm	npc_busy,#0
	jsr	init_ptemp
	rts

;------------------------------------------
normal_attack:		;普通攻击
	jsr	call_out
	lm	net_repeat,#2
	jsr	attack_npc

	bit	net_flag
	bmi	net_normal

	jsr	refresh_fight
	jsr	attack_man
	jmp	show_fight
net_normal:
	lda	#ESC_KEY
	ora	#80h
	sta	key
	rts
;------------------------------------------
attack_action:		;绝招攻击
	smb7	obj_flag
	jsr	show_perform
	cmp	#0ffh
	bne	to_perform
	jsr	scroll_to_lcd
	rts

to_perform:
	jsr	perform_attack

	bit	net_flag
	bmi	net_perform

	bcs	show_fight
	jsr	who_win
	
	jsr	refresh_fight
	jsr	attack_man
	jsr	call_out
	jmp	show_fight
net_perform:
	bcs	net_perform_rts			;perform fail
	smb7	net_perform_flag		;perform is over
	jsr	net_send_data			;perform sucess
	jsr	who_win
	lda	#ESC_KEY
	ora	#80h
	sta	key
	rts
net_perform_rts:
	rmb7	net_msg_vision
	jsr	refresh_fight
	rts
	
;------------------------------------------
goods_action:		;使用物品
	jsr	show_goods
	jsr	refresh_fight
	rts

;------------------------------------------
escape_action:		;逃跑
	if	lee_test
	lda	cheat_mode
	beq	esc_x
	lm2	npc_hp,#0
	rts
esc_x:	
	endif
	bit	net_flag
	bpl	escape_action_1
	smb7	net_quit_flag
	jsr	net_send_data
escape_action_1:
	cmp1	npc_pai,#BOSS_PAI
	bne	$+3
	rts
	smb7	obj_flag
	jsr	if_escape
	jcs	fail_quit

	jsr	show_fight_msg
	jsr	attack_man
	jsr	who_win
	jmp	show_fight

;------------------------------------------
to_xiqi:
	smb7	obj_flag
	lm2	obj_ptr,#man_state
	jsr	recover
refresh_fight:
	jsr	write_fight
	jsr	scroll_to_lcd
	rts

;------------------------------------------------------------------
; input: Areg (perform_id)
; output: 
;------------------------------------------------------------------
perform_attack:
	sta	perform_id
        bit     obj_flag
        bpl     npc_perform
        lm2     obj_ptr,#man_state
        lm2     you_ptr,#npc_state
        jmp     perform_1
npc_perform:
        lm2     obj_ptr,#npc_state
        lm2     you_ptr,#man_state
perform_1:
        jsr	perform
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;***** action ******;;;;;;;;;;;;;;;;;;;;;;;;;;;
fight_menu:
	db	00000000b	;格式
	db	5		;菜单总数
	db	00010000b	;格式
	db	ICON_MENU	;菜单方式
	dw	normal_attack	;程序地址
	dw	attack_action	;程序地址
	dw	to_xiqi
	dw	goods_action
	dw	escape_action
	if	scode
	db	'攻击',0ffh
	db	'绝招',0ffh
	db	'吸气',0ffh
	db	'物品',0ffh
	db	'逃跑',0ffh
	else
	db	'ю阑',0ffh
	db	'荡┷',0ffh
	db	'',0ffh
	db	'珇',0ffh
	db	'発禲',0ffh
	endif

;------------------------------------------------
;	who win? man : npc
; input: man_id located_id
; output: C Z
;	Z=0 noone win Z=1 someone win
;	C=0 man win C=1 npc win
;------------------------------------------------
who_win:
	lda	man_hp
	ora	man_hp+1
	beq	npc_win
	lda	npc_hp
	ora	npc_hp+1
	beq	man_win
	rts

npc_win:
	bit	net_flag
	bmi	no_kill
	lda	npc_daode
	bmi	kill_you
	beq	kill_you
	lda	man_daode
	bpl	kill_you
no_kill:
	lm2	string_ptr,#npc_msg
	jsr	show_talk_msg
	lda	#2
	bne	quit
kill_you:	
	lm2	string_ptr,#npc_msg2
	jsr	show_talk_msg
	lda	#0
	beq	quit
man_win:
	bit	net_flag
	bpl	man_win1
	lm2	string_ptr,#man_msg7
	jsr	show_talk_msg
	lda	#2
	bne	quit
man_win1:	
	cmp1	npc_pai,#BOSS_PAI
	bne	man_win2
	lm	exit_code,#3
	jmp	quit1
man_win2:	
	lm2	string_ptr,#man_msg
	jsr	show_talk_msg
key_loop:	
	jsr	wait_key
	cmp	#'y'
	beq	kill_npc
	cmp	#'n'
	beq	no_kill_npc
	jmp	key_loop
fail_quit:
	lda	#2
	sta	exit_code
	bit	net_flag
	bmi	quit1
	lm2	string_ptr,#npc_msg3
	jsr	show_talk_msg
	lda	#2
quit:
	sta	exit_code
	jsr	wait_cr_key
quit1:	
	jsr	CommunicateExit
	PullMenu	1
	lda	exit_code
	rts
no_kill_npc:
	lm2	string_ptr,#man_msg7
	jsr	show_talk_msg
	lda	#1
	bne	quit
kill_npc:
	jsr	killer
	lm2	range,#5
	jsr	random_it
	cmp	#2
	bcs	kill_npc2
	lda	npc_gender
kill_npc2:	
	asl	a
	tax
	lm20x	string_ptr,dead_talk
	jsr	show_talk_msg
	lda	npc_daode
	beq	daode_end
	bmi	kill_bad
	lda	man_daode
	sec
	sbc	npc_daode
	bcs	$+4
	lda	#0
	ldx	man_daode
	bpl	daode_1
	sec
	sbc	npc_daode
	bcs	daode_1
	lda	#0
daode_1:	
	sta	man_daode
daode_end:	
	lda	#3
	jmp	quit
kill_bad:
	lda	man_daode
	bpl	daode_end
	sec
	lda	#0
	sbc	npc_daode
	clc
	adc	man_daode
	bcc	$+4
	lda	#255
	jmp	daode_1

killer:	
	cmp1	located_id,#KILLER_NPC
	bne	killer1
	inc	guan_kill
	bne	killer_rts
	dec	guan_kill
killer_rts:	
	rts
killer1:
	inc	npc_kill
	rts
	
	if	scode
npc_msg:
	db	'承让了.',0,0
npc_msg2:
	db	7
	dw	man_name,10
	db	',去死吧!',0,0
npc_msg3:
	db	'哼,哪里逃!',0,0
man_msg:
	db	7
	dw	man_name,10
	db	'这一刀是劈还是不劈呢(Y/N)?',0,0
dead_talk:
	dw	man_msg2
	dw	man_msg3
	dw	man_msg4
	dw	man_msg5
	dw	man_msg6
man_msg2:
	db	'二十年后又是一条好汉!',0,0
man_msg3:
	db	'啊-----!',0,0
man_msg4:
	db	'可恶!我怎么会死呢.',0,0
man_msg5:
	db	'我会在地狱里等着你的.',0,0
man_msg6:
	db	'有的人活着,他已经死了,有...哎,我还没说完...',0,0
man_msg7:
	db	'..............',0,0
boss_tbl:	
	dw	boss_msg
	dw	boss_msg2
	dw	boss_msg3
boss_msg:
	db	7
	dw	npc_name,10
	db	':在每个故事的结尾,通常都会有一个最终BOSS.',0
	db	'遇上我,是你的不幸,要怪就怪那个幕后的导演吧!',0,0
boss_msg2:
	db	7
	dw	npc_name,10
	db	':哈哈----------!没想到吧.',0
	db	7
	dw	man_name,10
	db	':难道神秘人是...',0
	db	7
	dw	npc_name,10
	db	':不错.',0
	db	'十年前,自诩为名门正派的六大门派合力'
	db	'偷袭,把我关在这里...',0
	db	7
	dw	man_name,10
	db	':我会把你再次封印.',0
	db	7
	dw	npc_name,10
	db	':做梦吧.以你的实力,十万年还早!',0,0
boss_msg3:
	db	7
	dw	npc_name,10
	db	':苦海无边,回头是岸.',0
	db	7
	dw	man_name,10
	db	':不可能!',0,'难道你没有死?',0
	db	7
	dw	npc_name,10
	db	':施主罪孽深重,老纳是不会让你回到原来的世界'
	db	'再次危害天下的.施主,请回吧.',0
	db	'(选择 1.回去 2.少废话,这次你会死的很难看的)',0,0

	else
npc_msg:
	db	'┯琵.',0,0
npc_msg2:
	db	7
	dw	man_name,10
	db	',!',0,0
npc_msg3:
	db	',柑発!',0,0
man_msg:
	db	7
	dw	man_name,10
	db	'硂琌糀临琌ぃ糀㎡(Y/N)?',0,0
dead_talk:
	dw	man_msg2
	dw	man_msg3
	dw	man_msg4
	dw	man_msg5
	dw	man_msg6
man_msg2:
	db	'琌兵簙!',0,0
man_msg3:
	db	'摆-----!',0,0
man_msg4:
	db	'碿!и或穦㎡.',0,0
man_msg5:
	db	'и穦夯ń单帝.',0,0
man_msg6:
	db	'Τ帝,竒,Τ...玼,и临⊿弧Ч...',0,0
man_msg7:
	db	'..............',0,0
boss_tbl:	
	dw	boss_msg
	dw	boss_msg2
	dw	boss_msg3
boss_msg:
	db	7
	dw	npc_name,10
	db	':–珿ㄆ挡Ю,硄盽常穦Τ程沧BOSS.',0
	db	'笿и,琌ぃ┋,璶┣碞┣ê辊旧簍!',0,0
boss_msg2:
	db	7
	dw	npc_name,10
	db	':----------!⊿稱.',0
	db	7
	dw	man_name,10
	db	':螟笵琌...',0
	db	7
	dw	npc_name,10
	db	':ぃ岿.'
	db	'玡,郒タせ'
	db	'敖脓,ри闽硂柑...',0
	db	7
	dw	man_name,10
	db	':и穦рΩ.',0
	db	7
	dw	npc_name,10
	db	':暗冠.龟,窾临Ν!',0,0
boss_msg3:
	db	7
	dw	npc_name,10
	db	':璚礚娩,繷琌─.',0
	db	7
	dw	man_name,10
	db	':ぃ!',0,'螟笵⊿Τ?',0
	db	7
	dw	npc_name,10
	db	':琁竜腲瞏,ρ琌ぃ穦琵ㄓ'
	db	'Ω甡ぱ.琁,叫.',0
	db	'(匡拒 1. 2.ぶ紀杠,硂Ω穦螟)',0,0
	endif
;------------------------------------------------
;	show message at top 2 lines
; input: string_ptr
;------------------------------------------------
show_talk_msg:
	jsr	format_string
	lm	lcmd,#0
	block	#1,#0,#159,#26
	lm	lcmd,#1
	jsr	square_draw

	ldx	#1
	ldy	#2
	lda	#2
	jsr	show_string
	bcc	show_talk_rts

	WAIT_TALK_KEY
	jmp	show_talk_msg

show_talk_rts:
	rts
;------------------------------------------------
;	escape success or fail
; input:
; outpu: cy (sec:success clc:fail)
;	string_ptr: fail msg
;------------------------------------------------
if_escape:
	lm2	string_ptr,#not_move_msg1
	lda	man_busy
	bne	escape_fail

	if	1
	lm2	string_ptr,#not_move_msg2
	clc
	lda	man_dex
	adc	escape_factor
	sta	range
	lm	range+1,#0
	jsr	random_it
	cmp	npc_dex
	ble	escape_fail
	endif

	sec
	rts
escape_fail:
	add1	escape_factor,#10
	clc
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;***** action ******;;;;;;;;;;;;;;;;;;;;;;;;;;;

;------------------------------------------------
;	man attack npc
; input: none
; output: npc_hp
;------------------------------------------------
attack_npc:
	smb7	obj_flag
	lda	man_busy
	jne	not_attack_busy

	lm2	range,#16
	jsr	random_it
	sta	limb_flag

	;{{********** attack ***********
	
	jsr	get_kf_action		;o:string_ptr
	jsr	show_fight_msg
	lm	man_kf_dp,kf_dp
	lm	man_kf_pp,kf_pp

	lda	#HAND_KF
	bit	man_weapon
	bpl	$+4
	lda	#WEAPON_KF
	sta	kf_type
	lda	#0
	ldx	kf_ap
	jsr	skill_power
	lda	man_dex
	jsr	point_adjust	

	lm2	attack_point,a1		;AP
	lm2	attack_point+2,a2
	;}}********** attack ***********

	;{{********** dodge ***********
	jsr	get_dg_action2		;o:string

	lm	kf_type,#DODGE_KF
	lda	#1
	ldx	npc_kf_dp
	jsr	skill_npc_power		;output: a1,a2
	lm	npc_kf_dp,#0
	lda	npc_int
	jsr	point_adjust

	lda	npc_busy
	beq	npc_b0
	lm2	a3,#3
	jsr	divid42
npc_b0:
	lm2	dodge_point,a1		;DP
	lm2	dodge_point+2,a2	
	;}}********** dodge ***********
	jsr	cal_random_ApDp
	cmp4	a3,dodge_point
	jcc	not_attack_npc

	;{{********** parry ***********
	lda	npc_weapon
	jsr	get_py_action		;o:string

	lm	kf_type,#PARRY_KF
	lda	#1
	ldx	npc_kf_pp
	jsr	skill_npc_power
	lm	npc_kf_pp,#0
	lda	npc_str
	jsr	point_adjust

	lda	npc_busy
	beq	npc_b1
	lm2	a3,#3
	jsr	divid42
npc_b1:
	lm2	parry_point,a1		;PP
	lm2	parry_point+2,a2
	;}}********** parry ***********
	jsr	cal_random_ApPp
	cmp4	a3,parry_point
	jcc	not_attack_npc

	jsr	npc_fenshen		;判断npc是否使用了分身
	jcc	attack_npc_rts

	ldx	#NPC_X0+8
	ldy	#NPC_Y0+4
	jsr	show_effect

	;{{********** damage ***********
	lm2	obj_ptr,#man_state
	lm2	you_ptr,#npc_state
	jsr	cal_damage		;output:damage_point, a9

	sub	npc_hp,damage_point	;Damage
	bcs	npc_is_live
	lm2	npc_hp,#0
npc_is_live:
	sub	npc_effhp,a9
	bcs	npc_is_live2
	lm2	npc_effhp,#0
npc_is_live2:

	lm2	a1,npc_hp
	lda	a9
	ora	a9h
	beq	npc_is_live3
	lm2	a1,npc_effhp
npc_is_live3:
	lm2	a2,npc_maxhp		
	jsr	percent
	ldy	damage_type
	lm2	a8,damage_point,x
	jsr	get_result_msg	;o:string_ptr
	;}}********** damage ***********
	lda	#XI_KF
	jsr	find_kf
	bcc	not_attack_npc
	lda	man_kf+1,y
	sta	a1
	lm	a1h,#0
	lm2	a2,damage_point
	jsr	mul2
	lm2	a3,#100
	jsr	divid42
	add	man_hp,a1
	cmp2	man_hp,man_effhp
	bcc	not_attack_npc
	lm2	man_hp,man_effhp
not_attack_npc:
	jsr	show_fight_msg
	jsr	who_win
attack_npc_rts:
	rts

;------------------------------------------------
;	npc attack man
; input: none
; output: man_hp
;------------------------------------------------
attack_man:
	rmb7	obj_flag

        lda     npc_busy
        jne     not_attack_busy

	lm2	range,#16
	jsr	random_it
	sta	limb_flag

	;{{********** attack ***********
	jsr	get_kf_action2		;o:string_ptr
	jsr	show_fight_msg
	lm	npc_kf_dp,kf_dp		;for attack_npc use
	lm	npc_kf_pp,kf_pp

	lda	#HAND_KF
	bit	npc_weapon
	bpl	$+4
	lda	#WEAPON_KF
	sta	kf_type
	lda	#0
	ldx	kf_ap
	jsr	skill_npc_power
	lda	npc_dex
	jsr	point_adjust
	
	lm2	attack_point,a1		;AP
	lm2	attack_point+2,a2		
	;}}********** attack ***********

	;{{********** dodge ***********
	jsr	get_dg_action		;o:string_ptr

	lm	kf_type,#DODGE_KF
	lda	#1
	ldx	man_kf_dp
	jsr	skill_power
	lm	man_kf_dp,#0
	lda	man_con
	jsr	point_adjust

	lda	man_busy
	beq	man_b0
	lm2	a3,#3
	jsr	divid42
man_b0:
	lm2	dodge_point,a1		;DP
	lm2	dodge_point+2,a2
	;}}********** dodge ***********
	jsr	cal_random_ApDp
	cmp4	a3,dodge_point
	jcc	not_attack_man

	;{{********** parry ***********
	lda	man_weapon
	jsr	get_py_action		;o:string

	lm	kf_type,#PARRY_KF
	lda	#1
	ldx	man_kf_pp
	jsr	skill_power
	lm	man_kf_pp,#0
	lda	man_str
	jsr	point_adjust

	lda	man_busy
	beq	man_b1
	lm2	a3,#3
	jsr	divid42
man_b1:
	lm2	parry_point,a1		;PP
	lm2	parry_point+2,a2
	;}}********** parry ***********
	jsr	cal_random_ApPp		;output:a3,a4
	cmp4	a3,parry_point
	jcc	not_attack_man

	jsr	man_fenshen
	jcc	attack_man_rts

	ldx	#MAN_X0+8
	ldy	#MAN_Y0+4
	jsr	show_effect

	;{{********** damage ***********
	lm2	obj_ptr,#npc_state
	lm2	you_ptr,#man_state
	jsr	cal_damage

	sub	man_hp,damage_point	;Damage
	bcs	man_is_live
	lm2	man_hp,#0
man_is_live:
	sub	man_effhp,a9
	bcs	man_is_live2
	lm2	man_effhp,#0
man_is_live2:

	lm2	a1,man_hp
	lda	a9
	ora	a9h
	beq	man_is_live3
	lm2	a1,man_effhp
man_is_live3:
	lm2	a2,man_maxhp
	jsr	percent
	ldy	damage_type
	lm2	a8,damage_point,x
	jsr	get_result_msg	;o:string_ptr
	;}}********** damage ***********
	lda	#XI_KF
	jsr	find_npc_kf
	bcc	not_attack_man
	lda	npc_kf+1,y
	sta	a1
	lm	a1h,#0
	lm2	a2,damage_point
	jsr	mul2
	lm2	a3,#100
	jsr	divid42
	add	npc_hp,a1
	cmp2	npc_hp,npc_effhp
	bcc	not_attack_man
	lm2	npc_hp,npc_effhp

not_attack_man:
	jsr	show_fight_msg
	jsr	who_win
attack_man_rts:
	rts

;-----------------------------------------------------
; input: obj_flag
; output: (busy_flag)
;-----------------------------------------------------
not_attack_busy:

	bit	obj_flag
	bmi	man_attack_busy
	sec
	lda	npc_busy
	sbc	#1
	bcs	$+4
	lda	#0
	sta	npc_busy
	jmp	attack_busy_rts
man_attack_busy:
	sec
	lda	man_busy
	sbc	#1
	bcs	$+4
	lda	#0
	sta	man_busy
attack_busy_rts:
	lm	net_repeat,#1
	lm2	string_ptr,#not_move_msg0
	jsr	show_fight_msg
	rts

;-----------------------------------------------------
; input: none
; output: string_ptr damage_type damage_point
;-----------------------------------------------------
;是否有招式应该返回一个标志,可以用damage_point
;出口:kf_attack(有招式), weapon_nokf(无招式), bare_nokf(无招式)
get_kf_action:		;for man
	lda	man_weapon
	bmi	weapon_attack

	lda	man_usekf
	bpl	bare_nokf
	jmp	kf_attack
weapon_attack:
	bit	man_usekf+1
	bpl	weapon_nokf
	lda	man_usekf+1
	and	#7fh
	jsr	check_skill
	lda	man_weapon
	bcc	weapon_nokf
	lda	man_usekf+1
	jmp	kf_attack

;------------------------------------------------
get_kf_action2:		;for npc
	lda	npc_weapon
	bmi	weapon_attack2

	lda	npc_usekf
	bpl	bare_nokf
	jmp	kf_attack
weapon_attack2:		;!!DONT check skill
	bit	npc_usekf+1
	bpl	weapon_nokf
	lda	npc_usekf+1
	jmp	kf_attack

;--------------------------------
;i: Areg weapon
weapon_nokf:
	;weapon & nokf
	jsr	get_weapon_kf
	jmp	kf_attack

;--------------------------------
bare_nokf:
	lda	#BASIC_BARE_KF

;-------------------------------
;i: Areg (kf_id)
kf_attack:
	and	#7fh
	sta	kf_id
	jsr	random_kf_action
	lm2	damage_point,kf_damage
	rts

;-----------------------------------------------------
; input: none
; output: string_ptr
;-----------------------------------------------------
get_dg_action:
	lda	man_usekf+2
	bpl	bare_dodge
	bmi	kf_dodge
get_dg_action2:
	lda	npc_usekf+2
	bpl	bare_dodge
	bmi	kf_dodge

;-------------------------------
bare_dodge:
	lda	#BASIC_DODGE_KF
;-------------------------------
;i: Areg (kf_id)
kf_dodge:
	and	#7fh
	sta	kf_id
	jsr	random_kf_action
	rts

;------------------------------------------------------------------------
;	calculate the combined skill/combate_exp power of a skill
; input: kf_type Areg(0:attack 1:defense) Xreg(micor ajudst value)
; output: a1 a2 (4bytes)
;------------------------------------------------------------------------
;第一次调用好象有问题,以后就没问题了,估计是kf_ap的值没清

skill_power:			;man
	pha
	txa
	pha
	lm2	obj_ptr,#man_state
	jsr	query_skill	;output: skill_level
	pla
	tax	
	jmp	kf_power

skill_npc_power:			;npc
	pha
	txa
	pha
	lm2	obj_ptr,#npc_state
	jsr	query_npc_skill	;output: skill_level
	pla
	tax

;----------------
;input: x(micro adjust value)
;-----------------
kf_power:
	ldy	#ATTACK_OFF
	pla
	beq	$+4
	ldy	#DEFENSE_OFF
	lda	(obj_ptr),y
	adda2	skill_level	;apply_skill

	txa
	jsr	adjust_value
	bcc	is_plus
	sta	a1
	lm	a1h,#0
	sub	skill_level,a1
	bcs	is_negative
	lm2	skill_level,#0
	jmp	is_negative
is_plus:
	adda2	skill_level
is_negative:
	lda	skill_level
	ora	skill_level+1
	jeq	power0_rts

	;(skill_level)^3/300 + exp/100
	lm2	a1,skill_level		;180
	lm2	a2,skill_level
	jsr	mul2			;a1,a2
	lm2	a3,skill_level
	lm2	a4,#0
	jsr	mul4			;目前kf<=255,所以有效的是a1,a2
	lm2	a3,#300			;所以可以用a3而不会破坏值
	jsr	divid42

	push2	a1
	push2	a2

	ldy	#EXP_OFF
	lda	(obj_ptr),y
	sta	a1
	iny
	lda	(obj_ptr),y
	sta	a1h
	iny
	lda	(obj_ptr),y
	sta	a2
	iny
	lda	(obj_ptr),y
	sta	a2h
	lm2	a3,#100
	jsr	divid42

	;武学经验在65535*100之内,不会出错,
	
	pull2	a3
	pull2	a2
	add	a1,a2
	bcc	kf_power_rts
	inc	a3
kf_power_rts:
	lm2	a2,a3
	rts

power0_rts:
	ldy	#EXP_OFF
	lda	(obj_ptr),y
	sta	a1
	iny
	lda	(obj_ptr),y
	sta	a1h
	iny
	lda	(obj_ptr),y
	sta	a2
	iny
	lda	(obj_ptr),y
	sta	a2h
	lm2	a3,#200
	jsr	divid42
	rts

;--------------------------------------------------------------------
; input: obj_ptr you_ptr damage_point kf_force kf_damage
; output: damage_point(2bytes) a9(zero:no wounded ,non zero:wounded)
; destroy: a1--a9
;--------------------------------------------------------------------
;因为要以kf_damage和kf_force来判断有无招式,所以在cal_damage结束后
;要将这两个变量清0,以防止下次形成干扰

cal_damage:
	;modify by pyh	 	2001/8/15

	ldy	#STR_OFF
	lda	(obj_ptr),y
	sta	a8			
	lm	a8h,#0			;a8 : damage_bonus : me->str

	ldy	#DAMAGE_OFF
	lda	(obj_ptr),y
	sta	a9			
	lm	a9h,#0			;a9: damage : me->attack

	jsr	cal_basic_damage

	;到此处damage计算完毕,开始计算damage_bonus

	ldy	#FORCE_OFF
	lda	(obj_ptr),y
	sta	a6
	iny
	lda	(obj_ptr),y
	sta	a6h			;a6 : me->factor

	ldy	#FP_OFF
	lda	(obj_ptr),y
	sta	a7
	iny
	lda	(obj_ptr),y
	sta	a7h			;a7 : me->fp

	cmp2	a6,a7			;是否有内力
	bcc 	cal_damage_1		;内力不够
	lm2	a6,a7
cal_damage_1:
	
	sub	a7,a6,a1
	ldy	#FP_OFF	
	lda	a1
	sta	(obj_ptr),y
	iny
	lda	a1h
	sta	(obj_ptr),y

	jsr	cal_damage_bonus	;output:a8

	;
	;	damage_bonus += NPC 附加的特殊伤害
	;

	lm2	range,a8
	jsr	random_it
	add	a8,a1
	lsr2	a8
	add	a8,a9,damage_point

	lm2	kf_damage,#0
	lm2	kf_force,#0

	;judge if wounded 	modify by pyh	2001/8/28
	lm2	a9,#0			;first assumed no wounded
	ldy	#ARMOR_OFF
	lda	(you_ptr),y
	sta	a8			;victim->armor
	lm2	range,damage_point
	jsr	random_it
	cmp	a8
	bgt	judge_if_wounded
cal_damage_rts:
	rts
judge_if_wounded:
	;now random(damage) > npc_armor
	ldy	#WEAPON_OFF
	lda	(obj_ptr),y
	bmi	sure_wounded
	lm2	range,#4
	jsr	random_it
	bne	cal_damage_rts
sure_wounded:
	sub	damage_point,a8,a9
	rts

;---------------------
;output: a9(damage)
;---------------------
cal_basic_damage:

	;damage = ( damage + random(damage) )/2
	lm2	range,a9
	jsr	random_it
	add	a9,a1
	lsr2	a9

        ;kf有damage就计算,没有就不计算
        lda     kf_damage
        ora     kf_damage+1
        beq     basic_damage_rts

        lm2     a1,kf_damage
        lm2     a2,a9
        jsr	mul2
        lm2     a2,#100
	jsr	divid2
        add     a9,a1
basic_damage_rts:
	rts
;-------------

;------------------
;input:you_ptr,a7(me->fp),a6(me->factor)
;output:a8(damage_bonus)
;------------------
cal_damage_bonus:
	lda	a6
	ora	a6h
	beq	factor_zero		;pyh	9-24

	;有武器则加力除以6		;pyh	9-27
	ldy	#WEAPON_OFF
	lda	(obj_ptr),y
	bpl	no_weapon
	lm2	a1,a6
	lm2	a2,#6
	jsr	divid2
	lm2	a6,a1
no_weapon:

	lm2	a1,a7
	cmp2	a1,#3000
	bcc	no_weapon1
	lm2	a1,#3000
no_weapon1:	
	lm2	a2,#20
	jsr	divid2
	add	a6,a1

	ldy	#FORCE_OFF
	lda	(you_ptr),y
	sta	a1
	iny
	lda	(you_ptr),y
	sta	a1h			
	lm2	a2,#25
	jsr	divid2
	sub	a6,a1	
	bcc	you_little_force

factor_zero:
        add     a8,a6                   ;damage_bonus +=force_damage

        lda     kf_force
        ora     kf_force+1
        beq     damage_bonus_rts

        lm2     a1,kf_force
        lm2     a2,a8
        jsr	mul2
        lm2     a2,#100
	jsr	divid2
        add     a8,a1
damage_bonus_rts:
	rts
you_little_force:
	rts
	
;------------------------------------------------
;	show message at bottom 3 lines
; input: string_ptr
;------------------------------------------------
show_fight_msg:
	bit	net_flag			;pyh	8-8
	bpl	not_netfight
	jsr	net_send_data
not_netfight:	
	jsr	format_string
	CLS_NLINE	#MAN_FP_Y0-2,#80-MAN_FP_Y0+2

	ldx	#0
	ldy	#80-12*3
	lda	#3
	jsr	show_string

	extrn	waittime
	extrn	delay_1_sec
	ldx	#100
	jsr	waittime
	bit	net_flag	;trans
	bmi	not_delay
	jsr	delay_1_sec
not_delay:
	rts

;------------------------------------------------
; show attack picture
; input: Xreg Yreg
; output: lcdbuf
; destroy:
;------------------------------------------------
show_effect:
	lm2	fccode,#img_exp_ball
	BREAK_FUN	_Bwrite_block
	rts

;--------------------------------------------------------------------
;	write fight screen
; input: emeny_id
;usage:
;SetDigit	macro	x0,y0,value,mvalue
;SetLine	macro	x0,y0,value,mvalue,mitem
;--------------------------------------------------------------------
write_fight:
	push2	lcdbuf_ptr
	lm2	lcdbuf_ptr,#scroll_buf

	CLS_NLINE	#MAN_HP_Y0,#80-MAN_HP_Y0
	lda	#0
	jsr	get_player_img
	lm	img_buf+1,#32		;高度调整为32(原为48)
	ldx	#MAN_X0
	ldy	#MAN_Y0
	jsr	write_block0

	move	img_hp,img_buf,#26
	lm2	fccode,#img_buf
	ldx	#MAN_HP_X0-12
	ldy	#MAN_HP_Y0-2
	jsr	write_block0

	;*************************
	;a3设为线长, a3=39*max/eff
	lm2	a1,#39
	lm2	a2,man_effhp
	jsr	mul2
	lm2	a3,man_maxhp
	jsr	divid42
	lm	a3,a1
	;*************************

	SetLine	#MAN_HP_X0,#MAN_HP_Y0,man_hp,man_effhp,a3
	jsr	show_line
	SetDigit	#MAN_HP_X0+40,#MAN_HP_Y0,man_hp,man_effhp
	jsr	show_digit

	move	img_fp,img_buf,#26
	lm2	fccode,#img_buf
	;lm2	fccode,#img_fp
	ldx	#MAN_FP_X0-12
	ldy	#MAN_FP_Y0-2
	jsr	write_block0
	SetLine	#MAN_FP_X0,#MAN_FP_Y0,man_fp,man_maxfp
	jsr	show_line
	SetDigit	#MAN_FP_X0+40,#MAN_FP_Y0,man_fp,man_maxfp
	jsr	show_digit

	lm2	item_id,G_id_item
	cmp1	located_id,#KILLER_NPC
	bne	not_killer
	lm2	item_id,#474
	lda	ghost_gender_bak
	beq	not_killer
	lm2	item_id,#466
not_killer:
	lm	G_img_cmd,#0	;print
	jsr	get_img_data
write_man:
	ldx	#NPC_X0
	ldy	#NPC_Y0
	jsr	write_block0
	SetLine	#NPC_HP_X0,#NPC_HP_Y0,npc_hp,npc_maxhp
	jsr	show_line
	SetLine	#NPC_FP_X0,#NPC_FP_Y0,npc_fp,npc_maxfp
	jsr	show_line
	;SetDigit	#NPC_HP_X0+40,#NPC_HP_Y0,npc_hp,#0
	;BRK_FUN	_Fshow_digit

	pull2	lcdbuf_ptr
	rts
;--------------------
;output:a3,a4
;-------------------
cal_random_ApDp:
	clc
	lda	attack_point
	adc	dodge_point
	sta	a7
	lda	attack_point+1
	adc	dodge_point+1
	sta	a7h
	lda	attack_point+2
	adc	dodge_point+2
	sta	a8
	lda	attack_point+3
	adc	dodge_point+3
	sta	a8h
	jmp	random4
;-------------------
;output:
;--------------------
cal_random_ApPp:
	clc
        lda     attack_point
        adc     parry_point
        sta     a7
        lda     attack_point+1
        adc     parry_point+1
        sta     a7h
        lda     attack_point+2
        adc     parry_point+2
        sta     a8
        lda     attack_point+3
        adc     parry_point+3
        sta     a8h
random4:
	jsr	perform_random_it
        rts

;--------------------
; 正数直接返回,负数转化成补码
; input:A
; output:cy=0 正数,cy=1 负数
;--------------------
adjust_value:
	bpl	adjust_value_rts
	eor	#0ffh
	clc
	adc	#1
	sec
	rts
adjust_value_rts:
	clc
	rts

;----------------------

;-----------------------
; . 基本属性对战斗的修订
; input:A(ap, dp, pp) a1 a2( ?_point(4byets) )
; output:a1 a2( ?_point(4byets) )
;-----------------------
;注意: 必须紧跟着skill_power用!

point_adjust:
	cmp	#30
	bcc	little_than_30
	sec	
	sbc	#30	
	lsr	a		; 每两点调整 1%
	adc	#100
	jmp	mul_point	
little_than_30:
	sta	a7
	lda	#30
	sec
	sbc	a7
	lsr	a
	sta	a7
	lda	#100
	sec
	sbc	a7
mul_point:
	sta	a3
	lm	a3h,#0
	lm2	a4h,#0
	jsr	mul4		;a1, a2四个字节够用了
	lm2	a3,#100
	jsr	divid42
	rts
;----------------

;----------------------
;clc(sucess) sec(fail)
;---------------------
man_fenshen:
	cmp1	man_kar,#0ffh
	bne	man_fenshen_rts
	lm2	range,#100
	jsr	random_it
	cmp	man_per
	bcs	man_fenshen_rts
	lm2	string_ptr,#fenshen_dodge_msg
	jsr	show_fight_msg
	clc
	rts
man_fenshen_rts:
	sec
	rts
;-----------------
npc_fenshen:
	cmp1	npc_kar,#0ffh
	bne	npc_fenshen_rts
	;这说明npc使用了分身
	lm2	range,#100
	jsr	random_it
	cmp	npc_per			;会不会出现大于100的情况
	bcs	npc_fenshen_rts
	lm2	string_ptr,#fenshen_dodge_msg
	jsr	show_fight_msg
	clc
	rts

npc_fenshen_rts:
	sec
	rts

;------------------------
	if	scode
not_move_msg0:
        db      '$N现在呆若木鸡!',0,0
not_move_msg1:
        db      '$N现在动弹不得!',0,0
not_move_msg2:
	db	'$N转身想溜,被$n一把抓住:想跑,没门!',0,0
fenshen_dodge_msg:
	db	'$N没料到这一击却打了个空，原来打中的只是个影子！',0
	db	0
	else
not_move_msg0:
        db      '$N瞷璝れ蔓!',0,0
not_move_msg1:
        db      '$N瞷笆紆ぃ眔!',0,0
not_move_msg2:
	db	'$N锣ō稱啡,砆$nръ:稱禲,⊿!',0,0
fenshen_dodge_msg:
	db	'$N⊿硂阑玱ゴㄓゴい琌紇',0
	db	0
	endif

;---------------------------------------------------------------------
; fighting image
;---------------------------------------------------------------------
img_hp:
	db	12,8
	db	0ffh,0f0h
	db	0b6h,010h
	db	0b6h,0d0h
	db	0b6h,0d0h
	db	086h,010h
	db	0b6h,0f0h
	db	0b6h,0f0h
	db	0ffh,0f0h
img_fp:
	db	12,8
	db	0ffh,0f0h
	db	086h,010h
	db	0beh,0d0h
	db	0beh,0d0h
	db	08eh,010h
	db	0beh,0f0h
	db	0beh,0f0h
	db	0ffh,0f0h

img_exp_ball:
	db	16,16
	db	00000000b,00010000b
	db	00001000b,00110000b
	db	00001100b,01010000b
	db	00001010b,10011111b
	db	00111001b,10000010b
	db	00010000b,00000100b
	db	00001000b,00001000b
	db	11111000b,00000100b
	db	01000000b,00000010b
	db	00110000b,00000111b
	db	00001000b,00000100b
	db	00010000b,00000010b
	db	00100000b,10110010b
	db	01111111b,01101001b
	db	00000010b,01000101b
	db	00000000b,00000011b

	include	nf.s
;--------------------------------------------------------------------
	end
