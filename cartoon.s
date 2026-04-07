;;******************************************************************
;;	cartoon.s -
;;
;调用方示:	ldxy	#carton_tbl
;		jsr	cartoon
;
;;******************************************************************

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;说明: cartoon 动画显示程序,分别显示分立图案
;input: XregYreg 动画数据
;
; 	db	方映方式	b7:1 按键可中断 0:no
;				b6:1 ESC键中断 0:任何键中断
;				b5~b0: 循环次数,0时次数无限
;	db	x0,y0
;	dw	图片address
;		  .
;		  .
;	db	0ffh	结束符
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	include	h/rom.h
	include	h/mud_funcs.h

	public	cartoon


END_MARK	equ	0ffh
BLANK_MARK	equ	0feh
DELAY_TIME	equ	120

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; input: Xre Yreg
;; output: cy (clc: 图画正常结束 sec: 按键中断)
;; destroy: menu_ptr menu_offset menu_item
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
cartoon:
	stxy	menu_ptr
	ldy	#0
	sty	menu_offset
	lda	(menu_ptr),y
	sta	menu_item		;init

	jsr	init_img
	jsr	block_clear
	;
cartoon_cartoon:
	jsr	init_img
	lda	x0
	cmp	#END_MARK
	bne	cartoon_continue	
	;
	ldy	#0
	lda	(menu_ptr),y
	and	#00111111b
	bne	cartoon_dec
	lm	menu_offset,#0
	beq	cartoon_cartoon

cartoon_dec:
	dec	menu_item		;循环次数减一
	lda	menu_item
	and	#00111111b
	beq	cartoon_end
	lm	menu_offset,#0
	beq	cartoon_cartoon

cartoon_end:				;如顺序放
	dec	menu_offset
	jsr	init_img
	jsr	block_clear
	clc
	rts
	;
cartoon_continue:

	ldx	x0
	ldy	y0
	BREAK_FUN	_Bwrite_block

	lm	watch_dog_timer_flag,#0
	lm	down_time,#DELAY_TIME
delay_loop:
	lda	down_time
	beq	delay_end
	lda	key
	bpl	delay_loop
	and	#7fh
	sta	key

	bit	menu_item
	bpl	delay_loop
	lda	key
	cmp	#ESC_KEY
	beq	is_esc_key
	bit	menu_item
	bvs	delay_loop

is_esc_key:
	jsr	init_img
	jsr	block_clear
	sec
	rts

delay_end:
	jsr	init_img
	jsr	block_clear
	inc	menu_offset
	jmp	cartoon_cartoon

;---------------------------------------------------------
; input: fccode x0 y0
;---------------------------------------------------------
block_clear:
        ldy     #0
        lda     (fccode),y
        clc
        adc     x0
        sta     x1
        dec     x1
        iny
        lda     (fccode),y
        clc
        adc     y0
        sta     y1
        dec     y1

        push    lcmd
        lm      lcmd,#0
        BREAK_FUN	_Bblock_draw
        pull    lcmd
        rts

;---------------------------------------------------------
; input: menu_offset
; output: fccode x0 y0
;---------------------------------------------------------
init_img:
	lda	menu_offset
	asl	a
	asl	a
	tay
	iny				;得到显示画面序号
	lda	(menu_ptr),y
	sta	x0
	cmp	#END_MARK
	beq	init_img_rts
	iny
	lda	(menu_ptr),y
	sta	y0
	cmp	#END_MARK
	beq	init_img_rts

	iny
	lda	(menu_ptr),y
	sta	fccode
	iny
	lda	(menu_ptr),y
	sta	fccode+1

init_img_rts:
	rts

;-----------------------------------------------------------------------
	end
