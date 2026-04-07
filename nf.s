;=================================================
;
;	连线对战程序
;
;	writen by: pyh		2001/7/31
;
;
;==================================================

;变量定义

PROTOCOL_NUM	equ	10
debug		equ	0

__base 	equ	game_buf		;可以用56个字节
	define	1,net_game_version
	define	1,net_quit_flag
	define	1,net_msg_vision
	define	1,net_limb_flag
	define	1,net_repeat
	define	1,net_perform_flag
	define	1,net_init_flag
	

__base	equ	bank_text
	define	PROTOCOL_NUM,package_buf		;协议用
	define	120,temp_buf		;人,npc的数据用
	define	100,msg_buf		;字符串信息用

	if	debug					;目前230个字节
__base	equ	img_buf+500
	define	255,debug_buf
	endif

;--------------------------------
	public	netfight
	extrn	message_box_for_pyh
	extrn	find_goods
	extrn	send_data
	extrn	receive_data
	extrn	CommunicateInit

;--------------------------------主程序
netfight:
	PushMenu	1
	jsr	init_protocol
	jsr	init_fight	
	ldx     #50
        ldy     #30
        lm2     menu_ptr,#netgame_menu
        jsr	pop_menu
        jsr	scroll_to_lcd
cr_rts:
        rts
;---------------------

create_game:
	jsr	CommunicateInit
	smb7	net_init_flag

	smb7	net_msg_vision
	jsr	net_send_data
	rmb7	net_msg_vision
	jsr	net_receive_data

	rmb7	net_init_flag

	smb1	net_flag
	jsr	netgame
	rts

join_game:
	jsr	CommunicateInit
	smb7	net_init_flag

	jsr	net_receive_data
	smb7	net_msg_vision
	jsr	net_send_data
	rmb7	net_msg_vision

	rmb7	net_init_flag

	rmb1	net_flag
	jsr	netgame
	rts

;------------------------

netgame:
	lda	net_flag
	and	#02h
	beq	user_game
host_game:
	smb7	obj_flag
	jsr	init_interface
   	ldx     #MAIN_MENU_X0
        ldy     #MAIN_MENU_Y0
        lm2     menu_ptr,#fight_menu
  	jsr     pop_menu
	jmp	netgame
user_game:
	rmb7	obj_flag
	jsr	init_interface
user_game_1:
	jsr	net_receive_data
	lda	net_repeat

	if	0
	cmp	#1
	bne	MyDebug
	extrn	oldmon
	jsr	oldmon
MyDebug:
	lda	net_repeat
	endif

	bne	user_game_1
	jmp	netgame

;------------------


init_interface:
	BREAK_FUN	_Bclrscreen
        UPline  #MAN_X0/6+1,#1,man_name
        UPline  #NPC_X0/6+1,#1,npc_name
        jsr     lcd_to_scroll
        jsr     write_fight
        jsr     scroll_to_lcd
	rts

;-------------------
net_receive_data:
	lm2	data_buf,#bank_text
	if	debug
	jsr	my_receive_data
	else
	jsr	receive_data
	jcs	receive_error
	jsr	check_version		;pyh	9-5
	jcs	version_error
	endif
receive_1:

	jsr	judge_msg		;处理退出等特殊信息的程序
	jsr	trans_npc
	lm2	string_ptr,#msg_buf

	bit	net_msg_vision		;如果置位,则不显示字符串
	bmi	receive_2
	
	bit	net_perform_flag	;perform结束标志
	bmi	receive_2
	
	rmb7	net_flag
	jsr	show_fight_msg
	smb7	net_flag
	jsr	who_win
receive_2:
	rmb7	net_msg_vision
	rmb7	net_perform_flag

	smb1	net_flag
	rts

;------------------

net_send_data:
	dec	net_repeat
	jsr	package_man
	jsr	package_msg
	jsr	package_protocol
	lm2	data_buf,#bank_text
	lm	data_size,#250
	if	debug
	jsr	my_send_data
	else
	jsr	send_data
	jcs	send_error
	endif

	rmb7	net_msg_vision
	rmb1	net_flag
	rts

;-------------------

init_protocol:
	lm2	a1,#net_quit_flag
	ldy	#0
	lda	#0
init_protocol_1:
	sta	(a1),y
	iny
	cpy	#9
	bcc	init_protocol_1
	rts

;-------------------	
;input:package_buf
;output:a(type)
;-------------------
judge_msg:
	lm2	a1,#package_buf
	ldy	#0
judge_msg_1:
	lda	(a1),y
	sta	net_game_version,y
	iny
	cpy	#9
	bcc	judge_msg_1

	lm	limb_flag,net_limb_flag
	
	bit	net_quit_flag
	bmi	is_quit

	rts
is_quit:
	jmp	fail_quit
;-----------------

;--------------------
;input:none
;output:temp_buf,y(size)
;--------------------
;现在man_state和npc_state一致
;man_state:40,man_picid:1,man_usekf:5,man_kfnum:1,man_kf:40,npc_hp:10,
;npc_busy:1,npc_weapon:1,
;共99个数据,
package_man:
	lm2	a1,#man_state
	ldy	#0
package_man_1:
	lda	(a1),y
	sta	temp_buf,y
	iny	
	cpy	#MAN_SIZE		;#40
	bcc	package_man_1
package_man_2:
	lda	man_picid
	sta	temp_buf,y
	iny
	ldx	#0
package_man_4:				
	lda	man_usekf,x
	sta	temp_buf,y
	iny
	inx	
	cpx	#MAX_USEKF
	bcc	package_man_4
	lda	man_kfnum
	sta	temp_buf,y
	iny
	ldx	#0
package_man_5:
	lda	man_kf,x
	sta	temp_buf,y
	iny
	inx	
	lda	man_kf,x
	sta	temp_buf,y
	iny
	inx

	inx			;跳过score的两个字节
	inx
	cpx	#80
	bcc	package_man_5
	ldx	#0
package_patch:				;加十个数据
	lda	npc_hp,x
	sta	temp_buf,y
	iny
	inx
	cpx	#10
	bcc	package_patch
	lda	npc_busy
	sta	temp_buf,y
	iny
	lda	npc_weapon
	sta	temp_buf,y
	iny
	rts

;-------------------
;将接收到的数据传给npc
;input:temp_buf
;ouput:none
;-------------------
;npc_state:40,located_id:1,npc_usekf:5,npc_kfnum:1,npc_kf:40,man_hp:10,
;man_busy:1,man_weapon:1,

trans_npc:
	lm2	a1,#npc_state
	ldy	#0
	ldx	#0
trans_npc_1:
	lda	temp_buf,x
	sta	(a1),y
	iny
	inx
	cpy	#MAN_SIZE
	bcc	trans_npc_1
trans_npc_2:
	lda	temp_buf,x
	sta	located_id
	inx

	lm2	a1,#npc_usekf
	ldy	#0
trans_patch:
	lda	temp_buf,x
	sta	(a1),y
	iny
	inx
	cpy	#MAX_USEKF
	bcc	trans_patch

	lda	temp_buf,x
	sta	npc_kfnum
	inx
trans_npc_5:
	lm2	a1,#npc_kf
	ldy	#0
trans_npc_6:
	lda	temp_buf,x
	sta	(a1),y
	iny
	inx
	cpy	#MAX_KF*2
	bcc	trans_npc_6
	bit	net_init_flag		
	bpl	trans_npc_patch			;是初始化,返回
	rts

trans_npc_patch:
	lm2	a1,#man_hp
	ldy	#0
trans_npc_7:
	lda	temp_buf,x
	sta	(a1),y
	inx
	iny
	cpy	#10
	bcc	trans_npc_7
	lda	temp_buf,x
	sta	man_busy
	inx
	lda	temp_buf,x		;npc_weapon
	pha
	eor	man_weapon
	bmi	luoying_patch		;落英缤纷可能会打掉武器
	pla
	sta	man_weapon			
	inx					
	rts

	;在菜单中去掉武器
luoying_patch:				;这个过程x值改变了,不能再作为索引
	lda	man_weapon
	jsr	find_goods
	dec	man_goods+1,x
	pla
	sta	man_weapon
	rts

;-----------------------
;将字符串数据打包
;input:string_ptr
;output:msg_buf
;-----------------------
package_msg:
	lm2	a1,string_ptr
	ldy	#0
package_msg_1:
	lda	(a1),y
	sta	msg_buf,y
	iny
	cpy	#100
	bcc	package_msg_1
	rts
;------------------	
;
;	检查版本
;	cy = 1 (error)
;------------------	
check_version:				;pyh	9-5
	lda	bank_text
	cmp	game_ver
	bne	$+4
	clc
	rts
	sec
	rts
;------------------	
;input:protol
;output:package_buf
;------------------
package_protocol:
	lm	net_limb_flag,limb_flag
	lm	net_game_version,game_ver
	lm2	a1,#net_game_version
	ldy	#0
package_protocol_1:
	lda	(a1),y
	sta	package_buf,y
	iny
	cpy	#PROTOCOL_NUM
	bcc	package_protocol_1
	rts

;-----------------------
	if	debug
my_send_data:
	lm2	a1,data_buf
	ldy	#0	
my_send_data_1:
	lda	(a1),y
	sta	debug_buf,y
	iny
	cpy	#250
	bcc	my_send_data_1
	rts

;----------------
my_receive_data:
	lm2	a1,#bank_text
	ldy	#0
my_receive_data_1:
	lda	debug_buf,y
	sta	(a1),y
	iny
	cpy	#250
	bcc	my_receive_data_1
	rts
	endif

;-------------------
;显示接收失败
;-------------------
version_error:
	lm2	string_ptr,#version_error_msg	;pyh	9-5
	jmp	show_send_msg
receive_error:
	lm2	string_ptr,#receive_fail_msg
	jmp	show_send_msg
send_error:
	lm2	string_ptr,#send_fail_msg
show_send_msg:
	lm	key,#0
	lm	x0,#6
	lm	y0,#FRAME_Y0
	lm	x1,#6+12*12
	lm	y1,#FRAME_Y0+6*12
	jsr	message_box_for_pyh
	;jsr	refresh_scroll		LEE!!!TEST!!!
	jmp	fail_quit
;-------------------------------data

	if	scode
netgame_menu:                   ;pyh 6-25
        db      00000000b
        db      2
        db      10000001b
        db      BOX_MENU
        dw      create_game
        dw      join_game
        db      '创建对战',0ffh
        db      '加入对战',0ffh
send_fail_msg:
	db	'数据传输失败!',0
	db	0
receive_fail_msg:
	db	'数据接收失败!',0
	db	0
version_error_msg:
	db	'版本号有错!',0,0
	else
netgame_menu:                   ;pyh 6-25
        db      00000000b
        db      2
        db      10000001b
        db      BOX_MENU
        dw      create_game
        dw      join_game
        db      '承癸驹',0ffh
        db      '癸驹',0ffh
send_fail_msg:
	db	'计沮肚块ア毖!',0
	db	0
receive_fail_msg:
	db	'计沮钡Μア毖!',0
	db	0
version_error_msg:
	db	'セ腹Τ岿!',0,0
	endif

	end
