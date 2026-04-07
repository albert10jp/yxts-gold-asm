;*************************************************************
;	一些工具函数
;
;	Author	: pyh
;	Start	: 2002-10-26
;	End	:
;	
;*************************************************************
	include	h/gmud.h
	include	h/id.h
	include	h/func.mac
	include	h/mud_funcs.h

	public	make_ground
	public	main_move
	public	adjust_status
	public	message_loop
	public	change_map
	public	init_map
	public	check_hit
	public	show_player
	public	random_map
	public	move_blak

	extrn	random_it
	extrn	show_one_line
	extrn	get_player
	extrn	get_img_data
	extrn	get_img_data_fast
	extrn	speed_read
	extrn	speed_read_2
	extrn	mul_ax
	extrn	lee_block
	extrn	scroll_to_lcd
	extrn	check_stat
	
;-------------------------------------------------------
;功能	: 生成背景
;
;Input	: G_Sx,G_Sy
;	: G_Dx,G_Dy
;	: G_Scene (地图数据指针)
;
;Output	: lcdbuf
;-------------------------------------------------------
make_ground:
	lm21	L_game_i,G_Sy
	lm21	L_game_j,G_Sx

	lm21	L_game_Sy,G_Sy
	add	L_game_Sy,#ScreenY_Num+1
	lm21	L_game_Sx,G_Sx
	add	L_game_Sx,#ScreenX_Num+1
draw_y_loop:
	cmp2	L_game_i,L_game_Sy	;外层循环
	jcs	draw_y_end
draw_x_loop:
	cmp2	L_game_j,L_game_Sx		;内层循环
	jcs	draw_x_end

	;计算坐标
	lm2	L_game_x,L_game_j
	sub21	L_game_x,G_Sx
	clc
	asl2	L_game_x	;*32
	asl2	L_game_x
	asl2	L_game_x
	asl2	L_game_x
	asl2	L_game_x
	sub21	L_game_x,G_Dx

cal_y_pos:
	lm2	L_game_y,L_game_i
	sub21	L_game_y,G_Sy
	clc
	asl2	L_game_y	;*32
	asl2	L_game_y
	asl2	L_game_y
	asl2	L_game_y
	asl2	L_game_y
	sub21	L_game_y,G_Dy

draw_ground:
	ldx	L_game_x
	cpx	#200
	bcs	xxx1
	cpx	#ScreenX
	jcs	continue
xxx1:
	ldy	L_game_y
	cpy	#200
	bcs	xxx2
	cpy	#ScreenY
	jcs	continue

xxx2:
	lda	L_game_i
	ldx	G_Map_Width
	jsr	mul_ax
	add	a1,L_game_j	;第几个单元
	asl2	a1
	add	a1,G_Scene,SeekOffset

	;此处要跨bank取数据,如果速度不够,可以利用预读技术
	lm	bank_no,G_map_bank
	jsr	speed_read_2
	lm2	G_item,data_read_buf
	
	;画背景,得到背景索引
	lda	G_item+1
	and	#0e0h		;111
	clc
	mlsr	a,4
	tay
	lda	G_Map_Ground,y
	sta	item_id
	iny
	lda	G_Map_Ground,y
	sta	item_id+1

	lm	G_img_cmd,#0	;print
	jsr	get_img_data	;第一次调用

	;得到真正的图象id
	jsr	get_image_id

	lda	G_item		;背景只画一次
	ora	G_item+1
	;beq	write_over
	bne	xxx3
	
	;判断有无killer
	bit	G_Task_Flag
	bpl	write_over

	cmp1	G_Curr_Map,G_Killer_Map
	bne	write_over
	cmp1	L_game_j,G_Killer_X
	bne	write_over
	cmp1	L_game_i,G_Killer_Y
	bne	write_over

	;要画的位置是killer,取killer的图象
	lm2	G_item,#474		;男杀手
	lda	ghost_gender_bak
	beq	xxx3
	lm2	G_item,#466		;女杀手

xxx3:
	;画图象的掩码
	lm2	item_id,#512
	add	item_id,G_item
	lm	G_img_cmd,#4	;and
	jsr	get_img_data_fast

	;画图象
	lm2	item_id,G_item
	lm	G_img_cmd,#3	;ora
	jsr	get_img_data_fast

write_over:
	ldx	L_game_x
	ldy	L_game_y
	lm	lcmd,#0
	jsr	lee_block

continue:
	inc2	L_game_j			;内层循环
	jmp	draw_x_loop

draw_x_end:
	lm21	L_game_j,G_Sx
	inc2	L_game_i		;外层循环
	jmp	draw_y_loop

draw_y_end:
	;************* draw Npc **************
	;now empty
	;************* draw Npc **************

	rts

;-------------------------------------------------------
;功能	: 主角行走函数
;Input	: G_item,G_Door_Addr,G_Npc_Addr
;Output	: G_item
;-------------------------------------------------------
get_image_id:
	;G_item &= 8192,去掉背景索引
	lda	G_item+1
	and	#01fh
	sta	G_item+1

	cmp2	G_item,#BLAK
	bcs	$+3
	rts

	cmp2	G_item,#DOOR_OFF
	jcc	image_is_blak

	cmp2	G_item,#NPC_OFF
	jcc	image_is_door
	
	;现在只定义到3072,大于它的一定是NPC
image_is_npc:
	push2	G_Curr_Id
	push	located_id
	lm2	G_Curr_Id,G_item

	sub	G_item,#NPC_OFF
	lm2	SeekOffset,G_item
	asl2	G_item
	add	SeekOffset,G_item
	add	SeekOffset,G_Npc_Addr
	lm	bank_no,G_map_bank

	lm2	DataBufPtr,#data_read_buf
	lm2	DataCount,#3
	jsr	speed_read

	lm2	G_item,data_read_buf
	lm	located_id,data_read_buf+2
	jsr	check_stat
	bcs	npc_is_live

	lm2	G_item,#315		;骷髅头
npc_is_live:
	pull	located_id
	pull2	G_Curr_Id
	rts

image_is_blak:
	sub	G_item,#BLAK
	rts

image_is_door:
	sub	G_item,#DOOR_OFF
	asl2	G_item
	lm2	SeekOffset,G_item
	asl2	G_item
	add	SeekOffset,G_item
	add	SeekOffset,G_Door_Addr
	lm	bank_no,G_map_bank
	jsr	speed_read_2
	lm2	G_item,data_read_buf
	rts

;-------------------------------------------------------
;功能	: 主角行走函数
;
;说明	: 该函数目前适合与32x32为单元的背景,如背景改为
;	: 16x16,需要修改,障碍物检测比较难懂,我也不太明白
;
;Input	: G_role_X,G_role_Y
;	: G_Sx,G_Sy,G_Dx,G_Dy
;	: G_Scene( 地图指针 )
;	: 
;Output	: none
;-------------------------------------------------------
main_move:
show_player:
	jsr	make_ground

	;显示主角图形
	lda	G_role_way
	ldx	#6
	jsr	mul_ax

	lda	G_role_status
	asl	a
	adda2	a1

	if	1
	;处理透明色
	push2	a1

	add	a1,#mask_img_tbl
	jsr	get_player

	ldx	G_role_X
	ldy	G_role_Y
	lm	lcmd,#4
	jsr	lee_block

	pull2	a1
	endif

	add	a1,#player_img_tbl
	jsr	get_player

	ldx	G_role_X
	ldy	G_role_Y
	lm	lcmd,#3
	jsr	lee_block

	jsr	scroll_to_lcd
	ldx	#0
	ldy	#0
	lm2	string_ptr,#G_MapName
	jsr	show_one_line
	rts

;-------------------------------------------------------
;功能	: 碰撞检测
;
;Input	:
;	: G_role_x,G_role_y
;	: G_Sx,G_Sy
;
;Output	: sec(hit) clc(no)
;Destroy: a1
;-------------------------------------------------------
check_hit:
	jsr	move_blak
	lda	located_id
	bne	hit_it
	clc
	rts
hit_it:
	sec
	rts

;-------------------------------------------------------
;功能	: 判断所在块是否是障碍
;
;Input	: G_Sy,G_Sx,G_role_X,G_role_Y,G_role_way
;	: G_Dx,G_Dy
;
;Output	: sec(is blak) clc(no)
;-------------------------------------------------------
move_blak:
	lm	G_Curr_Id,#0
	sta	G_Curr_Id+1
	sta	located_id
	ldx	G_role_way
	lda	face_x,x
	sta	L_game_x
	lda	face_y,x
	sta	L_game_y

	lda	G_role_Y
	clc
	adc	#Role_Height-Unit_Height	;脚底位置
	clc
	adc	G_Dy

	clc
	mlsr	a,5
	clc
	adc	G_Sy
	adc	L_game_y
	sta	L_game_y		;记录下此块的纵坐标
	cmp	G_Map_Height
	jcs	not_move
	
	ldx	G_Map_Width
	jsr	mul_ax

	lda	G_role_X
	clc
	adc	G_Dx

	clc
	mlsr	a,5
	clc
	adc	G_Sx
	adc	L_game_x
	sta	L_game_x		;记录下此块的横坐标
	cmp	G_Map_Width
	jcs	not_move
	
	adda2	a1
	
	jsr	get_object0
	lm2	G_Curr_Id,a2		;save

	cmp2	a2,#BLAK
	jcc	judge_killer

	cmp2	a2,#DOOR_OFF
	jcc	not_move

	cmp2	a2,#NPC_OFF
	jcc	can_move
	;记录下最近一个碰撞过的NPC的位置以做检测

	sub	a2,#NPC_OFF
	lm2	SeekOffset,a2
	asl2	a2
	add	SeekOffset,a2
	add	SeekOffset,G_Npc_Addr
	lm	bank_no,G_map_bank
	lm2	DataBufPtr,#data_read_buf
	lm2	DataCount,#3
	jsr	speed_read

	lm2	G_id_item,data_read_buf
	lm	located_id,data_read_buf+2

not_move:
	sec
	rts
can_move:
	clc
	rts

judge_killer:
	;如果是空白,判断是否有killer存在
	bit	G_Task_Flag
	bpl	can_move

	cmp1	G_Curr_Map,G_Killer_Map
	bne	can_move
	cmp1	L_game_x,G_Killer_X
	bne	can_move
	cmp1	L_game_y,G_Killer_Y
	bne	can_move

	;************************
	;碰到了killer,作相应处理
	lm2	G_Curr_Id,#NPC_OFF
	lm	located_id,#KILLER_NPC
	;************************
	jmp	not_move

face_x:
	db	0,0ffh,1,0,0
face_y:
	db	1,0,0,0ffh,0
	

;-------------
player_img_tbl:
l	=	0a600h+3*0c0h
	rept	9
	dw	l
l	=	l+0c0h
	endr

l	=	0a600h
	rept	3
	dw	l
l	=	l+0c0h
	endr
	
mask_img_tbl:
l	=	0a600h+15*0c0h
	rept	9
	dw	l
l	=	l+0c0h
	endr

l	=	0a600h+12*0c0h
	rept	3
	dw	l
l	=	l+0c0h
	endr

;-------------------------------------------------------
;功能	: 边界检测
;
;说明	: 运算不支持负数比较,所以不判断左上角,要靠程序保证
;	: 左上角在边界内
;
;Input	: G_role_X,G_role_Y,G_Map_Width,G_Map_Height
;	: G_Sx,G_Sy,G_role_status
;
;Output	: G_role_X,G_role_Y,G_Sx,G_Sy,G_role_status
;-------------------------------------------------------
adjust_status:
	inc	G_role_status
	cmp1	G_role_status,#3
	bcc	adjust_rts
	lm	G_role_status,#0
adjust_rts:
	rts
;-------------------------------------------------------
;功能	: 消息循环处理函数
;
;-------------------------------------------------------
message_loop:
	lm2	a2,G_Curr_Id	;取得主角所站位置的id

	cmp2	a2,#DOOR_OFF
	jcc	message_loop_rts

	;得到门的信息,index*6
	sub	a2,#DOOR_OFF
	asl2	a2
	lm2	SeekOffset,a2
	asl2	a2
	add	SeekOffset,a2

	add	SeekOffset,G_Door_Addr
	lm	bank_no,G_map_bank
	lm2	DataBufPtr,#data_read_buf
	lm2	DataCount,#6
	jsr	speed_read
	lm2	G_item,data_read_buf

	lm	G_Curr_Map,data_read_buf+2

	lm	G_Init_X,data_read_buf+4
	lm	G_Init_Y,data_read_buf+5

	jsr	change_map
	jsr	show_player
message_loop_rts:
	rts

;-------------------------------------------------------
;功能	: 切换地图,调整地图宽,高,将指针指向数据区
;
;Input	: G_map_bank,G_Curr_Map
;
;Output	: G_Scene,G_Map_Width,G_Map_Height
;-------------------------------------------------------
change_map:
	jsr	change_map0
	jsr	adjust_pos
	rts

change_map0:
	lm	bank_no,G_map_bank
	lm2	SeekOffset,G_Map_Addr
	lda	G_Curr_Map		;!!test,此处大于128会溢出
	asl	a
	adda2	SeekOffset
	jsr	speed_read_2
	lm2	G_Scene,data_read_buf

	lm2	SeekOffset,G_Scene
	lm2	DataBufPtr,#G_Map_Width
	lm2	DataCount,#CHANGE_MAP_LEN
	jsr	speed_read

	;调整G_Scene使其指向数据区
	lda	#CHANGE_MAP_LEN
	adda2	G_Scene
	rts
	
;-------------------------------------------------------
random_map:
	lm	back_map,G_Curr_Map
random_map0:	
	ldx	G_Total_Map
	dex
	stx	range
	lm	range+1,#0
	jsr	random_it
	tax
	inx
	stx	G_Killer_Map
	lm	try_time,#8
	lm	G_Curr_Map,G_Killer_Map
	jsr	change_map0
random_map1:	
	ldx	G_Map_Width
	dex
	dex
	stx	range
	lm	range+1,#0
	jsr	random_it
	tax
	inx
	stx	G_Killer_X
	ldx	G_Map_Height
	dex
	dex
	stx	range
	lm	range+1,#0
	jsr	random_it
	tax
	inx
	stx	G_Killer_Y
	jsr	get_object
	bcs	try_fail
	dec	G_Killer_X
	jsr	get_object
	cmp	#2
	beq	try_fail
	inc	G_Killer_X
	inc	G_Killer_X
	jsr	get_object
	cmp	#2
	beq	try_fail
	dec	G_Killer_X
	dec	G_Killer_Y
	jsr	get_object
	cmp	#2
	beq	try_fail
	inc	G_Killer_Y
	inc	G_Killer_Y
	jsr	get_object
	cmp	#2
	beq	try_fail
	dec	G_Killer_Y
	move	G_MapName,G_img_buf,#16
	lm	G_Curr_Map,back_map
	jmp	change_map0
try_fail:
	dec	try_time
	bne	random_map1
	jmp	random_map0
try_time:
	db	8
back_map:
	db	8

get_object:	
	lda	G_Killer_Y
	ldx	G_Map_Width
	jsr	mul_ax
	lda	G_Killer_X
	adda2	a1
	jsr	get_object0
	lsr	a
	lsr	a
	cmp	#1
	rts

get_object0:	
	asl2	a1
	add	a1,G_Scene,SeekOffset
	lm	bank_no,G_map_bank
	jsr	speed_read_2
	lda	data_read_buf
	sta	a2
	lda	data_read_buf+1
	and	#1fh		;去掉背景索引
	sta	a2h
	rts
	
;-------------------------------------------------------
;功能	: 调整人物显示位置
;
;Input	: G_Init_X,G_Init_Y,G_Map_Width,G_Map_Height
;
;Output	: G_Sx,G_Sy
;	: G_Dx,G_Dy
;	: G_role_X,G_role_Y
;
;说明	: 调整原则,使人物的显示位置尽量在中间,
;	: 人物的最佳显示位置(2,1)
;-------------------------------------------------------
adjust_pos:
	lm	G_Sx,#0
	sta	G_Sy
	sta	G_Dx
	sta	G_Dy

	lda	G_Init_X
	cmp	#2
	bcc	adjust_y

adjust_x:
	sec
	sbc	#2
	sta	G_Sx

	lda	G_Map_Width
	sec
	sbc	#ScreenX/Unit_Width
	cmp	G_Sx
	bcs	adjust_y
	sta	G_Sx

adjust_y:
	lda	G_Init_Y
	cmp	#1
	bcc	adjust_over

	sec
	sbc	#1
	sta	G_Sy

	lda	G_Map_Height
	sec
	sbc	#ScreenY_Num
	cmp	G_Sy
	bcs	adjust_over
	sta	G_Sy
adjust_over:
	lda	G_Init_X
	sec
	sbc	G_Sx
	masl	a,5
	sta	G_role_X

	lda	G_Init_Y
	sec
	sbc	G_Sy
	masl	a,5
	sta	G_role_Y
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;tony for adjust feet
	lda	G_role_Y
	sec
	sbc	#16
	sta	G_role_Y
	rts
;-------------------------------------------------------
;功能	: 初始化地图数据指针
;
;Input	: G_Base_Map,G_map_bank
;
;Output	: G_Init_MapNum,G_Init_X,G_Init_Y
;	: G_Door_Addr,G_Npc_Addr,G_Map_Addr
;	: G_Total_Map
;-------------------------------------------------------
init_map:
	lm	bank_no,G_map_bank
	lm2	SeekOffset,#0
	lm2	DataBufPtr,#G_Total_Map
	lm2	DataCount,#INIT_MAP_LEN
	jsr	speed_read

	lm2	G_Map_Addr,#INIT_MAP_LEN
	jsr	change_map
	rts

;-------------------------------------------------------
	end
