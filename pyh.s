;******************************************************************
;
;	pyh.s - skill practice
;
;	written by:  pyh		2001/06/25
;
;				modify:	2001/08/20
;
;;*******************************************************************


	include	h/gmud.h
	include	h/id.h
	include	h/mud_funcs.h

	public	pyh_practice
	public	pyh_learn

	extrn	show_text
	extrn	mul2
	extrn	mul4
	extrn	mul_ax
	extrn	divid42
	extrn	divid_ax
	extrn	random_it
	extrn	clear_nline
	extrn	find_kf
	extrn	check_skill
	extrn	improve_skill
	extrn	scroll_to_lcd
	extrn	message_box_for_pyh

__base	equ	game_buf
	define	1,tmp1
;-----------------
DIE_DELAY	equ	5
START_LINE	equ	30

__base	equ	game_buf+200
 	define	1,learn_flag	
	define	2,add_point
	define	2,learn_score
	define	2,skill_score
	define	2,learn_time
	define	2,learn_pot	
	define	1,learn_force_lvl
	define	1,my_skill
	define	1,master_skill
	define	2,learn_temp1
	define	2,learn_temp2
	define	2,learn_temp3
	define	2,learn_temp4

;*******************************************
; 练习高级功夫
; input:pra_kf_id,pra_kf_lvl;pra_kf_score
; output:pra_kf_lvl,pra_kf_score
;
;变量复用:
;	define	1,learn_flag		,practice_flag
;	define	2,add_point
;	define	2,learn_score
;	define	2,skill_score
;	define	2,learn_time
;	define	2,learn_pot	
;	define	1,learn_force_lvl
;	define	1,my_skill		,practice_kf
;	define	1,master_skill		,basic_kf
;	define	2,learn_temp1
;	define	2,learn_temp2
; 	 cy=0 (sucess) cy=1 (fail)
;*******************************************
;将内力的影响作为一个判断条件		pyh	9-18
pyh_practice:
	;受伤不能练习
	cmp2	man_effhp,man_maxhp
	jne	you_hurt

	;相应的兵器不对应不能练习
	lda	kf_id
	jsr	find_kf
	lda	man_kf+1,y
	sta	my_skill
	
	lda	kf_id
	jsr	check_skill
	bcs	special_lvl
	cmp	#0
	jeq	no_basic_kf
	cmp	#1
	jeq	no_weapon
	rts			;just in case

special_lvl:
	;得到基本功夫等级
	jsr	find_kf	;A = basic_kf_id
	lda	man_kf+1,y
	sta	master_skill
	;基本功夫低于最高功夫则不能练习
	cmp	my_skill
	jcc	no_enough_basic

	jsr	cal_exp
	;比较当前的exp,小于返回
	cmp4	man_exp,a1
	jcc	no_enough_exp

	;判断有效等级乘以10是否大于最大内力
	lm21	a1,my_skill
	lda	master_skill
	lsr	a
	adda2	a1
	lm2	a2,#10
	jsr	mul2
	cmp2	man_maxfp,a1
	jcc	no_enough_maxfp

	;一次可以得到的点数basic/5 + 1
	lda	master_skill
	ldx	#5
	jsr	divid_ax
	clc
	adc	#1
	sta	a1
	lm	a1h,#0
	jsr	improve_skill
	bcc	pra_rts

	lm2	a9,#up_msg
	jsr	show_text
	jsr	scroll_to_lcd
pra_rts:
	clc
	rts

;-----------------
no_basic_kf:
	lm2	a9,#no_basic_msg
	jmp	fail_rts
no_weapon:
	lm2	a9,#no_weapon_msg
	jmp	fail_rts
no_enough_exp:
	lm2	a9,#exp_msg
	jmp	fail_rts
no_enough_basic:
	lm2	a9,#basic_low_msg
	jmp	fail_rts
no_enough_maxfp:
	lm2	a9,#maxfp_msg
	jmp	fail_rts
you_hurt:
	lm2	a9,#hurt_msg
fail_rts:
	jsr	show_text
	lm	learn_flag,#0
	sec
	rts

;----------------------------------------
;	input: my_skill
;	output: a1,a2
;----------------------------------------
cal_exp:
	;计算(skills-1)^3/10
	lda	my_skill
	tax
	jsr	mul_ax
	lm21	a3,my_skill
	jsr	mul2
	lm2	a3,#10
	jsr	divid42
	rts

;****************************************
;	向师傅学习技能
;	input:kf_id,my_skill,a9(master skill level)
;	cy = 0 (success) cy = 1 (fail)
;****************************************
;相应文档 ~/doc/work.txt
;相应变量:
;         learn_flag	正在学习的标志
;	  add_point	每秒钟增加的点数
;	  learn_score	升一级需要的经验点数
;	  skill_score	技能的当前经验数
;         learn_time	升一级需要的时间(秒)
;         learn_pot	每次消耗的潜能点数
;	  learn_force_lvl
;	  learn_my_skill
;	  learn_master_skill
;	  learn_temp1
;	  learn_temp2
pyh_learn:
	lda	game_buf
	sta	master_skill
	;init:  my_skill, skill_score
	lda     kf_id
        jsr 	find_kf
	lda	man_kf+1,y
	sta	my_skill

	;你的功夫大于师傅的功夫则不能学习
	cmp1	master_skill,my_skill
	jcc	you_high_master

	jsr	cal_exp
	;比较当前的exp,小于返回
	cmp4	man_exp,a1
	jcc	no_enough_exp

	lda	man_pot
	ora	man_pot+1
	jeq	learn_no_pot
	dec2	man_pot
	
	cmp1	kf_id,#LITERATE_KF		;pyh	9-11
	jne	patch_9_11

	lm2	learn_temp3,#5
	cmp1	my_skill,#20
	bcc	sub_money
	lm2	learn_temp3,#10
	cmp1	my_skill,#30
	bcc	sub_money
	lm2	learn_temp3,#50
	cmp1	my_skill,#60
	bcc	sub_money
	lm2	learn_temp3,#150
	cmp1	my_skill,#80
	bcc	sub_money
	lm2	learn_temp3,#300
	cmp1	my_skill,#100
	bcc	sub_money
	lm2	learn_temp3,#500
	cmp1	my_skill,#120
	bcc	sub_money
	lm2	learn_temp3,#1000
sub_money:
	lm2	learn_temp4,#0
	cmp4	man_money,learn_temp3
	jcc	learn_no_money
	sub42	man_money,learn_temp3

patch_9_11:
	;1 POT 可转化点数 = [悟性/2 + RANDOM( 悟性 )]/2 + RANDOM(福缘/5)
	lm	learn_temp1,man_int
	lsr	learn_temp1
	lm21	range,man_int
	jsr	random_it
	clc
	adc	learn_temp1
	sta	learn_temp1
	lsr	learn_temp1
	lda	man_kar
	ldx	#5
	jsr	divid_ax
	sta	range
	lm	range+1,#0
	jsr	random_it
	clc
	adc	learn_temp1
	sta	a1
	lm	a1h,#0
	jsr	improve_skill
	bcc	learn_rts

	lm2	a9,#up_msg
	jsr	show_text
	jsr	scroll_to_lcd
	;询问是否继续学习		;pyh	9-7
	lm	x0,#6
	lm	y0,#42
	lm	x1,#6+12*12
	lm	y1,#70
	move	learn_confirm_msg,bank_text,#100
	lm2	string_ptr,#bank_text
	jsr	message_box_for_pyh
	php
	jsr	scroll_to_lcd
	plp
	bcc	learn_rts
	sec
	rts
learn_rts:
	clc
	rts

learn_no_pot:
	lm2	a9,#learn_pot_msg
	jmp	fail_rts
learn_no_money:
	lm2	a9,#learn_money_msg
	jmp	fail_rts
you_high_master:
	lm2	a9,#skill_high_msg
	jmp	fail_rts

;----------------------------------------msg data
	if	scode
basic_kf_msg:
	db	'基本功夫不能练习,只能通过学习提高.',0,0
no_basic_msg:
	db	'想一步登天,可是你基本功夫还没学会呢',0,0
no_weapon_msg:
	db	'趁手的兵器都没有一把,瞎比划什么',0,0
exp_msg:
	db	'你的武学经验不足,无法领会更深的功夫',0,0
up_msg:
	db	'你的功夫进步了',0,0
basic_low_msg:
	db	'你的功夫很难再有所提高了,还是向师傅请教一下吧',0,0
maxfp_msg:
	db	'你的内力修为不足,要勤修内功',0,0
hurt_msg:
	db	'你受伤了,还是先治疗要紧.',0,0
learn_pot_msg:
	db	'你的潜能已经发挥到极限了',0,0
learn_money_msg:
	db	'没钱读什么书啊,回去准备够学费再来吧',0,0
skill_high_msg:
	db	'你的功夫已经不输为师了,真是可喜可贺呀',0,0
pra_lvl_msg:
	db	'你的技能很难再提高了,还是向师傅请教请教吧.',0,0

learn_confirm_msg	db	'      继续学习吗?',0,0
	else
basic_kf_msg:
	db	'膀セひぃ絤策,硄筁厩策矗蔼.',0,0
no_basic_msg:
	db	'稱˙祅ぱ,琌膀セひ临⊿厩穦㎡',0,0
no_weapon_msg:
	db	'禭も竟常⊿Τр,組ゑぐ',0,0
exp_msg:
	db	'猌厩竒喷ぃì,礚猭烩穦瞏ひ',0,0
up_msg:
	db	'ひ秈˙',0,0
basic_low_msg:
	db	'ひ螟Τ┮矗蔼,临琌畍撑叫毙',0,0
maxfp_msg:
	db	'ずぃì,璶对ず',0,0
hurt_msg:
	db	'端,临琌獀励璶候.',0,0
learn_pot_msg:
	db	'肩竒祇揣伐',0,0
learn_money_msg:
	db	'⊿窥弄ぐ摆,称镑厩禣ㄓ',0,0
skill_high_msg:
	db	'ひ竒ぃ块畍,痷琌尺禤',0,0
pra_lvl_msg:
	db	'м螟矗蔼,临琌畍撑叫毙叫毙',0,0

learn_confirm_msg	db	'      膥尿厩策盾?',0,0
	endif

;---------------------------------------	;pyh 6-25
	end
