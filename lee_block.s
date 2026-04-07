	include	../bbs/bbsa/h/graph.h
	include	h/gmud.h

	public	lee_block

Distant	macro	dx0,dx1
	sec
	lda	dx1
	sbc	dx0
	clc
	adc	#1
	endm
;********************** write_block ******************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
bitblt:
lee_block:
write_graph:
;i:	xy:point print position
; 	fccode,sccode:point data block struct
;       lcmd:	0:clear;	1:print		2: convert
;		3:ora		4:and		5: eor
;data block struct:
;	define	1,Dwidth			;dots
;	define	1,Bhight			;dots
;  width	1 2 3 4 5 6 7 8 9 ...........................
;              |   b_data+2+0  |  b_data+2+1   | b_data+2+width/8-1|
;  bit	       |7 6 5 4 3 2 1 0|7 6 5 4 3 2 1 0|7 6 5 4 3 2 1 0    |
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	stx	x0		;r0 is start x 
	sty	y0		;r0 is start y
	ldy	#0
	lda	(fccode),y
	sta	r3
	clc
	adc	x0
	sta	x1
	iny
	lda	(fccode),y
	clc
	adc	y0
	sta	y1
	dec	x1
	dec	y1
	add	fccode,#2,fccode
	
	lda	r3
	clc
	adc	#7
	lsr	a
	lsr	a
	lsr	a
	sta	r0

w_block:
;	input:	lcmd,x0,y0,x1,y1; fccode,sccode: point to data 
;	output:	lcdbuf
;  	change:	m1l,m1h xx,yy,r0,r1,r2,a3,a3h,r5,r6,r7,Screenbuffer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			;;;;;;;;xf for icon
	lm	r3,#0		
	lda	x0
	cmp	#SEGMENT
	bcc	judge_x
	lda	#0
	sec
	sbc	x0
	tax
	and	#7
	sta	r3
	txa
	lsr	a
	lsr	a
	lsr	a
	adda2	fccode
	lda	#0
	sta	x0
judge_x:
	lda	x1
	cmp	#SEGMENT
	bcc	judge_y0
	lda	#SEGMENT-1
	sta	x1
judge_y0:
	lda	y0
	cmp	#COMMON
	bcc	judge_y
y_fu:
	lda	r0
	adda2	fccode
	inc	y0
	bne	y_fu
judge_y:
	lda	y1
	cmp	#COMMON
	bcc	judge_end
	lda	#COMMON-1
	sta	y1
judge_end:	
			;;;;;;;;xf for icon

	;计算每行的字节数=>r6
	lda	x0		;x0/8
	lsr	a
	lsr	a
	lsr	a
	sta	r6
	lda	x1		;x1/8
	lsr	a
	lsr	a
	lsr	a
	sec
	sbc	r6
	sta	r6		
	inc	r6		;x1/8-x0/8+1
;	lda	x1

	;计算在lcdbuf中的起始位置=>a3
	lm	yy,y0
	lm	xx,x0
	jsr	byte_addr
	move	m1l,a3			;a3,a4(lcdbuf start_addr)

	;计算在lcdbuf中的结束位置=>m1l
	lm	xx,x1
	jsr	byte_addr	;m1l,m1h(start_line of lcdbuf end_addr)

	;计算在结束字节中的位=>r5
	lda	x1
	and	#7
	sta	r5		;x1 所在字节的位

write_block_loop:
	lm	xx,x0
	ldy	#0
	ldx	#0
get_a_line_data_loop:
	;把一行的数据取到wrb_buf,最后补一字节0
	lda	(fccode),y
	sta	wrb_buf,x
	inc2	fccode
	inx
	cpx	r0		;r0 is byte lend of a line
	bne	get_a_line_data_loop

	lda	#0
	sta	wrb_buf,x

	;判断是不是字节开始位置
	lda	xx
	and	#7
	beq	end_right_shift	;it one byte start

	;起始字节中的位=>r1
	sta	r1

	;把图形右移以对齐边界
	lda	#0ffh
	sta	r2
right_shift:
	lsr	r2
	jsr	shift_line
	dbne	r1,right_shift

	sec
	lda	#0ffh
	sbc	r2
	ldy	#0
	and	(a3),y
	ora	wrb_buf	;if add lcmd must change here
	sta	wrb_buf
end_right_shift:
	lda	r3
	beq	end_left_shift
	sta	r1
left_shift0:	
	ldx	r6
left_shift:	
	rol 	wrb_buf,x
	dex
	bpl	left_shift
	dec	r1
	bne	left_shift0
end_left_shift:	

	ldx	r5
	lda	#0ffh
adjust_last:
	lsr	a
	dbpl	x,adjust_last
	ldy	#0
	and	(m1l),y
	ldy	r6
	dey
	ora	wrb_buf,y
	sta	wrb_buf,y
	ldy	#0
write_a_line_data_loop:

			;if add lcmd must change here
	lda	lcmd
	cmp	#3
	bne	if_and
loop_or:	
	lda	(a3),y
	ora	wrb_buf,y
	sta	(a3),y
	iny
	cpy	r6
	bne	loop_or
	jmp	loop_end
if_and:	
	cmp	#4
	bne	if_copy
loop_and:	
	lda	(a3),y
	and	wrb_buf,y
	sta	(a3),y
	iny
	cpy	r6
	bne	loop_and
	jmp	loop_end
if_copy:	
loop_copy:
	lda	wrb_buf,y
	sta	(a3),y
	iny
	cpy	r6
	bne	loop_copy
loop_end:	
	lda	yy
	cmp	y1
	bne	$+3
	rts
	inc	yy
	add	a3,#SEGMENT/8,a3
	add	m1l,#SEGMENT/8,m1l
	jmp	write_block_loop
	rts

shift_line:
	ldx	#0
	lsr	wrb_buf
	php
shift_line_loop:
	inx
	cpx	r6		;x1/8-x0/8+1
	beq	shift_line_rts
	plp
	ror	wrb_buf,x
	php
	jmp	shift_line_loop
shift_line_rts:
	plp
	rts

;;;;;;;;;
;byte addr: LCD_MEMORY+yy*SEGMENT/8 + xx/8
byte_addr:
;	input: (xx,yy)
;	output:m1l(lcdaddr),Areg
;	not change:xx yy
;	change:Xreg
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;lm2	m1l,#lcdbuf	;
	lm2	m1l,#scroll_buf ;
	ldx	#CPR
tmp_loop:
	clc
	lda	yy
	adc	m1l
	sta	m1l
	lda	m1h
	adc	#0
	sta	m1h
	dex
	cpx	#0			;yy*CPR
	bne	tmp_loop

	lda	xx
	mlsr	a,3
	;and	#0fh
	clc
	adc	m1l
	sta	m1l
	lda	#0
	adc	m1h
	sta	m1h
	lda	xx
	and	#7
	tax
	lda	msktbl,x
	rts
msktbl:	db	80h,40h,20h,10h,08h,04h,02h,01h
	rts

	end
