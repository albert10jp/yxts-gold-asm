
DEF_BREAK_FUN	macro	labl
		extrn	labl
		dw	labl
		endm
	db	60h,0eah		;opcode for rts,nop
