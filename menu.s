;;******************************************************************
;;	menu.s - 弹出式菜单处理程序
;;
;;	written by lian
;;	begin on 2001/04/03
;;	finish on 2001/05/09
;;
;; "弹出式菜单处理程序" 是程序的用户界面,相当于 "通用菜单处理程序"
;; 不同的是前者是弹出式菜单,后者是全屏菜单 后者只是前者的特例
;;
;;*******************************************************************

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;说明: pop_menu
;input: Xreg,Yreg menu_ptr(表地址) a1(索引数据)
;input: menu_set 进入菜单后光标显示的位置(0,1,2,3...)
;
;menu_tbl:
;	db	01110000b	;菜单格式
;	db	4		;菜单总数
;	db	00100010b	;屏幕格式
;	db	NORMAL_MENU	;菜单方式
;	dw	win_prog1,show_prog1	;处理程序地址,显示程序地址(如果有)
;	dw	win_prog2,show_prog2	; ...
;	dw	win_prog2,show_prog3	;
;	dw	win_prog2,show_prog4	;
;	db	'攻击',0ffh	;菜单名称,结束符
;	db	'物品',0ffh	; ...
;	db	'状态',0ffh	;
;	db	'逃跑',0ffh	;
;	dw	index_addr	;索引表地址(如果有索引)
;
; 菜单格式:
;	bit7:	1:有索引	0:no
;	bit6:	1:有显示程序	0:no
;	bit5:	1:显示数量	0:no(最大为255,无索引时不起作用)
;	bit4:	1:一个程序	0:多个程序
;	bit3-0:	每行字符数(英文字作单位),为0时自动计算
; 菜单总数:
;	bit7:	1:动态菜单	0:普通菜单
;		动态菜单需要给出数据地址a1 格式为: 菜单项数 数值 ...
;	bit6-0:	菜单项总数(如果是普通菜单)
; 屏幕格式:
;	bit7:	1:有frame		0:no
;	bit6-4:	屏幕行数,0时自动计算 = 菜单项/列数
;	bit3:	1:开始位置为menu_set	0:开始位置为0
;	bit2-0:	每行列数,0时自动计算 = 菜单项/行数
; 菜单方式:
;	0	反显		NORMAL_MENU
;	1	三角箭头	ARROW_MENU
;	2	方框		BOX_MENU
;	3	圆点		RADIO_MENU
;	4	上方框		ICON_MENU
;	5	右方框		ICON_MENU1
;	6	单一勾		CHECK_MENU (menu_set勾)
;	7	多重勾		CHECK_MENU1 (索引数据bit7=1勾)
;	8	图形菜单	GRAPH_MENU (只能简单使用)
; 处理程序:
;	返回Areg=0ffh press ESC_KEY
;	如果处理程序地址为0, 返回Areg=menu_set press CR_KEY
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	include	h/gmud.h	;using graph.h
	include	h/id.h
	include	h/mud_funcs.h
	include	h/func.mac

	public	pop_menu
	public	show_menu_txt

	extrn	wait_key
	extrn	write_one_char

	extrn	divid_ax
	extrn	mul_ax
	extrn	square_draw
	extrn	write_block0
	extrn	w_block0

MENU_HEAD	equ	4
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PushMenuAll	macro
        lda     m_current_item
        pha
	lda     m_start_show_item
        pha
	lda	X_position
        pha
	lda	Y_position
	pha
	lda	menu_ptr
	pha
	lda	menu_ptr+1
	pha
	lda	data_addr
	pha
	lda	data_addr+1
	pha
	endm

PullMenuAll	macro
	pla
	sta	data_addr+1
	pla
	sta	data_addr
	pla
	sta	menu_ptr+1
	pla
	sta	menu_ptr
	pla
	sta	Y_position
	pla
	sta	X_position
	pla
	sta     m_start_show_item
	pla
        sta     m_current_item
	endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;input: Xreg,Yreg menu_ptr(表地址) a1(索引数据)
;output: m_current_item menu_set
;
;used: m_current_item,m_start_show_item
;	menu_flag,line_form
;
; 如果是动态菜单,则a1为索引数据地址,否则a1没有用
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pop_menu:
	stx	X_position
	sty	Y_position
	lm	walking,#0
	lm2	data_addr,a1
	lda	#0
	sta	m_current_item
	sta	m_start_show_item

	jsr	init_menu
	lda	line_num
	beq	menu_rts

	jsr	init_pos
	jsr	show_menu
	jsr	proc_show
proc_loop:
	jsr	wait_key
	cmp	#ESC_KEY
	beq	menu_rts

	SWITCH	#menu_key_len,menu_key_tbl
	jmp	proc_loop
menu_rts:
	lda	#0ffh
	rts

;-------------------------------------
;	show menu text
;-------------------------------------
show_menu_txt:
	stx	X_position
	sty	Y_position
	lm2	data_addr,a1
	lda	#0
	sta	m_current_item
	sta	m_start_show_item

	jsr	init_menu
	lda	line_num
	beq	menu_txt_rts

	jsr	init_pos
	lda	#0ffh
	sta	m_current_item
	jsr	show_menu
menu_txt_rts:
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	init global var
; input: menu_ptr data_addr
; output: key_word line_form scr_word scr_form
;	line_num menu_flag scr_sum menu_end_addr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
init_menu:
	lm2	a1,data_addr
	ldy	#0
	lda	(menu_ptr),y
	sta	key_word
	and	#0fh
	sta	char_form
	iny

	lda	(menu_ptr),y
	sta	line_num
	iny

	lda	(menu_ptr),y
	sta	scr_word
	and	#07h
	sta	line_form
	lda	scr_word
	mlsr	a,4
	and	#07h
	sta	scr_form
	iny

	lda	(menu_ptr),y
	sta	menu_flag
	iny

	lm2	prog_addr,menu_ptr
	lda	#MENU_HEAD
        adda2    prog_addr

        ;; menu_end_addr = menu_addr + MENU_HEAD +  program*4
	lm2     index_addr,menu_ptr
	ldx	#1
	bbs4	key_word,only_one_pro

	ldx	line_num
	bit	line_num
	bpl	only_one_pro
	ldy	#0
	lda	(a1),y
	tax
only_one_pro:
	txa
	asl	a
	bit	key_word
	bvc	$+3
	asl	a
	clc
	adc	#MENU_HEAD
        adda2    index_addr

	bit	line_num
	bmi	init_dmenu
	bit	key_word
	bpl	to_adjust

	;; index_addr = (menu_end_addr),line_num
	lm2	menu_end_addr,index_addr	;get index
	ldy	line_num
	lda	key_word
	and	#20h
	beq	init_index
	tya
	asl	a
	tay
init_index:
        lda     (menu_end_addr),y
        sta     index_addr
        iny
        lda     (menu_end_addr),y
        sta     index_addr+1		;index
	jmp	to_adjust

init_dmenu:
	;init Dpop_menu
	ldy	#0
	lda	(a1),y
	sta	line_num
	inc2	a1

	bit	key_word
	bmi	init_dindex
	lm2	index_addr,a1
	jmp	to_adjust
init_dindex:
	lm2	menu_end_addr,a1
	lm2	a1,index_addr
	ldy	#0
	lda	(a1),y
	sta	index_addr
	iny
	lda	(a1),y
	sta	index_addr+1
to_adjust:
	jsr	adjust_scr_form
	rts

;-----------------------------------------
; 1. if line_num / line_form < scr_form
;    then scr_form = line_num / line_form
; 2. scr_sum = scr_form * line_form
;-----------------------------------------
adjust_scr_form:
	lda	line_num
	ldx	scr_form
	beq	cal_scr_form
	ldx	line_form
	beq	cal_line_form

	jsr	divid_ax
	tay
	txa
	beq	$+3
	iny
	cpy	scr_form	;Yreg = line_num/line_form
	bcs	cal_scr_num
	sty	scr_form
cal_scr_num:
	tya
	ldx	line_form
	jsr	mul_ax
	sta	scr_num
	jmp	cal_scr_sum

cal_scr_form:
	ldx	line_form
	jsr	divid_ax
	tay
	txa
	beq	$+3
	iny
	sty	scr_form
	lm	scr_num,line_num
	jmp	cal_scr_sum

cal_line_form:
	ldx	scr_form
	jsr	divid_ax
	tay
	txa
	beq	$+3
	iny
	sty	line_form
	lm	scr_num,line_num
	jmp	cal_scr_sum

cal_scr_sum:
	lda	scr_form
	ldx	line_form
	jsr	mul_ax
	sta	scr_sum
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	init start position
; input: menu_set
; output: m_current_item,m_start_show_item
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
init_pos:
	lda	menu_set
	sta	check_item	;!!for CHECK_MENU
	bmi	init_pos_rts
	cmp	line_num
	bcs	init_pos_rts
	bbr3	scr_word,init_pos_rts

	lm	m_start_show_item,#0
	lm	m_current_item,menu_set
adjust_pos:
	lda	m_start_show_item
	clc
	adc	scr_sum
	cmp	m_current_item
	bgt	init_pos_rts
	add1	m_start_show_item,line_form
	jmp	adjust_pos
init_pos_rts:
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 画窗口边框
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
draw_frame:
	jsr	set_xy
	dec	x0
	beq	draw_frame1
	dec	x0
	bne	draw_frame2
draw_frame1:
	lm	x0,#1
draw_frame2:	
	dec	y0
	inc	y1

	lm	lcmd,#1
	jsr	square_draw
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;	set frame's coordinate
;; input: X_sit Y_sit
;; output: x0 x1 y0 y1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
set_xy:
	ldx	X_sit		;first x1 second x0
	lda	char_height
	lsr	a
	jsr	mul_ax
	sta	x1

	jsr	set_charx
	ldx	X_sit
	lda	char_height
	lsr	a
	jsr	mul_ax
	sta	x0

	lm	y0,Y_position
	clc
	lda	Y_sit
	adc	char_height
	sta	y1

	lda	large_size_flag
	bne	big_frame

	inc	x0		;for small font
	inc	x0
	dec	y1
big_frame:
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;	Updata menu screen
;; input: m_start_show_item m_current_item
;; output:
;;
;; used:
;; menu_tmp1: item index
;; menu_tmp2: line index
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
show_menu:
	lda	menu_flag
	cmp	#ICON_MENU
	beq	show_icon_txt
	cmp	#ICON_MENU1
	beq	show_icon_txt
	cmp	#GRAPH_MENU
	jeq	show_bitmap

	sub1	Y_position,char_height,Y_sit
	lm	menu_tmp1,m_start_show_item
	lm	menu_tmp2,#0
show_menu_loop:
	jsr	set_charx
	add1	Y_sit,char_height
	ldx	#0
show_item:
	txa
	pha
	ldy	menu_tmp1
	jsr	write_pad
	ldy	menu_tmp1
	jsr	move_point
	jsr	write_1_item
	pla
	tax
	inx
	inc	menu_tmp1
	cmp1	menu_tmp1,line_num
	bcs	show_menu_rts
	cpx	line_form
	bcc	show_item

	inc	menu_tmp2
	cmp1	menu_tmp2,scr_form
	bcc	show_menu_loop

show_menu_rts:
	rmb7	char_mode
	; check frame flag
	bit	scr_word
	jmi	draw_frame
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;	menu_flag = ICON_MENU
;; input: m_start_show_item
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
show_icon_txt:
	lm	menu_tmp1,m_start_show_item
	lm	Y_sit,Y_position
	lda	X_position
	mlsr	a,3
	sta	X_sit
small_loop:
	ldy	menu_tmp1
	jsr	set_current_pad	;out: fccode
	ldy	menu_tmp1
	jsr	pad_8x12
	inc	menu_tmp1
	cmp1	menu_tmp1,line_num
	bcc	small_loop

	jsr	set_icon_txt
	ldy	m_current_item
	jsr	move_point
	jsr	write_1_item
	rts

;----------------------
; i:X_sit Y_sit
;----------------------
set_icon_txt:
	lda	menu_flag
	cmp	#ICON_MENU
	beq	set_icon0
	cmp	#ICON_MENU1
	beq	set_icon1
	rts

set_icon0:
	jsr	set_charx
	add1	Y_sit,#12
	rts

set_icon1:
	jsr	set_charx
	lda	char_form
	bne	$+4
	lda	#8
	sta	a1
	inc	a1
	inc	a1
	sub1	X_sit,a1
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;	menu_flag = GRAPH_MENU
;; input: m_start_show_item
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
show_bitmap:
	lm	Y_sit,Y_position
	lm	menu_tmp1,m_start_show_item
	lm	menu_tmp2,#0
show_graph_loop:
	lm	X_sit,X_position
	ldx	#0
show_graph:
	txa
	pha
	ldy	menu_tmp1
	jsr	show_1_graph
	pla
	tax
	inx
	inc	menu_tmp1
	cmp1	menu_tmp1,line_num
	bcs	show_bitmap_rts
	cpx	line_form
	bcc	show_graph

	add1	Y_sit,graph_height
	add1	Y_sit,#8
	inc	menu_tmp2
	cmp1	menu_tmp2,scr_form
	bcc	show_graph_loop

show_bitmap_rts:
	lm	lcmd,#0
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; input:        Yreg(show No.) index_addr X_sit Y_sit
; output:	X_sit,graph_height
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
show_1_graph:
	lda	#1
	cpy	m_current_item
	bne	$+4
	lda	#6
	sta	lcmd

	tya
	asl	a
	tay
	lm2	index_menu_addr,index_addr
	lda	(index_menu_addr),y
	sta	fccode
	iny
	lda	(index_menu_addr),y
	sta	fccode+1
	
	;*********
	jsr	move_to_ram
	;*********
	push2	fccode
	ldx	X_sit
	ldy	Y_sit
	;BREAK_BBS	_Bwrite_block
	jsr	write_block0
	pull2	fccode

	ldy	#0
	lda	(fccode),y
	clc
	adc	#4
	adda1	X_sit
	iny
	lda	(fccode),y
	sta	graph_height
	rts

;----------------------------------
;input: fccode
;ouput: fccode
;---------------------------------
move_to_ram:
	ldy	#0
	lda	(fccode),y
	mlsr	a,3
	tax
	lda	(fccode),y
	and	#7
	beq	$+3
	inx
	iny
	lda	(fccode),y
	jsr	mul_ax
	clc
	adc	#2

	tax
	ldy	#0
mov_l:
	lda	(fccode),y
	sta	img_buf,y
	iny
	dbne	x,mov_l
	lm2	fccode,#img_buf
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; input:        Yreg(show No.) menu_end_addr
; output:       index_menu_addr
; used:         Xreg, Areg
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
move_point:
	bit	key_word
	bpl	not_index

	lda	key_word
	and	#20h
	beq	not_digit
	tya
	asl	a
	tay
not_digit:
	lda     (menu_end_addr),y
	and	#7fh			;!!for CHECK_MENU1
	tay

not_index:
	lm2	index_menu_addr,index_addr
	tya
	tax
	beq	find_curr_addr
next_item:
        ldy     #0ffh
next_byte:
        iny
        lda     (index_menu_addr),y
	beq	$+6
        cmp     #0ffh
        bne     next_byte
	iny
	tya
	adda2	index_menu_addr
        dex
        bne     next_item
find_curr_addr:
        rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;	set char positon
;; input:  X_position
;; output: X_sit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
set_charx:
	lda	char_height
	lsr	a
	tax		;6 or 8
	lda	X_position
	jsr	divid_ax
	sta	X_sit
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	画菜单窗口的提示 12x12 pad
;input:  menu_flag X_sit Y_sit
;output: X_sit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
write_pad:
	jsr	set_current_pad	;out: fccode

	lda	large_size_flag
	bne	pad_8x12

	;pad 12x12
	jsr	put_patbuf
	lda	char_height
	lsr	a
	ldx	X_sit
	jsr	mul_ax
	;clc
	;adc	#2	;small font offset
	sta	x0
	clc
	adc	#11
	sta	x1
	lm	y0,Y_sit
	clc
	adc	#11
	sta	y1
	jsr	w_block0

	inc	X_sit
	inc	X_sit
	rts

;-----------------------------------------------
;	pad 8x12
; input: X_sit Y_sit fccode
;-----------------------------------------------
pad_8x12:
	lda	Y_sit
	ldx	#CPR
	jsr	mul_ax
	add	a1,#lcdbuf,intc
	lda	X_sit
	adda2	intc

	ldx	#12
	ldy	#0
write_dot:
	lda	(fccode),y
	sta	(intc),y
	inc2	fccode
	lda	#CPR
	adda2	intc
	dbne	x,write_dot
	inc	X_sit
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;;	put 16x12
;; input: fccode
;; output: patbuf
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
put_patbuf:
	ldy	#0
	ldx	#0
patbuf_loop:
	lm	a2,#0
	lda	(fccode),y
	rept	2
	lsr	a
	ror	a2
	endr
	
	sta	img_buf,x
	inx
	lda	a2
	sta	img_buf,x
	inx
	iny
	cpy	#12
	bcc	patbuf_loop
	lm2	fccode,#img_buf
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;input: Yreg check_item
;output: fccode char_mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
set_current_pad:
	lda	menu_flag
	beq	to_write_reverse
	cmp	#CHECK_MENU
	beq	to_write_check
	cmp	#CHECK_MENU1
	beq	to_write_check1

to_write_normal:
	asl	a
	tax
	cpy	m_current_item
	beq	to_write_full

	lm20x	fccode,empty_pad_tbl
	rts

to_write_full:
	lm20x	fccode,full_pad_tbl
	rts

to_write_reverse:
	rmb7	char_mode
	cpy	m_current_item
	bne	not_reverse
	smb7	char_mode
not_reverse:
	pla
	pla
	rts

;i:Yreg
;o:Areg
to_write_check:
	lda	menu_flag
	cpy	check_item
	beq	to_write_normal
to_write_box:
	lda	#BOX_MENU
	jmp	to_write_normal

to_write_check1:
	lda     (menu_end_addr),y
	bpl	to_write_box
	lda	menu_flag
	jmp	to_write_normal

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	逐字写入一行
;input: char_mode X_sit Y_sit
;output: X_sit index_menu_addr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
write_1_item:
	ldy	#0ffh
write_line_loop:
	iny
	lda	(index_menu_addr),y
	sta	fccode
	beq	write_line_end
	cmp	#0ffh
	beq	write_line_end

	bit	fccode
	bpl	is_english
	iny
	lda	(index_menu_addr),y
	sta	fccode+1
is_english:
	tya
	pha

	ldx	X_sit
	ldy	Y_sit
	jsr	write_one_char
	inc	X_sit
	bit	fccode
	bpl	to_next
	inc	X_sit
to_next:
	pla
	tay
	jmp	write_line_loop

write_line_end:
	iny
	tya
	adda2	index_menu_addr
	dey

	jsr	digit_pad
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; write digit and pad zero if need
; input: Yreg X_sit
; output: X_sit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
digit_pad:
	lda	key_word
	bpl	init_pad
	and	#20h
	beq	init_pad

	tya
	pha
	lda	X_sit
	pha

	;write_digit:
	lm	fccode,#'x'
	ldx	X_sit
	ldy	Y_sit
	jsr	write_one_char
	inc	X_sit

	lda	menu_tmp1	;!!bug
	asl	a
	tay
	iny
	lda	#0
	pha
	lda     (menu_end_addr),y
	jsr	bin3digit
	pha
	txa
	pha
	tya
	pha

next_low:
	pla
	cmp	#'0'
	beq	next_low
to_low_byte:
	sta	fccode
	ldx	X_sit
	ldy	Y_sit
	jsr	write_one_char
	inc	X_sit
	pla
	bne	to_low_byte

	pla
	sta	a1
	sec
	lda	X_sit
	sbc	a1
	sta	a1
	pla
	clc
	adc	a1
	tay

init_pad:
	lda	char_form
	beq	write_item_rts
	lm	fccode,#0
pad_zero:
	cpy	char_form
	bcs	write_item_rts
	tya
	pha
	ldx	X_sit
	ldy	Y_sit
	jsr	write_one_char
	pla
	tay
	inc	X_sit
	iny
	jmp	pad_zero

write_item_rts:
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Input: Areg
;Output:Yreg(high) Xreg Areg(low)
;Example: 210--> Y('2') X('1') A('0')
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
bin3digit:
	ldy    	#'0'-1
	sec
b3d1:	iny
	sbc    	#100
	bcs    	b3d1
	adc    	#100

	ldx    	#'0'-1
	sec
b3d2:	inx
	sbc    	#10
	bcs    	b3d2
	adc    	#10+'0'
	rts

;;;;;;;;;;;;;;;;;;;;
proc_show:
	bit	key_word
	bvs	$+3
	rts

	PushMenuAll

	lm2	a1,prog_addr
	ldy	#0
	bbs4	key_word,get_proc_show
	lda	m_current_item
	asl	a
	asl	a
	tay
get_proc_show:
	iny
	iny
	lda	(a1),y
	tax
	iny
	lda	(a1),y
	sta	a1h
	stx	a1

	lda	m_current_item
	sta	menu_set
	lda	a1
	ora	a1h
	beq	$+5
	jsr	jmp_prog

	PullMenuAll
	jsr	init_menu
	rts

;;;;;;;;;;;;;;;;;;;;
proc_cr:
	PushMenuAll

	lm2	a1,prog_addr

	ldy	#0
	bbs4	key_word,jump_next_menu
	lda	m_current_item
	asl	a
	bit	key_word
	bvc	$+3
	asl	a
	tay
jump_next_menu:
	lda	(a1),y
	tax
	iny
	lda	(a1),y
	sta	a1h
	stx	a1

	lda	m_current_item
	sta	menu_set
	lda	a1
	ora	a1h
	beq	exit_menu
	jsr	jmp_prog

	PullMenuAll
	jsr	init_menu
	lda	line_num
	beq	exit_menu1
	jmp	to_refresh_menu

exit_menu:
	PullMenuAll
exit_menu1:
	pla
	pla
	pla
	pla
	lda	menu_set
	rts

;------------------
jmp_prog:
	jmp	(a1)

;;;;;;;;;;;;;;;;;;;;
proc_up:
	cmp1	scr_form,#1
	beq	proc_rts

	sec
	lda	m_current_item
	sbc	line_form
	sta	m_current_item
	bcs	to_up_menu
	adc	scr_num
	sta	m_current_item
	cmp	line_num
	bcc	to_tail_menu
	ldx	m_current_item
	dex
	stx	m_current_item
	bcs	to_tail_menu

;;;;;;;;;;;;;;;;;;;;
proc_left:
	cmp1	line_form,#1
	beq	proc_rts

	dec	m_current_item
	bpl	to_up_menu
	ldx	line_num
	dex
	stx	m_current_item
	jmp	to_tail_menu

;;;;;;;;;;;;;;;;;;
proc_down:
	cmp1	scr_form,#1
	beq	proc_rts

	add1	m_current_item,line_form
	cmp	line_num
	bcc	to_down_menu
	sbc	scr_num
	sta	m_current_item
	bcs	to_start_menu
	lm	m_current_item,#0
	bcc	to_start_menu

;;;;;;;;;;;;;;;;;;;;
proc_right:
	cmp1	line_form,#1
	beq	proc_rts

	inc	m_current_item
	lda	m_current_item
	cmp	line_num
	bcc	to_down_menu
	lm	m_current_item,#0
	bcs	to_start_menu

proc_rts:
	rts
;;;;;;;;;;;;;;;;;;;;
to_start_menu:
	if	0
	sec
	lda	m_current_item
	sbc	line_num
	sta	m_current_item
	endif
	lm	m_start_show_item,#0
	jmp	to_refresh_menu
to_tail_menu:
	if	0
	clc
	lda	m_current_item
	adc	line_num
	sta	m_current_item
	endif
	sub1	scr_num,scr_sum,m_start_show_item
	jmp	to_refresh_menu
to_up_menu:
	lda	m_current_item
	cmp	m_start_show_item
	bcs	to_refresh_menu
	sub1	m_start_show_item,line_form
	jmp	to_refresh_menu
to_down_menu:
	lda	m_start_show_item
	clc
	adc	scr_sum
	cmp	m_current_item
	bgt	to_refresh_menu
	add1	m_start_show_item,line_form
to_refresh_menu:
	jsr	show_menu
	jsr	proc_show
	rts

;;;;;;;;;;;;;;;;
menu_key_tbl:
	db	CR_KEY
	db	LEFT_KEY
	db	RIGHT_KEY
	db	UP_KEY
	db	DOWN_KEY
menu_key_len	equ	$-menu_key_tbl
	dw	proc_cr
	dw	proc_left
	dw	proc_right
	dw	proc_up
	dw	proc_down

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 8x12 pad
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

full_pad_tbl:
	dw	empty_dot
	dw	arrow_dot
	dw	box_full_dot
	dw	radio_full_dot
	dw	icon_full_dot
	dw	icon_full_dot
	dw	check_full_dot
	dw	check_full_dot
	dw	0		;GRAPH_MENU
empty_pad_tbl:
	dw	empty_dot
	dw	empty_dot
	dw	box_empty_dot
	dw	radio_empty_dot
	dw	icon_empty_dot
	dw	icon_empty_dot
	dw	check_empty_dot
	dw	check_empty_dot
	dw	0

arrow_dot:
	db	00000000b
	db	00000000b
	db	11000000b
	db	11100000b
	db	11110000b
	db	11111000b
	db	11111100b
	db	11111000b
	db	11110000b
	db	11100000b
	db	11000000b
	db	00000000b
box_full_dot:
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111100b
	db	00000000b
box_empty_dot:
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	11111100b
	db	10000100b
	db	10000100b
	db	10000100b
	db	10000100b
	db	11111100b
	db	00000000b
radio_full_dot:
	db	00000000b
	db	00000000b
	db	00000000b
	db	00111100b
	db	01000010b
	db	10011001b
	db	10111101b
	db	10111101b
	db	10011001b
	db	01000010b
	db	00111100b
	db	00000000b
radio_empty_dot:
	db	00000000b
	db	00000000b
	db	00000000b
	db	00111100b
	db	01000010b
	db	10000001b
	db	10000001b
	db	10000001b
	db	10000001b
	db	01000010b
	db	00111100b
	db	00000000b
icon_full_dot:
	db	00000000b
	db	00000000b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111100b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
icon_empty_dot:
	db	00000000b
	db	00000000b
	db	11111100b
	db	10000100b
	db	10000100b
	db	10000100b
	db	10000100b
	db	11111100b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
check_full_dot:
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	11111101b
	db	11111110b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111100b
	db	00000000b
check_empty_dot:
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	11111101b
	db	10000110b
	db	11000100b
	db	10101100b
	db	10010100b
	db	11111100b
	db	00000000b
empty_dot:
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0

;-------------------------------------------------------------------------------------
	end
