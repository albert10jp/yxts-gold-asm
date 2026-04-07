;;******************************************************************
;;	qlist.s - npc list (in text bank)
;;
;;	written by lian
;;*******************************************************************
	include	h/gmud.h
	include	h/id.h
	include	h/mud_funcs.h

	public	get_all_npc

	extrn	random_it
	extrn	set_read_buf

;---------------------------------------------------------------
;	get all npc from tabel =>img_buf
; input: Areg (=NPC_NUM)
; output: a1
; destroy: a1 a2 a3 a4 a5 a6 a7 img_buf
;---------------------------------------------------------------
get_all_npc:
	sta	a7
	lm	bank_no,#1
	lda	#NPC_EXP
	asl	a
	tay
	lda	txt_class_tbl,y
	sta	bank_data_ptr
	lda	txt_class_tbl+1,y
	sta	bank_data_ptr+1
	lm2	RecordSize,#200h
	lm2	data_buf,#img_buf+800
	jsr	set_read_buf
	ldx	#0
	stx	img_buf
	lm2	a5,#img_buf+800
	lm2	a6,#img_buf+1

get_all_loop:
	;******skip some npc
	txa
	ldy	#SKIP_NUM-1
check_next_npc:
	cmp	skip_npc_tbl,y
	beq	to_next_npc
	dey
	bpl	check_next_npc
	;******skip some npc
	mlsr	a,3
	tay
	lda	npc_stat_buf,y
	sta	a1
	txa
	and	#7
	tay
	lda	a1
	and	msktbl,y
	beq	to_next_npc

	ldy	#0
l_loop:
	lda	(a5),y
	sta	(a6),y	;exp
	iny
	cpy	#4
	bcc	l_loop
	txa
	sta	(a6),y	;id
	inc	img_buf

	lda	#5
	adda2	a6
to_next_npc:
	lda	#4
	adda2	a5
	inx
	cpx	a7
	bcc	get_all_loop

	lm2	a1,#img_buf
	rts

skip_npc_tbl:
	db	NONE_NPC
	db	OLDLADY_NPC
	db	FUREN_NPC
	db	CUNZHANG_NPC
	db	PINGYIZHI_NPC
	db	BUKUAI_NPC
	db	TEACHER_NPC
	db	KILLER_NPC
SKIP_NUM	equ	$-skip_npc_tbl

msktbl:
	db	80h,40h,20h,10h,8,4,2,1
;---------------------------------------------------------------
	end
