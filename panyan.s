;;*************************************************
;;	小游戏,用于mud游戏中练功之用
;;
;;	writen by:	pyh	time:	2001.7.3--2001.7.10
;;
;;	参考文档:	~/mud/panyan.doc
;;*************************************************
	include	h/gmud.h
	include	h/id.h
	include	h/mud_funcs.h
	include	h/func.mac
;==============================================		variable 
DODGE_BONUS	equ	3
PARRY_BONUS	equ	10
BALL_Y		equ	30

__base	equ	game_buf
	define	1,game_level
	define	2,top_score
	define	2,arrow	
	define	2,temp_lcd
	define	2,temp_arrow
	define	2,man_img
	define	2,temp_arrow_lcd
	define	2,temp_arrow_img
	define	2,tiaowu_score
	define	1,count
	define	1,cx
	define	2,temp1
	define	1,quit_flag
	define	1,flag
;==============================================		prcedure
FRAME_X0	=	6
FRAME_Y0	=	3

BEGIN1_LCD	equ	lcdbuf+20*7+11	;提示栏箭头的位置
BEGIN2_LCD	equ	lcdbuf+20*7+13
BEGIN3_LCD	equ	lcdbuf+20*7+15
BEGIN4_LCD	equ	lcdbuf+20*7+17

RIGHT_LCD	equ	lcdbuf+20*40+6	;按键箭头的位置
LEFT_LCD	equ	lcdbuf+20*40+2
UP_LCD		equ	lcdbuf+20*24+4
DOWN_LCD	equ	lcdbuf+20*56+4
							;人的位置
MAN_X		equ	13*8
MAN_Y		equ	30

;=============================================
	public	panyan

	extrn	get_player_img
	extrn	message_box_for_pyh
	extrn	show_box
	extrn	random_it
	extrn	wait_key
	extrn	waittime
	extrn	write_one_char
	extrn	write_block0
	extrn	getms

;================================================
panyan:
	;初始化
	lm	quit_flag,#0

	;******
	;显示提示信息
	lm	x0,#FRAME_X0
	lm	y0,#FRAME_Y0
	lm	x1,#FRAME_X0+12*12
	lm	y1,#FRAME_Y0+6*12
	move	hill_msg,bank_text,#hill_msg_len
	lm2	string_ptr,#bank_text
        jsr	message_box_for_pyh
	jcs	proc_quit1

get_kf_data:
	move	select_road_msg,bank_text,#select_road_len
	lm2	string_ptr,#bank_text
	lm	x0,#FRAME_X0
	lm	y0,#FRAME_Y0
	lm	x1,#FRAME_X0+12*12
	lm	y1,#FRAME_Y0+6*12
	jsr	show_box
	jsr	wait_key_loop

	;在选择过程中已经选定了kf_id	
	;取得功夫的数据
	lm	x0,#1
	lm	y0,#1
	lm	x1,#159
	lm	y1,#79
	;jsr	game_box		;恢复lcd时可能出错
	;所有的游戏代码写在此处
	lda	kf_id
	beq	proc_quit1
	cmp	#1
	beq	lian_dodge
	jmp	lian_unarmed

proc_quit:
	ldx	top_score
	ldy	top_score+1
	cmp1	kf_id,#2
	beq	proc_quit2
	stx	top_dance
	sty	top_dance+1
	jmp	proc_quit3
proc_quit2:
	stx	top_ball
	sty	top_ball+1
proc_quit3:
	;用所得的分数计算是否能升级
	jsr	cal_up_level
	;显示功夫升了几级,当前的点数是多少
proc_quit1:
	rts

;===============================================
;退出时计算所得分数可以升几级,kf_id,kf_level,kf_score
cal_up_level:
	rts

;===============================================	
;增加趣味性,采用跳舞机游戏的方法来练功.
lian_dodge:
	lm	game_level,#200
	lm2	tiaowu_score,#0
	jsr	game_box
	lm2	temp_arrow_lcd,#BEGIN1_LCD
	lm2	temp_arrow_img,#uparrow

	;绘制左边的四个箭头
	lm2	a1,#UP_LCD
	lm2	a2,#uparrow
	jsr	show_arrow

	lm2	a1,#RIGHT_LCD
	lm2	a2,#rightarrow
	jsr	show_arrow

	lm2	a1,#LEFT_LCD
	lm2	a2,#leftarrow
	jsr	show_arrow

	lm2	a1,#DOWN_LCD
	lm2	a2,#downarrow
	jsr	show_arrow

	;绘制人的图形
	lda	#0
	jsr	get_player_img
	ldx	#MAN_X
	ldy	#MAN_Y
	jsr	write_block0

wait_for_key:
	;取随机数,同一个随机数不能出现两次
	lm2	range,#4
	jsr	random_it
	cmp	flag
	beq	wait_for_key			;同一个随机数不能出现两次
	sta	flag

	;在信息提示栏不同的位置显示提示信息
	;上箭头
	cmp	#0
	bne	cmp1
	lm2	a3,#BEGIN2_LCD
	bne	a1_32
cmp1:
	;下箭头
	cmp	#1
	bne	cmp2
	lm2	a3,#BEGIN3_LCD
	bne	a1_32
cmp2:
	;右箭头
	cmp	#2
	bne	cmp3
	lm2	a3,#BEGIN4_LCD
	bne	a1_32
cmp3:
	;左箭头
	lm2	a3,#BEGIN1_LCD		

a1_32:
	;擦掉原来的提示箭头,解决刷新的问题
	lm2	a4,a1		;save
	jsr	erase_arrow	
	lm2	a1,a4		;restore

	;a1中存放着随机数,以uparrow作为头地址,以随机数作为索引
	lm2	a2,#uparrow
	lda	a1
	;所得随机数*64,每个箭头图形有64个字节
	rept 	5		
	asl	a
	endr
	adda2	a2

	;将显示的位置(a3)送给a1
	lm2	a1,a3
	;暂存a1,a2,为了以后擦除用
	lm2	temp_arrow_lcd,a1	;为了erase_arrow用
	lm2	temp_arrow_img,a2	;	*
	
	;显示提示箭头,
	jsr	flash_arrow

	;延时1秒后直接读取键值,如无方向键按下,显示下一个提示信息	
	;如有相应的键按下,转入相应的子程序,然后返回,继续显示提示
	;信息
	lm	key,#0
	ldx	game_level
	jsr	delay
	lda	key
	and	#7fh
	SWITCH	#game_cmd_len,game_cmd
test_wait_key:
	lda	quit_flag
	cmp	#0ffh
	jne	wait_for_key
	lm	key,#0
	jmp	proc_quit
game_cmd:
	db	ESC_KEY
	db	LEFT_KEY
	db	RIGHT_KEY
	db	UP_KEY
	db	DOWN_KEY
game_cmd_len	equ	$-game_cmd
	dw	proc_esc
	dw	proc_left
	dw	proc_right
	dw	proc_up
	dw	proc_down
proc_esc:
	lm	quit_flag,#0ffh
	rts

	;按下左键后的子程序
proc_left:
	;检查按下的键同提示键是否一样,如一样,则加分并显示
	lm2	temp_arrow,#leftarrow
	jsr	check_score	;pyh	7-5
	lm2	a1,#LEFT_LCD
	lm2	a2,#leftarrow
	lm2	temp_lcd,#LEFT_LCD

	;右提示栏内的右箭头闪烁
	jsr	flash_arrow

	;小人要向左移,先擦除中间的小人,然后在左边位置处显示小人,延时
	;后擦掉左边的小人,恢复中间的小人
	;*******
	lda	#4
	jsr	get_player_img
	;******
	ldx	#MAN_X
	ldy	#MAN_Y
	jsr	write_block0
	;延时
	rept	2
	jsr	delay_160_ms
	endr
	;恢复中间的小人,恢复又提示栏内的箭头
	jsr	refresh_arrow
	rts

proc_right:
	lm2	temp_arrow,#rightarrow
	jsr	check_score
	lm2	a1,#RIGHT_LCD
	lm2	a2,#rightarrow
	lm2	temp_lcd,#RIGHT_LCD
	jsr	flash_arrow

	;*******
	lda	#7
	jsr	get_player_img
	;******
	ldx	#MAN_X
	ldy	#MAN_Y
	jsr	write_block0

	rept	2
	jsr	delay_160_ms
	endr
	jsr	refresh_arrow
	rts

	;这个程序打了一个补丁,因为它影响到取随机数
proc_up:
	;因为调用check_score后随机数不变
	;估计是破坏了变量random,因此保存之
					
	lm2	temp_arrow,#uparrow
	jsr	check_score		;随机数总是不变
	lm2	a1,#UP_LCD
	lm2	a2,#uparrow
	lm2	temp_lcd,#UP_LCD

	jsr	flash_arrow

	lda	#9
	jsr	get_player_img
	ldx	#MAN_X
	ldy	#MAN_Y
	jsr	write_block0

	rept	2
	jsr	delay_160_ms
	endr
	jsr	refresh_arrow
	rts
proc_down:

	lm2	temp_arrow,#downarrow
	jsr	check_score
	lm2	a1,#DOWN_LCD
	lm2	a2,#downarrow
	lm2	temp_lcd,#DOWN_LCD
	jsr	flash_arrow

	;*******
	lda	#0
	jsr	get_player_img
	;******
	ldx	#MAN_X
	ldy	#MAN_Y
	jsr	write_block0

	rept	2
	jsr	delay_160_ms
	endr
	jsr	refresh_arrow
	rts

;***************************************************************
;练习基本拳脚的投篮小游戏
lian_unarmed:
	;初始化
	lm	game_level,#7
	lm	quit_flag,#0
	lm2	tiaowu_score,#0
basket_wait_key:
	;绘制游戏界面
	jsr	draw_basket_box
	;读键
	jsr	wait_key
	SWITCH	#basket_cmd_len,basket_cmd
	lda	quit_flag
	cmp	#0ffh
	bne	basket_wait_key
	jmp	proc_quit

basket_cmd:
	db	ESC_KEY
	db	CR_KEY
basket_cmd_len	equ	$-basket_cmd
	dw	proc_basket_esc
	dw	proc_basket_f1
	;按下ESC键后的子程序
proc_basket_esc:
	lm	quit_flag,#0ffh
	rts
	;按下F1键后的子程序,第一次按下,小球开始运动,第二次按下,小球停止
proc_basket_f1:
	;判断是移动还是停止
	;转相应子程序	move_bakset,stop_basket
	;设标志位temp_lcd,1表示移动,0表示停止
	jsr	move_basket

	;move_bakset返回小球停止后的横坐标,以此作为判断的依据
	;存此时的坐标,擦除时用(for erase_basket)
	lm	man_img,arrow
	lm	man_img+1,arrow+1

	;比较小球的横坐标,(25,31)
	lda	arrow
	cmp	#26
	bcs	$+8
	jsr	little_target
	jmp	proc_basket_f11
	cmp	#29
	bcc	$+8
	jsr	little_target
	jmp	proc_basket_f11
	;擦掉地上的小球
	lm	arrow,#60
	lm	arrow+1,#69
	jsr	erase_basket

	lm2	a8,#target_route
	jsr	shoot_target
	lda	#PARRY_BONUS
	adda2	tiaowu_score
	;擦除方框内的小球
proc_basket_f11:
	lm	arrow,man_img
	lm	arrow+1,man_img+1
	jsr	erase_basket
	;一个补丁,因为最后一次调用WriteBlock后总要出现一个方框,所以把
	;这个方框显示在特定的位置,这样美观一些
	lm	arrow,#127
	lm	arrow+1,#38
	jsr	erase_basket
	lm	key,#0
	rts

;==============================================================
;方框内的小球移动-停止的子程序,是程序的核心部分
;功能:按下F1键后,小球在水平框内水平移动.
;再次按下F1键,小球延时后停止.
move_basket:
	;在水平框中显示小球,小球的坐标是(27,16)
	lm	key,#0
	lm	arrow,#27		;(27,16)水平框中小球的坐标
	lm	arrow+1,#BALL_Y

	;左移的子程序
move_basket_2:
	;判断小球的坐标,如果到了左边框,要向回弹
	cmp1	arrow,#12		;(10,50),小球6x6
	;横坐标要右移
	bcc	move_basket_3		

	jsr	erase_basket
	;横坐标左移
	dec	arrow		
	lm2	a1,#basket_ball
	jsr	WriteBlock

	jsr	random_delay
	;jsr	delay_40_ms
	lda	key			
	and	#7fh	
	cmp	#CR_KEY
	bne	move_basket_6
	jmp	stop_basket		;按下了F1键,应该停止,由stop_basket
					;中的rts返回
move_basket_6:
	;jsr	erase_basket		;第一次显示时不对,要放在前面
	jmp	move_basket_2
	
	;右移的子程序
move_basket_3:
	cmp1	arrow,#44
	bcs	move_basket_2
	jsr	erase_basket
	inc	arrow
	lm2	a1,#basket_ball
	jsr	WriteBlock

	jsr	random_delay
	;jsr	delay_40_ms
	lda	key			
	and	#7fh	
	cmp	#CR_KEY
	bne	move_basket_7
	jmp	stop_basket		;按下了F1键,应该停止,由stop_basket
					;返回
move_basket_7:
	;jsr	erase_basket
	jmp	move_basket_3
move_basket_4:
	rts
;===============================================================
;取随机数延时,使小球时会时慢
random_delay:
	lm2	range,#4
	jsr	random_it
	cmp	#0
	bne	$+8
	ldx	#5
	jsr	delay
	rts
	cmp	#1
	bne	$+6
	jsr	delay_160_ms
	rts
	cmp	#2
	bne	$+8
	ldx	#20
	jsr	delay
	rts
	jsr	delay_160_ms
	rts
;===============================================================
stop_basket:
	sta	key
	lda	arrow			;得到此时的x坐标
	rts
;===============================================================
;如果小球停止后坐标在相应的范围内,则显示一段动画
;入口:a8(坐标表的首地址)
shoot_target:				;pyh	7-7
	ldy	#0
	lda	(a8),y
	sta	count
	sty	temp1
shoot_target_1:
	ldy	temp1
	iny
	lda	(a8),y
	sta	arrow
	sta	temp_arrow

	iny
	lda	(a8),y
	sta	arrow+1
	sta	temp_arrow+1
	sty	temp1

	lm2	a1,#basket_ball
	jsr	WriteBlock
	;jsr	delay_160_ms
	ldx	#10
	jsr	delay
	lm	arrow,temp_arrow
	lm	arrow+1,temp_arrow+1
	jsr	erase_basket

	dbne	count,shoot_target_1	
	lm	key,#0			;应该清掉F1键
	rts
;==============================================================
little_target:
	ldx	#240
	jsr	delay
	dec	game_level
	beq	$+3
	rts
	pla
	pla
	jmp	proc_basket_esc
;===============================================================
;画游戏场景
draw_basket_box:
	lm	lcmd,#0
	BREAK_FUN	_Bblock_draw
	lm	lcmd,#1
	BREAK_FUN	_Bsqure_draw

	jsr	draw_lankuang

	;画持球站立的小人
	;*******
	lda	#8
	jsr	get_player_img
	lm	img_buf+1,#32
	;******
	ldx	#30
	ldy	#43
	jsr	write_block0
	jsr	disp_score		;显示'score'
	jsr	show_score		;显示分数

	lm	x0,#20			;最下方的的长横线
	lm	x1,#155
	lm	y0,#75
	sta	y1
	BREAK_FUN	_Bline_draw

	;画水平框
	lm	x0,#10
	lm	y0,#BALL_Y-1
	lm	x1,#50
	lm	y1,#BALL_Y+6
	BREAK_FUN	_Bsqure_draw

	;画方框上的标记
	lm	x0,#27			;(27,32)区间
	sta	x1
	lm	y0,#BALL_Y+6
	lm	y1,#BALL_Y+7
	BREAK_FUN	_Bline_draw

	lm	x0,#32
	sta	x1
	lm	y0,#BALL_Y+6
	lm	y1,#BALL_Y+7
	BREAK_FUN	_Bline_draw

	;在人的前面放一个小球
	lm2	a1,#basket_ball
	lm	arrow,#60
	lm	arrow+1,#69
	jsr	WriteBlock

	;在水平框的中间放一个小球
	lm2	a1,#basket_ball
	lm	arrow,#27
	lm	arrow+1,#BALL_Y
	jsr	WriteBlock
	rts

;========================================================
draw_lankuang:
	;画篮球框
	lm	x0,#150			;   	|
	sta	x1			;	|
	lm	y0,#25			;	|
	lm	y1,#75			;	|
	BREAK_FUN	_Bline_draw		;	|
	
	lm	x0,#135			;-------
	lm	x1,#150			
	lm	y0,#27
	sta	y1
	BREAK_FUN	_Bline_draw

	lm	x0,#135			
	lm	x1,#150			
	lm	y0,#40
	sta	y1
	BREAK_FUN	_Bline_draw		;-------

	lm	x0,#135			;|
	sta	x1			;|
	lm	y0,#20			;|
	lm	y1,#45
	BREAK_FUN	_Bline_draw		

	lm	x0,#125			
	lm	x1,#135			
	lm	y0,#38
	sta	y1
	BREAK_FUN	_Bline_draw		;---

	lm	x0,#127			;|
	sta	x1			
	lm	y0,#38			
	lm	y1,#44
	BREAK_FUN	_Bline_draw		

	lm	x0,#132			;   |
	sta	x1			
	lm	y0,#38			
	lm	y1,#44
	BREAK_FUN	_Bline_draw		

	lm	x0,#127
	lm	x1,#132
	lm	y0,#43
	sta	y1
	BREAK_FUN	_Bline_draw		;--
	rts
;======================================================
;画图形用的子程序
WriteBlock:
	ldx	arrow
	ldy	arrow+1
	lm2	fccode,a1
	BREAK_FUN	_Bwrite_block
	rts
;==========================================================
;擦图形用的子程序
erase_basket:
	ldx	arrow
	ldy	arrow+1
	lm2	fccode,#basket_blank
	BREAK_FUN	_Bwrite_block
	rts
;========================================================
	;篮球的点阵(6x6)
basket_ball:
	if	0
	db	8,8
	db	00111100b
	db	01000010b
	db	10100101b
	db	10011001b
	db	10011001b
	db	10100101b
	db	01000010b
	db	00111100b
	endif
	db	6,6
	db	00110000b
	db	01001000b
	db	10110100b
	db	10110100b
	db	01001000b
	db	00110000b
	;对应于篮球的空白点阵,用于erase
basket_blank:
	db	6,6
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b

	;一条抛物线线上的坐标,共100个点
target_route:				;投篮进筐的篮球坐标(x,y)
	;画面细致的话要100个点
	db	83
	db	60,60
	db	61,58
	db	62,56
	db	63,54
	db	64,52
	db	65,50
	db	66,48
	db	67,47
	db	68,46
	db	69,44
	db	70,42	
	db	71,41
	db	72,40
	db	73,39
	db	74,38
	db	75,37
	db	76,36
	db	77,35
	db	78,34
	db	79,33
	db	80,32
	db	81,32
	db	82,31
	db	83,30
	db	84,29
	db	85,29
	db	86,28
	db	87,27
	db	88,27
	db	89,26
	db	90,25
	db	91,25
	db	92,24
	db	93,24
	db	94,23
	db	95,23
	db	96,22
	db	97,22
	db	97,21
	db	98,21
	db	99,21
	db	100,21
	db	101,20
	db	102,20
	db	103,20
	db	104,20
	db	105,20
	db	106,20
	db	107,21
	db	108,21
	db	109,21
	db	110,22
	db	111,22
	db	112,23
	db	113,23
	db	114,24
	db	115,25
	db	116,26
	db	117,27
	db	118,28
	db	127,46
	db	127,47
	db	127,48
	db	127,49
	db	127,50
	db	127,51
	db	127,52
	db	127,53
	db	127,54
	db	127,55
	db	127,56
	db	127,57
	db	127,58
	db	127,59
	db	127,60
	db	127,61
	db	127,62
	db	127,63
	db	127,64
	db	127,65
	db	127,66
	db	127,67
	db	127,68
;*****************************************************************
;练习基本内功的小游戏,可以不做
lian_force:
	rts
;================================================	img
	;跳舞机上各个箭头的点阵(16x16)
	;上箭头
uparrow:
	db	00000000b,00000000b
	db	00000001b,10000000b
	db	00000010b,01000000b
	db	00000100b,00100000b
	db	00001000b,00010000b
	db	00010000b,00001000b
	db	00100000b,00000100b
	db	01111000b,00011110b
	db	00001000b,00010000b
	db	00001000b,00010000b
	db	00001000b,00010000b
	db	00001000b,00010000b
	db	00001000b,00010000b
	db	00001000b,00010000b
	db	00001111b,11110000b
	db	00000000b,00000000b

	;下箭头
downarrow:
	db	00000000b,00000000b
	db	00001111b,11110000b
	db	00001000b,00010000b
	db	00001000b,00010000b
	db	00001000b,00010000b
	db	00001000b,00010000b
	db	00001000b,00010000b
	db	00001000b,00010000b
	db	01111000b,00011110b
	db	00100000b,00000100b
	db	00010000b,00001000b
	db	00001000b,00010000b
	db	00000100b,00100000b
	db	00000010b,01000000b
	db	00000001b,10000000b
	db	00000000b,00000000b

	;左箭头
rightarrow:
	db	00000000b,00000000b
	db	00000000b,10000000b
	db	00000000b,11000000b
	db	00000000b,10100000b
	db	01111111b,10010000b
	db	01000000b,00001000b
	db	01000000b,00000100b
	db	01000000b,00000010b
	db	01000000b,00000010b
	db	01000000b,00000100b
	db	01000000b,00001000b
	db	01111111b,10010000b
	db	00000000b,10100000b
	db	00000000b,11000000b
	db	00000000b,10000000b
	db	00000000b,00000000b

	;右箭头
leftarrow:
	db	00000000b,00000000b
	db	00000001b,00000000b
	db	00000011b,00000000b
	db	00000101b,00000000b
	db	00001001b,11111110b
	db	00010000b,00000010b
	db	00100000b,00000010b
	db	01000000b,00000010b
	db	01000000b,00000010b
	db	00100000b,00000010b
	db	00010000b,00000010b
	db	00001001b,11111110b
	db	00000101b,00000000b
	db	00000011b,00000000b
	db	00000001b,00000000b
	db	00000000b,00000000b

;================================================	describe
	if	scode
hill_msg:	
	db	'一座高山,山顶终年积雪,'
	db	'相传山顶有神仙居住,想上'
	db	'去看看吗?',0
	db	0
hill_msg_len	equ	$-hill_msg
select_road_msg:
	db	'这是方圆百里最有名的游'
	db	'戏厅,你想玩甚麽?(选择数字)',0
	db	'1.跳舞毯',0
	db	'2.投铅球',0
	db	'3.放弃',0
	db	0
select_road_len	equ	$-select_road_msg
	else
hill_msg:	
	db	'畒蔼,郴沧縩撤,'
	db	'肚郴Τ﹡,稱'
	db	'盾?',0
	db	0
hill_msg_len	equ	$-hill_msg
select_road_msg:
	db	'硂琌よ蛾κń程Τ村'
	db	'栏芔,稱或?(匡拒计)',0
	db	'1.铬籖脆',0
	db	'2.щ膞瞴',0
	db	'3.斌',0
	db	0
select_road_len	equ	$-select_road_msg
	endif

;===============================================
game_box:
	lm	lcmd,#0
	BREAK_FUN	_Bblock_draw
	lm	lcmd,#1
	BREAK_FUN	_Bsqure_draw
	
	lm	x0,#78			;将lcd分为两部分的竖线
	sta	x1
	lm	y0,#1
	lm	y1,#79
	BREAK_FUN	_Bline_draw
	
	jsr	disp_score		;显示'score'
	jsr	show_score		;显示分数

	lm	x0,#79			;提示栏下的横线
	lm	x1,#158
	lm	y0,#25
	sta	y1
	BREAK_FUN	_Bline_draw
	
	lm	x0,#90			;小人站立的直线
	lm	x1,#150
	lm	y0,#70
	sta	y1
	BREAK_FUN	_Bline_draw


	lm	x0,#36			;四个箭头中间的小正方形
	lm	y0,#44
	lm	x1,#43
	lm	y1,#51
	BREAK_FUN	_Bsqure_draw
	rts

;=============================================
;input:a1(图形在lcd上的位置),a2(图形的地址),x(图形有几行)
;=============================================
show_arrow:
	ldx	#16
	ldy	#0	
write_loop:
	lda	(a2),y
	sta	(a1),y
	iny
	lda	(a2),y
	sta	(a1),y
	iny
	lda	#18
	clc
	adc	a1
	sta	a1
	bcc	$+4
	inc	a1h
	dbne	x,write_loop
	rts
;=====================================================
;input:a1(图形在lcd上的位置),a2(图形的地址)
;=============================================
flash_arrow:
	ldx	#16
	ldy	#0	
flash_write_loop:
	lda	(a2),y
	eor	#0ffh
	sta	(a1),y
	iny
	lda	(a2),y
	eor	#0ffh
	sta	(a1),y
	iny
	lda	#18
	clc
	adc	a1
	sta	a1
	bcc	$+4
	inc	a1h
	dbne	x,flash_write_loop
	rts
;=====================================================	
refresh_arrow:
	lm2	a1,temp_lcd
	lm2	a2,temp_arrow
	jmp	show_arrow
;=====================================================
;destroy:a1,a2,x,y
erase_arrow:
	lm2	a1,temp_arrow_lcd
	lm2	a2,temp_arrow_img
	ldx	#16
	ldy	#0	
erase_arrow_loop:			;擦掉图形
	lda	#0
	sta	(a1),y
	iny
	sta	(a1),y
	iny
	lda	#18
	clc
	adc	a1
	sta	a1
	bcc	$+4
	inc	a1h
	dbne	x,erase_arrow_loop
	rts
;======================================================
check_score:
	cmp2	temp_arrow,temp_arrow_img
	beq	add_score
	pla
	pla
	jmp	proc_esc

add_score:
	ldx	game_level
	cpx	#80
	bcc	add_score1
	dex
	dex
	stx	game_level
add_score1:
	lda	#DODGE_BONUS
	adda2	tiaowu_score

show_score:
shsc0:
shsc1:
	lm2	a3,tiaowu_score
	ldx	#0
	lm	temp1+1,#5
shsc2:					;should we blank leading zero??
	jsr	get_next_digit
	stx	temp1			;----	 save
	jsr	show_one_digit		;    |
	ldx	temp1			;----	 restore
	inx
	inx
	cpx	#10
	bcc	shsc2
show_top:
	cmp2	tiaowu_score,top_score
	bcc	show_top1
	lm2	top_score,tiaowu_score
show_top1:
	lm2	a3,top_score
	ldx	#0
	lm	temp1+1,#5
show_top2:
	jsr	get_next_digit
	stx	temp1			;----	 save
	ldy	#13
	jsr	show_one_digit1		;    |
	ldx	temp1			;----	 restore
	inx
	inx
	cpx	#10
	bcc	show_top2
	rts
;;;
delay_160_ms
	ldx	#40
	jsr	waittime
	rts
delay:
	jsr	waittime
	rts
;===============================================================
get_next_digit:
	;input: xreg:测试万位,千位,百位,十位或者个位;
	;output:areg:该位数字;
b1o:	lm	cx,#0ffh
b2o:	inc	cx
	lm20x	a4,t1000
	sub	a3,a4
	bcs	b2o
	add	a3,a4
	lda	cx
	rts

t1000:	dw	10000
	dw	1000
	dw	100
	dw	10
	dw	1
;======================================================
show_one_digit:
	ldy	#2
show_one_digit1:
	ora	#30h
	sta	fccode
	inc	temp1+1
	ldx	temp1+1
	inx
	jmp	write_one_char
	
;================================================================
disp_score:
	lm	temp1,#0
disp_loop:	
	ldy	temp1
	lda	score,y
	beq	disp_end
	sta	fccode
	ldy	#2
	ldx	temp1
	inx
	jsr	write_one_char
	ldy	temp1
	lda	top,y
	sta	fccode
	ldy	#13
	ldx	temp1
	inx
	jsr	write_one_char
	inc	temp1
	jmp	disp_loop
disp_end:
	rts

;=================================================================
wait_key_loop:
	jsr	wait_key
	cmp	#62h		;1	,我的键盘按1后的键值
	beq	dodge_rts
	cmp	#6eh		;2
	beq	unarmed_rts
	cmp	#6dh		;3
	beq	force_rts
	jmp	wait_key_loop

dodge_rts:
	lm	kf_id,#1
	lm2	top_score,top_dance
	rts
unarmed_rts:
	lm	kf_id,#2
	lm2	top_score,top_ball
	rts
force_rts:
	lm	kf_id,#0
	rts
;=======================================================
score:
	db	'SCORE:',0
top:
	db	' TOP :',0
;--------------------------------------------------------------------
	end
