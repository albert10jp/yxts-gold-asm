;;******************************************************************
;;	math.s - fix math lib
;;
;;	written by lian
;;*******************************************************************
	include	h/gmud.h

	public	mul10
	public	mul_ax
	public	mul2
	public	mul4
	public	divid_ax
	public	divid2
	public	divid42
	public	divid4
	public	percent
	public	random_it
	public	perform_random_it

	extrn	getms

;------------------------------------------
; a1 = Areg * 10
; i: Areg
; o: a1
;------------------------------------------
mul10:
	pha
	sta	a1
	lm	a1h,#0
	asl2	a1
	asl2	a1
	asl2	a1
	pla
	asl	a
	bcc	$+4
	inc	a1h
	adda2	a1
	rts

;------------------------------------------
; a1 = Areg * Xreg
; d: a1 a2
;------------------------------------------
mul_ax:
	sta	a2
	stx	a2h
	lm2	a1,#0
	ldx	#8
mul_loop:
	asl2	a1
	asl	a2h
	bcc	mul_con
	lda	a2
	adda2	a1
mul_con:
	dbne	x,mul_loop
	lda	a1
	rts

;------------------------------------------
; a1 a2 = a1 * a2
; input: a1 a2
; output: a1 a2(result)
; d: a1 a2 a3 a4
;------------------------------------------
mul2:
	lm2	a3,a1
	lm2	a4,a2
	lm2	a1,#0
	lm2	a2,#0
	ldx	#16
mul2_loop:
	asl2	a1
	rol2	a2
	asl2	a4
	bcc	mul2_con
	add	a1,a3
	bcc	mul2_con
	inc2	a2
mul2_con:
	dbne	x,mul2_loop
	rts

;------------------------------------------
; 四字节乘法
; input: a1 a2 (被乘数)	a3,a4 (乘数)
; output: a1 a2 a3 a4
; d: a1 a2 a3 a4 a5 a6 a7 a8
;------------------------------------------
mul4:
	lm2	a5,a1
	lm2	a6,a2
	lm2	a7,a3
	lm2	a8,a4
	lm2	a1,#0
	lm2	a2,#0
	lm2	a3,#0
	lm2	a4,#0

	ldx	#32
mul4_loop:
	asl2	a1
	rol2	a2

	rol2	a3
	rol2	a4

	asl2	a7
	rol2	a8
	bcc	mul4_con

	add	a1,a5
	lda	a2
	adc	a6
	sta	a2
	lda	a2h
	adc	a6h
	sta	a2h
	bcc	mul4_con
	inc	a3
	bcc	mul4_con
	inc	a3h
	bcc	mul4_con
	inc	a4
	bcc	mul4_con
	inc	a4h
	bcc	mul4_con

mul4_con:
	dbne	x,mul4_loop
	rts

;------------------------------------------
; Areg = Areg / Xreg
; Xreg = remaider
; d: a1 a2
;------------------------------------------
divid_ax:
	sta	a1
	stx	a1h
	lm	a2,#0
	ldx	#8
divid_loop:
	asl	a1
	rol	a
	cmp	a1h
	bcc	divid_con
	sbc	a1h
divid_con:
	rol	a2
	dbne	x,divid_loop
	tax
	lda	a2
	rts

;------------------------------------------
; a1 = a1 / a2
; a2 = remaider
; input: a1(分母) a2(分子)
; output: a1(result) a2(remaider)
; d: a1 a2 a3 a4
;------------------------------------------
divid2:
	lm2	a3,a1
	lm2	a4,a2
	lm2	a1,#0
	lm2	a2,#0
	ldx	#16
divid2_loop:
	asl2	a3
	rol2	a2
	cmp2	a2,a4
	bcc	divid2_con
	sub	a2,a4
divid2_con:
	rol2	a1
	dbne	x,divid2_loop
	rts

;------------------------------------------
; a1 a2 = a1 a2 / a3
; a3 = remaider
; input: a1 a2(分母) a3(分子)
; output: a1 a2 (result) a3(remaider)
; d: a1 a2 a3 a4 a5 a6
;------------------------------------------
divid42:
	lm2	a4,a1
	lm2	a5,a2
	lm2	a6,a3
	lm2	a1,#0
	lm2	a2,#0
	lm2	a3,#0
	ldx	#32
divid42_loop:
	asl2	a4
	rol2	a5
	rol2	a3
	bcs	to_sub42
	cmp2	a3,a6
	bcc	divid42_con
to_sub42:
	sub	a3,a6
	sec
divid42_con:
	rol2	a1
	rol2	a2
	dbne	x,divid42_loop
	rts

;****************************************
;	func:四字节除法
;	input:a1,a2(被除数)a3,a4(除数)
;	output:a1,a2(结果)a3,a4(余数)
;	destory:a1,a2,a3,a4,a5,a6,a7,a8
;****************************************
divid4:
	lm2	a5,a1
	lm2	a6,a2
	lm2	a7,a3
	lm2	a8,a4
	lm2	a1,#0
	lm2	a2,#0
	lm2	a3,#0
	lm2	a4,#0
	ldx	#32
divid4_loop:
	asl2	a5
	rol2	a6
	rol2	a3
	rol2	a4
	cmp4	a3,a7
	bcc	divid4_con
	sec
	lda	a3
	sbc	a7
	sta	a3
	lda	a3h
	sbc	a7h
	sta	a3h
	lda	a4
	sbc	a8
	sta	a4
	lda	a4h
	sbc	a8h
	sta	a4h
divid4_con:
	rol2	a1
	rol2	a2
	dbne	x,divid4_loop
	rts

;************************************************;
; Areg = a1 * 100 / a2
;************************************************;
percent:
	push2	a2
	lm2	a2,#100
	jsr	mul2
	pull2	a3
	jsr	divid42
	lda	a1
	rts

;************************************************;
; 	random set in Areg
; input: range
; output: a1 a1h
;	Areg = a1
;************************************************;
random_it:
	lda	range
	ora	range+1
	beq	divisor_is_0

	if	1
	jsr	getms
	asl	a
	adc	random
	adc	mud_seed
	sta	mud_seed
	lm2	a1,mud_seed
	lm2	a2,#65531
	jsr	mul2
	inc2	a1
	lm2	mud_seed,a1
	endif

	if	0
	jsr	getms
	;lda	random
	adc	mud_seed
	tax
	lda	second_m2
	adc	mud_seed+1
	jsr	mul_ax
	lm2	a3,a1
	lda	second_m2
	adc	mud_seed
	tax
	jsr	getms
	;lda	random
	adc	mud_seed+1
	jsr	mul_ax
	lm2	a2,a3
	lm2	mud_seed,a1
	endif

	lm2	a3,range
	jsr	divid42
	lm	a1h,a3h
	lm	a1,a3
	rts

divisor_is_0:
	lm2	a1,#0
	rts

;************************************************;
;	func:取四字节的随机数
;	input:a7,a8(四字节数)
;	output:a3,a4(四字节随机数)
;************************************************;
perform_random_it:
	jsr	getms
	;lda	random
	adc	mud_seed
	tax
	lda	second_m2
	adc	mud_seed+1
	jsr	mul_ax
	lm2	a4,a1
	lda	second_m2
	adc	mud_seed
	tax
	jsr	getms
	;lda	random
	adc	mud_seed+1
	jsr	mul_ax
	lm2	a3,a1
	lm2	mud_seed,a1

	;a1 a2/a3 a4
	lm2	a1,a3
	lm2	a2,a4
	lm2	a3,a7
	lm2	a4,a8

	jsr	divid4
	rts

;************************************************;
;**   得到Num1,Num2之间均匀分布的一个随机数   ***;
;入口参数:	range(2byte)=Num2(2byte)-Num1(2byte)+1	range<0fffh
;出口参数:	radom_seed(2byte)
;		将 radom_seed>>2+Num1 得到Num1,Num2之间均匀分布的一个随机数
;		init.s中将radom_seed置为3
;		任何时候不可以改动radom_seed中的值
;改变量:	Xreg,Yreg,Areg,不破坏range
;************************************************;
	if	0
random:
	push2	range
	ldx	#0ffh
	clc
log:
	inx
	asl2	range
	bcc	log
	lm2	range,#0
exp:
	ror2	range
	dbne	x,exp			;m=2^( [log2range]+1 )
	;
	asl2	range
	asl2	range			;m*4
	;
	ldxy	radom_seed
	asl2	radom_seed
	asl2	radom_seed
	txa
	clc
	adc	radom_seed
	sta	radom_seed
	tya
	adc	radom_seed+1
	sta	radom_seed+1		;radom_seed*5
	;
get_radom_seed:
	sub	radom_seed,range
	bcs	get_radom_seed
	add	radom_seed,range	;mod(radom_seed*5,m*4)
	;
	pull2	range
	;
	ldxy	radom_seed
	rept	2
	clc
	tya
	lsr	a
	tay
	txa
	ror	a
	tax
	endr
	;
	cpy	range+1
	bne	random_end
	cpx	range
random_end:
	jcs	random
	rts
	endif

;---------------------------------------------------------------
	end
