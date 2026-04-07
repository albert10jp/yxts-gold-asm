	include ../prom5/h/ngffs.h
	include	../prom5/h/ndflash.h
	include	../prom5/h/ndflash.mac
	include	h/gmud.h

	public	speed_read
	public	speed_read_2

mon	equ	0
;---------------------------------------------
;快速文件读取
;in: 	SeekOffset(文件位置 0000-ffff)
;	DataBufPtr(缓冲区)
;	DataCount(bytes)
;---------------------------------------------
speed_read_2:
	lm2	DataBufPtr,#data_read_buf
	lm2	DataCount,#2
speed_read:
	ldx	#0aah
	lda	bank_no
	bne	speed_read1
	cmp1	SeekOffset+1,#80h
	bcs	speed_read1
	ldx	#0
speed_read1:
	stx	xor
	lm	FilePtrSize,#0
	lda	SeekOffset+1
	tax
	and	#3fh
	sta	SeekOffset+1
	sub	#SECTORSIZE,SeekOffset,SeekOffset+2
	txa
	and	#1
	sta	SeekOffset+1
	txa
	asl	a
	rol	FilePtrSize
	asl	a
	rol	FilePtrSize
	lda	bank_no
	asl	a
	asl	a
	adc	FilePtrSize
	sta	FilePtrSize
	txa
	lsr	a
	and	#1fh
	sta	pagenum
read_next_16k:
	lda	FilePtrSize		;系统程序最多10 block,所以一个byte 足够
	asl	a
	tax
	lda	my_hotbank,x
	sta	blocknum
	inx
	lda	my_hotbank,x
	sta	blocknum+1
	cmp2	DataCount,SeekOffset+2
	bcc	read_in_16k
	beq	read_in_16k
	push2	DataCount
	lm2	DataCount,SeekOffset+2
	jsr	read_in_16k
	pull2	DataCount
	sub	DataCount,SeekOffset+2
	inc	FilePtrSize
	lm	SeekOffset,#0
	sta	SeekOffset+1
	sta	SeekOffset+2
	sta	pagenum
	lm	SeekOffset+3,#40h
	jmp	read_next_16k
read_in_16k:
	lm	nd_addr_reg,SeekOffset
	jsr	CalNandAddr		;100t		;[blocknum:pagenum]-->address
	php				;2t
	sei				;2t		;disable interrupt

	;Disable_Area_C			;10t		

	Read_Cmd_Enable			;12t		;write read command
	lda	#ND_READ_A
	ldx	SeekOffset+1
	beq	to_pageA
	lda	#ND_READ_B		;2t
to_pageA:	
	sta	ND_IO_PORT		;3t		;

	jsr	Set_Read_Addr		;75t		;write read address

	ife	mon	
	jsr	NandBusyDelay		;;read R/B ???	;need check 
	endif

	Read_Dat_Enable			;12t		

	lda	SeekOffset
	ora	SeekOffset+1
	beq	read_zeng
	sub	#200h,SeekOffset,SeekOffset
	ldy	#0
	cmp2	DataCount,SeekOffset
	bcc	read_other0
	beq	read_other0
	sub	DataCount,SeekOffset
	lda	SeekOffset+1
	beq	read_head_other
read_head256:	
	lda	ND_IO_PORT
	eor	xor
	sta	(DataBufPtr),y
	iny
	bne	read_head256
	inc	DataBufPtr+1
read_head_other:
	ldx	SeekOffset
	beq	read_c0x
read_otherx:	
	lda	ND_IO_PORT
	eor 	xor
	sta	(DataBufPtr),y
	iny
	dex
	bne	read_otherx
	tya
	clc
	adc	DataBufPtr
	sta	DataBufPtr
	bcc	read_c0x
	inc	DataBufPtr+1
read_c0x:	
	jsr	Inc_Read_Addr
read_zeng:	
	ldy	#0
	lda	DataCount+1
	cmp	#2
	bcc	read_other0
read_256:	
	lda	ND_IO_PORT
	eor	xor
	sta	(DataBufPtr),y
	iny
	bne	read_256
	inc	DataBufPtr+1
	dec	DataCount+1
read_256b:	
	lda	ND_IO_PORT
	eor	xor
	sta	(DataBufPtr),y
	iny
	bne	read_256b
	jsr	Inc_Read_Addr
	ldy	#0
	inc	DataBufPtr+1
	dec	DataCount+1
	lda	DataCount+1
	cmp	#2
	bcs	read_256
read_other0:	
	lda	DataCount+1
	beq	read_other1
read_256x:	
	lda	ND_IO_PORT
	eor	xor
	sta	(DataBufPtr),y
	iny
	bne	read_256x
	inc	DataBufPtr+1
read_other1:	
	ldx	DataCount
	beq	read_end
read_other2:	
	lda	ND_IO_PORT
	eor	xor
	sta	(DataBufPtr),y
	iny
	dex
	bne	read_other2
	tya
	clc
	adc	DataBufPtr
	sta	DataBufPtr
	bcc	read_end
	inc	DataBufPtr+1
read_end:

	Nd_Reset
	Nd_Disable			;14t
	plp				;4t
	clc				;2t
	rts				;6t
	
CalNandAddr:					;96t
	lda	#0				;2t
	sta	nd_addr_reg+1			;4t

	lm2	nd_addr_reg+2,blocknum		;16t
	rept	3			;/8 54
	lsr	nd_addr_reg+3			;6t 
	ror	nd_addr_reg+2			;6t
	ror	nd_addr_reg+1			;6t
	endr
	
	lda	pagenum			;nd_addr_reg[4,3,2,1,0];4t
	ora	nd_addr_reg+1			;4t
	sta	nd_addr_reg+1			;4t
	rts					;6t
Set_Read_Addr:				;address input	for read 
	Read_Add_Enable			;12t
	lda	nd_addr_reg		;4t
	sta	ND_IO_PORT		;3t
	lda	nd_addr_reg+1		;4t
	sta	ND_IO_PORT		;3t
	lda	nd_addr_reg+2		;4t
	sta	ND_IO_PORT		;3t
	lda	nd_addr_reg+3
	sta	ND_IO_PORT
	Read_Add_Dis			;12t
	rts
NandBusyDelay:	
	rept	5			;10t
	nop
	endr
	ldy	#10h
	ldx	#0ffh
delay_loop:	;			;(11*256+4)*16t=45120 t  1.226s=1226ms
	lda	ND_CTRL_PORT		;3t
	and	#ND_RB_BIT		;2t
	bne	delay_end		;2t
	dex				;2t
	bne	delay_loop		;2t	
	dey				;2t
	bne	delay_loop		;2t
delay_end:
	rts
Inc_Read_Addr:				;address input	for read 
	Read_Cmd_Enable			;12t		;write read command
	lda	#ND_READ_A
	sta	ND_IO_PORT
	inc	nd_addr_reg+1
	bne	Inc_1
	inc	nd_addr_reg+2
	bne	Inc_1
	inc	nd_addr_reg+3
Inc_1:
	Read_Add_Enable			;12t
	
	lda	#0
	sta	ND_IO_PORT		;3t
	lda	nd_addr_reg+1		;4t
	sta	ND_IO_PORT		;3t
	lda	nd_addr_reg+2		;4t
	sta	ND_IO_PORT		;3t
	lda	nd_addr_reg+3
	sta	ND_IO_PORT
	Read_Add_Dis			;12t
	ife	mon	
	jsr	NandBusyDelay		;;read R/B ???	;need check 
	endif
	Read_Dat_Enable			;12t		
	rts
