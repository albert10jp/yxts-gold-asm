;;******************************************************************
;;	hello.s - bank3 perform entry
;;
;;	written by lian
;;******************************************************************
	include	h/a.h
	include	h/gmud.h
	include	h/id.h

	public	perform
	extrn	show_man_busy

;****************************************************************

;------------------------------------------------------------------
; input: perform_id
; output: 
;------------------------------------------------------------------
perform:
	ldy	#BUSY_OFF
	lda	(obj_ptr),y
	jne	show_man_busy

	lda	perform_id
	asl	a
	tax
	lm20x	a1,perform_tbl
	jmp	(a1)


perform_tbl:
	DEF_BREAK_FUN	daoying_gua
	DEF_BREAK_FUN	daoying_zhen
	DEF_BREAK_FUN	zhangdao_gua
	DEF_BREAK_FUN	zhangdao_zhen
	DEF_BREAK_FUN	luoying
	DEF_BREAK_FUN	liulang
	DEF_BREAK_FUN	sanhua
	DEF_BREAK_FUN	feizhi
	DEF_BREAK_FUN	honglian
	DEF_BREAK_FUN	leidong
	DEF_BREAK_FUN	fenshen
	DEF_BREAK_FUN	yianmu
	DEF_BREAK_FUN	lianzhan
	DEF_BREAK_FUN	yidao
	DEF_BREAK_FUN	chan
	DEF_BREAK_FUN	lian
	DEF_BREAK_FUN	taoyue
	DEF_BREAK_FUN	ji
	DEF_BREAK_FUN	luanhuan
	DEF_BREAK_FUN	yinyang
	DEF_BREAK_FUN	zhen
	DEF_BREAK_FUN	bingxin
	DEF_BREAK_FUN	liuchu
	DEF_BREAK_FUN	shengui

my_rts:
	rts

;------------------------------------------------------------------
	end
