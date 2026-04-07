;;******************************************************************
;;	game.s - game
;;
;;	written by lian
;;	begin on 2001/5/10
;;
;;     ┏━━━━━━━━━━━━━━━━━━━━━━━┓
;;     ┃	希望虽然渺茫,但永远存在 	       ┃
;;     ┗━━━━━━━━━━━━━━━━━━━━━━━┛
;;
;;此句是光照天下,大旱甘霖,胜于苦练内功十年的经典名言
;;******************************************************************
	include	h/gmud.h
	include	h/id.h
	include	h/func.mac
	include	h/mud_funcs.h
	include	../prom5/h/ngffs.h

	public	game
	public	exit_game
	public	show_game_menu
	public	set_small_font

	extrn	gmud
	extrn	list_menu
	extrn	clean_list_right

	extrn	setup_attr
	extrn	show_goods
	extrn	show_skills
	extrn	wait_key
	extrn	message_box
	extrn	pop_menu
	extrn	scroll_to_lcd
	extrn	set_tba_buffer
	extrn	format_string
	extrn	show_string
	extrn	get_text_data
	extrn	get_pai_name
	extrn	dazuo_cmd
	extrn	practice_cmd
	extrn	find_kf
	extrn	set_obj
	extrn	get_skill_desc

	extrn	divid42
	extrn	divid2
	extrn	divid_ax
	extrn	mul_ax
	extrn	percent
	extrn	block_draw
	extrn	square_draw
	extrn	line_draw
	extrn	bank_serve
	extrn	jiali
	extrn	recover
	extrn	heal
	extrn	set_read_buf
	extrn	speed_read

;test rcs!
;------------------------------------------------

;------------------------------------------------------------------
;取存档
;	如果有存档且,则
;		1.检查存档合法性
;		2.检查密码
;	否则开始新游戏
;------------------------------------------------------------------
game:
	ldx	#StackTop
	txs
	jsr	clear_all
	
	lm	idles,idleout_second
	lm	idleout_second,#0	;禁止自动关机
	sta	cheat_mode
	sta	walking

	move	inode_buf+I_SectorAddr,my_hotbank,#6
	lm2	phy_sectorslot,inode_buf+I_ISectorAddr
	lm2	phy_sector_offset,#0
	lm2	phy_len,#30
	la	phy_bufptr,my_hotbank+6
	BREAK_FUN	__phyNANDReadBytes

	lm	bank_no,#1
	lm2	SeekOffset,#0
	lm2	DataBufPtr,#txt_class_tbl
	lm2	DataCount,#32
	jsr	speed_read

	lm	bank_no,#1
	lm2	SeekOffset,#0b800h
	lm2	DataBufPtr,#3800h
	lm2	DataCount,#800h
	jsr	speed_read
	
	jsr	init_game
	
	BK2_FUN	_Fload_file
	bcc	create_game

	jsr	set_small_font	;set using 12x12 font
	BK2_FUN	_Fcheck_pwd
	jcc	exit_game

enter_gmud:
	lm2	a1,#SAVE_INTERVAL
	add42	mud_age,a1,save_time

	jsr	setup_attr	;set 后天属性
	jsr	setup_maxhp	;计算maxhp
	jsr	check_player	;合法性检查
	jsr	set_small_font	;set using 12x12 font
	jsr	set_tba_buffer	;打开中断
	jmp	gmud

;-----------------------------------------
create_game:
	lm	text_class,#OTHER_TEXT
	lm	text_id,#THEME_TEXT
	jsr	get_text_data
	ldxy	string_ptr
	BK2_FUN	_Fscroll

	jsr	new_game

	BK2_FUN	_Finput_new
	bcc	exit_game

	jsr	set_attr
	jsr	clear_apply
	BK2_FUN	_Fsave_file
	jmp	enter_gmud

;---------------------------------------
;input: game_stack
;---------------------------------------
exit_game:
	lm	disp_size_flag,#0
	lm	large_size_flag,#1

	jsr	clear_all		;Lee 防止泄密
	
	lm	idleout_second,idles
	BREAK_FUN	__main

clear_all:	
	lm2	a1,#2000h
	ldx	#20h
	lda	#0
	tay
clear_all1:	
	sta	(a1),y
	iny
	bne	clear_all1
	inc	a1h
	dex
	bne	clear_all1
	rts
	
;------------------------------------------------
;清一些临时变量
;------------------------------------------------
clear_apply:
	move	#0,man_goods,#2*MAX_GOODS
	lm	man_goods,#CLOTH
	lm	man_goods+1,#1
	lda	#0
	sta	top_dance+1
	sta	top_ball+1
	lda	#100
	sta	top_dance
	sta	top_ball
	rts

;------------------------------------------------
;进行容错处理
;------------------------------------------------
check_player:
	move	#0,man_attack,#4	;卸掉所有武器装备
	lm	man_weapon,#0		;因为有可能已没有该武器
	move	#0,man_equip,#MAX_EQUIP ;但man_weapon并未清除
	ldy	#0
check_p1:	
	lda	man_goods,y
	and	#7fh
	sta	man_goods,y
	iny
	iny
	cpy	#MAX_GOODS*2
	bcc	check_p1
	;检查功夫的合法性
	ldy	#0
	ldx	#0
to_find:
	cpx	man_kfnum
	beq	no_find

	lda	man_kf,y
	cmp	#KF_NUM
	bcs	no_find

	rept	4
	iny
	endr
	inx
	jmp	to_find
no_find:
	stx	man_kfnum

	ldx	#0
use_next:
	lda	man_usekf,x
	and	#7fh
	cmp	#KF_NUM
	bcc	use_valid
	lda	#0
	sta	man_usekf,x
use_valid:
	inx
	cpx	#MAX_USEKF
	bcc	use_next

	;检查气血的合法性
	cmp2	man_maxhp,man_effhp
	bcs	effhp_rts
	lm2	man_effhp,man_maxhp
effhp_rts:

	cmp2	man_effhp,man_hp
	bcs	hp_rts
	lm2	man_hp,man_effhp
hp_rts:
	rts

;------------------------------------------------
; init game
;------------------------------------------------
init_game:
	CiAll

	lda	#0
	sta	cursor_mode
	sta	net_flag
	sta	busy_flag
	sta	G_Task_Flag

	lm	team_flag,#2h		;!!no_use
	lm	npc_flag,#0ffh
	lm	perform_flag,#0
	move	#0,quest_temp,#72	;清任务区
	lm2	home_buf,#0
	move	#0ffh,npc_stat_buf,#32
	lm2	lcdbuf_ptr,#lcdbuf

	lm	timetick,#TICK_TIME
	rts

;------------------------------------------------
set_small_font:
	;***********
	lm	char_mode,#03h		;font
	lm	disp_size_flag,#1
	lm	large_size_flag,#0
	BREAK_FUN	_Bcal_curr_CPR_RPS

	ldx	#CPR26
	ldy	#80
	lm	char_height,#12
get_large_attr:
	stx	char_row
	sty	char_col
	rts

;------------------------------------------------
; creat new game
;------------------------------------------------
new_game:
	move	man_init_data,save_data,#man_init_len
	lm	man_kfnum,#0
	move 	#0,man_usekf,#MAX_USEKF
	move	#0,zero_area,#ZERO_SIZE
	rts

man_init_data:
	db	VERSION			;game_ver
	db	'HERO'			;game_pid
	dd	0			;mud_age
	db	20,20,20,20,20,20	;attr
	db	0,0ffh			;picid master
	dw	0			;respect

	db	'金远见',0,0,0		;name
	db	0,NONE_PAI,0,14,128	;busy pai gender age daode
	db	0,0,0,0			;attack defense damage armor
	dd	0			;exp
	dw	0			;jiali
	db	20,20,20,20,20,20	;str dex int con per kar
	dw	100,100,0,0,100		;hp fp effhp
	db	0			;weapon
	dw	100,100,100,100,0	;food water pot
	dd	100			;money
man_init_len	equ	$-man_init_data	

;-----------------------------------------
;input: mud_age
;ouput: man_age man_maxhp
;-----------------------------------------
setup_maxhp:
	;计算年龄
	move	mud_age,a1,#4
	lm2	a3,#AGE_TIME
	jsr	divid42
	clc
	lda	a1
	adc	#14
	sta	man_age

	;max_hp属性
	lda	man_age
	cmp	#14
	bcs	$+4
	lda	#14
	cmp	#29
	bcc	$+4
	lda	#29
	sec
	sbc	#14
	ldx	#20
	jsr	mul_ax
	lda	#100
	adda2	a1
	lm2	a2,man_maxfp
	lsr2	a2
	lsr2	a2
	add	a1,a2,man_maxhp

	;微调红莲教义
	cmp1	man_age,#20
	bcc	maxhp_rts
	lda	#JIAOYI_KF
	jsr	find_kf
	bcc	maxhp_rts
	lda	man_kf+1,y
	cmp	#80
	bcc	maxhp_rts

	;红莲教义 * 先天根骨 /10
	ldx	attr_con
	jsr	mul_ax
	lm2	a2,#10
	jsr	divid2
	add	man_maxhp,a1
maxhp_rts:
	rts


;------------------------------------------------
;input: attr_str
;ouput: man_maxfood man_maxwater
;------------------------------------------------
set_attr:
	clc
	lda	attr_str
	adc	#5
	ldx	#15
	jsr	mul_ax
	lm2	man_maxfood,a1
	clc
	lda	attr_str
	adc	#4
	ldx	#15
	jsr	mul_ax
	lm2	man_maxwater,a1
	rts

;------------------------------------------------------------------
;------------------------------------------------------------------
show_game_menu:
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
	db	4		;菜单总数
	db	10000100b	;格式
	db	ARROW_MENU	;菜单方式
	dw	show_look_menu
	dw	show_goods
	dw	show_skills
	dw	show_sys_menu
	if	scode
	db	'查看',0ffh
	db	'物品',0ffh
	db	'技能',0ffh
	db	'功能',0ffh
	else
	db	'琩',0ffh
	db	'珇',0ffh
	db	'м',0ffh
	db	'',0ffh
	endif

;---------------------------------------------------------------
; show system menu
;---------------------------------------------------------------
show_sys_menu:
	PushMenu
	ldx	#SYS_X0
	ldy	#FRAME_Y0
	lm2	menu_ptr,#sys_menu
	jsr	pop_menu
	jsr	scroll_to_lcd
	rts

;-----------------------------------------
end_game:
	ConfirmBox	#6,#20,#6+12*12,#48,confirm_msg
	bcs	no_end_game

	cmp4	mud_age,save_time
	bcc	to_end_game
	ConfirmBox	#12,#32,#12+12*12,#32+38,if_save_msg
	bcs	to_end_game
	BK2_FUN	_Fsave_file

to_end_game:
	jmp	exit_game

no_end_game:
	PullMenu
	jsr	scroll_to_lcd
	rts

	if	scode
confirm_msg	db	'    真的退出游戏吗?',0,0
if_save_msg	db	'你已经好久没存档了,现在保存吗?',0,0
	else
confirm_msg	db	'    痷癶村栏盾?',0,0
if_save_msg	db	'竒⊿郎,瞷玂盾?',0,0
	endif
;-----------------------------------------
save_game:
	PullMenu
	;lm2	string_ptr,#time_fail_msg
	;cmp4	mud_age,save_time
	;bcc	save_fail

	lm2	string_ptr,#save_fail_msg
	BK2_FUN	_Fsave_file
	bcc	save_fail

	jsr	setup_maxhp
	lm2	string_ptr,#save_succ_msg
	lm2	a1,#SAVE_INTERVAL
	add42	mud_age,a1,save_time
save_fail:
	lm	x0,#72
	lm	y0,#10
	lm	x1,#72+12*5
	lm	y1,#26
	jsr	message_box
	jsr	scroll_to_lcd
	rts

	if	scode
;time_fail_msg	db	'请稍后再存',0,0
save_fail_msg	db	'存档失败!',0,0
save_succ_msg	db	'存档成功!',0,0
	else
;time_fail_msg	db	'叫祔',0,0
save_fail_msg	db	'郎ア毖!',0,0
save_succ_msg	db	'郎Θ!',0,0
	endif

;-----------------------------------------
show_practice:
	PullMenu	1
	jsr	scroll_to_lcd
	jsr	practice_cmd
	rts

;-----------------------------------------
show_neili_menu:
	PullMenu	1
	jsr	scroll_to_lcd

	ldx	#SYS_X0
	ldy	#FRAME_Y0+8
	lm2	menu_ptr,#neili_menu
	jsr	pop_menu
	jsr	scroll_to_lcd
neili_rts:
	rts

to_dazuo:
	jsr	dazuo_cmd
	jsr	scroll_to_lcd
	rts

to_jiali:
	jsr	jiali
	jsr	scroll_to_lcd
	rts

to_xiqi:
	smb7	obj_flag
	jsr	recover
	jsr	scroll_to_lcd
	rts

to_heal:
	jsr	heal
	jsr	scroll_to_lcd
	rts

;---------------------------------------
sys_menu:
	db	00000000b	;格式
	db	4		;菜单总数
	db	10000001b	;格式
	db	ARROW_MENU	;菜单方式
	dw	show_neili_menu
	dw	show_practice
	dw	save_game
	dw	end_game
	if	scode
	db	'内力 ',0ffh
	db	'练功 ',0ffh
	db	'存档 ',0ffh
	db	'结束 ',0ffh
	else
	db	'ず ',0ffh
	db	'絤 ',0ffh
	db	'郎 ',0ffh
	db	'挡 ',0ffh
	endif

neili_menu:
	db	00000000b	;格式
	db	4
	db	10000001b
	db	ARROW_MENU
	dw	to_dazuo
	dw	to_jiali
	dw	to_xiqi
	dw	to_heal
	if	scode
	db	'打坐 ',0ffh
	db	'加力 ',0ffh
	db	'吸气 ',0ffh
	db	'疗伤 ',0ffh
	else
	db	'ゴГ ',0ffh
	db	' ',0ffh
	db	' ',0ffh
	db	'励端 ',0ffh
	endif

LOOK_X0		equ	6
LOOK_X1		equ	156
;---------------------------------------------------------------
;---------------------------------------------------------------
show_look_menu:
	lm	lcmd,#0
	block	#LOOK_X0-1,#FRAME_Y0-2,#LOOK_X1,#FRAME_Y0+6*12
	lm	lcmd,#1
	jsr	square_draw

	ldx	#LOOK_X0+8*6
	ldy	#FRAME_Y0
	lm2	menu_ptr,#look_menu
	jsr	pop_menu
	jsr	scroll_to_lcd
	rts

;---------------------------------------------------------------
show_hp:
	lm2	a1,man_effhp
	lm2	a2,man_maxhp
	jsr	percent
	sta	varbuf
	lm2	string_ptr,#hp_msg
	jsr	format_string
	jsr	show_more
	rts

show_score:
	lm2	string_ptr,#score_msg
	jsr	format_string
	jsr	show_more
	rts

show_desc:
	lda	man_pai
	jsr	get_pai_name
	lm2	varbuf,a1

	lda	man_gender
	asl	a
	tax
	lm20x	varbuf+2,xingbei

	lm2	varbuf+4,#no_per_msg
	cmp1	man_age,#16
	bcc	show_score_1
	lm2	varbuf+4,#man_per_desc
	ldx	man_gender
	beq	show_man_per
	dex
	beq	show_girl_per
	lda	game_hour
	lsr	a
	bcs	show_man_per
show_girl_per:	
	lm2	varbuf+4,#girl_per_desc
show_man_per:
	lda	man_per
	cmp	#31
	bcc	$+4
	lda	#31
	sec
	sbc	#10
	ldx	#3
	jsr	divid_ax
	ldx	#18
	jsr	mul_ax
	adda2	varbuf+4
show_score_1:
	lda	#0
	jsr	set_obj
	jsr	get_skill_desc
	lm2	varbuf+6,a1
	lm2	varbuf+8,a2

	lm2	string_ptr,#desc_msg
	jsr	format_string
	jsr	show_more
	rts

	if	scode
xingbei		db	'男女？'
	else
xingbei		db	'╧'
	endif
;---------------------------------------------------------------
;	show format msg
; input: string_ptr
;---------------------------------------------------------------
show_more:
	lm	lcmd,#0
	block	#LOOK_X0+1,#FRAME_Y0+12,#LOOK_X1-1,#FRAME_Y0+6*12-1

	lda	char_height
	lsr	a
	tax
	lda	#LOOK_X0
	jsr	divid_ax
	tax
	ldy	#FRAME_Y0+12

	lda	#5
	jsr	show_string
	bcc	show_more_rts

	lm	cursor_posx,#18
	lm	cursor_posy,#70
	lm	cursor_mode,#FLASH_FLAG
to_wait:
	jsr	wait_key
	cmp	#DOWN_KEY
	beq	show_more

	cmp	#LEFT_KEY
	beq	show_more_rts1
	cmp	#RIGHT_KEY
	beq	show_more_rts1
	cmp	#ESC_KEY
	bne	to_wait
show_more_rts1:
	ora	#80h
	sta	key
show_more_rts:
	lm	cursor_mode,#0
	rts

;----------------------------------------------------------
look_menu:
	db	01000100b	;格式
	db	3		;菜单总数
	db	00010000b	;格式
	db	ICON_MENU1	;菜单方式
	dw	0,show_hp
	dw	0,show_desc
	dw	0,show_score
	if	scode
	db	'状态',0ffh
	db	'描述',0ffh
	db	'属性',0ffh
	else
	db	'篈',0ffh
	db	'磞瓃',0ffh
	db	'妮┦',0ffh
	endif

;---------------------------------------------------------
hp_msg:
	if	scode
	db	'食物:',2
	dw	man_food,10
	db	'/',2
	dw	man_maxfood,0
	db	'饮水:',2
	dw	man_water,10
	db	'/',2
	dw	man_maxwater,0

	db	'生命:',2
	dw	man_hp,10
	db	'/',2
	dw	man_effhp,10
	db	'(',1
	dw	varbuf,10
	db	'%)',0

	db	'内力:',2
	dw	man_fp,10
	db	'/',2
	dw	man_maxfp,10
	db	'(+',2
	dw	man_force,10
	db	')',0

	db	'经验:',4
	dw	man_exp,10
	db	' 潜能:',2
	dw	man_pot,0
	db	0
	else
	db	':',2
	dw	man_food,10
	db	'/',2
	dw	man_maxfood,0
	db	'都:',2
	dw	man_water,10
	db	'/',2
	dw	man_maxwater,0

	db	'ネ㏑:',2
	dw	man_hp,10
	db	'/',2
	dw	man_effhp,10
	db	'(',1
	dw	varbuf,10
	db	'%)',0

	db	'ず:',2
	dw	man_fp,10
	db	'/',2
	dw	man_maxfp,10
	db	'(+',2
	dw	man_force,10
	db	')',0

	db	'竒喷:',4
	dw	man_exp,10
	db	' 肩:',2
	dw	man_pot,0
	db	0
	endif

desc_msg:
	if	scode
	db	'[',8
	dw	varbuf,10
	db	']',7
	dw	man_name,0
	db	'你是一位',1
	dw	man_age,10
	db	'岁的',6
	dw	varbuf+2,10
	db	'性',0
	db	'你',8
	dw	varbuf+4,0

	db	'武艺看起来',9
	dw	wuyi_desc,0
	db	'出手似乎',9
	dw	chushou_desc,0
	db	0
	else
	db	'[',8
	dw	varbuf,10
	db	']',7
	dw	man_name,0
	db	'琌',1
	dw	man_age,10
	db	'烦',6
	dw	varbuf+2,10
	db	'┦',0
	db	'',8
	dw	varbuf+4,0

	db	'猌美癬ㄓ',9
	dw	wuyi_desc,0
	db	'も',9
	dw	chushou_desc,0
	db	0
	endif
wuyi_desc
	db	8
	dw	varbuf+6
chushou_desc
	db	4
	dw	varbuf+8

score_msg:
	if	scode
	db	'金钱:',4
	dw	man_money,0
	db	'膂力 [',1
	dw	man_str,10
	db	'/',1
	dw	attr_str,10
	db	'] 命中 [',1
	dw	man_attack,10
	db	']',0

	db	'敏捷 [',1
	dw	man_dex,10
	db	'/',1
	dw	attr_dex,10
	db	'] 回避 [',1
	dw	man_defense,10
	db	']',0

	db	'悟性 [',1
	dw	man_int,10
	db	'/',1
	dw	attr_int,10
	db	'] 攻击 [',1
	dw	man_damage,10
	db	']',0

	db	'根骨 [',1
	dw	man_con,10
	db	'/',1
	dw	attr_con,10
	db	'] 防御 [',1
	dw	man_armor,10
	db	']',0
	db	0
	else
	db	'窥:',4
	dw	man_money,0
	db	'籑 [',1
	dw	man_str,10
	db	'/',1
	dw	attr_str,10
	db	'] ㏑い [',1
	dw	man_attack,10
	db	']',0

	db	'庇倍 [',1
	dw	man_dex,10
	db	'/',1
	dw	attr_dex,10
	db	'] 磷 [',1
	dw	man_defense,10
	db	']',0

	db	'┦ [',1
	dw	man_int,10
	db	'/',1
	dw	attr_int,10
	db	'] ю阑 [',1
	dw	man_damage,10
	db	']',0

	db	'癌 [',1
	dw	man_con,10
	db	'/',1
	dw	attr_con,10
	db	'] ň眘 [',1
	dw	man_armor,10
	db	']',0
	db	0
	endif

	if	scode
man_per_desc:
	db	'一塌糊涂,不是人样',0
	db	'牛眼马嘴,面目狰狞',0
	db	'小鼻小眼,一脸麻子',0
	db	'相貌平平,还过得去',0
	db	'五官端正,身材匀称',0
	db	'相貌英俊,双目有神',0
	db	'气宇轩昂,骨骼清奇',0
	db	'风流俊雅,仪表堂堂',0
girl_per_desc:
	db	'貌赛无盐,惨不忍睹',0
	db	'眼小嘴大,相貌丑陋',0
	db	'看上去...马马虎虎',0
	db	'相貌平平,还过得去',0
	db	'身材娇好,尚有资色',0
	db	'婷婷玉立,美貌如花',0
	db	'沉鱼落雁,闭月羞花',0
	db	'美奂绝伦,人间仙子',0
no_per_msg:
	db	'一脸稚气',0
	else
man_per_desc:
	db	'厄絢襖,ぃ琌妓',0
	db	'泊皑糒,ヘ瞮礼',0
	db	'惑泊,羪陈',0
	db	'华キキ,临筁眔',0
	db	'き﹛狠タ,ōっ嘿',0
	db	'华璣玊,蛮ヘΤ',0
	db	'癮,癌纅睲',0
	db	'瑈玊懂,祸绑绑',0
girl_per_desc:
	db	'华辽礚芉,篏ぃг窣',0
	db	'泊糒,华ぁ',0
	db	'...皑皑',0
	db	'华キキ,临筁眔',0
	db	'ō糱,﹟Τ戈︹',0
	db	'碄碄ドミ,华',0
	db	'↖辰辅董,超る槽',0
	db	'荡,丁',0
no_per_msg:
	db	'羪竂',0
	endif
;------------------------------------------------------------------
	end
