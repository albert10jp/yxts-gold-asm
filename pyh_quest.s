;========================================================
;
;	义工任务,送砖石任务
;
;	writen by : pyh		2001/9/5
;	
;
;========================================================
;相关程序:pyh_task.s talk.s
	include	h/id.h
	include	h/gmud.h
	include	h/mud_funcs.h

DELAY_CONST	equ	2

;-------------------

	public	saodi
	public	tiaoshui
	public	pichai
	public	fishing

;-------------------
	extrn	random_it
	extrn	find_goods
	extrn	add_goods
	extrn	format_string
	extrn	show_talk_msg
	extrn	show_talk_msg0
	extrn	wait_key
	extrn	delay_1_sec
	extrn	scroll_to_lcd
;-------------------

__base	equ	game_buf
	define	1,tmp1
	define	1,tmp2
	define	2,varbuf


;-------------------

saodi:
	lm2	a9,#fail_msg
	cmp2	man_hp,#30
	bcc	saodi_1
	sub	man_hp,#30
	lm2	a9,#saodi_msg
	jsr	show_loop_msg
	jmp	show_bonus
saodi_1:
	jsr	show_text
	rts
;-------------------
tiaoshui:
	lm2	a9,#fail_msg
	cmp2	man_hp,#40
	bcc	tiaoshui_1
	sub	man_hp,#40
	lm2	a9,#tiaoshui_msg
	jsr	show_loop_msg
	jmp	show_bonus
tiaoshui_1:
	jsr	show_text
	rts
;-------------------
pichai:
	lm2	a9,#fail_msg
	cmp2	man_hp,#50
	bcc	pichai_1
	sub	man_hp,#50
	lm2	a9,#pichai_msg
	jsr	show_loop_msg
	jmp	show_bonus
pichai_1:
	jsr	show_text
	rts

;-------------------
show_bonus:
	lm2	a9,#over_msg
	jsr	delay_show_text
	lm2	varbuf+2,#20
	lm2	varbuf+4,#10
	lm2	varbuf+6,#50
	add42	man_exp,varbuf+2
	add	man_pot,varbuf+4
	add42	man_money,varbuf+6
	lm2	a9,#bonus_msg
	jsr	show_text
	rts

;********************************************
;
;	钓一次需要80点气血,还不一定钓得着
;
;********************************************
fishing:
	lm2	a9,#diao_gan_msg
	lda	man_equip+HANDS_ARM
	bpl	fish_fail_rts
	and	#7fh
	cmp	#DIAOGAN
	bne	fish_fail_rts
	lm2	a9,#fish_hp_msg
	cmp2	man_hp,#40
	bcc	fish_fail_rts
	sub	man_hp,#40
	lm2	a9,#fish_start_msg
	jsr	show_text
	lm2	a9,#no_fish_msg
	lm2	range,#10		;%50的机率可以钓到一条鱼
	jsr	random_it
	cmp	#5
	bcs	fish_fail_rts
	;success
	lm2	a9,#have_fish_msg
	jsr	show_text
	lm2	a9,#fish_escape_msg
	lda	#YULOU
	jsr	find_goods
	bcc	fish_fail_rts
	lm	goods_id,#FISH
	jsr	add_goods
	lm2	a9,#fish_suc_msg
fish_fail_rts:
	jsr	show_text
	rts
;---------------------------------------------
;	input:a9(loop_msg_addr)
;	destroy:a9
;---------------------------------------------
show_loop_msg:
	lm	tmp1,#0	
show_next_msg:
	lda	tmp1
	beq	show_next_msg1
	lda	#16
	adda2	a9
show_next_msg1:
	jsr	delay_show_text
	inc	tmp1
	cmp1	tmp1,#4
	bcc	show_next_msg
	rts
;----------------
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
	jsr	show_talk_msg
	jmp	scroll_to_lcd
;--------------------
delay_show_text:			;pyh	9-10
	ldy	#0
delay_show_1:
	lda	(a9),y
	sta	img_buf,y
	iny	
	cpy	#200
	bcc	delay_show_1
	lm2	string_ptr,#img_buf
	jsr	show_talk_msg0

	lm	tmp2,#DELAY_CONST
delay_show_3:
	jsr	delay_1_sec
	dbne	tmp2,delay_show_3
	rts
;********************************************msg
	if	scode
bonus_msg:
	db	'你被奖励了：',2
	dw	varbuf+2,10
	db	' 点实战经验 ',2
	dw	varbuf+4,10
	db	' 点潜能 ',2
	dw	varbuf+6,10
	db	' 金钱',0
	db	0
saodi_msg:
 	db	'扫地扫地我扫地',0,0
	db	'地上还有西瓜皮',0,0
    	db	'婆婆家中欠打扫',0,0
    	db	'尘土满天难呼吸',0,0
tiaoshui_msg:
	db	'挑水挑水我挑水',0,0
	db	'倒水进缸水花飞',0,0
	db	'一桶两桶三四桶',0,0
	db	'反正不用交水费',0,0
pichai_msg:
	db	'劈柴劈柴我劈柴',0,0
	db	'抡起斧子劈起来',0,0
	db	'保护树木讲环保',0,0
	db	'婆婆没事别乱烧',0,0
over_msg:
    	db	'费了老大力气,总算干完了',0,0
fail_msg:
     	db	'婆婆呀,手都累软了,我们老板都没你狠',0,0
diao_gan_msg:
        db      '你看著池塘中的鱼,摸了摸肚皮,心中暗自思量:要是现在有个钓杆该多好啊!',0,0
fish_hp_msg:
        db      '现在日头这么毒,以你的体质,恐怕还没钓到鱼就已经...',0,0
fish_start_msg:
        db      '你在土里刨了刨,抓了只小蚯蚓,穿在钓钩上,一挥手,钓线划出一道优美的弧线扎进了水里.你往地上一蹲,开始钓鱼.',0,0
no_fish_msg:
        db      '过了很久也没有鱼上钩,你一收钓竿,到树下乘凉去了!',0,0
have_fish_msg:
        db      '浮子猛然沉了下去,你手急眼快,一提钓竿,有了!',0,0
fish_escape_msg:
        db      '你把鱼从钩上摘下来,猛然想起:坏了,没带鱼篓!一分神,鱼一下子滑到了水里,到手的鱼跑了!',0,0
fish_suc_msg:
        db      '你把鱼放进鱼篓,心里乐开了花,今天的零花钱有著落了!',0,0
	else
bonus_msg:
	db	'砆贱纘',2
	dw	varbuf+2,10
	db	' 翴龟驹竒喷 ',2
	dw	varbuf+4,10
	db	' 翴肩 ',2
	dw	varbuf+6,10
	db	' 窥',0
	db	0
saodi_msg:
 	db	'苯苯и苯',0,0
	db	'临Τ﹁ナブ',0,0
    	db	'盋盋產いろゴ苯',0,0
    	db	'剐骸ぱ螟㊣',0,0
tiaoshui_msg:
	db	'珼珼и珼',0,0
	db	'秈',0,0
	db	'表ㄢ表表',0,0
	db	'はタぃノユ禣',0,0
pichai_msg:
	db	'糀糀и糀',0,0
	db	'绷癬糀癬ㄓ',0,0
	db	'玂臔攫れ量吏玂',0,0
	db	'盋盋⊿ㄆ睹縉',0,0
over_msg:
    	db	'禣ρ,羆衡Ч',0,0
fail_msg:
     	db	'盋盋,も常仓硁,иρ狾常⊿',0,0
diao_gan_msg:
        db      '帝俄い辰,篘篘▄ブ,みい穞秖:璶琌瞷Τ敞赣摆!',0,0
fish_hp_msg:
        db      '瞷ら繷硂瑀,砰借,┤临⊿敞辰碞竒...',0,0
fish_start_msg:
        db      'ń,ъ矻癈,敞筥,揣も,敞絬笵纔┓絬ゃ秈ń.┕蜜,秨﹍敞辰.',0,0
no_fish_msg:
        db      '筁⊿Τ辰筥,Μ敞,攫睤!',0,0
have_fish_msg:
        db      '疊瞨礛↖,も泊е,矗敞,Τ!',0,0
fish_escape_msg:
        db      'р辰眖筥篕ㄓ,瞨礛稱癬:胊,⊿盿辰罬!だ,辰菲ń,も辰禲!',0,0
fish_suc_msg:
        db      'р辰秈辰罬,みń贾秨,さぱ箂窥Τ帝辅!',0,0
	endif

        end
