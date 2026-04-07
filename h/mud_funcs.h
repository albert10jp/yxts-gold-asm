;....................................................................
;Break ”√ 3 Byte: db 0, break_num, break_bank
;                 ---------------------------
;break_num  b6~b0 128 service num
;break_bank b7=0:Flash(RAM bank) 1:BUSROM
;....................................................................
BK2_FUN macro number
	jsr	bank_serve
	db	number
	endm

__base	equ	0
	define	1,_Ffight
	define	1,_Finput_new
	define	1,_Fcheck_pwd
	define	1,_Fnetfight
	define	1,_Ffinal_fight

__base	equ	0c0h	
	define	1,_Fcheat

__base	equ	80h
	define	1,_Fbaishi
	define	1,_Fscroll
	define	1,_Fload_file
	define	1,_Fsave_file
	define	1,_Fdelete_file
	define	1,_Fpanyan
	define	1,_Fending
	define	1,_Frank
