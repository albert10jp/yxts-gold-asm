;******************************************
;
;	perform攻击
;
;	writen by pyh	2001/07/21
;	modify by pyh 	2001/11/05
;
;	在程序中一定要保证obj_ptr和you_ptr
;	不变!
;******************************************
	include	h/gmud.h
	include	h/id.h
	include	h/func.mac
	include	h/mud_funcs.h
	include h/perform_id.h

	public	recover

	public	zhangdao_gua	;八卦派
	public	zhangdao_zhen
	public	daoying_gua		
	public	daoying_zhen		

	public	feizhi		;红莲教
	public	honglian
	public	leidong

	public	chan		;太极门
	public	lian
	public	taoyue
	public	ji
	public	luanhuan
	public	yinyang	
	public	zhen

	public	sanhua		;花间派
	public	liulang
	public	luoying

	public	liuchu		;雪山派
	public	shengui	
	public	bingxin

	public	lianzhan	;东瀛忍术
	public	yidao
	public	fenshen
	public	yianmu

	public	call_out	;服务程序
	public	quit_refresh
	public	show_man_busy
;-----------------------------
	extrn	divid2
	extrn	divid4
	extrn	divid42
	extrn	divid_ax
	extrn	mul2
	extrn	mul_ax
	extrn	random_it
	extrn	perform_random_it
	extrn	skill_npc_power
	extrn	scroll_to_lcd
	extrn	find_goods
	extrn	query_skill
	extrn	show_fight_msg
	extrn	attack_npc
	extrn	attack_man
	extrn	query_npc_skill
	extrn	skill_power

	extrn	set_get_buf
	extrn	set_read_buf

;-------------------------------
PTEMP_SIZE	equ	120
NPC_PTEMP_SIZE	equ	40

;------------------------------
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
	define	PTEMP_SIZE,ptemp		;120个字节
	define	NPC_PTEMP_SIZE,npc_ptemp	;40个字节
						;共190个字节,还有10个字节
						
;====================================================
heal_noenable_force:
	lm2	a9,#heal_enable_msg
	jsr	show_text
	jsr	scroll_to_lcd
	sec
	rts

;*************************
;	吸气(内功)
;*************************
;hp的上限不能超过3276,因为有effhp*20 < 65535的限制
recover:
	smb7	net_msg_vision
	
	bit	obj_flag
	bpl	recover_patch
	lda	man_usekf+3
	jpl	heal_noenable_force
recover_patch:

	lm	kf_type,#FORCE_KF
	jsr	query_obj_skill

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
	
	smb7	net_msg_vision	
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

;-----------------------------------------pyh 2001/11/05 作较大修改
;modify judge_kf, judge_force , find_ptemp

;*****************************
;	八卦化掌为刀
;*****************************
zhangdao_gua:

	lm	set_kf,#HUNYUAN_KF
	lm2	set_level,#105
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts
	
	lm	set_kf,#BAGUAZ_KF
	lm2	set_level,#105
	lda	#HAND_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm2	neili_cost,#200
	jsr	judge_force
	jcs	fail1_rts

	lm	perform_temp4,perform_id
	lm	perform_id,#ZHANGDAO2_PF
	jsr	find_ptemp
	jcc	using_perform
	lm	perform_id,perform_temp4
	
	jsr	find_ptemp
	jcc	using_perform

	;sucess
	jsr	sub_obj_fp

	lm2	a9,#zhangdao_sucess_msg
	jsr	show_text

	lm2	a1,skill_level
	lm2	a2,#25
	jsr	divid2
	lm	temp_delay,a1
	ldy	#ATTACK_OFF
	jsr	get_obj_data
	lm	temp_data,perform_data
	lm	temp_position,#1
	lm	temp_position_2,#0
	jsr	set_ptemp

	lm2	a1,skill_level
	lm2	a2,#15
	jsr	divid2
	lda	a1
	ldy	#ATTACK_OFF
	jsr	adc_obj_1byte

	;lm	man_busy,#2
	clc
	rts

;--------------------------

;******************************
;	八阵化掌为刀
;******************************
zhangdao_zhen:

	lm	set_kf,#HUNYUAN_KF
	lm2	set_level,#120
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts
	
	lm	set_kf,#BAZHEN_KF
	lm2	set_level,#120
	lda	#HAND_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm2	neili_cost,#400
	jsr	judge_force
	jcs	fail1_rts

	lm	perform_temp4,perform_id
	lm	perform_id,#ZHANGDAO1_PF
	jsr	find_ptemp
	jcc	using_perform
	lm	perform_id,perform_temp4

	jsr	find_ptemp
	jcc	using_perform

	;sucess
	jsr	sub_obj_fp

	lm2	a9,#zhangdao_sucess_msg
	jsr	show_text

	lm2	a1,skill_level
	lm2	a2,#20
	jsr	divid2
	lm	temp_delay,a1
	ldy	#STR_OFF
	jsr	get_obj_data
	lm	temp_data,perform_data
	lm	temp_position,#5
	ldy	#ATTACK_OFF
	jsr	get_obj_data
	lm	temp_data_2,perform_data
	lm	temp_position_2,#1
	jsr	set_ptemp

	lm2	a1,skill_level
	lm2	a2,#15
	jsr	divid2
	lda	a1
	ldy	#ATTACK_OFF
	jsr	adc_obj_1byte

	asl	a1
	lda	a1
	ldy	#STR_OFF
	jsr	adc_obj_1byte
	
	lda	#2
	jsr	set_obj_busy
	clc
	rts
;---------------------
	
not_level:
	lm2	a9,#level_msg
	jmp	fail_rts
not_suit_kf:
	lm	kf_id,set_kf
	lm2	a9,#suit_msg
	jmp	fail_rts
neili_level:
	lm2	a9,#neili_msg
	jmp	fail_rts
not_neili:
	lm2	a9,#not_neili_msg
	jmp	fail_rts
using_perform:
	lm2	a9,#using_msg
	jmp	fail_rts
perform_busy:
	lm2	a9,#busy_msg
	jmp	fail_rts
show_man_busy:
man_is_busy:
	lm2	a9,#man_busy_msg
	jmp	fail_rts
npc_is_busy:
	lm2	a9,#npc_busy_msg
	jmp	fail_rts
perform_str:
	lm2	a9,#not_str_msg
fail_rts:
	smb7	net_msg_vision
	jsr	show_text
fail1_rts:			;for patch use
	sec
	rts
	

;*****************************
;	八卦刀影掌
;*****************************

daoying_gua:
	
	jsr	get_obj_busy
	jne	man_is_busy

	lm	set_kf,#HUNYUAN_KF
	lm2	set_level,#90
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm	set_kf,#BAGUAD_KF
	lm2	set_level,#135
	lda	#WEAPON_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm	set_kf,#BAGUAZ_KF
	lm2	set_level,#30			;因为query_skill有武器就不判断空手,所以取
								;基本功夫/2作为限制条件
	lda	#HAND_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm2	neili_cost,#150
	jsr	judge_force
	jcs	fail1_rts	

	lm	perform_temp4,perform_id
	lm	perform_id,#ZHANGDAO1_PF
	jsr	find_ptemp
	jcc	using_perform
	lm	perform_id,#ZHANGDAO2_PF
	jsr	find_ptemp
	jcc	using_perform
	lm	perform_id,#DAOYING2_PF
	jsr	find_ptemp
	jcc	using_perform
	lm	perform_id,perform_temp4

	jsr	find_ptemp
	jcc	perform_busy
	
	;sucess
	jsr	sub_obj_fp

	lm2	a9,#daoying_sucess_msg
	jsr	show_text

	lm	temp_position,#0
	lm	temp_position_2,#0
	lm	temp_delay,#7
	jsr	set_ptemp

	lm2	perform_temp5,obj_ptr
	lm2	perform_temp6,you_ptr

	jsr	unwield_weapon
	lm	net_repeat,#3
	jsr	attack_xxx
	jsr	wield_weapon
	lm	net_repeat,#3
	jsr	attack_xxx
	
	lm2	obj_ptr,perform_temp5
	lm2	you_ptr,perform_temp6

	lda	#3
	jsr	set_obj_busy
	
	clc
	rts

;--------------------

;***************************
;	八阵刀影掌
;***************************

daoying_zhen:			;for baguazhang

	lm	set_kf,#HUNYUAN_KF
	lm2	set_level,#90
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm	set_kf,#BAGUAD_KF
	lm2	set_level,#90
	lda	#WEAPON_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm	set_kf,#BAZHEN_KF
	lm2	set_level,#45
	lda	#HAND_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm2	neili_cost,#450
	jsr	judge_force
	jcs	fail1_rts

	lm	perform_temp4,perform_id
	lm	perform_id,#ZHANGDAO1_PF
	jsr	find_ptemp
	jcc	using_perform
	lm	perform_id,#ZHANGDAO2_PF
	jsr	find_ptemp
	jcc	using_perform
	lm	perform_id,#DAOYING1_PF
	jsr	find_ptemp
	jcc	using_perform
	lm	perform_id,perform_temp4

	jsr	find_ptemp
	jcc	perform_busy

	;sucess
	jsr	sub_obj_fp

	lm2	a9,#daoying_sucess_msg
	jsr	show_text

	ldy	#ATTACK_OFF
	jsr	get_obj_data
	lm	perform_temp3,perform_data
	ldy	#STR_OFF
	jsr	get_obj_data
	lm	perform_temp4,perform_data

	lm	temp_data,perform_temp3
	lm	temp_position,#1
	lm	temp_data_2,perform_temp4
	lm	temp_position_2,#5
	lm	temp_delay,#7
	jsr	set_ptemp
	
	lda	#10
	ldy	#ATTACK_OFF
	jsr	adc_obj_1byte
	
	lm2	a1,skill_level
	lm2	a2,#9
	jsr	divid2
	lda	a1
	ldy	#STR_OFF
	jsr	adc_obj_1byte

	lm2	perform_temp5,obj_ptr
	lm2	perform_temp6,you_ptr

	jsr	unwield_weapon
	lm	net_repeat,#3
	jsr	attack_xxx
	lm	net_repeat,#3
	jsr	attack_xxx
	jsr	wield_weapon
	lm	net_repeat,#3
	jsr	attack_xxx

	lm2	obj_ptr,perform_temp5
	lm2	you_ptr,perform_temp6

	lm	perform_data,perform_temp3
	ldy	#ATTACK_OFF
	lda	#1
	jsr	set_obj_data

	lm	perform_data,perform_temp4
	ldy	#STR_OFF
	lda	#1
	jsr	set_obj_data

	jsr	clear_xxx_ptemp

	lda	#3
	jsr	set_obj_busy

	clc
	rts
;-----------------


;*****************************
;	流星飞掷
;*****************************
feizhi:
	ldy	#STR_OFF
	jsr	get_obj_data
	cmp1	perform_data,#33
	jcc	perform_str

	lm	set_kf,#TONGJI_KF
	lm2	set_level,#120
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm	set_kf,#PIFENG_KF
	lm2	set_level,#120
	lda	#WEAPON_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm2	perform_temp4,skill_level
	
	lm2	neili_cost,#550
	cmp2	skill_level,#150
	bcc	feizhi_1
	lm2	neili_cost,#850
feizhi_1:
	jsr	judge_force
	jcs	fail1_rts

	jsr	find_ptemp
	jcc	perform_busy

	;sucess
	jsr	sub_obj_fp

	lm2	a9,#feizhi_sucess_msg
	jsr	show_text

	lm	temp_position,#0
	lm	temp_position_2,#0
	lm	temp_delay,#9
	jsr	set_ptemp

	ldy	#ATTACK_OFF
	jsr	get_obj_data
	lm	perform_temp7,perform_data

	lda	#15
	ldy	#ATTACK_OFF
	jsr	adc_obj_1byte

	lm2	perform_temp5,obj_ptr
	lm2	perform_temp6,you_ptr

	lda	#1
	jsr	get_usekf		;output:A
	jsr	kf_attr			;input: A ,output: kf_id
	lda	#0
	ldx	#0
	jsr	skill_xxx_power

	lm2	tmp_attack_point,a1		;ap
	lm2	tmp_attack_point+2,a2		
	
	lm2	obj_ptr,perform_temp5
	lm2	you_ptr,perform_temp6

	lm	perform_temp8,obj_flag
	lda	#80h
	eor	obj_flag
	sta	obj_flag

	lda	#2
	jsr	get_usekf
	jsr	kf_attr
	lda	#1
	ldx	#0
	jsr	skill_xxx_power
	lm	obj_flag,perform_temp8

	jsr	get_obj_busy
	beq	feizhi_2
	lm2	a2,#3
	jsr	divid2
feizhi_2:
	lm2	tmp_dodge_point,a1		;dp
	lm2	tmp_dodge_point+2,a2		
	
	lm2	obj_ptr,perform_temp5
	lm2	you_ptr,perform_temp6

	clc
	lda	tmp_attack_point
	adc	tmp_dodge_point
	sta	a7
	lda	tmp_attack_point+1
	adc	tmp_dodge_point+1
	sta	a7h
	lda	tmp_attack_point+2
	adc	tmp_dodge_point+2
	sta	a8
	lda	tmp_attack_point+3
	adc	tmp_dodge_point+3
	sta	a8h
	jsr	perform_random_it	;output: a3 a4
	cmp4	a3,tmp_dodge_point
	jcc	feizhi_5

	;shoot
	lm2	a9,#feizhi_shoot_msg
	jsr	show_text

	ldy	#STR_OFF
	jsr	get_obj_data
	lda	perform_data
	adda2	perform_temp4	;skill_level changed
	asl2	perform_temp4
	;asl2	perform_temp4

	lm2	perform_temp8,perform_temp4
	jsr	sub_you_hp
	bcc	feizhi_4
feizhi_3:	
	;npc live
	lsr2	skill_level
	ldy	#EFFHP_OFF
	jsr	get_you_data

	sub	perform_data,skill_level

	ldy	#EFFHP_OFF
	lda	#2
	jsr	set_you_data
	
	lda	#3
	jsr	set_obj_busy
feizhi_4:
	jmp	feizhi_rts
feizhi_5:
	;not_shoot
	lm2	a9,#feizhi_dodge_msg
	jsr	show_text
	lda	#4
	jsr	set_obj_busy
feizhi_rts:
	lm	perform_data,perform_temp7
	ldy	#ATTACK_OFF
	lda	#1
	jsr	set_obj_data

	bit	obj_flag
	bpl	feizhi_patch_4
	;从菜单选项中去掉武器
	lda	man_weapon
	jsr	find_goods
	dec	man_goods+1,x
	lm	man_weapon,#0
	lm	man_damage,#0

	clc
	rts
feizhi_patch_4:
	lm	npc_weapon,#0
	clc
	rts

;-----------------------

;*****************************
;	红莲出世
;*****************************
honglian:

	lm	set_kf,#TONGJI_KF
	lm2	set_level,#120
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm2	neili_cost,#350
	jsr	judge_force
	jcs	fail1_rts

	jsr	find_ptemp
	jcc	using_perform

	;sucess
	jsr	sub_obj_fp

	lm2	a9,#honglian_sucess_msg
	jsr	show_text

	lm2	a1,skill_level
	lm2	a2,#20
	jsr	divid2
	lm	temp_delay,a1
	ldy	#ATTACK_OFF
	jsr	get_obj_data
	lm	temp_data,perform_data
	lm	temp_position,#1
	lm	temp_position_2,#0
	jsr	set_ptemp

	lm2	a1,skill_level
	lm2	a2,#9
	jsr	divid2
	lda	a1
	ldy	#ATTACK_OFF
	jsr	adc_obj_1byte

	lda	#1
	jsr	set_obj_busy
	clc
	rts

;-------------------


;****************************
;	雷动九天
;****************************
leidong:

	lm	set_kf,#TONGJI_KF
	lm2	set_level,#90
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm2	neili_cost,#150
	jsr	judge_force
	jcs	fail1_rts

	jsr	find_ptemp
	jcc	using_perform

	;sucess
	jsr	sub_obj_fp
	
	lm2	a9,#leidong_sucess_msg
	jsr	show_text

	lm2	a1,skill_level
	lm2	a2,#20
	jsr	divid2
	lm	temp_delay,a1
	ldy	#STR_OFF
	jsr	get_obj_data
	lm	temp_data,perform_data
	lm	temp_position,#5
	lm	temp_position_2,#0
	jsr	set_ptemp

	lm2	a1,skill_level
	lm2	a2,#6
	jsr	divid2
	lda	a1
	ldy	#STR_OFF
	jsr	adc_obj_1byte

	clc
	rts
;---------------------

	if	0
;*************************
;	天清地彻
;*************************
tiandi:
	smb7	obj_flag

	lm	set_kf,#TONGJI_KF
	lm2	set_level,#75
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm2	neili_cost,#350
	jsr	judge_force
	jcs	fail1_rts

	jsr	find_ptemp
	jcc	using_perform

	;sucess
	sub	man_fp,neili_cost

	lm2	a9,#tiandi_sucess_msg
	jsr	show_text

	lm2	a1,skill_level
	lm2	a2,#15
	jsr	divid2
	lm	temp_delay,a1
	lm	temp_data,man_int
	lm	temp_position,#7
	lm	temp_position_2,#0
	jsr	set_ptemp

	asl	man_int			;*2
	
	clc

	sec
	rts
;------------------------
	endif
	
;*****************************
;	缠字决
;*****************************
chan:
	
	jsr	get_you_busy
	jne	npc_is_busy

	lm	set_kf,#TAIJIG_KF
	lm2	set_level,#90
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm	set_kf,#TAIJIJ_KF
	lm2	set_level,#90
	lda	#WEAPON_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm2	neili_cost,#250
	jsr	judge_force
	jcs	fail1_rts

	lm	perform_temp4,perform_id
	lm	perform_id,#LIAN_PF
	jsr	find_ptemp
	jcc	using_perform
	lm	perform_id,perform_temp4

	jsr	find_ptemp
	jcc	perform_busy

	;sucess
	jsr	sub_obj_fp
	
	lm2	a9,#chan_sucess_msg
	jsr	show_text

	ldy	#EXP_OFF
	jsr	get_obj_data
	lm2	a7,perform_data
	lm2	a8,perform_data+2
	jsr	perform_random_it		;output:a3,a4
	lm2	perform_temp1,a3
	lm2	perform_temp2,a4

	ldy	#EXP_OFF
	jsr	get_you_data
	lm2	a1,perform_data
	lm2	a2,perform_data+2
	lm2	a3,#3
	lm2	a4,#0
	jsr	divid4
	cmp4	perform_temp1,a1
	bcc	chan_2
chan_1:
	;shoot
	lm2	a9,#chan_shoot_msg
	jsr	show_text

	lm2	a1,skill_level
	lm2	a2,#20
	jsr	divid2
	lm2	range,a1
	jsr	random_it
	clc
	adc	#1
	jsr	set_you_busy
	jmp	chan_rts
chan_2:
	;not shoot
	lm2	a9,#chan_dodge_msg
	jsr	show_text

	lda	#3
	jsr	set_obj_busy
chan_rts:
	lm	temp_position,#0
	lm	temp_position_2,#0
	lm	temp_delay,#6
	jsr	set_ptemp

	clc
	rts
;-------------------------	
	
;*******************************
;	连字决
;*******************************
lian:

	lm	set_kf,#TAIJIG_KF
	lm2	set_level,#120
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm	set_kf,#TAIJIJ_KF
	lm2	set_level,#120
	lda	#WEAPON_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm2	neili_cost,#350
	jsr	judge_force
	jcs	fail1_rts
	
	jsr	find_ptemp
	jcc	using_perform

	;sucess
	jsr	sub_obj_fp
	
	lm2	a9,#lian_sucess_msg
	jsr	show_text

	lm2	a1,skill_level
	lm2	a2,#30
	jsr	divid2
	lda	a1
	clc
	adc	#3
	sta	temp_delay
	ldy	#DEFENSE_OFF
	jsr	get_obj_data
	lm	temp_data,perform_data
	lm	temp_position,#2
	ldy	#ATTACK_OFF
	jsr	get_obj_data
	lm	temp_data_2,perform_data
	lm	temp_position_2,#1
	jsr	set_ptemp

	lm2	a1,skill_level
	lm2	a2,#15
	jsr	divid2
	lda	a1
	ldy	#DEFENSE_OFF
	jsr	adc_obj_1byte
	
	lda	#10
	ldy	#ATTACK_OFF
	jsr	adc_obj_1byte

	clc
	rts
;-------------------

;********************************
;	三环套月
;********************************
taoyue:

	lm	set_kf,#TAIJIG_KF
	lm2	set_level,#180
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm	set_kf,#TAIJIJ_KF
	lm2	set_level,#180
	lda	#WEAPON_KF
	jsr	judge_kf
	jcs	fail1_rts
	
	lm2	neili_cost,#400
	jsr	judge_force
	jcs	fail1_rts

	lm	perform_temp4,perform_id
	lm	perform_id,#LIAN_PF
	jsr	find_ptemp
	jcc	using_perform
	lm	perform_id,perform_temp4

	jsr	find_ptemp
	jcc	perform_busy

	;sucess
	jsr	sub_obj_fp
	
	lm2	a9,#taoyue_sucess_msg
	jsr	show_text

	ldy	#DAMAGE_OFF
	jsr	get_obj_data
	lm	perform_temp3,perform_data

	lm	temp_data,perform_temp3
	lm	temp_position,#3
	lm	temp_position_2,#0
	lm	temp_delay,#6
	jsr	set_ptemp

	lm2	a1,skill_level
	lm2	a2,#5
	jsr	divid2
	lda	a1
	ldy	#DAMAGE_OFF
	jsr	adc_obj_1byte
	
	lm2	perform_temp5,obj_ptr
	lm2	perform_temp6,you_ptr

	lm	perform_flag,#80h
	lm	net_repeat,#3
	jsr	attack_xxx
	lm	perform_flag,#81h
	lm	net_repeat,#3
	jsr	attack_xxx
	lm	perform_flag,#82h
	lm	net_repeat,#3
	jsr	attack_xxx
	lm	perform_flag,#0

	lm2	obj_ptr,perform_temp5
	lm2	you_ptr,perform_temp6

	lm	perform_data,perform_temp3
	ldy	#DAMAGE_OFF
	lda	#1
	jsr	set_obj_data
	
	jsr	clear_xxx_ptemp

	lda	#3
	jsr	set_obj_busy
	clc
	rts
;-----------------------

;****************************
;	挤字诀
;****************************
ji:

	lm	set_kf,#TAIJIG_KF
	lm2	set_level,#105
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm	set_kf,#TAIJIQ_KF
	lm2	set_level,#105
	lda	#HAND_KF
	jsr	judge_kf
	jcs	fail1_rts
	
	lm2	neili_cost,#350
	jsr	judge_force
	jcs	fail1_rts

	jsr	find_ptemp
	jcc	perform_busy
	
	;sucess
	jsr	sub_obj_fp

	lm2	a9,#ji_sucess_msg
	jsr	show_text
	
	ldy	#FP_OFF
	jsr	get_obj_data
	lm2	range,perform_data
	jsr	random_it
	lm2	perform_temp1,a1

	ldy	#FP_OFF
	jsr	get_you_data
	lm2	a1,perform_data
	lm2	a2,#3
	jsr	divid2
	cmp2	perform_temp1,a1	
	bcc	ji_3
ji_1:
	;shoot1
	lm2	a9,#ji_shoot_msg
	jsr	show_text

	ldy	#FP_OFF
	jsr	get_obj_data
	lm2	a1,perform_data
	lm2	a2,#10
	jsr	divid2
	add	neili_cost,a1,perform_temp2
	ldy	#FORCE_OFF
	jsr	get_obj_data
	add	perform_temp2,perform_data

	lm2	perform_temp8,perform_temp2
	jsr	sub_you_fp

	lm	temp_position,#0
	lm	temp_position_2,#0
	lm	temp_delay,#2
	jsr	set_ptemp
	jmp	ji_rts
ji_3:
	;judge again
	ldy	#FP_OFF
	jsr	get_you_data
	lm2	a1,perform_data
	lm2	a2,#5
	jsr	divid2
	cmp2	perform_temp1,a1
	bcc	ji_5

	;shoot2	
	lm2	a9,#ji_shoot_msg1
	jsr	show_text

	lm2	perform_temp8,neili_cost
	jsr	sub_you_fp
	jmp	ji_rts
ji_5:
	lm2	a9,#ji_dodge_msg
	jsr	show_text

	lm2	range,#3
	jsr	random_it
	clc
	adc	#1
	jsr	set_obj_busy
ji_rts:
	clc
	rts
;--------------------

;****************************
;	乱环诀
;****************************
luanhuan:
	
	lm	set_kf,#TAIJIG_KF
	lm2	set_level,#150
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm	set_kf,#TAIJIQ_KF
	lm2	set_level,#150
	lda	#HAND_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm2	neili_cost,#300
	jsr	judge_force
	jcs	fail1_rts

	jsr	find_ptemp
	jcc	perform_busy

	jsr	get_you_busy
	jne	npc_is_busy			;can change

	;sucess
	jsr	sub_obj_fp
		
	lm2	a9,#luanhuan_sucess_msg
	jsr	show_text

	lm2	range,skill_level
	jsr	random_it
	lm2	perform_temp1,a1

	lm	kf_type,#PARRY_KF
	jsr	query_you_skill
	lm2	a1,skill_level
	lm2	a2,#3
	jsr	divid2
	cmp2	perform_temp1,a1
	bcc	luanhuan_2
luanhuan_1:
	;shoot
	lm2	a9,#luanhuan_shoot_msg
	jsr	show_text

	lm2	a1,perform_temp1
	lm2	a2,#30
	jsr	divid2
	lm	perform_data,a1
	inc	perform_data
	inc	perform_data
	lda	perform_data
	jsr	set_you_busy

	lm	temp_position,#0
	lm	temp_position_2,#0
	jsr	get_you_busy
	clc
	adc	#4
	sta	temp_delay
	jsr	set_ptemp
	jmp	luanhuan_rts
luanhuan_2:
	;not shoot
	lm2	a9,#luanhuan_dodge_msg
	jsr	show_text
	lda	#2
	jsr	set_obj_busy
luanhuan_rts:
	clc
	rts
;------------------------

;*******************************
;	阴阳诀
;*******************************
yinyang:
	
	lm	set_kf,#TAIJIG_KF
	lm2	set_level,#180
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm	set_kf,#TAIJIQ_KF
	lm2	set_level,#180
	lda	#HAND_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm2	neili_cost,#500
	jsr	judge_force
	jcs	fail1_rts

	jsr	find_ptemp
	jcc	perform_busy

	;sucess
	jsr	sub_obj_fp

	lm2	a9,#yinyang_sucess_msg
	jsr	show_text

	jsr	get_you_busy
	bne	yinyang_1
	lm2	range,#5
	jsr	random_it
	jeq	yinyang_3
yinyang_1:

	ldy	#ATTACK_OFF
	jsr	get_obj_data
	lm	perform_temp3,perform_data
	ldy	#STR_OFF
	jsr	get_obj_data
	lm	perform_temp4,perform_data

	lm	temp_data,perform_temp3
	lm	temp_position,#1
	lm	temp_data_2,perform_temp4
	lm	temp_position_2,#5
	lm	temp_delay,#7
	jsr	set_ptemp

	lda	#15
	ldy	#ATTACK_OFF
	jsr	adc_obj_1byte

	lm2	a1,skill_level
	lm2	a2,#5
	jsr	divid2
	lda	a1
	ldy	#STR_OFF
	jsr	adc_obj_1byte

	lm	perform_flag,#80h
	lm	net_repeat,#3
	jsr	attack_xxx
	lm	perform_flag,#0

	lm	perform_data,perform_temp3
	ldy	#ATTACK_OFF
	lda	#1
	jsr	set_obj_data

	lm	perform_data,perform_temp4
	ldy	#STR_OFF
	lda	#1
	jsr	set_obj_data

	jsr	clear_xxx_ptemp

	lda	#3
	jsr	set_obj_busy
	jmp	yinyang_rts
yinyang_3:

	lm2	a9,#yinyang_attack_msg
	jsr	show_text
	
	lm2	range,skill_level
	jsr	random_it
	lm2	perform_temp1,a1

	lm	kf_type,#PARRY_KF
	jsr	query_you_skill
	lm2	a1,skill_level
	lm2	a2,#3
	jsr	divid2
	cmp2	perform_temp1,a1
	bcc	yinyang_5
yinyang_4:
	;shoot
	lm2	a9,#yinyang_shoot_msg
	jsr	show_text
	
	lm2	a1,perform_temp1
	lm2	a2,#25
	jsr	divid2
	inc	a1
	inc	a1
	lda	a1
	jsr	set_you_busy

	lm	temp_position,#0
	lm	temp_position_2,#0
	lm	temp_delay,#5
	jsr	set_ptemp

	jmp	yinyang_rts

yinyang_5:
	lm2	a9,#yinyang_dodge_msg
	jsr	show_text
	lda	#2
	jsr	set_obj_busy

yinyang_rts:
	clc
	rts
;-----------------------		

;****************************
;	震字诀
;****************************
zhen:

	lm	set_kf,#TAIJIG_KF
	lm2	set_level,#90
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm	set_kf,#TAIJIQ_KF
	lm2	set_level,#90
	lda	#HAND_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm2	neili_cost,#200
	jsr	judge_force
	jcs	fail1_rts

	jsr	find_ptemp
	jcc	perform_busy
	
	;sucess
	jsr	sub_obj_fp

	lm2	a9,#zhen_sucess_msg
	jsr	show_text

	ldy	#FP_OFF
	jsr	get_obj_data
	lm2	range,perform_data
	jsr	random_it
	lm2	perform_temp1,a1

	ldy	#FP_OFF
	jsr	get_you_data
	lm2	a1,perform_data
	lm2	a2,#3
	jsr	divid2
	cmp2	perform_temp1,a1
	jcc	zhen_4
zhen_1:

	ldy	#FP_OFF
	jsr	get_obj_data
	lm2	a1,perform_data
	lm2	a2,#10
	jsr	divid2
	lm2	perform_temp2,a1
	
	ldy	#FORCE_OFF
	jsr	get_obj_data
	add	perform_temp2,perform_data
	
	ldy	#FP_OFF
	jsr	get_you_data
	lm2	a1,perform_data
	lm2	a2,#30
	jsr	divid2
	sub	perform_temp2,a1

	bcs	zhen_2
	lm2	a9,#zhen_dodge_msg
	jsr	show_text

	lda	#2
	jsr	set_obj_busy
	jmp	zhen_rts
zhen_2:
	;shoot
	lm2	a9,#zhen_shoot_msg
	jsr	show_text
	
	lm2	perform_temp8,perform_temp2
	jsr	sub_you_hp
	lsr2	perform_temp2

	ldy	#EFFHP_OFF
	jsr	get_you_data
	sub	perform_data,perform_temp2
	ldy	#EFFHP_OFF
	lda	#2
	jsr	set_you_data

	lm	temp_position,#0
	lm	temp_position_2,#0
	lm	temp_delay,#2
	jsr	set_ptemp

	jmp	zhen_rts

zhen_4:
	;judge again

	ldy	#FP_OFF
	jsr	get_you_data
	lm2	perform_temp2,perform_data
	lsr2	perform_temp2
	lsr2	perform_temp2			;/4
	cmp2	perform_temp1,perform_temp2
	bcc	zhen_7
zhen_5:
	;shoot2
	lm2	a9,#zhen_shoot_msg1

	ldy	#FP_OFF
	jsr	get_you_data
	cmp2	perform_data,#200
	bcs	zhen_6
	lm2	perform_data,#0
	ldy	#FP_OFF
	lda	#2
	jsr	set_you_data
	jmp	zhen_rts
zhen_6:
	lm2	perform_temp8,#100
	jsr	sub_you_fp
	jmp	zhen_rts		
zhen_7:
	lm2	a9,#zhen_dodge_msg1
	jsr	show_text
	
	lm2	range,#3
	jsr	random_it
	clc
	adc	#2
	jsr	set_obj_busy
zhen_rts:
	clc
	rts
;---------------------

;*****************************
;	三花
;*****************************

sanhua:

	;比较内功等级是否符合要求
	lm	set_kf,#SANHUA_KF
	lm2	set_level,#90
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts

	;判断内力是否够用
	lm2	neili_cost,#350
	jsr	judge_force	
	jcs	fail1_rts

	;判断是否正在使用三花
	jsr	find_ptemp
	jcc	using_perform
	
	;sucess

	;调整内力
	jsr	sub_obj_fp

	;显示信息
	lm2	a9,#sanhua_sucess_msg
	jsr	show_text

	;调整属性

	lm2	a1,skill_level
	lm2	a2,#20
	jsr	divid2
	lm	perform_temp1,a1
	lm	temp_delay,a1
	cmp	#8
	bcc	sanhua_1
	lm	temp_delay,#8
sanhua_1:
	ldy	#DEX_OFF
	jsr	get_obj_data
	lm	temp_data,perform_data
	lm	temp_position,#6
	ldy	#DEFENSE_OFF
	jsr	get_obj_data
	lm	temp_data_2,perform_data
	lm	temp_position_2,#2
	jsr	set_ptemp

	asl	perform_temp1
	lda	perform_temp1
	ldy	#DEX_OFF
	jsr	adc_obj_1byte

	lm2	a1,skill_level
	lm2	a2,#5
	jsr	divid2
	lda	a1
	sec
	sbc	#5
	sta	perform_data
	ldy	#DEFENSE_OFF
	lda	#1
	jsr	set_obj_data

	clc
	rts
;--------------------------

;***********************************
;	柳浪闻莺
;***********************************
liulang:

	;检查三花聚顶心法	
	lm	set_kf,#SANHUA_KF
	lm2	set_level,#120
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts

	;检查一剪梅花手
	lm	set_kf,#MEIHUA_KF
	lm2	set_level,#60
	lda	#HAND_KF
	jsr	judge_kf
	jcs	fail1_rts

	;判断柳叶刀法
	lm2	neili_cost,#200

	lm	set_kf,#LIU_KF  
	lm2	set_level,#90
	lda	#WEAPON_KF
	jsr	judge_kf
	jcs	fail1_rts

	cmp2	skill_level,#120
	bcc	liulang_1
	lm2	neili_cost,#400
liulang_1:
	jsr	judge_force
	jcs	fail1_rts

	lm	perform_temp4,perform_id
	lm	perform_id,#SANHUA_PF
	jsr	find_ptemp
	jcc	using_perform
	lm	perform_id,perform_temp4

	jsr	find_ptemp
	jcc	perform_busy

	;sucess
	jsr	sub_obj_fp

	lm2	a9,#liulang_sucess_msg
	jsr	show_text
	
	lm	temp_position,#0
	lm	temp_position_2,#0
	lm	temp_delay,#7
	jsr	set_ptemp

	;开始攻击,两掌一刀
	jsr	unwield_weapon
	lm	net_repeat,#3
	jsr	attack_xxx
	lm	net_repeat,#3
	jsr	attack_xxx
	jsr	wield_weapon
	lm	net_repeat,#3
	jsr	attack_xxx

	lda	#3
	jsr	set_obj_busy
	clc
	rts
;-----------------------

;*********************************
;	落英缤纷
;*********************************

luoying:
	
	;检查三花聚顶
	lm	set_kf,#SANHUA_KF
	lm2	set_level,#120
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts

	;检查花团锦簇鞭法
	lm	set_kf,#HUATUAN_KF
	lm2	set_level,#120
	lda	#WEAPON_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm2	neili_cost,#400
	jsr	judge_force
	jcs	fail1_rts
	
	jsr	find_ptemp
	jcc	perform_busy

	;sucess
	jsr	sub_obj_fp

	lm2	a9,#luoying_sucess_msg
	jsr	show_text

	jsr	get_you_weapon
	jpl	luoying_3
luoying_1:				
	;npc has weapon
	ldy	#DEX_OFF
	jsr	get_obj_data
	lm	range,perform_data
	lm	range+1,#0
	jsr	random_it
	sta	perform_temp1

	ldy	#DEX_OFF
	jsr	get_you_data
	lda	perform_data
	ldx	#3
	jsr	divid_ax
	cmp	perform_temp1

	bcs	luoying_2		;not shoot

	;shoot
	lm2	a9,#luoying_shoot_msg
	jsr	show_text
	lda	#0h
	jsr	set_you_weapon
	jmp	luoying_rts
luoying_2:
	lm2	a9,#luoying_dodge_msg
	jsr	show_text
	lda	#2
	jsr	set_obj_busy
	jmp	luoying_rts

luoying_3:
	;npc no weapon
	lm2	range,skill_level
	jsr	random_it
	lm2	perform_temp1,a1	

	lm	kf_type,#DODGE_KF
	jsr	query_you_skill
	lm2	a1,skill_level
	lm2	a2,#3
	jsr	divid2
	cmp2	perform_temp1,a1
	bcc	luoying_6
luoying_4:
	lm2	a9,#luoying_shoot_msg1
	jsr	show_text

	lm2	perform_temp8,perform_temp1
	jsr	sub_you_hp
	bcs	luoying_5
	jmp	luoying_rts
luoying_5:
	;npc live
	lsr2	perform_temp1
	ldy	#EFFHP_OFF
	jsr	get_you_data
	sub	perform_data,perform_temp1
	ldy	#EFFHP_OFF
	lda	#2
	jsr	set_you_data
	lda	#2
	jsr	set_you_busy
	jmp	luoying_rts
luoying_6:
	;not shoot
	lm2	a9,#luoying_dodge_msg1
	jsr	show_text
	lda	#2
	jsr	set_obj_busy
luoying_rts:
	lm	temp_position,#0
	lm	temp_position_2,#0
	lm	temp_delay,#6
	jsr	set_ptemp

	clc
	rts
;-----------------

;************************************
;	雪花六出
;************************************
liuchu:

	lm	set_kf,#XUESHANG_KF
	lm2	set_level,#90
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts	

	lm	set_kf,#XUESHANJ_KF
	lm2	set_level,#90
	lda	#WEAPON_KF
	jsr	judge_kf
	jcs	fail1_rts	
	
	sub	skill_level,#90,a1
	lm2	a2,#30
	jsr	divid2
	lm2	a2,#150
	jsr	mul2
	add	a1,#250,neili_cost
	cmp2	neili_cost,#600
	bcc	liuchu_1
	lm2	neili_cost,#600
liuchu_1:
	jsr	judge_force
	jcs	fail1_rts

	jsr	find_ptemp
	jcc	perform_busy

	;sucess 
	jsr	sub_obj_fp

	lm2	a9,#liuchu_sucess_msg
	jsr	show_text

	lm2	perform_temp1,skill_level
	sub	perform_temp1,#90
	lm2	a1,perform_temp1
	lm2	a2,#30
	jsr	divid2
	lda	a1
	clc
	adc	#2
	cmp	#5
	bcc	liuchu_2
	lda	#5
liuchu_2:
	sta	perform_temp1

	ldy	#ATTACK_OFF
	jsr	get_obj_data
	lm	perform_temp4,perform_data

	lm	temp_data,perform_temp4
	lm	temp_position,#1
	lm	temp_position_2,#0
	lm	temp_delay,#10
	jsr	set_ptemp

	lda	#10
	ldy	#ATTACK_OFF
	jsr	adc_obj_1byte

	lm2	perform_temp5,obj_ptr
	lm2	perform_temp6,you_ptr
liuchu_3:	

	lm	net_repeat,#3
	jsr	attack_xxx
	dec	perform_temp1
	bne	liuchu_3
	
	lm2	obj_ptr,perform_temp5
	lm2	you_ptr,perform_temp6

	lm	perform_data,perform_temp4
	ldy	#ATTACK_OFF
	lda	#1
	jsr	set_obj_data
	
	jsr	clear_xxx_ptemp

	lda	#3
	jsr	set_obj_busy
	clc
	rts
;----------------------

;************************************
;	神倒鬼跌三连环
;************************************
shengui:

	lm	set_kf,#XUEYING_KF 
	lm2	set_level,#120
	lda	#HAND_KF
	jsr	judge_kf
	jcs	fail1_rts
	
	lm2	neili_cost,#350
	jsr	judge_force
	jcs	fail1_rts

	jsr	get_you_busy
	jne	npc_is_busy

	jsr	find_ptemp
	jcc	perform_busy

	;sucess
	jsr	sub_obj_fp

	lm2	a9,#shengui_sucess_msg
	jsr	show_text

	ldy	#FP_OFF
	jsr	get_obj_data
	lm2	range,perform_data
	jsr	random_it
	lm2	perform_temp1,a1

	ldy	#FP_OFF
	jsr	get_you_data
	lm2	a1,perform_data
	lm2	a2,#2
	jsr	divid2
	cmp2	perform_temp1,a1
	bcc	shengui_2
shengui_1:
	;shoot
	lm2	a9,#shengui_shoot_msg
	jsr	show_text
	
	lm2	a1,skill_level
	lm2	a2,#35
	jsr	divid2
	lm2	range,a1
	jsr	random_it
	inc	a1
	inc	a1
	inc	a1
	lda	a1
	jsr	set_you_busy
	
	lm2	a1,skill_level
	lm2	a2,#3
	jsr	divid2
	lm2	perform_temp8,a1
	jsr	sub_you_hp
	jmp	shengui_rts
shengui_2:
	;not shoot
	lm2	a9,#shengui_dodge_msg
	jsr	show_text
	lda	#2
	jsr	set_obj_busy
shengui_rts:
	lm	temp_position,#0
	lm	temp_position_2,#0
	lm	temp_delay,#5
	jsr	set_ptemp
	clc
	rts

;-----------------
		

;***********************************
;	冰心诀
;***********************************
bingxin:
	
	lm2	neili_cost,#150

	lm	set_kf,#XUESHANG_KF
	lm2	set_level,#75
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts

	cmp2	skill_level,#90
	bcc	bingxin_1
	lm2	neili_cost,#250
bingxin_1:
	jsr	judge_force
	jcs	fail1_rts

	jsr	find_ptemp
	jcc	using_perform

	;sucess
	jsr	sub_obj_fp

	lm2	a9,#bingxin_sucess_msg
	jsr	show_text

	lm2	a1,skill_level
	lm2	a2,#20
	jsr	divid2
	lda	a1
	cmp	#10
	bcc	bingxin_2
	lda	#10
bingxin_2:
	sta	temp_delay
	ldy	#ARMOR_OFF
	jsr	get_obj_data
	lm	temp_data,perform_data
	lm	temp_position,#4	
	lm	temp_position_2,#0
	jsr	set_ptemp

	lsr2	skill_level
	lsr2	skill_level
	cmp2	skill_level,#100
	bcc	bingxin_3
	lm	skill_level,#100
bingxin_3:
	lda	skill_level
	ldy	#ARMOR_OFF
	jsr	adc_obj_1byte
bingxin_4:
	clc
	rts
;----------------------
	
;************************************
;	旋风三连斩
;************************************
lianzhan:

	jsr	get_obj_busy
	jne	man_is_busy
	
	lm	set_kf,#RENSHU_KF
	lm2	set_level,#120
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm	set_kf,#YIDAO_KF
	lm2	set_level,#90
	lda	#WEAPON_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm2	neili_cost,#350
	jsr	judge_force
	jcs	fail1_rts

	lm	perform_temp4,perform_id
	lm	perform_id,#YIDAOZHAN_PF
	jsr	find_ptemp
	jcc	perform_busy
	lm	perform_id,perform_temp4

	jsr	find_ptemp
	jcc	perform_busy

	;sucess
	jsr	sub_obj_fp

	lm2	a9,#lianzhan_sucess_msg
	jsr	show_text

	lm	perform_flag,#80h
	lm	net_repeat,#3
	jsr	attack_xxx
	lm	perform_flag,#81h
	lm	net_repeat,#3
	jsr	attack_xxx
	lm	perform_flag,#82h
	lm	net_repeat,#3
	jsr	attack_xxx
	lm	perform_flag,#0

	lm	temp_position,#0
	lm	temp_position_2,#0
	lm	temp_delay,#5
	jsr	set_ptemp
	
	lda	#1
	jsr	set_obj_busy

	clc
	rts
;--------------------

;*************************************
;	迎风一刀斩
;*************************************
yidao:
	jsr	get_obj_busy
	jne	man_is_busy

	;判断忍术
	lm	set_kf,#RENSHU_KF
	lm2	set_level,#120
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts

	;判断川枫一刀流刀法等级
	lm	set_kf,#YIDAO_KF
	lm2	set_level,#120
	lda	#WEAPON_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm2	neili_cost,#550
	jsr	judge_force
	jcs	fail1_rts

	jsr	find_ptemp
	jcc	perform_busy

	;sucess
	jsr	sub_obj_fp
	
	;显示起手信息
	lm2	a9,#yidao_sucess_msg
	jsr	show_text
	
	ldy	#DAMAGE_OFF
	jsr	get_obj_data
	lm	perform_temp3,perform_data
	ldy	#ATTACK_OFF
	jsr	get_obj_data
	lm	perform_temp4,perform_data
	
	lm	temp_data,perform_temp3
	lm	temp_position,#3
	lm	temp_data_2,perform_temp4
	lm	temp_position_2,#1
	lm	temp_delay,#7
	jsr	set_ptemp

	lm2	a1,skill_level
	lm2	a2,#3
	jsr	divid2
	lda	a1
	clc
	clc
	adc	#20
	ldy	#DAMAGE_OFF
	jsr	adc_obj_1byte
	
	lda	#15
	ldy	#ATTACK_OFF
	jsr	adc_obj_1byte

	;攻击npc
	lm2	perform_temp5,obj_ptr
	lm2	perform_temp6,you_ptr
	
	lm	net_repeat,#3
	jsr	attack_xxx

	lm2	obj_ptr,perform_temp5
	lm2	you_ptr,perform_temp6

	lm	perform_data,perform_temp3
	ldy	#DAMAGE_OFF
	lda	#1
	jsr	set_obj_data
	
	lm	perform_data,perform_temp4
	ldy	#ATTACK_OFF
	lda	#1
	jsr	set_obj_data

	jsr	clear_xxx_ptemp

	lda	#1
	jsr	set_obj_busy

	clc
	rts
;-------------------------

;*******************************
;	忍法影分身
;*******************************
fenshen:
	smb7	obj_flag

	lm	set_kf,#RENSHU_KF
	lm2	set_level,#120
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts

	lm2	neili_cost,#550
	jsr	judge_force
	jcs	fail1_rts

	jsr	find_ptemp
	jcc	using_perform

	;sucess
	sub	man_fp,neili_cost
	
	lm2	a9,#fenshen_sucess_msg
	jsr	show_text

	lm2	a1,skill_level
	lm2	a2,#20
	jsr	divid2
	lm	temp_delay,a1
	lm	temp_data,man_per
	lm	temp_position,#9
	lm	temp_data_2,man_kar
	lm	temp_position_2,#10
	jsr	set_ptemp

	lm2	a1,skill_level
	lm2	a2,#5
	jsr	divid2
	lda	a1
	cmp	#40
	bcs	fenshen_1
	lda	#30
fenshen_1:
	sta	man_per
	lm	man_kar,#0ffh		;借用man_kar作为是否使用fenshen的
					;标志
	clc
	rts

;******************************
;	忍术烟幕
;******************************
yianmu:
	
	lm	set_kf,#RENSHU_KF
	lm2	set_level,#90
	lda	#FORCE_KF
	jsr	judge_kf
	jcs	fail1_rts	

	lm2	neili_cost,#300
	jsr	judge_force
	jcs	fail1_rts

	ldy	#FP_OFF
	jsr	get_you_data
	lm2	a1,perform_data
	lm2	a2,#3
	jsr	divid2
	lm2	perform_temp1,a1
	
	ldy	#FP_OFF
	jsr	get_obj_data
	lm2	range,perform_data
	jsr	random_it
	cmp2	a1,perform_temp1
	jcc	yianmu_fail

	jsr	find_ptemp
	jcc	perform_busy

	;sucess
	jsr	sub_obj_fp

	lm2	a9,#yianmu_sucess_msg
	jsr	show_text

	lm2	a1,skill_level
	lm2	a2,#20
	jsr	divid2
	lm	temp_delay,a1
	ldy	#ATTACK_OFF
	jsr	get_you_data
	lm	temp_data,perform_data
	lm	temp_position,#11
	lm	temp_position_2,#0
	jsr	set_ptemp

	lm	perform_temp1,#20
	
	lm2	a1,skill_level
	lm2	a2,#8
	jsr	divid2
	cmp2	a1,#20
	bcc	yianmu_1
	lm	perform_temp1,a1
yianmu_1:
	ldy	#ATTACK_OFF
	jsr	get_you_data
	lda	perform_data
	sec
	sbc	perform_temp1
	bpl	yianmu_2
	lda	#0
yianmu_2:
	sta	perform_data
	ldy	#ATTACK_OFF
	lda	#1
	jsr	set_you_data
	clc
	rts
yianmu_fail:
	lda	#2
	jsr	set_obj_busy
	lm2	a9,#yianmu_fail_msg
	jsr	show_text
	clc
	rts
;------------------



;--------------------------------
;--------------------------------
;--------------------------------

;subpro有关的子程序


;***********************
;input:A
;output:kf_id
;***********************
kf_attr:
	and	#7fh
	sta	kf_id
	rts	
;-------------------


;**************************************
;	func:从指定的地质指针开始取若干
;	     个字节送入bank_text,并显示
;	input:a9
;	output:string_ptr
;**************************************
show_text:
	ldy	#0
	bit	net_flag
	bpl	show_text_1
	lm	net_repeat,#2
show_text_1:
	lm	bank_no,#1
	lda	#PERFORM_TEXT
	asl	a
	tay
	lda	txt_class_tbl,y
	sta	bank_data_ptr
	lda	txt_class_tbl+1,y
	sta	bank_data_ptr+1
	lda	a9
	asl	a
	tay
	jsr	set_get_buf
	sta	bank_data_ptr
	iny
	lda	data_read_buf,y
	sta	bank_data_ptr+1
	lm2	RecordSize,#200
	lm2	data_buf,#img_buf
	jsr	set_read_buf
show_text_2:
	lm2	string_ptr,#img_buf
	jsr	show_fight_msg
	rts

;----------------

;*************************************************
;	struct	ptemp{
;	int	perform_id		;绝招id
;	int	temp_data		;要恢复的第一个数据
;	int	temp_position		;第一个数据位置
;	int	temp_data_2		;要恢复的第二个数据
;	int	temp_position_2		;第二个数据位置
;	int	temp_delay
;	}
;	struct	ptemp tmp[20]	
;
;

;====================================================
;input:perform_id,temp_data,temp_position,temp_delay
;output:bcc(fail) sec(sucess)
;====================================================
set_ptemp:
	jsr	find_pspace
	bcc	set_fail_rts
	lda	perform_id
	sta	(a1),y
	iny
	lda	temp_data
	sta	(a1),y
	iny	
	lda	temp_position
	sta	(a1),y
	iny	
	lda	temp_data_2
	sta	(a1),y
	iny	
	lda	temp_position_2
	sta	(a1),y
	iny	
	lda	temp_delay
	sta	(a1),y
	sec
	rts
set_fail_rts:
	clc
	rts
;-----------------------

;***************************
;input:none
;output:y
;	bcc(fail) bcs(sucess)
;***************************
find_pspace:
	lm2	a1,#ptemp
	ldy	#0
	lm	perform_temp8,#PTEMP_SIZE
	bit	obj_flag
	bmi	find_pspace_1
	lm2	a1,#npc_ptemp
	ldy	#0
	lm	perform_temp8,#NPC_PTEMP_SIZE
find_pspace_1:
	lda	(a1),y
	cmp	#0ffh
	beq	find_pspace_rts
	iny
	iny
	iny
	iny	
	iny
	iny				;有6个元素,所以加6次
	cpy	perform_temp8
	bcc	find_pspace_1
	clc
find_pspace_rts:
	sec
	rts
;---------------------------

;*******************************************************
;修改ptemp数组中的delay,在每次绝招攻击之前调用,如果delay
;结束,将数组元素清0,释放数组空间,显示相关绝招的结束信息
;恢复man_? 调整前的数值.
;遍历数组,检查delay元素,
;
;input:none
;output:none
;*******************************************************
call_out:
	lm2	a1,#ptemp
	ldy	#5		;delay
call_out_1:
	lda	(a1),y
	beq	call_out_2
	sec
	sbc	#1
	sta	(a1),y
	bne	call_out_2
	tya
	pha
	jsr	call_out_serve
	pla
	tay
call_out_2:
	iny	
	iny
	iny
	iny	
	iny
	iny
	cpy	#PTEMP_SIZE+NPC_PTEMP_SIZE		;160
	bcc	call_out_1
	rts

;--------------------
;input:y
;--------------------

call_out_serve:
	dey
	dey
	dey			
	dey
	dey
	tya	
	pha

	lda	(a1),y		;perform_id
	jsr	out_show			;maybe change a1

	pla
	tay
	lm2	a1,#ptemp
	lda	#0ffh
	sta	(a1),y
	lda	#0
	iny
	sta	(a1),y
	iny
	sta	(a1),y
	iny	
	sta	(a1),y
	iny	
	sta	(a1),y
	iny	
	sta	(a1),y
	rts
;----------------------
;恢复man_data
;input:a(perform_id)
;output:man_data
;----------------------
out_show:
	pha				;perform_id
	jsr	refresh_data		;y增加了2
	jsr	refresh_data
	pla
	jsr	show_over_msg
	rts	

;--------------------------------------------------------------
;position: 	1,attack 2,defense 3,damage 4,armor 5,str 6,dex 
;		7,int    8,con     9,per    10,kar  11,npc_attack
;--------------------------------------------------------------

refresh_data:
	iny			;data
	lda	(a1),y
	tax
	iny			;position
	lda	(a1),y
	jeq	is_none
	cmp	#1
	jeq	is_attack
	cmp	#2
	jeq	is_defense
	cmp	#3
	jeq	is_damage
	cmp	#4
	jeq	is_armor
	cmp	#5
	jeq	is_str
	cmp	#6
	jeq	is_dex
	cmp	#7
	jeq	is_int
	cmp	#8
	jeq	is_con
	cmp	#9
	jeq	is_per
	cmp	#10
	jeq	is_kar
	cmp	#11
	jeq	is_npc_attack

;-------
is_none:
	rts

;-------
is_attack:
	bit	obj_flag
	bpl	is_attack_1
	stx	man_attack
	rts
is_attack_1:
	stx	npc_attack
	rts
;-------
is_defense:
	bit	obj_flag
	bpl	is_defense_1
	stx	man_defense
	rts
is_defense_1:
	stx	npc_defense
	rts
;-------
is_damage:
	bit	obj_flag
	bpl	is_damage_1
	stx	man_damage
	rts
is_damage_1:
	stx	npc_damage
	rts
;-------
is_armor:
	bit	obj_flag
	bpl	is_armor_1
	stx	man_armor
	rts
is_armor_1:
	stx	npc_armor
	rts
;-------
is_str:
	bit	obj_flag
	bpl	is_str_1
	stx	man_str
	rts
is_str_1:
	stx	npc_str
	rts
;-------
is_dex:
	bit	obj_flag
	bpl	is_dex_1
	stx	man_dex
	rts
is_dex_1:
	stx	npc_dex
	rts
;-------
is_int:
	bit	obj_flag
	bpl	is_int_1
	stx	man_int
	rts
is_int_1:
	stx	npc_int
	rts
;-------
is_con:
	bit	obj_flag
	bpl	is_con_1
	stx	man_con
	rts
is_con_1:
	stx	npc_con
	rts
;-------
is_per:
	bit	obj_flag
	bpl	is_per_1
	stx	man_per
	rts
is_per_1:
	stx	npc_per
	rts
;-------
is_kar:	
	bit	obj_flag
	bpl	is_kar_1
	stx	man_kar
	rts
is_kar_1:
	stx	npc_kar
	rts
;-------
is_npc_attack:
	bit	obj_flag
	bpl	is_npc_attack_1
	stx	npc_attack
	rts
is_npc_attack_1:
	stx	man_attack
	rts

;------------------

;*********************************
;根据perform_id,显示绝招的结束信息
;input:perform_id
;*********************************
show_over_msg:
	cmp	#ZHANGDAO1_PF
	beq	show_over_patch
	cmp	#ZHANGDAO2_PF
	bne	show_over_1
show_over_patch:
	lm2	a9,#zhangdao_over_msg
	jsr	show_text	
	rts
show_over_1:
	cmp	#SANHUA_PF
	bne	show_over_2
	lm2	a9,#sanhua_over_msg
	jsr	show_text
	rts
show_over_2:
show_over_3:
	cmp	#FENSHEN_PF
	bne	show_over_4
	lm2	a9,#fenshen_over_msg
	jsr	show_text
	rts
show_over_4:
	cmp	#YIANMU_PF
	bne	show_over_5
	lm2	a9,#yianmu_over_msg
	jsr	show_text
	rts
show_over_5:
	cmp	#LIAN_PF
	bne	show_over_6
	lm2	a9,#lian_over_msg
	jsr	show_text
	rts
show_over_6:
	cmp	#BINGXIN_PF
	bne	show_over_7
	lm2	a9,#bingxin_over_msg
	jsr	show_text
show_over_7:
	rts

;----------------------

;*****************************
;遍历数组,查找等于perform_id的元素
;input:perform_id
;output:y	bcc(sucess),bcs(fail)
;*****************************
find_ptemp:
	lm2	a1,#ptemp
	ldy	#0
	lm	perform_temp8,#PTEMP_SIZE
	bit	obj_flag
	bmi	find_ptemp_1
	lm2	a1,#npc_ptemp
	ldy	#0
	lm	perform_temp8,#NPC_PTEMP_SIZE
find_ptemp_1:
	lda	(a1),y
	cmp	perform_id
	beq	find_ptemp_rts
	iny
	iny
	iny
	iny
	iny
	iny
	cpy	perform_temp8
	bcc	find_ptemp_1
	sec
	rts
find_ptemp_rts:
	clc
	rts
;--------------------	
	public	init_ptemp
init_ptemp:
	lm2 	a1,#ptemp
	ldy	#0
init_ptemp_1:
	lda	#0ffh
	sta	(a1),y
	iny
	lda	#0
	sta	(a1),y
	iny
	sta	(a1),y
	iny
	sta	(a1),y
	iny
	sta	(a1),y
	iny
	sta	(a1),y
	iny
	cpy	#PTEMP_SIZE+NPC_PTEMP_SIZE
	bcc	init_ptemp_1
	rts	

;********************************
;	战斗结束时,清理ptemp数组
;********************************	
quit_refresh:
	lm2	a1,#ptemp
	ldy	#5				;数组中delay的位置
quit_refresh_1:
	lda	(a1),y
	beq	quit_refresh_2
	jsr	quit_refresh_3
quit_refresh_2:
	rept	6
	iny
	endr
	cpy	#PTEMP_SIZE
	bcc	quit_refresh_1
	rts

quit_refresh_3:
	tya
	pha				;save y

	rept	5
	dey
	endr				;返回到起始位置,perform_id

	jsr	refresh_data		;output:y +=2
	jsr	refresh_data
	
	pla
	tay
	rts

;!!!不能破坏perform_temp3,perform_temp4,因为用他们保存了变量
unwield_weapon:
	bit	obj_flag
	bpl	unwield_npc_weapon
	lm	perform_temp4+1,man_damage
	lm	man_damage,#0
	lda	man_weapon
	jsr	find_goods
	lda	#80h
	eor	man_goods,x
	sta	man_goods,x
	rmb7	man_weapon
	rts
unwield_npc_weapon:
	rmb7 	npc_weapon
	rts

wield_weapon:
	bit	obj_flag
	bpl	wield_npc_weapon
	lda	man_weapon
	jsr	find_goods
	lda	#80h
	eor	man_goods,x
	sta	man_goods,x
	lm	man_damage,perform_temp4+1
	smb7	man_weapon
	rts
wield_npc_weapon:
	smb7	npc_weapon
	rts
;-----------------------------
;input:a(kf_type)set_kf,set_level
;--------------------
judge_kf:
	bit	obj_flag
	bpl	judge_npc_kf
	sta	kf_type
	tax
	lda	man_usekf,x
	and	#7fh
	sta	kf_id
	cmp	set_kf
	jne	not_suit_kf
	jsr	query_skill
	cmp2	skill_level,set_level
	jcc	not_level
	clc
	rts

judge_npc_kf:
	sta	kf_type
	tax
	lda	npc_usekf,x
	and	#7fh
	sta	kf_id
	cmp	set_kf
	jne	not_suit_kf
	jsr	query_npc_skill
	cmp2	skill_level,set_level
	jcc	not_level
	clc
	rts	

;-----------------
;input:neili_cost
;-----------------
judge_force:
	ldy	#MAXFP_OFF
	jsr	get_obj_data
	cmp2	perform_data,neili_cost
	jcc	neili_level
	ldy	#FP_OFF
	jsr	get_obj_data
	cmp2	perform_data,neili_cost
	jcc	not_neili
	clc
	rts
;-------------

;********************************
;	取人或NPC的enable_kfU
;	input:a -- which kf
;	output: A
;********************************	
get_usekf:
	tay
	bit	obj_flag		;if 80h MAN else NPC
	bpl	is_Npc_kf
	lda	man_usekf,y
	rts
is_Npc_kf:
	lda	npc_usekf,y
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
;------------------
get_you_data:
	ldx	#0
get_you_loop:
	lda	(you_ptr),y
	sta	perform_data,x
	inx
	iny
	cpx	#4
	bcc	get_you_loop
	rts
;------------------
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
;------------------
set_you_data:
	sta	perform_temp8
	ldx	#0
set_you_loop:
	lda	perform_data,x
	sta	(you_ptr),y
	inx
	iny
	cpx	perform_temp8
	bcc	set_you_loop
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
;********************************
;	减去hp
;	input:perform_temp8
;********************************
sub_obj_hp:
	ldy	#HP_OFF
	jsr	get_obj_data
	sub	perform_data,perform_temp8
	php
	bcs	sub_obj_hp1
	lm2	perform_data,#0
sub_obj_hp1:
	ldy	#HP_OFF
	lda	#2
	jsr	set_obj_data
	plp
	rts
;********************************
;	减去内力,
;	input:perform_temp8
;********************************
sub_you_fp:
	ldy	#FP_OFF
	jsr	get_you_data
	sub	perform_data,perform_temp8
	php
	bcs	sub_you_fp1
	lm2	perform_data,#0
sub_you_fp1:
	ldy	#FP_OFF
	lda	#2
	jsr	set_you_data
	plp
	rts
;********************************
;	减去hp
;	input:perform_temp8
;********************************
sub_you_hp:
	ldy	#HP_OFF
	jsr	get_you_data
	sub	perform_data,perform_temp8
	php
	bcs	sub_you_hp1
	lm2	perform_data,#0
sub_you_hp1:
	ldy	#HP_OFF
	lda	#2
	jsr	set_you_data
	plp
	rts
;********************************
;	加上A值到指定的数据上<
;	input:A ,Y 
;********************************
adc_obj_1byte:
	clc
	adc	(obj_ptr),y
	bcc	adc_obj_1byte1
	lda	#0ffh
adc_obj_1byte1:
	sta	(obj_ptr),y
	rts
;********************************
;	取目标的busy
;	output:A
;********************************
get_obj_busy:
	bit	obj_flag
	bpl	get_npc_busy
	lda	man_busy
	rts
get_npc_busy:
	lda	npc_busy
	rts
;********************************
;	设置目标的busy
;	input:A
;********************************
set_obj_busy:
	bit	obj_flag
	bpl	set_npc_busy
	sta	man_busy
	rts
set_npc_busy:
	sta	npc_busy
	rts

;********************************
;	取对手的busy
;	output:A
;********************************
get_you_busy:
	bit	obj_flag
	bpl	get_you_busy1
	lda	npc_busy
	rts
get_you_busy1:
	lda	man_busy
	rts
;------------------
set_you_busy:
	bit	obj_flag
	bpl	set_you_busy1
	sta	npc_busy
	rts
set_you_busy1:
	sta	man_busy
	rts
;********************************
;	根据obj_flag来决定
;	攻击人还是NPC
;********************************
attack_xxx:
	bit	obj_flag
	bpl	attack_xxx_1
	;man
	jsr	attack_npc
	rts
attack_xxx_1:
	;npc
	jsr	attack_man
	rts
;********************************
;	取人或NPC的kf_level
;	input:kf_type
;	outpu:skill_level
;********************************
query_obj_skill:
	bit	obj_flag
	bpl	query_npc
	jsr	query_skill
	rts
query_npc:
	jsr	query_npc_skill
	rts
;********************************
;	根据obj_flag
;	来取对手的功夫
;********************************
query_you_skill:
	bit	obj_flag
	bpl	opp_is_npc
	jsr	query_npc_skill
	rts
opp_is_npc:
	jsr	query_skill
	rts
;********************************
;	根据obj_flag
;	来取对手的weapon
;********************************
get_you_weapon:
	bit	obj_flag
	bpl	get_you_weapon1
	lda	npc_weapon
	rts
get_you_weapon1:
	lda	man_weapon
	rts
;********************************
;	根据obj_flag
;	来设置对手weapon
;	input: A
;********************************
set_you_weapon:
	bit	obj_flag
	bpl	set_you_weapon1
	and	npc_weapon
	sta	npc_weapon
	rts
set_you_weapon1:
	;从菜单选项中去掉武器
	lda	man_weapon
	jsr	find_goods
	dec	man_goods+1,x
	lm	man_weapon,#0
	lm	man_damage,#0
	rts
	
;********************************
;	根据obj_flag
;	来清楚相应的数组
;********************************
clear_xxx_ptemp:
	jsr	find_ptemp
	bit	obj_flag
	bpl	clear_npc_ptemp
	lda	#0
	sta	ptemp+2,y
	sta	ptemp+4,y
	rts
clear_npc_ptemp:
	lda	#0
	sta	npc_ptemp+2,y
	sta	npc_ptemp+4,y
	rts
;********************************
;	use skills_power
;********************************
skill_xxx_power:
	bit	obj_flag
	bpl	skill_npc_powerx
	jsr 	skill_power
	rts
skill_npc_powerx:
	jsr 	skill_npc_power
	rts

;----------------------------
	end
