	include	h/gmud.h
	include	h/id.h

	public	query_npc_skill
	public	find_name
	public	get_npc_name
	public	find_npc_kf

	extrn	get_basic_kf
	extrn	get_text_data
	
LEFT_CHAR	equ	4
TOTAL_CHAR	equ	18
HEIGHT_CHAR	equ	5
;--------------------------------------------------------
; input: kf_type
; output: skill_level
;--------------------------------------------------------
query_npc_skill:
	lm2	skill_level,#0
	lda	kf_type
	ora	#80h
	jsr	get_basic_kf
	jsr	find_npc_kf
	bcc	query_rts

	lda	npc_kf+1,y
	lsr	a
	sta	skill_level

	ldy	kf_type
	lda	npc_usekf,y
	bpl	query_rts
	and	#7fh
	jsr	find_npc_kf
	bcc	query_rts

	lda	npc_kf+1,y
	adda2	skill_level
query_rts:
	rts
	
;----------------------------------------------------
; input: Areg (=kf_id)
; output: cy(sec:find, clc:no find) Xreg Yreg
; Destry: 
;----------------------------------------------------
find_npc_kf:
	ldx	#0
	ldy	#0
	cpx	npc_kfnum
	beq	no_find
to_find:
	cmp	npc_kf,y
	beq	find_it
	iny
	iny
	inx
	cpx	npc_kfnum
	bcc	to_find
no_find:
	clc
	rts
find_it:
	sec
	rts
	
;---------------------------------------------------------------
; input: Areg a1
; output: a1
; destroy: Areg Xreg Yreg
;---------------------------------------------------------------
find_name:
	tax
	beq	get_addr_rts
next_item:
	ldy     #0ffh
next_byte:
        iny
        lda     (a1),y
	beq	$+6
        cmp     #0ffh
        bne     next_byte
	iny
	tya
	adda2	a1
        dex
        bne     next_item
get_addr_rts:
	rts
	
;--------------------------------------------------------
; input: Areg(located_id)
; output: a1(name address)
;--------------------------------------------------------
get_npc_name:
	sta	text_id
	lm	text_class,#NPC_NAME
	jsr	get_text_data
	lm2	a1,string_ptr
	rts
