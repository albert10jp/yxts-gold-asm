	include ../prom5/h/ngffs.h

	public	bank_serve

	extrn	speed_read

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
jmp_serve:
	db	4ch
bank_addr:
	db	1,2
regA:
	db	3
regX:
	db	4
regY:
	db	5
addr_save:
	db	6,7
p_save:
	db	8
number_save:
	db	9
	
bank_serve:
	sta	regA
	stx	regX
	sty	regY
	pla
	sta	addr_save
	pla
	sta	addr_save+1
	inc2	addr_save
	lm	bank_no,#0
	sta	SeekOffset
	lm	SeekOffset+1,#80h	;µÚ¶ş¸öbank
	push2	a1
	lm2	a1,addr_save
	ldy	#0
	lda	(a1),y
	sta	number_save
	bpl	bank_servex
	cmp	#0c0h
	bcc	bank_serve1
	lm	SeekOffset+1,#0e1h
	jmp	bank_servex
bank_serve1:	
	inc	bank_no
	lm	SeekOffset+1,#0c0h
bank_servex:	
	pull2	a1
	lm2	DataBufPtr,#4000h
	lm2	DataCount,#6100h
	lda	number_save
	bpl	bank_servexx
	and	#3fh
	sta	number_save
	lm2	DataCount,#4000h
bank_servexx:	
	jsr	speed_read
	lda	number_save
	asl	a
	tax
	lda	4000h,x
	sta	bank_addr
	lda	4001h,x
	sta	bank_addr+1
	lda	regA
	ldx	regX
	ldy	regY
	jsr	jmp_serve
	sta	regA
	stx	regX
	sty	regY
	php
	pla
	sta	p_save
	lm	bank_no,#0
	sta	SeekOffset
	sta	SeekOffset+1
	lm2	DataBufPtr,#4000h
	lm2	DataCount,#6100h
	jsr	speed_read
	lda	addr_save+1
	pha
	lda	addr_save
	pha
	lda	p_save
	pha
	lda	regA
	ldx	regX
	ldy	regY
	plp
	rts
	
;---------------------------------------------------------------
	end
