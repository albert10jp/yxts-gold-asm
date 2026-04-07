	include	h/gmud.h
	
mingwen	equ	img_buf+5
MINGWEN_LEN	equ	SAVE_SIZE+1

DA_ZI	equ	65533
xxx:
	lda	a1
	eor	#'J'
	sta	my_seed0+1
	lda	a1h
	eor	#'L'
	sta	my_seed1+1
	push2	a2
	push2	a3
	ldy	#0
change_loop:
	jsr	my_random
	lda	mingwen,y
	eor	a3
	sta	mingwen,y
	iny
	cpy	#MINGWEN_LEN
	bcc	change_loop
	pull2	a3
	pull2	a2
	rts	

my_random:
	lm2	a2,#DA_ZI
	jsr	my_mul16
	lda	io_bios_bsw
	asl	a
	lda	a3
	adc	#1
	sta	a3
	bcc	$+12
	inc	a3h
	bne	$+8
	inc	a2
	bne	$+4
	inc	a2h
	lm	my_seed0+1,a3
	lm	my_seed1+1,a3h
	rts

my_mul16:
					;a1xa2,³Ë»ýµÄµÍ16bit->a3
		ldx	#16		;¸ß16bit->a2
		lda	#0
		sta	a3
		sta	a3h
		clc
my_mul16_1:
		rol	a2
		rol	a2h
		bcc	my_mul16_2
		lda	a3
		clc
		adc	a1
		sta	a3
		lda	a3h
		adc	a1h
		sta	a3h
		bcc	$+4
		inc	a2
my_mul16_2:
		dex
		bne	$+3
		rts
		asl	a3
		rol	a3h
		jmp	my_mul16_1
xxx_LEN		equ	$-xxx

secret:
	ldy	#0
	ldx	#KEY_LEN
l_secret:
	lda	xxx,y
	eor	secret_key-1,x
	sta	xxx,y
	dex
	bne	$+4
	ldx	#KEY_LEN
	iny
	cpy	#xxx_LEN
	bcc	l_secret
	rts

secret_key:
	db	'LeePyhGmuD'
KEY_LEN		equ	$-secret_key

