;====================================================
;
;	第一类任务系统(寻人, 寻物, 杀NPC)
;
;	writen by : pyh		2001/8/29
;
;	杀妖任务		2001/9/3
;
;
;====================================================
;程序的扩展性很好!
;任务的数据要把id为0的人和物品去掉
;!还没有include数据文件
;数据文件格式:
;	quest_goods_tbl:
;		db	1		;第一个字节,任务总数
;		dd	10		;任务的经验上限
;		db	YAO		;任务对应的id
;		dd	1000
;		db	BOOK
;		. . . 
	
	include	h/gmud.h
	include	h/id.h
	include	h/mud_funcs.h
	include	h/func.mac

;--------------------------------
MAXREWARD	equ	200
MAXDELAY	equ	80
DELAY_CONST 	equ	35
TEMP_SIZE	equ	12		;数组的元素个数
QUEST_DATA_SIZE	equ	5
QUEST_INDEX_OFF	equ	0
QUEST_EXP_OFF	equ	1
QUEST_ID_OFF	equ	5
QUEST_DELAY_OFF	equ	6
QUEST_REWARD_OFF	equ	10

HAS_REWARD	equ	0feh
QUEST_OVER	equ	0ffh
MENPAI_NUM	equ	6
GHOST_NUM	equ	8
SPACE_CONST	equ	10
GHOST_AGE	equ	34
REWARD_MAXDELAY	equ	1200		;20分钟
GHOST_BONUS	equ	80
DONE_LIMIT	equ	300		;300秒
WAIT_LIMIT	equ	1200
;--------------------------------

__base		equ	game_buf
		define	1,quest_numbers
		define	1,quest_index
		define	4,quest_exp
		define	4,quest_delay
		define	2,quest_reward
		define	1,ghost_level
		define	1,select_street_id
		define	1,select_room_id
		define	1,select_room_type
		define	2,task_temp1
		define	2,task_temp2
		define	2,task_temp3
		define	100,task_id_buf

ghost_state       equ	task_temp3
        define  MAX_NAME+1,ghost_name
        define  1,ghost_flag
        define  1,ghost_pai
        define  1,ghost_gender
        define  1,ghost_age
	define	1,ghost_daode
ghost_fight_buf   equ     __base
        define  1,ghost_attack
        define  1,ghost_defense
        define  1,ghost_damage
        define  1,ghost_armor
        define  4,ghost_exp
        define  2,ghost_force
        define  1,ghost_str
        define  1,ghost_dex
        define  1,ghost_int
        define  1,ghost_con
        define  1,ghost_per
        define  1,ghost_kar
        define  2,ghost_hp
        define  2,ghost_maxhp
        define  2,ghost_fp
        define  2,ghost_maxfp
        define  2,ghost_effhp
GHOST_DATE_LEN	equ	__base-ghost_fight_buf
        define  1,ghost_weapon
        define  1,ghost_equip
        define  2,ghost_money
        define  MAX_USEKF,ghost_usekf     ;bit7:1 enable 0: no
        define  1,ghost_kfnum
        define  2*MAX_KF,ghost_kf         ;功夫(id 级别)
        define  2,ghost_desc              ;long describe
	
		
;--------------------------------

	public	pyh_task
	public	set_quest_over
	public	find_quest_id
	public	init_ghost
	public	show_bonus

	extrn	random_map
	extrn	format_string
	extrn	show_talk_msg
	extrn	find_goods
	extrn	scroll_to_lcd
	extrn	set_live_stat
	extrn	message_box_for_pyh
	extrn	get_all_goods

	extrn	mul_ax
	extrn	mul2
	extrn	mul4
	extrn	random_it
	extrn	divid2
	extrn	divid4
	extrn	divid42
	extrn	divid_ax
	extrn	get_all_npc

;---------------------------------------------
; input: located_id
; output: cy
;---------------------------------------------
pyh_task:
        lda     located_id
        SWITCH  #TASK_NUM,task_npc_tbl
        rts

task_npc_tbl:
	db	CUNZHANG_NPC
	db	FUREN_NPC
	db	PINGYIZHI_NPC
	db	BUKUAI_NPC
	db	TEACHER_NPC
	db	OLDLADY_NPC
TASK_NUM        equ     $-task_npc_tbl
        dw      query_npc
	dw	query_goods
	dw	query_kill
	dw	query_ghost
	dw	pyh_task_bonus
	dw	voluntary_work
;---------------
query_npc:
	lda	#QUEST_NPC
	jmp	query_check
query_goods:
	lda	#QUEST_GOODS
	jmp	query_check
query_kill:
	lda	man_daode
	bmi	good_man
	lda	#QUEST_KILL
query_check:
	sta	quest_type
	jsr	judge_reward
	bcs	query_check_rts
	jsr	test_player
	jsr	check_player
query_check_rts:
	rts
query_ghost:
	lda	man_daode
	bpl	bad_man
	lda	#QUEST_GHOST
	sta	quest_type
	jsr	work_me
	bcs	$+5
	jsr	start_job
	rts
good_man:
	lm2	string_ptr,#good_man_msg
	jmp	show_talk_msg
bad_man:
	lm2	string_ptr,#bad_man_msg
	jmp	show_talk_msg

;*************************************
;	判断是否有任务已经完成
;	遍历quest_temp,比较id是否等于0ffh
;	input	: 
;	output  : cy = 1(find)
;	destroy	: 
;*************************************
judge_reward:
	lm	task_temp1,#0
judge_reward_loop:
	lda	task_temp1
	ldx	#TEMP_SIZE
	jsr	mul_ax
	clc
	adc	#QUEST_ID_OFF
	tay
	lda	quest_temp,y
	cmp	#HAS_REWARD
	beq	find_reward
	inc	task_temp1
	cmp1	task_temp1,#QUEST_KILL
	bcc	judge_reward_loop
	beq	judge_reward_loop
	clc
	rts
find_reward:
	lm2	string_ptr,#quest_reward_msg
	jsr	show_talk_msg
	sec	
	rts

;*************************************
;	检查TEMP数组中的id
;	input:quest_type
;*************************************
test_player:
	lda	quest_type
	jsr	find_quest_id
	sty	task_temp1		;save y
	sta	quest_id
	beq	test_player_rts		;无任务
	lda	quest_type
	cmp	#QUEST_NPC
	beq	test_player_rts		;寻人任务
	cmp	#QUEST_KILL
	beq	test_player_rts		;杀人任务
	lda	quest_id
	jsr	find_goods		;寻物任务
	bcc	test_player_rts
	jsr	query_if_give
test_player_rts:
	rts
	
;*************************************
;	检查玩家的任务数据
;	判断任务是否存在,有的话要判断是否完成
;	没有则给一个任务
;	input: Areg
;*************************************
check_player:
	lm2	string_ptr,#quest_done_msg
	lda	quest_id
	beq	get_task
	cmp	#QUEST_OVER		;id = 0ffh 表示任务完成
	beq	task_is_done
	jsr	get_exist_msg
	jmp	show_talk_msg
task_is_done:
	lda	quest_type
	jsr	find_quest_id
	lda	#HAS_REWARD
	sta	quest_temp,y
	;把当前时间写入任务数组
	lda	mud_age			;pyh	9-4
	sta	quest_temp+1,y
	lda	mud_age+1
	sta	quest_temp+2,y
	lda	mud_age+2
	sta	quest_temp+3,y
	lda	mud_age+3
	sta	quest_temp+4,y
	jsr	show_talk_msg
	rts
get_task:
	lda	quest_type
	asl	a
	tay
	lda	quest_tbl,y
	sta	a1
	iny
	lda	quest_tbl,y
	sta	a1h		;a1中存放的是地址指针
	jsr	jmp_prog
	lm2	a9,a1		;a1中存放的是地址指针
	jsr	quest_accurate_index
	lda	quest_index
	bmi	no_npc
	sta	range
	lm	range+1,#0
	jsr	random_it
	sta	quest_index
	jsr	get_quest_data
	jsr	cal_delay
	jsr	cal_reward
	jsr	set_task_temp
	lda	quest_type
	jsr	get_new_msg
	jsr	show_talk_msg
	rts
jmp_prog:
	jmp	(a1)
no_npc:
	lm2	string_ptr,#no_npc_msg
	jmp	show_talk_msg
	
;*************************************
;	把id设为0ffh,供外界调用
;	input	: Areg
;	output	: Yreg
;*************************************
set_quest_over:
	ldx	#TEMP_SIZE
	jsr	mul_ax
	clc
	adc	#QUEST_ID_OFF
	tay
	lda	#QUEST_OVER
	sta	quest_temp,y
	rts	
;*************************************
;	得到任务的id,供外界调用
;	input	: Areg
;	output	: Areg(id) , Yreg,
;*************************************
find_quest_id:
	ldx	#TEMP_SIZE
	jsr	mul_ax
	clc
	adc	#QUEST_ID_OFF
	tay
	lda	quest_temp,y
	rts	
;-----------------------------------------
;	询问是否把物品给对方,给的话把id改成0ffh
;	以表示完成,不给则返回
;	input	: Yreg(quest_id position)
;-----------------------------------------
query_if_give:
	lm2	string_ptr,#if_give_msg
	jsr	format_string
	lm	x0,#6
	lm	y0,#0
	lm	x1,#6+12*12
	lm	y1,#26
	jsr	message_box_for_pyh
	bcs	if_give_rts

	lda	quest_id
	jsr	find_goods
	dec	man_goods+1,x
	ldy	task_temp1
	lda	#QUEST_OVER
	sta	quest_temp,y
	sta	quest_id
if_give_rts:
	rts
;-----------------------------------------
;	任务的数据结构
;	struct{
;		quest_exp;	(4bytes)
;		quest_id;	(1bytes)
;	}quest_data;
;
;	input	: task_tbl,task_number, 
;		  a1(quest_data_addr)
;	output	: quest_index	(1bytes)
;	注意	: a9不能被破坏
;
;	func	: 根据经验值判断所能接受任务的最大值
;-----------------------------------------
quest_accurate_index:
	lm	quest_index,#0
	ldy	#0
	lda	(a1),y
	sta	quest_numbers		;第一个字节存放任务的数目
	beq	quest_index_rts
	iny
contine_cmp_exp:
	inc	quest_index
	cmp1	quest_index,quest_numbers
	beq	quest_index_rts
	lda	(a1),y
	sta	task_temp1
	iny	
	lda	(a1),y
	sta	task_temp1+1
	iny	
	lda	(a1),y
	sta	task_temp2
	iny	
	lda	(a1),y
	sta	task_temp2+1
	iny
	iny
	cmp4	man_exp,task_temp1
	bcs	contine_cmp_exp
	beq	quest_index_rts2
quest_index_rts:
	dec	quest_index
quest_index_rts2:
	rts

;-----------------------------------------
;	delay = MAXDELAY * i / sizeof(quest_keys) 
;        	+ DELAY_CONST + uptime()
;	input	: quest_index, quest_numbers
;	output	: quest_delay (4bytes)单位:秒
;-----------------------------------------
cal_delay:
	if	0
	lda	#MAXDELAY
	ldx	quest_index
	jsr	mul_ax
	lm2	a2,quest_numbers
	jsr	divid2
	lda	#DELAY_CONST
	adda2	a1
	add42	mud_age,a1,quest_delay
	endif
	rts

;-----------------------------------------
;	得到任务的数据
;	input	: quest_type, quest_index
;		: a1(quest_data_head)
;	output	: quest_exp, quest_id
;-----------------------------------------
get_quest_data:
	inc2	a9		;跳过第一个字节
	lda	quest_index
	ldx	#QUEST_DATA_SIZE
	jsr	mul_ax
	add	a9,a1
	ldy	#0
	lda	(a9),y
	sta	quest_exp
	iny
	lda	(a9),y
	sta	quest_exp+1
	iny
	lda	(a9),y
	sta	quest_exp+2
	iny
	lda	(a9),y
	sta	quest_exp+3
	iny
	lda	(a9),y
	sta	quest_id
	rts
;-----------------------------------------
;	struct{
;		int index;		(1bytes)
;		long daoxing;		(4bytes)
;		int id;			(1bytes)
;		long time;		(4bytes)
;		int reward;		(2bytes)
;	}quest_temp;
;	每个任务需要12bytes,共需 12 * 3 = 36(bytes)
;	根据quest_type定位到相应位置,然后把数据逐一写入
;	input	: quest_type, quest_index, quest_addr
;		  quest_temp
;-----------------------------------------
set_task_temp:
	lda	quest_type
	ldx	#TEMP_SIZE
	jsr	mul_ax
	tay
	;index
	lda	quest_index
	sta	quest_temp,y
	iny
	;quest_exp
	lda	quest_exp
	sta	quest_temp,y
	iny
	lda	quest_exp+1
	sta	quest_temp,y
	iny
	lda	quest_exp+2
	sta	quest_temp,y
	iny
	lda	quest_exp+3
	sta	quest_temp,y
	iny
	lda	quest_id
	sta	quest_temp,y
	iny
	;quest_delay
	lda	quest_delay
	sta	quest_temp,y
	iny
	lda	quest_delay+1
	sta	quest_temp,y
	iny
	lda	quest_delay+2
	sta	quest_temp,y
	iny
	lda	quest_delay+3
	sta	quest_temp,y
	iny
	lda	quest_reward
	sta	quest_temp,y
	iny
	lda	quest_reward+1
	sta	quest_temp,y
	iny
	rts
;-----------------------------------------
;	计算奖励
;	input	: quest_index, quest_numbers, man_exp, quest_exp
;	output	: quest_reward
;-----------------------------------------
cal_reward:
	;reward += MAXREWARD*(1+index)/sizeof(quests)
	ldx	quest_index
	inx
	lda	#MAXREWARD
	jsr	mul_ax
	lm2	a2,quest_numbers
	jsr	divid2
	lm2	quest_reward,a1
	;reward = reward*(1+log10(exp/10000))*exp/(exp+dx)*dx/(exp+dx)
	lm2	a1,man_exp
	lm2	a2,man_exp+2
	lm2	a3,#10000
	jsr	divid42
	lda	a1
	jsr	log10
	iny
	sty	a1			
	lm	a1h,#0			;now a1 <= 3
	lm2	a2,quest_reward		;now (a2 = man_reward) < 800
	jsr	mul2
	lm2	quest_reward,a1
	;exp+dx
	lda	man_exp
	clc
	adc	quest_exp
	sta	task_temp1
	lda	man_exp+1
	adc	quest_exp+1
	sta	task_temp1+1
	lda	man_exp+2
	adc	quest_exp+2
	sta	task_temp2
	lda	man_exp+3
	adc	quest_exp+3
	sta	task_temp2+1
	;reward*exp/(exp+dx)
	lm2	a1,man_exp
	lm2	a2,man_exp+2
	lm2	a3,quest_reward
	lm2	a4,#0
	jsr	mul4
	lm2	a3,task_temp1
	lm2	a4,task_temp2
	jsr	divid4
	lm2	quest_reward,a1
	;reward*dx/(exp+dx)
	lm2	a1,quest_exp
	lm2	a2,quest_exp+2
	lm2	a3,quest_reward
	lm2	a4,#0
	jsr	mul4
	lm2	a3,task_temp1
	lm2	a4,task_temp2
	jsr	divid4
	lm2	quest_reward,a1
	;reward += random(who->query_int())+random(who->query_kar());
	lm21	range,man_kar
	jsr	random_it
	sta	task_temp1
	lm21	range,man_int
	jsr	random_it
	clc
	adc	task_temp1
	adda2	quest_reward
	cmp2	quest_reward,#MAXREWARD
	bcc	quest_reward_rts
	lm2	quest_reward,#MAXREWARD
	lda	task_temp1
	adda2	quest_reward
quest_reward_rts:
	rts
;________________________________________
;	求10的几次方
;	input 	: Areg
;	output	: Yreg
;	destroy	: a1, a2 
;________________________________________
log10:
	ldy	#0
log10_loop:
	ldx	#10
	jsr	divid_ax
	beq	log10_rts	
	iny
	jmp	log10_loop
log10_rts:
	rts

;-----------------------------------------
;	input	: quest_type, quest_id
;	ouput	: string_ptr
;-----------------------------------------
get_exist_msg:
	
	lm2	a1,#exist_msg_tbl
	jmp	get_msg
get_new_msg:
	lm2	a1,#new_msg_tbl
get_msg:
	lda	quest_type
	asl	a
	tay
	lda	(a1),y
	sta	string_ptr
	iny
	lda	(a1),y
	sta	string_ptr+1
	jsr	format_string
	rts

;杀妖mieyao
;*****************************************************
;	struct{
;		int C;		//系数
;		int name;	//妖怪的名字(4bytes)
;		int ghost_id;
;		long time_start1;//(4bytes)
;		int bonus;	//(2bytes)
;	}			//共12个字节
;			
;	input	: none
;	output	: cy=0 (suc) cy=1 (fail)
;	
;*****************************************************
work_me:
	lda	#QUEST_GHOST
	jsr	find_quest_id		;output : y(id_position)
	bne	not_first_kill
first_kill:
	;it is first time
	lm	ghost_level,#1
	jsr	create_ghost
	clc
	rts
not_first_kill:
	;Yreg must not be changed,it need test!
	lda	quest_temp+1,y			;quest_time(4bytes)
	sta	task_temp2
	lda	quest_temp+2,y
	sta	task_temp2+1
	lda	quest_temp+3,y
	sta	task_temp3
	lda	quest_temp+4,y
	sta	task_temp3+1
	
	lda	quest_temp,y			;quest_id
	cmp	#QUEST_OVER
	jeq	kill_has_done
kill_not_done:
	lm2	a1,#WAIT_LIMIT
	add42	task_temp2,a1
	cmp4	mud_age,task_temp2
	bcs	kill_failed
	;get ghost_name addr
	
	lda	quest_temp-4,y
	sta	task_temp1
	lda	quest_temp-3,y
	sta	task_temp1+1
	lda	quest_temp-2,y
	sta	task_temp2
	lda	quest_temp-1,y
	sta	task_temp2+1
	lm2	task_temp3,#0		;作为结束标志
not_kill_ghost:
	lm2	string_ptr,#gnot_done_msg
	jsr	format_string
	jsr	show_talk_msg
	sec
	rts
kill_failed:
	;failed, decrease 1 lvl
	;失败的话要销毁killer
	rmb7	G_Task_Flag

	lda	quest_temp-5,y
	cmp	#2
	bcs	great_than_1
	lda	#1
	bne	$+4
great_than_1:
	sbc	#1
	sta	ghost_level
	jsr	create_ghost
	clc
	rts
kill_has_done:
	;cmp4	task_temp2,mud_age
	;bgt	get_new_ghost
	lm2	a1,#DONE_LIMIT
	add42	task_temp2,a1
	cmp4	mud_age,task_temp2
	bgt	get_new_ghost
	lm2	string_ptr,#time_limit_msg
	jsr	show_talk_msg
	sec
	rts
get_new_ghost:
	lda	quest_temp-5,y
	cmp	#10
	bcs	another_loop
	clc
	adc	#1
	bne	$+4
another_loop:
	lda	#2
	sta	ghost_level
	jsr	create_ghost
	clc
	rts
;********************************************
;
;	在随机地点产生一个NPC,并显示相应信息
;
;********************************************
start_job:
	smb7	G_Task_Flag
	jsr	random_map

	lm2	a9,#G_img_buf
	lm2	quest_exp+4,#0		;作为字符串结束标志
	lm2	string_ptr,#kill_NPC_msg
	jsr	format_string
	jmp	show_talk_msg

;============================================
;
;	input: ghost_level, man_fight_status
;	output: ghost_status
;
;============================================
create_ghost:
	lm	quest_index,ghost_level
	lm	quest_id,#KILLER_NPC
	lm2	range,#GHOST_NUM
	jsr	random_it
	asl	a
	tay
	lda	name_xing_tbl,y
	sta	quest_exp
	lda	name_xing_tbl+1,y
	sta	quest_exp+1
	lm	range,#GHOST_NUM
	lm	range+1,#0
	sta	ghost_gender_bak
	jsr	random_it
	cmp	#4
	bcc	create_1
	inc	ghost_gender_bak
create_1:	
	asl	a
	tay
	lda	name_ming_tbl,y
	sta	quest_exp+2
	lda	name_ming_tbl+1,y
	sta	quest_exp+3

	lm2	range,#GHOST_BONUS
	jsr	random_it
	lm2	a2,#GHOST_BONUS
	add	a1,a2
	lm21	a2,ghost_level
	jsr	mul2
	lm2	quest_reward,a1

	lm2	quest_delay,mud_age
	lm2	quest_delay+2,mud_age+2
	jsr	set_task_temp
	rts

;***********************************************************
;
;	根据quest_index生成GHOST的数据,然后move进npc_status
;	判断是否是ghost,不是则返回,是的要判断和上次访问的NPC
;	id是否相同,是的话返回.
;	
;***********************************************************
init_ghost:
	bit	G_Task_Flag
	bpl	init_ghost_rts
	cmp1	located_id,#KILLER_NPC
	beq	init_ghost1
init_ghost_rts:
	clc
	rts
init_ghost1:	
	jsr	copy_status
	sec
	rts
;==============================================================
;
;	copy玩家的数据,经过折算后存入ghost_state,一些数据要自己
;	生成,如性别,门派,所用的功夫等
;
;==============================================================
copy_status:
	move	man_attack,ghost_attack,#GHOST_DATE_LEN
	move	attr_str,ghost_str,#6

	lda	#QUEST_GHOST
	jsr	find_quest_id
	sty	task_temp1
	lda	quest_temp-5,y
	tay
	dey
	lda	ghost_index_tbl,y
	sta	ghost_level			;复用作为系数因子
	;ghost_name
	ldy	task_temp1
	lda	quest_temp-4,y
	sta	ghost_name
	lda	quest_temp-3,y
	sta	ghost_name+1
	lda	quest_temp-2,y
	sta	ghost_name+2
	lda	quest_temp-1,y
	sta	ghost_name+3
	lm2	ghost_name+4,#0

	lm21	range,#6
	jsr	random_it
	sta	ghost_pai
	inc	ghost_pai
	lm	ghost_age,#GHOST_AGE
	;开始折算
	;需要折算的有exp,hp,fp,
	lm2	a1,man_exp
	lm2	a2,man_exp+2
	lm21	a3,ghost_level
	lm2	a4,#0
	jsr	mul4
	lm2	a3,#100
	jsr	divid42
	lm2	ghost_exp,a1
	lm2	ghost_exp+2,a2
	lm2	a1,man_maxhp
	lm21	a2,ghost_level
	jsr	mul2
	lm2	a3,#100
	jsr	divid42
	lm2	ghost_maxhp,a1
	lm2	ghost_effhp,a1
	lm2	ghost_hp,a1
	lm2	a1,man_maxfp
	lm21	a2,ghost_level
	jsr	mul2
	lm2	a3,#100
	jsr	divid42
	lm2	ghost_maxfp,a1
	lm2	ghost_fp,a1
	;遍历man_kf,找出最高等级来
	lm	task_temp1,#0
	lm2	a1,#man_kf
	ldy	#1
	ldx	#0
higtest_level_loop:
	cpx	man_kfnum
	bcs	find_high_over
	lda	(a1),y
	cmp	task_temp1
	bcc	$+5
	sta	task_temp1
	iny
	iny
	iny
	iny
	inx
	bne	higtest_level_loop
find_high_over:
	;将等级进行折算
	lda	ghost_level
	ldx	task_temp1
	jsr	mul_ax
	lm2	a2,#100
	jsr	divid2
	lm	ghost_level,a1
	;确定ghost用什么功夫
	jsr	set_ghost_kf

	move	ghost_name,npc_name,#NPC_DATA_LEN
	move	ghost_usekf,npc_usekf,#MAX_USEKF
	move	ghost_kfnum,npc_kfnum,#2*MAX_KF+1
	move	#0,npc_equip,#NPC_GOODS-1
	lm2	npc_money,#10
	lm	npc_desc,#0
	sta	npc_daode
	lm	npc_gender,ghost_gender_bak

	lm2	a1,npc_maxfp
	lm2	a2,#40
	jsr	divid2
	lm2	npc_force,a1
	rts

;---------------------------------------------
;
;	input: ghost_level(kf_level),ghost_pai
;
;---------------------------------------------
set_ghost_kf:
	lda	ghost_pai
	asl	a
	tay
	lda	menpai_tbl,y
	sta	a9
	lda	menpai_tbl+1,y
	sta	a9h
	ldy	#0
set_enable_loop:
	lda	(a9),y
	ora	#80h
	sta	ghost_usekf,y
	iny
	cpy	#5
	bcc	set_enable_loop
	lda	(a9),y
	ora	#80h
	sta	ghost_weapon

	ldx	#0
	ldy	#0
set_basickf_loop:
	tya
	sta	ghost_kf,x		;basic_kf_id
	inx
	lda	ghost_level
	sta	ghost_kf,x
	inx
	iny
	cpy	#BASIC_KF_NUM
	bcc	set_basickf_loop

	ldy	#0
set_sepkf_loop:
	lda	(a9),y
	sta	ghost_kf,x
	inx
	lda	ghost_level
	sta	ghost_kf,x
	inx
	iny
	cpy	#4
	bcc	set_sepkf_loop
	lm	ghost_kfnum,#BASIC_KF_NUM+4
	rts

;******************************************************
;
;	作完第一类任务后给奖励,判断任务完成时间是否超过
;	20分钟,不超过的话,加上这项任务的奖励
;	HAS_REWARD
;
;******************************************************
pyh_task_bonus:
	lm2	quest_reward,#0
	lm2	task_temp1,#0
task_bonus_loop:
	lda	task_temp1
	jsr	find_quest_id
	cmp	#HAS_REWARD
	bne	task_bonus_patch
	lm	task_temp1+1,#0ffh
	lda	#0
	sta	quest_temp,y
task_bonus_patch:
	lda	quest_temp+1,y
	sta	task_temp2
	lda	quest_temp+2,y
	sta	task_temp2+1
	lda	quest_temp+3,y
	sta	task_temp3
	lda	quest_temp+4,y
	sta	task_temp3+1
	lm2	a1,#REWARD_MAXDELAY			;20分钟
	add42	task_temp2,a1
	cmp4	mud_age,task_temp2
	bgt	task_bonus_2
task_bonus_1:
	lda	quest_temp+5,y
	sta	a2
	lda	quest_temp+6,y
	sta	a2h
	add	quest_reward,a2
task_bonus_2:
	inc	task_temp1
	cmp1	task_temp1,#QUEST_GHOST		;#3
	jcc	task_bonus_loop
	lda	task_temp1+1
	bmi	task_bonus_5
	lm2	string_ptr,#no_bonus_msg
	jmp	show_pyh_bonus
task_bonus_5:
	;现在奖励在quest_reward中,需要折算
	lm2	a1,quest_reward
	lm2	a2,#3			;发现奖励有些少,乘以3
	jsr	mul2
	lm2	quest_reward,a1
	lm2	range,#100
	jsr	random_it
	cmp	#70
	bcc	give_exp		;必要可以缩小其范围
give_pot:
	lsr2	quest_reward
	lm2	task_buf+4,quest_reward
	add	man_pot,task_buf+4
	lm2	string_ptr,#get_pot_msg
	jmp	show_pyh_bonus
	if	0
give_silver:
	lsr2	quest_reward
	lm2	task_buf+6,quest_reward
	add42	man_money,task_buf+6
	lm2	string_ptr,#get_silver_msg
	jmp	show_pyh_bonus
	endif
give_exp:
	lm2	task_buf+2,quest_reward
	add42	man_exp,task_buf+2
	lm2	string_ptr,#get_exp_msg
show_pyh_bonus:
	jsr	format_string
	jmp	show_talk_msg
;---------------------------------------------
; input: task_buf
; output: man_state
; task_buf 变量区:
;	byte	type
;	byte	object
;	byte[2]	bonus1	--exp
;	byte[2]	bonus2	--pot
;	byte[2]	bonus3	--money
;---------------------------------------------
show_bonus:
	
	add42	man_exp,task_buf+2
	add	man_pot,task_buf+4

	lm2	string_ptr,#bonus_msg
	jsr	format_string
	Message	#12,#10,#140,#60
	jmp	scroll_to_lcd
;**************************************************
;
;	义工任务,只是设置标志位,然后返回
;	从三种任务,扫地,挑水,劈柴中随机挑选一种任务
;	设好home_buf,然后返回,清home_buf要在子程序中
;	执行
;	input	: home_buf(2bytes)
;	output	: home_buf(2bytes)
;
;**************************************************
voluntary_work:
	lda	man_exp+2
	ora	man_exp+3
	jne	exp_so_high
	cmp2	man_exp,#5000
	jcs	exp_so_high
	lda	home_buf
	bne	task_not_done
	lm2	range,#3
	jsr	random_it
	and	#03h
	sta	home_buf
	inc	home_buf		;1, 2, 3
	asl	a
	asl	a
	tay
	lda	random_task,y
	sta	task_temp1
	lda	random_task+1,y
	sta	task_temp1+1
	lda	random_task+2,y
	sta	task_temp2
	lda	random_task+3,y
	sta	task_temp2+1
	lm2	task_temp3,#0
	lm2	string_ptr,#voluntary_task_msg
show_voluntary_task:
	jsr	format_string
	jmp	show_talk_msg
exp_so_high:
	lm2	string_ptr,#exp_high_msg
	jmp	show_voluntary_task
task_not_done:
	lm2	string_ptr,#have_task_msg
	jmp	show_voluntary_task

;--------------------------------------------------------
quest_npc_tbl:
	lda	#NPC_NUM
	jsr	get_all_npc
	ldx	#5
	ldy	#4
	jsr	inssort
	rts	
quest_goods_tbl:
	jsr	get_all_goods
	ldx	#5
	ldy	#4
	jsr	inssort
	rts

;---------------------------------------------------------------
;	插入排序
;算法如下:
; for (i=1; i<n; i++)
;	for (j=i; (j>0) && (key(array[j])<key(arry[j-1])); j--)
;		swap(array[j], array[j-1])
; input: a1:数组(第一byte为数组大小) Xreg:元素大小 Yreg:key大小
; ouput: a1:排序数组(从小到大)
; destry: a1-a7
;---------------------------------------------------------------
inssort:
	stx	a7
	sty	a7h

	lm	a6,#1	;i
	lm2	a5,a1
	clc
	lda	a7
	adc	#1
	adda2	a5
sort_loop1:
	lda	a6
	ldy	#0
	cmp	(a1),y
	jcs	loop1_rts

	lm	a6h,a6	;j
	lm2	a3,a5
sort_loop2:
	lda	a6h
	beq	loop2_rts

	sub21	a3,a7,a2
	;cmp (key(array[j]),key(array[j-1]))
	ldy	a7h
cmp_next:
	dey
	bmi	cmp_rts
	lda	(a3),y
	cmp	(a2),y
	beq	cmp_next
cmp_rts:
	bcs	loop2_rts

	;swap (array[j],array[j-1])
	ldy	#0
swap_loop:
	lda	(a3),y
	sta	a4
	lda	(a2),y
	sta	(a3),y
	lda	a4
	sta	(a2),y
	iny
	cpy	a7
	bcc	swap_loop

	dec	a6h
	sub21	a3,a7
	jmp	sort_loop2
loop2_rts:
	inc	a6
	lda	a7
	adda2	a5
	jmp	sort_loop1
loop1_rts:
	rts
;*********************************************	data
exist_msg_tbl:
	dw	npc_exist_msg
	dw	goods_exist_msg
	dw	kill_exist_msg
new_msg_tbl:
	dw	npc_new_msg
	dw	goods_new_msg
	dw	kill_new_msg
quest_tbl:
	dw	quest_npc_tbl		;寻人
	dw	quest_goods_tbl		;寻物
	dw	quest_npc_tbl		;杀人
my_street_tbl:
	db	0,1,2,3,4,5,6,0,0,1,2,4,5,6
ghost_index_tbl:
	db	80,85,90,95,100,105,110,115,120,125
menpai_tbl:
	dw	non_pai
	dw	bagua_pai
	dw	flower_pai
	dw	honglian_pai
	dw	naja_pai
	dw	taiji_pai
	dw	xueshan_pai
non_pai:
bagua_pai:
        db	BAGUAZ_KF		;unarmed_kf
        db	BAGUAD_KF		;weapon_kf
        db	YOULONG_KF		;dodge_kf
        db	HUNYUAN_KF		;force_kf
        db	BAGUAD_KF		;parry_kf
	db	BLADE			;use weapon
flower_pai:
        db	MEIHUA_KF
        db	HUATUAN_KF
        db	HUAFEI_KF
        db	SANHUA_KF
        db	HUATUAN_KF
	db	WHIP
honglian_pai:
        db	TAIZU_KF
        db  	PIFENG_KF
        db 	HEXIANG_KF
        db  	TONGJI_KF
        db  	PIFENG_KF
	db	STAFF
naja_pai:
        db	WUFA_KF
        db	YIDAO_KF
        db	WUYING_KF
        db	RENSHU_KF
        db	YIDAO_KF
	db	BLADE
taiji_pai:
        db	TAIJIQ_KF
        db	TAIJIJ_KF
        db	WANLIU_KF
        db	TAIJIG_KF
        db	TAIJIJ_KF
	db	TIE_SWORD
xueshan_pai:
        db	XUEYING_KF
        db	XUESHANJ_KF
        db	TAXUE_KF
        db	XUESHANG_KF
        db	XUESHANJ_KF
	db	TIE_SWORD

;=============================================	msg	
	if	scode
good_man_msg:
	db	'最讨厌伪君子了,马上从我面前消失!',0,0
bad_man_msg:
	db	'你不是通辑犯吗?来人,给我拿下!',0,0
no_npc_msg:
	db	'什么?你把人杀光了?I服了YOU!',0,0
npc_new_msg:
	db	'请速去拜见$q!',0,0
goods_new_msg:
	db	'今天妾身正准备请人去找$q,能否帮个忙?',0,0
kill_new_msg:
	db	'老夫夜观天象,$q阳寿已尽,你去解决他! ',0,0
npc_exist_msg:
	db	'老夫不是说过请去拜见$q吗!',0,0
goods_exist_msg:
	db	'妾身还盼着您的$q呢!',0,0
kill_exist_msg:
	db	'老夫不是让你解决$q吗?',0,0
quest_done_msg:
	db	'你完成了任务,去顾炎武处领赏吧!',0,0
quest_reward_msg:
	db	'看你红光满面,还是先去顾炎武处领赏吧!',0,0
if_give_msg:
	db	'使用$q完成任务吗?',0,0
no_bonus_msg:
	db	'努力吧,干活去吧!',0,0
gnot_done_msg:
	db	'在下不是请你去收服',7
	dw	task_temp1,10
	db	'吗?'
	db	0,0
kill_NPC_msg:
	db	'近有恶人『',7
	dw	quest_exp,10
	db	'』在',8
	dw	a9,10
	db	'为非作歹,请速去为民除害!',0
	db	0,0
bonus_msg:
	db	'你被奖励了：',0
	db	2
	dw	task_buf+2,10
	db	' 点实战经验',0
	db	2
	dw	task_buf+4,10
	db	' 点潜能',0
	db	0
get_pot_msg:
	db	'你被奖励了：',0
	db	2
	dw	task_buf+4,10
	db	' 点潜能',0
	db	0
get_silver_msg:
	db	'你被奖励了金钱：',2
	dw	task_buf+6,0
	db	0
get_exp_msg:
	db	'你被奖励了：',0
	db	2
	dw	task_buf+2,10
	db	' 点实战经验',0
	db	0
time_limit_msg:
	db	'多谢,奸邪暂时已经除尽了,先歇息一下吧!',0,0
name_xing_tbl:
	db	'赵','钱','孙','李','周','吴','郑','王'
name_ming_tbl:
	db	'英','雄','豪','杰','梅','兰','竹','菊'
voluntary_task_msg:
	db	'老身年事已高,有好心人帮帮我『',7
	dw	task_temp1,10
	db	'』吗?',0
	db	0
random_task:
	db	'扫地'
	db	'挑水'
	db	'劈柴'
exp_high_msg:
	db	'唉! 你在江湖上也小有名气了,老身使唤不动你了!',0,0
have_task_msg:
	db	'老身吩咐你的事做完了么?',0,0
	else
good_man_msg:
	db	'程癚菇滂,皑眖и玡ア!',0,0
bad_man_msg:
	db	'ぃ琌硄胯デ盾?ㄓ,倒и!',0,0
no_npc_msg:
	db	'ぐ或?р炳?I狝YOU!',0,0
npc_new_msg:
	db	'叫硉ǎ$q!',0,0
goods_new_msg:
	db	'さぱヽōタ称叫т$q,腊Γ?',0,0
kill_new_msg:
	db	'ρひ芠ぱ禜,$q锭关荷,秆∕! ',0,0
npc_exist_msg:
	db	'ρひぃ琌弧筁叫ǎ$q盾!',0,0
goods_exist_msg:
	db	'ヽō临帝眤$q㎡!',0,0
kill_exist_msg:
	db	'ρひぃ琌琵秆∕$q盾?',0,0
quest_done_msg:
	db	'ЧΘヴ叭,臮猌矪烩洁!',0,0
quest_reward_msg:
	db	'骸,临琌臮猌矪烩洁!',0,0
if_give_msg:
	db	'ㄏノ$qЧΘヴ叭盾?',0,0
no_bonus_msg:
	db	',!',0,0
gnot_done_msg:
	db	'ぃ琌叫Μ狝',7
	dw	task_temp1,10
	db	'盾?'
	db	0,0
kill_NPC_msg:
	db	'Τ碿',7
	dw	quest_exp,10
	db	'',8
	dw	a9,10
	db	'獶わ,叫硉チ埃甡!',0
	db	0,0
bonus_msg:
	db	'砆贱纘',0
	db	2
	dw	task_buf+2,10
	db	' 翴龟驹竒喷',0
	db	2
	dw	task_buf+4,10
	db	' 翴肩',0
	db	0
get_pot_msg:
	db	'砆贱纘',0
	db	2
	dw	task_buf+4,10
	db	' 翴肩',0
	db	0
get_silver_msg:
	db	'砆贱纘窥',2
	dw	task_buf+6,0
	db	0
get_exp_msg:
	db	'砆贱纘',0
	db	2
	dw	task_buf+2,10
	db	' 翴龟驹竒喷',0
	db	0
time_limit_msg:
	db	'谅,ǜ既竒埃荷,凡!',0,0
name_xing_tbl:
	db	'化','窥','甝','','㏄','','綠',''
name_ming_tbl:
	db	'璣','动','花','狽','宾','孽','λ','碘'
voluntary_task_msg:
	db	'ρōㄆ蔼,Τみ腊腊и',7
	dw	task_temp1,10
	db	'盾?',0
	db	0
random_task:
	db	'苯'
	db	'珼'
	db	'糀'
exp_high_msg:
	db	'! 打Τ,ρōㄏ酬ぃ笆!',0,0
have_task_msg:
	db	'ρō㎎ㄆ暗Ч?',0,0
	endif

;*************************************************************

	end

