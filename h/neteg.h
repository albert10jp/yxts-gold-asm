
;**********************
; NC 系列的双人游戏通讯
;**********************

;------------------------
;接口程序的常量定义
;========================

KEY_EXIT	equ	1
OVER_EXIT	equ	2
CHK_SUM_ERR	equ	3

;------------------------
;程序内部用到的常量定义
;========================

FALSE		equ	00		
TRUE		equ	01
ESC_KEY		equ	02
TIME_OUT	equ	03	


MAX_TRY_NO	equ	10
OVER_TIME	equ	0f0h


TIME_OUT_50ms	equ	00
TIME_OUT_100ms	equ	01

START_FLAG	equ	0c1h
END_FLAG	equ	0c0h
INSERT_FLAG	equ	07dh
CONVERT_FLAG	equ	020h	

MAX_DATA_LENGTH	equ	64		
MAX_NOP_TIMES	equ	150
MAX_ERR_TIMES	equ	10	

CONNECT_FRAME	equ	10h
DATA_FRAME	equ	30h
DISC_FRAME	equ	20h	

F_SendBuffer	equ	DeviceLog			
;F_RecvBuffer	equ	NegotiationQOS			

;S_SendBuffer	equ	NegotiationQOS	
S_RecvBuffer	equ	DeviceLog

;--------
;变量定义
;========

__base		equ	a5

		define	2,B2R0
		define	2,B2R1

__base		equ	IrdaModeMark	

		define	1,B1R0
		define	1,B1R1
		define	1,ConnectADD
		define	1,DataLength
		define	1,Sequence
		define	2,CheckSum
		define	1,SelfFrameType
;08h
		define	1,RecvFrameType
		define	1,FrameType
		define	1,RecvSequence
		define	1,GameCommonFlag
		define	1,GameSendLength
		define	1,GameRecvLength
		define	2,StartAddress
;10h
		define	2,DataLeft
		define	1,FrameID
		define	1,DebugCount		
		define	1,Speed
	
		define	1,ErrorCount				
			
DataReceived	equ	DataLeft		


;--------------
;==============

clear_PSD	macro
		pha
		php

		lda	33h
                and	#0fch
                ora	#3
                sta	33h           ; switch bank 3

                lda	#40h
                sta	GPCReg        ; p6.4 as output
                lda	P06
		and	#0efh
                sta	P06		; P6.4 output 0

		plp
		pla
               	endm

;=====================================


