	include	h/gmud.h
	include	h/func.mac
	
	public	rank
	
	extrn	format_string
	extrn	divid42
	extrn	divid2
	extrn	message_box
	extrn	message_box_more

__base	equ	game_buf
	define	1,do_kill
	define	2,rank_desc

rank:
	ldx	guan_kill
	lda	man_daode
	bmi	ending_1
	ldx	si_kill
ending_1:	
	stx	do_kill

	lda	man_daode
	cmp	#BADMAN
	bcs	ranking1
	lda	man_per
	cmp	#32
	bcc	ranking1
	lda	si_kill
	cmp	#100
	bcc	ranking1
	lm2	rank_desc,#rank5
	jmp	ranking_end
ranking1:	
	lda	man_daode
	cmp	#GOODMAN
	bcc	ranking2
	lda	guan_kill
	cmp	#60
	bcc	ranking2
	lda	man_per
	cmp	#22
	bcc	ranking2
	lm2	rank_desc,#rank6
	jmp	ranking_end
ranking2:
	lda	npc_kill
	bne	ranking3
	lda	guan_kill
	bne	ranking3
	lm2	rank_desc,#rank7
	jmp	ranking_end
ranking3:
	lda	man_daode
	bmi	ranking4
	lda	si_kill
	cmp	#108
	bcc	ranking5
	lm2	rank_desc,#rank2
	jmp	ranking_end
ranking4:
	lda	guan_kill
	cmp	#64
	bcc	ranking5
	lm2	rank_desc,#rank8
	jmp	ranking_end
ranking5:
	lda	npc_kill
	cmp	#120
	bcc	ranking6
	lm2	rank_desc,#rank4
	jmp	ranking_end
ranking6:
	lda	man_gender
	beq	ranking7
	lda	man_per
	cmp	#36
	bcc	ranking7
	lda	man_age
	cmp	#30
	bcs	ranking7
	lm2	rank_desc,#rank9
	jmp	ranking_end
ranking7:
	lda	game_hour+1
	bne	ranking8
	lda	game_hour
	cmp	#48
	bcs	ranking8
	lm2	rank_desc,#rank3
	jmp	ranking_end
ranking8:
	cmp2	top_dance,#300
	bcc	ranking9
	lm2	rank_desc,#rank10
	jmp	ranking_end
ranking9:
	cmp2	top_ball,#300
	bcc	ranking10
	lm2	rank_desc,#rank11
	jmp	ranking_end
ranking10:	
	lm2	rank_desc,#rank1
ranking_end:	
	BREAK_FUN	_Bclrscreen
	lm	large_size_flag,#0
	lm2	string_ptr,#pingding
	jsr	format_string
	lm	x0,#6
	lm	y0,#3
	lm	x1,#156
	lm	y1,#77
	jsr	message_box
	lm2	string_ptr,#end2
	lda	man_daode
	cmp	#GOODMAN
	bcs	ending_2
	cmp	#BADMAN
	bcc	ending_2
	lm2	string_ptr,#end1
ending_2:
	lm	x0,#6
	lm	y0,#3
	lm	x1,#156
	lm	y1,#77
	jsr	message_box_more
	rts
;----------------------------------------
	if	scode
pingding:
	db	'时间      ',2
	dw	game_hour,10
	db	':',1
	dw	game_min,0
	db	'杀NPC数   ',1
	dw	npc_kill,0
	db	'追杀数    ',1
	dw	do_kill,0
	db	'名声      ',1
	dw	man_daode,0
	db	'等级评定  ',8
	dw	rank_desc,0
	db	0
rank1:	
	db	'普通菜鸟',0
rank2:	
	db	'浪子杀手',0
rank3:	
	db	'神行太保',0
rank4:
	db	'冷血屠夫',0
rank5:
	db	'邪恶天使',0
rank6:
	db	'盖世大侠',0
rank7:
	db	'好好先生',0
rank8:
	db	'无情名捕',0
rank9:
	db	'绝代佳人',0
rank10:
	db	'舞林高手',0
rank11:
	db	'灌篮高手',0
	
end1:
	db	'    〃喂，喂！醒醒！太阳都晒到屁股了．再不起床就要迟到啦．〃',0
	db	'    ？？？',0
	db	'    一阵忙乱之后．',0
	db	'    〃有没有搞错？今天可是星期日啊！〃',0
	db	'    ．．．．．．',0,0
end2:	
	db	'    终于着陆了．',0
	db	'    眼前是一个嘈杂的市场，到处都是蓝眼睛白皮肤的外国人，而且装扮也很奇怪．',0
	db	'    〃请问，这里是拍片现场吗？〃',0
	db	'    〃WHAT YOU SAY？〃',0
	db	'    不会吧？竟然来到了中世纪的欧洲．',0
	db	'    MY GOD！',0,0

	else
pingding:
	db	'丁      ',2
	dw	game_hour,10
	db	':',1
	dw	game_min,0
	db	'炳NPC计   ',1
	dw	npc_kill,0
	db	'發炳计    ',1
	dw	do_kill,0
	db	'羘      ',1
	dw	man_daode,0
	db	'单蝶﹚  ',8
	dw	rank_desc,0
	db	0
rank1:	
	db	'炊硄垫尘',0
rank2:	
	db	'炳も',0
rank3:	
	db	'︽び玂',0
rank4:
	db	'﹀監ひ',0
rank5:
	db	'ǜ碿ぱㄏ',0
rank6:
	db	'籠獿',0
rank7:
	db	'ネ',0
rank8:
	db	'礚薄',0
rank9:
	db	'荡ㄎ',0
rank10:
	db	'籖狶蔼も',0
rank11:
	db	'拈膞蔼も',0
	
end1:
	db	'    〔侈侈眶眶び锭常Ьぃ癬碞璶筐罢〔',0
	db	'    ',0
	db	'    皚Γ睹ぇ',0
	db	'    〔Τ⊿Τ穌岿さぱ琌琍戳ら摆〔',0
	db	'    ',0,0
end2:	
	db	'    沧帝嘲',0
	db	'    泊玡琌顾馒カ初矪常琌屡泊氟フブ涧瓣τ杆ш┣',0
	db	'    〔叫拜硂柑琌╃瞷初盾〔',0
	db	'    〔WHAT YOU SAY〔',0
	db	'    ぃ穦澈礛ㄓい稼瑆',0
	db	'    MY GOD',0,0
	endif

	end
