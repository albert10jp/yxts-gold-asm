	public	game
game:
	BREAK_FUN	_Bclear_screen
	move	msg,ScreenBuffer,#msg_len
	UPDATELCD
	READKEY
	cmp	#'y'
	beq	delete_file
	rts

delete_file:
	move	file_name,FileName,#name_len
	BREAK_FUN	__do_unlink
	rts

file_name	db	'/gmud.sav',0
name_len	equ	$-file_name

msg		db	'    本程式將刪除英雄'
		db	'壇說Ｘ的存擋，是否執'
		db	'行(Y/N)?'
msg_len		equ	$-msg
