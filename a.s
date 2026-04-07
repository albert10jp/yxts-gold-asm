	db	0aeh,0eeh,0eah
	dw	2000h
	dw	2000h
	
	extrn	game
        jmp     game

	db	0d0h,7,30h,3,0ffh,0ffh

	end
