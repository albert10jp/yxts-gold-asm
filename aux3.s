	include	h/gmud.h
	include	h/gmud.h
	public	mud_proc_key
;-----------------------------------------------
;	as proc_key
; input: Xreg Yreg a1
; output: cy Yreg
;-----------------------------------------------
mud_proc_key:
	tya
	pha

	txa
	dey
ProcKeyLoop:
	cmp	(a1),y
	beq	ProcLegalKey
	dbpl	y,ProcKeyLoop
	pla
	txa
	clc
	rts

ProcLegalKey:
	pla
	adda2	a1

	txa
	pha			; backup key value

	tya
	asl	a
	tay
	lda	(a1),y
	tax
	iny
	lda	(a1),y
	sta	a1h
	stx	a1

	;------- set index
	dey
	tya
	lsr	a
	tay
	;------- set index

	pla			; restore key value
	tax

	jsr	JmpKeyProc
	sec
	rts

JmpKeyProc:
	jmp	(a1)	;in: Areg Yreg(index)
