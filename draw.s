;;******************************************************************
;;	draw.s - graphic lib
;;		write_block line_draw square_draw block_draw
;;
;;	written by lian
;;	begin on 2001/03/12
;;	finish on 2001/03/23
;;	2001/04/09	add: line_draw square_draw block_draw
;;	2001/07/12	add: lcmd(6:convert) for write_block 
;;*******************************************************************
	include	h/gmud.h
	;-------------------------------------------
	; lcmd(line_draw square_draw block_draw)
	;	0:clear	1:print	2:convert
	;-------------------------------------------

	public	line_draw
	public	square_draw
	public	block_draw

	public	w_block0
	public	write_block0

	public	clear_nline
	public	clear_nline2

	extrn	mul_ax
	extrn	lcd_start_addr_tbl

;-----------------------------------------------------------------
;	draw vertical line or horizontal line
; input: x0,x1,y0,y1
; output: (intc)
;-----------------------------------------------------------------
line_draw:
	cmp1	x0,x1
	beq	vline
	cmp1	y0,y1
	beq	hline
	rts

;-----------------------------------------------------------------
;draw vertical line when(x0 == x1)
;-----------------------------------------------------------------
vline:
	ldx	x0
	ldy	y0
	jsr	byte_addr
	lda	x0
	and	#7
	sta	r2

	Distant	y0,y1
	sta	yy
vline_loop:
	lda	yy
	beq	vline_rts

	jsr	put_a_dot
	dec	yy
	lda	#CPR
	adda2	intc
	jmp	vline_loop
vline_rts:
	rts

;--------------------------------------
; input: intc lcmd r2
; output: (intc)
;--------------------------------------
put_a_dot:
	ldx	r2
	lda	lcmd
	beq	cls_dot
	cmp	#1
	beq	write_dot
	cmp	#2
	beq	convert_dot
	rts

cls_dot:
	lda	msktbl,x
	eor	#0ffh
	ldy	#0
	and	(intc),y
	sta	(intc),y
	rts
write_dot:
	lda	msktbl,x
	ldy	#0
	ora	(intc),y
	sta	(intc),y
	rts
convert_dot:
	lda	msktbl,x
	ldy	#0
	eor	(intc),y
	sta	(intc),y
	rts

;-----------------------------------------------------------------
;draw horizontal line when(y0 == y1)
; Yreg as index
;-----------------------------------------------------------------
hline:
	jsr	set_write_var
hline0:
	ldy	#0
	ldx	r2
	jsr	part_byte0
	iny
	cpy	r0
	beq	hline_rts
	iny
	cpy	r0
	beq	to_last_byte

	;1 -- r0-2	r0>2
	ldy	#1
	ldx	#2
hline_loop:
	jsr	put_byte
	iny
	inx
	cpx	r0
	bcc	hline_loop

to_last_byte:
	ldy	r0
	dey
	ldx	r3
	jsr	part_byte1

hline_rts:
	rts

;--------------------------------------
; input: intc Xreg Yreg lcmd
; output: Areg
;--------------------------------------
part_byte0:
	beq	put_byte
	dex
	lda	(intc),y
	sta	a1

	lda	lcmd
	beq	cls_byte0
	cmp	#1
	beq	write_byte0
	cmp	#2
	beq	convert_byte0
	rts
cls_byte0:
	lda	msktbl1,x
	and	a1
	sta	(intc),y
	rts
write_byte0:
	lda	msktbl1,x
	eor	#0ffh
	ora	a1
	sta	(intc),y
	rts
convert_byte0:
	lda	msktbl1,x
	eor	#0ffh
	eor	a1
	sta	(intc),y
	rts

;--------------------------------------
; input: intc Xreg Yreg lcmd
; output: Areg
;--------------------------------------
part_byte1:
	lda	(intc),y
	sta	a1

	lda	lcmd
	beq	cls_byte1
	cmp	#1
	beq	write_byte1
	cmp	#2
	beq	convert_byte1
	rts
cls_byte1:
	lda	msktbl1,x
	eor	#0ffh
	and	a1
	sta	(intc),y
	rts
write_byte1:
	lda	msktbl1,x
	ora	a1
	sta	(intc),y
	rts
convert_byte1:
	lda	msktbl1,x
	eor	a1
	sta	(intc),y
	rts

;--------------------------------------
; input: intc Yreg lcmd
; output: (intc)
;--------------------------------------
put_byte:
	lda	lcmd
	beq	cls_byte
	cmp	#1
	beq	write_byte
	cmp	#2
	beq	convert_byte
	rts

cls_byte:
	lda	#0
	sta	(intc),y
	rts
write_byte:
	lda	#0ffh
	sta	(intc),y
	rts
convert_byte:
	lda	#0ffh
	eor	(intc),y
	sta	(intc),y
	rts

;-----------------------------------------------------------------
;	draw square frame line
; input: x0,x1,y0,y1
; output: (intc)
;-----------------------------------------------------------------
square_draw:
	;; x0,y0,x0,y1
  	lda     x1
        pha
        lm      x1,x0
        jsr     line_draw
        pla
        sta     x1
	;; x0,y0,x1,y0
        lda     y1
        pha
        lm      y1,y0
        jsr     line_draw
        pla
        sta     y1
	;; x1,y1,x0,y1
        lda     y0
        pha
        lm      y0,y1
        jsr     line_draw
        pla
        sta     y0
	;; x1,y1,x1,y0
        lda     x0
        pha
        lm      x0,x1
        jsr     line_draw
        pla
        sta     x0
        rts

;-----------------------------------------------------------------
;	input:	 x0,y0,x1,y1
;	output:	 lcdbuf_ptr
;	change:	 y0back
;-----------------------------------------------------------------
block_draw:
	lda	y0
	sta	y0back
	lda	y1
	pha

	lda	y0
	sta	y1
	jsr	set_write_var
block_loop:
	jsr	hline0
	pla
	cmp	y0
	beq	block_rts
	pha

	inc	y1
	inc	y0
	lda	#CPR
	adda2	intc
	jmp	block_loop
block_rts:
	lda	y0back
	sta	y0
	rts

;;************************************************************************
;  写屏例程:
;    write_block write_block0 write_block1
; 
; x0 > 0 时使用write_block0
;	此时读 block_data 从头开始读
;	移位时向右,保留头
; x0 <= 0 时使用write_block1
;	此时读 block_data 会从头截取block
;	移位时向左,截取头
;;************************************************************************
;-----------------------------------------------------------------
; write block to (intc)
;
;input:	xy: 坐标
; 	fccode: block data
;output:
;
;destroy:
;;***** r0 是写 scroll_buf 时 byte 总数
;;***** r1 是读 block data 时 byte 总数
;;***** r2 是 begin_address bit position (位移次数)
;;***** r3 是 end_address bit position
;;***** r4 是 block width
;;***** r5 是 block height
;;***** r6 是临时变量
;
;流程:
; 1.首先设置好变量 r0 r1 r2 r3 r4 r5 intc fccode
; 2.然后对每一行
;	2.1.从数据块取本行数据 ==> patbuf
;	2.2.调整 patbuf, 调整行头和行尾 byte
;	2.3.把 patbuf 数据送入显示缓冲区 scroll_buf
;-----------------------------------------------------------------
w_block0:
	sec
	lda	x1
	sbc	x0
	mlsr	a,3
	sta	r4
	inc	r4
	jmp	block0_judge

write_block0:
	txa
	jeq	write_block1

	jsr	set_coordinate
	jcs	write_block_rts
	
block0_judge:
	jsr	judge_xy
	jcs	write_block_rts

	jsr	set_write_var

	;;************* loop each line ************
	;; 1. block_data ==> patbuf
	;; 2. adjust patbuf
	;; 3. patbuf ==> scroll_buf
	;;----------------------------------------
	Distant	y0,y1
	sta	yy
write_block_loop:
	lda	yy
	jeq	write_block_rts
	dec	yy

	;;block data ==> patbuf
	ldy	#0
read_line_loop:
	lda	(fccode),y
	cmp1	lcmd,#6,x
	bne	$+4
	eor	#0ffh
	sta	patbuf,y
	iny
	cpy	r1
	bne	read_line_loop

	;;----------------------------------------
	; 对每一行, patbuf的尾留 1byte 缓冲
	; 以处理不完整的 byte
	; 所以有效的 patbuf的长度为 r0
	;;----------------------------------------
	lda	#0
	sta	patbuf,y

	lm	r6,r2
	beq	adjust_last_byte

	;; 调整 patbuf
right_shift:
	ldy	r0
	ldx	#0
	lsr	patbuf
	dey
	beq	right_shift_next
right_shift_loop:
	inx
	ror	patbuf,x
	dbne	y,right_shift_loop
right_shift_next:
	dbne	r6,right_shift

	;调整行头 byte
	ldx	r2
	dex
	lda	msktbl1,x
	ldy	#0
	and	(intc),y
	ora	patbuf
	sta	patbuf

adjust_last_byte:
	;调整行尾 byte
	ldy	r0
	dey
	lda	patbuf,y
	sta	a1
	lda	(intc),y
	sta	a1h
	ldx	r3
	jsr	merge_byte
	sta	patbuf,y

	;; patbuf ==> scroll_buf
	ldy	#0
write_line_loop:
	lda	patbuf,y
	sta	(intc),y
	iny
	cpy	r0
	bcc	write_line_loop

	lda	r4
	adda2	fccode
	lda	#CPR
	adda2	intc
	jmp	write_block_loop
	;;************* loop each line ************

write_block_rts:
	rts

;-----------------------------------------------------------------
; write_block1 与 write_block 类似
;不同点:
; 1.set coordinate 不同
; 2.shift 方向和次数不同
; 3.bit0是icon,计算时bit0计入,写时忽略
;
;;***** r0 是写 scroll_buf 时 byte 总数
;;***** r1 是读 block data 时 byte 总数
;;***** r2 是 begin_address bit position (位移次数)
;;***** r3 是 end_address bit position
;;***** r4 是 block width
;;***** r5 是 block height
;;***** r6 是临时变量
;-----------------------------------------------------------------
write_block1:
	jsr	set_coordinate1
	jcs	write_block_rts1

	jsr	judge_xy
	jcs	write_block_rts1

	jsr	set_write_var1

	;;************* loop each line ************
	;; 1. block_data ==> patbuf
	;; 2. adjust patbuf
	;; 3. patbuf ==> scroll_buf
	;;----------------------------------------
	Distant	y0,y1
	sta	yy
write_block_loop1:
	lda	yy
	jeq	write_block_rts1
	dec	yy

	;;block data ==> patbuf
	ldy	#0
read_line_loop1:
	lda	(fccode),y
	cmp1	lcmd,#6,x
	bne	$+4
	eor	#0ffh
	sta	patbuf,y
	iny
	cpy	r1
	bne	read_line_loop1

	lm	r6,r2
	beq	adjust_byte1
	;; 调整 patbuf
left_shift:
	ldx	r1
	asl	patbuf-1,x
	dex
	beq	left_shift_next
left_shift_loop:
	rol	patbuf-1,x
	dbne	x,left_shift_loop
left_shift_next:
	dbne	r6,left_shift

adjust_byte1:
	;调整行头 byte
	lda	patbuf
	and	#7fh
	sta	patbuf
	ldy	#0
	lda	(intc),y
	and	#80h
	ora	patbuf
	sta	patbuf

	;调整行尾 byte
	ldy	r1
	dey
	lda	patbuf,y
	sta	a1
	lda	(intc),y
	sta	a1h
	ldx	r3
	jsr	merge_byte
	sta	patbuf,y

	;; patbuf ==> scroll_buf
	ldy	#0
write_line_loop1:
	lda	patbuf,y
	sta	(intc),y
	iny
	cpy	r0
	bcc	write_line_loop1

	lda	r4
	adda2	fccode
	lda	#CPR
	adda2	intc
	jmp	write_block_loop1
	;;************* loop each line ************

write_block_rts1:
	rts

;----------------------------------------
;;**** set (x0,y0) (x1,y1) ****
; x1=x0+width-1
; y1=y0+height-1
;
; in: Xreg,Yreg,fccode
; out: x0,y0  x1,y1 r4,r5
;----------------------------------------
set_coordinate:
	stx	x0
	sty	y0
	ldy	#0
	lda	(fccode),y
	sta	r4
	iny
	lda	(fccode),y
	sta	r5

	lda	x0
	cmp	#HDPS
	bcs	x0_is_flow
	clc
	adc	r4
	sta	x1
	dec	x1

	lda	y0
	clc
	adc	r5
	sta	y1
	dec	y1

	lda	#2
	adda2	fccode
	lda	r4
	jsr	byte_count
	sta	r4

	clc
	rts

x0_is_flow:
	sec
	rts

;----------------------------------------------
; when x0 is minus, plus set fccode
;----------------------------------------------
set_coordinate1:
	stx	x0
	sty	y0
	ldy	#0
	lda	(fccode),y
	sta	r4
	iny
	lda	(fccode),y
	sta	r5

	;x1=width-x0-1
	sub1	r4,x0,x1
	bcc	x1_is_minus
	dec	x1

	lda	x0
	mlsr	a,3
	adda2	fccode
	lda	x0
	and	#7
	sta	r2
	lm	x0,#0

	lda	y0
	clc
	adc	r5
	sta	y1
	dec	y1

	lda	#2
	adda2	fccode
	lda	r4
	jsr	byte_count
	sta	r4

	clc
	rts

x1_is_minus:
	sec
	rts

;---------------------------------------------------------
; 调整 (x0,y0) (x1,y1) fccode
;
; input: (x0,y0) (x1,y1)
; output: (x0,y0) (x1,y1) fccode
;
; 调整位置出错则 sec, 否则 clc
; 出错为图形超出范围,不能显示在lcd上,
;
;参数范围:
; 原始坐标为直角坐标体系, 可以是:负数 0 正数
; x坐标的正负分别调用不同 write_block, x坐标为绝对值
; y坐标的正负用最高位表示
; 0 时认为是正数
;
; 调整前坐标范围如下:
; x0: 不能 >= 160 , 为 <160 正数 0 负数
; x1: 不能 < 0, 为正数 0
; y0: 不能 >= 80
; y1: 不能 < 0
; 调整后坐标范围如下:
;	x: 0--159 y:0--79
;
; 检查合法性时分两步,
; 	1.set_coordinate 时检查x 
;	2.judge_xy 时检查y
;bug:
; if(y1 > 127), then y1 considered minus
; that means y0+block_height cant above 127
;---------------------------------------------------------
judge_xy:
	lda	y0
	bmi	check_y1
	cmp	#VDPS
	bcs	judge_err
check_y1:
	lda	y1
	bmi	judge_err

	lda	x0
	jsr	judge_x
	sta	x0

	lda	x1
	jsr	judge_x
	sta	x1

	lda	y0
	jsr	judge_y
	sta	y0

	lda	y1
	jsr	judge_y
	sta	y1

	clc
	rts

judge_err:
	sec
	rts

;--------------------------------
judge_x:
	cmp	#HDPS
	bcs	x_max
	rts
x_max:
	lda	#HDPS-1
	rts

;--------------------------------
; Areg: -80 -- 80
;--------------------------------
judge_y:
	bmi	y_min
	cmp	#VDPS
	bcs	y_max
	rts

y_min:
	eor	#0ffh
	clc
	adc	#1
	ldx	r4
	jsr	mul_ax
	add	fccode,a1
	lda	#0
	rts

y_max:
	lda	#VDPS-1
	rts

;-----------------------------------------------------------------
; 设置 scroll_buf 参数 r0 r1 r2 r3 intc
; r0 >= r1
; input: x0 x1 y0 y1
; output: r0 r1 r2 r3 intc
;-----------------------------------------------------------------
set_write_var:
	lda	x0
	and	#7
	sta	r2
	lda	x1
	and	#7
	sta	r3

	Distant	x0,x1
	sta	xx
	jsr	byte_count
	sta	r1

	lda	xx
	clc
	adc	r2
	jsr	byte_count
	sta	r0

	ldx	x0
	ldy	y0
	jsr	byte_addr	;intc: byte_address
	rts


;-----------------------------------------------------------------
; 设置 scroll_buf 参数 r0 r1 r2 r3 intc
; r1 >= r0
; input: x0 x1 y0 y1
; output: r0 r1 r2 r3 intc
;-----------------------------------------------------------------
set_write_var1:
	lda	x1
	and	#7
	sta	r3

	Distant	x0,x1
	sta	xx
	jsr	byte_count
	sta	r0

	lda	xx
	clc
	adc	r2
	jsr	byte_count
	sta	r1

	ldx	x0
	ldy	y0
	jsr	byte_addr	;intc: byte_address
	rts

;----------------------------------------
; input:  Xreg(起始行0---79,Yreg(共清几行)
; output: lcdbuf_ptr
;========================================
clear_nline:
	txa
	asl	a
	tax
	lm20x	intc,lcd_start_addr_tbl
	add	intc,lcdbuf_ptr

	tya
	tax
cl_loop1:
	ldy	#0
	lda	#0
cl_loop2:
	sta	(intc),y
	iny
	cpy	#CPR
	bcc	cl_loop2
	lda	#CPR
	adda2	intc
	dbne	x,cl_loop1
	rts

clear_nline2:
	txa
	asl	a
	tax
	lm20x	intc,lcd_start_addr_tbl
	add	intc,lcdbuf_ptr

	tya
	tax
cl2_loop1:
	ldy	#0
	lda	(intc),y
	and	#40h
	sta	(intc),y
	iny
	lda	#0
cl2_loop2:
	sta	(intc),y
	iny
	cpy	#CPR-1
	bcc	cl2_loop2
	lda	(intc),y
	and	#1
	sta	(intc),y
	lda	#CPR
	adda2	intc
	dbne	x,cl2_loop1
	rts
;;************************************************************************
;; 通用例程
;;************************************************************************

;-----------------------------------------------------------------
;	把象素长度转换为 byte 数量
; Areg = (Areg-1)/8+1	Lee for 4 color A=(A+3)/4
; input: Areg
; output: Areg
;-----------------------------------------------------------------
byte_count:
	tax
	dex
	txa
	mlsr	a,3
	tax
	inx
	txa
	rts

;-----------------------------------------------------------------
;	把象素坐标转换为 byte 位置
;   intc = (y*CPR) + x/4
; input: (x,y) lcdbuf_ptr
; output: intc
; destroy: Areg
;-----------------------------------------------------------------
byte_addr:
	tya
	pha
	asl	a
	tay
	lda	lcd_start_addr_tbl,y
	sta	intc
	lda	lcd_start_addr_tbl+1,y
	sta	intc+1

	txa
	mlsr	a,3
	adda2	intc

	add	intc,lcdbuf_ptr
	pla
	tay
	rts

;------------------------------------------------------------
;	merge (a1 a1h) to one byte
; Areg = a1(bit0-bitx) + a1h(bit(x+1)-bit7)
;
; input: a1 a1h x(0-7):a1 remaider pos
; output: Areg
; destory: a1 Areg
;------------------------------------------------------------
merge_byte:
	lda	msktbl1,x
	and	a1
	sta	a1
	lda	msktbl1,x
	eor	#0ffh
	and	a1h
	ora	a1
	rts

msktbl: 	db	80h,40h,20h,10h,08h,04h,02h,01h
msktbl1:	db	080h,0c0h,0e0h,0f0h,0f8h,0fch,0feh,0ffh

;---------------------------------------------------------------
	end
