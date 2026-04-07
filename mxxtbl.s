	public	lcd_start_addr_tbl

lcd_start_addr_tbl:
l	=	0		
	rept	80
	dw	l
l	=	l+CPR
	endr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	end
