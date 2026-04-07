;;******************************************************************
;;	system.s - handle system event module
;;
;;	written by lian
;;	begin on 2001/03/26
;;	finish on
;;
;;      ┏━━━━━━━━━━━━━━━━━━━┓
;;      ┃	他过去的许若,是非凡的		┃
;;      ┃	而他现在的所作,则什么也不是	┃
;;      ┗━━━━━━━━━━━━━━━━━━━┛
;;
;;*******************************************************************
	include	h/gmud.h
	include	h/id.h
	include ../prom5/h/ngffs.h

	public	wait_key
	public	release_key
	public	proc_sys_event
	public	delay_1_sec
	public	delay_160_ms

	public	set_tba_buffer
	public	set_get_buf
	public	set_read_buf

	public	getms
	public	setms
	public	gettime
	public	waittime
	public	waittime1
	public	wait_cr_key

	extrn	find_kf
	extrn	flash_cursor
	extrn	mspeed4
	extrn	speed7
	extrn	speed_read

;------------------------------------------------------------------
;Input:	Key
;Output:Areg
;------------------------------------------------------------------
release_key:
	lda	kbd_matrix
	ora	#88h
	sta	kbd_matrix
	lda	kbd_matrix+4
	ora	#8
	sta	kbd_matrix+4
	lda	kbd_matrix+5
	ora	#8
	sta	kbd_matrix+5
	rts

wait_key:
	lm	watch_dog_timer_flag,#0
	lda	key
	bmi	wkey1
	
	MSPEED	2
	lda	walking
	beq	wait_menu
wkey:
	jsr	proc_sys_event
	jsr	sys_refresh
	
	lda	key		;check if 
	bpl	wkey
wkey0:
	MSPEED	7
	lda	key
wkey1:	
	and	#7fh
	sta	key
	rts
wait_menu:
	jsr	proc_sys_event
	jsr	sys_refresh
	ldy	#10h
	ldx	#0
wait_menu1:	
	lda	key
	bmi	wkey0
	dex
	bne	wait_menu1
	dey
	bne	wait_menu1
	jsr	flash_cursor
	jmp	wait_menu

;------------------------------------------------------------------
; handle system event
; no time limit
;------------------------------------------------------------------
proc_sys_event:
	lm	watch_dog_timer_flag,#0
	rts
	
;------------------------------------------------------------------
; set timebase buffer
;------------------------------------------------------------------
set_tba_buffer:
	rts

;----------------------------------------------------------
; system refresh event 
; heart_beat
; !!!注意:在这只能使用AregXregYreg以及专用变量
;----------------------------------------------------------
sys_refresh:
	lda	#TR_s
	sta	RIReg
	lda	RTCVal
	and	#3fh
	cmp	my_second
	bne	sys_refresh1	
	rts
sys_refresh1:	
	sta	my_second
	inc	game_sec
	lda	game_sec
	cmp	#60
	bcc	sys_refresh2
	lm	game_sec,#0
	inc	game_min
	lda	game_min
	cmp	#60
	bcc	sys_refresh2
	lm	game_min,#0
	inc2	game_hour

sys_refresh2:
	;mud系统时间
	inc	mud_age
	bne	age_end
	inc	mud_age+1
	bne	age_end
	inc	mud_age+2
	bne	age_end
	inc	mud_age+3
age_end:
	lm	idlesec,#0

	;战斗 学习 练功 打坐时busy,不恢复气血
	bit	busy_flag
	bpl	to_restore
	rts
to_restore:
	push2	a1
	;恢复(使用变量a1)
	dec	timetick
	jne	tick_end
	lm	timetick,#TICK_TIME
	lda	man_food
	ora	man_food+1
	jeq	tick_end
	dec2	man_food
	lda	man_water
	ora	man_water+1
	jeq	tick_end
	dec2	man_water

	;kee=con/2+maxfp/16
	;在中断中不能破坏变量,所以简化
	lm2	a1,man_maxfp
	rept	4
	lsr	a1h
	ror	a1
	endr
	lda	man_con
	lsr	a
	adda2	a1
	add	man_hp,a1
	cmp2	man_hp,man_effhp
	bcc	tick_fp

	lm2	man_hp,man_effhp
	cmp2	man_effhp,man_maxhp
	bcs	tick_fp
	inc2	man_effhp

tick_fp:
	;fp=skill_level(basic_force)
	;在中断中不能破坏变量,所以简化
	lda	man_maxfp
	ora	man_maxfp+1
	beq	tick_end
	cmp2	man_fp,man_maxfp
	bcs	tick_end

	lda	#BASIC_FORCE_KF
	jsr	find_kf
	bcc	tick_end
	lda	man_kf+1,y
	adda2	man_fp
	cmp2	man_fp,man_maxfp
	bcc	tick_end
	lm2	man_fp,man_maxfp
tick_end:
	pull2	a1
	rts
;------------------------------------------
getms:
	lda	#TR_ms
	sta	RIReg
	lda	RTCVal
	rts
setms:
	lda	#TR_ms
	sta	RIReg
	lda	RTCVal
	sta	my_ms
	rts
gettime:
	lda	#TR_ms
	sta	RIReg
	lda	RTCVal
	sec
	sbc	my_ms
	rts
waittime:
	jsr	setms
waittime1:
	stx	wait_xx+1
        jsr     mspeed4
waittime2:
	jsr	proc_sys_event
	jsr	gettime
wait_xx:	
	cmp	#40
	bcc	waittime2
        jmp     speed7
	
;------------------------------------------
; destroy: areg, xreg
;------------------------------------------
delay_160_ms:
        ldx     #40
	jmp	waittime
delay_1_sec:
        ldx     #240
	jmp	waittime

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;在ram 切BANK 获得数据公用例程
; Input:	bank_no		数据所在的bank号
;		bank_data_ptr	数据表地址
;		bank_data	数据暂存
;		Yreg		数据表偏移量
; Output:	Areg		数据
; Used:		above regist
; Destory:	None
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
set_get_buf:
	tya
	pha
	lm2	SeekOffset,bank_data_ptr
	lm2	DataBufPtr,#data_read_buf
	lm2	DataCount,#100h
	jsr	speed_read
	pla
	tay
	lda	data_read_buf,y
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;在BIOS 切BANK 获得数据公用例程
; Input:	bank_no		数据所在的bank号
;		bank_data_ptr	源数据表地址
;		RecordSize	数据大小
;		data_buf	目的数据地址
; Output:	data_buf	数据地址
; Used:		above regist
; Destory:	None
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
set_read_buf:
	lm2	SeekOffset,bank_data_ptr
	lm2	DataBufPtr,data_buf
	lm2	DataCount,RecordSize
	jsr	speed_read
	rts

;------------------------------------------
wait_cr_key:
	jsr	wait_key
	cmp	#CR_KEY
	bne	wait_cr_key
	rts
;---------------------------------------------------------------
	end
