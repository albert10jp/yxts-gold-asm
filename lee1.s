	include	h/gmud.h
	include	h/func.mac
	include	h/id.h
	
	public	show_text	
	public	dazuo
	public	recover
	public	heal
	public	jiali

	extrn	format_string
	extrn	clear_nline
	extrn	show_string
	extrn	query_skill
	extrn	divid2
	extrn	divid_ax
	extrn	mul2
	extrn	mul_ax
	extrn	divid42
	extrn	scroll_to_lcd
	extrn	input_digit

__base	equ	game_buf			;网络对战用
	define	1,net_game_version
	define	1,net_quit_flag
	define	1,net_msg_vision
	define	1,net_limb_flag
	define	1,net_repeat
	define	1,net_perform_flag
__base	equ	game_buf+30
	define	4,tmp_attack_point
	define	4,tmp_dodge_point
;------------------------------
__base	equ	game_buf+56			;共200个字节
	define	2,neili_cost
	define	1,set_kf
	define	2,set_level
	define	1,temp_data
	define	1,temp_delay
	define	1,temp_position
	define	1,temp_data_2
	define	1,temp_position_2
	define	2,perform_temp1
	define	2,perform_temp2
	define	2,perform_temp3
	define	2,perform_temp4
	;pyh:2001/11/05
	define	2,perform_temp5
	define	2,perform_temp6
	define	2,perform_temp7
	define	2,perform_temp8
	define	4,perform_data			;30个字节
	;pyh:2001/11/05
	;define	PTEMP_SIZE,ptemp		;120个字节
	;define	NPC_PTEMP_SIZE,npc_ptemp	;40个字节

MAN_FP_Y0	equ	44
	
show_text:
	ldy	#0
show_text_1:
	lda	(a9),y
	sta	img_buf,y
	iny	
	cpy	#200
	bcc	show_text_1
	lm2	string_ptr,#img_buf
	
	jsr	format_string
	CLS_NLINE	#MAN_FP_Y0-2,#80-MAN_FP_Y0+2

	ldx	#0
	ldy	#80-12*3
	lda	#3
	jsr	show_string
	extrn	waittime
	extrn	delay_1_sec
	ldx	#100
	jsr	waittime
	jsr	delay_1_sec
	rts

;***************************
;	疗伤
;***************************
common:
	smb7	obj_flag
	lm2	obj_ptr,#man_state
	rts

heal:
	jsr	common
	lda	man_usekf+3
	jpl	heal_noenable_force
	
	lm	kf_type,#FORCE_KF 
	jsr	query_skill			;o: skill_level

	;内功的有效等级要大于45
	cmp2	skill_level,#45			
	jcc	heal_no_level				

	;判断最大内力是否够用
	cmp2	man_maxfp,#150
	jcc	heal_noenough_maxneili

	;判断有效内力是否够用
	cmp2	man_fp,#100
	jcc	heal_noenough_neili
	
	;是否受伤
	cmp2	man_effhp,man_maxhp
	jeq	heal_no_hurt

	;是否受伤过重
	lm2	a1,man_maxhp
	lm2	a2,#3
	jsr	divid2		;output:a1
	cmp2	man_effhp,a1
	jcc	heal_bad_hurt


	;作判断,是否在战斗中
	;xxxx
	;
	;


	;显示信息,(你全身放松,坐下来开始运功疗伤.)
	lm2	a9,#heal_sucess_msg
	jsr	show_text

	;算法(perform_kf_level/5)+10	;healgain
	;heal_gain = 10 + (int)me->query_skill("force")/5 

	;需要的差值
	sub	man_maxhp,man_effhp,perform_temp1	
	lda	perform_temp1
	ora	perform_temp1+1
	jeq	heal_4					

	lm2	a1,skill_level
	lm2	a2,#5
	jsr	divid2		;output:a1
	lda	#10
	adda2	a1

	;if(a1>perform_temp1)	a1=perform_temp1	
	cmp2	a1,perform_temp1			
	bcc	heal_2
	lm2	a1,perform_temp1
heal_2:
	add	man_effhp,a1
heal_3:
	sub	man_fp,#50
	
	;显示信息
	lm2	a9,#heal_over_msg
	jsr	show_text
	jsr	scroll_to_lcd
	sec
	rts
heal_4:
	lm2	a9,#heal_noeff_msg
	jsr	show_text

	lm2	a9,#heal_noeff_msg1
	jsr	show_text

	clc	
	rts
;--------------------------------
heal_noenable_force:
	lm2	a9,#heal_enable_msg
	jmp	heal_fail
heal_noenough_maxneili:
	lm2	a9,#heal_maxneili_msg
	jmp	heal_fail
heal_noenough_neili:
	lm2	a9,#not_neili_msg
	jmp	heal_fail
heal_no_hurt:
	lm2	a9,#heal_nohurt_msg
	jmp	heal_fail
heal_bad_hurt:
	lm2	a9,#heal_badhurt_msg
	jmp	heal_fail
heal_no_level:
	lm2	a9,#heal_level_msg
	jmp	heal_fail
dazuo_no_level:
	lm2	man_fp,man_maxfp
	lm2	a9,#dazuo_level_msg
heal_fail:
	jsr	show_text
	jsr	scroll_to_lcd
	sec
	rts

;*************************
;	吸气(内功)
;*************************
;hp的上限不能超过3276,因为有effhp*20 < 65535的限制
recover:
	jsr	common
	lda	man_usekf+3
	jpl	heal_noenable_force
recover_patch:

	lm	kf_type,#FORCE_KF
	jsr	query_skill

	;内力是否够用
	ldy	#FP_OFF
	jsr	get_obj_data
	cmp2	perform_data,#20
	jcc	recover_no_neili
	
	;forceneed=(keeneed*20/(10+skill/15))+1
	lm2	a1,skill_level
	lm2	a2,#15
	jsr	divid2		;output:a1
	lda	#10
	adda2	a1
	lm2	perform_temp1,a1	;save

	;keeneed=man_effhp - man_hp
	ldy	#EFFHP_OFF
	jsr	get_obj_data
	lm2	perform_temp5,perform_data

	ldy	#HP_OFF
	jsr	get_obj_data
	lm2	perform_temp6,perform_data

	sub	perform_temp5,perform_temp6,perform_temp2
	lm2	a1,perform_temp2
	lm2	a2,#20
	jsr	mul2			;output:a1,a1h
	lm2	a2,perform_temp1
	jsr	divid2		;outpu:a1
	lm2	perform_temp3,a1
	lda	#1
	adda2	a1

	;if(neili_cost>man_fp) 	neili_cost=man_fp
	lm2	neili_cost,a1
	ldy	#FP_OFF
	jsr	get_obj_data
	cmp2	neili_cost,perform_data
	bcc	recover_1
	lm2	neili_cost,perform_data
recover_1:
	cmp2	perform_temp2,#0
	jeq	recover_hp_full

	;receive_heal=forceneed*(10+skill/15)/20
	lm2	a2,perform_temp1
	lm2	a1,neili_cost		;neili_cost=forceneed
	jsr	mul2			;output:a1
	lm2	a2,#20
	jsr	divid2		;output:a1
	ldy	#HP_OFF
	jsr	get_obj_data
	add	perform_data,a1
	lm2	perform_temp5,perform_data

	ldy	#EFFHP_OFF
	jsr	get_obj_data
	cmp2	perform_temp5,perform_data	;pyh	7-25
	bcc	recover_2			
	lm2	perform_temp5,perform_data
recover_2:
	lm2	perform_data,perform_temp5
	ldy	#HP_OFF
	lda	#2
	jsr	set_obj_data
	
	jsr	sub_obj_fp
	
	lm2	a9,#recover_over_msg
	jsr	show_text
	
	sec					;pyh	7-25
	rts
;-------------------------
recover_no_neili:
	lm2	a9,#not_neili_msg
	jmp	recover_fail
recover_hp_full:
	lm2	a9,#recover_hp_msg
recover_fail:
	jsr	show_text
	sec
	rts

;************************************
;	加力子程序
;************************************
jiali:
	jsr	common
	ldx	#FORCE_KF
	lda	man_usekf,x
	jpl	heal_noenable_force

	lm	kf_type,#FORCE_KF
	jsr	query_skill
	lm2	a2,skill_level
	lsr2	a2
	lm2	a1,man_force
	ldx	#53
	ldy	#44
	jsr	input_digit
	cmp2	a1,a2
	bcs	jiali_1
	lm2	man_force,a1
jiali_rts:
	rts
jiali_1:
	lm2	man_force,a1
	lm2	a9,#jiali_flow_msg
	jsr	show_text
	rts

;*****************************
;	打坐
;*****************************
dazuo:
	jsr	common
	;force_gain(a8)=int/5+eff_lvl/10
	ldx	#FORCE_KF
	lda	man_usekf,x
	jpl	heal_noenable_force

	lm	kf_type,#FORCE_KF
	jsr	query_skill
	lda	skill_level
	ora	skill_level+1
	jeq	dazuo_no_level

	lm2	a1,skill_level
	lm2	a2,#10
	jsr	divid2
	lm2	a8,a1
	lda	man_con
	ldx	#5
	jsr	divid_ax
	adda2	a8

	lm2	a1,man_maxfp
	asl2	a1
	cmp2	man_fp,a1
	bcs	to_inc

	add	man_fp,a8
	jmp	dazuo_rts
to_inc:
	;(MAXFP)=有效内功等级*10 + 先天根骨*(年龄-14)+EXP/1000 
	lm2	a1,skill_level
	lm2	a2,#10
	jsr	mul2
	lm2	a8,a1
	lda	man_age
	cmp	#60
	bcc	$+4
	lda	#60
	sec
	sbc	#14
	ldx	attr_con
	jsr	mul_ax
	add	a8,a1
	move	man_exp,a1,#4
	lm2	a3,#1000
	jsr	divid42
	add	a8,a1

	cmp2	man_maxfp,a8
	jcs	dazuo_no_level

	inc2	man_maxfp
	lm2	man_fp,#0

dazuo_rts
	clc
	rts
	
;********************************
;	取人或NPC的data
;	input:y
;	output: perform_data(4bytes)
;********************************
get_obj_data:
	ldx	#0
get_obj_loop:
	lda	(obj_ptr),y
	sta	perform_data,x
	inx
	iny
	cpx	#4
	bcc	get_obj_loop
	rts

set_obj_data:
	sta	perform_temp8
	ldx	#0
set_obj_loop:
	lda	perform_data,x
	sta	(obj_ptr),y
	inx
	iny
	cpx	perform_temp8
	bcc	set_obj_loop
	rts

;********************************
;	减去内力,
;	input:neili_cost
;********************************
sub_obj_fp:
	ldy	#FP_OFF
	jsr	get_obj_data
	sub	perform_data,neili_cost
	php
	bcs	sub_obj_fp1
	lm2	perform_data,#0
sub_obj_fp1:
	ldy	#FP_OFF
	lda	#2
	jsr	set_obj_data
	plp
	rts

;----------------------------------------------------------------------------
	if	scode
heal_enable_msg:
	db	'$N必须先选择$N要用的内功心法.',0
	db	0
heal_sucess_msg:
	db	'$N全身放松,坐下来开始运功疗伤.',0
	db	0
heal_over_msg:
	db	'$N摧动真气,脸上一阵红一阵白,哇的一声吐出一口淤血,脸色看起来好多了.',0
	db	0
heal_noeff_msg:
	db	'过了好久好久,$N经过运功疗伤,感觉到所有的伤都好了!',0
	db	0
heal_noeff_msg1:
	db	'$N运功完毕,精神焕发地站起身来.',0
	db	0
heal_maxneili_msg:
	db	'$N的真气不够,不能用来疗伤.',0
	db	0
heal_nohurt_msg:
	db	'$N并没有受伤.',0
	db	0
heal_badhurt_msg:
	db	'$N已经受伤过重,只怕一运真气便有生命危险.',0
	db	0
heal_level_msg:
	db	'$N运功良久,一抖衣袖,长叹一声站起身来.',0
	db	0
dazuo_level_msg:
	db	'$N的内功等级不够!',0,0
jiali_flow_msg:
	db	'你目前加力上限为',2
	dw	man_force,0
	db	0
not_neili_msg:
	db	'$N的内力不够.',0
	db	0
recover_over_msg:
	db	'$N深深吸了几口气,脸色看起来好多了.',0
	db	0
recover_hp_msg:
	db	'$N现在体力充沛.',0
	db	0

	else
heal_enable_msg:
	db	'$Nゲ斗匡拒$N璶ノずみ猭.',0
	db	0
heal_sucess_msg:
	db	'$Nō猀,Гㄓ秨﹍笲励端.',0
	db	0
heal_over_msg:
	db	'$N篟笆痷,羪皚皚フ,珃羘睯﹀,羪︹癬ㄓ.',0
	db	0
heal_noeff_msg:
	db	'筁,$N竒筁笲励端,稰谋┮Τ端常!',0
	db	0
heal_noeff_msg1:
	db	'$N笲Ч拨,弘坟祇癬ōㄓ.',0
	db	0
heal_maxneili_msg:
	db	'$N痷ぃ镑,ぃノㄓ励端.',0
	db	0
heal_nohurt_msg:
	db	'$N⊿Τ端.',0
	db	0
heal_badhurt_msg:
	db	'$N竒端筁,┤笲痷獽Τネ㏑繧.',0
	db	0
heal_level_msg:
	db	'$N笲▆,л︾砈,鼓羘癬ōㄓ.',0
	db	0
dazuo_level_msg:
	db	'$Nず单ぃ镑!',0,0
jiali_flow_msg:
	db	'ヘ玡',2
	dw	man_force,0
	db	0
not_neili_msg:
	db	'$Nずぃ镑.',0
	db	0
recover_over_msg:
	db	'$N瞏瞏,羪︹癬ㄓ.',0
	db	0
recover_hp_msg:
	db	'$N瞷砰↘.',0
	db	0
	endif

	end
