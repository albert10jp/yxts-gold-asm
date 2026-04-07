
		include ./h/neteg.h
		include ./h/gmud.h

		public	CommunicateInit

		public	SendData
		public	send_data
		
		public	ReceiveData
		public	receive_data

		public	CommunicateExit

		extrn	oldmon


;;;;;;;;;;;;;;;;;;
enable_UCE      macro
        switch_BK       0
        lda     #04h
        sta     IVReg
        endm

disable_UCE     macro
        switch_BK       0
        lda     #00h
        sta     IVReg
        endm

;--------------------------------------------------------------------
;Name:		CommunicateInit
;Input:		none
;Ouput:		none
;Function:	第一次进入通讯时,必须调用!!!!
;====================================================================
CommunicateInit:
		
		jsr	DriverEnable	
		jsr	InitRegister
		jsr	WaitPLL		; 等待 UART 的锁相环稳定		

		rts

DriverEnable:
		enable_UART		; enable UART	
		enable_UCE		; enable UART clock
		jsr	InitBrui	; initial brui

		Enable_Irda		; enable transeceiver
		switch_BK	0

		rts			

;--------------------------------------------------------------------
;Name:		CommunicateExit
;Input:		none
;Ouput:		none
;Function:	退出通讯时,必须调用!!!!
;====================================================================

CommunicateExit:

		Disable_Irda
		disable_UCE
		disable_UART

		rts	


;-------------------------------------------------------------------
;Name:		SendData
;Input:		data_size		;等待发送的数据长度
;		(data_buf)的数据
;
;Output:	cy = 1	发送失败, a 存放失败原因
;		cy = 0	发送成功			
;
;Function:	尽力发送上层给出的数据,直到 超时/按键 退出
;
;Status:
;===================================================================
send_data:
SendData:

		jsr	SetOverTime	;设定空等待的最大时间

		jsr	AreYouReady	;询问接收方是否 准备好
		jsr	JudgeReturn

		jsr	JudgeCommonFlag	;对是否收次进入进行判断		

		jsr	GiveYouData	;发送数据
		jsr	JudgeReturn	

		jsr	SendDataOver	;告知接收方 发送结束
		jsr	JudgeReturn	

		jmp	Success		
	
;--------------------------------------------------------------------
;Name:		ReceiveData
;Input:		None
;Output:	cy = 1  接收失败, a 指出出错原因
;		cy = 0	成功接收数据, data_size 长度 data_buf数据	
;				
;		ConnectADD 连接地址,由第一次连接时确立,后面沿用
;		Sequence 数据包的序列号,通讯过程中应为一个连续的值
;
;Function:	接收数据,保存于 data_buf
;
;Status:
;====================================================================
receive_data:
ReceiveData:
		jsr	SetOverTime	;设定空等待的最大时间

		jsr	IamReady	;等待发送方的连接
		jsr	JudgeReturn

		jsr	JudgeCommonFlag	;对是否收次进入进行判断		

		jsr	ReceiveSave	;接收数据保存
		jsr	JudgeReturn	

		jsr	YesIKnow	;等待对方断开连接
		jsr	JudgeReturn

		jmp	Success			

;------------------
;程序退出的两个出口
;==================

Success:	
		clc			;成功 发送/接收数据
		php
		jmp	GoBack
Failure:
		sec			;发送/接收数据 失癮
		php
GoBack:
		plp	
		rts

;------------------------------------------------------------------
;Name:		JudgeReturn
;Input:		ReturnCode
;Output:	none
;Function:	对 ReturnCode 进行判断, 失败则直接跳 Failure		
;==================================================================
JudgeReturn:
		lda	ReturnCode
		cmp	#TRUE
		bne	ErrorReturn
		rts
ErrorReturn:
		pla
		pla

		dec	ReturnCode
		lda	ReturnCode	; A 中放出错原因
		jmp	Failure
;-------------------------------------------------------------
;Input:		GameCommonFlag
;Output:	GameCommonFlag
;Function:	判断是否第一次进入,对GameCommonFlag 进行处理	
;=============================================================
JudgeCommonFlag:
		lda	GameCommonFlag
		and	#80h
		beq	EndJudgeFlag

		lda	GameCommonFlag
		and	#7fh
		sta	GameCommonFlag
EndJudgeFlag:
		rts		

;---------------------------------------------------------------------
;Name:		ReceiveSave
;Input:
;Output:	ReturnCode
;		data_size
;		data_buf 	data_buf指向的地址区域J
;Function:
;Status:	
;======================================================================

ReceiveSave:
		lm2	StartAddress,data_buf	;初始化起始地址
		lm2	DataReceived,#00h				
RS_Loop:
		lm	SelfFrameType,#DATA_FRAME	

		jsr	ReceiveResponse

		lda	ReturnCode
		cmp	#TRUE
		bne	EndReceiveSave	

		lm2	B2R1,#S_RecvBuffer+04h
		lm2	B2R0,StartAddress

		lda	GameRecvLength
		sec
		sbc	#05h
		sta	B1R0

		jsr	NormalMove

		clc		
		lda	StartAddress		;移动 地址指针
		adc	B1R0
		sta	StartAddress

		lda	StartAddress+1
		adc	#00h
		sta	StartAddress+1		

		clc
		lda	DataReceived		;计算 收到的数据长度
		adc	B1R0
		sta	DataReceived

		lda	DataReceived+1
		adc	#00h
		sta	DataReceived+1

		lm	data_size,DataReceived	;存入 data_size

		lda	RecvSequence
		and	#80h
		bne	RS_Loop	
	
		lm	ReturnCode,#TRUE			

EndReceiveSave:
		rts

;-----------------------------------------------------------------
;Name:		IamReady
;Input:		GameCommonFlag
;		ConnectADD
;		Sequence
;	
;Output:	ReturnCode = TRUE 	;成功
;			   = ESC_KEY	;按键退出
;			   = TIME_OUT	;超时退出
;	
;Function:	与发送方进行握手		
;Status:	
;=================================================================

IamReady:
		lm	SelfFrameType,#CONNECT_FRAME

		lda	GameCommonFlag
		and	#80h
		bne	IamReadyStep1
		
		lm	SelfFrameType,#CONNECT_FRAME+1

IamReadyStep1:
		jsr	ReceiveResponse
		rts				

;------------------------------------------------------------------
;Name:		YesIKnow
;Input:		None
;Output:	ReturnCode
;Function:
;Status:					
;==================================================================

YesIKnow:
		lm	SelfFrameType,#DISC_FRAME
		jsr	ReceiveResponse

		lda	ReturnCode
		cmp	#TRUE
		bne	EndIKnow		
EndIKnow:
		rts		

;------------------------------------------------------------------
;Name:		ReceiveResponse
;Input:		SelfFrameType		
;
;Output:	ReturnCode = TRUE ;成功
;		GameRecvLength	收到的数据流的长度					
;		S_RecvBuffer 中的数据
;		RecvFrameType
;		RecvSequence			
;
;		= ESC_KEY	;按键退出
;	  	= TIME_OUT	;超时退出
;		 	
;Function:	接收发送方的数据包,并进行回应
;		并对 Brui 的硬件故障进行排除				
;==================================================================

ReceiveResponse:
		lm	ErrorCount,#0ffh
RecvRespLoop:
		inc	ErrorCount

		lda	ErrorCount
		cmp	#MAX_ERR_TIMES		;连续不能收到数据, Brui出现故障
		bne	RecvRespGo

		lm	ErrorCount,#0ffh	
		jsr	DriverEnable		;此处为 硬件BUG 打的补丁

RecvRespGo:
		jsr	CheckOverTime

		lda	ReturnCode	
		cmp	#TRUE
		bne	End_RR

		lda	#TIME_OUT_100ms
		jsr	SetTimeOut		

		lm2	B2R0,#S_RecvBuffer
		jsr	ReceivePacket

		lda	ReturnCode
		cmp	#TRUE
		jne	RecvRespLoop

		jsr	RecvNormalCheck		;进行逻辑检查

		lda	ReturnCode
		cmp	#FALSE
		jeq	RecvRespLoop

		lda	RecvSequence
		and	#7fh
		sta	Sequence		;保存序列号				

		lm	FrameType,RecvFrameType	;保存 FrameType			

		jsr	SendResponse		;进行回应

		lda	ReturnCode
		cmp	#TRUE
		beq	End_RR
		
		jmp	RecvRespLoop		
End_RR:
		rts		

;--------------------------------------------------------------------
;Name:		GiveYouData
;Input:		data_size		;待发送数据的长度
;		daat_buf存放的数据	
;
;Output:	ReturnCode				
;
;====================================================================

GiveYouData:	
		lm2	StartAddress,data_buf
		lm2	DestAddress,#F_SendBuffer

		lm	DataLeft+1,#00h
		lda	data_size
		sta	DataLeft+0

		bne	GiveDataStep1
		
		lm	DataLeft+1,#01h		;数据长度为 256 bytes

GiveDataStep1:
		lm	DataLength,#MAX_DATA_LENGTH	

		lda	DataLeft+1
		bne	GiveDataStep2		;数据长 256 bytes

		lda	DataLeft+0
		cmp	#MAX_DATA_LENGTH	
		bcs	GiveDataStep2		;实际数据 > MAX_DATA_LENGTH
		
		lm	DataLength,DataLeft+0	;取数据的实际长度

GiveDataStep2:
		sec
		lda	DataLeft+0
		sbc	DataLength
		sta	DataLeft+0
		
		lda	DataLeft+1
		sbc	#00h
		sta	DataLeft+1		;计算剩余数据的长度

		lm	FrameType,#DATA_FRAME	;设定帧的类型

		lda	ConnectADD
		ora	#80h
		sta	ConnectADD		;设定为发送方

		lda	Sequence
		ora	#80h
		sta	Sequence		

		lda	DataLeft+0
		ora	DataLeft+1
		bne	GiveDataStep3		;判断是否有后续数据

		lda	Sequence
		and	#7fh
		sta	Sequence
GiveDataStep3:
		jsr	FormPacket		; 打包

		jsr	RequestConfirm		

		lda	ReturnCode
		cmp	#TRUE
		bne	EndGiveData

		lda	DataLeft+0
		ora	DataLeft+1
		beq	EndGiveData

		clc
		lda	StartAddress+0
		adc	DataLength
		sta	StartAddress+0
		lda	StartAddress+1
		adc	#00h
		sta	StartAddress+1		;计算起始地址

		jmp	GiveDataStep1

EndGiveData:
		rts

;---------------------------------------------------------------------
;Name:		AreYouReady
;Input:		game_second_m2	;时间标志
;		ConnectADD	;连接地址
;Output:	cy = 0		;success
;		cy = 1,a = KEY_EXIT / OVER_EXIT	;按键/超时 退出 
;
;Function:	发送不含数据的包,测试对方能否回应	
;
;Status:	尚未测试	
;=====================================================================

AreYouReady:
		jsr	IncreaseSequence

		lm	FrameType,#CONNECT_FRAME

		lda	GameCommonFlag
		and	#80h
		bne	AreYouStep1			

		lm	FrameType,#CONNECT_FRAME+1
AreYouStep1:
		lda	ConnectADD
		ora	#80h
		sta	ConnectADD			; 设定自己为 发送方

		lda	Sequence
		ora	#80h
		sta	Sequence

		lm	DataLength,#00h			; 空包,不带数据
		lm2	DestAddress,#F_SendBuffer	; 数据包的存放地址

		jsr	FormPacket			; 打包
		jsr	RequestConfirm			
		rts	

;---------------
;=======================================================
DecreaseSequence:
		dec	Sequence
		lda	Sequence
		and	#7fh
		sta	Sequence
		rts

IncreaseSequence:
		inc	Sequence
		lda	Sequence
		and	#7fh
		sta	Sequence
		rts
;----------------------------------------------------------------------
;Name:		SendDataOver		
;Input:		None
;Output:	ReturnCode
;Function:	表明数据传输过程结束	
;======================================================================

SendDataOver:
		lm	FrameType,#DISC_FRAME

		lda	ConnectADD
		ora	#80h
		sta	ConnectADD			; 设定自己为 发送方

		lda	Sequence
		and	#7fh
		sta	Sequence

		lm	DataLength,#00h			; 空包,不带数据
		lm2	DestAddress,#F_SendBuffer	; 数据包的存放地址

		jsr	FormPacket		
		jsr	RequestConfirm			

		jsr	DecreaseSequence		;与 AreYouReady 中的 Increase 对应

		rts	
;--------------------------------------------------------------------
;Name:		RequestConfirm
;Input:		FrameID			;数据包的起始标识
;		ConnectADD		;连接地址
;		Sequence		;发送包的序列号
;		game_second_m2		;定时标志		
;
;		GameSendLength		;发送数据包的总长度
;		F_SendBuffer中的数据
;
;Output:	cy = 0	;成功发送数据,并收到对方确认	
;		cy = 1  ;失败退出, a 的内容表明失败的原因
;
;Function:	发送数据包,接收回应; 收到回应则退出, 未收到则循环直到
;		定时/按键退出	
;
;Status:	尚未测试 尚未加入  按键/时间 的检查
;=====================================================================


RequestConfirm:
		jsr	CheckOverTime		;定时/按键检查
		
		lda	ReturnCode
		cmp	#TRUE
		bne	EndRequestCfm

		lm	B1R0,GameSendLength
		lm2	B2R0,#F_SendBuffer
		jsr	SendPacket		;发送数据包		

		jsr	ReceiveAck		;接收对方的回应	

		lda	ReturnCode
		cmp	#TRUE
		bne	RequestConfirm

		inc	Sequence		;帧序列号递增!!!
EndRequestCfm:
		rts
;-------------------------------------------------------------------
;Name:		ReceiveAck
;Input:		None		
;Output:	ReturnCode == TRUE		;接收到正确的回应
;			   == FALSE		;未收到正确回应			   
;Function:	定时接收接收方做出的回应,该回应不含数据	
;		使用 F_RecvBuffer做为数据接收缓冲区
;Status:	
;===================================================================

ReceiveAck:
		lda	#TIME_OUT_50ms
		jsr	SetTimeOut		; time out = 50 ms

ReceiveAckLoop:
		lm2	B2R0,#F_RecvBuffer	;接收到的数据存放于 F_RecvBuffer
		jsr	ReceivePacket		

		lda	ReturnCode
		cmp	#TRUE
		bne	EndRecvAck		;未收到正确数据包,退出

		lm	ReturnCode,#FALSE

		ldy	#00h

		lda	(B2R0),y		;判断 FrameID
		cmp	FrameID	
		bne	CheckTimerMark		
		
		iny
		lda	(B2R0),y
		eor	ConnectADD		
		cmp	#80h			;判断 ConnectADD	
		bne	CheckTimerMark		

		lda	RecvSequence
		eor	Sequence
		and	#7fh
		bne	CheckTimerMark		

		lm	ReturnCode,#TRUE
		jmp	EndRecvAck

CheckTimerMark:

		lda	TimerMark		;对定时标志进行判断,定时未到,则继续接收
		bne	ReceiveAckLoop	
EndRecvAck:
		rts

;--------------------------------------------------------------------
;Name:		FormPacket
;
;Input:		FrameID		;数据包的标识
;		ConnectADD	;连接地址
;		DataLength	;数据的长度
;		StartAddress	;源数据的起始地址 
;		Sequence	;数据包的序列号	
;		数据		;由 StartAddress 指出的
;		DestAddress	;数据包形成后存放的目的地址
;		
;Output:	GameSendLength	;待发送的数据的长度	
;		DestAddress	;数据包的起始地址		
;
;Function:	形成待发送的数据包,发送方/接收方都可以调用该程序,
;		
;		DataLength == 0 的包用于链路控制 (发送/接收方均可使用)
;		DataLength != 0 的包用于数据传输 (只有发送方使用)	
;
;Statous:	尚未测试
;
;=====================================================================				
FormPacket:
		push	B1R0
		push	B1R1
		push2	B2R0		
		push2	B2R1

		lda	#00h
		sta	B1R0
		sta	B1R1

		ldy	B1R1

		lm2	B2R1,DestAddress	

		lda	FrameID
		sta	(B2R1),y		; load FrameID
		iny

		lda	ConnectADD
		sta	(B2R1),y		; load connect address
		iny

		lda	FrameType
		sta	(B2R1),y		; 帧的类型
		iny

		lda	DataLength
		clc
		adc	#01h
		sta	(B2R1),y		; load length	
		iny
		
		tya
		sta	B1R1

		lda	DataLength
		beq	LoadSequence

		lm2	B2R0,StartAddress

LoadDataLoop:
		ldy	B1R0
		lda	(B2R0),y
		ldy	B1R1
		sta	(B2R1),y

		inc 	B1R0
		inc	B1R1
						
		lda	B1R0
		cmp	DataLength
		bne 	LoadDataLoop
LoadSequence:
		ldy	B1R1
		lda	Sequence	
		sta	(B2R1),y
		inc 	B1R1		

		lm	B1R0,B1R1
		lm2	B2R0,B2R1
		jsr	CaculateCheckSum	;计算数据的校验和

		ldy	B1R1
		
		lda	CheckSum+0
		sta	(B2R1),y
		iny
		lda	CheckSum+1
		sta	(B2R1),y
		iny

		tya
		sta	GameSendLength		;要发送的数据长度
			
		pull2	B2R1
		pull2	B2R0
		pull	B1R1
		pull	B1R0

		rts

;------------------------------------------------------------
;*************  以下为通用子程序 ****************************
;============================================================

;---------------
;Name:		InitRegister
;Input:		None
;Output:	GameCommonFlag	首次标志
;		ConnectADD	连接地址
;		Sequence	数据包的序列号
;
;Function:	进入通讯时,必须调用一次 !!
;=========================================================

InitRegister:
		lda	GameCommonFlag
		ora	#80h
		sta	GameCommonFlag	; 置第一次进入标志

		lda	#TR_ms
		sta	RIReg
		lda	RTCVal

		and	#7fh

		sta	ConnectADD
		sta	Sequence			

		lm	FrameID,#1ch
		
		rts
;------------
;Name:		InitBrui
;Input:		
;Output:
;	
;Function:	初始化, 全双工,红外,9.6k bps
;
;Status:
;=======================================================

InitBrui:
		switch_BK	1

		lda	#05h
		sta	BSReg		; 9.6k bps

		lda	#13h		
		sta	IRCReg		

init_dataformat:
		switch_BK	0
		lda	#1
		sta	LCReg		;8 data bit , 1 stop bit , none parity

		jsr	ClearFifo

		rts

;---------------
;Name:		NormalMove
;Input:		B2R1	源数据指针	
;		B2R0	目的地址指针	
;		B1R0	数据长度
;Output:
;Function:	通用的数据移动
;Status:
;=============================================================	

NormalMove:
		tya
		pha
		
		ldy	#00h
NormalMoveLoop:		
		lda	(B2R1),y
		sta	(B2R0),y
		iny
		cpy	B1R0
		bne	NormalMoveLoop

		pla
		tay
		rts		
;---------------
;Name:		SendResponse
;Input:		FrameID
;		ConnectADD
;		Sequence
;Output:	
;Function:	接收方对发送方进行回应	
;Status:
;============================================================

SendResponse:
		lda	ConnectADD
		and	#7fh
		sta	ConnectADD		

		lm	DataLength,#00h			; 空包,不带数据
		lm2	DestAddress,#S_SendBuffer	; 数据包的存放地址
		jsr	FormPacket			; 打包		

		lm	B1R0,GameSendLength
		lm2	B2R0,DestAddress
		jsr	SendPacket			;发送数据包		

		rts
;--------------
;Name:		RecvNormalCheck
;Input:		接收到的校验正确的数据包
;		B2R0	数据的起始地址
;		GameRecvLength	数据流的长度
;
;		GameCommonFlag	通用标志		
;		FrameID
;		ConnectADD	
;		Sequence		
;		SelfFrameType	自身的数据类型
;		RecvFrameType	收到的数据类型	
;
;Output:	ReturnCode = FALSE	;出错
;			   = TRUE	;正确	
;			   = TRUE+1	;与上一帧序列号相同
;
;Function:	对 ConnectADD Sequence 进行检查
;		第一次进行连接时, FrameType 必须一致 !!!! 	
;Status:			
;=============================================================

RecvNormalCheck:
		tya
		pha

		lm	ReturnCode,#FALSE

		ldy	#00h
		
		lda	(B2R0),y		;检查 FrameID
		cmp	FrameID	
		bne	EndRNormalCheck

		iny
		lda	(B2R0),y		;检查是否为发送方	
		and	#80h
		beq	EndRNormalCheck		

		lda	GameCommonFlag		;判断是否为第一次进入
		and	#80h
		beq	CheckAddress

		lda	RecvFrameType		;第一次连接 FrameType 必须一致 !!!
		cmp	SelfFrameType
		bne	EndRNormalCheck		

		ldy	#01h
		lda	(B2R0),y
		and	#7fh
		sta	ConnectADD		;保存连接地址

		ldy	GameRecvLength
		dey

		lda	(B2R0),y
		and	#7fh
		sta	Sequence		;保存序列号

		lm	ReturnCode,#TRUE			
		jmp	EndRNormalCheck

CheckAddress:
		lda	(B2R0),y
		eor	ConnectADD
		and	#7fh
		bne	EndRNormalCheck				
CheckSequence:
		lda	RecvSequence
		and	#7fh
		bne	CheckSequenceGo	
		lda	#80h
CheckSequenceGo:
		sec
		sbc	Sequence
		cmp	#01h
		bne	IsLastFrame

		lm	ReturnCode,#TRUE	;序列号递增, 正确
		jmp	EndRNormalCheck
IsLastFrame:
		cmp	#00h
		bne	EndRNormalCheck

		lm	ReturnCode,#TRUE+1	;序列号与上一帧相同			
EndRNormalCheck:
		pla
		tay
		rts

;--------------
;Name:		ReceivePacket	
;Input:		B2R0		收到的数据存放的起始地址
;		TimerMark	定时标志				
;
;Output:	ReturnCode == TRUE 收到校验正确的数据包
;		GameRecvLength	收到的数据流的长度
;
;		RecvFrameType	收到的数据流的类型
;		RecvSequence	收到的数据流的序列号
;
;Function:	接收数据包
;		对数据包进行传输的较验
;		将正确包的类型/序列号 保存于 RecvFrameType RecvSequence
;	
;Status:	
;===============================================================================

ReceivePacket:
		push	B1R0
		push	B1R1

		lm	ReturnCode,#FALSE

		ldy	#00h
Recv_START:
		jsr	Receive
		jeq	EndRecvPacket			

		lda	RHReg
		cmp	#START_FLAG		;寻找数据流的起始标志 START_FLAG	
		bne	Recv_START

		ldy	#00h			
		lm	B1R0,#FALSE		;B1R0 作为转换标志
RecvPacketLoop:
		jsr	Receive
		beq	EndRecvPacket				
		
		lda	RHReg
		cmp	#END_FLAG		;对数据进行判断	
		beq	StreamOver

		cmp	#INSERT_FLAG
		bne	Judge_INSERT	

		lm	B1R0,#TRUE
		jmp	RecvPacketLoop

Judge_INSERT:
		sta	B1R1
				
		lda	B1R0
		cmp	#TRUE
		bne	SaveOneByte			

		lm	B1R0,#FALSE

		lda	B1R1
		eor	#CONVERT_FLAG		
		sta	B1R1
SaveOneByte:
		lda	B1R1
		sta	(B2R0),y
		iny
		jmp	RecvPacketLoop	
StreamOver:
		dey
		dey				;最后两个字节为 校验和

		tya
		sta	B1R0								
		jsr	CaculateCheckSum	;计算收到的数据的校验和

		lda	(B2R0),y
		cmp	CheckSum+0
		bne	EndRecvPacket

		iny
		lda	(B2R0),y
		cmp	CheckSum+1
		bne	EndRecvPacket

		dey
		dey
		lda	(B2R0),y
		sta	RecvSequence			

		ldy	#02h
		lda	(B2R0),y
		sta	RecvFrameType		;收到的数据包的类型

		lm	ReturnCode,#TRUE
		lm	GameRecvLength,B1R0	;收到的数据流的长度	
EndRecvPacket:
		pull	B1R1
		pull	B1R0
		rts		

;--------------
;Name:		SendPacket
;Input:		B2R0	要发送数据的起始地址
;		B1R0	数据的长度
;Output:	None
;============================================================
SendPacket:
		pha
		php
		tya
		pha

		lda	#START_FLAG
		jsr	TransmitOneByte		;起始标志

		ldy	#00h
SendPacketLoop:
		lda	(B2R0),y

		cmp	#START_FLAG
		bne	JudgeStep1
		jsr	InsertConvert
		jmp	SendOutData	
JudgeStep1:
		cmp	#INSERT_FLAG
		bne	JudgeStep2
		jsr	InsertConvert
		jmp	SendOutData	
JudgeStep2:
		cmp	#END_FLAG
		bne	SendOutData
		
		jsr	InsertConvert
SendOutData:
		jsr	TransmitOneByte	
	
		iny
		cpy	B1R0
		bne	SendPacketLoop			

		lda	#END_FLAG
		jsr	TransmitOneByte		;结束标志

		jsr	WaitTransmitOver	;等待传送结束

		pla
		tay
		plp
		pla
		rts

;--------------
;Name:		TransmitOneByte
;Input:		a
;Output:	none	
;=================================================

TransmitOneByte:
		pha	

		switch_BK	0
tr_wait:
		lda	LSReg		; MyWait 					
		and	#TxRDY
		beq	tr_wait

		pla

		sta	THReg
		rts		

;--------------
;Name:		InsertConvert
;Input:		a 
;Output:	a
;Function:	发送插入标志,在将数据处理	
;=================================================

InsertConvert:
		pha
		
		lda	#INSERT_FLAG
		jsr	TransmitOneByte
		
		pla
		eor	#CONVERT_FLAG

		rts

;---------------
;Name:		WaitTransmitOver
;Input:		None
;Output:	None
;Function:	检查 线路状态寄存器 ,看发送缓冲区的数据是否全部发出
;=====================================================================

WaitTransmitOver:

		lda	#TIME_OUT_100ms				
		jsr	SetTimeOut

WaitTransOver:
		lm	watch_dog_timer_flag,#00h		

		lda	TimerMark
		bne	WaitTransGo

		jsr	DriverEnable			
		jmp	EndWaitTrans	

WaitTransGo:
		switch_BK	0

		lda	LSReg			; MyWait
		and	#TxEMT
		beq	WaitTransOver

		lda	LSReg
		and	#TxRDY
		beq	WaitTransOver
EndWaitTrans:
		jsr	ClearFifo		

		rts


;---------------
;Input:		None
;Output:	None
;Function:	clear T&R FIFO	
;===================================================================
ClearFifo:
		switch_BK	1
		lda	#30h
		sta	FCReg		;clear T&R FIFO; switch bank 0
		rts		


;---------------
;Name:		Receive
;Input:		TimerMark
;Output:	P
;
;Function:	接收数据,收到则退出,未收到则时间到退出	
;--------------------------------------------------------------------

Receive:
		lm	watch_dog_timer_flag,#00h
ReceiveLoop:
		switch_BK	0

		lda	LSReg		; MyWait
		and	#RxRDY
		bne	EndRecv
		lda	TimerMark
		bne	ReceiveLoop
EndRecv:
		rts			

;--------------
;Name:		CaculateCheckSum		
;Input:		B2R0	数据的起始地址
;		B1R0	数据的长度
;Output:	CheckSum+0 数据的累加和
;		CheckSum+1 数据的异或值						
;============================================================

CaculateCheckSum:
		pha
		php
		tya
		pha
		
		lda	#00h
		sta	CheckSum+0
		sta	CheckSum+1
		
		ldy	#00h
CaculateLoop:
		lda	(B2R0),y
		eor	CheckSum+1
		sta	CheckSum+1
		clc		
		lda	(B2R0),y
		adc	CheckSum+0		
		sta	CheckSum+0

		iny
		cpy	B1R0
		bne	CaculateLoop		
		
		pla
		tay
		plp	
		pla
		rts			

;--------------
;Name:		SetTimerOut
;Input:		a = 0 	; 50 ms
;		a = 1	; 100 ms
;
;Output:	TimerMark
;Status:	
;=======================================================

SetTimeOut:
		pha
		disable_Sample
		pla

		tay
		lda	TimeOutTable,y	;设定 定时器的值				

		sta	TimerCNT
		sta	TimerMark

		clear_Sample
		enable_Samp64

		rts

TimeOutTable:
		db	10
		db	20

;---------------
;Name:		SetOverTime
;Input:		None
;Output:	None
;	
;=========================================================
SetOverTime:
		lm	game_second_m2,#00h
		rts	

;---------------
;Name:		CheckOverTime
;Input:		None
;Output:	None
;Function:	clear game_second_m2
;=================================================

CheckOverTime:
		jsr	CheckPushKey
		bne	exit_by_key
check_over1:
		lda	game_second_m2
		cmp	#OVER_TIME
		blt	not_over
check_over2:
		lm	ReturnCode,#TIME_OUT
		rts
not_over:
		lm	ReturnCode,#TRUE
		rts

exit_by_key:
		lm	ReturnCode,#ESC_KEY
		rts

;---------------
		
;Name:		CheckPushKey
;Input:		None
;Output:	A
;Function:	检查是否有"ESC"键按下		
;==============================================

CheckPushKey:
		lm	io_port1_dir,#0ffh	
		lda	#08h
		sta	io_port1
		lda	io_port0
		and	#80h
		rts

;---------------
;Name:		WaitPLL
;Input:		None
;Output:	None
;Function:	延时,等待UART 的 clock 振荡稳定
;=========================================================

WaitPLL:
		push	B1R0
			
		lm	RIReg,#TR_ms
		lda	RTCVal
	
		clc
		adc	#50
		sta	B1R0
	
WaitPllLoop:
		lm	RIReg,#TR_ms
		lda	RTCVal
		cmp	B1R0
		bne	WaitPllLoop				

		pull	B1R0
		rts

;-----------------------------------------------------------------------
	end

;---------------
;Name:		TheLastListen
;Input:		None
;Output:	None
;Function:	看空间介质有无红外线的数据传输,有则等待,无则定时退出
;====================================================================

TheLastListen:
		jsr	ReceiveOneByte
		beq	EndLastWait
		lda	RHReg

		jmp	TheLastListen
EndLastWait:
		rts

;---------------
;Name:		ReceiveOneByte
;Input:		None	
;Output:	A == 0	; no data received
;		A != 0  ; data received 	
;====================================================================

ReceiveOneByte:
		tya
		pha
		
		ldy	#00h

ReceiveByteLoop:
		lda	LSReg
		and	#RxRDY
		beq	IsTimeOut
		
		pla
		tay

		lda	#TRUE
EndReceiveByte:
		rts

IsTimeOut:
		nop
		nop
		nop
		nop
		
		iny
		cpy	#MAX_NOP_TIMES
		bne	ReceiveByteLoop		

		pla
		tay
		lda	#FALSE
		jmp	EndReceiveByte

;---------------
;Name:		Delay10ms
;Input:		none
;Output:	none
;Function:	等待约10 ms
;=======================================================

Delay10ms:
		push	B1R0
			
		lm	RIReg,#TR_ms
		lda	RTCVal
		
		clc
		adc	#02h
		sta	B1R0
Delay10Loop:
		lm	RIReg,#TR_ms
		lda	RTCVal
		cmp	B1R0
		bne	Delay10Loop

		pull	B1R0
		rts
;***************
					
