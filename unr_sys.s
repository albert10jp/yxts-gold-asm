
	include h/vector.h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	起始字符	格式含义
;	字母		BIOS 提供例程
;	_B		ACTIVE BIOS 提供例程
;;;;;;;;; BELOW IS AT BIOS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	vector	bin2digit
	vector	enter_sleep
	vector	enter_sleepz		
	vector	start_4ch
	vector	stop_4ch
	vector	bell		
	vector	key_click_bell
	vector	mspeed4	
	vector	speed7	
	vector	speed5	
	vector	cspeed	
	vector	mspeed	
	vector	delay_time
	vector	delay_time1
	vector	wait_1_sec	
	vector	wait_160_ms
	vector	isdigit	
	vector	enable_dac_out
	vector	disable_dac_out		

	vector	start_sound		
	vector	stop_sound		
	vector	out_celp_data
	vector	TTS_Sleep
	vector	TTS_Wakeup	
	vector	TTS_Reset
	vector	Adj_Volume		
	vector	wait_dsp1_ready
	vector	move_to_ram
	vector	get_8x8_font
					;io.s	
	vector	ProcKey
	vector	Proc_Key
	vector	case
					;prockey.s
	vector	TwoHz
					;nmi.s
	vector	gysdata
					;gysdata.s
	vector	playdt
					;kbd.s
	vector	set_alarm_on
					;set_alarm_on.s
	vector	get_next_data
					;adpcm.s
	vector	getunicode
	vector	log_to_ph
					;get_unicode.s
	vector	oldmon
					;oldmon.s
	vector	ExeFile
	vector	move_rbuf_databuf
	vector	move_databuf_wbuf
	vector	phyWrite_512B
	vector	phyWrite_16B
	vector	phyRead_16B
	vector	phyRead_512B
	vector	PhyReadBytes
	vector	NgffsMoveData
					;ngffs_bios.s
	vector	disp_icon
					;comm_irq.s
	vector	downexec
					;downexec.s
	vector	proc_menuI		; 通用菜单程序
;-----------------------------------------------
	end
