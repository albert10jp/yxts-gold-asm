;;;;;;;;;;;;;;;;;;下載 專用======48 BYTE====================
	db	'Application     '	;目錄名 16byte
	if	scode
	db	'啞踢荎倯抭.bin  '
	;db	'啞踢聆彸唳.bin  '
	else
	db	'白金英雄壇.bin  '	;文件名 16byte
	endif
	db	0f8h,0dfh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;8byte
	db	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	;8byte

	end

