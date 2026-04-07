;;******************************************************************
;;	npc.s - mud dialog (man to npc)
;;
;;	written by lian
;;	begin on
;;	finish on
;;******************************************************************
	include	h/gmud.h
	include	h/id.h
	include	h/func.mac
	include	h/mud_funcs.h

	public	npc_action
	public	find_npc_kf
	public	query_npc_skill
	public	get_npc_name
	public	get_pai_name
	public	init_npc
	public	master1

	extrn	init_ghost
	extrn	set_all_goods
	extrn	add_goods
	extrn	find_goods
	extrn	get_goods_attr
	extrn	get_goods_name
	extrn	goods_name_tbl
	extrn	find_kf
	extrn	add_kf
	extrn	kf_name_tbl
	extrn	get_text_data
	extrn	get_basic_kf
	extrn	set_obj
	extrn	get_skill_desc

	extrn	show_talk_msg
	extrn	show_talk_msg0
	extrn	pop_menu
	extrn	format_string
	extrn	show_string
	extrn	scroll_to_lcd
	extrn	find_name
	extrn	show_process
	extrn	cat_string
	extrn	message_box_more
	extrn	show_one_line

	extrn	divid_ax
	extrn	random_it
	extrn	mul_ax
	extrn	mul2
	extrn	divid42
	extrn	npc_quest
	extrn	pyh_learn
	extrn	bank_serve
	extrn	set_die_stat
	extrn	divid2
	extrn	mul4
	extrn	refresh_scroll
	extrn	show_bonus
	extrn	message_box

BUY_X0		equ	6
BUY_Y0		equ	16
PRICE_X0	equ	BUY_X0
PRICE_Y0	equ	BUY_Y0+40

LEARN_X0	equ	6
LEARN_Y0	equ	16

DAXIA_EXP	equ	200000
;---------------------------------------------------------------
; 逐个检查 NPC 动作, 如有动作则sec 反之clc
; 前提是每个NPC只能是某一类
;
; NPC类别: 1.任务NPC 2.师傅NPC 3.商人NPC
; input: located_id
;---------------------------------------------------------------
npc_action:
	PushMenu
	jsr	scroll_to_lcd

	jsr	init_npc

	ldx	#1
	ldy	#2
	lm2	string_ptr,#npc_name
	jsr	show_one_line
	jsr	init_menu
	SET_TALK_XY	38
	jsr	pop_menu
	jsr	scroll_to_lcd
	rts

;------------------------------------------------
;	get npc data
;如果这次访问的NPC和上次相同;则不取数据
;这样NPC的状态可以保存下来
;注意: 需要维护 npc_flag 变量的值
; input: located_id
; output: npc_state
;------------------------------------------------
init_npc:
	;cmp1	npc_flag,located_id
	;bne	$+3
	;rts

	jsr	init_ghost
	bcs	check_weapon
	lm	text_class,#NPC_DATA
	lm	text_id,located_id
	jsr	get_text_data

check_weapon:
	;******** 动态加上npc_damage和npc_armor *********
	lda	npc_weapon
	bpl	check_equip
	and	#7fh
	jsr	get_goods_attr

	ldy	#2
	lda	(a1),y
	clc
	adc	npc_damage
	sta	npc_damage

check_equip:
	lda	npc_equip
	bpl	init_npc_rts
	and	#7fh
	jsr	get_goods_attr

	ldy	#2
	lda	(a1),y
	clc
	adc	npc_armor
	sta	npc_armor
	;******** 加上npc_damage和npc_armor *********

	;******** 计算后天属性 ************
	lda	#BASIC_BARE_KF
	jsr	find_npc_kf
	bcc	next_attr1
	lda	npc_kf+1,y
	ldx	#10
	jsr	divid_ax
	clc
	adc	npc_str
	sta	npc_str
next_attr1:
	lda	#BASIC_DODGE_KF
	jsr	find_npc_kf
	bcc	next_attr2
	lda	npc_kf+1,y
	ldx	#10
	jsr	divid_ax
	clc
	adc	npc_dex
	sta	npc_dex
next_attr2:
	;******** 计算后天属性 ************

init_npc_rts:
	lm	npc_flag,located_id
	rts

;----------------------------------------------------------
;	get dynamic menu
;input: npc_state
;ouput: menu_ptr
;----------------------------------------------------------
init_menu:
	;for special npc
	lda	located_id
	INDEX	SPECIAL_NUM,special_npc
	lm2	menu_ptr,a1
	bcs	init_menu_rts

	lm2	menu_ptr,#npc_menu4	;学习
	cmp1	man_master,located_id
	beq	init_menu_rts

	lm2	menu_ptr,#npc_menu1	;通用
	cmp1	npc_pai,#NONE_PAI
	beq	init_menu_rts

	lm2	menu_ptr,#npc_menu2	;交易
	cmp1	npc_pai,#TRADE_PAI
	beq	init_menu_rts
	lm2	menu_ptr,#npc_menu3	;拜师
init_menu_rts:
	rts

special_npc:
	db	TEACHER_NPC
	db	DAXIA_NPC
	db	KILLER_NPC
SPECIAL_NUM	equ	$-special_npc
	dw	npc_menu4
	dw	npc_menu4
	dw	npc_menu1

;-------------------------------------------
;和npc交谈
;-------------------------------------------
	extrn	pyh_task		;pyh	8-31
	extrn	find_quest_id
	extrn	set_quest_over
npc_talk:
	PullMenu
	jsr	scroll_to_lcd
	
	jsr	pyh_task		;接任务
	bcc	query_find
	jmp	scroll_to_lcd

query_find:
	lda	#QUEST_NPC
	jsr	find_quest_id		;找人任务
	beq	query_npc_quest
	cmp	located_id
	bne	query_npc_quest

	lda	#QUEST_NPC
	jsr	set_quest_over
	lm2	string_ptr,#know_msg	;pyh	8-31
	jmp	npc_dunno1

query_npc_quest:
	;将npc的quest插在这里,pyh	9-10
	;入口:located_id
	lda	located_id
	jsr	npc_quest		;quest
	bcs	npc_dunno
	rts

npc_dunno:
	lm2	range,#5
	jsr	random_it
	asl	a
	tax
	lm20x	string_ptr,dunno_msg_tbl
	jsr	format_string
npc_dunno1:	
	jsr	show_talk_msg
	jmp	scroll_to_lcd

dunno_msg_tbl:
	dw	dunno_msg1
	dw	dunno_msg2
	dw	dunno_msg3
	dw	dunno_msg4
	dw	dunno_msg5
	if	scode
dunno_msg1:
	db	'$o睁大眼睛望著你，显然不知道你在说什麽',0,0
dunno_msg2:
	db	'$o打了个哈哈:今天的天气真是,哈哈',0,0
dunno_msg3:
	db	'$o看了你一眼,又转身忙自己的事情去了',0,0
dunno_msg4:
	db	'没看到我在忙吗,你还是找别人CHAT去吧',0,0
dunno_msg5:
	db	'我什么也不知道,就算知道也不说,打死你我也不说',0,0
	else
dunno_msg1:
	db	'$o窩泊氟辨帝陪礛ぃ笵弧ぐ或',0,0
dunno_msg2:
	db	'$oゴ:さぱぱ痷琌,',0,0
dunno_msg3:
	db	'$o泊,锣ōΓㄆ薄',0,0
dunno_msg4:
	db	'⊿иΓ盾,临琌тCHAT',0,0
dunno_msg5:
	db	'иぐぃ笵,碞衡笵ぃ弧,ゴиぃ弧',0,0
	endif

;-------------------------------------------
;查看npc
;-------------------------------------------
npc_look:
	PullMenu

	;**** age *****
	lda	npc_age
	ldx	#10
	jsr	divid_ax
	ldx	#10
	jsr	mul_ax
	sta	varbuf+2

	lda	#1
	jsr	set_obj
	jsr	get_skill_desc
	lm2	varbuf+4,a1
	lm2	varbuf+6,a2

	;**** goods *****
	lm	tmp1,#0
l_goods:
	lm2	a1,#0
	ldx	tmp1
	lda	npc_goods,x
	bpl	no_equip
	and	#7fh
	jsr	get_goods_name
no_equip:
	lda	tmp1
	asl	a
	tax
	lm2x0	varbuf+10,a1
	inc	tmp1
	cmp1	tmp1,#3
	bcc	l_goods

	lm2	string_ptr,#npc_desc_msg
	jsr	format_string
	lm	x0,#6
	lm	y0,#3
	lm	x1,#156
	lm	y1,#77
	jsr	message_box_more
	jmp	scroll_to_lcd

;-------------------------------------------
;和npc战斗
;-------------------------------------------
npc_fight:
	PullMenu
	smb7	busy_flag
	BK2_FUN	_Ffight
	bit	net_flag
	jmi	fail_quit
	cmp	#2
	jeq	fail_quit
	cmp	#3
	beq	man_win
	cmp	#1
	beq	not_quest
npc_win:
	extrn	exit_game
	jmp	exit_game
man_win:
	jsr	set_die_stat

	extrn	find_quest_id
	extrn	set_quest_over
	lda	#QUEST_KILL
	jsr	find_quest_id
	cmp	located_id
	bne	check_ghost

	lda	#QUEST_KILL
	jsr	set_quest_over
	inc	si_kill
	jmp	not_quest
check_ghost:
	lda	#QUEST_GHOST
	jsr	find_quest_id
	cmp	located_id
	bne	not_quest
	lda	#QUEST_GHOST
	jsr	set_quest_over		;Yreg可以使用

	lda	quest_temp+5,y
	sta	task_buf+2
	lda	quest_temp+6,y
	sta	task_buf+3
	lm2	a1,task_buf+2
	lm2	a2,#4
	jsr	divid2
	lm2	task_buf+4,a1
	jsr	show_bonus
	rmb7	G_Task_Flag

not_quest:
	jsr	get_npc_goods

fail_quit:
	jsr	refresh_scroll
	rmb7	busy_flag
	rts

get_npc_goods:
	add42	man_money,npc_money

	lm	tmp1,#0
l_get:
	lda	tmp1
	asl	a
	tax
	lda	#0
	sta	varbuf,x
	sta	varbuf+1,x

	ldx	tmp1
	lda	npc_goods,x
	beq	no_goods
	cmp	#SANJIAO
	bne	l_get1
	ldx	npc_pai
	lda	shiban_tbl,x
	bit	shiban
	bne	no_goods
	ora	shiban
	sta	shiban
	lda	#SANJIAO
l_get1:	
	and	#7fh
	sta	goods_id
	jsr	add_goods

	lda	goods_id
	jsr	get_goods_name
	lda	tmp1
	asl	a
	tax
	lm2x0	varbuf,a1
no_goods:
	inc	tmp1
	cmp1	tmp1,#4
	bcc	l_get

	lm2	string_ptr,#get_msg
	jsr	format_string
	lm	x0,#6
	lm	y0,#3
	lm	x1,#6+12*12
	lm	y1,#3+6*12
	jsr	message_box
	rts

shiban_tbl:
	db	0,1,2,4,8,16,32

	if	scode
get_msg:
	db	'大获全胜!战斗获得',0
	db	'金钱:',2
	dw	npc_money,0
	db	'物品:',8
	dw	varbuf,10
	db	' ',8
	dw	varbuf+2,10
	db	' ',8
	dw	varbuf+4,10
	db	' ',8
	dw	varbuf+6,0
	db	0
	else
get_msg:
	db	'莉秤!驹ゆ莉眔',0
	db	'窥:',2
	dw	npc_money,0
	db	'珇:',8
	dw	varbuf,10
	db	' ',8
	dw	varbuf+2,10
	db	' ',8
	dw	varbuf+4,10
	db	' ',8
	dw	varbuf+6,0
	db	0
	endif
;-------------------------------------------
;向npc拜师
;-------------------------------------------
npc_apprentice:
	PullMenu
	jsr	scroll_to_lcd

	lm2	string_ptr,#have_kf_msg
	lda	man_pai
	cmp	#XIAOYAO_PAI
	beq	apprentice_fail

	lm2	string_ptr,#have_master_msg
	lda	man_pai
	cmp	#NONE_PAI
	beq	to_baishi
	cmp	npc_pai
	bne	apprentice_fail

to_baishi:
	lda	located_id
	BK2_FUN	_Fbaishi
	bcs	apprentice_fail

	lda	located_id
	sta	man_master
	lda	npc_pai
	sta	man_pai
	lm2	a1,#apprentice_msg
	jsr	cat_string

apprentice_fail:
	jsr	format_string
	jmp	npc_dunno1

;-------------------------------------------
;和npc交易
;-------------------------------------------
npc_trade:
	PullMenu
	jsr	scroll_to_lcd
	jsr	dealer
	jsr	scroll_to_lcd
	rts

;-------------------------------------------
;向npc请教
;-------------------------------------------
npc_learn:
	PullMenu
	jsr	scroll_to_lcd
	lda	located_id
	cmp	#DAXIA_NPC
	bne	to_learn
	lm2	a2,#DAXIA_EXP/65536
	lm2	a1,#DAXIA_EXP%65536
	cmp4	man_exp,a1
	bcs	to_learn
	;cant learn
	lm2	string_ptr,#daxia_low_msg
	jmp	npc_dunno1
to_learn:
	jsr	master
	jsr	scroll_to_lcd
	rts

daxia_low_msg:
	if	scode
	db	'去去去,攒够经验再来吧!',0,0
	else
	db	',鲢镑竒喷ㄓ!',0,0
	endif
;----------------------------------------------------------------
;	DEALER NPC
; input: man_state
;----------------------------------------------------------------
dealer:
	lda	vendor_goods
	bne	buy_goods
	beq	sell_goods
	rts

;----------------------------------------
buy_goods:
	PushMenu
	lm2	string_ptr,#deal_msg
	jsr	show_talk_msg0

	lm2	goods_ptr,#vendor_goods
	lm2	menu_ptr,#buy_menu
	lm2	a1,goods_ptr
	ldx	#BUY_X0
	ldy	#BUY_Y0
	jsr	pop_menu
	rts

;----------------------------------------
sell_goods:
	PushMenu
	lm2	string_ptr,#deal1_msg
	jsr	show_talk_msg0

	lm2	a1,#dmenu_buf
	jsr	set_all_goods
	lm2	goods_ptr,a1
	lm2	menu_ptr,#sell_menu
	lm2	a1,goods_ptr
	ldx	#BUY_X0
	ldy	#BUY_Y0
	jsr	pop_menu
	rts

;---------------------------------------
; input: menu_set
;---------------------------------------
show_price1:	;buy
	ldy	menu_set
	iny
	lda	(goods_ptr),y
	sta	goods_id
	jsr	get_goods_attr
	ldy	#6
	lda	(a1),y
	sta	goods_price
	iny
	lda	(a1),y
	sta	goods_price+1
	jmp	show_price
show_price2:	;sell
	lda	menu_set
	asl	a
	tay
	iny
	lda	(goods_ptr),y
	sta	goods_id
	and	#7fh
	jsr	get_goods_attr
	ldy	#6
	lda	(a1),y
	sta	goods_price
	iny
	lda	(a1),y
	sta	goods_price+1
	lm2	a1,goods_price
	lm2	a2,#7
	jsr	mul2
	lm2	a3,#10
	jsr	divid42
	lm2	goods_price,a1

show_price:
	lm2	string_ptr,#goods_price_msg
	jsr	format_string

	ldx	#PRICE_X0/12+1
	ldy	#PRICE_Y0
	lda	#6
	jsr	show_string
	rts

;---------------------------------------------
; input: goods_id
;---------------------------------------------
buy_it:
	lda	man_money+2
	ora	man_money+3
	bne	to_sub_money
	cmp2	man_money,goods_price
	bcc	no_money
to_sub_money:
	jsr	add_goods
	bcc	no_money
	sub42	man_money,goods_price
	PullMenu
	rts

no_money:
	rts

;---------------------------------------------
; input: menu_set goods_id
;---------------------------------------------
sell_it:
	lda	goods_id
	bmi	no_sell
	jsr	find_goods
	bcc	no_sell

	dec	man_goods+1,x
	add42	man_money,goods_price

	lda	menu_set
	asl	a
	tay
	iny
	iny
	lda	(goods_ptr),y
	sec
	sbc	#1
	sta	(goods_ptr),y
	bne	no_sell
	PullMenu
no_sell:
	rts

;----------------------------------------------------------------
; input: located_id
;----------------------------------------------------------------
master:
	lm2	string_ptr,#learn_msg
	jsr	show_talk_msg0
master1:	
	lm2	kf_ptr,#npc_kfnum
	lm2	a1,kf_ptr
	lm2	menu_ptr,#master_menu
	ldx	#LEARN_X0
	ldy	#LEARN_Y0
	jsr	pop_menu
	rts

;-------------------------------------
;input: kf_ptr menu_set
;outout: kf_id
;-------------------------------------
learn_it:
	lda	menu_set
	asl	a
	tay
	iny
	lda	(kf_ptr),y
	sta	kf_id
	iny
	lda	(kf_ptr),y
	sta	game_buf	;master skill_level

	lda	kf_id
        jsr	add_kf
	bcc	learn_rts

        ldxy    #learn_tbl
	smb7	busy_flag
        jsr     show_process
	rmb7	busy_flag
        jsr     scroll_to_lcd

	lda	kf_id
        jsr	find_kf
	bcc	learn_rts
	lda	man_kf+1,y
	bne	learn_rts
	dec	man_kfnum
learn_rts:
        rts

learn_tbl:
	;y0的位置需要调整
        db      32,1                    ;x0,y0
        dw      learn_set_line,learn_set_digit      ;ouput:binbuf bcdbuf
        ;dw      1000                    ;单位:ms
        dw      4        ;单位:ms,学习速度加快50倍,改为50ms, pyh 1-10
        dw      learn_inc_continue            ;program
learn_set_line:
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
learn_set_digit:
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
learn_inc_continue:
        jsr 	pyh_learn	;sec: quit
        rts

;--------------------------------------------------------
; input: Areg(located_id)
; output: a1(name address)
;--------------------------------------------------------
get_npc_name:
	sta	text_id
	lm	text_class,#NPC_NAME
	jsr	get_text_data
	lm2	a1,string_ptr
	rts

;--------------------------------------------------------
; input: Areg
; output: a1
;--------------------------------------------------------
get_pai_name:
	lm2	a1,#pai_name_tbl,x
	jsr	find_name
	rts

;--------------------------------------------------------
; input: kf_type
; output: skill_level
;--------------------------------------------------------
query_npc_skill:
	lm2	skill_level,#0
	lda	kf_type
	ora	#80h
	jsr	get_basic_kf
	jsr	find_npc_kf
	bcc	query_rts

	lda	npc_kf+1,y
	lsr	a
	sta	skill_level

	ldy	kf_type
	lda	npc_usekf,y
	bpl	query_rts
	and	#7fh
	jsr	find_npc_kf
	bcc	query_rts

	lda	npc_kf+1,y
	adda2	skill_level
query_rts:
	rts

;----------------------------------------------------
; input: Areg (=kf_id)
; output: cy(sec:find, clc:no find) Xreg Yreg
; Destry: 
;----------------------------------------------------
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

;-------------------------------------
npc_menu1:
	db	00000000b
	db	3
	db	10000001b
	db	BOX_MENU
	dw	npc_talk
	dw	npc_look
	dw	npc_fight
	if	scode
	db	'交谈',0ffh
	db	'查看',0ffh
	db	'战斗',0ffh
	else
	db	'ユ酵',0ffh
	db	'琩',0ffh
	db	'驹ゆ',0ffh
	endif

npc_menu2:
	db	00000000b
	db	4
	db	10000001b
	db	BOX_MENU
	dw	npc_talk
	dw	npc_look
	dw	npc_fight
	dw	npc_trade
	if	scode
	db	'交谈',0ffh
	db	'查看',0ffh
	db	'战斗',0ffh
	db	'交易',0ffh
	else
	db	'ユ酵',0ffh
	db	'琩',0ffh
	db	'驹ゆ',0ffh
	db	'ユ',0ffh
	endif

npc_menu3:
	db	00000000b
	db	4
	db	10000001b
	db	BOX_MENU
	dw	npc_talk
	dw	npc_look
	dw	npc_fight
	dw	npc_apprentice
	if	scode
	db	'交谈',0ffh
	db	'查看',0ffh
	db	'战斗',0ffh
	db	'拜师',0ffh
	else
	db	'ユ酵',0ffh
	db	'琩',0ffh
	db	'驹ゆ',0ffh
	db	'畍',0ffh
	endif

npc_menu4:
	db	00000000b
	db	4
	db	10000001b
	db	BOX_MENU
	dw	npc_talk
	dw	npc_look
	dw	npc_fight
	dw	npc_learn
	if	scode
	db	'交谈',0ffh
	db	'查看',0ffh
	db	'战斗',0ffh
	db	'请教',0ffh
	else
	db	'ユ酵',0ffh
	db	'琩',0ffh
	db	'驹ゆ',0ffh
	db	'叫毙',0ffh
	endif

master_menu:
	db	10111110b
	db	80h
	db	10110001b
	db	RADIO_MENU
	dw	learn_it
	dw	kf_name_tbl
buy_menu:
	db	11011000b
	db	80h
	db	10110001b
	db	RADIO_MENU
	dw	buy_it,show_price1
	dw	goods_name_tbl
sell_menu:
	db	11111011b
	db	80h
	db	10110001b
	db	RADIO_MENU
	dw	sell_it,show_price2
	dw	goods_name_tbl

;--------------------------------------------------------
npc_desc_msg:
	if	scode
	db	7
	dw	npc_name,10
	db	'看起来约',1
	dw	varbuf+2,10
	db	'多岁',0
	db	'武艺看起来',9
	dw	wuyi_desc,0
	db	'出手似乎',9
	dw	chushou_desc,0
	db	'带著:',8
	dw	varbuf+10,10
	db	' ',8
	dw	varbuf+12,10
	db	' ',8
	dw	varbuf+14,0
	db	7
	dw	npc_desc,0
	db	0
	else
	db	7
	dw	npc_name,10
	db	'癬ㄓ',1
	dw	varbuf+2,10
	db	'烦',0
	db	'猌美癬ㄓ',9
	dw	wuyi_desc,0
	db	'も',9
	dw	chushou_desc,0
	db	'盿帝:',8
	dw	varbuf+10,10
	db	' ',8
	dw	varbuf+12,10
	db	' ',8
	dw	varbuf+14,0
	db	7
	dw	npc_desc,0
	db	0
	endif
wuyi_desc
	db	8
	dw	varbuf+4
chushou_desc
	db	4
	dw	varbuf+6

goods_price_msg:
	if	scode
	db	'金钱:',4
	dw	man_money,10
	db	' 价格:',5
	dw	goods_price,0
	db	0
	else
	db	'窥:',4
	dw	man_money,10
	db	' 基:',5
	dw	goods_price,0
	db	0
	endif

;-----------------------------------------------------
	if	scode
know_msg:
	db	'我知道了,多谢来访!',0,0
deal_msg:
	db	'要买什么你自己看看吧!',0,0
deal1_msg:
	db	'有什么不用的东西就拿来吧!',0,0
learn_msg:
	db	'你想学什么就说吧!',0,0
is_apprentice_msg:
	;db	'你恭恭敬敬地向$o磕头请安，叫道：「师父！」',0,0
have_master_msg:
	db	'你已另有名师,还想来我这儿偷师学艺吗?',0,0
have_kf_msg:	
	db	'你已自创门派,无需拜师吧?',0,0
apprentice_msg:
	db	'你跪了下来向$o恭恭敬敬地磕了四个响头，叫道：「师父！」',0
	db	'恭喜您成为$o弟子',0
	db	0
	else
know_msg:
	db	'и笵,谅ㄓ砐!',0,0
deal_msg:
	db	'璶禦ぐ!',0,0
deal1_msg:
	db	'Τぐぃノ狥﹁碞ㄓ!',0,0
learn_msg:
	db	'稱厩ぐ碞弧!',0,0
is_apprentice_msg:
	;db	'穛穛$o絎繷叫笵畍',0,0
have_master_msg:
	db	'Τ畍,临稱ㄓи硂ㄠ敖畍厩美盾?',0,0
have_kf_msg:
	db	'承,礚惠畍?',0,0
apprentice_msg:
	db	'各ㄓ$o穛穛絎臫繷笵畍',0
	db	'尺眤Θ$o',0
	db	0
	endif

;-----------------------------------------------------
	if	scode
pai_name_tbl:
	db	'江湖小虾',0
	db	'八卦门',0
	db	'花间派',0
	db	'红莲教',0
	db	'尹贺谷',0
	db	'太极门',0
	db	'雪山剑派',0
	db	'逍遥派',0
	else
pai_name_tbl:
	db	'打郊',0
	db	'',0
	db	'丁',0
	db	'浆毙',0
	db	'え禤é',0
	db	'び伐',0
	db	'撤糃',0
	db	'硃换',0
	endif

;----------------------------------------------------------------
	end
