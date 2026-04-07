;;******************************************************************
;;	save.s - 档案存取程式
;;
;;	written by lian
;;	modify by pyh 2001/11/05,because file system has changed.
;; difference between ver1.0 and ver2.0 is:
;;	ver2.0 add: secret checksum
;;
;;******************************************************************
	include	h/gmud.h
	include	h/mud_funcs.h
        include ../prom5/h/ngffs.h

	public	save_file
	public	load_file
	public	delete_file

	extrn	getms

file_buf	equ	img_buf
	
;------------------------------------------------------------------
; save archives
; if archives exit then
;	replace archives <== file_buf
; else
;	create new archives <== file_buf
; input:a1(地址指针),a2(长度)
;------------------------------------------------------------------
save_file:
	jsr	set_save_data	;<==file_buf == pointer to data

	move	file_name,FileName,#name_len
       	lm      FileOpenMode,#O_WRONLY_
	BREAK_FUN	__do_open
	bcc	replace_file
	cmp1	FileErrorCode,#ENOENT
	beq	new_file
	jmp	err_rts

replace_file:
	lm2	DataBufPtr,#file_buf
	lm2	DataCount,#SAVE_SIZE+8
	BREAK_FUN	__do_write
	jcc	close_file
	jmp	err_close_rts

;---------------------------------------
new_file:
        move    file_name,FileName,#name_len          ;创建文件
       	lm      FileOpenMode,#O_CREAT_|O_WRONLY_
	lm	FileAttr,#_R_OK|_W_OK|0fh^HID_OK
	lm	FileAttr+1,#0ffh
        BREAK_FUN      __do_open
        jcs     err_rts

	lm2	DataBufPtr,#file_buf
	lm2	DataCount,#SAVE_SIZE+8
	BREAK_FUN	__do_write
	jcc	close_file
	jmp	err_close_rts

;------------------------------------------------------------------
; input: save_data
; ouput: file_buf
;------------------------------------------------------------------
set_save_data:
	jsr	get_checksum
	la	a1,save_data
	la	a2,file_buf
	lm2	a3,#SAVE_SIZE
	jsr	my_move
	la	a2,file_buf+SAVE_SIZE
	ldy	#0
set_save_data_loop:
	lda	bank_text,y
	sta	(a2),y
	iny
	cpy	#CHECK_SIZE
	bne	set_save_data_loop
	lda	game_second_m2
	sta	(a2),y
	eor	#99h
	sta	a1
	iny
	jsr	getms
	sta	(a2),y
	eor	#66h
	sta	a1h
	jsr	secret
	rts

;------------------------------------------------------------------
; load archives
; if archives exit then
;	load archives ==> file_buf
; else
;	ERROR
; input:a1(地址指针),a2(长度)
;------------------------------------------------------------------
load_file:
	move	file_name,FileName,#name_len
       	lm      FileOpenMode,#O_RDONLY_
	BREAK_FUN	__do_open
	bcc	to_open_file
	jmp	err_rts

to_open_file:
	lm2	DataBufPtr,#file_buf
	lm2	DataCount,#SAVE_SIZE+8
	BREAK_FUN	__do_read
	cmp2	DataCount,#SAVE_SIZE+8
	beq	Read_Sucess
	jmp	err_close_rts
Read_Sucess:
	jsr	set_load_data	;lee 
	BREAK_FUN	__do_close
	jsr	check_pid	;lee
	bcc	$+3
	rts
	jsr	delete_file
	clc
	rts

;------------------------------------------
;input: file_buf
;ouput: save_buf bank_text
;------------------------------------------
set_load_data:
	la	a2,file_buf+SAVE_SIZE
	ldy	#6
	lda	(a2),y
	eor	#99h
	sta	a1
	iny
	lda	(a2),y
	eor	#66h
	sta	a1h
	jsr	secret
	la	a2,save_data
	la	a1,file_buf
	lm2	a3,#SAVE_SIZE
	jsr	my_move
	la	a2,file_buf+SAVE_SIZE
	ldy	#0
set_load_data_loop:
	lda	(a2),y
	sta	bank_text,y
	iny
	cpy	#CHECK_SIZE
	bne	set_load_data_loop
	rts

my_move:
	ldy	#0
move_cont:
	lda	(a1),y
	sta	(a2),y
	dec2	a3
	lda	a3
	ora	a3h
	beq	move_end
	iny
	bne	move_cont
	inc 	a1h
	inc	a2h
	jmp	move_cont
move_end:
	rts
;------------------------------------------
; delete archives
; if archives exit then
;	delete archives
;------------------------------------------
delete_file:
	move	file_name,FileName,#name_len
	BREAK_FUN	__do_unlink
	rts

;------------------------------------------
err_close_rts:
	BREAK_FUN 	__do_close
err_rts:	
	clc
	rts

close_file:
	BREAK_FUN	__do_close
	sec
	rts

file_name	db	'/gmud.sav',0
name_len	equ	$-file_name

;------------------------------------------------
;	set 校验码
;purpose:计算存盘数据的校验码(6bytes)
;input: a1(check_data)
;ouput: bank_text
;destroy: 
;------------------------------------------------
get_checksum:
	la	a1,save_data+5
	lm2	a2,#SAVE_SIZE-5
	lda	#0
	sta	bank_text
	sta	bank_text+1
	sta	bank_text+2
	sta	bank_text+3
	sta	bank_text+4
	sta	bank_text+5
	ldy	#0
check_loop:
	lda	(a1),y
	tax
	eor	bank_text+5
	sta	bank_text+5
	txa
	clc
	adc	bank_text+3
	sta	bank_text+3
	bcc	get_checksum_0
	inc	bank_text+4
get_checksum_0:
	lda	ecc_tbl,x
	and	#3fh
	eor	bank_text+2
	sta	bank_text+2
	lda	ecc_tbl,x
	and	#40h
	beq	get_checksum_1
	tya
	eor	bank_text
	sta	bank_text
	tya
	eor	#0ffh
	eor	bank_text+1
	sta	bank_text+1
get_checksum_1:
	dec2	a2
	lda	a2
	ora	a2h
	beq	check_end
	iny
	bne	check_loop
	inc	a1h
	jmp	check_loop
check_end:
	lda	bank_text+2
	eor	#0ffh
	asl	a
	asl	a
	ora	#3
	sta	bank_text+2
	rts
	
;---------------------------------------------------------------
;purpose: 加密或解密存盘数据
; input: 
;	 a1(密码种子)
;	 file_buf+5(明文或密文)
;	 SAVE_SIZE-5+CHECK_SIZE(数据长度[应小于256])
;output:
;	 file_buf+5(密文或明文)
;---------------------------------------------------------------
DA_ZI	equ	65533

secret:
	lda	a1
	eor	#'J'
	sta	my_seed0+1
	lda	a1h
	eor	#'L'
	sta	my_seed1+1
	la	a4,file_buf+5
	lm2	a5,#SAVE_SIZE+1
	ldy	#0
change_loop:
	jsr	my_random
	lda	(a4),y
	eor	a3
	sta	(a4),y
	inc2	a4
	dec2	a5
	lda	a5
	ora	a5h
	bne	change_loop
	rts	

my_random:
my_seed0:
	lda	#0aah
	sta	a1
my_seed1:
	lda	#55h
	sta	a1h
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
					;a1xa2,乘积的低16bit->a3
		ldx	#16		;高16bit->a2
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

ecc_tbl:
	db	0h,55h,56h,3h,59h,0ch,0fh,5ah,
	db	5ah,0fh,0ch,59h,3h,56h,55h,0h,
	db	65h,30h,33h,66h,3ch,69h,6ah,3fh,
	db	3fh,6ah,69h,3ch,66h,33h,30h,65h,
	db	66h,33h,30h,65h,3fh,6ah,69h,3ch,
	db	3ch,69h,6ah,3fh,65h,30h,33h,66h,
	db	3h,56h,55h,0h,5ah,0fh,0ch,59h,
	db	59h,0ch,0fh,5ah,0h,55h,56h,3h,
	db	69h,3ch,3fh,6ah,30h,65h,66h,33h,
	db	33h,66h,65h,30h,6ah,3fh,3ch,69h,
	db	0ch,59h,5ah,0fh,55h,0h,3h,56h,
	db	56h,3h,0h,55h,0fh,5ah,59h,0ch,
	db	0fh,5ah,59h,0ch,56h,3h,0h,55h,
	db	55h,0h,3h,56h,0ch,59h,5ah,0fh,
	db	6ah,3fh,3ch,69h,33h,66h,65h,30h,
	db	30h,65h,66h,33h,69h,3ch,3fh,6ah,
	db	6ah,3fh,3ch,69h,33h,66h,65h,30h,
	db	30h,65h,66h,33h,69h,3ch,3fh,6ah,
	db	0fh,5ah,59h,0ch,56h,3h,0h,55h,
	db	55h,0h,3h,56h,0ch,59h,5ah,0fh,
	db	0ch,59h,5ah,0fh,55h,0h,3h,56h,
	db	56h,3h,0h,55h,0fh,5ah,59h,0ch,
	db	69h,3ch,3fh,6ah,30h,65h,66h,33h,
	db	33h,66h,65h,30h,6ah,3fh,3ch,69h,
	db	3h,56h,55h,0h,5ah,0fh,0ch,59h,
	db	59h,0ch,0fh,5ah,0h,55h,56h,3h,
	db	66h,33h,30h,65h,3fh,6ah,69h,3ch,
	db	3ch,69h,6ah,3fh,65h,30h,33h,66h,
	db	65h,30h,33h,66h,3ch,69h,6ah,3fh,
	db	3fh,6ah,69h,3ch,66h,33h,30h,65h,
	db	0h,55h,56h,3h,59h,0ch,0fh,5ah,
	db	5ah,0fh,0ch,59h,3h,56h,55h,0h,
;------------------------------------------------
;	是gmud存盘文件吗?
; input: game_pid (4bytes) game_ver bank_text
; output: cy (sec:suc)
;------------------------------------------------
check_pid:
	cmp4	game_pid,pid_msg
	bne	pid_fail
	cmp1	game_ver,#VERSION	;版本不对
	bne	pid_fail

	move	bank_text,bank_text+CHECK_SIZE,#CHECK_SIZE
	jsr	get_checksum

	ldx	#CHECK_SIZE-1
pid_loop:
	lda	bank_text,x
	cmp	bank_text+CHECK_SIZE,x
	bne	pid_fail
	dbpl	x,pid_loop
	sec
	rts
pid_fail:
	clc
	rts

pid_msg		db	'HERO'

	end
