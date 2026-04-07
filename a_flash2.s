	include	h/id.h

DEF_FLASH2_FUN	macro	label
		extrn	label
		dw	label
		endm

dd	macro	val
	dw	val%65536
	dw	val/65536
	endm

text_class_tbl:
	dw	npc_data_tbl	;name
	dw	npc_data_tbl	;data
	dw	other_addr_tbl	;other

	DEF_FLASH2_FUN	bank2_hello
	DEF_FLASH2_FUN	panyan
	DEF_FLASH2_FUN	stage_weapon
npc_data_tbl:
	dw	ailike
	dw	babarian
	dw	eshen
	dw	huatuo
	dw	liliehu
	dw	nakelu
	dw	suolaisi
	dw	taishan
	dw	wangliehu
	dw	zhangliehu
	dw	zhaoliehu
	dw	gehong
	dw	huayue
	dw	kongxu
	dw	liusun
	dw	maoai
	dw	maogu
	dw	maoying
	dw	mingyue
	dw	qingfeng
	dw	zhangboyu
	dw	laolongwang
	dw	longguard
other_addr_tbl:

	include	data/npc_data_patch

	end

