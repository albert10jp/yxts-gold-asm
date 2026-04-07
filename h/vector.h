;注: 24exp 的跳转表从 c000h 开始放
__base	equ	0e006h	
vector	macro	labl
	public	labl
	define	3,labl
	endm
