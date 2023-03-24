						
;; IBM 5110 PALM						
; **********************************************************************						
; *** Disassembled code of the IBM 5110 model 1 Executable ROS       ***						
; *** Disassembly and comments copyright by Christian Corti          ***						
; *** Version 24.03.2008                                             ***						
	cpu         IBM5110						
						
        include     "ebcdic_5110.inc"  ; or use ebcdic.inc						
        intsyntax	  +$hex,-x'hex'      ; support $-style hex (not IBM 0x style)		
        codepage    cp037              ; activate a string mapping of chars						
      ORG $0000						
			DW $000A		; R0L0	
			DW $0000		; R1L0	
						
; ----------------------------------------------------------------------						
						
			MOVE R8, $D0			
			CTRL $2, #$BF		; switch to meta-interpreter	
			JMP ($00AC)			
						
; ----------------------------------------------------------------------						
						
			; Clear all memory			
			; (Memory parity check seems to be disabled)			
			; This will also clear all registers from R4L0			
			; to R15L3!			
						
			CTRL $F, #$FF		; Reset all devices	
			MOVE R2, R0			
			LBI R2, #$08		; R2 <- $0008	
			MOVE R3, R2			
			LBI R3, #$00		; R3 <- $0000	
			MOVE (R2)+, R3			
			MHL R1, R2			
			OR R1, R2			
			SZ R1			
			BRA $0014		; Loop	
						
			; Size installed memory in increments of 8 kbytes			
						
			LBI R15, #$1F			
			MLH R15, R15			
			LBI R15, #$FF		; start with last address $1FFF	
						
			; If there is no memory at the location pointed			
			; to by R15, a read will return $FF instead of $00			
			MOVB R1, (R15)			
			SNS R1			
			BRA $0038		; no memory here	
						
			; Next memory location (increment by $2000)			
			MOVE R5, R15			
			MHL R1, R15			
			ADD R1, #$20			
			MLH R15, R1			
						
			LBI R1, #$FF			
			SBSH R5, R1		; done	
			BRA $0024		; Loop	
						
			CTRL $0, #$FB		; Toggle level 0	
			CTRL $F, #$FF		; Reset all devices	
						
			; Put $FFFF (halt code) in R7L0			
			; R7 remains unaltered during bring up diagnostic			
			DEC R7, R7		; R7 <- $FFFF	
						
			; Test RWS locations $0020-$05FF			
			LBI R4, #$20		; R4 <- $0020 (start address)	
			LBI R6, #$06		; R6 <- $0006 (high end address)	
			LBI R1, #$04			
			MLH R1, R1			
			LBI R1, #$C4			
			INC2 R2, R0			
			RET R1			; test memory
						
			; Put 0000, 1111, 2222, ... into locations $0080-00BF			
			; This is an aid to locate the registers in display			
			; register mode			
			MOVE R14, R3			
			LBI R14, #$80		; R14 <- $0080	
			LBI R13, #$C0		; R13 <- $00C0	
			MOVE R15, R3		; R15 <- $0000	
			MOVE (R14)+, R15			
			SNS R15			
			LBI R15, #$EF			
			ADD R15, #$11			
			MLH R15, R15			
			SE R14, R13			
			BRA $0054		; -> -$0E(R0)	
						
			MOVE $3E, R5		; last RWS address	
			LBI R5, #$02			
			MLH R5, R5			
			LBI R5, #$00			
			MOVE $3C, R5		; begin of display	
						
			; Clear display			
			LBI R15, #' '			
			MLH R15, R15			
			LBI R13, #$06			
			MOVE (R5)+, R15			
			SBSH R5, R13			
			BRA $0072		; -> -$06(R0)	
						
			; --- Test A ---			
			; Bus In bit test			
						
			MOVE R5, $3C			
			LBI R1, #'A'			
			MOVB (R5)+, R1			
			LBI R15, #$FF			
			GETB R15, $0			
			SS R15			
			HALT			
						
			; --- Test B ---			
			; Bus Out bit test			
						
			LBI R1, #'B'			
			MOVB (R5)+, R1			
			CTRL $F, #$AA			
			CTRL $F, #$D5			
						
			; --- Test C ---			
			; Op Code test			
						
			LBI R1, #'C'			
			MOVB (R5)+, R1			
			MOVE $3C, R5			
						
			LBI R10, #$02			
			BRA $009C		; $04(R0)	
						
			LBI R10, #$FF			
			MOVE R3, $A0			
			MOVE $3A, R10			
			MOVE $38, R3			
			LBI R4, #$02			
			MLH R4, R4			
			LBI R4, #$40			
			LBI R11, #$D6			
			MOVB (R4)+, R11			
			LBI R11, #'C'			
			MOVB (R4)+++, R11			
			MOVE $36, R4			
						
			LBI R1, #$00			
			MLH R1, R1		; R0=0000	
			DEC2 R3, R1		; R3=FFFE	
			ROR R3			; R3=FF7F
			ADD R3, #$83		; R3=0002	
			MOVB (R3)++, R3		; R1=0200,R3=0004	
			DEC R2, R1		; R2=01FF	
			MOVB R4, (R3)++++	; R4=0001,R3=0008		
			ROR R4			; R4=0080
			OR R4, R3		; R4=0088	
			MOVE R5, (R3)++		; R5=0088,R3=000C	
			SUB R5, #$80		; R5=0008	
			MOVE (R3)~, R5		; R6=0008,R3=000B	
			INC2 R5, R6		; R5=000A	
			MOVB R7, (R3)---	; R7=000A,R3=0008		
			MOVE R8, (R3)--		; R8=0088,R3=0004	
			MOVE (R3), R8		; R2=0088	
			XOR R2, R7		; R2=0082	
			MOVE R9, (R3)		; R9=0082	
			SET R7, #$07		; R7=000F	
			ADD R7, R3		; R7=0013	
			MOVB R10, (R7)		; R10=0082	
			SWAP R5			; R5=00A0
			SUB R10, R5		; R10=FFE2	
			MOVE (R3), R10		; R2=FFE2	
			ADDH R2, R10		; R2=01E1	
			ROR3 R2			; R2=013C
			MOVE R9, (R3)		; R9=013C	
			SHR R9			; R9=0196
			ADDH2 R9, R9		; R9=FF97	
			MOVB R11, (R7)		; R11=0097	
			MHL R8, R9		; R8=00FF	
			CLR R8, #$5A		; R8=00A5	
			AND R11, R8		; R11=0085	
			SHR R11			; R11=0042
			MOVE $18, R3		; R12=0004	
			SUB R12, #$03		; R12=0001	
			MOVE R13, $0E		; R13=0013	
			MOVE R14, R13		; R14=0013	
			ADD R14, R12		; R14=0014	
			ADD R14, R11		; R14=0056	
			MOVE R15, R0		; R15=0104	
			LBI R15, #$56		; R15=0156	
			SNE R14, R15			
			SE R14, R15			
			HALT			
			SLT R14, R15			
			SGE R14, R15			
			BRA $0110		; -> -$02(R0)	
			SGT R14, R15			
			SLE R14, R15			
			BRA $0116		; -> -$02(R0)	
			SZ R14			
			SNZ R14			
			HALT			
			SS R14			
			SNS R14			
			HALT			
			SNBS R14, R15			
			SBS R14, R15			
			HALT			
			SNBC R14, R5			
			SBC R14, R5			
			HALT			
			SBSH R14, R12			
			SNBSH R14, R12			
			HALT			
			MOVE R4, $36			
			MOVE R11, $38			
			ADD R11, #$01			
			MOVE $38, R11			
			MOVB (R4), R11			
			MOVE R10, $3A			
			SNS R10			
			BRA $00B0		; -> -$96(R0)	
						
			SUB R10, #$01			
			MOVE $3A, R10			
			SZ R10			
			BRA $00B0		; -> -$9E(R0)	
						
			LBI R3, #$00			
			LBI R11, #$40			
			MLH R11, R11			
			MOVE (R4)--, R11			
			MOVE (R4), R11			
						
			; --- Test D ---			
			; RWS and ROS Switching Test			
						
			LBI R11, #'D'			
			MOVE R5, $3C			
			MOVB (R5)+, R11			
			LBI R1, #$01			
			MLH R1, R1			
			LBI R1, #$6E			
			LBI R2, #$10			
			MLH R2, R2			
			LBI R2, #$7B			
			MOVE (R1), R2			
			CTRL $0, #$7B			
			HALT			
						
			; --- Test E ---			
			; Interrupt 1, 2, 3 Tests			
						
			LBI R11, #'E'			
			MOVB (R5)+, R11			
			LBI R15, #$05			
			MLH R15, R15			
			LBI R15, #$36			
			MOVE $20, R15			
			ADD R15, #$04			
			MOVE $40, R15			
			ADD R15, #$26			
			MOVE $60, R15			
			CTRL $0, #$5F			
						
			; --- Test F ---			
			; Device Address Test			
			; This test does a GETB for every device address,			
			; errors cause a machine checks (i.e. device address			
			; or parity error).			
						
			LBI R11, #'F'			
			MOVB (R5)+, R11			
			MOVE R14, R3			
			LBI R11, #'D'			
			MOVB (R4)+, R11			
			LBI R11, #'A'			
			MOVB (R4)+++, R11			
						
			LBI R10, #'0'			
			LBI R13, #$FA			
			BRA $019E		; $04(R0)	
						
			; next device			
			ADD R14, #$04		; jump increment	
			ADD R10, #$01		; next digit	
						
			SNE R10, R13			
			LBI R10, #'A'		; hex digits after '9'	
			MOVB (R4), R10			
						
			LBI R15, #$FF			
			ADD R0, R14		; jump to device to test	
			GETB R15, $0			
			BRA $019A			
			GETB R15, $1			
			BRA $019A			
			GETB R15, $2			
			BRA $019A			
			GETB R15, $3			
			BRA $019A			
			GETB R15, $4			
			BRA $019A			
			GETB R15, $5			
			BRA $019A			
			GETB R15, $6			
			BRA $019A			
			GETB R15, $7			
			BRA $019A			
			GETB R15, $8			
			BRA $019A			
			GETB R15, $9			
			BRA $019A			
			GETB R15, $A			
			BRA $019A			
			GETB R15, $B			
			BRA $019A			
			GETB R15, $C			
			BRA $019A			
			GETB R15, $D			
			BRA $019A			
			GETB R15, $E			
			BRA $019A			
			GETB R15, $F			
						
			; clear message on screen			
			LBI R11, #' '			
			MLH R11, R11			
			MOVE (R4)--, R11			
			MOVE (R4), R11			
						
			; --- Test G ---			
			; Keyboard Test			
						
			LBI R11, #'G'			
			MOVB (R5)+, R11			
						
			CTRL $4, #$40		; enable int.3 and typamatic	
			ADD R15, #$01			
			SS R15			
			BRA $01F4		; small delay	
			CTRL $4, #$42		; disable typamatic	
						
			; --- Test H ---			
			; Storage Test (05FF to end) and Stuck Key Test			
						
			LBI R11, #'H'			
			MOVB (R5)+, R11			
						
			MOVE R6, $3E			
			MHL R6, R6			
			ADD R6, #$01			
			MOVE R10, R3			
			LBI R4, #$06			
			MLH R4, R4			
			LBI R4, #$00		; R4=$0600, starting address	
			LBI R1, #$04			
			MLH R1, R1			
			LBI R1, #$C4			
			INC2 R2, R0			
			RET R1			; call memory test routine
						
			; --- Test J ---			
			; Executable ROS initialize			
						
			LBI R11, #'J'			
			MOVB (R5)+, R11			
			MOVE $3C, R5			
						
			CTRL $F, #$FF		; reset all devices	
						
			MOVE R1, $3E			
			MOVE $A8, R1			
			MOVE $AA, R1			
						
			MOVE R1, $100			
			MOVE $A0, R1			
			MOVE $B0, R1			
						
			LBI R1, #$06			
			MOVE $CE, R1			
						
			LBI R1, #$80			
			MOVE $A2, R1			
						
			LBI R1, #$62			
			MOVE $1FC, R1			
						
			LBI R1, #$06			
			MLH R1, R1			
			LBI R1, #$00			
			MOVE $AC, R1			
						
			LBI R1, #$06			
			MLH R1, R1			
			LBI R1, #$31			
			MOVE $A6, R1			
						
			INC2 R14, R0			
			BRA $026C		; $20(R0)	
						
						
			LBI R1, #$06			
			MLH R1, R1			
			LBI R1, #$80			
			RET R1			
						
						
			LBI R1, #$00			
			MLH R1, R1			
			LBI R1, #$98			
			RET R1			
						
						
			LBI R1, #$04			
			MLH R1, R1			
			LBI R1, #$B2			
			RET R1			
						
						
			LBI R1, #$02			
			MLH R1, R1			
			LBI R1, #$F8			
			RET R1			
						
						
			LBI R15, #$07			
			MLH R15, R15			
			LBI R15, #$00			
			MOVE $BE, R15			
						
			ADD R15, #$C0			
			MOVE $D8, R15			
						
			ADD R15, #$04			
			MOVE (R15)--, R14			
						
			SUB R15, #$10			
			MOVE R14, $A0			
			DEC R14, R14			
			MOVE (R15)+, R14			
			MOVE (R15), R14			
						
						
			; --- Test K ---			
			; Executable ROS check (1st half)			
						
			MOVE R5, $3C			
			LBI R11, #'K'			
			MOVB (R5)+, R11			
			MOVE $3C, R5			
						
			LBI R9, #$80		; get status byte 1	
			STAT R9, $2			
			NOP			
			LBI R10, #$80			
			MLH R10, R10			
			LBI R14, #$1F			
			MLH R14, R14			
			LBI R14, #$FE			
			SNBC R9, R10			
			BRA $02A8		; $06(R0)	
						
			MOVE R8, $1C			
			INC2 R2, R0			
			JMP ($00AC)			
						
			; R12 contains highbyte of Exec ROS size			
			MHL R12, R14			
			ADD R12, #$20			
			MLH R14, R12			
						
			; --- Test L ---			
			; Feature ROS check			
						
			MOVE R5, $3C			
			LBI R11, #'L'			
			LBI R1, #$9F			
			SNE R12, R1			
			MOVB (R5)+, R11			
			MOVE $3C, R5			
			SHR R10			
			SZ R10			
			BRA $029E		; -> -$22(R0)	
						
			; --- Test M ---			
			; Executable ROS check (2nd half)			
						
			MOVE R5, $3C			
			LBI R11, #'M'			
			MOVB (R5)+, R11			
			MOVE $3C, R5			
						
			LBI R9, #$40		; get status byte 2	
			STAT R9, $2			
			NOP			
			MHL R10, R10			
			SNBC R9, R10			
			BRA $02DE		; $0A(R0)	
						
			MOVE R8, $1C			
			MOVE $D0, R8			
			MOVE R1, $CE			
			INC2 R2, R0			
			DEC2 R0, R1			
			MHL R12, R14			
			ADD R12, #$20			
			MLH R14, R12			
						
			; --- Test N ---			
			; Test SORT utility on Feature ROS card			
						
			MOVE R5, $3C			
			LBI R11, #'N'			
			LBI R1, #$9F			
			SNE R12, R1			
			MOVB (R5)+, R11			
			MOVE $3C, R5			
			SHR R10			
			SZ R10			
			BRA $02D0		; -> -$26(R0)	
			BRA $0304		; $0C(R0)	
						
			LBI R10, #$FF			
			MOVE $3A, R10			
			LBI R4, #$02			
			MLH R4, R4			
			LBI R4, #$40			
			BRA $030E		; $0A(R0)	
						
			; --- Test P ---			
			; Non-Exec ROS content and CRC check			
						
			MOVE R4, $3C			
			LBI R11, #'P'			
			MOVB (R4)+, R11			
			MOVE $3C, R4			
						
			LBI R4, #$40			
			LBI R14, #$01			
			LBI R15, #$80		; get keyboard status	
			STAT R15, $4			
			LBI R1, #$40			
			SBS R15, R1			
			SET R14, #$04			
			MLH R14, R14			
			LBI R14, #$00			
			MOVE $A4, R14			
						
			; print "ROS"			
			LBI R11, #'R'			
			MOVB (R4)+, R11			
			LBI R11, #'O'			
			MOVB (R4)+, R11			
			LBI R11, #'S'			
			MOVB (R4)++, R11			
			MOVE $36, R4			
						
			; Build IOCB for CRC check at $0100			
			LBI R3, #$01			
			MLH R3, R3			
			LBI R3, #$00		; R3 <- 0100 (address of IOCB)	
			LBI R14, #$01			
			MLH R14, R14			
			LBI R14, #$02		; R14 <- 0102	
			MOVE $100, R14		; IOCB_DA=1/_Sub=2	
			LBI R14, #$40		; R14 <- 0140	
			MOVE $102, R14		; IOCB_Cmd=1/_Flags=40	
			MOVE R14, $AC			
			MOVE $104, R14		; IOCB_BA <- 0600	
			LBI R14, #$18			
			MLH R14, R14			
			LBI R14, #$00			
			MOVE $106, R14		; IOCB_BS <- 1800	
			MOVE R15, $A0			
			MOVE $108, R15		; IOCB_CI1	
			MOVE $10C, R15		; IOCB_Ret	
						
			; Begin with module 40			
			LBI R6, #$40		; R6 <- xx40	
			MOVE $38, R6			
						
			; First test ROS addressing			
			DEC R14, R15		; R14 <- FFFF	
			LBI R15, #$1C		; R15 <- 001C	
			CTRL $1, #$02		; select Common ROS	
			PUTB $1, (R15)			
			PUTB $1, (R15)		; set address to FFFF	
			STAT R13, $1			
			STAT R12, $1		; get address	
			SNS R13			
			SS R12			
			BRA $037C		; not FFFF --> error	
						
			GETB R1, $1			
			BRA $036D			                  ; ODD ADDRESS: original value $036D
			GETB R1, $1		; get word	
			STAT R13, $1			
			STAT R12, $1		; get autoincremented address	
			SNZ R13			
			SZ R12			
			BRA $037C		; not zero --> error	
			BRA $0386		; ROS addressing OK	
						
			; Error 01 - ROS addressing error			
			LBI R1, #'0'			
			MLH R1, R1			
			LBI R1, #'1'			
			MOVE $10C, R1			
			BRA $0398			
						
			; Write ROS module number in R6 to screen			
			MOVE $38, R6			
			LBI R1, #$05			
			MLH R1, R1			
			LBI R1, #$1E			
			INC2 R2, R0			
			RET R1			; Call 051E
						
			; Do CRC of ROS module			
			MOVE R8, $AE			
			INC2 R2, R0			
			JMP ($00AC)			
						
			MOVE R6, $10C		; IOCB_Ret	
			SNZ R6			
			BRA $03C2		; No error, OK	
						
			; ROS error			
			MOVE R4, $36			
			ADD R4, #$04			
			LBI R11, #'E'			
			MOVB (R4)+, R11			
			LBI R11, #'R'			
			MOVB (R4)+, R11			
			MOVB (R4)+++, R11			
			MOVE R8, $FA			
			INC2 R2, R0			
			JMP ($00AC)			
						
			MOVE R15, $38		; get ROS module number	
			LBI R1, #$40			
			SE R15, R1		; don't halt if module 40	
			HALT			
			; Call AUX IPL			
			LBI R1, #$05			
			MLH R1, R1			
			LBI R1, #$B0			
			RET R1			
						
			; Module CRC ok			
			STAT R14, $1			
			MLH R14, R14			
			STAT R14, $1			
			MOVE $3E, R14		; save current ROS address	
						
			DEC2 R14, R14			
			MOVE R13, $A0			
			LBI R13, #$1C			
			PUTB $1, (R13)+			
			PUTB $1, (R13)		; go back 2 words	
						
			MOVE R13, $38			
			MOVE R4, $36			
			GETB R6, $1			
			MLH R6, R6			
			NOP			
			GETB R6, $1			
			SNE R6, R13			
			BRA $0404		; $20(R0)	
						
			ADD R4, #$04			
			LBI R11, #'I'			
			MOVB (R4)+, R11			
			LBI R11, #'D'			
			MOVB (R4)+++, R11			
			LBI R1, #$05			
			MLH R1, R1			
			LBI R1, #$1E			
			INC2 R2, R0			
			RET R1			
						
			; Error 08			
			MOVE $36, R4			
			LBI R1, #'0'			
			MLH R1, R1			
			LBI R1, #'8'			
			MOVE $10C, R1			
			BRA $0398		; -> -$6C(R0)	
						
			; Current module 40 ?			
			LBI R1, #$40			
			SE R6, R1			
			BRA $044E		; No	
						
			; Yes, select Common ROS word address 0BF0			
			LBI R14, #$0B			
			MLH R14, R14			
			LBI R14, #$F0		; R14 <- 0BF0	
			MOVE R15, $A0			
			LBI R15, #$1C			
			CTRL $1, #$02		; select Common ROS	
			PUTB $1, (R15)+			
			PUTB $1, (R15)-			
			BRA $041B			     ; ODD ADDRESS: original value $041B is odd
			GETB R1, $1			
			MLH R1, R1			
			NOP			
			GETB R1, $1			
			MOVE $DC, R1			
						
			MOVE R14, $102			
			LBI R14, #$08		; IOCB_Flags=8	
			MOVE $102, R14			
			LBI R14, #$01			
			MLH R14, R14			
			LBI R14, #$00			
			MOVE $106, R14		; IOCB_BS <- 0100	
						
			MOVE R8, $AE			
			INC2 R2, R0			
			JMP ($00AC)			
						
			; After module 40 change IOCB for other modules			
			MOVE R14, $102			
			LBI R14, #$40		; IOCB_Flags=40	
			MOVE $102, R14			
			LBI R14, #$18			
			MLH R14, R14			
			LBI R14, #$00			
			MOVE $106, R14		; IOCB_BS <- 1800	
			MOVE R15, $100			
			MOVE R6, $38			
			MOVE R4, $36			
						
			MOVE R14, $3E		; restore current ROS address	
			MOVE $108, R14		; IOCB_CI1	
						
			ADD R6, #$01		; increment module number	
			LBI R1, #$40			
			SGE R6, R1			
			BRA $0486		; $2C(R0)	
						
			; Test whether we're done with the Common ROS			
			LBI R1, #$42		; last Common ROS module	
			SE R6, R1			
			BRA $047E		; no, do next part	
						
			; Assume BASIC mode			
			LBI R6, #$10		; module 10	
			LBI R15, #$08		; subdevice 8 (BASIC ROS)	
						
			; Test whether APL or BASIC mode			
			MOVE R14, $A4			
			LBI R1, #$04			
			SBSH R14, R1			
			BRA $0470			
						
			; No we're in APL mode			
			LBI R6, #$20		; module 20	
			LBI R15, #$04		; subdevice 4 (APL ROS)	
						
			; Setup new IOCB			
			MOVE $100, R15		; IOCB_DA/_Sub	
			MOVE R15, $A0			
			MOVE $108, R15		; IOCB_CI1 <- 0	
			LBI R14, #$18			
			MLH R14, R14			
			LBI R14, #$00			
			MOVE $106, R14		; IOCB_BS <- 1800	
						
			; Loop			
			LBI R1, #$03			
			MLH R1, R1			
			LBI R1, #$86			
			RET R1			; Jump back
			; ----			
						
			LBI R14, #$1C			
			LBI R15, #$34			
			SE R6, R14			
			SNE R6, R15			
			BRA $0492		; $02(R0)	
			BRA $047E		; -> -$14(R0)	
						
			MOVE R10, $3A			
			SS R10			
			BRA $04A0		; $08(R0)	
						
			LBI R1, #$02			
			MLH R1, R1			
			LBI R1, #$F8			
			RET R1			; Jump to $02F8
						
			; --- Test Q ---			
			; Bring up complete, pass			
			; control to BASIC or APL			
						
			MOVE R5, $3C		; R14L1	
			LBI R11, #'Q'			
			MOVB (R5)+, R11			
			MOVE R8, $1FA			
			MOVE R15, $1F8			
			LBI R1, #$10			
			SBS R15, R1			
			JMP ($00AC)			
			JMP ($00CE)			
						
						
						
			CTRL $0, #$3F			
			LBI R4, #$00			
			MLH R4, R4			
			LBI R4, #$20			
			MOVE R6, $AA			
			MHL R6, R6			
			ADD R6, #$01			
			LBI R10, #$01			
			MLH R10, R10			
						
						
			LBI R12, #$00			
			MLH R12, R12		; R12 <- $0000	
			AND R10, R12		; R10 <- $00	
			MOVE R14, R12		; R14 <- $0000	
			MOVE R15, R4			
			SNZ R12			
			MOVB (R15), R14			
			MOVB R13, (R15)+			
			SE R14, R13			
			HALT			
			SNZ R10			
			ADD R14, #$01			
			SZ R15			
			BRA $04CE		; -> -$12(R0)	
						
			SZ R10			
			BRA $04F2		; $0E(R0)	
						
			ADD R14, #$01			
			LBI R1, #$3F			
			LBI R13, #$80			
			SNBSH R15, R1			
			BRA $04F2		; $04(R0)	
						
			SNBSH R15, R13			
			ADD R14, #$01			
			MHL R1, R15			
			SE R6, R1			
			BRA $04CE		; -> -$2A(R0)	
						
			ADD R12, #$80			
			SNZ R10			
			MHL R14, R12			
			SZ R12			
			BRA $04CC		; -> -$36(R0)	
						
			LBI R1, #$01			
			SNBSH R10, R1			
			BRA $04CC		; -> -$3C(R0)	
						
			ADD R10, #$04			
			ADD R0, R10			
			HALT			
			HALT			
						
			LBI R14, #$A9			
			BRA $04CC		; -> -$48(R0)	
						
			LBI R14, #$D6			
			BRA $04CC		; -> -$4C(R0)	
						
			LBI R14, #$00			
			BRA $04CC		; -> -$50(R0)	
						
			RET R2			
						
						
			; Write hex representation of R6 to screen			
						
			LBI R12, #$0F			
			SWAP R6			
			AND R12, R6			
			LBI R1, #$09			
			SLE R12, R1			
			ADD R12, #$C7			
			ADD R12, #$F0			
			MOVB (R4)+, R12			
			LBI R1, #$01			
			SBC R4, R1			
			BRA $051E		; -> -$16(R0)	
						
			RET R2			
						
						
			LBI R4, #$F1			
			BRA $053C		; $02(R0)	
						
			LBI R4, #$F2			
			CTRL $0, #$3F		; Disable interrupts	
			MOVE R5, $3C			
			LBI R5, #$40			
			LBI R11, #'I'			
			MOVB (R5)+, R11			
			LBI R11, #'N'			
			MOVB (R5)+, R11			
			LBI R11, #'T'			
			MOVB (R5)+, R11			
			LBI R11, #'R'			
			MOVB (R5)++, R11			
			MOVB (R5)++, R4			
			LBI R11, #'E'			
			MOVB (R5)+, R11			
			LBI R11, #'R'			
			MOVB (R5)+, R11			
			MOVB (R5), R11			
			HALT			; Error halt
						
			CTRL $0, #$3F		; Disable interrupts	
			MOVE R4, $3C			
			LBI R4, #$40			
			LBI R11, #'K'			
			MOVB (R4)+, R11			
			LBI R11, #'E'			
			MOVB (R4)+, R11			
			LBI R11, #'Y'			
			MOVB (R4)++, R11			
			LBI R15, #$40			
			STAT R15, $4			
			MOVE R6, R15			
			INC2 R2, R0			
			BRA $051E		; Call $051E,R2	
						
			; Get scancode->EBCDIC table			
			ADD R4, #$02			
			LBI R14, #$0B			
			MLH R14, R14			
			LBI R14, #$F0			
			CTRL $1, #$02		; Select Common ROS	
			LBI R13, #$7C		; R14L3	
			PUTB $1, (R13)+			
			PUTB $1, (R13)-			
			BRA $058D			     ; ODD ADDRESS: original value $058D 
			GETB R14, $1			
			MLH R14, R14			
			NOP			
			GETB R14, $1			
						
			; Get character matching scancode			
			MOVE R12, $A0			
			OR R12, R15			
			SHR R12			
			ADD R14, R12			
			PUTB $1, (R13)+			
			PUTB $1, (R13)			
			BRA $05A3		      ; ODD ADDRESS: original value $05A3	
			GETB R6, $1			
			LBI R1, #$01			
			SBC R15, R1			
			GETB R6, $1			
			MOVB (R4), R6			
			HALT			; Error halt
						
			MOVE R15, $3C		; R14L1	
			LBI R15, #$80			
			LBI R11, #'A'			
			MOVB (R15)+, R11			
			LBI R11, #'U'			
			MOVB (R15)+, R11			
			LBI R11, #'X'			
			MOVB (R15)++, R11			
			LBI R11, #'I'			
			MOVB (R15)+, R11			
			LBI R11, #'P'			
			MOVB (R15)+, R11			
			LBI R11, #'L'			
			MOVB (R15)+, R11			
						
			LBI R1, #$20			
			MLH R1, R1			
			MOVE $B0, R1			
						
			MOVE R8, $F8			
			INC2 R8, R8			
			JMP ($00AC)			
						
			HALT			
			ORG   $05FE			
			HALT			
						
						
			LBI R1, #$01			
			SBS R8, R1			
			RET R8			
						
			DEC R8, R8			
			CTRL $0, #$3B			
			MOVE R1, $A4			
			CLR R1, #$80			
			MOVE $A4, R1			
			CTRL $0, #$5F			
			RET R8			
						
			HALT			
      ORG   $061E						
			HALT			
						
			LBI R1, #$00			
			MLH R1, R1			
			LBI R1, #$A5			
			PUTB $0, (R1)			
			RET R8			
						
			HALT			
			ORG   $067E			
			HALT			
						
						
						
						
						
						
			CTRL $4, #$43		; disable interrupt 3	
						
			MOVE R14, (R3)		; IOCB_DA/_Sub	
			INC2 R5, R3			
			MOVE R6, (R5)+		; IOCB_Cmd/_Flags	
			MOVE R4, (R5)+		; IOCB_BA	
			LBI R1, #$20			
			SBC R6, R1			
			MOVE R3, R4			
						
			MOVE R12, (R5)+		; IOCB_BS	
			; negate R12			
			MHL R15, R12			
			LBI R1, #$FF			
			XOR R12, R1			
			XOR R15, R1			
			MLH R12, R15			
			ADD R12, #$01			
						
			LBI R11, #$80			
			LBI R13, #'1'			
			MLH R13, R13			
			LBI R13, #'4'			
						
			; Test for valid subdevice address			
			CTRL $1, #$08		; select BASIC ROS (addr 8)	
			LBI R1, #$08			
			SNE R14, R1			
			BRA $06BE			
			CTRL $1, #$04		; select APL ROS (addr 4)	
			LBI R1, #$04			
			SNE R14, R1			
			BRA $06BE			
			CTRL $1, #$02		; select Common ROS (addr 2)	
			LBI R1, #$02			
			SE R14, R1			
			BRA $06FC		; error 14 (subdevice error)	
						
			PUTB $1, (R5)+		; IOCB_CI1	
			PUTB $1, (R5)-			
			LBI R13, #'0'			
			MLH R13, R13			
			LBI R13, #'2'			
						
			MHL R15, R6			
			LBI R1, #$01			
			SE R15, R1			
			BRA $0706		; not command 1	
						
			; Command 1			
			MOVE R9, $A0		; reset CRC to 0	
			LBI R5, #$08			
			SBS R6, R5			
			DEC R9, R9		; .. or to FFFF	
			LBI R13, #$40			
						
			GETB R10, $1			
			SBS R6, R13			
			MOVB (R4)+, R10		; copy ROS to RWS	
			ADD R12, #$01			
			INC2 R8, R0			
			SBS R6, R5			
			BRA $072C		; Call CRC routine	
			SNBSH R12, R11			
			BRA $06DA		; loop over ROS	
						
			; finished			
			LBI R1, #$20		; Loop CRC test?	
			SBC R6, R1		; no	
			BRA $0680		; yes	
						
			MHL R1, R9			
			OR R1, R9			
			SNZ R1			
			BRA $0702		; no error	
						
			; Error 07			
			LBI R13, #'7'			
						
			; Put error code into IOCB			
			MOVE R5, R3			
			ADD R5, #$0C		; IOCB_Ret	
			MOVE (R5), R13			
						
			; Return to caller			
			MOVE R8, R2			
			JMP ($00AC)			
			; ----			
						
			LBI R1, #$02			
			SE R15, R1			
			BRA $0706      ;   THINK THIS IS WRONG (?? perhaps meant $0702 ??)			
						
			; Command 2			
			CTRL $0, #$6F		; Display off	
						
			CTRL $1, #$88		; select BASIC ROS and ???	
			LBI R1, #$08			
			SNE R14, R1			
			BRA $0720		; $0A(R0)	
			CTRL $1, #$84		; select APL ROS and ???	
			LBI R1, #$04			
			SNE R14, R1			
			BRA $0720		; $02(R0)	
			CTRL $1, #$82		; select Common ROS and ???	
			PUTB $1, (R4)+			
			ADD R12, #$01			
			SNBSH R12, R11			
			BRA $0720		; -> -$08(R0)	
						
			CTRL $0, #$77		; Display on	
			BRA $0702		; return	
			; ----			
						
			; "Add" byte in R10 to CRC in R9			
			MHL R14, R9			
			XOR R14, R10			
			MOVE R1, R14			
			MOVE R15, R14			
			SWAP R15			
			XOR R14, R15			
			CLR R14, #$0F			
			XOR R14, R9			
			MOVE R9, R1			
			CLR R15, #$F0			
			XOR R9, R15			
			ROR3 R1			
			MOVE R15, R1			
			CLR R15, #$E0			
			XOR R14, R15			
			CLR R1, #$1F			
			XOR R9, R1			
			SWAP R15			
			MOVE R1, R15			
			CLR R15, #$1F			
			XOR R9, R15			
			CLR R1, #$FE			
			XOR R14, R1			
			MLH R9, R14			
						
			INC2 R0, R8			
						
						
						
			HALT			
						
						
			ORG $0800			
			; Put address of HOLD routine into location $FC			
			LBI R1, #$0C			
			MLH R1, R1			
			LBI R1, #$4A			
			MOVE $FC, R1		; $FC <- $0C4A	
						
			MOVE R4, $A0			
			INC2 R3, R0		; Point R3 to kbd. int.	
			BRA $0810			
						
						
						
			CTRL $4, #$02		; Reset int. 3	
						
			LBI R4, #$80			
			STAT R4, $4		; Get keyboard status	
			MLH R13, R4			
			LBI R1, #$08			
			SBC R4, R1		; Key pending ?	
			BRA $0848		; yes	
						
			MOVE R1, $D8		; Supervisor vector table	
			ADD R1, #$12		; User vector for keyboard int.	
			MOVE R8, (R1)			
			MHL R1, R8			
			SNZ R1			
			BRA $083A		; No user vector	
						
			; User vector set			
			CLR R8, #$01			
			MOVE R1, $A4			
			SET R1, #$10		; Level 3 RWS	
			MOVE $A4, R1			
			MOVE R1, $AC			
			ADD R1, #$20			
			INC2 R2, R0			
			RET R1			; Call user vector
			BRA $0800		; Loop	
						
			; No vector			
			MOVE R10, $A4			
			MHL R1, R10			
			SET R1, #$10		; Kbd int. without key pending	
			MLH R1, R10			
			MOVE $A4, R10			
						
			CTRL $F, #$04		; Reset address $B (?)	
			INC2 R0, R3		; Loop	
						
						
			; Key pending			
						
			CTRL $0, #$7D		; Turn off alarm	
			LBI R4, #$40			
			STAT R4, $4		; Scancode	
						
			MOVE R5, $B0		; Previous code to R5	
			MOVE R7, $A4			
			MOVE R6, $A2			
			MOVE R8, $A0			
			MHL R9, R5			
			LBI R1, #$C0			
			SNBC R9, R1			
			BRA $0866		; $08(R0)	
						
			; Already in Cmd-HOLD state			
			LBI R1, #$0A			
			MLH R1, R1			
			LBI R1, #$C8			
			RET R1			; Jump to $0AC8
						
						
			LBI R9, #$0F			
			AND R9, R4			
			LBI R1, #$06		; HOLD or ATTN ?	
			SE R9, R1			
			BRA $089C		; No	
						
			LBI R1, #$76		; HOLD key pressd ?	
			SLE R4, R1			
			BRA $087E		; No, so must be ATTN	
						
			; HOLD key			
			LBI R1, #$0A			
			MLH R1, R1			
			LBI R1, #$5C			
			RET R1			; Jump to $0A5C
			; returns to R3			
						
						
			; ATTN key			
			LBI R9, #$B6		; Set R9 to ATTN scancode	
			LBI R1, #$40			
			SBC R6, R1			
			SGT R4, R9			
			BRA $088A		; $02(R0)	
			BRA $08D6		; $4C(R0)	
						
			LBI R1, #$80			
			SBC R6, R1			
			SLT R4, R9			
			BRA $0894		; $02(R0)	
			BRA $08E8		; $54(R0)	
						
			SGE R4, R9			
			LBI R8, #$08			
			SLE R4, R9			
			LBI R8, #$04			
						
						
						
			LBI R1, #$01		; Translate scancode ?	
			SBC R7, R1			
			BRA $0926		; Yes	
						
			; Don't translate scancode			
			MOVE R5, R4			
			MLH R5, R8			
			MOVE $B0, R5		; Store scancode to $B0	
			LBI R1, #$B6		; ATTN ?	
			SE R9, R1			
			RET R3			; No, return
						
			MHL R1, R7			
			SET R1, #$80			
			MLH R7, R1			
			MOVE $A4, R7			
						
			LBI R1, #$04			
			SBSH R7, R1			
			RET R3			
						
			MOVE R10, $1FC			
			MOVB R1, (R10)			
			SET R1, #$80			
			MOVB (R10), R1			
						
			SGT R4, R9			
			RET R3			
						
			MOVE R11, $1FE			
			MHL R10, R11			
			LBI R1, #$0A			
			MLH R11, R1			
			SE R10, R1			
			MOVE $1FE, R11			
			RET R3			
						
			MOVE (R15), R14			
			CLR R6, #$40			
			MOVE $A2, R6			
			MOVE R1, $A0			
			MOVE $00, R1			
			CTRL $0, #$77			
			CTRL $4, #$02			
			MOVE $00, R15			
			RET R3			
						
			MOVE R10, $BE			
			SUB R10, #$10			
			LBI R11, #$01			
			MLH R11, R11			
			LBI R11, #$F0			
			MOVE R1, (R11)+			
			MOVE (R10)+, R1			
			SZ R10			
			BRA $08F2		; -> -$08(R0)	
						
			MOVE R11, $A0			
			MOVE R1, (R11)+			
			MOVE (R10)+, R1			
			LBI R1, #$20			
			SE R11, R1			
			BRA $08FC		; -> -$0A(R0)	
						
			LBI R1, #$40			
			SBC R6, R1			
			MOVE (R15), R14			
			CTRL $F, #$DF			
			LBI R6, #$80			
			MOVE $A2, R6			
			CTRL $2, #$7F			
			LBI R1, #$01			
			MLH R7, R1			
			CLR R7, #$0E			
			MOVE $A4, R7			
			MOVE R1, $F8			
			MOVE $10, R1			
			MOVE R1, $AC			
			MOVE $00, R1			
			RET R3			
						
			LBI R1, #$01			
			SBS R13, R1			
			BRA $093C		; $10(R0)	
						
			LBI R1, #$91			
			SNE R4, R1			
			BRA $0A2C		; $FA(R0)	
						
			LBI R1, #$95			
			SE R4, R1			
			BRA $093C		; $04(R0)	
						
			SET R6, #$80			
			CLR R13, #$01			
			LBI R1, #$2F			
			SNE R5, R1			
			RET R3			
						
			MOVE R9, $DC			
			LBI R1, #$01			
			SBSH R6, R1			
			BRA $0950		; $06(R0)	
						
			ADD R9, R4			
			MOVB R5, (R9)			
			BRA $0960		; $10(R0)	
						
			MOVE R10, R4			
			SHR R10			
			ADD R9, R10			
			INC2 R2, R0			
			BRA $0A16		; $BC(R0)	
						
			LBI R1, #$01			
			SBS R4, R1			
			MHL R5, R5			
			LBI R1, #$40			
			SLT R5, R1			
			SET R8, #$02			
			LBI R1, #$38			
			SNE R4, R1			
			CLR R8, #$02			
			LBI R1, #$D7			
			LBI R10, #$47			
			SE R4, R1			
			SNE R4, R10			
			CLR R8, #$02			
			LBI R1, #$DE			
			LBI R10, #$4E			
			SE R4, R1			
			SNE R4, R10			
			CLR R8, #$02			
			LBI R1, #$DF			
			LBI R10, #$4F			
			SE R4, R1			
			SNE R4, R10			
			CLR R8, #$02			
			LBI R1, #$01			
			SNBSH R6, R1			
			BRA $09E6		; $56(R0)	
						
			LBI R1, #$20			
			SBC R6, R1			
			BRA $09B2		; $1C(R0)	
						
			LBI R1, #$54			
			LBI R10, #$55			
			SE R5, R1			
			SNE R5, R10			
			LBI R5, #$00			
			LBI R1, #$02			
			SBC R8, R1			
			BRA $09B2		; $0C(R0)	
						
			LBI R1, #$44			
			SNE R5, R1			
			LBI R5, #$2C			
			LBI R1, #$47			
			SNE R5, R1			
			LBI R5, #$2D			
			LBI R1, #$04			
			SBSH R6, R1			
			BRA $09C4		; $0C(R0)	
						
			LBI R1, #$D7			
			SNE R4, R1			
			LBI R5, #$44			
			LBI R1, #$47			
			SNE R4, R1			
			LBI R5, #$47			
			LBI R1, #$02			
			LBI R10, #$01			
			SBS R8, R1			
			SBSH R13, R10			
			BRA $09E6		; $18(R0)	
						
			LBI R1, #$2C			
			LBI R10, #$2D			
			SE R5, R1			
			SNE R5, R10			
			BRA $09DA		; $02(R0)	
						
			BRA $09E6		; $0C(R0)	
						
			MOVE $B0, R5			
			MOVE R8, $E6			
			INC2 R2, R0			
			JMP ($00AC)			
						
			NOP			
			RET R3			
						
			SNZ R5			
			RET R3			
						
			MLH R5, R8			
			MOVE $B0, R5			
			MOVE $A2, R6			
			LBI R1, #$40			
			SNE R5, R1			
			BRA $0A0A		; $14(R0)	
						
			LBI R1, #$02			
			LBI R10, #$37			
			SBSH R5, R1			
			SGE R5, R10			
			RET R3			
						
			LBI R1, #$04			
			SBSH R6, R1			
			LBI R10, #$3A			
			SGE R5, R10			
			RET R3			
						
			CTRL $4, #$40			
			LBI R10, #$19			
			SUB R10, #$01			
			SZ R10			
			BRA $0A0E		; Delay	
						
			RET R3			
						
						
						
						
						
			CTRL $1, #$02		; Select Common ROS	
			MOVE R10, $A0			
			LBI R10, #$72		; Word address in R9L3	
			PUTB $1, (R10)+			
			PUTB $1, (R10)-			
			BRA $0A21			
						
			GETB R5, $1		; Get high byte	
			MLH R5, R5			
			NOP			
			GETB R5, $1		; Get low byte	
						
			RET R2			
						
						
			MOVE R9, $BE			
			SUB R9, #$10			
			LBI R8, #$01			
			MLH R8, R8			
			LBI R8, #$F0			
			MOVE R1, (R9)+			
			MOVE (R8)+, R1			
			SZ R9			
			BRA $0A36		; -> -$08(R0)	
						
			MOVE R8, $A0			
			MOVE R1, (R9)+			
			MOVE (R8)+, R1			
			LBI R1, #$20			
			SE R8, R1			
			BRA $0A40		; -> -$0A(R0)	
						
			LBI R1, #$80			
			SNBC R13, R1			
			CTRL $2, #$BF			
			LBI R1, #$80			
			SBC R12, R1			
			CTRL $0, #$7B			
			MOVE $A4, R12			
			CLR R13, #$01			
			RET R3			
						
						
						
						
			LBI R1, #$16		; Cmd-HOLD ?	
			SNE R4, R1			
			BRA $0A7A		; Yes	
						
			LBI R1, #$01		; CRT on ?	
			SBSH R7, R1			
			BRA $0A74		; No	
						
			LBI R1, #$02		; I/O active ?	
			SNBSH R7, R1			
			BRA $0A74		; Yes	
						
			LBI R1, #$02			
			SBS R6, R1			
			BRA $0A7A		; $06(R0)	
						
			SET R6, #$10			
			MOVE $A2, R6			
						
			RET R3			
						
						
						
						
			LBI R1, #$02		; I/O active ?	
			SNBSH R7, R1			
			CTRL $F, #$DF		; Yes, reset all except kbd.	
						
			MHL R1, R5			
			SET R1, #$80		; Flag for Cmd-HOLD	
			MLH R5, R1			
			MOVE $B0, R5			
						
			; Save registers from level 0			
			MOVE R8, $A0			
			MOVE R9, $BE			
			ADD R9, #$20			
			LBI R10, #$20			
			MOVE R1, (R8)+			
			MOVE (R9)+, R1			
			SE R8, R10			
			BRA $0A90			
						
			MOVE R1, $FC		; Put address of HOLD routine	
			MOVE $00, R1		; into R0L0	
						
			LBI R1, #$01			
			SBC R13, R1			
			BRA $0AC4		; $22(R0)	
						
			MOVE R12, R7			
			MHL R1, R12			
			CLR R1, #$02		; Clear I/O active	
			MLH R12, R1			
			CLR R12, #$0E		; Clear prt. status etc.	
						
			LBI R1, #$10		; Level 3 RWS ?	
			SBC R7, R1			
			BRA $0AB8		; Yes	
						
			LBI R1, #$80		; Level 0 RWS ?	
			SBC R7, R1			
			CTRL $0, #$7B		; Yes, switch to ROS	
						
			CLR R13, #$80			
			LBI R5, #$20			
			STAT R5, $2		; ???	
			CLR R5, #$7F			
			OR R13, R5			
			CTRL $2, #$7F		; ???	
						
			CTRL $4, #$46		; Enable interrupt	
			RET R3			
						
						
						
						
			LBI R1, #$80			
			SBC R9, R1			
			BRA $0AD8		; $0A(R0)	
						
			LBI R13, #$80			
			SET R9, #$80			
			MLH R5, R9			
			MOVE $B0, R5			
			MOVE R12, R7			
						
			LBI R1, #$02			
			SBC R6, R1			
			BRA $0AC4		; -> -$1A(R0)	
						
			LBI R1, #$89			
			LBI R9, #$16			
			SNBC R4, R1			
			SBS R4, R9			
			BRA $0AEA		; $02(R0)	
						
			BRA $0B16		; $2C(R0)	
						
			LBI R1, #$93			
			SNE R4, R1			
			BRA $0B4C		; $5C(R0)	
						
			LBI R1, #$B7			
			SNE R4, R1			
			BRA $0B92		; $9C(R0)	
						
			LBI R1, #$97			
			SNE R4, R1			
			BRA $0BA0		; $A4(R0)	
						
			LBI R9, #$01			
			SBSH R6, R9			
			SNBC R7, R9			
			BRA $0AC4		; -> -$40(R0)	
						
			LBI R1, #$4E			
			SNE R4, R1			
			BRA $0BC8		; $BE(R0)	
						
			LBI R1, #$20			
			LBI R10, #$10			
			SNBC R4, R1			
			SBS R4, R10			
			BRA $0AC4		; -> -$50(R0)	
						
			BRA $0BC8		; $B2(R0)	
						
			CTRL $4, #$4A			
			MOVE R8, $A0			
			MOVE R9, $BE			
			ADD R9, #$20			
			LBI R10, #$20			
			MOVE R1, (R9)+			
			MOVE (R8)+, R1			
			SE R8, R10			
			BRA $0B20		; -> -$08(R0)	
						
			INC2 R2, R0			
			BRA $0BB0		; $84(R0)	
						
			MOVE R1, $A0			
			MOVE $B0, R1			
			LBI R9, #$01			
			SBC R13, R9			
			RET R3			
						
			MOVE $A4, R12			
			LBI R9, #$90			
			SNBS R12, R9			
			RET R3			
						
			LBI R9, #$80			
			SBC R12, R9			
			CTRL $0, #$7B			
			LBI R1, #$80			
			SNBC R13, R1			
			CTRL $2, #$BF			
			RET R3			
						
						
						
						
						
			INC2 R2, R0			
			BRA $0BB0		; $60(R0)	
						
			LBI R9, #$01			
			SBC R13, R9			
			BRA $0B82		; $2C(R0)	
						
			LBI R1, #$01			
			SBC R7, R1			
			SET R13, #$01			
			LBI R6, #$80			
			SNBC R13, R9			
			MOVE $A2, R6			
						
			; Sichere Bereich ab $01F0			
			MOVE R9, $BE			
			SUB R9, #$10			
			LBI R8, #$01			
			MLH R8, R8			
			LBI R8, #$F0			
			MOVE R1, (R8)+			
			MOVE (R9)+, R1			
			SZ R9			
			BRA $0B6C		; -> -$08(R0)	
						
			; Lo(R9) ist beim ersten Eintreten gleich 0			
						
			MOVE R8, R9			
			ADD R8, #$20			
			MOVE R10, R8			
			MOVE R1, (R8)+			
			MOVE (R9)+, R1			
			SE R9, R10			
			BRA $0B7A		; -> -$08(R0)	
						
			LBI R1, #$10			
			MLH R1, R1			
			LBI R1, #$00			
			MOVE $F8, R1		; ($F8) <- $1000	
			MOVE $10, R1		; R8L0 <- $1000	
			MOVE R1, $AC			
			MOVE $00, R1		; R0L0 <- ($AC)	
			RET R3			
						
						
			MOVE R1, $C0			
			MOVE $10, R1			
			MOVE R1, $AC			
			MOVE $00, R1			
			MOVE R1, $A0			
			MOVE $04, R1			
			RET R3			
						
						
			MOVE R1, $00			
			MOVE $04, R1			
			MOVE R1, $FE			
			INC2 R1, R1			
			MOVE $10, R1			
			MOVE R1, $AC			
			MOVE $00, R1			
			RET R3			
						
			LBI R8, #$05			
			MLH R8, R8			
			LBI R8, #$C0			
			MOVE R10, R8			
			ADD R10, #$20			
			MOVE R9, $BE			
			ADD R9, #$40			
			MOVE R1, (R9)+			
			MOVE (R8)+, R1			
			SGE R8, R10			
			BRA $0BBE		; -> -$08(R0)	
						
			RET R2			
						
			LBI R8, #$FF			
			LBI R1, #$DE			
			SNE R4, R1			
			LBI R8, #$0C			
			LBI R1, #$4E			
			SNE R4, R1			
			LBI R8, #$0D			
			LBI R1, #$18			
			SNE R4, R1			
			LBI R8, #$00			
			LBI R1, #$58			
			SNE R4, R1			
			LBI R8, #$20			
			LBI R1, #$5A			
			SNE R4, R1			
			LBI R8, #$E0			
			LBI R1, #$D8			
			SNE R4, R1			
			LBI R8, #$D0			
			LBI R1, #$1A			
			SNE R4, R1			
			LBI R8, #$C0			
			LBI R1, #$5C			
			SNE R4, R1			
			LBI R8, #$B0			
			LBI R1, #$DA			
			SNE R4, R1			
			LBI R8, #$A0			
			LBI R1, #$1C			
			SNE R4, R1			
			LBI R8, #$90			
			LBI R1, #$5E			
			SNE R4, R1			
			LBI R8, #$80			
			LBI R1, #$DC			
			SNE R4, R1			
			LBI R8, #$70			
			LBI R1, #$1E			
			SNE R4, R1			
			LBI R8, #$60			
			LBI R1, #$9E			
			SNE R4, R1			
			LBI R8, #$50			
			LBI R1, #$9C			
			SNE R4, R1			
			LBI R8, #$40			
			LBI R1, #$9A			
			SNE R4, R1			
			LBI R8, #$30			
			LBI R1, #$98			
			SNE R4, R1			
			LBI R8, #$10			
			SNS R8			
			RET R3			
						
			LBI R5, #$00			
			OR R5, R8			
			MOVE $B0, R5			
			MOVE R8, $E6			
			INC2 R2, R0			
			JMP ($00AC)			
						
			RET R3			
						
			LBI R1, #$0B			
			MLH R1, R1			
			LBI R1, #$16			
			RET R1			
						
						
						
						
						
			CTRL $4, #$47		; Int 3 off	
						
			LBI R8, #$05			
			MLH R8, R8			
			LBI R8, #$C0		; R8 <- $05C0 (line 15, col 0)	
			LBI R10, #$E0			
			MOVE R9, $BE			
			ADD R9, #$40		; R9 <- $0740 (temp area)	
						
			; Save 5C0-5DF			
			MOVE R1, (R8)+			
			MOVE (R9)+, R1			
			SGE R8, R10			
			BRA $0C58		; -> -$08(R0)	
						
			; Write blanks to 5C0-5DF			
			LBI R8, #$C0			
			LBI R9, #$40			
			MLH R9, R9			
			MOVE (R8)+, R9			
			SGE R8, R10			
			BRA $0C66		; -> -$06(R0)	
						
			LBI R9, #$06			
			MLH R9, R9			
			LBI R9, #$C0		; R9 <- $06C0	
			LBI R8, #$C0			
						
			LBI R10, #$C4		; 4 characters (C4-C0)	
			MOVE R1, $A4			
			LBI R1, #$02			
			SNBSH R1, R1		; I/O active ?	
			LBI R10, #$D4		; Yes (20 characters)	
						
			; Copy HOLD message to 5C0			
			MOVE R1, (R9)+			
			MOVE (R8)+, R1			
			SGE R8, R10			
			BRA $0C7E		; -> -$08(R0)	
						
			; Modify I/O status			
			MOVE R8, $A2			
			CLR R8, #$12			
			MOVE $A2, R8			
						
			MOVE R8, $A4			
			MHL R1, R8			
			CLR R1, #$02		; Clear I/O active bit	
			SET R1, #$01		; Set CRT on bit	
			MLH R8, R1			
			CLR R8, #$0E		; Clear Printer active etc.	
			MOVE $A4, R8			
						
			CTRL $0, #$77		; Display on	
			CTRL $4, #$42		; Int 3 on	
						
			; Hier wird bei HOLD gehalten			
			HALT			
						
						
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
						
						
			BRA $0D38		; $36(R0)	
						
			LBI R10, #$02			
			MLH R10, R10			
			LBI R10, #$00			
			MOVE R15, $BE			
			ADD R15, #$94			
			MOVE R14, R10			
			MOVE (R15)+, R14	; $0200		
			LBI R13, #$03			
			MLH R13, R13			
			LBI R13, #$E0			
			MOVE (R15), R13		; $03E0	
			MOVE R15, R14			
			MOVE R14, $BE			
			ADD R14, #$20			
			LBI R13, #$40			
			MOVE R1, (R14)+			
			MOVE (R15)+, R1			
			SE R14, R13			
			BRA $0D20		; -> -$08(R0)	
						
			LBI R13, #$04			
			MOVE R14, $A0			
			LBI R14, #$20			
			MOVE R1, (R14)+			
			MOVE (R15)+, R1			
			SBSH R15, R13			
			BRA $0D2E		; -> -$08(R0)	
			BRA $0D3A		; Have offset	
						
			MOVE R10, $A0		; No offset	
						
			MOVE R1, $A2			
			SET R1, #$02			
			MOVE $A2, R1			
						
			MOVE R15, $BE			
			ADD R15, #$98			
			MOVE (R15)+, R10	; Display offset		
			MOVE R1, $A0			
			MOVE (R15)++, R1			
						
			; Save variables			
			MOVE (R15)+, R2			
			MOVE R1, $B6			
			MOVE (R15)+, R1			
			MOVE R13, $A4			
			MOVE (R15)+, R13			
						
			; Clear ATTN flag, CRT off,			
			; (don't translate scancode)			
			MHL R1, R13			
			CLR R1, #$81			
			MLH R13, R1			
			CLR R13, #$01			
			MOVE $A4, R13			
						
			MOVE R1, $B0			
			MOVE (R15), R1			
			MOVE R1, $A0			
			MOVE $B0, R1			
						
			; Clear $076C..0795 (two IOCBs)			
			LBI R15, #$07			
			MLH R15, R15			
			LBI R15, #$6C			
			MOVE R3, R15			
			MOVE R14, $A0			
			LBI R13, #$94			
			MOVE (R15)+, R14			
			SGE R15, R13			
			BRA $0D72			
						
			LBI R1, #$05			
			MLH R1, R1			
			LBI R1, #$00			
			MOVE (R3), R1		; IOCB_DA	
						
			; Sense printer			
			MOVE R8, $AE			
			INC2 R2, R0			
			JMP ($00AC)		; Call I/O Supervisor	
						
			; Wait until printer idle			
			MOVE R8, $C4			
			INC2 R2, R0			
			JMP ($00AC)			
			NOP			
						
			MOVE R15, R3			
			ADD R15, #$0C		; IOCB_Ret	
			MOVE R14, (R15)			
			SZ R14			
			BRA $0E3C		; Error	
						
			; IOCB_DA and IOCB_Sub			
			MOVE R15, R3			
			MOVE R14, R15			
			ADD R14, #$14		; first word after IOCB	
			MOVE R1, (R15)+			
			MOVE (R14)+, R1			
						
			; IOCB_Cmd and IOCB_Flags			
			LBI R1, #$02		; Write (print)	
			MLH R1, R1			
			LBI R1, #$00			
			MOVE (R15)+, R1			
			MOVE (R14)+, R1			
						
			; IOCB_BA			
			LBI R6, #$04			
			MLH R6, R6			
			LBI R6, #$00			
			MOVE (R15)+, R6		; Buffer 1 at $0400	
			MOVE R1, R6			
			ADD R1, #$6A			
			MOVE (R14)+, R1		; Buffer 2 at $046A	
						
			; IOCB_BS			
			LBI R1, #$00			
			MLH R1, R1			
			LBI R1, #$66		; 102 characters	
			MOVE (R15)+, R1			
			MOVE (R14)+, R1			
						
			; IOCB_CI1			
			MOVE R1, $A0			
			INC R1, R1		; 1 line feed	
			MOVE (R15), R1			
			MOVE (R14), R1			
						
			; IOCB_Stat1			
			ADD R15, #$08			
			ADD R14, #$08			
			MOVE R1, (R15)			
			MOVE (R14), R1			
						
			MOVE R15, $BE			
			ADD R15, #$94			
			MOVE R14, (R15)			
			CLR R14, #$1F			
			MOVE (R15)+, R14			
						
			; Limit end address to last RWS address			
			MOVE R13, (R15)			
			MHL R12, R13			
			MOVE R11, $AA			
			MHL R10, R11			
			SLE R12, R10			
			MOVE R13, R11			
			SLT R12, R10			
			SGT R13, R11			
			BRA $0DF2		; $02(R0)	
			MOVE R13, R11			
			MOVE (R15), R13			
						
			; Test if end address > start address			
			MHL R12, R13			
			MHL R11, R14			
			SGE R12, R11			
			BRA $0E02		; $06(R0)	
			SGT R12, R11			
			SLE R13, R14			
			BRA $0E10		; $0E(R0)	
						
			MOVE R15, R3			
			ADD R15, #$0C		; IOCB_Ret	
			LBI R1, #$F0			
			MLH R1, R1			
			LBI R1, #$F1			
			MOVE (R15), R1		; Error 01	
			BRA $0E42		; Exit	
						
			; Difference gives size			
			SUB R13, R14			
			MHL R1, R13			
			MHL R14, R14			
			SUB R1, R14			
			MLH R13, R1			
			CLR R13, #$1F		; Make multiple of 16 words	
			ADD R15, #$06			
			MOVE (R15), R13			
						
			BRA $0E72		; Print hex dump	
			; returns via jump to 0E22			
						
			; Sense printer			
			LBI R3, #$6C		; IOCB 1	
			MOVE R15, R3			
			ADD R15, #$02		; IOCB_Cmd+Flags	
			MOVE R1, $A0			
			MOVE (R15), R1		; Sense	
			MOVE R8, $AE			
			INC2 R2, R0			
			JMP ($00AC)			
						
			; Wait until printer idle			
			MOVE R8, $C4			
			INC2 R2, R0			
			JMP ($00AC)			
			BRA $0E3C		; Error	
			BRA $0E42		; OK	
						
			MOVE R8, $FA			
			INC2 R2, R0			
			JMP ($00AC)		; "ERROR 0xx..."	
						
			; Clear lines 0-11			
			LBI R15, #$02			
			MLH R15, R15			
			LBI R15, #$00			
			LBI R14, #$40			
			MLH R14, R14			
			LBI R13, #$05			
			MOVE (R15)+, R14			
			SBSH R15, R13			
			BRA $0E4E		; -> -$06(R0)	
						
			MOVE R1, $A2			
			CLR R1, #$06			
			MOVE $A2, R1			
						
			; Restore variables and exit to caller			
			MOVE R15, $BE			
			ADD R15, #$9E			
			MOVE R2, (R15)+		; Restore R2	
			MOVE R1, (R15)+			
			MOVE $B6, R1			
			MOVE R1, (R15)+			
			MOVE $A4, R1			
			MOVE R1, (R15)+			
			MOVE $B0, R1			
						
			CTRL $0, #$77		; Display on	
			MOVE R8, R2			
			JMP ($00AC)		; Exit	
						
						
						
						
			MOVE R15, $BE			
			ADD R15, #$94			
			MOVE R4, (R15)		; Start address	
			MOVE R14, R4			
			ADD R14, #$20		; 16 words	
			MOVE (R15)++, R14	; New start address		
						
			MOVE R12, (R15)+	; Display address offset		
						
			MOVE R14, (R15)			
			LBI R3, #$6C		; IOCB 1	
			SZ R14			
			LBI R3, #$80		; IOCB 2	
			LBI R1, #$01			
			XOR R14, R1		; Toggle between the two IOCBs	
			MOVE (R15), R14			
						
			; Create hex dump line			
			MOVE R14, R3			
			ADD R14, #$04		; IOCB_BA	
			MOVE R6, (R14)			
			INC2 R2, R0			
			BRA $0EC4		; Call $0EC4,R2	
						
			; Print line			
			MOVE R8, $AE			
			INC2 R2, R0			
			JMP ($00AC)			
						
			MOVE R15, R3			
			ADD R15, #$0C		; IOCB_Ret	
			MOVB R14, (R15)			
			SZ R14			
			BRA $0E3C		; Error	
						
			MOVE R14, $A4			
			LBI R14, #$80			
			SNBSH R14, R14			
			BRA $0E22		; ATTN was pressed	
						
			MOVE R15, $BE			
			ADD R15, #$9C			
			MOVE R14, (R15)		; Number of lines to dump	
			MHL R1, R14			
			OR R1, R14			
			SNZ R1			
			BRA $0E22		; Finished, return	
						
			SUB R14, #$20			
			MOVE (R15), R14			
			BRA $0E72		; Loop	
						
						
						
						
						
						
						
						
			LBI R14, #17		; 16 data words + address	
						
			; R10 <- R4 - R12			
			MOVE R10, R4			
			SUB R10, R12			
			MHL R1, R10			
			MHL R12, R12			
			SUB R1, R12			
			MLH R10, R1			
						
			; Convert address to hex			
			INC2 R5, R0			
			BRA $0EF4		; Call $0EF4,R5	
						
			; Four blanks between address and data			
			LBI R1, #$40			
			MLH R1, R1			
			MOVE (R6)+, R1			
			MOVE (R6)+, R1			
			SUB R14, #$01			
						
			; Convert next data word to hex			
			MOVE R10, (R4)+			
			INC2 R5, R0			
			BRA $0EF4		; Call $0EF4,R5	
						
			; Two blanks between data words			
			LBI R1, #$40			
			MLH R1, R1			
			MOVE (R6)+, R1			
			SUB R14, #$01			
						
			SZ R14			
			BRA $0EE0		; -> -$12(R0)	
						
			RET R2			
						
						
						
						
						
			LBI R13, #$02			
			MHL R11, R10			
			LBI R12, #$0F			
			SWAP R11			
			AND R12, R11			
			LBI R1, #$09			
			SLE R12, R1			
			ADD R12, #$C7			
			ADD R12, #'0'			
			MOVB (R6)+, R12			
			SNS R13			
			RET R5			
						
			SUB R13, #$01			
			SNZ R13			
			MOVE R11, R10			
			BRA $0EF8		; -> -$1C(R0)	
						
						
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
						
						
			MOVE R6, $A2			
			MOVE R1, $B0			
			MOVE R5, R1			
			LBI R1, #$00			
			MOVE $B0, R1		; Clear last keycode	
						
			LBI R1, #$0C			
			LBI R9, #$0D			
			SE R5, R1			
			SNE R5, R9			
			BRA $0F6E		; $1A(R0)	
						
			LBI R4, #$80			
			STAT R4, $4		; Get keyboard status	
			LBI R1, #$01			
			SBC R4, R1			
			BRA $0F98		; Katakana enable	
						
			MOVE $72, R5			
			MOVE R10, $A0			
			LBI R10, #$73			
			PUTB $F, (R10)		; Reset charset	
			INC2 R2, R2			
						
			CTRL $4, #$42		; Enable Int 3	
			MOVE R8, R2			
			JMP ($00AC)		; Return to caller	
						
			LBI R10, #$0C			
			LBI R9, #$02			
			SBC R5, R10			
			SBC R5, R9			
			BRA $0F68		; -> -$10(R0)	
						
			LBI R9, #$0B			
			MLH R9, R9			
			LBI R9, #$F0			
			LBI R1, #$20			
			SBS R6, R1			
			BRA $0F8A		; $06(R0)	
						
			LBI R9, #$17			
			MLH R9, R9			
			LBI R9, #$F1			
			SE R5, R10			
			ADD R9, #$01			
			INC2 R8, R0			
			BRA $0FD8		; $46(R0)	
						
			BRA $0F68		; -> -$2C(R0)	
						
			MOVE $DC, R9			
			BRA $0F66		; -> -$32(R0)	
						
			; Katakana enable			
						
			CLR R6, #$20			
			LBI R9, #$0B			
			MLH R9, R9			
			LBI R9, #$F0		; R9 <- $0BF0	
			SNZ R5			
			BRA $0FB2		; $0E(R0)	
						
			SET R6, #$20			
			LBI R9, #$17			
			MLH R9, R9			
			LBI R9, #$F1		; R9 <- $17F1	
						
			LBI R1, #$2D			
			SNE R5, R1			
			ADD R9, #$01		; R9 <- $17F2	
						
			INC2 R8, R0		; Get word from Common ROS	
			BRA $0FD8		; Call subroutine	
			BRA $0FBA		; Word is $FFFF	
			BRA $0FC2		; Word is not $FFFF	
						
			LBI R1, #$0C			
			SBS R5, R1			
			BRA $0F5E		; -> -$62(R0)	
			BRA $0F68		; -> -$5A(R0)	
						
			CLR R5, #$0F			
			LBI R1, #$20			
			SE R5, R1			
			SNZ R5			
			BRA $0FCE			
			BRA $0F68		; Exit	
						
			SZ R5			
			LBI R5, #$F0			
			MOVE $A2, R6			
			MOVE $DC, R9			
			BRA $0F5E		; -> -$7A(R0)	
						
						
			CTRL $1, #$02		; Select Common ROS	
			MOVE $72, R9		; ROS address	
			MOVE R10, $A0			
			LBI R10, #$72		; R10 <- $0072 (contents of R9)	
			PUTB $1, (R10)+			
			PUTB $1, (R10)-			
			BRA $0FE5			
						
			; Get ROS word			
			GETB R9, $1			
			MLH R9, R9			
			MOVE R10, R9			
			GETB R9, $1			
						
			AND R10, R9			
			SNS R10			
			RET R8			; Word was $FFFF
			INC2 R0, R8		; Return	
						
						
						
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
						
						
			BRA $1012		; $10(R0)	
						
			LBI R1, #$1E			
			MLH R1, R1			
			LBI R1, #$C8			
			RET R1			; Jump to $1EC8
						
						
						
			LBI R1, #$1E			
			MLH R1, R1			
			LBI R1, #$10			
			RET R1			; Jump to $1E10
						
						
			MOVE R10, $A2			
			LBI R1, #$20			
			SBS R10, R1			
			BRA $1028		; $0E(R0)	
						
			MOVE R1, $A0			
			MOVE $B0, R1		; Clear last keycode	
			CTRL $4, #$43		; Disable int. 3	
			MOVE R8, $E6			
			INC2 R2, R0			
			JMP ($00AC)			
			NOP			
						
			LBI R12, #$FF			
			LBI R1, #$1E			
			MLH R1, R1			
			LBI R1, #$48			
			INC2 R4, R0			
			RET R1			; Call $1E48,R4
						
			; Fill upper half of screen with R9			
			LBI R13, #$02			
			MLH R13, R13			
			LBI R13, #$00			
			MOVE R14, R13			
			LBI R12, #$04			
			MOVE (R14)+, R9			
			SBSH R14, R12			
			BRA $103E		; -> -$06(R0)	
						
			LBI R12, #$80			
			MOVE R15, $A2			
			MOVE R14, R13			
			LBI R14, #$10			
			LBI R11, #$00			
			SBS R15, R12			
			BRA $1056		; $04(R0)	
						
			LBI R14, #$0B			
			LBI R11, #$03			
			MOVE $1FC, R11			
			INC2 R2, R0			
			JMP ($01F8)			
						
			LBI R14, #$2B			
			SBS R15, R12			
			LBI R14, #$30			
			INC2 R2, R0			
			JMP ($01F8)			
						
			DEC2 R2, R0			
			MOVE $1F6, R2			
			LBI R1, #$8D			
			MOVE $1FC, R1			
			LBI R14, #$02			
			MLH R14, R14			
			LBI R14, #$80			
			MOVE R7, $A0			
			MOVE $B0, R7			
			BRA $10CA		; $50(R0)	
						
			LBI R1, #$55			
			SNE R5, R1			
			JMP ($01F8)			
						
			LBI R1, #$FA			
			SNE R5, R1			
			BRA $1012		; -> -$74(R0)	
						
			LBI R1, #$C1			
			SGE R5, R1			
			BRA $10CA		; $3E(R0)	
						
			SGT R5, R1			
			BRA $1096		; $06(R0)	
						
			LBI R1, #$C4			
			SE R5, R1			
			BRA $109C		; $06(R0)	
						
			MOVB (R14)++, R5			
			OR R7, R5			
			BRA $10CA		; $2E(R0)	
						
			LBI R11, #$C3			
			SLE R5, R11			
			BRA $10CA		; $28(R0)	
						
			MOVE R10, $A2			
			LBI R1, #$80			
			SBS R10, R1			
			JMP ($01F8)			
						
			OR R7, R5			
			SLT R5, R11			
			BRA $10B8		; $08(R0)	
						
			LBI R1, #$12			
			MLH R1, R1			
			LBI R1, #$1E			
			RET R1			
						
			LBI R1, #$1E			
			MLH R1, R1			
			LBI R1, #$8E			
			INC2 R4, R0			
			RET R1			
						
			LBI R1, #$13			
			MLH R1, R1			
			LBI R1, #$52			
			RET R1			
						
			MOVE R13, R14			
			SGT R14, R13			
			MOVE R14, R13			
			INC2 R4, R0			
			JMP ($01F4)			
						
			SNZ R7			
			BRA $107A		; -> -$5E(R0)	
						
			LBI R1, #$3D			
			SNE R5, R1			
			SUB R14, #$01			
			SLE R5, R9			
			MOVB (R14)+, R5			
			LBI R1, #$85			
			SGT R14, R1			
			BRA $10CC		; -> -$1C(R0)	
						
			MOVE R14, R13			
			INC2 R4, R0			
			JMP ($01F2)			
						
			DEC2 R13, R13			
			CLR R15, #$01			
			MOVE R6, R15			
			LBI R14, #$C2			
			LBI R1, #$08			
			MOVE $1FC, R1			
			INC2 R2, R0			
			JMP ($01F8)			
						
			DEC2 R2, R0			
			MOVE $1F6, R2			
			LBI R1, #$8D			
			MOVE $1FC, R1			
			MOVE R12, $AA			
			MHL R12, R12			
			LBI R14, #$03			
			MLH R14, R14			
			LBI R14, #$02			
			LBI R1, #$C1			
			SE R7, R1			
			BRA $111A		; $04(R0)	
						
			MOVE R13, R14			
			LBI R13, #$0A			
			MHL R11, R6			
			SGT R11, R12			
			BRA $1126		; $06(R0)	
						
			SS R11			
			LBI R11, #$00			
			AND R11, R12			
			MLH R6, R11			
			MOVE R5, R6			
			INC2 R4, R0			
			BRA $1156		; $28(R0)	
						
			ADD R14, #$04			
			MHL R11, R6			
			SGT R11, R12			
			BRA $113C		; $06(R0)	
						
			SS R11			
			LBI R11, #$00			
			AND R11, R12			
			MLH R6, R11			
			MOVE R5, (R6)+			
			INC2 R4, R0			
			BRA $1156		; $12(R0)	
						
			ADD R14, #$02			
			LBI R1, #$3A			
			SBS R14, R1			
			BRA $1130		; -> -$1C(R0)	
						
			LBI R1, #$BA			
			SLT R14, R1			
			BRA $115E		; $0C(R0)	
						
			LBI R14, #$82			
			BRA $111A		; -> -$3C(R0)	
						
			LBI R1, #$1D			
			MLH R1, R1			
			LBI R1, #$86			
			RET R1			
						
			SUB R6, #$20			
			MHL R11, R6			
			SLE R11, R12			
			AND R11, R12			
			MLH R6, R11			
			MOVE R14, R13			
			LBI R1, #$38			
			SLT R14, R1			
			BRA $1174		; $04(R0)	
						
			SLE R14, R13			
			BRA $1178		; $04(R0)	
						
			MOVE R14, R13			
			MOVE R15, $A0			
			INC2 R4, R0			
			JMP ($01F4)			
						
			LBI R1, #$42			
			SE R5, R1			
			BRA $1186		; $04(R0)	
						
			ADD R6, #$10			
			BRA $10FE		; -> -$88(R0)	
						
			LBI R1, #$45			
			SE R5, R1			
			BRA $1190		; $04(R0)	
						
			SUB R6, #$10			
			BRA $10FE		; -> -$92(R0)	
						
			LBI R11, #$C1			
			SNE R7, R11			
			BRA $11B4		; $1E(R0)	
						
			LBI R1, #$C4			
			SGT R5, R1			
			SGE R5, R11			
			BRA $116A		; -> -$34(R0)	
						
			MOVE R14, R13			
			LBI R11, #$04			
			MOVE (R14)+, R9			
			SBSH R14, R11			
			BRA $11A2		; -> -$06(R0)	
						
			MOVE R7, $A0			
			MOVE R14, R13			
			LBI R1, #$10			
			MLH R1, R1			
			LBI R1, #$7A			
			RET R1			
						
			LBI R1, #$2E			
			SNE R5, R1			
			BRA $11F2		; $38(R0)	
						
			ADD R15, #$01			
			LBI R1, #$3D			
			SE R5, R1			
			BRA $11D2		; $10(R0)	
						
			SUB R14, #$01			
			SUB R15, #$02			
			LBI R1, #$04			
			SGT R15, R1			
			BRA $116A		; -> -$62(R0)	
						
			SUB R14, #$02			
			LBI R15, #$03			
			BRA $116A		; -> -$68(R0)	
						
			LBI R10, #$3A			
			SE R5, R10			
			BRA $11DC		; $04(R0)	
						
			ADD R14, #$01			
			BRA $11DE		; $02(R0)	
						
			MOVB (R14)+, R5			
			LBI R1, #$04			
			SE R15, R1			
			BRA $116A		; -> -$7A(R0)	
						
			ADD R14, #$02			
			LBI R15, #$00			
			SNE R5, R10			
			BRA $116A		; -> -$82(R0)	
						
			LBI R1, #$38			
			SGE R14, R1			
			BRA $116A		; -> -$88(R0)	
						
			MOVE R14, R13			
			MHL R1, R6			
			SZ R1			
			BRA $1206		; $0C(R0)	
						
			LBI R1, #$06			
			SNE R6, R1			
			BRA $1216		; $16(R0)	
						
			LBI R1, #$20			
			SGE R6, R1			
			JMP ($01F8)			
						
			INC2 R4, R0			
			JMP ($01F2)			
						
			MOVE (R6)+, R15			
			ADD R14, #$02			
			LBI R1, #$38			
			SGE R14, R1			
			BRA $11F4		; -> -$20(R0)	
						
			RET R2			
						
			INC2 R4, R0			
			JMP ($01F2)			
						
			MOVE (R6), R15			
			RET R2			
						
			DEC2 R2, R0			
			MOVE $1F6, R2			
			LBI R14, #$02			
			MLH R14, R14			
			LBI R14, #$83			
			LBI R1, #$0B			
			MOVE $1FC, R1			
			INC2 R2, R0			
			JMP ($01F8)			
						
			LBI R1, #$8D			
			MOVE $1FC, R1			
			LBI R14, #$C0			
			LBI R1, #$C2			
			MOVB (R14)+, R1			
			MOVE R13, R14			
			BRA $1256		; $18(R0)	
						
			LBI R7, #$00			
			LBI R1, #$C5			
			LBI R12, #$D9			
			LBI R11, #$E7			
			SNE R5, R1			
			OR R7, R5			
			SNE R5, R12			
			OR R7, R5			
			SNE R5, R11			
			OR R7, R5			
			SZ R7			
			MOVB (R14)++, R5			
			LBI R1, #$CC			
			SGT R14, R1			
			SGE R14, R13			
			MOVE R14, R13			
			SGT R14, R13			
			LBI R7, #$00			
			INC2 R4, R0			
			JMP ($01F4)			
						
			SGT R14, R13			
			BRA $123E		; -> -$2C(R0)	
						
			LBI R10, #$C2			
			LBI R8, #$C7			
			LBI R1, #$3D			
			SE R5, R1			
			BRA $127E		; $0A(R0)	
						
			SUB R14, #$01			
			SE R14, R10			
			SNE R14, R8			
			SUB R14, #$01			
			BRA $1256		; -> -$28(R0)	
						
			LBI R1, #$3A			
			SE R5, R1			
			BRA $128E		; $0A(R0)	
						
			ADD R14, #$01			
			SE R14, R10			
			SNE R14, R8			
			ADD R14, #$01			
			BRA $1256		; -> -$38(R0)	
						
			LBI R1, #$2E			
			SNE R5, R1			
			BRA $12A2		; $0E(R0)	
						
			LBI R1, #$CC			
			SE R14, R1			
			MOVB (R14)+, R5			
			LBI R1, #$C7			
			SNE R14, R1			
			ADD R14, #$01			
			BRA $1256		; -> -$4C(R0)	
						
			INC2 R14, R13			
			INC2 R4, R0			
			JMP ($01F2)			
						
			LBI R1, #$01			
			SBC R15, R1			
			JMP ($01F8)			
						
			MOVE R6, R15			
			LBI R1, #$D9			
			SNE R7, R1			
			SET R6, #$01			
			ADD R14, #$01			
			MOVB R1, (R14)			
			SNE R1, R9			
			BRA $12D8		; $1A(R0)	
						
			INC2 R4, R0			
			JMP ($01F2)			
						
			LBI R1, #$01			
			SBC R15, R1			
			JMP ($01F8)			
						
			MOVE R12, (R15)			
			MOVE $7C, R12			
			MOVE $7E, R15			
			MOVE R12, $A0			
			MOVE (R15), R12			
			MOVE R1, $A2			
			SET R1, #$40			
			MOVE $A2, R1			
			MOVE R1, $A4			
			CLR R1, #$01			
			MOVE $A4, R1			
			LBI R14, #$05			
			MLH R14, R14			
			LBI R14, #$C0			
			INC2 R2, R0			
			JMP ($01F0)			
						
			MOVE R15, R3			
			ADD R15, #$0C			
			MOVE R12, $A0			
			MHL R1, R15			
			SZ R1			
			MOVE (R15), R12			
			MOVE R12, $BE			
			SUB R12, #$10			
			LBI R15, #$01			
			MLH R15, R15			
			LBI R15, #$F0			
			MOVE R1, (R12)+			
			MOVE (R15)+, R1			
			SZ R12			
			BRA $12FE		; -> -$08(R0)	
						
			MOVE R8, R6			
			MOVE R15, $AC			
			LBI R1, #$E7			
			SNE R7, R1			
			MOVE R15, $CE			
			INC2 R2, R0			
			RET R15			
						
			MOVE R10, $A2			
			LBI R1, #$40			
			SBS R10, R1			
			BRA $1326		; $0A(R0)	
						
			CLR R10, #$40			
			MOVE $A2, R10			
			MOVE R1, $7E			
			MOVE R5, $7C			
			MOVE (R1), R5			
			MOVE R12, $BE			
			SUB R12, #$10			
			LBI R15, #$01			
			MLH R15, R15			
			LBI R15, #$F0			
			MOVE R1, (R15)+			
			MOVE (R12)+, R1			
			SZ R12			
			BRA $1330		; -> -$08(R0)	
						
			LBI R2, #$10			
			MLH R2, R2			
			LBI R2, #$12			
			MOVE R15, R3			
			MHL R12, R15			
			SNZ R12			
			RET R2			
						
			ADD R15, #$0C			
			MOVE R12, (R15)			
			SNZ R12			
			RET R2			
						
			MOVE R8, $FA			
			JMP ($00AC)			
						
			LBI R14, #$C0			
			LBI R1, #$27			
			MOVE $1FC, R1			
			INC2 R2, R0			
			JMP ($01F8)			
						
			LBI R14, #$03			
			MLH R14, R14			
			LBI R14, #$00			
			LBI R1, #$31			
			MOVE $1FC, R1			
			INC2 R2, R0			
			JMP ($01F8)			
						
			LBI R14, #$40			
			LBI R1, #$3A			
			MOVE $1FC, R1			
			INC2 R2, R0			
			JMP ($01F8)			
						
			LBI R14, #$80			
			LBI R1, #$45			
			MOVE $1FC, R1			
			INC2 R2, R0			
			JMP ($01F8)			
						
			LBI R14, #$C0			
			LBI R1, #$4E			
			MOVE $1FC, R1			
			INC2 R2, R0			
			JMP ($01F8)			
						
			MOVE R14, R13			
			INC2 R4, R0			
			JMP ($01F4)			
						
			LBI R12, #$F0			
			LBI R11, #$F5			
			SLT R5, R12			
			SLE R5, R11			
			BRA $1388		; -> -$10(R0)	
						
			MOVB (R14), R5			
			LBI R1, #$F1			
			SGT R5, R1			
			BRA $13EC		; $4C(R0)	
						
			SNE R5, R11			
			BRA $1430		; $8C(R0)	
						
			MOVE R1, $D8			
			ADD R1, #$04			
			MOVE R6, (R1)			
			LBI R1, #$F2			
			SNE R5, R1			
			ADD R6, #$08			
			LBI R1, #$F3			
			SNE R5, R1			
			ADD R6, #$10			
			LBI R1, #$F4			
			SNE R5, R1			
			ADD R6, #$18			
			ADD R14, #$04			
			LBI R1, #$1F			
			MOVE $1FC, R1			
			INC2 R2, R0			
			JMP ($01F8)			
						
			INC2 R4, R0			
			JMP ($01F4)			
						
			LBI R1, #$2E			
			SE R5, R1			
			BRA $13C6		; -> -$0A(R0)	
						
			MOVE R1, $A4			
			CLR R1, #$01			
			MOVE $A4, R1			
			MOVE R8, $0C			
			INC2 R2, R0			
			JMP ($00AC)			
						
			MOVE R6, $104			
			INC R6, R6			
			MOVE R15, $10C			
			SNZ R15			
			BRA $13D0		; -> -$16(R0)	
						
			MOVE R2, $F8			
			MOVE R8, $FA			
			JMP ($00AC)			
						
			MOVE R15, $A0			
			LBI R15, #$14			
			LBI R10, #$17			
			MLH R10, R10			
			LBI R10, #$FC			
			CTRL $4, #$43			
			CTRL $1, #$02			
			PUTB $1, (R15)+			
			PUTB $1, (R15)			
			BRA $13FF		; -> -$01(R0)	
						
			GETB R11, $1			
			MLH R11, R11			
			NOP			
			GETB R11, $1			
			MOVE R3, $12E			
			LBI R12, #$01			
			MLH R12, R12			
			LBI R12, #$02			
			MOVE $100, R12			
			LBI R12, #$00			
			MLH R5, R12			
			MOVE $102, R12			
			LBI R1, #$2A			
			MLH R12, R1			
			MOVE $104, R12			
			LBI R1, #$18			
			MLH R12, R1			
			MOVE $106, R12			
			MOVE $108, R11			
			MOVE $10E, R5			
			MOVE R6, $AE			
			MOVE R14, R13			
			MOVE $136, R14			
			BRA $13BC		; -> -$74(R0)	
						
			MOVE R15, $13A			
			SUB R15, #$40			
			MOVE $136, R14			
			LBI R14, #$4E			
			MOVE R1, (R15)+			
			MOVE (R14)+, R1			
			LBI R1, #$58			
			SGT R14, R1			
			BRA $1438		; -> -$0A(R0)	
						
			LBI R14, #$C0			
			INC2 R2, R0			
			JMP ($01F0)			
						
			DEC2 R2, R0			
			MOVE $1F6, R2			
			LBI R1, #$8D			
			MOVE $1FC, R1			
			MOVE R3, $12E			
			MOVE R14, $136			
			LBI R1, #$C4			
			MOVB (R14)+, R1			
			LBI R1, #$E5			
			MOVB (R14)+, R1			
			LBI R1, #$7C			
			MOVB (R14)+++, R1			
			MOVE R13, R14			
			LBI R7, #$C3			
			SGT R14, R13			
			MOVE R14, R13			
			INC2 R4, R0			
			JMP ($01F4)			
						
			LBI R1, #$3D			
			SNE R5, R1			
			SUB R14, #$01			
			SLE R5, R9			
			MOVB (R14)+, R5			
			LBI R1, #$87			
			SGT R14, R1			
			BRA $1464		; -> -$18(R0)	
						
			INC2 R14, R14			
			LBI R11, #$02			
			INC R14, R13			
			MOVE R1, $1F2			
			INC2 R4, R0			
			DEC2 R0, R1			
			MOVE R14, R13			
			MOVB R5, (R14)			
			LBI R11, #$0F			
			AND R11, R5			
			LBI R1, #$30			
			SBS R5, R1			
			ADD R11, #$09			
			LBI R1, #$05			
			SGE R11, R1			
			JMP ($01F8)			
						
			MLH R15, R11			
			MOVE $100, R15			
			MOVE R15, $13A			
			MOVE $104, R15			
			LBI R15, #$02			
			MLH R15, R15			
			LBI R15, #$00			
			MOVE $106, R15			
			MOVE R7, $A0			
			MOVE $110, R15			
			INC2 R2, R0			
			JMP ($0132)			
						
			MOVE R14, $136			
			ADD R14, #$0A			
			MOVE R6, $110			
			LBI R1, #$C0			
			MHL R11, R6			
			SBC R11, R1			
			BRA $14C8		; $06(R0)	
						
			LBI R1, #$9F			
			MOVE $1FC, R1			
			JMP ($01F8)			
						
			LBI R1, #$80			
			SBSH R6, R1			
			BRA $14D6		; $08(R0)	
						
			LBI R1, #$D9			
			MOVB (R14)+, R1			
			LBI R1, #$C4			
			MOVB (R14)++++, R1			
			LBI R1, #$40			
			SBSH R6, R1			
			BRA $14E4		; $08(R0)	
						
			LBI R1, #$E6			
			MOVB (R14)+, R1			
			LBI R1, #$E3			
			MOVB (R14)++++, R1			
			LBI R1, #$20			
			SBSH R6, R1			
			BRA $14F2		; $08(R0)	
						
			LBI R1, #$D4			
			MOVB (R14)+, R1			
			LBI R1, #$D2			
			MOVB (R14)++++, R1			
			LBI R1, #$01			
			MLH R1, R1			
			LBI R1, #$60			
			MOVE $10A, R1			
			MOVE R1, $106			
			MOVE $14E, R1			
			DEC2 R2, R0			
			MOVE $1F6, R2			
			LBI R1, #$8D			
			MOVE $1FC, R1			
			MOVE R7, $A0			
			MOVE $102, R7			
			MOVE R14, $136			
			LBI R14, #$C0			
			MOVE $136, R14			
			MOVE R13, R14			
			LBI R1, #$C0			
			LBI R15, #$03			
			SLT R14, R1			
			SNBSH R14, R15			
			MOVE R14, R13			
			INC2 R4, R0			
			JMP ($01F4)			
						
			LBI R1, #$3D			
			SE R5, R1			
			BRA $152A		; $04(R0)	
						
			SUB R14, #$01			
			BRA $1512		; -> -$18(R0)	
						
			LBI R1, #$3A			
			SE R5, R1			
			BRA $1534		; $04(R0)	
						
			ADD R14, #$01			
			BRA $1512		; -> -$22(R0)	
						
			LBI R1, #$2E			
			SNE R5, R1			
			BRA $153E		; $04(R0)	
						
			MOVB (R14)+, R5			
			BRA $1512		; -> -$2C(R0)	
						
			MOVE R14, R13			
			MOVE R15, (R14)+			
			MHL R12, R15			
			LBI R7, #$40			
			LBI R1, #$D9			
			LBI R11, #$C4			
			SNE R12, R1			
			SE R15, R11			
			BRA $1552		; $02(R0)	
						
			BRA $1578		; $26(R0)	
						
			LBI R7, #$10			
			LBI R1, #$E6			
			LBI R11, #$E3			
			SNE R12, R1			
			SE R15, R11			
			BRA $156C		; $0E(R0)	
						
			MOVB R15, (R14)			
			LBI R1, #$D7			
			SE R15, R1			
			BRA $1578		; $12(R0)	
						
			SET R7, #$08			
			ADD R14, #$01			
			BRA $1578		; $0C(R0)	
						
			LBI R7, #$20			
			LBI R1, #$D4			
			LBI R11, #$D2			
			SNE R12, R1			
			SE R15, R11			
			JMP ($01F8)			
						
			MLH R7, R7			
			LBI R7, #$00			
			LBI R1, #$20			
			SBSH R7, R1			
			BRA $158A		; $08(R0)	
						
			LBI R1, #$1A			
			MLH R1, R1			
			LBI R1, #$CA			
			RET R1			
						
			LBI R1, #$10			
			SBSH R7, R1			
			BRA $1598		; $08(R0)	
						
			LBI R1, #$40			
			SBSH R6, R1			
			JMP ($01F8)			
						
			BRA $159E		; $06(R0)	
						
			LBI R1, #$80			
			SBSH R6, R1			
			JMP ($01F8)			
						
			MOVE R1, $A0			
			MOVE $150, R1			
			ADD R1, #$01			
			MOVE $108, R1			
			LBI R1, #$18			
			MOVE $152, R1			
			LBI R1, #$F2			
			MLH R1, R1			
			LBI R1, #$F4			
			MOVE $146, R1			
			MOVE R1, $AA			
			MOVE $142, R1			
			MHL R12, R7			
			MOVE R2, R0			
			MOVB R1, (R14)+			
			SE R1, R9			
			JMP ($01F8)			
						
			MOVB R5, (R14)+			
			SE R5, R9			
			BRA $15CE		; $08(R0)	
						
			LBI R1, #$16			
			MLH R1, R1			
			LBI R1, #$AE			
			RET R1			
						
			MOVB R1, (R14)+			
			SE R1, R9			
			JMP ($01F8)			
						
			LBI R1, #$C1			
			SE R5, R1			
			BRA $15E4		; $0A(R0)	
						
			INC2 R4, R0			
			JMP ($01F2)			
						
			SET R7, #$02			
			MOVE $140, R15			
			RET R2			
						
			LBI R1, #$E2			
			SE R5, R1			
			BRA $15F4		; $0A(R0)	
						
			INC2 R4, R0			
			JMP ($01F2)			
						
			SET R7, #$01			
			MOVE $142, R15			
			RET R2			
						
			LBI R1, #$E3			
			SE R5, R1			
			BRA $1626		; $2C(R0)	
						
			MOVE $1FE, R14			
			ADD R14, #$01			
			INC2 R4, R0			
			JMP ($0134)			
						
			MOVE $152, R15			
			MOVE R14, $1FE			
			MOVE R15, $A0			
			MOVB R11, (R14)+			
			MOVB R10, (R14)+			
			LBI R1, #$F0			
			SNE R11, R1			
			LBI R11, #$40			
			SNE R10, R9			
			BRA $161C		; $06(R0)	
						
			MLH R15, R11			
			OR R15, R10			
			BRA $1622		; $06(R0)	
						
			MLH R15, R10			
			OR R15, R11			
			SUB R14, #$01			
			MOVE $146, R15			
			RET R2			
						
			LBI R15, #$C6			
			SNE R5, R15			
			SET R12, #$80			
			LBI R1, #$D9			
			SE R5, R1			
			SNE R5, R15			
			BRA $1636		; $02(R0)	
						
			BRA $164A		; $14(R0)	
						
			MOVB R15, (R14)+			
			LBI R1, #$F0			
			SBS R15, R1			
			BRA $1656		; $18(R0)	
						
			INC2 R4, R0			
			JMP ($0134)			
						
			SET R7, #$04			
			MOVE $144, R15			
			DEC R14, R13			
			RET R2			
						
			LBI R1, #$D5			
			SE R5, R1			
			BRA $1674		; $24(R0)	
						
			MOVB R15, (R14)+			
			SNE R15, R9			
			JMP ($01F8)			
						
			DEC R13, R14			
			LBI R11, #$00			
			MOVB R15, (R14)+			
			ADD R11, #$01			
			SE R15, R9			
			BRA $165A		; -> -$08(R0)	
						
			LBI R1, #$12			
			SLT R11, R1			
			JMP ($01F8)			
						
			SET R12, #$84			
			SET R7, #$04			
			MOVE $14C, R13			
			MOVE R13, R14			
			DEC R14, R14			
			RET R2			
						
			MOVE R1, $110			
			LBI R1, #$01			
			SBSH R1, R1			
			JMP ($01F8)			
						
			LBI R1, #$C3			
			SE R5, R1			
			BRA $1690		; $0E(R0)	
						
			ADD R14, #$01			
			INC2 R4, R0			
			JMP ($0134)			
						
			MOVE $148, R15			
			SET R12, #$01			
			DEC R14, R13			
			RET R2			
						
			LBI R1, #$C8			
			SE R5, R1			
			JMP ($01F8)			
						
			ADD R14, #$01			
			INC2 R4, R0			
			JMP ($0134)			
						
			MHL R1, R15			
			LBI R11, #$01			
			SNZ R1			
			SLE R15, R11			
			JMP ($01F8)			
						
			ROR R15			
			MOVE $150, R15			
			DEC R14, R13			
			RET R2			
						
			MLH R7, R12			
			LBI R1, #$02			
			SBS R7, R1			
			JMP ($01F8)			
						
			LBI R1, #$20			
			SBSH R6, R1			
			BRA $16CE		; $12(R0)	
						
			LBI R1, #$04			
			SBC R7, R1			
			BRA $16CE		; $0C(R0)	
						
			LBI R1, #$44			
			SBSH R7, R1			
			JMP ($01F8)			
						
			LBI R1, #$01			
			SBSH R6, R1			
			JMP ($01F8)			
						
			LBI R1, #$10			
			SBSH R7, R1			
			BRA $16DE		; $0A(R0)	
						
			LBI R10, #$01			
			SBSH R7, R10			
			SBC R7, R10			
			BRA $16DE		; $02(R0)	
						
			JMP ($01F8)			
						
			MOVE R10, $A2			
			MHL R10, R10			
			LBI R1, #$30			
			SNBC R10, R1			
			BRA $1700		; $18(R0)	
						
			MOVE R1, $1F6			
			MOVE $12C, R1			
			INC2 R1, R0			
			BRA $16FE		; $0E(R0)	
						
			SNZ R15			
			BRA $1700		; $0C(R0)	
						
			MOVE R1, $A2			
			LBI R1, #$10			
			SBSH R1, R1			
			JMP ($012C)			
						
			BRA $1700		; $02(R0)	
						
			MOVE $1F6, R1			
			MOVE R11, $142			
			MOVE R10, $140			
			MHL R8, R11			
			MHL R1, R10			
			SLE R8, R1			
			BRA $1712		; $06(R0)	
						
			SLT R8, R1			
			SGT R11, R10			
			JMP ($01F8)			
						
			SUB R11, R10			
			MHL R1, R11			
			MHL R10, R10			
			SUB R1, R10			
			MLH R11, R1			
			MOVE $14A, R11			
			LBI R11, #$01			
			LBI R10, #$20			
			SBSH R7, R11			
			SBSH R6, R10			
			JMP ($0130)			
						
			MOVE R1, $13A			
			MOVE $104, R1			
			MOVE R1, $14E			
			MOVE $106, R1			
			LBI R7, #$04			
			LBI R1, #$01			
			SNBSH R6, R1			
			BRA $17EE		; $B6(R0)	
						
			MOVE R1, $144			
			MOVE $108, R1			
			INC2 R2, R0			
			JMP ($0132)			
						
			MOVE R1, $A0			
			MOVE $108, R1			
			MOVE R10, $104			
			MOVB R11, (R10)			
			LBI R1, #$10			
			SNBSH R7, R1			
			BRA $177A		; $2C(R0)	
						
			LBI R1, #$97			
			MOVE $1FC, R1			
			SNZ R11			
			JMP ($01F8)			
						
			MOVE R15, $A0			
			LBI R1, #$20			
			SNE R11, R1			
			MOVE R15, R11			
			LBI R1, #$80			
			SNE R11, R1			
			MOVE R15, R11			
			LBI R1, #$40			
			SNE R11, R1			
			MOVE R15, R11			
			SNZ R15			
			JMP ($0130)			
						
			LBI R1, #$1A			
			MLH R1, R1			
			LBI R1, #$4A			
			INC2 R4, R0			
			RET R1			
						
			JMP ($0130)			
						
			MOVE R15, $A0			
			MOVE R12, $152			
			LBI R1, #$14			
			SNE R12, R1			
			LBI R15, #$20			
			LBI R1, #$28			
			SNE R12, R1			
			LBI R15, #$40			
			LBI R1, #$50			
			SNE R12, R1			
			LBI R15, #$80			
			SNZ R15			
			BRA $17A0		; $0C(R0)	
						
			MOVE $152, R15			
			LBI R1, #$1A			
			MLH R1, R1			
			LBI R1, #$4A			
			INC2 R4, R0			
			RET R1			
						
			MOVE R11, $152			
			MOVE R12, $104			
			MOVB (R12), R11			
			MOVE R11, $A0			
			ADD R12, #$05			
			MOVB (R12)+, R11			
			MOVE (R12), R11			
			SUB R12, #$06			
			LBI R7, #$0B			
			LBI R1, #$04			
			SBSH R7, R1			
			BRA $17E8		; $30(R0)	
						
			ADD R12, #$80			
			MOVE $1FE, R12			
			LBI R1, #$1A			
			MLH R1, R1			
			LBI R1, #$30			
			INC2 R4, R0			
			RET R1			
						
			MOVE R12, $1FE			
			MOVE $104, R12			
			MOVE R12, $A0			
			LBI R12, #$11			
			MOVE $106, R12			
			LBI R12, #$10			
			MOVE $102, R12			
			LBI R7, #$FD			
			INC2 R2, R0			
			JMP ($0132)			
						
			MOVE R1, $13A			
			MOVE $104, R1			
			MOVE R1, $14E			
			MOVE $106, R1			
			MOVE R1, $A0			
			MOVE $102, R1			
			LBI R7, #$0B			
			INC2 R2, R0			
			JMP ($0132)			
						
			JMP ($0130)			
						
			LBI R1, #$04			
			SBSH R7, R1			
			BRA $1836		; $42(R0)	
						
			MOVE R1, $14C			
			MOVE $108, R1			
			LBI R1, #$04			
			MOVE $102, R1			
			INC2 R2, R0			
			JMP ($0132)			
						
			LBI R11, #$10			
			SZ R15			
			BRA $181E		; $18(R0)	
						
			SBSH R7, R11			
			BRA $1842		; $38(R0)	
						
			LBI R1, #$75			
			MOVE $1FC, R1			
			MOVE R10, $108			
			MOVE R8, $144			
			SE R10, R8			
			JMP ($01F8)			
						
			MHL R10, R10			
			MHL R8, R8			
			SNE R10, R8			
			BRA $1842		; $24(R0)	
						
			SBSH R7, R11			
			BRA $182E		; $0C(R0)	
						
			LBI R1, #$F1			
			LBI R10, #$F4			
			SNE R15, R1			
			SE R12, R10			
			BRA $182E		; $02(R0)	
						
			BRA $1836		; $08(R0)	
						
			LBI R1, #$1C			
			MLH R1, R1			
			LBI R1, #$52			
			RET R1			
						
			MOVE R1, $A0			
			MOVE $102, R1			
			MOVE R1, $144			
			MOVE $108, R1			
			INC2 R2, R0			
			JMP ($0132)			
						
			MOVE R1, $A0			
			MOVE $108, R1			
			MOVE $102, R1			
			LBI R1, #$10			
			SBSH R7, R1			
			BRA $1894		; $46(R0)	
						
			LBI R1, #$84			
			MOVE $1FC, R1			
			MOVE R15, $10E			
			ADD R15, #$2A			
			MOVB R12, (R15)			
			SE R12, R9			
			JMP ($01F8)			
						
			ADD R15, #$18			
			LBI R12, #$05			
			MOVB R1, (R15)+			
			SE R1, R9			
			JMP ($01F8)			
						
			SUB R12, #$01			
			SZ R12			
			BRA $1860		; -> -$0C(R0)	
						
			MOVE R12, $146			
			MHL R11, R12			
			LBI R1, #$F8			
			SNE R11, R1			
			LBI R15, #$80			
			LBI R1, #$F4			
			SNE R11, R1			
			LBI R15, #$40			
			LBI R1, #$F2			
			SNE R11, R1			
			LBI R15, #$20			
			LBI R1, #$F0			
			SE R12, R1			
			JMP ($0130)			
						
			LBI R1, #$1A			
			MLH R1, R1			
			LBI R1, #$4A			
			INC2 R4, R0			
			RET R1			
						
			JMP ($0130)			
						
			LBI R1, #$97			
			MOVE $1FC, R1			
			MOVE R15, $10E			
			ADD R15, #$4D			
			MOVB R12, (R15)+			
			MOVB R1, (R15)-			
			OR R12, R1			
			SNZ R12			
			JMP ($01F8)			
						
			SUB R15, #$4D			
			ADD R15, #$2B			
			MOVB R12, (R15)			
			LBI R1, #$C5			
			SE R12, R1			
			JMP ($0130)			
						
			MOVE R10, $A0			
			ADD R15, #$34			
			MOVE R11, $BE			
			SUB R11, #$20			
			MOVB R12, (R15)+			
			MOVB R8, (R11)+			
			SNS R8			
			BRA $18C8		; $06(R0)	
						
			SE R12, R8			
			LBI R10, #$FF			
			BRA $18BA		; -> -$0E(R0)	
						
			SZ R10			
			JMP ($0130)			
						
			MOVE R15, $10E			
			ADD R15, #$6C			
			MOVE R12, (R15)'			
			MHL R11, R12			
			LBI R1, #$F0			
			LBI R10, #$F2			
			SNE R12, R1			
			SGE R11, R10			
			JMP ($0130)			
						
			CLR R11, #$F0			
			LBI R1, #$01			
			SBC R11, R1			
			JMP ($0130)			
						
			LBI R1, #$08			
			LBI R12, #$06			
			SGT R11, R1			
			SNE R11, R12			
			JMP ($0130)			
						
			STAT R11, $0			
			MOVE R15, R11			
			LBI R1, #$1A			
			MLH R1, R1			
			LBI R1, #$4A			
			INC2 R4, R0			
			RET R1			
						
			LBI R7, #$02			
			LBI R12, #$10			
			SBSH R7, R12			
			LBI R7, #$01			
			LBI R1, #$02			
			SBSH R7, R1			
			BRA $1914		; $08(R0)	
						
			LBI R1, #$1A			
			MLH R1, R1			
			LBI R1, #$7C			
			RET R1			
						
			MOVE R1, $140			
			MOVE $104, R1			
			LBI R1, #$01			
			SBSH R7, R1			
			BRA $1930		; $12(R0)	
						
			MOVE $102, R1			
			MOVE R15, $144			
			MOVE R1, $150			
			OR R15, R1			
			MOVE R1, $148			
			MLH R15, R1			
			MOVE $108, R15			
			MOVE R2, $1F6			
			JMP ($0132)			
						
			LBI R11, #$40			
			LBI R1, #$80			
			SNBSH R7, R1			
			SBS R6, R11			
			BRA $194E		; $14(R0)	
						
			MOVE R1, $14A			
			MOVE $106, R1			
			INC2 R2, R0			
			JMP ($0132)			
						
			MOVE R1, $14E			
			MOVE $106, R1			
			LBI R1, #$01			
			SE R7, R1			
			BRA $19B6		; $6A(R0)	
						
			BRA $1996		; $48(R0)	
						
			DEC2 R2, R0			
			ADD R2, #$0E			
			MOVE R11, $106			
			LBI R1, #$01			
			SE R7, R1			
			BRA $196E		; $14(R0)	
						
			JMP ($0132)			
						
			DEC2 R2, R0			
			MOVE R15, $104			
			MOVE R12, $106			
			MOVE R11, R12			
			ADD R15, R12			
			MHL R12, R15			
			ADDH R12, R12			
			MLH R15, R12			
			MOVE $104, R15			
			MOVE R15, $14A			
			LBI R12, #$FF			
			SNBSH R15, R12			
			LBI R12, #$00			
			MOVE R10, $A0			
			SUB R15, R11			
			MHL R10, R15			
			MHL R11, R11			
			SUB R10, R11			
			MLH R15, R10			
			MOVE $14A, R15			
			OR R10, R15			
			SNZ R10			
			BRA $1996		; $0C(R0)	
						
			SS R12			
			JMP ($0132)			
						
			SBSH R10, R12			
			SNBSH R15, R12			
			BRA $1996		; $02(R0)	
						
			JMP ($0132)			
						
			LBI R1, #$01			
			SE R7, R1			
			BRA $19A2		; $06(R0)	
						
			LBI R1, #$65			
			MOVE $1FC, R1			
			JMP ($01F8)			
						
			LBI R7, #$03			
			INC2 R2, R0			
			JMP ($0132)			
						
			MOVE R14, $13A			
			MOVE $104, R14			
			INC2 R2, R0			
			JMP ($01F0)			
						
			LBI R1, #$80			
			SBS R6, R1			
			JMP ($01F6)			
						
			MOVE R1, $13A			
			MOVE $104, R1			
			MOVE R1, $108			
			MOVE $14A, R1			
			MOVE R1, $144			
			MOVE $108, R1			
			LBI R7, #$04			
			INC2 R2, R0			
			JMP ($0132)			
						
			LBI R1, #$02			
			SBSH R6, R1			
			BRA $19D8		; $0A(R0)	
						
			MOVE R12, $104			
			ADD R12, #$06			
			MOVE R1, $14A			
			MOVE (R12), R1			
			BRA $1A24		; $4C(R0)	
						
			MOVE R12, $10E			
			ADD R12, #$05			
			LBI R1, #$04			
			SBSH R7, R1			
			BRA $19E6		; $04(R0)	
						
			INC2 R4, R0			
			BRA $1A30		; $4A(R0)	
						
			MOVE R15, $10E			
			ADD R15, #$2A			
			LBI R12, #$D7			
			LBI R1, #$08			
			SBSH R7, R1			
			MOVE R12, R9			
			MOVB (R15)+, R12			
			LBI R1, #$C5			
			MOVB (R15), R1			
			ADD R15, #$22			
			MOVE R12, $14A			
			MHL R1, R12			
			MOVB (R15)+, R1			
			MOVB (R15)-, R12			
			ADD R15, #$12			
			MOVE R12, R15			
			MOVE R11, $BE			
			SUB R11, #$20			
			MOVB R10, (R11)+			
			SNS R10			
			BRA $1A14		; $04(R0)	
						
			MOVB (R12)+, R10			
			BRA $1A0A		; -> -$0A(R0)	
						
			ADD R15, #$0D			
			MOVE R11, $146			
			MOVE R10, R9			
			SNE R11, R9			
			MHL R10, R11			
			SNE R11, R9			
			MOVE R11, R10			
			MOVE (R15), R11			
			LBI R7, #$0B			
			INC2 R2, R0			
			JMP ($0132)			
						
			MOVE R14, $13A			
			MOVE R2, $1F6			
			JMP ($01F0)			
						
			MOVE R15, $14C			
			LBI R11, #$10			
			MOVB R10, (R15)+			
			MOVB (R12)+, R10			
			MOVB R10, (R15)+			
			SUB R11, #$01			
			SE R10, R9			
			BRA $1A36		; -> -$0A(R0)	
						
			SNS R11			
			RET R4			
						
			MOVB (R12)+, R9			
			SUB R11, #$01			
			BRA $1A40		; -> -$0A(R0)	
						
			STAT R15, $0			
			LBI R1, #$01			
			MLH R15, R1			
			MOVE $116, R15			
			LBI R15, #$01			
			LBI R1, #$10			
			SBSH R7, R1			
			LBI R15, #$02			
			MLH R15, R15			
			LBI R15, #$08			
			MOVE $118, R15			
			MOVE R1, $13A			
			SUB R1, #$40			
			MOVE $11A, R1			
			LBI R1, #$02			
			MLH R1, R1			
			LBI R1, #$00			
			MOVE $106, R1			
			MOVE $11C, R1			
			MOVE R1, $140			
			MOVE $11E, R1			
			MHL R1, R7			
			SET R1, #$02			
			MLH R7, R1			
			RET R4			
						
			MOVE R1, $11A			
			MOVE $104, R1			
			LBI R1, #$01			
			SE R7, R1			
			BRA $1A8A		; $04(R0)	
						
			INC2 R2, R0			
			JMP ($0132)			
						
			INC2 R2, R0			
			MOVE $13E, R2			
			ADD R3, #$16			
			MOVE $138, R7			
			MOVE R8, $AE			
			INC2 R2, R0			
			JMP ($00AC)			
						
			STAT R15, $1			
			MLH R15, R15			
			STAT R15, $1			
			MOVE $11E, R15			
			CTRL $1, #$00			
			LBI R1, #$1E			
			MLH R1, R1			
			LBI R1, #$48			
			INC2 R4, R0			
			RET R1			
						
			MOVE R7, $138			
			SUB R3, #$16			
			MOVE R2, $13E			
			LBI R7, #$01			
			LBI R1, #$10			
			SBSH R7, R1			
			JMP ($0132)			
						
			LBI R7, #$02			
			LBI R11, #$01			
			MLH R11, R11			
			LBI R11, #$00			
			LBI R1, #$19			
			MLH R1, R1			
			LBI R1, #$6E			
			RET R1			
						
			LBI R1, #$20			
			SNBSH R6, R1			
			BRA $1AD6		; $06(R0)	
						
			LBI R1, #$9F			
			MOVE $1FC, R1			
			JMP ($01F8)			
						
			MOVB R1, (R14)+			
			SE R1, R9			
			JMP ($01F8)			
						
			INC2 R4, R0			
			JMP ($0134)			
						
			MOVE $14A, R15			
			SET R7, #$01			
			MOVE R14, R13			
			INC2 R4, R0			
			JMP ($0134)			
						
			MHL R1, R15			
			OR R1, R15			
			SNZ R1			
			JMP ($01F8)			
						
			MOVE $142, R15			
			MOVE $112, R15			
			MOVE R14, R13			
			INC2 R4, R0			
			JMP ($0134)			
						
			MHL R1, R15			
			OR R1, R15			
			SZ R1			
			SNZ R7			
			JMP ($01F8)			
						
			MOVE $144, R15			
			MOVE $108, R15			
			INC2 R14, R13			
			LBI R1, #$03			
			MLH R1, R1			
			LBI R1, #$00			
			MOVE $104, R1			
			LBI R7, #$04			
			INC2 R2, R0			
			JMP ($0132)			
						
			LBI R1, #$01			
			SBSH R6, R1			
			BRA $1B5E		; $3E(R0)	
						
			SNZ R15			
			BRA $1B30		; $0C(R0)	
						
			LBI R1, #$F1			
			LBI R11, #$F4			
			SNE R15, R1			
			SE R12, R11			
			BRA $1BBA		; $8C(R0)	
						
			BRA $1B3E		; $0E(R0)	
						
			MOVE R15, $10E			
			ADD R15, #$4D			
			MOVB R12, (R15)+			
			MOVB R1, (R15)			
			OR R12, R1			
			SZ R12			
			BRA $1B9C		; $5E(R0)	
						
			MOVE R15, $108			
			ADD R15, #$01			
			MOVE $108, R15			
			MOVE R15, $112			
			SUB R15, #$01			
			MOVE $112, R15			
			MHL R1, R15			
			OR R1, R15			
			SZ R1			
			BRA $1B16		; -> -$3C(R0)	
						
			MOVE R12, $144			
			MOVE $108, R12			
			INC2 R2, R0			
			JMP ($0132)			
						
			LBI R7, #$05			
			BRA $1B8E		; $30(R0)	
						
			SZ R15			
			BRA $1B6E		; $0C(R0)	
						
			LBI R7, #$05			
			MOVE R15, $104			
			MOVB R12, (R15)+			
			SS R12			
			BRA $1B9C		; $30(R0)	
						
			BRA $1B8E		; $20(R0)	
						
			LBI R1, #$F1			
			LBI R11, #$F1			
			SNE R15, R1			
			SE R12, R11			
			BRA $1B7A		; $02(R0)	
						
			BRA $1BBA		; $40(R0)	
						
			LBI R1, #$F4			
			LBI R11, #$F0			
			SNE R15, R1			
			SE R12, R11			
			BRA $1BBA		; $36(R0)	
						
			MOVE R15, $108			
			LBI R1, #$01			
			SE R15, R1			
			BRA $1BBA		; $2E(R0)	
						
			LBI R7, #$06			
			MOVE R1, $14A			
			MOVE $108, R1			
			MOVE R1, $142			
			MOVE $10E, R1			
			INC2 R2, R0			
			JMP ($0132)			
						
			BRA $1BBA		; $1E(R0)	
						
			MOVE R12, $1F6			
			LBI R1, #$5A			
			MOVE $1FC, R1			
			INC2 R1, R0			
			ADD R1, #$04			
			MOVE $1F6, R1			
			JMP ($01F8)			
						
			LBI R1, #$2E			
			SE R5, R1			
			BRA $1B9C		; -> -$14(R0)	
						
			MOVE $1F6, R12			
			LBI R1, #$01			
			SBSH R6, R1			
			BRA $1B8E		; -> -$2A(R0)	
						
			BRA $1B52		; -> -$68(R0)	
						
			MOVE R2, $1F6			
			MOVE R14, $104			
			SZ R15			
			INC2 R2, R0			
			JMP ($01F0)			
						
			MOVE R2, $1F6			
			MOVE R8, $FA			
			JMP ($00AC)			
						
			MOVE $13C, R2			
			LBI R14, #$05			
			MLH R14, R14			
			LBI R14, #$C0			
			INC2 R2, R0			
			JMP ($01F0)			
						
			MOVE R11, $102			
			MLH R11, R7			
			MOVE $102, R11			
			MOVE $138, R7			
			MOVE R1, $A2			
			LBI R1, #$40			
			SBSH R1, R1			
			BRA $1BF2		; $0C(R0)	
						
			MOVE R14, $136			
			INC2 R4, R0			
			JMP ($01F4)			
						
			LBI R1, #$2E			
			SE R5, R1			
			BRA $1BE8		; -> -$0A(R0)	
						
			MOVE R1, $A4			
			CLR R1, #$01			
			MOVE $A4, R1			
			MOVE R8, $AE			
			INC2 R2, R0			
			JMP ($00AC)			
						
			MOVE R8, $C4			
			INC2 R2, R0			
			JMP ($00AC)			
						
			NOP			
			LBI R1, #$1E			
			MLH R1, R1			
			LBI R1, #$48			
			INC2 R4, R0			
			RET R1			
						
			MOVE R7, $138			
			MOVE R6, $110			
			MOVE R14, $136			
			MOVE R13, $136			
			MOVE R15, $A4			
			LBI R1, #$80			
			SNBSH R15, R1			
			BRA $1C64		; $44(R0)	
						
			MOVE R15, $10C			
			MHL R12, R15			
			LBI R1, #$20			
			SNBSH R7, R1			
			JMP ($013C)			
						
			MOVE R11, $102			
			LBI R1, #$04			
			SBS R11, R1			
			SNZ R15			
			JMP ($013C)			
						
			LBI R1, #$01			
			SE R7, R1			
			BRA $1C52		; $18(R0)	
						
			LBI R1, #$F0			
			LBI R11, #$F1			
			SNE R15, R1			
			SE R12, R11			
			BRA $1C46		; $02(R0)	
						
			LBI R15, #$00			
			LBI R1, #$F9			
			LBI R11, #$F0			
			SNE R15, R1			
			SE R12, R11			
			BRA $1C52		; $02(R0)	
						
			LBI R15, #$00			
			MOVE R2, $1F6			
			MOVE R14, $136			
			ADD R14, #$40			
			SZ R15			
			INC2 R2, R0			
			JMP ($01F0)			
						
			MOVE R2, $1F6			
			MOVE R8, $FA			
			JMP ($00AC)			
						
			LBI R1, #$01			
			MLH R15, R1			
			MOVE $A4, R15			
			MOVE R15, $A2			
			MHL R15, R15			
			MOVE R12, $12C			
			LBI R1, #$30			
			SBC R15, R1			
			MOVE $1F6, R12			
			LBI R1, #$6D			
			MOVE $1FC, R1			
			JMP ($01F8)			
						
			MOVE R1, $A4			
			SET R1, #$01			
			MOVE $A4, R1			
			CTRL $4, #$42			
			MOVB R8, (R14)			
			MOVE R11, R9			
			SNE R8, R11			
			LBI R11, #$6D			
			MLH R11, R8			
			MOVE R5, $B0			
			SZ R5			
			BRA $1CAC		; $18(R0)	
						
			SUB R10, #$01			
			LBI R1, #$FF			
			SBSH R10, R1			
			BRA $1C8E		; -> -$0E(R0)	
						
			LBI R10, #$40			
			MLH R10, R10			
			LBI R10, #$00			
			MOVB (R14), R11			
			MHL R1, R11			
			MLH R1, R11			
			MOVE R11, R1			
			BRA $1C8E		; -> -$1E(R0)	
						
			MOVE R1, $A0			
			MOVE $B0, R1			
			MOVB (R14), R8			
			LBI R1, #$2F			
			SNE R5, R1			
			JMP ($00F8)			
						
			LBI R1, #$2E			
			SE R5, R1			
			SNZ R7			
			RET R4			
						
			LBI R1, #$3A			
			SNE R5, R1			
			RET R4			
						
			LBI R1, #$3D			
			SNE R5, R1			
			RET R4			
						
			LBI R1, #$42			
			SNE R5, R1			
			RET R4			
						
			LBI R1, #$45			
			SNE R5, R1			
			RET R4			
						
			LBI R1, #$47			
			SGT R5, R1			
			BRA $1C7C		; -> -$62(R0)	
						
			LBI R1, #$F9			
			LBI R11, #$F0			
			SGT R5, R1			
			SGE R5, R11			
			BRA $1CEA		; $02(R0)	
						
			RET R4			
						
			LBI R11, #$C1			
			LBI R1, #$C6			
			SGT R5, R1			
			SGE R5, R11			
			BRA $1C7C		; -> -$78(R0)	
						
			RET R4			
						
						
			CTRL $4, #$43			
			MOVE $1FE, R14			
			LBI R8, #$5A			
			MOVE R11, $1FC			
			SGE R11, R8			
			BRA $1D0E		; $0C(R0)	
						
			LBI R14, #$05			
			MLH R14, R14			
			LBI R14, #$C0			
			INC2 R2, R0			
			JMP ($01F0)			
						
			SUB R14, #$40			
			MOVE R10, $1FA			
			ADD R10, R11			
			MOVE R1, $A0			
			LBI R1, #$14			
			CTRL $1, #$02			
			PUTB $1, (R1)+			
			PUTB $1, (R1)			
			BRA $1D1D		; -> -$01(R0)	
						
			GETB R10, $1			
			SNS R10			
			BRA $1D28		; $04(R0)	
						
			MOVB (R14)+, R10			
			BRA $1D1E		; -> -$0A(R0)	
						
			SLT R11, R8			
			BRA $1D30		; $04(R0)	
						
			MOVE R14, $1FE			
			RET R2			
						
			MOVE R14, R13			
			MOVE $1FE, R7			
			MOVE R7, $A0			
			INC2 R4, R0			
			JMP ($01F4)			
						
			LBI R14, #$05			
			MLH R14, R14			
			LBI R14, #$C0			
			INC2 R2, R0			
			JMP ($01F0)			
						
			MOVE R7, $1FE			
			JMP ($01F6)			
						
						
						
						
			BRA $1D4C		; $02(R0)	
						
			LBI R11, #$04		; four digits	
			MOVE R15, $A0			
						
			MOVB R5, (R14)+			
			LBI R1, #'9'			
			LBI R10, #'0'			
			SGT R5, R1			
			SGE R5, R10			
			BRA $1D5E		; $04(R0)	
						
			SUB R5, #'0'			
			BRA $1D6C		; $0E(R0)	
						
			LBI R1, #'F'			
			LBI R10, #'A'			
			SGT R5, R1			
			SGE R5, R10			
			BRA $1D82		; No hex digit	
						
			ADD R5, #10			
			SUB R5, #'A'			
						
			SWAP R15			
			OR R15, R5			
			SUB R11, #$01			
			LBI R1, #$02			
			SE R11, R1			
			BRA $1D7C		; $04(R0)	
						
			MLH R15, R15			
			LBI R15, #$00			
			SZ R11			
			BRA $1D4E		; -> -$32(R0)	
						
			RET R4			
						
			MOVE R13, R14			
			JMP ($01F8)			
						
						
						
						
			LBI R11, #$02			
			MHL R15, R5		; convert high byte	
						
			LBI R10, #$0F			
			SWAP R15		; convert one nibble	
			AND R10, R15			
			LBI R1, #$09			
			SLE R10, R1			
			ADD R10, #$C7			
			ADD R10, #'0'			
			MOVB (R14)+, R10			
			SNS R11			
			RET R4			; all four nibbles done
						
			SUB R11, #$01			
			SNZ R11			
			MOVE R15, R5			
			BRA $1D8A		; convert low byte	
						
						
			MOVE R8, $A0			
			MOVB R1, (R14)+			
			ADD R8, #$01			
			SE R1, R9			
			BRA $1DA8		; -> -$08(R0)	
						
			LBI R1, #$05			
			SLT R8, R1			
			JMP ($01F8)			
						
			MOVE R13, R14			
			SUB R14, #$02			
			MOVB R15, (R14)-			
			LBI R8, #$F0			
			SBS R15, R8			
			JMP ($01F8)			
						
			SUB R15, #$F0			
			MOVE R10, $A0			
			MOVB R11, (R14)-			
			SNE R11, R9			
			RET R4			
						
			SBS R11, R8			
			JMP ($01F8)			
						
			SUB R11, #$F0			
			SZ R10			
			BRA $1DDA		; $04(R0)	
						
			LBI R10, #$0A			
			BRA $1DE8		; $0E(R0)	
						
			ADD R10, #$5A			
			LBI R1, #$64			
			SGT R10, R1			
			BRA $1DE8		; $06(R0)	
						
			LBI R10, #$03			
			MLH R10, R10			
			LBI R10, #$E8			
			SNZ R11			
			BRA $1DC6		; -> -$26(R0)	
						
			SUB R11, #$01			
			ADD R15, R10			
			MOVE R1, R10			
			MHL R1, R15			
			ADDH2 R1, R1			
			MLH R15, R1			
			BRA $1DE8		; -> -$12(R0)	
						
						
			BRA $1E02		; $06(R0)	
						
						
						
						
			LBI R14, #$02			
			MLH R14, R14			
			LBI R14, #$00			
						
						
						
			LBI R9, #$40			
			MLH R9, R9			
			MOVE (R14)+, R9			
			LBI R1, #$06			
			SBSH R14, R1			
			BRA $1E06		; -> -$08(R0)	
						
			RET R2			
						
						
						
						
						
			MOVE R12, R2		; Save R2	
						
			; Clear bottom line			
			LBI R14, #$05			
			MLH R14, R14			
			LBI R14, #$C0			
			INC2 R2, R0			
			BRA $1E02		; -> -$1A(R0)	
						
			SUB R14, #$3F			
			LBI R1, #'E'			
			MOVB (R14)+, R1		; 'E'	
			LBI R1, #'R'			
			MLH R1, R1			
			MOVE (R14)+, R1		; 'RR'	
			LBI R11, #'O'			
			MLH R1, R11			
			MOVE (R14)+', R1	; 'OR '		
			LBI R1, #'0'			
			MOVB (R14)+, R1		; '0'	
			MOVE R11, R3			
			ADD R11, #$0C		; IOCB_Ret	
			MOVE R1, (R11)			
			MOVE (R14)+', R1			
			MOVE R5, (R3)		; IOCB_DA and _Sub	
			INC2 R4, R0			
			BRA $1D86		; Convert to hex	
						
			SUB R14, #$04			
			MOVB (R14), R9			
						
			MOVE R8, R12			
			JMP ($00AC)		; Return to caller	
						
						
			LBI R9, #$40			
			MLH R9, R9		; '  '	
			LBI R1, #$1D			
			MLH R1, R1			
			LBI R1, #$FC			
			DEC2 R1, R1		; R1 <- $1DFA	
			MOVE $1F0, R1			
						
			LBI R1, #$1D			
			MLH R1, R1			
			LBI R1, #$4A			
			MOVE $1F2, R1			
						
			LBI R1, #$1C			
			MLH R1, R1			
			LBI R1, #$7C			
			MOVE $1F4, R1			
						
			LBI R1, #$1C			
			MLH R1, R1			
			LBI R1, #$F6			
			MOVE $1F8, R1			
						
			MOVE R15, $A0			
			LBI R15, #$14			
			LBI R10, #$0B			
			MLH R10, R10			
			LBI R10, #$F6			
			CTRL $4, #$43			
			CTRL $1, #$02			
			PUTB $1, (R15)+			
			PUTB $1, (R15)			
			BRA $1E81		; -> -$01(R0)	
						
			GETB R11, $1			
			MLH R11, R11			
			NOP			
			GETB R11, $1			
			MOVE $1FA, R11			
			RET R4			
						
			MOVE R15, $A0			
			ADD R15, #$100			
			MOVE $12E, R15			
			LBI R1, #$18			
			MLH R1, R1			
			LBI R1, #$FE			
			MOVE $130, R1			
			LBI R1, #$1B			
			MLH R1, R1			
			LBI R1, #$CA			
			MOVE $132, R1			
			LBI R1, #$1D			
			MLH R1, R1			
			LBI R1, #$A6			
			MOVE $134, R1			
			LBI R1, #$04			
			MLH R1, R1			
			LBI R1, #$00			
			MOVE $13A, R1			
			LBI R12, #$01			
			MLH R12, R12			
			LBI R12, #$60			
			MOVE R11, R12			
			ADD R11, #$80			
			MOVE R10, $A0			
			MOVE (R12)+, R10			
			SE R12, R11			
			BRA $1EC0		; -> -$06(R0)	
						
			RET R4			
						
			INC2 R2, R0			
			BRA $1F0C		; $40(R0)	
						
			INC2 R8, R2			
			CTRL $F, #$FF			
			MOVE R12, $100			
			MHL R15, R12			
			LBI R12, #$7F			
			LBI R1, #$0E			
			SE R15, R1			
			BRA $1EEC		; $10(R0)	
						
			CTRL $E, #$80			
			STAT R5, $E			
			SNS R5			
			BRA $1EFC		; $18(R0)	
						
			GETB R11, $E			
			SE R11, R12			
			BRA $1EFC		; $12(R0)	
						
			JMP ($00AC)			
						
			CTRL $D, #$80			
			STAT R5, $D			
			SNS R5			
			BRA $1EFC		; $08(R0)	
						
			GETB R11, $D			
			SE R11, R12			
			BRA $1EFC		; $02(R0)	
						
			JMP ($00AC)			
						
			LBI R11, #$F1			
			MLH R11, R11			
			LBI R11, #$F3			
			SS R5			
			LBI R11, #$F4			
			MOVE $10C, R11			
			MOVE R8, R2			
			JMP ($00AC)			
						
			MOVE $A6, R2			
			INC2 R4, R0			
			BRA $1E48		; -> -$CA(R0)	
						
			INC2 R4, R0			
			BRA $1E8E		; -> -$88(R0)	
						
			MOVE R3, $12E			
			LBI R1, #$0E			
			MLH R1, R1			
			LBI R1, #$80			
			MOVE $100, R1			
			MOVE R1, $A0			
			MOVE $102, R1			
			MOVE R1, $13A			
			MOVE $104, R1			
			MOVE $106, R1			
			SUB R1, #$80			
			MOVE $136, R1			
			INC2 R4, R0			
			BRA $1F90		; $5E(R0)	
						
			BRA $1F44		; $10(R0)	
						
			LBI R1, #$0D			
			MLH R1, R1			
			LBI R1, #$80			
			MOVE $100, R1			
			NOP			
			NOP			
			INC2 R4, R0			
			BRA $1F90		; $4C(R0)	
						
			MOVE R1, $A8			
			MOVE $142, R1			
			LBI R1, #$40			
			MLH R1, R1			
			LBI R1, #$00			
			MOVE $140, R1			
			MOVE R1, $A0			
			INC R1, R1			
			MOVE $144, R1			
			NOP			
			NOP			
			MOVE R1, $106			
			MOVE $14E, R1			
			LBI R1, #$01			
			MLH R1, R1			
			LBI R1, #$60			
			MOVE $10A, R1			
			MOVE R6, $110			
			LBI R7, #$C0			
			MLH R7, R7			
			LBI R7, #$00			
			DEC2 R2, R0			
			ADD R2, #$0E			
			MOVE $1F6, R2			
			LBI R1, #$17			
			MLH R1, R1			
			LBI R1, #$00			
			RET R1			
						
			SZ R15			
			HALT			
			MOVE R8, $140			
			INC R8, R8			
			MOVE R15, $AC			
			ADD R15, #$0A			
			MOVE R12, $A0			
			LBI R12, #$84			
			MOVE (R15), R12			
			JMP ($00AC)			
						
			MOVE $13C, R4			
			MOVE R8, $AE			
			INC2 R2, R0			
			JMP ($00AC)			
						
			MOVE R4, $13C			
			MOVE R15, $10C			
			MOVE R12, $100			
			MHL R12, R12			
			LBI R11, #$0E			
			SNZ R15			
			RET R4			
						
			SE R12, R11			
			BRA $1FB8		; $0E(R0)	
						
			MHL R12, R15			
			LBI R11, #$F1			
			LBI R10, #$F3			
			SNE R12, R11			
			SE R15, R10			
			BRA $1FB8		; $02(R0)	
			INC2 R0, R4			
						
			MOVE R8, $FA			
			INC2 R2, R0			
			JMP ($00AC)			
						
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
						
						
						
						
			LBI R1, #$05			
			MLH R1, R1			
			LBI R1, #$01			
			MOVE $1C0, R1		; $1C0 <- $0501	
						
			LBI R1, #$08			
			MLH R1, R1			
			LBI R1, #$00			
			MOVE $60, R1		; R0L3 <- $0800	
						
			LBI R1, #$0D			
			MLH R1, R1			
			LBI R1, #$00			
			MOVE $FE, R1		; $FE <- $0D00	
						
			LBI R1, #$0F			
			MLH R1, R1			
			LBI R1, #$40			
			MOVE $E6, R1		; $E6 <- $0F40	
						
			LBI R1, #$10			
			MLH R1, R1			
			LBI R1, #$00			
			MOVE $F8, R1		; $F8 <- $1000	
						
			ADD R1, #$0A			
			MOVE $FA, R1		; $FA <- $100A	
						
			MOVE R8, R2			
			JMP ($00AC)		; Return	
						
			BRA $1FCE		; -> -$32(R0)	
						
						
						
						
						
						
						
						
						
						
						
						
						
			MOVE $D2, R2		; Save return address	
						
			MOVE R5, (R3)			
			MHL R5, R5			
			LBI R1, #$0D		; Is IOCB_DA = $D ?	
			SNE R5, R1			
			BRA $2010		; Yes	
						
			; Device address not $Dx0			
						
			LBI R6, #$5E		; Error 02	
			BRA $2076			
						
			; Device address correct			
						
			CTRL $F, #$01		; Reset diskette adapter	
			MOVE R8, $A6			
			INC2 R2, R0			
			JMP ($00AC)		; Test if device ready	
			BRA $2038		; Not ready	
						
			; Device ready			
						
			MOVE R5, (R3)			
			LBI R1, #$0F		; Test subdevice	
			SBC R5, R1			
			BRA $200C		; Subdevice not $x0	
						
			; Subdevice OK			
						
			INC2 R4, R3			
			MOVB R5, (R4)		; IOCB_Cmd	
			SZ R5			
			BRA $203A		; Not Sense command	
						
			; Sense			
						
			ADD R4, #$0E			
			MOVE R7, $A0			
			LBI R7, #$04			
			MOVE (R4), R7		; Set IOCB_Stat1 to $0004	
						
			MOVE R8, $C4			
			INC2 R2, R0			
			JMP ($00AC)		; Wait for printer	
			BRA $2124		; Exit if error	
						
			LBI R4, #$00			
			MLH R4, R4			
			LBI R4, #$A4			
			MOVB R5, (R4)			
			SET R5, #$02		; Set I/O active flag	
			MOVB (R4)+, R5			
			MOVB R5, (R4)			
			CLR R5, #$20		; Level 2 in ROS	
			SET R5, #$08		; (?)	
			MOVB (R4), R5			
			PUTB $0, (R4)			
						
			CTRL $0, #$6F		; CRT off	
			LBI R5, #$08			
			MOVE $90, R5			
			STAT R5, $D		; Diskette sense byte	
			LBI R1, #$08			
			SBS R5, R1		; Erase Gate Sense ?	
			BRA $2062		; No	
			LBI R6, #$1E		; Error 34	
			BRA $2076		; Exit	
						
			CTRL $D, #$01		; Reset Read/Write/Diag	
			INC2 R4, R3			
			MOVB R5, (R4)		; IOCB_Cmd	
			SNZ R5			
			BRA $212A		; Sense command	
						
			; Other command			
						
			GETB R7, $D		; Access Sense byte	
			LBI R1, #$80			
			SBS R7, R1		; New Media ?	
			BRA $2080		; No	
						
			; New media -> error			
						
			LBI R6, #$26		; Error 30	
						
			LBI R1, #$3E			
			MLH R1, R1			
			LBI R1, #$FA			
			INC2 R2, R0			
			RET R1			; Error exit
						; (doesn't return)
						
			LBI R1, #$04			
			SE R5, R1		; Find command ?	
			BRA $208E		; No	
						
			; Find			
						
			LBI R1, #$23			
			MLH R1, R1			
			LBI R1, #$16			
			RET R1			; Jump to $2316
						
						
			LBI R1, #$05			
			SE R5, R1		; Mark command ?	
			BRA $209C		; No	
						
			; Mark			
						
			LBI R1, #$24			
			MLH R1, R1			
			LBI R1, #$A6			
			RET R1			; Jump to $24A6
						
						
			MOVE R7, (R4)		; IOCB_Flags to Lo(R7)	
			LBI R1, #$01			
			SBC R7, R1		; Absolute command ?	
			BRA $20D8		; Yes, skip following tests	
						
			; The following commands are not availavle			
			; with the absolute flag set			
						
			ADD R4, #$08			
			MOVE R4, (R4)		; IOCB_WA	
			ADD R4, #$09			
			MOVB R7, (R4)			
			SNS R7			
			BRA $20E4		; $34(R0)	
						
			LBI R1, #$03		; Write last ?	
			SNE R5, R1			
			BRA $20E2		; Yes, jump to write routine	
						
			LBI R1, #$08		; (???)	
			SNE R5, R1			
			BRA $20DC		; (Jump to read routine)	
						
			LBI R1, #$0B		; Write Header ?	
			SE R5, R1			
			BRA $20CA		; No	
						
			; Write Header			
						
			LBI R1, #$27			
			MLH R1, R1			
			LBI R1, #$14			
			RET R1			; JMP $2714
						
						
			LBI R1, #$0C		; Scan ?	
			SE R5, R1			
			BRA $20D8		; No	
						
			LBI R1, #$28			
			MLH R1, R1			
			LBI R1, #$40			
			RET R1			; JMP $2840
						
						
			; Read/Write			
						
			LBI R1, #$01		; Read ?	
			SNE R5, R1			
			BRA $21BA		; Yes	
						
						
			LBI R1, #$02		; Write ?	
			SNE R5, R1			
			BRA $21B8		; Yes	
						
						
			LBI R1, #$10		; Find ID ?	
			SE R5, R1			
			BRA $2102		; No	
						
			; Find ID			
						
			; Preset track, side and sector from CI1			
			LBI R1, #$37			
			MLH R1, R1			
			LBI R1, #$1E			
			INC2 R2, R0			
			RET R1			; CALL $371E,R2
						
			; Locate sector on disk (implies seek etc)			
			LBI R1, #$37			
			MLH R1, R1			
			LBI R1, #$80			
			INC2 R2, R0			
			RET R1			; CALL $3780,R2
						
			CTRL $D, #$01			
			BRA $2118		; Finished	
						
						
			LBI R1, #$11		; Initialize Head ?	
			SE R5, R1			
			BRA $2114		; No, error 02	
						
			; Initialize Head			
						
			LBI R1, #$3A			
			MLH R1, R1			
			LBI R1, #$6C			
			INC2 R2, R0			
			RET R1			; CALL $3A6C,R2
			BRA $2118		; Finished	
						
						
			LBI R6, #$5E		; Error 02	
			BRA $2076		; Error exit	
						
						
			; Exit Diskette I/O Supervisor			
						
			MOVE R5, $A4			
			MHL R1, R5			
			CLR R1, #$02		; Clear I/O active flag	
			CLR R5, #$08			
			MLH R5, R1			
			MOVE $A4, R5			
						
			MOVE R2, $D2			
			MOVE R8, R2			
			JMP ($00AC)		; Return to caller	
						
						
						
						
						
						
			GETB R5, $D		; Access Sense Byte	
			LBI R1, #$80			
			SBS R5, R1		; New Media ?	
			BRA $2158		; No	
						
			; New Media			
			; Set track value to $FF (=new media)			
						
			LBI R11, #$FF			
			LBI R1, #$3B			
			MLH R1, R1			
			LBI R1, #$7C			
			INC2 R2, R0			
			RET R1			; Set track value
						
			INC2 R4, R3			
			MOVE R5, (R4)			
			SET R5, #$40		; IOCB_Flags	
			MOVE (R4), R5			
						
			; Test index timing			
						
			LBI R1, #$3A			
			MLH R1, R1			
			LBI R1, #$DC			
			INC2 R2, R0			
			RET R1			; CALL $3ADC, R2
						
			GETB R5, $D		; Access Sense Byte	
			MOVE R4, $A0			
			LBI R4, #$0B		; Address of Lo(R5)	
			PUTB $D, (R4)		; This clears New Media bit	
						
			; No new media			
						
			LBI R1, #$3B			
			MLH R1, R1			
			LBI R1, #$78			
			INC2 R2, R0			
			RET R1			; Get track value
						
			SS R11			; Track $FF ?
			BRA $2170		; No	
						
			; Track unknown			
						
			LBI R1, #$3A			
			MLH R1, R1			
			LBI R1, #$6C			
			INC2 R2, R0			
			RET R1			; Recalibrate
						
			; Track known			
						
			MOVE R5, $A0			
			MOVE $9A, R5		; Track 0	
			MOVE $9C, R5			
			LBI R5, #$07		; Sector 7	
			MOVE $9E, R5			
			LBI R5, #$D0		; Max. 8 revolutions to find	
			MOVE $98, R5		; sector ($D0 / 26 = 8)	
						
			LBI R1, #$34			
			MLH R1, R1			
			LBI R1, #$38			
			INC2 R2, R0			
			RET R1			; Read sector
						
			SNZ R6			; Error returned ?
			BRA $2190		; No	
						
			LBI R6, #$32		; Error 24	
			BRA $2238		; Exit	
						
			LBI R1, #$3A			
			MLH R1, R1			
			LBI R1, #$14			
			INC2 R2, R0			
			RET R1			; Verify volume header
						
			LBI R1, #$33			
			MLH R1, R1			
			LBI R1, #$7E			
			INC2 R2, R0			
			RET R1			; Verify diskette parameters
						
			ADD R4, #$02			
			MOVE R7, $A0			
			LBI R7, #$0A			
			MOVE (R4), R7		; IOCB_CI1 <- $000A	
						
			ADD R4, #$08			
			LBI R7, #$F1			
			MLH R7, R7			
			LBI R7, #$C4			
			MOVE (R4), R7		; IOCB_Stat1 <- '1D'	
						
			BRA $2118		; Return	
						
						
			; Write			
						
			BRA $2280		; $C6(R0)	
						
						
						
						
						
						
			MOVE R4, R3			
			ADD R4, #$03		; IOCB_Flags	
			MOVB R5, (R4)			
			LBI R1, #$01			
			SBC R5, R1			
			BRA $2264		; Absolute Read	
						
						
						
						
						
						
			MOVE R5, $90			
			CLR R5, #$08			
			MOVE $90, R5			
						
			; Get number of sectors (-> R2L2)			
			LBI R1, #$29			
			MLH R1, R1			
			LBI R1, #$9C			
			INC2 R2, R0			
			RET R1			; CALL $299C, R2
						
			MOVE R4, R3			
			ADD R4, #$0E			
			MOVE R5, $A0			
			MOVE (R4), R5		; Clear IOCB_CI2	
						
			SUB R4, #$0A			
			MOVE R5, (R4)		; IOCB_BA	
			MOVE $5C, R5		; R14L2	
						
			; Test if operation within file limits			
			LBI R1, #$33			
			MLH R1, R1			
			LBI R1, #$36			
			INC2 R2, R0			
			RET R1			; Call $3336, R2
						
			; Calculate track, side and sector for I/O			
			MOVE R4, R3			
			ADD R4, #$08		; IOCB_CI1	
			MOVE R13, (R4)		; Get file offset	
			LBI R1, #$2F			
			MLH R1, R1			
			LBI R1, #$12			
			INC2 R2, R0			
			RET R1			; CALL $2F12, R2
						
			; Read sector			
			LBI R1, #$34			
			MLH R1, R1			
			LBI R1, #$38			
			INC2 R2, R0			
			RET R1			; CALL $3438, R2
						
			; Test if any error or flags			
			SZ R6			
			BRA $2228		; Yes, error or flag	
						
			; No, everything's ok			
			MOVE R4, R3			
			ADD R4, #$0E		; IOCB_CI2	
			MOVE R5, (R4)			
			ADD R5, #$01			
			MOVE (R4), R5		; Increment number of read sect.	
						
			; Adjust current buffer address for read interrupt			
			LBI R1, #$36			
			MLH R1, R1			
			LBI R1, #$F8			
			INC2 R2, R0			
			RET R1			; CALL $36F8, R2
						
			; Decrement loop count			
			MOVE R5, $44		; R2L2	
			SUB R5, #$01			
			MOVE $44, R5			
			BRA $224E		; $26(R0)	
						
						
			; Error or flag returned from read routine			
			MOVE R5, $52			
			LBI R1, #$C6		; Flag 'F' (bad sector) ?	
			SNE R5, R1			
			BRA $2242		; Yes	
						
			LBI R1, #$C4		; Flag 'D' (DDAM) ?	
			SNE R5, R1			
			BRA $2242		; Yes	
						
			; Hard error			
			LBI R6, #$18		; Error 37	
			LBI R1, #$3E			
			MLH R1, R1			
			LBI R1, #$FA			
			INC2 R2, R0			
			RET R1			; Error exit
						
						
			MOVE R4, R3			
			ADD R4, #$03		; IOCB_Flags	
			MOVB R5, (R4)			
			LBI R1, #$08			
			SBC R5, R1			
			BRA $227C		; Error 44	
						
			; Increment file offset			
			LBI R1, #$33			
			MLH R1, R1			
			LBI R1, #$2A			
			INC2 R2, R0			
			RET R1			; CALL $332A, R2
						
			; Loop if any sectors left, else return to caller			
			MOVE R5, $44		; R2L2	
			MHL R1, R5			
			OR R5, R1			
			SZ R5			
			BRA $21E4		; Loop	
			BRA $21B6		; Return	
						
						
			; Absolute Read			
						
			; Preset track, side and sector from CI1			
			LBI R1, #$37			
			MLH R1, R1			
			LBI R1, #$1E			
			INC2 R2, R0			
			RET R1			; CALL $371E, R2
						
			; Read sector			
			LBI R1, #$34			
			MLH R1, R1			
			LBI R1, #$38			
			INC2 R2, R0			
			RET R1			; CALL $3438, R2
						
			SNZ R6			
			BRA $21B6		; Return	
						
			LBI R6, #$0A		; Error 44	
			BRA $2238		; Error exit	
						
						
						
						
						
						
			MOVE R4, R3			
			ADD R4, #$03			
			MOVB R5, (R4)			
			LBI R1, #$01			
			SBC R5, R1			
			BRA $22F4		; Absolute Write	
						
						
						
						
						
						
			ADD R4, #$05			
			MOVE R7, (R4)			
			ADD R4, #$02			
			MOVE R4, (R4)			
			ADD R4, #$02			
			MOVE R8, (R4)+			
			MHL R5, R7			
			MHL R10, R8			
			SLE R5, R10			
			BRA $22B8		; $18(R0)	
						
			SLT R5, R10			
			SGT R7, R8			
			BRA $22A8		; $02(R0)	
						
			BRA $22B8		; $10(R0)	
						
			MOVE R8, (R4)			
			MOVE $EA, R8			
			MHL R10, R8			
			SLE R5, R10			
			BRA $22B8		; $06(R0)	
						
			SLT R5, R10			
			SGT R7, R8			
			BRA $22BC		; $04(R0)	
						
			LBI R6, #$4E			
			BRA $2238		; -> -$84(R0)	
						
			LBI R1, #$29			
			MLH R1, R1			
			LBI R1, #$9C			
			INC2 R2, R0			
			RET R1			
						
			MOVE R5, $90			
			CLR R5, #$28			
			MOVE $90, R5			
			LBI R1, #$34			
			MLH R1, R1			
			LBI R1, #$9E			
			INC2 R2, R0			
			RET R1			
						
			MOVE R4, R3			
			ADD R4, #$08			
			MOVE R7, (R4)+			
			MOVE R4, (R4)+			
			ADD R4, #$02			
			MOVE R8, (R4)			
			MHL R5, R7			
			MHL R10, R8			
			SLE R5, R10			
			BRA $22F0		; $06(R0)	
						
			SLT R5, R10			
			SGT R7, R8			
			BRA $22F2		; $02(R0)	
						
			MOVE (R4), R7			
			BRA $227A		; -> -$7A(R0)	
						
						
						
						
						
						
			LBI R1, #$37			
			MLH R1, R1			
			LBI R1, #$1E			
			INC2 R2, R0			
			RET R1			; preset track/side/sector
						
			MOVE R5, $90			
			CLR R5, #$20			
			MOVE $90, R5			
						
			LBI R1, #$34			
			MLH R1, R1			
			LBI R1, #$9E			
			INC2 R2, R0			
			RET R1			
						
			SNZ R6			
			BRA $227A		; -> -$98(R0)	
						
			LBI R6, #$3C			
			BRA $2238		; -> -$DE(R0)	
						
						
						
						
						
						
			MOVE R4, R3			
			ADD R4, #$0A			
			MOVE R7, (R4)		; IOCB_WA	
			ADD R7, #$09			
			LBI R5, #$FF			
			MOVB (R7), R5			
						
			SUB R4, #$07		; IOCB_Flags	
			MOVB R5, (R4)			
			LBI R1, #$06		; Bits 5 and 6	
			SBS R5, R1		; Both bits set ?	
			BRA $2330		; No	
						
			; Invalid IOCB_Flags			
						
			LBI R6, #$5E		; Error 02	
			BRA $238E			
						
			; Flags OK			
						
			LBI R1, #$04		; Test bit 5	
			SBC R5, R1		; Clear = Find by number	
			BRA $235A		; Find by name	
						
			; Check file number			
						
			ADD R4, #$05			
			MOVE R5, (R4)+		; IOCB_CI1	
			MOVE $EA, R5		; Contains file number	
			LBI R1, #$80			
			SNBSH R5, R1		; File number in valid range ?	
			BRA $238C		; No, error 36	
						
			MHL R1, R5			
			OR R1, R5			
			SNZ R1			; File number <> 0 ?
			BRA $238C		; No, error 36	
						
			; File number valid			
						
			MOVE R4, (R4)		; IOCB_WA	
			ADD R4, #$06			
			MOVE (R4), R5		; Store file number in WA	
						
			INC2 R4, R3			
			MOVE R8, (R4)		; IOCB_Flags	
			LBI R1, #$02		; Test bit 6	
			SBS R8, R1			
			BRA $2438		; $DE(R0)	
						
			; Find by name			
						
			MOVE R5, $90			
			CLR R5, #$02			
			MOVE $90, R5			
						
			LBI R1, #$31			
			MLH R1, R1			
			LBI R1, #$BA			
			INC2 R2, R0			
			RET R1			; CALL $31BA, R2
						
			INC2 R4, R3			
			MOVE R7, (R4)		; IOCB_Flags	
			LBI R1, #$02		; Test bit 6	
			SBS R7, R1			
			BRA $2390		; $1C(R0)	
						
			ADD R4, #$06			
			MOVE R7, (R4)		; IOCB_CI1	
			MOVE $F6, R7			
			SUB R5, R7			
			MHL R7, R5			
			MLH R5, R5			
			MHL R5, R7			
			SUB R7, R5			
			MHL R5, R5			
			MLH R5, R7		; R5 <- R5 - R7	
			ADD R5, #$01			
			BRA $2396		; $0A(R0)	
						
			LBI R6, #$1A		; Error 36	
			BRA $245C			
						
						
			MOVE R7, $A0			
			LBI R7, #$01			
			MOVE $F6, R7			
						
			MOVE $8E, R5			
			MOVE R4, R3			
			ADD R4, #$04			
			MOVE R5, (R4)			
			MOVE $EE, R5			
			MOVE R5, $F6			
			LBI R1, #$2F			
			MLH R1, R1			
			LBI R1, #$E8			
			INC2 R2, R0			
			RET R1			
						
			LBI R1, #$34			
			MLH R1, R1			
			LBI R1, #$38			
			INC2 R2, R0			
			RET R1			
						
			SZ R6			
			BRA $241A		; $60(R0)	
						
			MOVE R5, $90			
			LBI R1, #$10			
			SBS R5, R1			
			BRA $23D6		; $14(R0)	
						
			MOVE R4, $EE			
			MOVE R5, $F6			
			LBI R1, #$01			
			SBC R5, R1			
			ADD R4, #$80			
			MOVE $EE, R4			
			MOVB R5, (R4)			
			LBI R1, #$C4			
			SNE R5, R1			
			BRA $23F2		; $1C(R0)	
						
			INC2 R4, R3			
			MOVE R7, (R4)			
			LBI R1, #$02			
			SBS R7, R1			
			BRA $23E8		; $08(R0)	
						
			MOVE R5, $F6			
			MOVE $EA, R5			
			BRA $2466		; $80(R0)	
						
			BRA $2310		; -> -$D8(R0)	
						
			LBI R1, #$29			
			MLH R1, R1			
			LBI R1, #$66			
			INC2 R2, R0			
			RET R1			
						
			MOVE R5, $F6			
			ADD R5, #$01			
			MOVE $F6, R5			
			MOVE R5, $8E			
			SUB R5, #$01			
			MOVE $8E, R5			
			MHL R1, R5			
			OR R1, R5			
			SNZ R1			
			BRA $2430		; $2A(R0)	
						
			MOVE R5, $90			
			LBI R1, #$10			
			SBS R5, R1			
			BRA $2398		; -> -$76(R0)	
						
			MOVE R5, $F6			
			LBI R1, #$01			
			SBS R5, R1			
			BRA $2398		; -> -$7E(R0)	
						
			MOVE R4, $EE			
			BRA $23CA		; -> -$50(R0)	
						
			MOVE R5, $90			
			LBI R1, #$10			
			SBS R5, R1			
			BRA $23F2		; -> -$30(R0)	
						
			MOVE R5, $F6			
			ADD R5, #$02			
			MOVE $F6, R5			
			MOVE R5, $8E			
			SUB R5, #$02			
			MOVE $8E, R5			
			BRA $23FE		; -> -$32(R0)	
						
			MOVE R5, $90			
			LBI R1, #$02			
			SBS R5, R1			
			BRA $2486		; $4E(R0)	
						
			; Find by number			
						
			MOVE R5, $EA		; Get file number	
			LBI R1, #$2F			
			MLH R1, R1			
			LBI R1, #$E8			
			INC2 R2, R0			
			RET R1			; Get location of dir. entry
						
			LBI R1, #$34			
			MLH R1, R1			
			LBI R1, #$38			
			INC2 R2, R0			
			RET R1			; Read sector
						
			SNZ R6			; Errors ?
			BRA $2466		; No	
						
			MOVE R5, $52		; R9L2	
			LBI R1, #$C4			
			SNE R5, R1		; First data byte 'D' ?	
			BRA $2486		; Yes, deleted dir. entry	
						
			LBI R6, #$18		; Error 37	
						
			LBI R1, #$3E			
			MLH R1, R1			
			LBI R1, #$FA			
			INC2 R2, R0			
			RET R1			; Error exit
						
			; No errors during read of directory entry			
						
			MOVE R4, R3			
			ADD R4, #$04			
			MOVE R7, (R4)++		; IOCB_BA	
						
			MOVE R5, $EA			
			MOVE (R4), R5		; Store file no. in IOCB_CI1	
						
			MOVE R8, $90			
			LBI R1, #$10			
			SBS R8, R1		; MFM (Diskette 2D) ?	
			BRA $248A		; No	
						
			LBI R1, #$01			
			SBC R5, R1		; Odd file number ?	
			ADD R7, #$80		; Yes, add offset 128 bytes	
						
			MOVB R8, (R7)			
			LBI R1, #$C4			
			SE R8, R1		; Deleted dir. entry ?	
			BRA $248A		; No	
						
			; Deleted directory entry			
						
			LBI R6, #$10		; Error 41	
			BRA $245C		; Exit	
						
			; Directory entry valid			
						
			ADD R4, #$06			
			MOVE (R4)--, R7		; Ptr to dir entry in IOCB_CI2	
						
			MOVE R4, (R4)		; IOCB_WA	
			ADD R4, #$09			
			LBI R1, #$04		; (Last command?)	
			MOVB (R4)---, R1			
			MOVE (R4), R5		; Store file number in WA	
						
			; Parse header record			
			MOVE R4, R7			
			LBI R1, #$30			
			MLH R1, R1			
			LBI R1, #$AA			
			INC2 R2, R0			
			RET R1			; CALL $30AA, R2
						
			BRA $23E6		; Return	
						
						
						
						
						
						
			MOVE R4, R3			
			ADD R4, #$0E		; IOCB_CI2	
			MOVE R15, (R4)		; Number of files to mark	
			MHL R1, R15			
			OR R1, R15			
			SNZ R1			
			BRA $24EC		; Zero -> error 02	
						
			LBI R1, #$80			
			SNBSH R15, R1			
			BRA $24EC		; Negative -> error 02	
						
			SUB R4, #$04			
			MOVE R4, (R4)		; IOCB_WA	
			ADD R4, #$06			
			MOVE R5, (R4)		; Current file number	
			MHL R1, R5			
			OR R1, R5			
			SNZ R1			
			BRA $24EC		; Zero -> error 02	
						
			; Last file number (-> R15)			
			ADD R15, R5			
			MHL R5, R15			
			ADDH R5, R5			
			MLH R15, R5			
			SUB R15, #$01			
						
			; Get total number of directory entries (-> R5)			
			LBI R1, #$31			
			MLH R1, R1			
			LBI R1, #$BA			
			INC2 R2, R0			
			RET R1			; CALL $31BA, R2
						
			MHL R7, R5			
			MHL R8, R15			
			SLE R8, R7			
			BRA $24EC		; $06(R0)	
			SLT R8, R7			
			SGT R15, R5			
			BRA $24F0		; $04(R0)	
						
			; Last file number > last directory entry			
			LBI R6, #$5E		; Error 02	
			BRA $257E		; Error exit	
						
						
			; Read Volume Header			
			MOVE R5, $A0			
			MOVE $9A, R5		; Track 0	
			MOVE $9C, R5		; Side 0	
			LBI R5, #$07			
			MOVE $9E, R5		; Sector 7	
			LBI R5, #$D0			
			MOVE $98, R5			
			LBI R1, #$34			
			MLH R1, R1			
			LBI R1, #$38			
			INC2 R2, R0			
			RET R1			; CALL $3438, R2
						
			MOVE R4, R3			
			ADD R4, #$04		; IOCB_BA	
			MOVE R4, (R4)			
			ADD R4, #$48		; Extended Arrangement Ind.	
			MOVB R5, (R4)			
			LBI R1, #$40			
			SNE R5, R1			
			BRA $251C		; Blank, OK	
						
			LBI R6, #$30		; Error 25	
			BRA $257E		; Error exit	
						
						
			LBI R1, #$29			
			MLH R1, R1			
			LBI R1, #$D2			
			INC2 R2, R0			
			RET R1			; CALL $29D2, R2
						
			MOVE R4, R3			
			ADD R4, #$08		; IOCB_CI1	
			MOVE R5, (R4)		; Size of new file in kbytes	
			MHL R1, R5			
			OR R5, R1			
			SNZ R5			
			BRA $24A4		; Zero -> finished, return	
						
			LBI R1, #$2C			
			MLH R1, R1			
			LBI R1, #$26			
			INC2 R2, R0			
			RET R1			; CALL $2C26, R2
						
			LBI R1, #$33			
			MLH R1, R1			
			LBI R1, #$16			
			INC2 R2, R0			
			RET R1			; CALL $3316, R2
						
			MOVE R8, $A0			
			CLR R5, #$F0			
			LBI R1, #$03			
			SNE R5, R1			
			BRA $2562		; $10(R0)	
						
			LBI R1, #$02			
			SNE R5, R1			
			BRA $2560		; $08(R0)	
						
			LBI R1, #$01			
			SE R5, R1			
			ADD R8, #$04			
			ADD R8, #$02			
			ADD R8, #$01			
			ADD R8, #$01			
			MOVE R4, R3			
			ADD R4, #$0E			
			MOVE R5, (R4)			
			MOVE $8E, R5			
			SUB R4, #$0A			
			MOVE R5, (R4)++			
			MOVE $EE, R5			
			MOVE R5, (R4)			
			LBI R1, #$F0			
			MHL R5, R5			
			SNBC R5, R1			
			BRA $2588		; $0C(R0)	
						
			LBI R6, #$0E			
			LBI R1, #$3E			
			MLH R1, R1			
			LBI R1, #$FA			
			INC2 R2, R0			
			RET R1			
						
			LBI R1, #$33			
			MLH R1, R1			
			LBI R1, #$16			
			INC2 R2, R0			
			RET R1			
						
			MHL R7, R5			
			LBI R1, #$40			
			SNE R7, R1			
			CLR R5, #$80			
			CLR R5, #$0F			
			STAT R5, $0			
			ADD R5, #$01			
			MLH R1, R5			
			LBI R1, #$01			
			MOVE R4, R3			
			ADD R4, #$08			
			MOVE R5, (R4)+			
			MOVE R4, (R4)			
			MOVE (R4), R1			
			ADD R4, #$06			
			MOVE R7, (R4)			
			MOVE $F6, R7			
			MOVE R7, $A0			
			ADD R7, R8			
			SUB R5, #$01			
			MHL R1, R5			
			OR R1, R5			
			SZ R1			
			BRA $25B6		; -> -$0C(R0)	
						
			MOVE $80, R7			
			MOVE R1, $90			
			CLR R1, #$14			
			MOVE $90, R1			
			MOVE R5, $F6			
			MHL R1, R5			
			SZ R1			
			BRA $25D8		; $06(R0)	
						
			LBI R1, #$13			
			SGT R5, R1			
			BRA $262E		; $56(R0)	
						
			LBI R1, #$33			
			MLH R1, R1			
			LBI R1, #$16			
			INC2 R2, R0			
			RET R1			
						
			LBI R1, #$D4			
			MHL R5, R5			
			SE R5, R1			
			BRA $262E		; $44(R0)	
						
			MOVE R5, $90			
			SET R5, #$10			
			MOVE $90, R5			
			MOVE R5, $F6			
			LBI R1, #$01			
			SBS R5, R1			
			BRA $260A		; $12(R0)	
						
			MOVE R5, $EE			
			ADD R5, #$80			
			MOVE $EE, R5			
			MOVE R5, $90			
			SET R5, #$04			
			MOVE $90, R5			
			BRA $2618		; $12(R0)	
						
			BRA $257E		; -> -$8A(R0)	
						
			BRA $2532		; -> -$D8(R0)	
						
			MOVE R5, $8E			
			LBI R1, #$01			
			SE R5, R1			
			BRA $262E		; $1C(R0)	
						
			MHL R1, R5			
			SZ R1			
			BRA $262E		; $16(R0)	
						
			MOVE R5, $F6			
			LBI R1, #$2F			
			MLH R1, R1			
			LBI R1, #$E8			
			INC2 R2, R0			
			RET R1			
						
			LBI R1, #$34			
			MLH R1, R1			
			LBI R1, #$38			
			INC2 R2, R0			
			RET R1			
						
			MOVE R5, $80			
			LBI R1, #$2A			
			MLH R1, R1			
			LBI R1, #$FE			
			INC2 R2, R0			
			RET R1			
						
			MOVE R13, $F0			
			LBI R1, #$2F			
			MLH R1, R1			
			LBI R1, #$12			
			INC2 R2, R0			
			RET R1			
						
			MOVE R4, $EE			
			ADD R4, #$1C			
			LBI R1, #$30			
			MLH R1, R1			
			LBI R1, #$72			
			INC2 R2, R0			
			RET R1			
						
			MOVE R4, $EE			
			ADD R4, #$1C			
			MOVE R7, R4			
			ADD R7, #$2E			
			LBI R8, #$05			
			MOVB R5, (R4)+			
			MOVB (R7)+, R5			
			SUB R8, #$01			
			SZ R8			
			BRA $265E		; -> -$0A(R0)	
						
			MOVE R13, $F2			
			LBI R1, #$2F			
			MLH R1, R1			
			LBI R1, #$12			
			INC2 R2, R0			
			RET R1			
						
			MOVE R4, $EE			
			ADD R4, #$22			
			LBI R1, #$30			
			MLH R1, R1			
			LBI R1, #$72			
			INC2 R2, R0			
			RET R1			
						
			LBI R1, #$2E			
			MLH R1, R1			
			LBI R1, #$30			
			INC2 R2, R0			
			RET R1			
						
			MOVE R5, $90			
			LBI R1, #$10			
			SBS R5, R1			
			BRA $26C2		; $2E(R0)	
						
			LBI R1, #$04			
			SBC R5, R1			
			BRA $26BE		; $24(R0)	
						
			SET R5, #$04			
			MOVE $90, R5			
			MOVE R5, $8E			
			SUB R5, #$01			
			MOVE $8E, R5			
			MHL R1, R5			
			OR R5, R1			
			SNZ R5			
			BRA $26C8		; $1C(R0)	
						
			MOVE R5, $EE			
			ADD R5, #$80			
			MOVE $EE, R5			
			MOVE R5, $F6			
			ADD R5, #$01			
			MOVE $F6, R5			
			BRA $262E		; -> -$8C(R0)	
						
			BRA $25CA		; -> -$F2(R0)	
						
			BRA $260A		; -> -$B4(R0)	
						
			CLR R5, #$04			
			MOVE $90, R5			
			MOVE R5, $8E			
			SUB R5, #$01			
			MOVE $8E, R5			
			MOVE R5, $F6			
			LBI R1, #$2F			
			MLH R1, R1			
			LBI R1, #$E8			
			INC2 R2, R0			
			RET R1			
						
			MOVE R1, $90			
			CLR R1, #$20			
			MOVE $90, R1			
			LBI R1, #$34			
			MLH R1, R1			
			LBI R1, #$9E			
			INC2 R2, R0			
			RET R1			
						
			SNZ R6			
			BRA $26EC		; $04(R0)	
						
			LBI R6, #$44			
			BRA $2606		; -> -$E6(R0)	
						
			MOVE R1, $8E			
			MHL R5, R1			
			OR R1, R5			
			SNZ R1			
			BRA $2608		; -> -$EE(R0)	
						
			MOVE R4, R3			
			ADD R4, #$04			
			MOVE R4, (R4)			
			MOVE $EE, R4			
			MOVE R5, $F6			
			ADD R5, #$01			
			MOVE $F6, R5			
			LBI R1, #$14			
			SNE R5, R1			
			BRA $26BA		; -> -$50(R0)	
						
			MOVE R5, $90			
			LBI R1, #$10			
			SBS R5, R1			
			BRA $262E		; -> -$E4(R0)	
						
			BRA $26BC		; -> -$58(R0)	
						
						
						
						
						
						
			; Get pointer to directory entry			
			MOVE R4, R3			
			ADD R4, #$0E		; IOCB_CI2	
			MOVE R4, (R4)			
			MOVE $8E, R4		; Save IOCB_CI2	
						
			; Get EOE			
			ADD R4, #$25			
			MOVB R5, (R4)+			
			MOVB R13, (R4)			
			MLH R13, R5			
						
			; Test if file size kept unchanged			
			MOVE R4, R3			
			ADD R4, #$0A		; IOCB_WA	
			MOVE R4, (R4)			
			ADD R4, #$04			
			MOVE R7, (R4)		; Total file size	
			SE R7, R13			
			BRA $2774		; Changed -> error 02	
			MHL R7, R7			
			SE R7, R5			
			BRA $2774		; Dito	
						
			; OK, file size is the same			
						
			; Get track, side and sector for EOE			
			LBI R1, #$2F			
			MLH R1, R1			
			LBI R1, #$12			
			INC2 R2, R0			
			RET R1			; CALL $2F12, R2
						
			; Put track, side and sector in binary into			
			; directory entry			
			MOVE R4, $8E		; Pointer to dir. entry	
			ADD R4, #$22		; EOE	
			LBI R1, #$30			
			MLH R1, R1			
			LBI R1, #$72			
			INC2 R2, R0			
			RET R1			
						
			; Get EOD			
			MOVE R4, $8E			
			ADD R4, #$4D		; EOD	
			MOVB R5, (R4)+			
			MOVB R13, (R4)			
			MLH R13, R5			
						
			MOVE R4, R3			
			ADD R4, #$0A		; IOCB_WA	
			MOVE R4, (R4)			
			ADD R4, #$04			
			MOVE R5, (R4)		; Total file size	
			ADD R5, #$01		;  plus 1	
			MHL R7, R13			
			MHL R8, R5			
			SLE R7, R8			
			BRA $2774		; EOD illegal	
			SLT R7, R8			
			SGT R13, R5			
			BRA $2782		; $0E(R0)	
						
			LBI R6, #$5E		; Error 02	
			LBI R1, #$3E			
			MLH R1, R1			
			LBI R1, #$FA			
			INC2 R2, R0			
			RET R1			; Error exit
						
						
			BRA $26F4		; -> -$8E(R0)	
						
						
			; Get track, side and sector for EOD			
			LBI R1, #$2F			
			MLH R1, R1			
			LBI R1, #$12			
			INC2 R2, R0			
			RET R1			
						
			; Put track, side and sector in binary into			
			; directory entry			
			MOVE R4, $8E		; Pointer to dir. entry	
			ADD R4, #$4A		; EOD	
			LBI R1, #$30			
			MLH R1, R1			
			LBI R1, #$72			
			INC2 R2, R0			
			RET R1			
						
			; Get file number			
			MOVE R4, R3			
			ADD R4, #$0A		; IOCB_WA	
			MOVE R4, (R4)			
			ADD R4, #$06			
			MOVE R15, (R4)		; File number	
						
			MOVE R4, $8E		; Pointer to dir. entry	
			ADD R4, #$2B		; Exchange Type Indicator	
			MOVB R5, (R4)			
			LBI R1, #$40			
			SE R5, R1			
			BRA $281C		; $6C(R0)	
						
			LBI R1, #$33			
			MLH R1, R1			
			LBI R1, #$16			
			INC2 R2, R0			
			RET R1			
						
			MOVE R4, $8E			
			LBI R1, #$0F			
			SBC R5, R1			
			BRA $27F4		; $32(R0)	
						
			MHL R8, R5			
			LBI R1, #$40			
			SE R8, R1			
			BRA $281C		; $52(R0)	
						
			LBI R1, #$80			
			SBC R5, R1			
			BRA $2816		; $46(R0)	
						
			MOVE R8, $8E			
			ADD R8, #$22			
			LBI R1, #$F7			
			MOVB R7, (R8)+			
			SE R7, R1			
			BRA $27E4		; $08(R0)	
						
			MOVB R7, (R8)			
			LBI R1, #$F3			
			SLE R7, R1			
			BRA $2816		; $32(R0)	
						
			LBI R7, #$00			
			LBI R8, #$30			
			ADD R4, #$50			
			MOVB (R4)+, R7			
			SUB R8, #$01			
			SZ R8			
			BRA $27EA		; -> -$08(R0)	
						
			BRA $281C		; $28(R0)	
						
			MOVE R7, $A0			
			LBI R7, #$47			
			MOVE R8, R15			
			SUB R7, R8			
			MHL R8, R7			
			MLH R7, R7			
			MHL R7, R8			
			SUB R8, R7			
			MHL R7, R7			
			MLH R7, R8			
			LBI R1, #$80			
			SNBSH R7, R1			
			BRA $2816		; $08(R0)	
						
			CLR R5, #$F0			
			LBI R1, #$01			
			LBI R7, #$C8			
			SE R5, R1			
			LBI R7, #$C5			
			ADD R4, #$2B			
			MOVB (R4), R7			
			MOVE R5, R15			
			LBI R1, #$2F			
			MLH R1, R1			
			LBI R1, #$E8			
			INC2 R2, R0			
			RET R1			
						
			MOVE R5, $90			
			CLR R5, #$20			
			MOVE $90, R5			
			LBI R1, #$34			
			MLH R1, R1			
			LBI R1, #$9E			
			INC2 R2, R0			
			RET R1			
						
			SNZ R6			
			BRA $2780		; -> -$BC(R0)	
						
			LBI R6, #$44			
			BRA $2776		; -> -$CA(R0)	
						
						
			; Scan			
						
			MOVE R5, $A0			
			MOVE $46, R5			
			MOVE R4, R3			
			ADD R4, #$0E			
			MOVE R4, (R4)			
			MOVB R1, (R4)+			
			MOVB R5, (R4)+			
			MLH R5, R1			
			MOVE $44, R5			
			OR R5, R1			
			SZ R5			
			BRA $285C		; $04(R0)	
						
			LBI R6, #$5E			
			BRA $28B8		; $5C(R0)	
						
			MOVB R5, (R4)+			
			SNZ R5			
			BRA $2858		; -> -$0A(R0)	
						
			MOVE $56, R5			
			MOVE $58, R4			
			LBI R1, #$33			
			MLH R1, R1			
			LBI R1, #$36			
			INC2 R2, R0			
			RET R1			
						
			MOVE R4, R3			
			ADD R4, #$08			
			MOVE R13, (R4)			
			LBI R1, #$2F			
			MLH R1, R1			
			LBI R1, #$12			
			INC2 R2, R0			
			RET R1			
						
			LBI R1, #$34			
			MLH R1, R1			
			LBI R1, #$38			
			INC2 R2, R0			
			RET R1			
						
			SZ R6			
			BRA $28E6		; $58(R0)	
						
			INC2 R2, R0			
			BRA $2944		; $B2(R0)	
						
			BRA $2908		; $74(R0)	
						
			BRA $2938		; $A2(R0)	
						
			MOVE R5, $46			
			SET R5, #$80			
			MOVE $46, R5			
			MOVE R5, $44			
			SUB R5, #$01			
			MOVE $44, R5			
			LBI R1, #$33			
			MLH R1, R1			
			LBI R1, #$2A			
			INC2 R2, R0			
			RET R1			
						
			MOVE R5, $44			
			MHL R1, R5			
			OR R5, R1			
			SZ R5			
			BRA $28C4		; $0E(R0)	
						
			LBI R6, #$28			
			LBI R1, #$3E			
			MLH R1, R1			
			LBI R1, #$FA			
			INC2 R2, R0			
			RET R1			
						
			BRA $283A		; -> -$8A(R0)	
						
			MOVE R4, R3			
			ADD R4, #$08			
			MOVE R7, (R4)+			
			MOVE R4, (R4)			
			ADD R4, #$02			
			MOVE R8, (R4)			
			SUB R7, R8			
			MHL R8, R7			
			MLH R7, R7			
			MHL R7, R8			
			SUB R8, R7			
			MHL R7, R7			
			MLH R7, R8			
			LBI R1, #$80			
			SBSH R7, R1			
			BRA $2942		; $5E(R0)	
						
			BRA $2870		; -> -$76(R0)	
						
			MOVE R5, $52			
			LBI R1, #$C6			
			SNE R5, R1			
			BRA $28F8		; $0A(R0)	
						
			LBI R1, #$C4			
			SNE R5, R1			
			BRA $28F8		; $04(R0)	
						
			LBI R6, #$18			
			BRA $28B8		; -> -$40(R0)	
						
			MOVE R4, R3			
			ADD R4, #$03			
			MOVB R5, (R4)			
			LBI R1, #$08			
			SBS R5, R1			
			BRA $28A2		; -> -$62(R0)	
						
			LBI R6, #$0A			
			BRA $28B8		; -> -$50(R0)	
						
			MOVE R5, $46			
			LBI R1, #$80			
			SBC R5, R1			
			BRA $2916		; $06(R0)	
						
			MOVE R5, $A0			
			MOVE $44, R5			
			BRA $28A2		; -> -$74(R0)	
						
			MOVE R4, R3			
			ADD R4, #$08			
			MOVE R13, (R4)			
			SUB R13, #$01			
			MOVE (R4), R13			
			LBI R1, #$2F			
			MLH R1, R1			
			LBI R1, #$12			
			INC2 R2, R0			
			RET R1			
						
			LBI R1, #$34			
			MLH R1, R1			
			LBI R1, #$38			
			INC2 R2, R0			
			RET R1			
						
			SZ R6			
			BRA $2916		; -> -$22(R0)	
						
			LBI R1, #$33			
			MLH R1, R1			
			LBI R1, #$2A			
			INC2 R2, R0			
			RET R1			
						
			BRA $28C2		; -> -$82(R0)	
						
			MOVE R15, $56			
			MOVE R4, R3			
			ADD R4, #$04			
			MOVE R4, (R4)			
			MOVE R7, $58			
			MOVB R5, (R4)+			
			MOVB R8, (R7)+			
			SE R5, R8			
			BRA $2960		; $0A(R0)	
						
			SUB R15, #$01			
			SZ R15			
			BRA $294E		; -> -$0E(R0)	
						
			ADD R2, #$02			
			BRA $2964		; $04(R0)	
						
			SLT R8, R5			
			ADD R2, #$04			
			RET R2			
						
			MOVE R7, R3			
			ADD R7, #$08			
			MOVE R7, (R7)			
			MOVE R4, $EE			
			ADD R4, #$05			
			LBI R15, #$11			
			MOVB R8, (R7)+			
			MOVB R5, (R4)+			
			SE R5, R8			
			BRA $299A		; $20(R0)	
						
			LBI R1, #$40			
			SNE R5, R1			
			BRA $2986		; $06(R0)	
						
			SUB R15, #$01			
			SZ R15			
			BRA $2972		; -> -$14(R0)	
						
			MOVE R5, $90			
			LBI R1, #$02			
			SBS R5, R1			
			BRA $2992		; $04(R0)	
						
			LBI R6, #$12			
			BRA $2A08		; $76(R0)	
						
			SET R5, #$02			
			MOVE $90, R5			
			MOVE R5, $F6			
			MOVE $EA, R5			
			RET R2			
						
						
						
						
						
						
						
						
						
			MOVE R4, R3			
			ADD R4, #$06		; IOCB_BS -> R7	
			MOVE R7, (R4)++			
						
			MOVE R4, (R4)		; IOCB_WA -> R4	
			ADD R4, #$08			
			MOVB R15, (R4)		; Physical record size	
						
			; Calculate number of sectors from buffer size,			
			; result in R7			
						
			ADD R15, #$07			
			MOVE R5, $A0			
			LBI R10, #$01			
			SBC R7, R10			
			LBI R10, #$FF			
			SHR R7			
			MHL R5, R7			
			SHR R5			
			MLH R7, R5			
			SUB R15, #$01			
			SZ R15			
			BRA $29AE		; -> -$12(R0)	
						
			SNS R10			
			ADD R7, #$01			
			MOVE $44, R7		; R2L2	
						
			MHL R1, R7			
			OR R1, R7			
			SZ R1			
			RET R2			; Return
						
			; Error, number of sectors equal 0			
						
			LBI R6, #$5E		; Error 02	
			BRA $2A08		; Error exit	
						
						
						
						
						
			MOVE $E8, R2		; Save R2	
						
			MOVE R4, R3			
			ADD R4, #$0E		; IOCB_CI2	
			MOVE R5, (R4)--			
			MOVE $8E, R5		; Number of files to mark	
						
			MOVE R4, (R4)		; IOCB_WA	
			ADD R4, #$06			
			MOVE R5, (R4)			
			MOVE $F6, R5		; Start with first file number	
						
			; Get track, side and sector of current file entry			
			MOVE R5, $F6			
			LBI R1, #$2F			
			MLH R1, R1			
			LBI R1, #$E8			
			INC2 R2, R0			
			RET R1			; CALL $2FE8, R2
						
			; Read sector			
			LBI R1, #$34			
			MLH R1, R1			
			LBI R1, #$38			
			INC2 R2, R0			
			RET R1			; CALL $3438, R2
						
			SNZ R6			
			BRA $2A12		; No error	
						
			; Error or other flags returned			
			MOVE R5, $52		; R9L2	
			LBI R1, #$C4			
			SNE R5, R1			
			BRA $2ACC		; Deleted header record	
						
			LBI R6, #$18		; Error 37	
			LBI R1, #$3E			
			MLH R1, R1			
			LBI R1, #$FA			
			INC2 R2, R0			
			RET R1			
						
						
			MOVE R5, $90			
			LBI R1, #$10			
			SBS R5, R1			
			BRA $2A2A		; FM	
						
			MOVE R5, $F6			
			LBI R1, #$01		; Odd file number ?	
			SBC R5, R1			
			BRA $2A8A		; Yes	
						
			MOVE R5, $52		; R9L2	
			LBI R1, #$C4		; Deleted header record ?	
			SNE R5, R1			
			BRA $2A9E		; Yes	
						
			; Mark header record as deleted			
			MOVE R4, R3			
			ADD R4, #$04		; IOCB_BA	
			MOVE R4, (R4)			
						
			LBI R1, #$2E			
			MLH R1, R1			
			LBI R1, #$00			
			INC2 R2, R0			
			RET R1			; CALL $2E00, R2
						
			MOVE R8, $90			
			LBI R1, #$10			
			SBS R8, R1			
			BRA $2A6E		; FM	
						
			MOVE R5, $F6			
			LBI R1, #$01			
			SBC R5, R1			
			BRA $2A58		; $0E(R0)	
						
			MOVE R5, $8E			
			LBI R1, #$01			
			SE R5, R1			
			BRA $2AAE		; $5C(R0)	
						
			MHL R1, R5			
			SZ R1			
			BRA $2AAE		; $56(R0)	
						
			MOVE R4, R3			
			ADD R4, #$04		; IOCB_BA	
			MOVE R4, (R4)			
			LBI R7, #$C4			
			MOVB R5, (R4)			
			SE R5, R7			
			BRA $2A74		; Entry not deleted	
						
			ADD R4, #$80		; Second dir. entry	
			MOVB R5, (R4)			
			SE R5, R7			
			BRA $2A74		; Entry not deleted	
						
			MOVE R8, $90			
			SET R8, #$20		; Mark sector deleted (DDAM)	
			BRA $2A76			
						
			CLR R8, #$20		; Mark sector normal (NDAM)	
						
			MOVE $90, R8			
						
			LBI R1, #$34			
			MLH R1, R1			
			LBI R1, #$9E			
			INC2 R2, R0			
			RET R1			; CALL $349E, R2
						
			SNZ R6			
			BRA $2AE8		; $62(R0)	
						
			LBI R6, #$44			
			BRA $2A08		; -> -$82(R0)	
						
			MOVE R4, R3			
			ADD R4, #$04			
			MOVE R4, (R4)			
			ADD R4, #$80			
			MOVB R5, (R4)			
			LBI R1, #$C4			
			SE R5, R1			
			BRA $2A30		; -> -$6A(R0)	
			BRA $2AE8		; $4C(R0)	
						
			BRA $29E4		; -> -$BA(R0)	
						
			MOVE R5, $8E		; Number of files to mark	
			SUB R5, #$01		; Decrement by one	
			MOVE $8E, R5		; and store	
			MHL R1, R5			
			OR R5, R1			
			SZ R5			
			BRA $2AB4		; $08(R0)	
			BRA $2AF4		; Zero, finished	
						
			MOVE R5, $8E			
			SUB R5, #$01			
			MOVE $8E, R5			
						
			MOVE R5, $F6		; Current file number	
			ADD R5, #$01		; Increment by one	
			MOVE $F6, R5		; and store	
			MOVE R4, R3			
			ADD R4, #$04		; IOCB_BA	
			MOVE R4, (R4)			
			ADD R4, #$80		; Second dir. entry	
			MOVB R5, (R4)			
			LBI R1, #$C4			
			SE R5, R1			
			BRA $2A30		; Not a deleted header record	
			BRA $2A6E		; Deleted header record	
						
			MOVE R5, $90			
			LBI R1, #$10			
			SBS R5, R1			
			BRA $2AE8		; $14(R0)	
						
			MOVE R5, $8E			
			SUB R5, #$01			
			MOVE $8E, R5			
			MHL R1, R5			
			OR R5, R1			
			SNZ R5			
			BRA $2AF4		; $12(R0)	
						
			MOVE R5, $F6			
			ADD R5, #$01			
			MOVE $F6, R5			
			MOVE R5, $8E			
			SUB R5, #$01			
			MOVE $8E, R5			
			MHL R1, R5			
			OR R5, R1			
			SNZ R5			
						
			JMP ($00E8)		; Return	
						
						
			MOVE R5, $F6			
			ADD R5, #$01			
			MOVE $F6, R5			
			BRA $2A9C		; -> -$62(R0)	
						
			MOVE $86, R2			
			MOVE R15, $A0			
			MOVE R9, $EC			
			MOVE R10, $EA			
			MOVE R7, R5			
			MOVE R8, R9			
			ADD R7, R8			
			MHL R8, R7			
			ADDH R8, R8			
			MLH R7, R8			
			MOVE R8, R10			
			SUB R8, R7			
			MHL R7, R8			
			MLH R8, R8			
			MHL R8, R7			
			SUB R7, R8			
			MHL R8, R8			
			MLH R8, R7			
			LBI R1, #$80			
			SNBSH R8, R1			
			BRA $2BBA		; $92(R0)	
						
			MOVE R8, R9			
			MHL R1, R8			
			ROR3 R8			
			CLR R8, #$E0			
			ROR3 R1			
			CLR R1, #$1F			
			OR R8, R1			
			MHL R1, R8			
			ROR3 R1			
			CLR R1, #$E0			
			MLH R8, R1			
			MOVE R7, R9			
			CLR R7, #$F8			
			MOVE R4, R3			
			ADD R4, #$04			
			MOVE R4, (R4)			
			ADD R4, #$100			
			ADD R4, R8			
			MHL R8, R4			
			ADDH R8, R8			
			MLH R4, R8			
			MOVB R8, (R4)			
			SS R8			
			BRA $2B68		; $10(R0)	
						
			ADD R15, #$08			
			SUB R15, R7			
			ADD R9, R15			
			MHL R15, R9			
			ADDH R15, R15			
			MLH R9, R15			
			MOVE $EC, R9			
			BRA $2B00		; -> -$68(R0)	
						
			SZ R8			
			BRA $2B74		; $08(R0)	
						
			ADD R15, #$08			
			SUB R15, R7			
			LBI R7, #$07			
			BRA $2B78		; $04(R0)	
						
			INC2 R2, R0			
			BRA $2C06		; $8E(R0)	
						
			MOVE R13, R15			
			MOVE R1, R5			
			SUB R13, R1			
			MHL R1, R13			
			MLH R13, R13			
			MHL R13, R1			
			SUB R1, R13			
			MHL R13, R13			
			MLH R13, R1			
			LBI R1, #$80			
			SBSH R13, R1			
			BRA $2BA0		; $10(R0)	
						
			LBI R1, #$07			
			SNE R7, R1			
			BRA $2B9A		; $04(R0)	
						
			ADD R7, #$01			
			BRA $2B74		; -> -$26(R0)	
						
			MOVE R7, $A0			
			ADD R4, #$01			
			BRA $2B52		; -> -$4E(R0)	
						
			MOVE R15, R5			
			MOVE R1, $F4			
			ADD R1, #$01			
			MOVE $F4, R1			
			MOVE $F0, R9			
			ADD R9, R15			
			MHL R15, R9			
			ADDH R15, R15			
			MLH R9, R15			
			MOVE $EC, R9			
			SUB R9, #$01			
			MOVE $F2, R9			
			JMP ($0086)			
						
			MOVE R5, $F4			
			SNZ R5			
			BRA $2BFA		; $3A(R0)	
						
			MOVE R5, $90			
			LBI R1, #$04			
			SBS R5, R1			
			BRA $2BFA		; $32(R0)	
						
			MOVE R4, $EE			
			LBI R1, #$C4			
			MOVB (R4), R1			
			MOVE R5, $F6			
			LBI R1, #$2F			
			MLH R1, R1			
			LBI R1, #$E8			
			INC2 R2, R0			
			RET R1			
						
			MOVE R1, $90			
			CLR R1, #$20			
			MOVE $90, R1			
			LBI R1, #$34			
			MLH R1, R1			
			LBI R1, #$9E			
			INC2 R2, R0			
			RET R1			
						
			SNZ R6			
			BRA $2BFA		; $0C(R0)	
						
			LBI R6, #$44			
			LBI R1, #$3E			
			MLH R1, R1			
			LBI R1, #$FA			
			INC2 R2, R0			
			RET R1			
						
			MOVE R4, R3			
			ADD R4, #$0E			
			MOVE R5, $F4			
			MOVE (R4), R5			
			LBI R6, #$0E			
			BRA $2BF0		; -> -$16(R0)	
						
			ADD R15, #$01			
			LBI R1, #$07			
			SUB R1, R7			
			LBI R13, #$80			
			ADD R1, R1			
			ADD R0, R1			
			ROR R13			
			ROR R13			
			ROR R13			
			ROR R13			
			ROR R13			
			ROR R13			
			ROR R13			
			SBC R8, R13			
			BRA $2B5C		; -> -$C8(R0)	
						
			RET R2			
						
						
						
						
						
			MOVE $E8, R2		; Save R2	
						
			MOVE R4, R3			
			ADD R4, #$04		; IOCB_BA	
			MOVE R4, (R4)			
			ADD R4, #$100		; ??	
			LBI R15, #$FF			
			MOVE R5, $A0			
			MOVE (R4)+, R5			
			SUB R15, #$01			
			SZ R15			
			BRA $2C34		; -> -$08(R0)	
						
			; Get number of sectors per cylinder			
			LBI R1, #$31			
			MLH R1, R1			
			LBI R1, #$7E			
			INC2 R2, R0			
			RET R1			; CALL $317E, R2
						
			; Get drive status word			
			LBI R1, #$33			
			MLH R1, R1			
			LBI R1, #$16			
			INC2 R2, R0			
			RET R1			; CALL $3316, R2
						
			MHL R7, R5			
			LBI R1, #$40			
			SNE R7, R1			
			CLR R5, #$80			
			CLR R5, #$0F			
			STAT R5, $0			
			ADD R5, #$01			
			MOVE R4, R3			
			ADD R4, #$0A			
			MOVE R4, (R4)			
			MLH R7, R5			
			LBI R7, #$01			
			MOVE (R4), R7			
			MOVE R8, $9A			
			LBI R15, #$4A			
			MOVE R6, $A0			
			MOVE R7, $A0			
			SUB R5, #$01			
			SUB R15, R5			
			ADD R6, R8			
			SUB R15, #$01			
			SZ R15			
			BRA $2C76		; -> -$08(R0)	
						
			MOVE $EA, R6			
			MOVE $EC, R7			
			MOVE R7, $A0			
			MOVE $F4, R7			
			LBI R7, #$01			
			MOVE $F6, R7			
			LBI R1, #$31			
			MLH R1, R1			
			LBI R1, #$BA			
			INC2 R2, R0			
			RET R1			
						
			MOVE $8E, R5			
			MOVE R4, R3			
			ADD R4, #$04			
			MOVE R7, (R4)			
			MOVE $EE, R7			
			MOVE R5, $F6			
			LBI R1, #$2F			
			MLH R1, R1			
			LBI R1, #$E8			
			INC2 R2, R0			
			RET R1			
						
			LBI R1, #$34			
			MLH R1, R1			
			LBI R1, #$38			
			INC2 R2, R0			
			RET R1			
						
			SNZ R6			
			BRA $2CCE		; $16(R0)	
						
			MOVE R5, $90			
			LBI R1, #$10			
			SBS R5, R1			
			BRA $2D7E		; $BE(R0)	
						
			MOVE R5, $8E			
			SUB R5, #$01			
			MOVE $8E, R5			
			MOVE R5, $F6			
			ADD R5, #$01			
			MOVE $F6, R5			
			BRA $2D7E		; $B0(R0)	
						
			LBI R1, #$31			
			MLH R1, R1			
			LBI R1, #$7E			
			INC2 R2, R0			
			RET R1			
						
			MOVE R5, $90			
			LBI R1, #$10			
			SBS R5, R1			
			BRA $2CEA		; $0A(R0)	
						
			MOVE R4, $EE			
			MOVB R5, (R4)			
			LBI R1, #$C4			
			SNE R5, R1			
			BRA $2D7E		; $94(R0)	
						
			MOVE R4, $EE			
			ADD R4, #$1C			
			LBI R1, #$32			
			MLH R1, R1			
			LBI R1, #$86			
			INC2 R2, R0			
			RET R1			
						
			MOVE R4, $EE			
			ADD R4, #$22			
			LBI R1, #$32			
			MLH R1, R1			
			LBI R1, #$86			
			INC2 R2, R0			
			RET R1			
						
			MOVE R4, $EE			
			ADD R4, #$1F			
			MOVB R1, (R4)+			
			MOVB R7, (R4)+			
			MLH R7, R1			
			ADD R4, #$04			
			MOVB R1, (R4)+			
			MOVB R8, (R4)			
			MLH R8, R1			
			MOVE R15, R8			
			MOVE R1, R7			
			SUB R15, R1			
			MHL R1, R15			
			MLH R15, R15			
			MHL R15, R1			
			SUB R1, R15			
			MHL R15, R15			
			MLH R15, R1			
			MOVE R5, $EA			
			SUB R5, R8			
			MHL R8, R5			
			MLH R5, R5			
			MHL R5, R8			
			SUB R8, R5			
			MHL R5, R5			
			MLH R5, R8			
			LBI R8, #$80			
			SNBSH R5, R8			
			BRA $2D44		; $04(R0)	
						
			SBSH R15, R8			
			BRA $2D52		; $0E(R0)	
						
			LBI R6, #$16			
			LBI R1, #$3E			
			MLH R1, R1			
			LBI R1, #$FA			
			INC2 R2, R0			
			RET R1			
						
			BRA $2C96		; -> -$BC(R0)	
						
			ADD R15, #$01			
			LBI R9, #$03			
			MOVE R8, R7			
			MOVE R5, $A0			
			MHL R5, R8			
			SHR R8			
			SHR R5			
			MLH R8, R5			
			SUB R9, #$01			
			SZ R9			
			BRA $2D5C		; -> -$0C(R0)	
						
			MOVE R4, R3			
			ADD R4, #$04			
			MOVE R4, (R4)			
			ADD R4, #$100			
			ADD R4, R8			
			MHL R8, R4			
			ADDH R8, R8			
			MLH R4, R8			
			CLR R7, #$F8			
			INC2 R2, R0			
			BRA $2DAA		; $2C(R0)	
						
			MOVE R5, $8E			
			SUB R5, #$01			
			MOVE $8E, R5			
			MHL R1, R5			
			OR R5, R1			
			SNZ R5			
			JMP ($00E8)			
						
			MOVE R5, $F6			
			ADD R5, #$01			
			MOVE $F6, R5			
			MOVE R7, $90			
			LBI R1, #$10			
			SBS R7, R1			
			BRA $2D50		; -> -$4A(R0)	
						
			MOVE R5, $F6			
			LBI R1, #$01			
			SBS R5, R1			
			BRA $2D50		; -> -$52(R0)	
						
			MOVE R5, $EE			
			ADD R5, #$80			
			MOVE $EE, R5			
			BRA $2CE0		; -> -$CA(R0)	
						
			LBI R1, #$07			
			SUB R1, R7			
			MOVE R13, $A0			
			LBI R13, #$FF			
			ADD R1, R1			
			ADD R0, R1			
			SHR R13			
			SHR R13			
			SHR R13			
			SHR R13			
			SHR R13			
			SHR R13			
			SHR R13			
			ADD R15, R7			
			SUB R15, #$08			
			LBI R1, #$80			
			SNBSH R15, R1			
			BRA $2DD8		; $0A(R0)	
						
			MOVB R1, (R4)			
			OR R1, R13			
			MOVB (R4)+, R1			
			LBI R7, #$00			
			BRA $2DAA		; -> -$2E(R0)	
						
			LBI R1, #$FF			
			XOR R15, R1			
			ADD R15, #$01			
			MLH R1, R1			
			LBI R1, #$00			
			ADD R15, R15			
			ADD R0, R15			
			SHR R1			
			SHR R1			
			SHR R1			
			SHR R1			
			SHR R1			
			SHR R1			
			SHR R1			
			SHR R1			
			AND R13, R1			
			MOVB R1, (R4)			
			OR R1, R13			
			MOVB (R4), R1			
			RET R2			
						
						
						
						
						
						
			ADD R4, #$2A		; Write Protect Indicator	
			MOVB R5, (R4)			
			LBI R1, #$40			
			SE R5, R1			
			BRA $2E24		; File is write protected	
						
			ADD R4, #$18		; Expiration Date	
			LBI R15, #$06		; Length of field	
			MOVB R5, (R4)+			
			LBI R1, #$40			
			SE R5, R1			
			BRA $2E24		; File not expired	
			SUB R15, #$01			
			SZ R15			
			BRA $2E0E		; -> -$0E(R0)	
						
			; Mark header record as deleted			
			; (HDR1 -> DDR1)			
			SUB R4, #$48		; Header Label ID	
			LBI R1, #$C4			
			MOVB (R4), R1			
						
			RET R2			; Return
						
						
			; Put number of failed file into IOCB			
			MOVE R4, R3			
			ADD R4, #$0E		; IOCB_CI2	
			MOVE R5, $F6			
			MOVE (R4), R5			
						
			LBI R6, #$14		; Error 39	
			BRA $2D46		; Error exit	
						
						
						
						
						
			MOVE $82, R2			
			MOVE R4, $EE			
			LBI R1, #'H'			
			MOVB (R4)+, R1			
			LBI R1, #'D'			
			MOVB (R4)+, R1			
			LBI R1, #'R'			
			MOVB (R4)+, R1			
			LBI R1, #'1'			
			MOVB (R4)+, R1			
			LBI R1, #' '			
			MOVB (R4)+, R1			
			LBI R1, #'S'			
			MOVB (R4)+, R1			
			LBI R1, #'Y'			
			MOVB (R4)+, R1			
			LBI R1, #'S'			
			MOVB (R4)+, R1			
			MOVE R5, $F6			
			MOVE R7, $A0			
			LBI R8, #$03			
			MLH R8, R8			
			LBI R8, #$E8			
			SUB R5, R8			
			MHL R8, R5			
			MLH R5, R5			
			MHL R5, R8			
			SUB R8, R5			
			MHL R5, R5			
			MLH R5, R8			
			LBI R1, #$80			
			SBSH R5, R1			
			BRA $2E84		; $12(R0)	
						
			LBI R8, #$03			
			MLH R8, R8			
			LBI R8, #$E8			
			ADD R5, R8			
			MHL R8, R5			
			ADDH R8, R8			
			MLH R5, R8			
			LBI R1, #$F0			
			BRA $2E86		; $02(R0)	
						
			LBI R1, #$F1			
			MOVB (R4)+, R1			
			SUB R5, #$64			
			LBI R1, #$80			
			SNBSH R5, R1			
			BRA $2E94		; $04(R0)	
						
			ADD R7, #$01			
			BRA $2E88		; -> -$0C(R0)	
						
			SET R7, #$F0			
			MOVB (R4)+, R7			
			ADD R5, #$64			
			LBI R1, #$30			
			MLH R1, R1			
			LBI R1, #$92			
			INC2 R2, R0			
			RET R1			
						
			MHL R7, R5			
			MOVB (R4)+, R7			
			MOVB (R4)+, R5			
			LBI R7, #$40			
			LBI R8, #$0C			
			MOVB (R4)+, R7			
			SUB R8, #$01			
			SZ R8			
			BRA $2EAE		; -> -$08(R0)	
						
			LBI R1, #$F1			
			MOVB (R4)+, R1			
			LBI R1, #$F2			
			MOVB (R4)+, R1			
			LBI R1, #$F8			
			MOVB (R4)+, R1			
			LBI R1, #$40			
			MOVB (R4)+, R1			
			LBI R1, #$33			
			MLH R1, R1			
			LBI R1, #$16			
			INC2 R2, R0			
			RET R1			
						
			MOVE R4, $EE			
			ADD R4, #$21			
			SET R5, #$F0			
			LBI R1, #$F0			
			SNE R5, R1			
			LBI R5, #$40			
			MOVB (R4), R5			
			ADD R4, #$06			
			LBI R1, #$40			
			MOVB (R4)+, R1			
			MOVB (R4)+, R1			
			MOVB (R4)+, R1			
			MOVB (R4)+, R1			
			MHL R5, R5			
			LBI R1, #$C5			
			MOVB (R4)+, R1			
			LBI R8, #$1E			
			LBI R7, #$40			
			MOVB (R4)+, R7			
			SUB R8, #$01			
			SZ R8			
			BRA $2EF4		; -> -$08(R0)	
						
			ADD R4, #$05			
			MOVB (R4)+, R7			
			LBI R1, #$40			
			SNE R5, R1			
			LBI R7, #$00			
			LBI R8, #$30			
			MOVB (R4)+, R7			
			SUB R8, #$01			
			SZ R8			
			BRA $2F08		; -> -$08(R0)	
						
			JMP ($0082)			
						
						
						
						
						
						
						
						
						
			MOVE $86, R2		; Save R2	
						
			; Get sectors per track (-> R5)			
			LBI R1, #$31			
			MLH R1, R1			
			LBI R1, #$98			
			INC2 R2, R0			
			RET R1			; CALL $3198, R2
						
			; Value *8 gives no. of tries until sector found			
			MOVE R1, R5			
			SWAP R1			
			ROR R1			
			MOVE $98, R1			
						
			MOVE R7, $A0			
						
			MOVE R4, R3			
			ADD R4, #$0A		; IOCB_WA	
			MOVE R4, (R4)			
			ADD R4, #$01			
			MOVB R8, (R4)		; Get sector and side from WA	
			CLR R8, #$80		; Clear side bit	
						
			MOVE R15, R13		; File offset in no. of sectors	
			MOVE R1, R5		; Sectors per track	
			SUB R1, R8		; Sectors remaining on track	
			SUB R15, R1			
						
			; Test if offset on current track			
			LBI R8, #$80			
			INC2 R2, R0			
			BRA $2F60			
						
			; Desired sector is not on current track			
			SWAP R5			
			ROR R5			
						
			SUB R15, R5			
			SNBSH R15, R8			
			BRA $2F58		; $0C(R0)	
			MHL R1, R15			
			OR R1, R15			
			SNZ R1			
			BRA $2F58		; $04(R0)	
						
			ADD R7, #$08			
			BRA $2F46		; Loop ^	
						
			ADD R15, R5			
			ROR3 R5			
			MOVE R2, R0			
			SUB R15, R5		; Loop v	
						
			; R8 is $80			
			SNBSH R15, R8			
			BRA $2F70		; $0C(R0)	
						
			MHL R1, R15			
			OR R1, R15			
			SNZ R1			
			BRA $2F70		; $04(R0)	
						
			ADD R7, #$01			
			RET R2			; Loop ^
						
						
			ADD R15, R5			
			MOVE $9E, R15		; Sector	
			SZ R7			
			BRA $2F90		; $18(R0)	
						
			MOVE R4, R3			
			ADD R4, #$0A			
			MOVE R4, (R4)			
			MOVE R5, (R4)			
			MHL R7, R5			
			MOVE $9A, R7		; Cylinder	
			MOVE R7, $A0			
			LBI R1, #$80			
			SBC R5, R1			
			LBI R7, #$01			
			MOVE $9C, R7		; Side	
			BRA $2F96		; $06(R0)	
						
			MOVE $9A, R7			
			INC2 R2, R0			
			BRA $2F98		; $02(R0)	
						
			JMP ($0086)		; Return	
						
						
						
						
						
			MOVE $84, R2			
			LBI R1, #$33			
			MLH R1, R1			
			LBI R1, #$16			
			INC2 R2, R0			
			RET R1			
						
			MOVE R4, R3			
			ADD R4, #$0A			
			MOVE R4, (R4)			
			MHL R5, R5			
			LBI R1, #$40			
			SE R5, R1			
			BRA $2FC0		; $0E(R0)	
						
			MOVE R8, $A0			
			MOVE $9C, R8			
			MOVE R5, (R4)			
			MHL R8, R5			
			MOVE R5, $9A			
			ADD R8, R5			
			BRA $2FE4		; $24(R0)	
						
			MOVE R7, $A0			
			MOVE R5, (R4)			
			LBI R1, #$80			
			SBC R5, R1			
			LBI R7, #$01			
			MOVE R8, $9A			
			LBI R1, #$01			
			SBS R8, R1			
			BRA $2FDA		; $08(R0)	
						
			ADD R7, #$01			
			CLR R7, #$02			
			SNZ R7			
			ADD R8, #$01			
			MOVE $9C, R7			
			SHR R8			
			MOVE R5, (R4)			
			MHL R7, R5			
			ADD R8, R7			
			MOVE $9A, R8			
						
			JMP ($0084)			
						
						
						
						
						
						
						
			MOVE $84, R2		; Save R2	
			MOVE R15, R5		; File number	
						
			LBI R1, #$31			
			MLH R1, R1			
			LBI R1, #$BA			
			INC2 R2, R0			
			RET R1			; Get number of dir. entries
						
			MOVE R7, R5		; Max. dir entry number	
			MOVE R8, R15		; File number	
			SUB R7, R8			
			MHL R8, R7			
			MLH R7, R7			
			MHL R7, R8			
			SUB R8, R7			
			MHL R7, R7			
			MLH R7, R8		; R7 <- R7 - R8	
			LBI R1, #$80			
			SBSH R7, R1		; File number > Max dir. entry?	
			BRA $301A		; No, ok	
						
			LBI R6, #$1A		; Error 36	
			LBI R1, #$3E			
			MLH R1, R1			
			LBI R1, #$FA			
			INC2 R2, R0			
			RET R1			; Error exit
						
			MOVE R7, $A0		; Start with side 0	
			MOVE R8, $A0		; and track 0	
						
			MHL R1, R15			
			SZ R1			
			BRA $302E			
			LBI R1, #$13			
			SLE R15, R1		; File number <= 19	
			BRA $302E		; No	
						
			ADD R15, #$07		; Add 7 sectors for dir. entry	
			BRA $3066			
						
			; File number > 19 means dir. entry is not			
			; on track 0 side 0			
						
			MHL R1, R5			
			SZ R1			
			BRA $3040		; $0C(R0)	
			LBI R1, #$2D			
			SE R5, R1		; Max. 45 entries ?	
			BRA $3040		; No	
						
			LBI R7, #$01		; Side 1	
			SUB R15, #$13		; Sector number	
			BRA $3066			
						
			; More than max. 45 entries on diskette,			
			; so there are 2 entries per sector (Diskette 2D)			
						
			SUB R15, #$12			
			SHR R15			; Rel. sector with dir. entry
			MOVE R1, $A0			
			MHL R1, R15			
			SHR R1			
			MLH R15, R1			
			LBI R1, #$01			
			XOR R7, R1			
			SNZ R7			
			ADD R8, #$01			
			SUB R15, #$1A		; 26 sectors per dir. track	
			MHL R1, R15			
			OR R1, R15			
			SNZ R1			
			BRA $3064		; Zero -> done	
			LBI R1, #$80			
			SBSH R15, R1		; Negative -> done	
			BRA $304C		; Loop	
						
			ADD R15, #$1A		; Add 26 sectors (correction)	
						
			; Track, side and sector of dir. entry known			
						
			MOVE $9C, R7		; Side	
			MOVE $9A, R8		; Track	
			MOVE $9E, R15		; Sector	
			LBI R1, #$D0		; Number of retries	
			MOVE $98, R1			
						
			JMP ($0084)		; Return to caller	
						
						
						
						
						
						
			MOVE $82, R2		; Save R2	
						
			MOVE R5, $9A		; Track	
			INC2 R2, R0			
			BRA $3092		; $18(R0)	
			MOVE (R4)+, R5			
						
			MOVE R5, $9C		; Side	
			INC2 R2, R0			
			BRA $3092		; $10(R0)	
			MOVB (R4)++, R5			
						
			MOVE R5, $9E		; Sector	
			INC2 R2, R0			
			BRA $3092		; $08(R0)	
			MOVB (R4)-, R5			
						
			MHL R5, R5			
			MOVB (R4), R5			
						
			JMP ($0082)		; Return	
						
						
						
						
						
						
			MOVE R8, $A0			
						
			SUB R5, #$0A			
			LBI R1, #$80			
			SNBSH R5, R1			
			BRA $30A0		; $04(R0)	
			ADD R8, #$01			
			BRA $3094		; Loop	
						
			SET R8, #$F0			
			ADD R5, #$0A			
			SET R5, #$F0			
			MLH R5, R8			
						
			RET R2			
						
						
						
						
						
						
			MOVE $86, R2		; Save R2	
			MOVE $8E, R4		; Save R4 (Ptr. to dir. entry)	
						
			LBI R1, #$C8			
			MOVB R5, (R4)+			
			SE R5, R1		; 'H' ?	
			BRA $30FE		; No, error 38	
						
			LBI R1, #$C4			
			MOVB R5, (R4)+			
			SE R5, R1		; 'D' ?	
			BRA $30FE		; No, error 38	
						
			LBI R1, #$D9			
			MOVB R5, (R4)+			
			SE R5, R1		; 'R' ?	
			BRA $30FE		; No, error 38	
						
			LBI R1, #$F1			
			MOVB R5, (R4)			
			SE R5, R1		; '1' ?	
			BRA $30FE		; No, error 38	
						
			LBI R1, #$33			
			MLH R1, R1			
			LBI R1, #$16			
			INC2 R2, R0			
			RET R1			; Get status word
						
			CLR R5, #$F0		; Sector length code	
						
			MOVE R4, $8E		; Restore R4	
			ADD R4, #$2B			
			MOVB R7, (R4)		; Exchange Type Indicator	
			LBI R1, #$40			
			SNE R7, R1			
			BRA $30F8		; Blank	
						
			LBI R1, #$C8			
			SE R7, R1			
			BRA $30F4		; Not a basic exchange data set	
						
			LBI R1, #$40			
			MOVB (R4), R1			
			LBI R7, #$01		; 256 bytes phys. record size	
			BRA $30F8			
						
			SUB R4, #$0A			
			MOVB R7, (R4)		; Physical Record Length	
						
			CLR R7, #$F0			
			SNE R5, R7			
			BRA $3102		; $04(R0)	
						
			LBI R6, #$16		; Error 38	
			BRA $3010		; -> -$F2(R0)	
						
			MOVE R8, R3			
			ADD R8, #$0A			
			MOVE R8, (R8)		; IOCB_WA	
			ADD R8, #$08			
			MOVB (R8), R7		; Store record length in WA	
						
			MOVE R4, $8E		; Restore R4	
			ADD R4, #$1C		; Ptr to Begin Of Extent	
			INC2 R2, R0			
			BRA $31F0		; Check extent	
						
			INC2 R2, R0			
			BRA $317E		; Get sectors/cylinder in $9A	
						
			MOVE R4, $8E		; Restore R4	
			ADD R4, #$22		; End Of Extent (EOE)	
			MOVE R5, (R4)		; Track (EOE)	
			LBI R1, #$32			
			MLH R1, R1			
			LBI R1, #$5A			
			INC2 R2, R0			
			RET R1			; Convert to binary
						
			LBI R1, #$4A			
			SLE R8, R1		; EOE <= track 74 ?	
			BRA $30FE		; No, error 38	
						
			; Convert EOE in header record			
			LBI R1, #$32			
			MLH R1, R1			
			LBI R1, #$86			
			INC2 R2, R0			
			RET R1			
						
			INC2 R2, R0			
			ADD R2, #$0E		; R2 = $314A	
			; (Go straight through following subroutine)			
						
						
			; Get binary value back from header record			
			MOVB R7, (R4)+			
			MOVB R5, (R4)			
			MLH R5, R7			
						
			; Get pointer to work area			
			MOVE R4, R3			
			ADD R4, #$0A		; IOCB_WA	
			MOVE R4, (R4)			
			RET R2			
						
						
			; Store marked file size in WA			
			ADD R4, #$04			
			MOVE (R4), R5			
						
			; Convert EOD in header record			
			MOVE R4, $8E		; Restore R4	
			ADD R4, #$4A		; EOD	
			LBI R1, #$32			
			MLH R1, R1			
			LBI R1, #$86			
			INC2 R2, R0			
			RET R1			
						
			INC2 R2, R0			
			BRA $313C		; -> -$24(R0)	
						
			; Store used file size in WA			
			ADD R4, #$02			
			MOVE (R4)+, R5			
						
			; Test if used size > marked size			
			MOVE R7, (R4)		; Marked file size	
			ADD R7, #$01			
			SUB R7, R5			
			MHL R5, R7			
			MLH R7, R7			
			MHL R7, R5			
			SUB R5, R7			
			MHL R7, R7			
			MLH R7, R5			
			LBI R1, #$80			
			SNBSH R7, R1		; Used > marked ?	
			BRA $30FE		; Yes, error 38	
						
			JMP ($0086)		; Return	
						
						
						
						
						
						
						
			MOVE $84, R2		; Save R2	
						
			INC2 R2, R0			
			BRA $3198		; Get sectors/track	
						
			MOVE $9C, R5			
			INC2 R2, R0			
			BRA $3204		; Get drive status	
			MOVE R7, $9C			
						
			MHL R5, R5			
			LBI R1, #$40			
			SE R5, R1		; Diskette 1 ?	
			ADD R7, R7		; No, double number of sectors	
			MOVE $9A, R7			
						
			JMP ($0084)		; Return to caller	
						
						
						
						
						
						
						
			MOVE $82, R2		; Save R2	
						
			INC2 R2, R0			
			BRA $3204		; Get drive status	
						
			CLR R5, #$F0		; Sector length code	
			MHL R8, R5			
			LBI R1, #$D4			
			SNE R8, R1		; Diskette 2D ?	
			SUB R5, #$01		; Yes, normalize to 0-2	
						
			MOVE R1, $A0			
			CLR R5, #$F0			
			ADD R5, R5			
			ADD R0, R5			
			ADD R1, #$0B		; 26 sectors/track	
			ADD R1, #$07		; 15 sectors/track	
			ADD R1, #$08		; 8 sectors/track	
			MOVE R5, R1			
						
			JMP ($0082)		; Return to caller	
						
						
						
						
						
						
						
						
						
			MOVE $82, R2		; Save R2	
						
			; Get status word			
			INC2 R2, R0			
			BRA $3204		; Call $3316	
						
			MHL R7, R5			
			LBI R1, #$40			
			SNE R7, R1		; Diskette 1 ?	
			CLR R5, #$80		; Yes, clear interleave bit	
						
			MHL R8, R5			
			MOVE R7, $A0			
			LBI R7, #$13		; Standard 19 dir. entries	
			LBI R1, #$40			
			SNE R8, R1		; Diskette 1	
			BRA $31DC		; Yes, skip next block	
						
			LBI R1, #$F2			
			SE R8, R1		; Test if Diskette 2 or 2D	
			ADD R7, #$1A		; Add 26 dir. entries for 2D	
			ADD R7, #$1A		; Add 26 dir. entries for 2	
						
			CLR R5, #$0F		; Clear length code nibble	
			SWAP R5			; Number of add. dir. tracks
			SNZ R5			
			BRA $31EC		; No additional dir. tracks	
						
			; Calculate total number of directory entries			
						
			ADD R7, #$68		; 104 entries per add. track	
			SUB R5, #$01		; Decrement track count	
			SZ R5			
			BRA $31E4		; Loop	
						
			MOVE R5, R7			
			JMP ($0082)		; Return to caller	
						
						
						
						
						
						
			MOVE $84, R2		; Save R2	
						
			MOVE R5, (R4)+'		; Track of extent	
			INC2 R2, R0			
			BRA $325A		; Convert to binary	
						
			LBI R1, #$4A			
			SLE R8, R1		; Track <= 74 ?	
			BRA $3256		; No, error 38	
						
			MOVE R15, R8			
			MOVE R7, R4			
						
			INC2 R2, R0			
			BRA $3284		; Get drive status	
						
			MHL R6, R5			
			LBI R1, #$D4			
			SE R6, R1		; Diskette 2D ?	
			LBI R5, #$00		; No, no additional dir tracks	
			CLR R5, #$0F			
			SWAP R5			; Number of dir. tracks
			SGT R15, R5		; Data track > last dir track ?	
			BRA $3256		; No, error 38	
						
			MOVE R4, R7			
			MOVB R7, (R4)+		; Number is at odd address	
			MOVB R5, (R4)--		; so have to do byte accesses	
			MLH R5, R7		; Sector of extent	
			INC2 R2, R0			
			BRA $325A		; Convert to binary (into R8)	
						
			MLH R8, R15		; Track number to high byte	
						
			MOVB R5, (R4)		; Head of extent	
			LBI R7, #$F0			
			SNE R5, R7		; Side 0 ?	
			BRA $3238		; Yes	
						
			LBI R1, #$40			
			SNE R6, R1			
			BRA $3256		; Blank, error 38	
						
			LBI R7, #$F1			
			SE R5, R7		; Side 1 ?	
			BRA $3256		; No, error 38	
						
			CLR R5, #$F0			
			SZ R5			
			SET R8, #$80		; Set flag for side 1	
						
			MOVE R7, R3			
			ADD R7, #$0A			
			MOVE R7, (R7)		; IOCB_WA	
			MOVE (R7), R8		; Store track etc. in WA	
						
			INC2 R2, R0			
			BRA $3198		; Get sectors/track	
						
			MOVE R7, (R7)			
			CLR R7, #$80		; Clear side bit	
			SZ R7			; Track 0 -> error
			SLE R7, R5		; Sector>sect/trk -> error	
			BRA $3256		; Error 38	
						
			JMP ($0084)		; Return to caller	
						
			LBI R6, #$16		; Error 38	
			BRA $3304		; Exit	
						
						
						
						
						
						
			; Test if number is numeric (EBCDIC)			
						
			MHL R7, R5			
			LBI R8, #$F0			
			SNBS R7, R8			
			SBS R5, R8			
			BRA $3256		; Not numeric, error 38	
						
			; Convert EBCDIC to binary, high digit			
						
			CLR R7, #$F0			
			LBI R1, #$09			
			SLE R7, R1			
			BRA $3256		; Number invalid, error 38	
						
			MOVE R8, $A0		; Binary track number	
						
			SNZ R7			
			BRA $3278		; $06(R0)	
			ADD R8, #$0A		; Add 10	
			SUB R7, #$01			
			BRA $326E		; Loop	
						
			; Convert EBCDIC to binary, low digit			
						
			CLR R5, #$F0			
			LBI R1, #$09			
			SLE R5, R1			
			BRA $3256		; Number invalid, error 38	
						
			ADD R8, R5			
			RET R2			
						
						
			BRA $3316		; $90(R0)	
						
						
						
						
						
						
						
						
						
						
			MOVE $82, R2		; Save R2	
						
			MOVE R5, (R4)+'		; End Track	
			INC2 R2, R0			
			BRA $325A		; Convert to binary	
			MOVE R11, R8		; Save result	
						
			MOVB R8, (R4)+			
			MOVB R5, (R4)--			
			MLH R5, R8		; End Sector	
			INC2 R2, R0			
			BRA $325A		; Convert to binary	
			MOVE R13, R8		; Save result	
						
			MOVB R12, (R4)++	; End Side		
			LBI R7, #$F0			
			SNE R12, R7			
			BRA $32B2		; Side 0, ok	
						
			MOVE R5, $9A			
			MOVE R1, $9C			
			SNE R5, R1			
			BRA $3302		; Error 38	
						
			LBI R7, #$F1			
			SE R12, R7		; Side 1 ?	
			BRA $3302		; No, error 38	
						
			CLR R12, #$F0		; Make binary	
						
			MOVE R7, R3			
			ADD R7, #$0A			
			MOVE R7, (R7)		; IOCB_WA	
			MOVE R5, (R7)		; Get BOE from WA	
			MOVE R7, $A0		; Total number of sectors	
			MHL R1, R5		; Track	
			SUB R11, R1		; Tracks between end and BOE	
			LBI R1, #$80			
			SNBSH R11, R1		; End Track < BOE ?	
			BRA $3302		; Yes, error 38	
						
			SNZ R11			
			BRA $32D4		; Done	
			MOVE R1, $9A		; Sectors/cylinder	
			ADD R7, R1		; Add to number of sectors	
			SUB R11, #$01		; Decrement cylinder cound	
			BRA $32C8		; Loop	
						
			LBI R1, #$80			
			SBC R5, R1			
			SUB R12, #$01			
			MOVE R8, $9C			
			SZ R13			
			SLE R13, R8			
			BRA $3302		; Error 38	
						
			LBI R1, #$80			
			SBS R12, R1			
			BRA $32EC		; $04(R0)	
						
			SUB R7, R8			
			BRA $32F0		; $04(R0)	
						
			SZ R12			
			ADD R7, R8			
			CLR R5, #$80			
			SUB R13, R5			
			ADD R13, R7			
			MHL R7, R13			
			ADDH R7, R7			
			MLH R13, R7			
			LBI R1, #$80			
			SBSH R13, R1			
			BRA $330E		; $0C(R0)	
						
			LBI R6, #$16		; Error 38	
						
			LBI R1, #$3E			
			MLH R1, R1			
			LBI R1, #$FA			
			INC2 R2, R0			
			RET R1			; Error routine
						
						
			MOVB (R4)-, R13			
			MHL R13, R13			
			MOVB (R4), R13			
						
			JMP ($0082)		; Return to caller	
						
						
						
						
						
						
			MOVE R4, $D8			
			SUB R4, #$0C			
						
			MOVE R5, (R3)		; IOCB_Sub in Lo(R5)	
			ADD R5, R5		; Shift left one position	
			SNZ R5			
			BRA $3326		; Finished	
			ADD R4, #$02			
			BRA $331C		; Loop	
						
			MOVE R5, (R4)			
			RET R2			
						
						
						
						
						
						
						
			MOVE R4, R3			
			ADD R4, #$08			
			MOVE R5, (R4)		; IOCB_CI1	
			ADD R5, #$01			
			MOVE (R4), R5			
						
			RET R2			
						
						
						
						
						
						
			; Get offset (in sectors)			
			MOVE R4, R3			
			ADD R4, #$08			
			MOVE R7, (R4)		; IOCB_CI1 (file offset)	
			LBI R1, #$80			
			SNBSH R7, R1			
			BRA $337A		; Error 10	
						
			; Get used space (no. of sectors)			
			ADD R4, #$02			
			MOVE R4, (R4)		; IOCB_WA	
			ADD R4, #$02			
			MOVE R8, (R4)			
						
			; Test if operation beyond end of file			
			MOVE R5, R7			
			SUB R5, R8			
			MHL R8, R5			
			MLH R5, R5			
			MHL R5, R8			
			SUB R8, R5			
			MHL R5, R5			
			MLH R5, R8		; R5 <- R5 - R8	
			LBI R1, #$80			
			SNBSH R5, R1		; Offset <= EOF ?	
			RET R2			; Yes, return
						
			; Error, operation past end of file or data			
						
			ADD R4, #$02			
			MOVE R8, (R4)		; Get 4(IOCB_WA)	
						
			MOVE R5, R7			
			SUB R8, R5			
			MHL R5, R8			
			MLH R8, R8			
			MHL R8, R5			
			SUB R5, R8			
			MHL R8, R8			
			MLH R8, R5		; R8 <- R8 - R5	
			LBI R1, #$80			
						
			LBI R6, #$50		; Default to error 9 (EOD)	
			SNBSH R8, R1		; Negative (R8<R5) ?	
			LBI R6, #$4E		; Yes, error 10 (EOF)	
			BRA $3304		; Error exit	
						
						
						
						
						
						
						
			MOVE R4, R3			
			ADD R4, #$04			
			MOVE R4, (R4)		; IOCB_BA	
						
			ADD R4, #$47			
			MOVB R7, (R4)		; Volume Surface Indicator	
			ADD R4, #$04			
			MOVB R8, (R4)		; Physical Sector Length	
						
			LBI R1, #$40			
			SNE R7, R1		; Diskette 1	
			BRA $33B0		; Yes	
						
			STAT R5, $D		; Diskette Sense Byte	
			LBI R1, #$04			
			SBS R5, R1		; Two-sided diskette ?	
			BRA $33AC		; No, error 25	
						
			LBI R1, #$F2			
			SNE R7, R1		; Diskette 2 ?	
			BRA $33B0		; Yes	
						
			LBI R1, #$D4			
			SE R7, R1		; Diskette 2D ?	
			BRA $33AC		; No, error 25	
						
			LBI R1, #$40			
			SE R8, R1		; 128 bytes/sect. ?	
			BRA $33BC		; No	
						
			LBI R6, #$30		; Error 25	
			BRA $3304		; -> -$AC(R0)	
						
			LBI R1, #$F3			
			SNE R8, R1		; 1024 bytes/sect. ?	
			BRA $33AC		; Yes, error 25	
						
			LBI R1, #$40			
			SNE R8, R1		; 128 bytes/sect. ?	
			BRA $33C8		; Yes	
						
			LBI R1, #$F1			
			SGE R8, R1		; >= 256 bytes/sect. ?	
			BRA $33AC		; No, error 25	
						
			LBI R1, #$F3			
			SLE R8, R1		; <= 1024 bytes/sect. ?	
			BRA $33AC		; No, error 25	
						
			CLR R8, #$F0		; Make binary (sector length)	
						
			LBI R1, #$40			
			SE R7, R1		; Diskette 1 ?	
			BRA $33EA		; No	
						
			; Diskette 1			
						
			ADD R4, #$01			
			MOVE R5, (R4)		; Interleave factor	
			LBI R1, #$40			
			SNE R5, R1		; Blank (1:1) ?	
			BRA $340C		; Yes	
						
			LBI R1, #$F1			
			SE R5, R1		; '.1' ?	
			BRA $33E6		; No	
						
			MHL R5, R5			
			LBI R1, #$F0			
			SE R5, R1		; '01' ?	
			SET R8, #$80		; No	
						
			BRA $340C			
						
			; Diskette 2			
						
			LBI R1, #$D4		; 'M'	
			SE R7, R1		; Diskette 2D ?	
			BRA $340C		; No	
						
			SUB R4, #$0B			
			MOVB R5, (R4)		; Extended Label Area	
			LBI R1, #$40			
			SNE R5, R1		; Additional tracks ?	
			BRA $3406		; No	
						
			LBI R1, #$F1			
			SGE R5, R1		; >= '1'	
			BRA $33AC		; No, error 25	
						
			LBI R1, #$F9			
			SLE R5, R1		; <= '9'	
			BRA $33AC		; No, error 25	
						
			CLR R5, #$F0		; Make binary	
			SWAP R5			; To high nibble
			OR R8, R5		; Sector length to low nibble	
						
			MLH R8, R7		; Vol. Surf. Ind. to high byte	
						
			; Save status word			
						
			MOVE R4, $D8			
			SUB R4, #$0C			
			MOVE R7, (R3)			
			ADD R7, R7			
			SNZ R7			
			BRA $341E		; $04(R0)	
			ADD R4, #$02			
			BRA $3414		; -> -$0A(R0)	
						
			MOVE (R4), R8			
						
			; Set IOCB_BS to size of a data sector			
						
			CLR R8, #$F0		; Get length code	
			LBI R1, #$03			
			SNE R8, R1		; 1024 bytes/sect. ?	
			ADD R8, #$01		; Size $0400	
			MOVE R15, $A0			
			MLH R15, R8			
			SNZ R8			
			LBI R15, #$80		; 128 bytes (default)	
			MOVE R4, R3			
			ADD R4, #$06			
			MOVE (R4), R15		; IOCB_BS	
						
			RET R2			; Return to caller
						
						
						
						
						
						
						
			MOVE $8A, R2		; Save R2	
						
			MOVE R5, $A0			
			MOVE $94, R5			
						
			LBI R1, #$37			
			MLH R1, R1			
			LBI R1, #$80			
			INC2 R2, R0			
			RET R1			; Locate sector on disk
						
			; Sector found			
						
			MOVE R4, R3			
			ADD R4, #$04			
			MOVE R4, (R4)		; IOCB_BA	
						
			MOVE R5, $90			
			LBI R1, #$08			
			SBS R5, R1			
			MOVE R4, $5C			
						
			LBI R6, #$00			
			LBI R1, #$3D			
			MLH R1, R1			
			LBI R1, #$5C			
			INC2 R2, R0			
			RET R1			; Read data field
						
			SNZ R6			; Errors found ?
			BRA $349C		; No	
						
			LBI R1, #$80			
			SBS R6, R1		; CRC error ?	
			BRA $349C		; No	
						
			MOVE R5, $A2			
			LBI R1, #$80			
			SNBSH R5, R1		; Retry on CRC errors ?	
			BRA $3480		; No	
						
			MOVE R5, $94			
			ADD R5, #$01			
			MOVE $94, R5		; Increment retry counter	
			LBI R1, #$0A			
			SGE R5, R1			
			BRA $343E		; Retry read	
						
			LBI R1, #$20			
			SNBS R6, R1		; DDAM ?	
			BRA $3492		; Yes	
						
			LBI R6, #$40		; Error 17	
			LBI R1, #$3E			
			MLH R1, R1			
			LBI R1, #$FA			
			INC2 R2, R0			
			RET R1			; Error exit
						
			MOVE R7, $52		; Get first data byte from R9L2	
			LBI R1, #$C4			
			SNE R7, R1		; Is it 'D' ?	
			BRA $3486		; Yes, error 17	
						
			; Sectors with DDAM may have CRC errors if first			
			; data byte is not 'D'. No error is set then.			
						
			CLR R6, #$80		; Clear CRC error flag	
						
			JMP ($008A)		; Return to caller	
						
						
						
						
						
			MOVE $8A, R2		; Save R2	
						
			MOVE R5, $A0			
			MOVE $94, R5		; Reset retry counter	
						
			MOVE R5, $90			
			CLR R5, #$01			
			MOVE $90, R5			
						
			MOVE R4, R3			
			ADD R4, #$04		; IOCB_BA	
			MOVE R7, (R4)			
			MOVE $5C, R7		; R14L2	
						
			LBI R1, #$08			
			SBC R5, R1			
			BRA $34DA		; $22(R0)	
						
			ADD R4, #$0A		; IOCB_CI2	
			MOVE R5, $A0			
			MOVE (R4), R5			
						
			MOVE R5, $44		; R2L2	
			MOVE $46, R5		; R3L2	
						
			SUB R4, #$06		; IOCB_CI1	
			MOVE R13, (R4)			
			MOVE $58, R13		; R12L2	
						
			MOVE R5, $5C		; R14L2	
			MOVE $5A, R5		; R13L2	
						
			LBI R1, #$2F			
			MLH R1, R1			
			LBI R1, #$12			
			INC2 R2, R0			
			RET R1			; CALL $2F12, R2
						
			MOVE R5, $9A			
			MOVE $56, R5		; R11L2	
						
			; Locate sector on disk (implies seek etc.)			
			LBI R1, #$37			
			MLH R1, R1			
			LBI R1, #$80			
			INC2 R2, R0			
			RET R1			; CALL $3780, R2
						
			MOVE R4, $5C		; R14L2	
			LBI R6, #$FB			
			MOVE R5, $90			
			LBI R1, #$20			
			SBC R5, R1			
			LBI R6, #$F8			
			LBI R1, #$10			
			SBS R5, R1			
			BRA $3500		; $0A(R0)	
						
			LBI R5, #$3E			
			MLH R5, R5			
			LBI R5, #$72			
			LBI R7, #$14			
			BRA $3508		; $08(R0)	
						
			LBI R5, #$3E			
			MLH R5, R5			
			LBI R5, #$D8			
			LBI R7, #$0A			
			LBI R9, #$00			
			MLH R9, R9			
			LBI R9, #$67			
			MOVE R15, $5E			
			SLT R15, R7			
			BRA $3522		; $0E(R0)	
						
			SUB R9, #$01			
			LBI R1, #$80			
			SBSH R9, R1			
			BRA $350E		; -> -$0E(R0)	
						
			CTRL $D, #$01			
			LBI R6, #$38			
			BRA $35E0		; $BE(R0)	
						
			CTRL $D, #$01			
			MOVE $40, R5			
			LBI R1, #$3E			
			MLH R1, R1			
			LBI R1, #$1A			
			INC2 R2, R0			
			RET R1			
						
			MOVE R5, $90			
			LBI R1, #$09			
			SBC R5, R1			
			BRA $3598		; $60(R0)	
						
			MOVE R7, $46			
			SUB R7, #$01			
			MOVE $46, R7			
			LBI R1, #$33			
			MLH R1, R1			
			LBI R1, #$2A			
			INC2 R2, R0			
			RET R1			
						
			MHL R1, R7			
			OR R1, R7			
			SNZ R1			
			BRA $3588		; $38(R0)	
						
			MOVE R7, $EA			
			MOVE R13, R5			
			SUB R7, R5			
			MHL R5, R7			
			MLH R7, R7			
			MHL R7, R5			
			SUB R5, R7			
			MHL R7, R7			
			MLH R7, R5			
			LBI R1, #$80			
			SNBSH R7, R1			
			BRA $3588		; $20(R0)	
						
			LBI R1, #$2F			
			MLH R1, R1			
			LBI R1, #$12			
			INC2 R2, R0			
			RET R1			
						
			MOVE R5, $9A			
			MOVE R7, $56			
			SE R7, R5			
			BRA $3588		; $0E(R0)	
						
			LBI R1, #$36			
			MLH R1, R1			
			LBI R1, #$F8			
			INC2 R2, R0			
			RET R1			
						
			BRA $34DA		; -> -$AC(R0)	
						
			BRA $34C6		; -> -$C2(R0)	
						
			MOVE R5, $5A			
			MOVE $5C, R5			
			MOVE R13, $58			
			LBI R1, #$2F			
			MLH R1, R1			
			LBI R1, #$12			
			INC2 R2, R0			
			RET R1			
						
			LBI R1, #$37			
			MLH R1, R1			
			LBI R1, #$80			
			INC2 R2, R0			
			RET R1			
						
			MOVE R4, $5C			
			LBI R6, #$FF			
			LBI R1, #$3D			
			MLH R1, R1			
			LBI R1, #$5C			
			INC2 R2, R0			
			RET R1			
						
			MOVE R5, $90			
			LBI R1, #$20			
			SBS R5, R1			
			BRA $3630		; $78(R0)	
						
			MOVB R5, (R4)			
			LBI R1, #$C6			
			SE R5, R1			
			BRA $3620		; $60(R0)	
						
			LBI R1, #$20			
			SBS R6, R1			
			BRA $35CE		; $08(R0)	
						
			MOVE R5, $52			
			LBI R1, #$C6			
			SNE R5, R1			
			BRA $35E2		; $14(R0)	
						
			MOVE R5, $94			
			ADD R5, #$01			
			MOVE $94, R5			
			LBI R1, #$0A			
			SGE R5, R1			
			BRA $3584		; -> -$56(R0)	
						
			MOVE R5, $8E			
			MOVB (R4), R5			
			LBI R6, #$24			
			BRA $366C		; $8A(R0)	
						
			MOVE R5, $90			
			CLR R5, #$21			
			MOVE $90, R5			
			MOVE R5, $8E			
			MOVB (R4), R5			
			MOVE R5, $58			
			MOVE R4, R3			
			ADD R4, #$08			
			MOVE (R4), R5			
			LBI R1, #$33			
			MLH R1, R1			
			LBI R1, #$2A			
			INC2 R2, R0			
			RET R1			
						
			MOVE R8, $44			
			ADD R4, #$06			
			MOVE R7, (R4)			
			SUB R8, R7			
			MHL R7, R8			
			MLH R8, R8			
			MHL R8, R7			
			SUB R7, R8			
			MHL R8, R8			
			MLH R8, R7			
			MOVE $46, R8			
			MOVE R5, $A0			
			MOVE $94, R5			
			BRA $36C2		; $A8(R0)	
						
			BRA $3584		; -> -$98(R0)	
						
			BRA $3586		; -> -$98(R0)	
						
			BRA $358C		; -> -$94(R0)	
						
			LBI R1, #$20			
			SBS R6, R1			
			BRA $3634		; $0E(R0)	
						
			LBI R1, #$80			
			SBC R6, R1			
			BRA $3634		; $08(R0)	
						
			LBI R6, #$00			
			BRA $36F6		; $C6(R0)	
						
			SNZ R6			
			BRA $368C		; $58(R0)	
						
			MOVE R7, $A2			
			LBI R1, #$80			
			SNBSH R7, R1			
			BRA $364E		; $12(R0)	
						
			MOVE R5, $90			
			SET R5, #$01			
			MOVE $90, R5			
			MOVE R5, $94			
			ADD R5, #$01			
			MOVE $94, R5			
			LBI R1, #$0A			
			SGE R5, R1			
			BRA $3584		; -> -$CA(R0)	
						
			LBI R6, #$80			
			MOVE R5, $90			
			LBI R1, #$08			
			SBC R5, R1			
			BRA $36F6		; $9E(R0)	
						
			LBI R1, #$80			
			SNBSH R7, R1			
			BRA $366A		; $0C(R0)	
						
			MOVE R4, R3			
			ADD R4, #$03			
			MOVB R5, (R4)+			
			LBI R1, #$08			
			SBS R5, R1			
			BRA $3676		; $0C(R0)	
						
			LBI R6, #$3C			
			LBI R1, #$3E			
			MLH R1, R1			
			LBI R1, #$FA			
			INC2 R2, R0			
			RET R1			
						
			MOVE R4, $5C			
			MOVB R5, (R4)			
			MOVE $8E, R5			
			LBI R5, #$C6			
			MOVB (R4), R5			
			MOVE R5, $90			
			SET R5, #$20			
			MOVE $90, R5			
			MOVE R5, $A0			
			MOVE $94, R5			
			BRA $361A		; -> -$72(R0)	
						
			MOVE R5, $90			
			LBI R1, #$08			
			SBC R5, R1			
			BRA $36F4		; $60(R0)	
						
			CLR R5, #$01			
			MOVE $90, R5			
			INC2 R2, R0			
			BRA $36F8		; $5C(R0)	
						
			MOVE R5, $58			
			ADD R5, #$01			
			MOVE $58, R5			
			MOVE R4, R3			
			ADD R4, #$0E			
			MOVE R5, (R4)			
			ADD R5, #$01			
			MOVE (R4), R5			
			MOVE R5, $A0			
			MOVE $94, R5			
			SUB R4, #$06			
			MOVE R5, (R4)			
			MOVE R7, $58			
			SE R5, R7			
			BRA $361E		; -> -$9C(R0)	
						
			MHL R5, R5			
			MHL R7, R7			
			SE R5, R7			
			BRA $361E		; -> -$A4(R0)	
						
			MOVE R5, $46			
			MHL R1, R5			
			OR R1, R5			
			SNZ R1			
			BRA $36F4		; $28(R0)	
						
			MOVE R4, R3			
			ADD R4, #$08			
			MOVE R5, (R4)+			
			MOVE R7, $EA			
			MOVE R13, R5			
			SUB R7, R5			
			MHL R5, R7			
			MLH R7, R7			
			MHL R7, R5			
			SUB R5, R7			
			MHL R7, R7			
			MLH R7, R5			
			LBI R1, #$80			
			SBSH R7, R1			
			BRA $361C		; -> -$CE(R0)	
						
			MOVE R4, (R4)			
			ADD R4, #$02			
			MOVE (R4), R13			
			LBI R6, #$4E			
			BRA $366C		; -> -$88(R0)	
						
			LBI R6, #$00			
			JMP ($008A)			
						
						
						
						
						
						
			MOVE R4, R3			
			ADD R4, #$0A		; IOCB_WA	
			MOVE R4, (R4)			
			ADD R4, #$08			
			MOVB R5, (R4)		; Get physical record size	
			LBI R1, #$03			
			SNE R5, R1			
			ADD R5, #$01		; 1024 bytes/sector	
			MLH R5, R5			
			SNZ R5			
			LBI R5, #$80		; 128 bytes/sector	
			CLR R5, #$0F			
						
			MOVE R7, $5C		; R14L2	
			ADD R7, R5			
			MHL R5, R7			
			ADDH R5, R5			
			MLH R7, R5			
			MOVE $5C, R7		; R14L2	
						
			RET R2			
						
						
						
						
						
						
			MOVE $84, R2		; Save R2	
						
			MOVE R4, R3			
			ADD R4, #$08		; IOCB_CI1	
			MOVB R8, (R4)+		; Track number	
			LBI R1, #$4C			
			SGT R8, R1		; Greater than 76 ?	
			BRA $3730		; No	
						
			LBI R6, #$5E		; Error 02	
			BRA $366C		; Error exit	
						
						
			MOVE $9A, R8		; Store track number	
						
			MOVB R7, (R4)			
			MOVE R5, $A0			
			LBI R1, #$80		; Test if bit 0 set	
			SBC R7, R1			
			LBI R5, #$01		; Yes, side 1	
			MOVE $9C, R5		; Store side	
						
			CLR R7, #$80		; Clear side flag	
			SNZ R7			; Test sector number
			BRA $372C		; Zero, error	
						
			SNZ R8			
			BRA $3762		; Track zero	
						
			; Get drive status word			
			LBI R1, #$33			
			MLH R1, R1			
			LBI R1, #$16			
			INC2 R2, R0			
			RET R1			; CALL $3316, R2
						
			MHL R15, R5			
			LBI R1, #$40			
			SNE R15, R1			
			CLR R5, #$80			
			CLR R5, #$0F			
			SWAP R5			
			SLE R8, R5			
			BRA $3766		; $04(R0)	
						
			LBI R5, #$1A			
			BRA $3770		; $0A(R0)	
						
			; Get sectors per track			
			LBI R1, #$31			
			MLH R1, R1			
			LBI R1, #$98			
			INC2 R2, R0			
			RET R1			
						
			MOVE R1, R5			
			SWAP R1			
			ROR R1			
			MOVE $98, R1			
						
			SLE R7, R5			
			BRA $372C		; Error	
						
			MOVE $9E, R7		; Store sector number	
						
			JMP ($0084)		; Return	
						
						
						
						
						
						
						
						
			MOVE $88, R2		; Save R2	
						
			MOVE R5, $A0			
			MOVE $96, R5			
			LBI R1, #$3B			
			MLH R1, R1			
			LBI R1, #$78			
			INC2 R2, R0			
			RET R1			; Get track value
						
			STAT R5, $D		; Diskette Sense byte	
			LBI R1, #$08			
			SBS R5, R1		; Erase Gate active ?	
			BRA $37A2		; No	
						
			LBI R1, #$38			
			MLH R1, R1			
			LBI R1, #$A0			
			INC2 R2, R0			
			RET R1			; Wait for Erase Gate off
						
			MOVE R1, $90			
			CLR R1, #$C0			
			MOVE $90, R1			
						
			MOVE R5, $9A			
			SNE R11, R5		; Already on desired track ?	
			BRA $3800		; Yes	
						
			SGT R5, R11		; Track > current track ?	
			BRA $37C0		; No	
						
			SUB R5, R11			
			MOVE R15, R5			
			LBI R10, #$00		; Seek in	
			MOVE R1, $90			
			SET R1, #$80			
			MOVE $90, R1			
			BRA $37CC			
						
			MOVE R15, R11			
			SUB R15, R5			
			LBI R10, #$FF		; Seek out	
			MOVE R1, $90			
			SET R1, #$40			
			MOVE $90, R1			
						
			LBI R1, #$3D			
			MLH R1, R1			
			LBI R1, #$0C			
			INC2 R2, R0			
			RET R1			; Seek routine
						
			MOVE R11, $9A		; Update current track	
			LBI R1, #$3B			
			MLH R1, R1			
			LBI R1, #$7C			
			INC2 R2, R0			
			RET R1			; Set track value
						
			SZ R11			; Track 0 ?
			BRA $37F2		; No	
						
			LBI R1, #$3A			
			MLH R1, R1			
			LBI R1, #$94			
			INC2 R2, R0			
			RET R1			; Verify Access Lines
			BRA $3800		; $0E(R0)	
						
			; Delay after seek			
						
			LBI R9, #$15			
			MLH R9, R9			
			LBI R9, #$BD			
			SUB R9, #$01			
			LBI R1, #$80			
			SBSH R9, R1			
			BRA $37F8		; Loop	
						
			; On desired track			
						
			LBI R1, #$39			
			MLH R1, R1			
			LBI R1, #$3E			
			INC2 R2, R0			
			RET R1			; Set adapter flags
						
			MOVE R5, $A0			
			MOVE $92, R5			
						
			LBI R1, #$3B			
			MLH R1, R1			
			LBI R1, #$9A			
			INC2 R2, R0			
			RET R1			; Read next ID field
						
			SNZ R6			; CRC error ?
			BRA $3840		; No	
						
			CTRL $D, #$01		; Reset R/W/D	
			MOVE R5, $92			
			ADD R5, #$01			
			MOVE $92, R5			
			MOVE R1, $98			
			SLT R5, R1			
			BRA $383C		; $12(R0)	
						
			LBI R5, #$80		; Read status byte	
			STAT R5, $4		; from keyboard adapter	
			LBI R1, #$08			
			SBS R5, R1		; Key pending ?	
			BRA $380E		; No, loop	
			CTRL $4, #$42		; Enable int. 3	
						
			MOVE R5, $A0			
			MOVE $98, R5			
			BRA $380E		; Loop	
						
			LBI R6, #$3E		; Error 18	
			BRA $387F		; Error routine	
						
			; ID field read			
						
			MOVE R5, $9A		; Compare track with ID byte 1	
			SNE R5, R11		; Same (track correct) ?	
			BRA $3876		; Yes	
						
			; Track byte from ID field is not equal to			
			; current track number			
						
			CTRL $D, #$01		; Reset R/W/D	
			CTRL $4, #$4A			
			MOVE R5, $96			
			ADD R5, #$01			
			MOVE $96, R5		; Increment retry counter	
			LBI R7, #$05			
			SLT R5, R7			
			BRA $385C		; $06(R0)	
						
			INC2 R2, R0			
			BRA $38B4		; Seek to desired track	
			BRA $380A		; Retry read on current track	
						
			SE R5, R7			
			BRA $386C		; $0C(R0)	
						
			; Recalibrate after 5 retries			
						
			LBI R1, #$3A			
			MLH R1, R1			
			LBI R1, #$6C			
			INC2 R2, R0			
			RET R1			; Call $3A6C
			BRA $37A2		; Retry	
						
			LBI R7, #$0A			
			SGE R5, R7			
			BRA $3856		; -> -$1C(R0)	
						
			; 10 unsuccessful retries			
						
			LBI R6, #$2C		; Error 27	
			BRA $3880		; Error exit	
						
			; Track byte from ID correct			
						
			MOVE R1, $9C		; Compare side with ID byte 2	
			SNE R12, R1		; Same (side correct) ?	
			BRA $388A		; Yes	
						
			CTRL $D, #$01			
			LBI R6, #$2E			
			LBI R1, #$3E			
			MLH R1, R1			
			LBI R1, #$FA			
			INC2 R2, R0			
			RET R1			
						
			; Side byte from ID correct			
						
			MOVE R1, $9E		; Compare sector with ID byte 3	
			SNE R13, R1		; Same (sector found) ?	
			BRA $389E		; Yes	
						
			; Wrong sector number			
						
			CTRL $D, #$01		; Reset R/W/D	
			CTRL $4, #$42			
			LBI R1, #$39			
			MLH R1, R1			
			LBI R1, #$AA			
			INC2 R2, R0			
			RET R1			; Find sector
						
			; Desired sector found			
						
			JMP ($0088)		; Return to caller	
						
						
						
						
						
						
			LBI R9, #$38		; Timeout value	
						
			STAT R5, $D		; Diskette Sense byte	
			LBI R1, #$08			
			SBS R5, R1		; Erase Gate active ?	
			RET R2			; No, return to caller
						
			SUB R9, #$01			
			SZ R9			
			BRA $38A2		; Loop	
						
			; Timeout			
						
			LBI R6, #$1E		; Error 34	
			BRA $3880		; Error routine	
						
						
						
						
						
						
			MOVE $86, R2		; Save R2	
						
			SNS R11			
			BRA $38E0		; Track unknown	
						
			MOVE R15, $9A		; Get track	
			SGT R15, R11		; Compare to track from ID	
			BRA $38CE		; 	
						
			; Head too far outside (track to small)			
						
			SUB R15, R11		; Difference to desired track	
			LBI R10, #$00		; Step direction	
			MOVE R1, $90			
			SET R1, #$80			
			CLR R1, #$40			
			MOVE $90, R1			
			BRA $3912		; $44(R0)	
						
			; Head too far inside (track to big)			
						
			MOVE R7, R11			
			SUB R7, R15		; Difference to desired track	
			MOVE R15, R7			
			LBI R10, #$FF		; Step direction	
			MOVE R1, $90			
			SET R1, #$40			
			CLR R1, #$80			
			MOVE $90, R1			
			BRA $3912		; $32(R0)	
						
			; Track unknown			
						
			LBI R1, #$80			
			MOVE R5, $90			
			SBS R5, R1			
			BRA $38EE		; $06(R0)	
						
			LBI R15, #$01			
			LBI R10, #$00			
			BRA $3912		; $24(R0)	
						
			LBI R1, #$40			
			SBS R5, R1			
			BRA $38FA		; $06(R0)	
						
			LBI R15, #$01			
			LBI R10, #$FF			
			BRA $3912		; $18(R0)	
						
			LBI R1, #$3A			
			MLH R1, R1			
			LBI R1, #$6C			
			INC2 R2, R0			
			RET R1			
						
			MOVE R15, $9A			
			SNZ R15			
			BRA $393C		; $32(R0)	
						
			LBI R10, #$00			
			MOVE R1, $90			
			SET R1, #$80			
			MOVE $90, R1			
						
			; Seek to correct position			
						
			LBI R1, #$3D			
			MLH R1, R1			
			LBI R1, #$0C			
			INC2 R2, R0			
			RET R1			; Seek
						
			MOVE R5, $9A			
			SZ R5			; Seek to track 0 ?
			BRA $392E		; No	
						
			LBI R1, #$3A			
			MLH R1, R1			
			LBI R1, #$94			
			INC2 R2, R0			
			RET R1			; Verify access lines
			BRA $393C		; $0E(R0)	
						
			; Delay after seek operation			
						
			LBI R9, #$15			
			MLH R9, R9			
			LBI R9, #$BD			
			SUB R9, #$01			
			LBI R1, #$80			
			SBSH R9, R1			
			BRA $3934		; -> -$08(R0)	
						
			JMP ($0086)		; Return to caller	
						
						
						
						
						
						
						
			MOVE $82, R2		; Save R2	
						
			GETB R8, $D		; Access Sense byte	
			CLR R8, #$74			
						
			MOVE R1, $90			
			CLR R1, #$10			
			MOVE $90, R1			
						
			MOVE R7, $9A			
			LBI R1, #$2A			
			SLT R7, R1		; Track >= 42 ?	
			SET R8, #$10		; Yes, set Inner Tracks	
			LBI R1, #$3C			
			SLT R7, R1		; Track >= 60 ?	
			SET R8, #$20		; Yes, set Switch Filter	
			SZ R7			; Track 0 ?
			BRA $3962		; No	
						
			MOVE R7, $9C			
			SNZ R7			; Side 0 ?
			BRA $397C		; Yes (system track)	
						
			LBI R1, #$33			
			MLH R1, R1			
			LBI R1, #$16			
			INC2 R2, R0			
			RET R1			; Get status word (?)
						
			MHL R5, R5			
			LBI R1, #$D4		; 'M'	
			SE R5, R1		; Diskette 2D ?	
			BRA $397C		; No	
						
			MOVE R1, $90			
			SET R1, #$10			
			MOVE $90, R1			
			SET R8, #$40		; MFM	
						
			MOVE R1, $9C		; Side	
			SZ R1			
			BRA $3986			
						
			CLR R8, #$04		; Select Side 0	
			BRA $3992			
						
			LBI R1, #$40			
			SE R5, R1		; Diskette 1 ?	
			BRA $3990		; No	
						
			LBI R6, #$2A		; Error 28	
			BRA $3A3C		; Error routine	
						
			SET R8, #$04		; Select Side 1	
						
			MOVE R7, $A0			
			LBI R7, #$11		; Lo(R8)	
			PUTB $D, (R7)		; Access Control byte	
						
			CLR R8, #$80			
			GETB R7, $D		; Access Sense byte	
			SNE R7, R8		; Got new settings ?	
			JMP ($0082)		; Yes, return to caller	
						
			; Access Sense byte not updated			
						
			STAT R5, $D		; Diskette Sense byte	
			MLH R7, R5			
			MOVE $E8, R7		; Set Diskette Status Byte	
			LBI R6, #$1C		; Error 35	
			BRA $3A3C		; Error routine	
						
						
						
						
						
						
						
			MOVE $84, R2		; Save R2	
						
			MOVE R5, $A0			
			MOVE $92, R5			
						
			LBI R8, #$00			
						
			LBI R1, #$3B			
			MLH R1, R1			
			LBI R1, #$9A			
			INC2 R2, R0			
			RET R1			; Read ID
						
			SNZ R6			; CRC error ?
			BRA $39E0		; No	
						
			CTRL $D, #$01		; Reset R/W/D	
			MOVE R5, $9E			
			SE R5, R13		; Sector found ?	
			BRA $39E8		; No	
						
			; Sector found, but CRC error			
						
			MOVE R5, $A2			
			LBI R1, #$80			
			SNBSH R5, R1			
			BRA $39DC		; No retries please	
						
			MOVE R5, $92			
			ADD R5, #$01			
			MOVE $92, R5		; Increment retry counter	
			LBI R1, #$0A			
			SGE R5, R1			
			BRA $39E8		; Retry read	
						
			LBI R6, #$42		; Error 16	
			BRA $3A3C		; Exit	
						
			MOVE R5, $9E		; Sector to find	
			SNE R5, R13		; Found ?	
			JMP ($0084)		; Yes, return to caller	
						
			; Sector not found			
						
			CTRL $D, #$01		; Reset R/W/D	
			ADD R8, #$01		; Increment find counter	
						
			LBI R5, #$80			
			STAT R5, $4		; Get keyboard status	
			LBI R1, #$08			
			SBS R5, R1		; Key pending ?	
			BRA $39F8		; No	
						
			CTRL $4, #$42		; Enable Int 3	
			LBI R8, #$00			
						
			MOVE R5, $98			
			SGE R8, R5			
			BRA $39B2		; Read next ID	
						
			MOVE R5, $92			
			SZ R5			
			BRA $3A08		; $04(R0)	
						
			LBI R6, #$3A		; Error 20	
			BRA $3A3C		; Exit	
						
			MHL R1, R5			
			SLT R1, R5			
			BRA $3A04		; -> -$0A(R0)	
						
			MLH R5, R5			
			MOVE $92, R5			
			BRA $39B0		; Restart	
						
						
						
						
						
						
			MOVE R4, R3			
			ADD R4, #$04			
			MOVE R4, (R4)		; IOCB_BA	
			LBI R1, #$E5		; 'V'	
			MOVB R7, (R4)+			
			SE R7, R1		; Test byte 1	
			BRA $3A3A		; Wrong	
						
			LBI R1, #$D6		; 'O'	
			MOVB R7, (R4)+			
			SE R7, R1		; Test byte 2	
			BRA $3A3A		; Wrong	
						
			LBI R1, #$D3		; 'L'	
			MOVB R7, (R4)+			
			SE R7, R1		; Test byte 3	
			BRA $3A3A		; Wrong	
						
			LBI R1, #$F1		; '1'	
			MOVB R7, (R4)			
			SNE R7, R1		; Test byte 4	
			BRA $3A46		; Correct	
						
			LBI R6, #$32		; Error 24	
						
			LBI R1, #$3E			
			MLH R1, R1			
			LBI R1, #$FA			
			INC2 R2, R0			
			RET R1			; Error exit
						
			ADD R4, #$07			
			LBI R1, #$40			
			MOVB R7, (R4)		; Accessibility	
			SNE R7, R1			
			BRA $3A54		; Access allowed	
						
			LBI R6, #$0C		; Error 43	
			BRA $3A3C		; Exit	
						
			ADD R4, #$3F			
			LBI R1, #$40			
			MOVB R7, (R4)		; Special Requirements Ind.	
			SE R7, R1			
			BRA $3A68		; Not blank	
						
			ADD R4, #$06			
			LBI R1, #$E6		; 'W'	
			MOVB R7, (R4)		; Label Standard Version	
			SNE R7, R1			
			RET R2			; Everything's correct, return
						
			LBI R6, #$30		; Error 25	
			BRA $3A3C		; Exit	
						
						
						
						
						
						
						
			MOVE $84, R2		; Save R2	
			MOVE R15, $A0			
						
			GETB R5, $D		; Access Sense byte	
			CLR R5, #$FC		; Mask Access Lines	
			SNZ R5			
			BRA $3A84		; $0C(R0)	
						
			LBI R7, #$02			
			SGE R5, R7			
			ADD R15, #$01			
			ADD R15, #$01			
			SE R5, R7			
			ADD R15, #$01			
						
			ADD R15, #$4E			
						
			; Seek			
						
			LBI R10, #$FF			
			LBI R1, #$3D			
			MLH R1, R1			
			LBI R1, #$0C			
			INC2 R2, R0			
			RET R1			; CALL $3D0C, R2
						
			BRA $3A96		; $02(R0)	
						
						
						
						
						
						
			MOVE $84, R2			
						
			GETB R5, $D		; Access Sense byte	
			CLR R5, #$FC		; Mask Access Lines	
			LBI R7, #$03			
			SNE R5, R7		; Track 0, 4, 8, ... ?	
			BRA $3AC6		; Yes	
						
			; Access Lines not %11, seek the			
			; required number of tracks outwards			
						
			MOVE R15, $A0		; Number of tracks to track 0	
			LBI R7, #$01			
			SLE R5, R7			
			ADD R15, #$01		; One	
			SE R5, R7			
			ADD R15, #$01		; Another one	
			ADD R15, #$01		; And another one (max. 3)	
			LBI R10, #$FF		; Seek out	
			LBI R1, #$3D			
			MLH R1, R1			
			LBI R1, #$0C			
			INC2 R2, R0			
			RET R1			; Seek routine
						
			GETB R5, $D		; Access Sense byte	
			SET R5, #$FC			
			SNS R5			; Access Lines all set ?
			BRA $3AC6		; Yes	
						
			LBI R6, #$2C		; No, error 27	
			BRA $3B5C		; Error routine	
						
			LBI R11, #$00		; Track 0	
			INC2 R2, R0			
			BRA $3B7C		; Set track value	
						
			; Delay after seek			
						
			LBI R9, #$15			
			MLH R9, R9			
			LBI R9, #$BD			
			SUB R9, #$01			
			LBI R1, #$80			
			SBSH R9, R1			
			BRA $3AD2		; -> -$08(R0)	
						
			JMP ($0084)		; Return to caller	
						
						
						
						
						
						
			MOVE $82, R2		; Save R2	
						
			LBI R9, #$71			
			MLH R9, R9			
			LBI R9, #$2B		; R9 <- $712B	
						; (Timeout value)
						
			STAT R5, $D		; Diskette Sense Byte	
			LBI R7, #$10			
			SBC R5, R7		; Index ?	
			LBI R7, #$00		; Yes	
						
			INC2 R2, R0			
			BRA $3B48		; Wait for Index bit change	
						
			INC2 R2, R0			
			BRA $3BA8		; Engage heads	
						
			LBI R9, #$71			
			MLH R9, R9			
			LBI R9, #$2B		; R9 <- $712B	
						
			CTRL $0, #$3F		; Disable interrupts	
			STAT R5, $D		; Diskette Sense byte	
			LBI R7, #$10			
			SBS R5, R7		; Index ?	
			BRA $3B0A		; No	
						
			LBI R7, #$00			
			INC2 R2, R0			
			BRA $3B48		; Wait until index hole passed	
						
			LBI R7, #$10			
			INC2 R2, R0			
			BRA $3B48		; Wait for index hole	
						
			; Delay after detection of index hole			
						
			LBI R9, #$06			
			MLH R9, R9			
			LBI R9, #$36		; R9 <- $0636	
			SUB R9, #$01			
			LBI R1, #$80			
			SBSH R9, R1			
			BRA $3B16		; Loop	
						
			STAT R5, $D		; Diskette Sense byte	
			LBI R1, #$10			
			SBC R5, R1		; Index ?	
			BRA $3B58		; Yes, error 45	
						
			CTRL $D, #$01		; Reset R/W/D	
						
			LBI R9, #$35			
			MLH R9, R9			
			LBI R9, #$D5		; R9 <- $35D5	
			INC2 R2, R0			
			BRA $3B66		; Wait for index hole	
			BRA $3B40		; Index hole found too early	
						
			LBI R9, #$02			
			MLH R9, R9			
			LBI R9, #$F7		; R9 <- $02F7	
			INC2 R2, R0			
			BRA $3B66		; Wait for index hole	
			BRA $3B44		; Index hole found in time	
						
			LBI R6, #$60		; Error 01	
			BRA $3B5A			
						
			CTRL $0, #$5F		; Enable interrupts	
			JMP ($0082)		; Return to caller	
						
						
			; Wait for Index bit change or timeout			
						
			STAT R5, $D		; Diskette Sense byte	
			CLR R5, #$EF			
			SNE R5, R7		; Test Index bit	
			RET R2			
						
			SUB R9, #$01			
			LBI R1, #$80			
			SBSH R9, R1			
			BRA $3B48		; Loop until timeout	
						
			; Timeout			
						
			LBI R6, #$08		; Error 45	
			CTRL $0, #$5F		; Enable interrupts	
			LBI R1, #$3E			
			MLH R1, R1			
			LBI R1, #$FA			
			INC2 R2, R0			
			RET R1			; Error routine
						; (won't return here)
						
						
			; Wait for index hole or timeout			
						
			SUB R9, #$01		; Decrement timeout counter	
			LBI R1, #$80			
			SNBSH R9, R1			
			INC2 R0, R2		; Error exit (timeout)	
						
			STAT R5, $D		; Diskette Sense byte	
			LBI R1, #$10			
			SBS R5, R1		; Exit loop if Index found	
			BRA $3B66		; Loop until timeout	
						
			RET R2			
						
						
						
						
						
						
			LBI R10, #$FF			
			BRA $3B7E		; $02(R0)	
						
						
						
						
						
						
			LBI R10, #$00			
						
			MOVE R4, $D8			
			SUB R4, #$10			
			MOVE R5, (R3)		; IOCB_Sub in Lo(R5)	
			ADD R5, R5		; Shift left one position	
			SNZ R5			
			BRA $3B8E		; Finished	
			ADD R4, #$01			
			BRA $3B84		; Loop	
						
			SS R10			
			BRA $3B96			
						
			MOVB R11, (R4)		; Get value	
			RET R2			
						
			MOVB (R4), R11		; Set value	
			RET R2			
						
						
						
						
						
						
			MOVE $82, R2		; Save R2	
						
			CTRL $D, #$01		; Reset R/W/D	
			LBI R1, #$08			
			GETB R5, $D		; Access Sense byte	
			SBC R5, R1		; Heads engaged ?	
			BRA $3BAA		; Yes	
						
			INC2 R2, R0			
			BRA $3C30		; Engage heads	
						
			LBI R9, #$44			
			MLH R9, R9			
			LBI R9, #$66		; R9 <- $4466	
						
			MOVE R4, $A0			
			LBI R4, #$16		; Buffer address (R11L0)	
			MOVE $48, R4		; R4L2 <- $0016	
						
			MOVE R15, $A0			
			LBI R15, #$04		; Read 4 bytes	
			MOVE $5E, R15		; R15L2 <- $0004	
						
			MOVE R7, $A0		; Clear flag	
			MOVE $54, R7		; R10L2 <- $0000	
						
			LBI R7, #$3C			
			MLH R7, R7			
			LBI R7, #$5E		; Address of Int 2 routine	
			MOVE $40, R7		; R0L2 <- $3C5E	
						
			LBI R6, #$00			
			MOVE $4C, R6		; R6L2 <- $00	
						
			CTRL $4, #$43		; Int 3 off	
			CTRL $D, #$40		; Start Read	
			CTRL $4, #$4B		; (?)	
			INC2 R2, R0			
			BRA $3C12		; Wait for data or timeout	
						
			MOVE R5, $4A		; R5L2	
			LBI R1, #$FE		; ID address mark	
			SNE R5, R1		; Correct address mark ?	
			BRA $3BE2		; Yes	
						
			CTRL $D, #$01		; Reset R/W/D	
			BRA $3BB0		; Restart	
						
			; ID address mark found			
						
			LBI R9, #$00			
			MLH R9, R9			
			LBI R9, #$33		; R9 <- $0033	
						
			; Rest of ID field is read automatically			
						
			MOVE R7, $A0			
			MOVE $54, R7		; R10L2 <- $0000	
			CTRL $4, #$4B			
			INC2 R2, R0			
			BRA $3C12		; Wait for data or timeout	
						
			STAT R5, $D		; Diskette Status byte	
			LBI R1, #$01			
			SBS R5, R1		; R/W Overrun ?	
			BRA $3C00		; No	
						
			CTRL $D, #$01		; Reset R/W/D	
			LBI R6, #$22		; Error 32	
			BRA $3C54			
						
			LBI R6, #$00			
			LBI R1, #$02			
			SBC R5, R1		; CRC Error ?	
			LBI R6, #$80		; Yes	
						
			; R11 and R12 contain the 4 data bytes			
			; from the ID field			
						
			MOVE R14, R12		; R14 <- 4th byte	
			MHL R13, R14		; R13 <- 3rd byte	
			MOVE R12, R11		; R12 <- 2nd byte	
			MHL R11, R12		; R11 <- 1st byte	
						
			JMP ($0082)		; Return to caller	
						
						
			; Wait for data byte to arrive from diskette			
			; or timeout			
						
			SUB R9, #$01		; Decrement loop counter	
			LBI R1, #$80			
			SNBSH R9, R1			
			BRA $3C22		; Timeout	
						
			MOVE R7, $54		; R10L2	
			SS R7			
			BRA $3C12		; Loop	
			RET R2			; Data byte arrived, return
						
			STAT R5, $D		; Diskette Sense byte	
			LBI R1, #$01			
			SBC R5, R1		; R/W Overrun ?	
			BRA $3BFA		; Yes, error 32	
						
			CTRL $D, #$01			
			LBI R6, #$38		; Error 21	
			BRA $3C54			
						
						
						
						
						
						
			GETB R5, $D		; Access Sense byte	
			CLR R5, #$80		; Don't reset New Media	
			SET R5, #$08		; Engage Head	
			MOVE R4, $A0			
			LBI R4, #$0B			
			PUTB $D, (R4)			
						
			; Delay until heads engaged			
						
			LBI R9, #$31			
			MLH R9, R9			
			LBI R9, #$B0		; R9 <- $31B0	
			SUB R9, #$01			
			LBI R1, #$80			
			SBSH R9, R1			
			BRA $3C42		; Loop	
						
			GETB R5, $D		; Access Sense byte	
			LBI R1, #$08			
			SNBS R5, R1		; Heads engaged ?	
			RET R2			; Yes, OK and return
						
			; Heads still not engaged, error			
						
			LBI R6, #$20		; Error 33	
						
			LBI R1, #$3E			
			MLH R1, R1			
			LBI R1, #$FA			
			INC2 R2, R0			
			RET R1			
						
						
						
						
						
						
						
			STAT R5, $D		; Diskette Sense byte	
			LBI R1, #$40			
			MOVE R7, R5			
			CLR R5, #$16			
			SE R5, R1		; Read Mode ?	
			BRA $3CF6		; No, error 35	
						
			LBI R10, #$FF		; New byte ready	
			GETB R5, $D		; Get data byte (Address Mark)	
			; Exit from interrupt routine because			
			; GETB resets IRQ2 line			
						
			CTRL $4, #$47		; (?)	
			BRA $3C71		; Delay jump	
						
			SUB R15, #$03			
			LBI R8, #$80			
			GETB R7, $D		; Get first data byte	
			; Exit from interrupt routine because			
			; GETB resets IRQ2 line			
						
			SZ R6			
			BRA $3CBA		; $3E(R0)	
						
			; Read			
						
			MOVB (R4)+, R7		; Store first data byte	
			MOVE R9, R7		; Save first data in R9	
			SUB R15, #$01			
			SNBSH R15, R8			
			BRA $3C90		; $0A(R0)	
						
			GETB R7, $D		; Get data byte	
			MOVB (R4)+, R7		; Store data byte	
			SUB R15, #$01		; Decrement byte counter	
			SBSH R15, R8		; Done ?	
			BRA $3C86		; No, loop	
						
			CTRL $D, #$04		; Read CRC	
			NOP			
			GETB R7, $D		; Get n-1 th data byte	
			BRA $3C97			
			NOP			
			MOVB (R4)+, R7		; Store it	
			GETB R7, $D		; Get n'th data byte	
			BRA $3C9F			
			MOVB (R4)+, R7		; Store it	
			NOP			
			GETB R7, $D		; CRC byte 1	
			BRA $3CA7			
			NOP			
			LBI R10, #$FF		; Set done flag	
			CTRL $4, #$47			
			GETB R7, $D		; CRC byte 2	
						
			; Read gap bytes until interrupted			
						
			MOVE R15, $A0			
			ADD R15, #$01		; Count number of gap bytes read	
			BRA $3CB5		; Delay	
			GETB R7, $D			
			BRA $3CB2		; Loop	
						
						
						
			MOVE R9, R7			
			MOVB R1, (R4)+			
			SE R7, R1			
			BRA $3CE8		; $26(R0)	
						
			SUB R15, #$01			
			GETB R7, $D			
			MOVB R1, (R4)+			
			SE R7, R1			
			BRA $3CE8		; $1C(R0)	
						
			SUB R15, #$01			
			SBSH R15, R8			
			BRA $3CC4		; -> -$0E(R0)	
						
			CTRL $D, #$04			
			NOP			
			GETB R7, $D			
			MOVB R1, (R4)+			
			SE R7, R1			
			BRA $3CE8		; $0A(R0)	
						
			BRA $3CDF		; -> -$01(R0)	
						
			GETB R7, $D			
			MOVB R1, (R4)			
			SNE R7, R1			
			BRA $3CA2		; -> -$46(R0)	
						
			CTRL $0, #$3F			
			CTRL $D, #$01			
			LBI R5, #$3D			
			MLH R5, R5			
			LBI R5, #$DE			
			MOVE $00, R5			
			CTRL $0, #$5F			
						
			; Error			
						
			LBI R5, #$3D			
			MLH R5, R5			
			LBI R5, #$00			
			MOVE $00, R5			
			CTRL $D, #$01			
						
						
			; This is executed at level 0			
						
			MOVE R7, $4E			
			GETB R5, $D			
			MLH R5, R7			
			MOVE $E8, R5		; Set Diskette Status Byte	
			LBI R6, #$1C		; Error 35	
			BRA $3C54		; Error routine	
						
						
						
						
						
						
			MOVE $82, R2		; Save R2	
						
			CTRL $D, #$01		; Reset R/W/D	
						
			; Check bounds of R15 (track counter)			
						
			LBI R1, #$51			
			SLE R15, R1			
			LBI R15, #$4E			
			MOVE R7, R15			
						
			GETB R5, $D		; Access Sense byte	
			MOVE R6, R5			
						
			; Generate next Access Lines pattern			
						
			CLR R5, #$FC		; Mask Access Lines	
			MOVE R8, R5			
			LBI R1, #$03			
			XOR R8, R1		; Invert Access Line bits	
			ROR3 R8			
			ROR3 R8			; Move them to bits 4 and 5
			OR R5, R8		; Insert original bits 6 and 7	
						
			SZ R10			
			BRA $3D32		; $04(R0)	
						
			ROR R5			
			BRA $3D3A		; $08(R0)	
						
			MOVE R8, R5			
			SWAP R8			
			OR R5, R8			
			ROR3 R5			
						
			; Send new Access Lines pattern to adapter			
						
			CLR R5, #$FC			
			CLR R6, #$03			
			OR R5, R6			
			MOVE R4, $A0			
			LBI R4, #$0B		; Lo(R5L0)	
			PUTB $D, (R4)			
						
			LBI R9, #$03			
			MLH R9, R9			
			LBI R9, #$1B		; R9 <- $031B	
			SUB R9, #$01			
			LBI R1, #$80			
			SBSH R9, R1			
			BRA $3D4C		; Delay loop	
						
			SUB R7, #$01		; Decrement track counter	
			SZ R7			; Finished ?
			BRA $3D18		; No, loop	
						
			JMP ($0082)		; Return to caller	
						
						
						
						
						
						
						
			MOVE $82, R2		; Save R2	
						
			LBI R9, #$00			
			MLH R9, R9			
			LBI R9, #$67		; Timeout value	
						
			MOVE $4C, R6		; R6L2	
			MOVE R15, $A0			
			LBI R1, #$03			
			SLT R14, R1			
			LBI R14, #$04			
			MLH R15, R14			
			SNZ R14			
			LBI R15, #$80			
						
			LBI R8, #$14		; 20 gap bytes (MFM)	
			MOVE R5, $90			
			LBI R1, #$10			
			SBS R5, R1		; MFM ?	
			LBI R8, #$0A		; No, then 10 gap bytes (FM)	
						
			; Skip over some gap bytes			
						
			SUB R9, #$01			
			LBI R1, #$80			
			SNBSH R9, R1			
			BRA $3E14		; Error 21	
						
			MOVE R5, $5E		; R15L2 (number of gap bytes)	
			SGE R5, R8			
			BRA $3D7E		; Loop	
						
			CTRL $D, #$01		; Reset R/W/D	
			MOVE R8, $A0			
			MOVE $54, R8		; Clear flag (R10L2)	
			MOVE $48, R4		; Buffer address (R4L2)	
			MOVE $5E, R15		; Number of bytes (R15L2)	
			LBI R8, #$3C			
			MLH R8, R8			
			LBI R8, #$5E			
			MOVE $40, R8		; Int 2 routine (R0L2)	
			MOVE R6, $A0			
			CTRL $D, #$40		; Start Read	
			CTRL $4, #$4B			
			INC2 R2, R0			
			BRA $3DE4		; Wait for data byte	
						
			MOVE R5, $4A		; R5L2	
			LBI R1, #$F8			
			SE R5, R1		; Deleted Data Address Mark ?	
			BRA $3DB4		; No	
						
			LBI R6, #$20		; Set flag for DDAM	
			BRA $3DBC			
						
			LBI R1, #$FB			
			SNE R5, R1		; Normal Data Address Mark ?	
			BRA $3DBC		; Yes	
			BRA $3D8C		; No, ignore and retry	
						
			; Read data field			
						
			LBI R9, #$07			
			MLH R9, R9			
			LBI R9, #$3E			
			CTRL $4, #$4B			
			MOVE R8, $A0			
			MOVE $54, R8		; Clear flag (R10L2)	
			INC2 R2, R0			
			BRA $3DE4		; Wait until all data read	
						
			STAT R5, $D		; Diskette Sense Byte	
			CTRL $D, #$01		; Reset R/W/D	
			LBI R1, #$01			
			SBS R5, R1		; R/W Overrun ?	
			BRA $3DDA		; No	
						
			LBI R6, #$22		; Error 32	
			BRA $3E10		; Exit	
						
			LBI R1, #$02			
			SBC R5, R1		; CRC error ?	
			SET R6, #$80		; Set flag for CRC error	
						
			CTRL $4, #$4A			
			JMP ($0082)		; Return to caller	
						
						
			SUB R9, #$01			
			LBI R1, #$80			
			SNBSH R9, R1			
			BRA $3DF4			
						
			MOVE R7, $54			
			SS R7			
			BRA $3DE4			
			RET R2			
						
			LBI R1, #$01			
			STAT R5, $D			
			SBC R5, R1			
			BRA $3DCE			
						
			CTRL $D, #$01			
			MOVE R5, $A2			
			LBI R1, #$80			
			SNBSH R5, R1			
			BRA $3E0E		; Error 22	
						
			MOVE R5, $94			
			LBI R1, #$09			
			SGE R5, R1			
			BRA $3DDE			
						
			; Error 22			
			LBI R6, #$36			
						
			; Error exit			
			INC2 R2, R0			
			BRA $3EFA			
						
			; Error 21			
			LBI R6, #$38		; Error 21	
			CTRL $D, #$01		; Reset R/W/D	
			BRA $3E10		; Exit	
						
						
						
			LBI R9, #$07			
			MLH R9, R9			
			LBI R9, #$3E			
						
			; Setup level 2 registers			
			MOVE $48, R4		; R4L2	
			MOVE $4C, R6		; R6L2	
			MOVE R15, $A0			
			LBI R1, #$03			
			SLT R14, R1			
			LBI R14, #$04			
			MLH R15, R14			
			SNZ R14			
			LBI R15, #$80			
			MOVE $5E, R15		; R15L2	
			MOVE R8, $A0			
			MOVE $54, R8		; R10L2	
						
			CTRL $D, #$80		; Start Write	
						
			SUB R9, #$01			
			LBI R1, #$80			
			SNBSH R9, R1			
			BRA $3E56			
			MOVE R7, $54		; R10L2	
			SS R7			
			BRA $3E3A			
						
			STAT R5, $D		; Write overrun?	
			LBI R1, #$01			
			SBS R5, R1			
			BRA $3E64			
			CTRL $D, #$01		; Yes, reset write	
			LBI R6, #$22			
			BRA $3E10		; Error ..	
						
			LBI R1, #$01			
			STAT R5, $D			
			SBC R5, R1			
			BRA $3E50		; Write overrun	
						
			CTRL $D, #$01			
			LBI R6, #$34			
			BRA $3E10			
						
			LBI R1, #$08			
			SBS R5, R1			
			BRA $3E6E			
						
			CTRL $4, #$4A			
			RET R2			
						
			LBI R6, #$1E			
			BRA $3E10			
						
						
						
			CTRL $4, #$4B			
						
			; Write sync field			
			MOVE R7, $A0			
			LBI R7, #$0C			
			LBI R8, #$00			
			MLH R8, R8			
			LBI R8, #$A0			
			PUTB $D, (R8)			
			SUB R7, #$01			
			SZ R7			
			BRA $3E7E			
						
			; Write address mark			
			CTRL $D, #$02		; Write Address Mark	
			LBI R5, #$A1		; Address Mark byte	
			LBI R8, #$4B		; Lo(R5L2)	
			PUTB $D, (R8)		; .. first	
			BRA $3E8F			
			BRA $3E91			
			PUTB $D, (R8)		; .. second	
			BRA $3E95			
			BRA $3E97			
			PUTB $D, (R8)		; .. third	
			BRA $3E9B			
						
			CTRL $D, #$08		; Turn on Erase Gate	
			LBI R8, #$4D		; Lo(R6L2)	
			PUTB $D, (R8)		; .. and last	
			BRA $3EA3			
						
			; Write ID field			
			LBI R8, #$80			
			SUB R15, #$01			
			PUTB $D, (R4)+			
			NOP			
			SUB R15, #$01			
			SBSH R15, R8			
			BRA $3EA8			
						
			; Write two CRC bytes			
			CTRL $D, #$0C		; Write CRC	
			NOP			
			PUTB $D, (R4)		; CRC byte 1	
			BRA $3EB9			
			CTRL $D, #$0C			
			BRA $3EBD			
			PUTB $D, (R4)		; CRC byte 2	
						
			MOVE R4, $A0			
			LBI R4, #$5E		; R15L0	
			CTRL $D, #$08		; CRC off	
			BRA $3EC7			
			PUTB $D, (R4)			
			NOP			
						
			LBI R10, #$FF		; Set Done flag	
						
			; Finished			
			CTRL $4, #$47			
			BRA $3ED1			
			BRA $3ED3			
						
			CTRL $D, #$09		; Reset Write; keep Erase Gate	
			HALT			
						
						
						
			CTRL $4, #$4B			
			MOVE R7, $A0			
			LBI R7, #$06			
			LBI R8, #$00			
			MLH R8, R8			
			LBI R8, #$A0			
			PUTB $D, (R8)			
			SUB R7, #$01			
			NOP			
			SZ R7			
			BRA $3EE4			
						
			CTRL $D, #$02		; Write Address Mark	
			LBI R8, #$4D			
			PUTB $D, (R8)			
			BRA $3EF5			
						
			CTRL $D, #$08		; Erase Gate	
			BRA $3EA4			
						
						
			; Diskette Error Routine			
						
			MOVE $80, R2		; Save R2	
			CTRL $4, #$4A		; Enable Int 3	
						
			LBI R7, #$F0			
			MLH R7, R7		; R7 <- $F0F0	
			ADD R0, R6			
			ADD R7, #$01		; F0F1	
			ADD R7, #$01		; F0F2	
			ADD R7, #$01		; ...	
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01		; F0F8	
			ADD R7, #$01		; F0F9	
			ADD R7, #$F7		; F1F0	
			ADD R7, #$01		; F1F1	
			ADD R7, #$01		; ...	
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$F7		; F2F0	
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$F7		; F3F0	
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$F7		; F4F0	
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01			
			ADD R7, #$01		; F4F9	
						
			MOVE R4, R3			
			ADD R4, #$0C		; IOCB_Ret	
			MOVE (R4), R7		; Set return code	
			INC2 R4, R3			
			MOVB R5, (R4)		; IOCB_Cmd	
						
			LBI R1, #$40			
			SE R6, R1		; Error 17 ?	
			BRA $3F8C		; No	
						
			LBI R1, #$00			
			SNE R5, R1		; Sense ?	
			BRA $3F88		; Yes	
						
			LBI R1, #$04			
			SNE R5, R1		; Find ?	
			BRA $3F88		; Yes	
						
			LBI R1, #$05			
			SE R5, R1		; Mark ?	
			BRA $3F8C		; No	
						
			; Error 17 while Sense, Find or Mark			
			LBI R6, #$44		; Set to error 15	
			BRA $3EFE			
						
			LBI R1, #$34			
			SGE R6, R1		; Error <= 23 (<= is correct)	
			BRA $3FA2		; No	
						
			LBI R1, #$44			
			SLE R6, R1			
			BRA $3FA2		; $0A(R0)	
						
			LBI R1, #$3A			
			MLH R1, R1			
			LBI R1, #$DC			
			INC2 R2, R0			
			RET R1			
						
			LBI R1, #$16			
			SE R6, R1		; Error 38 ?	
			BRA $3FB6		; No	
						
			LBI R1, #$05			
			SE R5, R1		; Mark ?	
			BRA $3FB6		; No	
						
			MOVE R4, R3			
			ADD R4, #$0E		; IOCB_CI2	
			MOVE R7, $F6			
			MOVE (R4), R7			
						
			LBI R1, #$60			
			SNE R6, R1		; Error 01 ?	
			BRA $3FCE		; Yes	
						
			LBI R1, #$08			
			SNE R6, R1		; Error 45 ?	
			BRA $3FCE		; Yes	
						
			LBI R1, #$22			
			SLE R6, R1		; Error >= 32 (>= is correct)	
			BRA $3FDA		; No	
						
			LBI R1, #$1C			
			SGE R6, R1		; Error <= 35	
			BRA $3FDA		; No	
						
			; Reset adapter			
						
			GETB R8, $D		; Access Sense byte	
			CLR R8, #$88		; Clear New Media/Head Engage	
			CTRL $D, #$01		; Reset R/W/D	
			MOVE R4, $A0			
			LBI R4, #$11		; Lo(R8)	
			PUTB $D, (R4)			
						
			; Exit from Diskette I/O Supervisor			
						
			LBI R1, #$21			
			MLH R1, R1			
			LBI R1, #$18			
			RET R1			; JMP $2118
			HALT			
			HALT			
						
						
						
						
			LBI R1, #$02			
			MLH R1, R1			
			LBI R1, #$02			
			MOVE $1C2, R1		; $1C2 <- $0202	
						
			; Put address of diskette I/O supervisor routine			
			; into vector table (entry for system device D)			
			LBI R1, #$20			
			MLH R1, R1			
			LBI R1, #$00			
			MOVE R4, $D8			
			ADD R4, #$34			
			MOVE (R4), R1			
						
			; Return to caller			
			MOVE R8, R2			
			JMP ($00AC)			
						
			; Entry point for setup routine			
			BRA $3FE6			
						
						
						
						
						
						
						
						
						
						
						
						
			MOVE R4, $D8		; vector for device 0	
			MOVE R5, (R4)			
			MHL R6, R5			
			OR R6, R5			
			SZ R6			
			BRA $4014		; vector already set	
						
			; Set vector for device 0 ($41DC)			
			LBI R5, #$41			
			MLH R5, R5			
			LBI R5, #$DC			
			MOVE (R4), R5			
						
			ADD R4, #$10		; vector for device 4	
			MOVE R5, (R4)			
			MHL R6, R5			
			OR R6, R5			
			SZ R6			
			BRA $4028		; vector alreadz set	
						
			; Set vector for device 4 ($4334)			
			LBI R5, #$43			
			MLH R5, R5			
			LBI R5, #$34			
			MOVE (R4), R5			
						
			LBI R1, #$48			
			MLH R1, R1			
			LBI R1, #$14			
			MOVE $C2, R1			
						
			LBI R1, #$48			
			MLH R1, R1			
			LBI R1, #$3A			
			MOVE $C0, R1			
						
			MOVE R4, $A4			
			MHL R5, R4			
			CLR R5, #$04			
			MOVE R7, $1F8			
			LBI R6, #$20			
			SBS R7, R6			
			SET R5, #$04			
			MLH R4, R5			
			MOVE $A4, R4			
						
			LBI R4, #$41			
			MLH R4, R4			
			LBI R4, #$4E			
			MOVE $C4, R4			
						
			; Initialization done, change entry point of			
			; supervisor routine			
			LBI R1, #$40			
			MLH R1, R1			
			LBI R1, #$5A			
			MOVE $AE, R1			
						
						
						
						
						
						
						
			MOVE R1, $BE			
			SUB R1, #$12			
			MOVE R4, (R1)			
			SZ R4			
			BRA $406C		; $08(R0)	
						
			LBI R4, #$00			
			MLH R4, R4			
			LBI R4, #$14			
			MOVE (R1), R4			
						
			CTRL $0, #$3F		; Disable Interrupts	
			MOVE R4, $A4			
			SET R4, #$02		; in Exec-ROS (?)	
			MOVE $A4, R4			
			CTRL $0, #$5F		; Enable Interrupts	
						
			CTRL $1, #$02		; Select Common ROS	
			CTRL $4, #$4A		; Typamatic off / Int 3 on	
						
			MOVE $B6, R2		; Save return address	
			MOVE R13, R3		; Ptr to IOCB in R13	
						
			LBI R1, #$01			
			SBSH R4, R1		; Test CRT status	
			BRA $40B6		; CRT off -> jump	
			CTRL $0, #$77		; Turn CRT on (as told)	
						
			LBI R1, #$02			
			SNBSH R4, R1		; Is I/O active ?	
			BRA $40B8		; Yes -> jump	
						
			MOVE R4, $A2			
			LBI R1, #$10			
			SBS R4, R1		; Should call be HOLDed ?	
			BRA $40B8		; No	
						
			; HOLD			
			MOVE R5, $B0			
			MHL R5, R5			
			SET R5, #$40			
			MLH R5, R5			
			CLR R5, #$FF			
			MOVE $B0, R5			
						
			LBI R1, #$40			
			MLH R1, R1			
			LBI R1, #$B8		; R1 <- $40B8	
			MOVE R5, $BE			
			ADD R5, #$20		; R5 <- $0720 (temp area)	
			MOVE (R5)++, R1		; \	
			MOVE (R5)+, R2		;  > Save registers	
			MOVE (R5), R3		; /	
			MOVE R8, $FC		; Address of HOLD routine	
			INC2 R2, R0			
			JMP ($00AC)		; HOLD	
						
						
			CTRL $0, #$6F		; Turn CRT off	
						
			MOVE R13, R3		; Ptr to IOCB to R13	
						
			ADD R13, #$0C		; IOCB_Ret	
			MOVE R4, $A0			
			MOVE (R13), R4		; Clear error code	
						
			SUB R13, #$0C		; IOCB_DA	
			MOVB R4, (R13)			
			LBI R1, #$F0			
			SBC R4, R1		; Is DA >= $10 (invalid)	
			BRA $40EC		; Yes -> Error	
						
			MOVE R8, $C4			
			INC2 R2, R0			
			JMP ($00AC)			
			BRA $40FC		; $2A(R0)	
						
			MOVE R13, R3			
			MOVB R4, (R13)		; IOCB_DA	
			MOVE R5, $D8			
			ADD R4, R4			
			ADD R4, R4			
			ADD R5, R4			
			MOVE R4, (R5)+			
			MHL R6, R4			
			AND R6, R4			
			SNS R6			
			BRA $40F6		; $0E(R0)	
						
			MHL R6, R4			
			SNZ R6			
			BRA $41D0		; Error 13	
						
			MOVE R8, $08		; R8 <- R4L0	
			INC2 R2, R0			
			JMP ($00AC)		; Call I/O routine for device	
			BRA $40FC		; $06(R0)	
						
			MOVE R8, (R5)			
			INC2 R2, R0			
			JMP ($00CE)			
						
						
			MOVE R4, $A4			
			LBI R1, #$01			
			SBSH R4, R1			
			BRA $414A		; $46(R0)	
						
			CTRL $0, #$77			
			LBI R1, #$02			
			SNBSH R4, R1			
			BRA $4136		; $2A(R0)	
						
			MOVE R4, $A2			
			LBI R1, #$10			
			SBS R4, R1			
			BRA $4136		; $22(R0)	
						
			MOVE R5, $B0			
			MHL R5, R5			
			SET R5, #$40			
			MLH R5, R5			
			CLR R5, #$FF			
			MOVE $B0, R5			
			LBI R1, #$41			
			MLH R1, R1			
			LBI R1, #$36			
			MOVE R5, $BE			
			ADD R5, #$20			
			MOVE (R5)++, R1			
			MOVE (R5)+, R2			
			MOVE (R5), R3			
			MOVE R8, $FC			
			INC2 R2, R0			
			JMP ($00AC)			
						
			MOVE R13, R3			
			MOVE R2, $B6			
			CTRL $4, #$4A			
			CTRL $0, #$3F			
			MOVE R4, $A4			
			CLR R4, #$02			
			MOVE $A4, R4			
			CTRL $0, #$5F			
			MOVE R8, R2			
			JMP ($00AC)			
						
			CTRL $0, #$6F			
			BRA $4136		; -> -$18(R0)	
						
						
			MOVE R13, R3		; Ptr to IOCB to R13	
			ADD R13, #$10		; IOCB_Stat1	
			MOVE R4, (R13)			
			SUB R13, #$10			
						
			LBI R5, #$0C			
			SNBC R4, R5			
			BRA $41C6		; Return	
						
			LBI R1, #$04			
			SBS R4, R1			
			BRA $41CC		; R5 <- $04	
			LBI R5, #$08			
						
			MOVE R1, $BE			
			SUB R1, #$12			
			MOVE R7, (R1)			
						
			; Busy wait until printer ready or timeout			
			LBI R9, #$90			
			MLH R9, R9			
			LBI R9, #$00		; R9 <- $9000	
			MOVE R6, $A4			
			SBS R6, R5		; Check printer status	
			BRA $418C		; Printer ready	
			LBI R1, #$FF			
			SUB R9, #$01			
			SBSH R9, R1			
			BRA $4170		; Loop	
			SUB R7, #$01			
			MHL R10, R7			
			SZ R10			
			BRA $416A		; Loop	
			SZ R7			
			BRA $416A		; Loop	
			BRA $41BA		; Error 70	
						
			; Printer ready			
			LBI R1, #$02			
			SBS R4, R1			
			BRA $41C6		; Exit	
						
			LBI R5, #$0C			
			MOVE R1, $BE			
			SUB R1, #$12			
			MOVE R7, (R1)			
			LBI R9, #$90			
			MLH R9, R9			
			LBI R9, #$00		; R9 <- $9000	
			MOVE R6, $A4			
			SBS R6, R5			
			BRA $41C6		; Exit	
			LBI R1, #$FF			
			SUB R9, #$01			
			SBSH R9, R1			
			BRA $41A0		; -> -$0E(R0)	
			SUB R7, #$01			
			MHL R10, R7			
			SZ R10			
			BRA $419A		; -> -$1C(R0)	
			SZ R7			
			BRA $419A		; -> -$20(R0)	
						
			LBI R6, #$F7			
			MLH R6, R6			
			LBI R6, #$F0		; R6 <- '70'	
			ADD R13, #$0C		; IOCB_Ret	
			MOVE (R13), R6			
			BRA $41C8		; Error	
						
			ADD R2, #$02		; OK return	
						
			MOVE R8, R2			
			JMP ($00AC)		; Return	
						
						
			LBI R5, #$04			
			BRA $4164		; -> -$6C(R0)	
						
						
						
						
						
			LBI R6, #$F1			
			MLH R6, R6			
			LBI R6, #$F3		; R6 <- '13'	
			ADD R13, #$0C		; IOCB_Ret	
			MOVE (R13), R6		; Set error code	
			BRA $40FC			
						
						
						
						
						
						
						
			MOVE $B2, R2		; Save R2	
			CTRL $4, #$43		; Disable Int 3	
						
			MOVE R13, R3			
			MOVE R4, (R13)+			
			MOVB R4, (R13)+			
			CLR R4, #$F0		; IOCB_Cmd	
						
			MOVB R6, (R13)---	; IOCB_Flags		
			CLR R6, #$F0			
						
			ADD R4, R4			
			ADD R0, R4			
			BRA $42A2		; Screen on	
			BRA $4224		; Screen off	
			BRA $426E		; Scroll up	
			BRA $4234		; Scroll down	
			BRA $4210		; Clear screen	
			BRA $42C4		; Alarm on	
			BRA $42C8		; Alarm off	
			BRA $42CC		; Beep	
			BRA $42E0		; (?)	
			BRA $42B6		; invalid	
			BRA $42B6		; invalid	
			BRA $42B6		; invalid	
			BRA $42B6		; invalid	
			BRA $42B6		; invalid	
			BRA $42B6		; invalid	
			BRA $42B6		; invalid	
						
			; Clear screen			
						
			LBI R4, #$02			
			MLH R4, R4			
			LBI R4, #$00		; R4 <- $0200	
			LBI R5, #$40			
			MLH R5, R5		; R5 <- $4040	
			LBI R6, #$06		; End address (high byte)	
			MOVE (R4)+, R5			
			SBSH R4, R6			
			BRA $421C		; Loop	
			BRA $42B0		; Exit	
						
			; Screen off			
						
			CTRL $0, #$2F		; Disable Ints / Screen off	
			MOVE R4, $A4			
			MHL R5, R4			
			CLR R5, #$01		; Clear CRT on flag	
			MLH R4, R5			
			MOVE $A4, R4			
			CTRL $0, #$5F		; Enable Ints	
			BRA $42B0		; Exit	
						
			; Scroll down			
						
			LBI R4, #16			
			SUB R4, R6		; Line counter	
						
			LBI R5, #$06			
			MLH R5, R5			
			LBI R5, #$3E		; R5 <- $063E	
						
			SUB R5, #$40		; Calc start address	
			SUB R6, #1			
			SS R6			
			BRA $423E		; Loop	
						
			MOVE R6, R5		; R5 = current line	
			SUB R6, #$40		; R6 = previous line	
						
			SUB R4, #1		; Decrement line counter	
			SNZ R4			
			BRA $425E			
						
			LBI R7, #$20		; 32 words per line	
			MOVE R1, (R6)-		; copy word from previous line	
			MOVE (R5)-, R1		; ... to current line	
			SUB R7, #1		; Decrement word counter	
			SZ R7			
			BRA $4252			
			BRA $424A			
						
			; Clear line 0			
			LBI R6, #$40			
			MLH R6, R6		; R6 <- $4040	
			LBI R7, #$20		; 32 words	
			MOVE (R5)-, R6			
			SUB R7, #1			
			SZ R7			
			BRA $4264			
						
			BRA $42A2		; Screen on and exit	
						
			; Scroll up			
						
			LBI R1, #15		; Lines to scroll	
						
			LBI R5, #$02			
			MLH R5, R5			
			LBI R5, #$00		; R5 <- $0200 (current line)	
						
			LBI R4, #$02			
			MLH R4, R4			
			LBI R4, #$40		; R4 <- $0240 (next line)	
						
			SNE R6, R1			
			BRA $4296		; No lines to scroll	
			; Should jump to 4294 or 42A2 instead!!			
						
			LBI R7, #$20		; 32 words	
			MOVE R1, (R4)+		; copy word from next line	
			MOVE (R5)+, R1		; ... to current line	
			SUB R7, #1			
			SZ R7			
			BRA $4282			
						
			ADD R6, #1			
			LBI R1, #15			
			SE R6, R1			
			BRA $4280			
						
			; Clear bottom line			
			LBI R7, #$20		; 32 words	
			LBI R4, #$40			
			MLH R4, R4			
			MOVE (R5)+, R4			
			SUB R7, #1			
			SZ R7			
			BRA $429A			
						
			; Screen on			
						
			CTRL $0, #$37		; Disable Ints / Screen on	
			MOVE R4, $A4			
			MHL R5, R4			
			SET R5, #$01		; Set Screen on flag	
			MLH R4, R5			
			MOVE $A4, R4			
			CTRL $0, #$5F		; Enable Ints	
						
			; Exit			
						
			MOVE R2, $B2		; Restore R2	
			MOVE R8, R2			
			JMP ($00AC)		; Return to caller	
						
			; Error			
						
			LBI R4, #$F0			
			MLH R4, R4			
			LBI R4, #$F2		; R4 <- '02'	
			MOVE R13, R3			
			ADD R13, #$0C		; IOCB_Ret	
			MOVE (R13), R4		; Set error code	
			BRA $42A2		; Screen on and return	
						
			; Alarm on			
						
			CTRL $0, #$7E			
			BRA $42B0		; Exit	
						
			; Alarm off			
						
			CTRL $0, #$7D			
			BRA $42B0		; Exit	
						
			; Beep			
						
			CTRL $0, #$7E			
			LBI R9, #$80			
			MLH R9, R9			
			LBI R9, #$00		; R9 <- $8000	
			LBI R1, #$FF			
			SUB R9, #1			
			SBSH R9, R1			
			BRA $42D4		; Delay loop	
			CTRL $0, #$7D			
			BRA $42B0		; Exit	
						
			; (?)			
						
			MOVE R5, $A2			
			LBI R1, #$04			
			SBS R5, R1			
			BRA $4304		; $1C(R0)	
						
			ADD R13, #$10		; IOCB_Stat1	
			MOVE R5, (R13)			
			SET R5, #$04			
			MOVE (R13), R5			
						
			MOVE R8, $C4			
			INC2 R2, R0			
			JMP ($00AC)			
			BRA $4328		; $30(R0)	
						
			MOVE R13, R3			
			ADD R13, #$10		; IOCB_Stat1	
			MOVE R5, (R13)			
			CLR R5, #$04			
			MOVE (R13), R5			
			SUB R13, #$10			
						
			ADD R13, #$08		; IOCB_CI1	
			MOVB R4, (R13)			
			LBI R1, #$0F			
			SBC R4, R1			
			BRA $42B6		; Error	
						
			LBI R1, #$F0			
			SNBS R4, R1			
			BRA $42B6		; Error	
						
			; R4 = $x0 with x>0			
			LBI R1, #$00			
			MLH R1, R1			
			LBI R1, #$B1		; R1 <- $00B1	
			MOVB (R1), R4			
						
			CTRL $4, #$43		; Disable Int 3	
			MOVE R8, $E6			
			INC2 R2, R0			
			JMP ($00AC)			
			NOP			
			BRA $42B0		; Exit	
						
						
			MOVE R13, R3			
			ADD R13, #$10		; IOCB_Stat1	
			MOVE R5, (R13)			
			CLR R5, #$04			
			MOVE (R13), R5			
						
			BRA $42B0		; Exit	
						
						
						
						
						
			CTRL $0, #$77		; Display On	
			MOVE $B4, R2		; Save R2	
						
			MOVE R13, R3		; IOCB	
			ADD R13, #$02			
			MOVB R4, (R13)--	; IOCB_Cmd		
			LBI R1, #$01			
			SNE R4, R1			
			BRA $437E			
						
			LBI R1, #$40			
			SNE R4, R1			
			BRA $4364		; $1A(R0)	
						
			LBI R1, #$41			
			SNE R4, R1			
			BRA $4368		; $18(R0)	
						
			; Error 02			
			MOVE R13, R3			
			ADD R13, #$0C		; IOCB_Ret	
			LBI R1, #'0'			
			MLH R1, R1			
			LBI R1, #'2'			
			MOVE (R13), R1			
			LBI R1, #$43			
			MLH R1, R1			
			LBI R1, #$EC			
			RET R1			
						
			; Command $40			
						
			LBI R4, #$0C			
			BRA $436A		; $02(R0)	
						
			; Command $41			
						
			LBI R4, #$0D			
						
			LBI R1, #$00			
			MLH R1, R1			
			LBI R1, #$B1			
			MOVB (R1), R4			
			CTRL $4, #$43			
			MOVE R8, $E6			
			INC2 R2, R0			
			JMP ($00AC)			
			NOP			
						
			; Return			
			BRA $43EC		; $6E(R0)	
						
			; Command 1			
						
			MOVE R4, $A2			
			LBI R1, #$04			
			SNBC R4, R1			
			BRA $4394		; $0E(R0)	
						
			CLR R4, #$04			
			MOVE $A2, R4			
			LBI R1, #$49			
			MLH R1, R1			
			LBI R1, #$34			
			INC2 R2, R0			
			RET R1			; Call $4934
						
			MOVE R4, $A4			
			SET R4, #$01			
			MHL R5, R4			
			CLR R5, #$80			
			MLH R4, R5			
			MOVE $A4, R4			
						
			MOVE R4, $A0			
			MOVE $B0, R4			
						
			MOVE R13, R3		; IOCB	
			ADD R13, #$01			
			MOVB R4, (R13)-		; IOCB_Sub	
			LBI R1, #$80			
			SE R4, R1			
			BRA $43F8		; $48(R0)	
						
			; Input one character without echo			
			ADD R13, #$04			
			MOVE R4, (R13)~		; IOCB_BA	
						
			; Cursor blink loop, exits if key pressed			
			MOVB R6, (R4)		; get char in current position	
			LBI R1, #$40			
			SE R6, R1			
			BRA $43C0			
			LBI R7, #'_'		; blink with underscore	
			BRA $43C2			
			LBI R7, #' '		; blink with blank	
			MOVE R8, R6			
			MOVB (R4), R7			
			LBI R9, #$40			
			MLH R9, R9			
			LBI R9, #$00			
			MOVE R10, $B0			
			SZ R10			
			BRA $43E2		; key pressed -> exit loop	
			LBI R1, #$FF			
			SUB R9, #$01			
			SBSH R9, R1			
			BRA $43CC			
			MLH R6, R7			
			MOVE R7, R8			
			MHL R8, R6			
			BRA $43C4			
						
			MOVB (R4), R6			
			MOVE R1, $A0			
			MOVE $B0, R1			
			MOVB (R13), R10		; store character	
			SUB R13, #$03			
						
			; Return			
			MOVE R4, $A4			
			CLR R4, #$01			
			MOVE $A4, R4			
			MOVE R2, $B4		; restore R2	
			MOVE R8, R2			
			JMP ($00AC)		; return to caller	
						
			; Input string with echo and editing			
			MOVE R14, $A0			
			MOVE R4, $A0			
			ADD R13, #$04			
			MOVE R12, (R13)+			
			LBI R1, #$02			
			MHL R4, R12			
			SLT R4, R1			
			BRA $4410		; $08(R0)	
						
			LBI R1, #$43			
			MLH R1, R1			
			LBI R1, #$50			
			RET R1			
						
			MOVE R7, (R13)			
			MOVE R8, R7			
			MHL R9, R7			
			SZ R7			
			BRA $441E		; $04(R0)	
						
			SNZ R9			
			BRA $4408		; -> -$16(R0)	
						
			LBI R10, #$04			
			SLE R9, R10			
			BRA $4408		; -> -$1C(R0)	
						
			SE R9, R10			
			BRA $442C		; $04(R0)	
						
			SZ R7			
			BRA $4408		; -> -$24(R0)	
						
			MOVE R9, R7			
			MOVE R14, R12			
			MOVE R5, R12			
			ADD R13, #$08			
			MOVE R4, (R13)			
			MOVE R7, R4			
			ADD R5, R7			
			MHL R7, R5			
			ADDH R7, R7			
			MLH R5, R7			
			ADD R14, R9			
			MHL R9, R14			
			ADDH R9, R9			
			MLH R14, R9			
			SUB R14, #$01			
			MHL R9, R14			
			LBI R1, #$06			
			SLT R9, R1			
			BRA $4408		; -> -$4A(R0)	
						
			MHL R9, R5			
			LBI R1, #$06			
			SLT R9, R1			
			BRA $4408		; -> -$52(R0)	
						
			MOVE R7, R4			
			ADD R7, #$01			
			MHL R10, R7			
			MHL R11, R8			
			SLE R10, R11			
			BRA $4408		; -> -$5E(R0)	
						
			SE R10, R11			
			BRA $446E		; $04(R0)	
						
			SLE R7, R8			
			BRA $4408		; -> -$66(R0)	
						
			CTRL $1, #$02			
			LBI R1, #$49			
			MLH R1, R1			
			LBI R1, #$B0			
			INC2 R2, R0			
			RET R1			; Call $49B0
						
			LBI R1, #$04			
			MOVE R15, $A4			
			SNBSH R15, R1			
			BRA $44C0		; $3E(R0)	
						
			MOVE R7, R4			
			ADD R7, #$01			
			MOVE R9, $A0			
			MOVE R10, $A0			
			MHL R8, R7			
			SNZ R8			
			BRA $4496		; $06(R0)	
						
			MHL R8, R7			
			SZ R8			
			BRA $449C		; $06(R0)	
						
			LBI R1, #$63			
			SGT R7, R1			
			BRA $44A2		; $06(R0)	
						
			ADD R9, #$01			
			SUB R7, #$64			
			BRA $4490		; -> -$12(R0)	
						
			LBI R1, #$09			
			SGT R7, R1			
			BRA $44AE		; $06(R0)	
						
			ADD R10, #$01			
			SUB R7, #$0A			
			BRA $44A2		; -> -$0C(R0)	
						
			ADD R7, #$F0			
			ADD R9, #$F0			
			ADD R10, #$F0			
			LBI R1, #$05			
			MLH R1, R1			
			LBI R1, #$FD			
			MOVB (R1)+, R9			
			MOVB (R1)+, R10			
			MOVB (R1), R7			
			MOVE R5, R12			
			MOVE R7, R4			
			ADD R5, R7			
			MHL R7, R5			
			ADDH R7, R7			
			MLH R5, R7			
			MOVB R6, (R5)			
			LBI R1, #$40			
			SE R6, R1			
			BRA $44D8		; $04(R0)	
						
			LBI R7, #$6D			
			BRA $44DA		; $02(R0)	
						
			LBI R7, #$40		; Leerzeichen	
			MOVE R8, R6			
			MOVB (R5), R7		; schreibe Cursor (Blank)	
			LBI R9, #$40			
			MLH R9, R9			
			LBI R9, #$00			
						
			MOVE R10, $B0			
			SZ R10			
			BRA $44FA		; $10(R0)	
						
			LBI R1, #$FF			
			SUB R9, #$01			
			SBSH R9, R1			
			BRA $44E4		; -> -$0E(R0)	
						
			MLH R6, R7			
			MOVE R7, R8			
			MHL R8, R6			
			BRA $44DC		; -> -$1E(R0)	
						
			MOVB (R5), R6			
			MOVE R7, $A0			
			MOVE $B0, R7			
			LBI R1, #$02			
			SBSH R10, R1			
			BRA $4598		; $92(R0)	
						
			MOVE R7, $A2			
			LBI R1, #$20			
			SBC R7, R1			
			BRA $457C		; $6E(R0)	
						
			MOVB R15, (R5)			
			MOVE R7, $A2			
			LBI R1, #$02			
			SNBSH R7, R1			
			BRA $4560		; $48(R0)	
						
			LBI R7, #$0B			
			MLH R7, R7			
			LBI R7, #$F5			
			LBI R8, #$00			
			MLH R8, R8			
			LBI R8, #$0E			
			PUTB $1, (R8)+			
			PUTB $1, (R8)-			
			BRA $4529		; -> -$01(R0)	
						
			GETB R7, $1			
			MLH R7, R7			
			NOP			
			GETB R7, $1			
			LBI R8, #$00			
			MLH R8, R8			
			LBI R8, #$0E			
			PUTB $1, (R8)+			
			PUTB $1, (R8)			
			BRA $453D		; -> -$01(R0)	
						
			GETB R8, $1			
			SNS R8			
			BRA $457C		; $38(R0)	
						
			SE R8, R10			
			BRA $4556		; $0E(R0)	
						
			NOP			
			GETB R8, $1			
			SE R8, R15			
			BRA $455A		; $0A(R0)	
						
			NOP			
			GETB R10, $1			
			BRA $457C		; $26(R0)	
						
			GETB R8, $1			
			BRA $4559		; -> -$01(R0)	
						
			GETB R8, $1			
			NOP			
			BRA $453E		; -> -$22(R0)	
						
			MOVE R7, $DA			
			MOVB R8, (R7)+			
			SNS R8			
			BRA $457C		; $14(R0)	
						
			SE R8, R10			
			BRA $4576		; $0A(R0)	
						
			MOVB R8, (R7)+			
			SE R8, R15			
			BRA $4578		; $06(R0)	
						
			MOVB R10, (R7)			
			BRA $457C		; $06(R0)	
						
			ADD R7, #$01			
			ADD R7, #$01			
			BRA $4562		; -> -$1A(R0)	
						
			MOVB (R5), R10			
			ADD R4, #$01			
			MOVE R10, $A4			
			LBI R1, #$04			
			SBSH R10, R1			
			BRA $4590		; $08(R0)	
						
			MOVE R1, $1FC			
			MOVB R10, (R1)			
			CLR R10, #$80			
			MOVB (R1), R10			
						
			LBI R1, #$44			
			MLH R1, R1			
			LBI R1, #$6E			
			RET R1			
						
			MOVE R8, R10			
			LBI R1, #$26			
			SGE R10, R1			
			BRA $4612		; $72(R0)	
						
			LBI R1, #$47			
			SLE R10, R1			
			BRA $4590		; -> -$16(R0)	
						
			SUB R8, #$26			
			ADD R8, R8			
			ADD R0, R8			
			BRA $4658		; $AA(R0)	
			BRA $4604		; $54(R0)	
			BRA $45F0		; $3E(R0)	
			BRA $462A		; $76(R0)	
			BRA $4590		; -> -$26(R0)	
			BRA $461A		; $62(R0)	
			BRA $4590		; -> -$2A(R0)	
			BRA $4590		; -> -$2C(R0)	
			BRA $464E		; $90(R0)	
			BRA $463A		; $7A(R0)	
			BRA $4666		; $A4(R0)	
			BRA $4666		; $A2(R0)	
			BRA $4666		; $A0(R0)	
			BRA $4666		; $9E(R0)	
			BRA $4666		; $9C(R0)	
			BRA $4666		; $9A(R0)	
			BRA $4666		; $98(R0)	
			BRA $4666		; $96(R0)	
			BRA $4666		; $94(R0)	
			BRA $4666		; $92(R0)	
			BRA $457E		; -> -$58(R0)	
			BRA $457E		; -> -$5A(R0)	
			BRA $46A6		; $CC(R0)	
			BRA $4660		; $84(R0)	
			BRA $4660		; $82(R0)	
			BRA $4646		; $66(R0)	
			BRA $45FC		; $1A(R0)	
			BRA $4642		; $5E(R0)	
			BRA $4690		; $AA(R0)	
			BRA $4690		; $A8(R0)	
			BRA $4590		; -> -$5A(R0)	
			BRA $4680		; $94(R0)	
			BRA $4680		; $92(R0)	
			BRA $4590		; -> -$60(R0)	
						
			LBI R10, #$4F			
			LBI R1, #$04			
			MOVE R7, $A4			
			SBSH R7, R1			
			BRA $45FC		; $02(R0)	
						
			LBI R10, #$BF			
			LBI R1, #$45			
			MLH R1, R1			
			LBI R1, #$06			
			RET R1			
						
			LBI R10, #$BF			
			LBI R1, #$04			
			MOVE R7, $A4			
			SBSH R7, R1			
			BRA $45FC		; -> -$12(R0)	
						
			LBI R10, #$4F			
			BRA $45FC		; -> -$16(R0)	
						
			LBI R1, #$47			
			MLH R1, R1			
			LBI R1, #$3E			
			RET R1			
						
			LBI R1, #$04			
			MOVE R15, $A4			
			SNBSH R15, R1			
			BRA $4626		; $04(R0)	
						
			LBI R10, #$5C			
			BRA $45FC		; -> -$2A(R0)	
						
			LBI R10, #$B6			
			BRA $45FC		; -> -$2E(R0)	
						
			LBI R1, #$04			
			MOVE R15, $A4			
			SNBSH R15, R1			
			BRA $4636		; $04(R0)	
						
			LBI R10, #$61			
			BRA $45FC		; -> -$3A(R0)	
						
			LBI R10, #$B8			
			BRA $45FC		; -> -$3E(R0)	
						
			LBI R1, #$47			
			MLH R1, R1			
			LBI R1, #$0E			
			RET R1			
						
			LBI R10, #$40			
			BRA $45FC		; -> -$4A(R0)	
						
			LBI R1, #$46			
			MLH R1, R1			
			LBI R1, #$E0			
			RET R1			
						
			LBI R1, #$20			
			SUB R13, #$06			
			MOVB (R13), R1			
			ADD R13, #$06			
			BRA $4678		; $20(R0)	
						
			MOVE R8, $C2			
			INC2 R2, R0			
			JMP ($00AC)			
						
			BRA $4590		; -> -$D0(R0)	
						
			SUB R4, #$01			
			SUB R5, #$01			
			BRA $4590		; -> -$D6(R0)	
						
			LBI R1, #$04			
			MOVE R15, $A4			
			SNBSH R15, R1			
			BRA $4736		; $C8(R0)	
						
			CLR R10, #$F0			
			MOVE (R13), R4			
			SUB R13, #$06			
			MOVB (R13), R10			
			ADD R13, #$06			
			LBI R1, #$48			
			MLH R1, R1			
			LBI R1, #$06			
			RET R1			
						
			SUB R13, #$05			
			MOVB R8, (R13)			
			ADD R13, #$05			
			LBI R1, #$80			
			SNE R8, R1			
			BRA $4736		; $AA(R0)	
						
			LBI R8, #$40			
			BRA $469E		; $0E(R0)	
						
			SUB R13, #$05			
			MOVB R8, (R13)			
			ADD R13, #$05			
			LBI R1, #$80			
			SNE R8, R1			
			BRA $4736		; $9A(R0)	
						
			LBI R8, #$80			
			SUB R13, #$06			
			MOVB (R13), R8			
			ADD R13, #$06			
			BRA $4678		; -> -$2E(R0)	
						
			MOVE R7, R14			
			SUB R7, #$01			
			MOVE R8, (R7)			
			LBI R1, #$40			
			SE R8, R1			
			BRA $4736		; $84(R0)	
						
			SUB R13, #$08			
			MOVE R8, (R13)			
			ADD R13, #$08			
			SUB R8, #$01			
			SE R8, R4			
			BRA $46C6		; $08(R0)	
						
			MHL R9, R8			
			MHL R10, R4			
			SNE R9, R10			
			BRA $4736		; $70(R0)	
						
			MOVB R9, (R7)+			
			MOVB (R7)--, R9			
			SUB R8, #$01			
			MHL R9, R8			
			MHL R10, R4			
			SE R9, R10			
			BRA $46C6		; -> -$0E(R0)	
						
			SGE R4, R8			
			BRA $46C6		; -> -$12(R0)	
						
			ADD R7, #$01			
			LBI R1, #$40			
			MOVB (R7), R1			
			BRA $4736		; $56(R0)	
						
			SUB R13, #$08			
			MOVE R7, (R13)			
			ADD R13, #$08			
			SUB R7, #$01			
			SE R7, R4			
			BRA $46F4		; $08(R0)	
						
			MHL R8, R7			
			MHL R9, R4			
			SNE R8, R9			
			BRA $4708		; $14(R0)	
						
			ADD R5, #$01			
			MOVB R8, (R5)-			
			MOVB (R5)+, R8			
			SUB R7, #$01			
			MHL R8, R7			
			MHL R9, R4			
			SE R8, R9			
			BRA $46F4		; -> -$10(R0)	
						
			SGE R4, R7			
			BRA $46F4		; -> -$14(R0)	
						
			LBI R1, #$40			
			MOVB (R5)-, R1			
			BRA $4736		; $28(R0)	
						
			SUB R13, #$08			
			MOVE R7, (R13)			
			ADD R13, #$08			
			MOVE R15, $A4			
			LBI R1, #$04			
			SBSH R15, R1			
			BRA $4724		; $08(R0)	
						
			MOVE R15, $1FC			
			MOVB R1, (R15)			
			SET R1, #$80			
			MOVB (R15), R1			
			LBI R1, #$40			
			MOVB (R5)+, R1			
			SUB R7, #$01			
			MHL R8, R7			
			MHL R9, R4			
			SE R8, R9			
			BRA $4724		; -> -$0E(R0)	
						
			SGE R4, R7			
			BRA $4724		; -> -$12(R0)	
						
			LBI R1, #$44			
			MLH R1, R1			
			LBI R1, #$6E			
			RET R1			
						
			CTRL $0, #$3F			
			LBI R1, #$04			
			MOVE R15, $A4			
			SNBSH R15, R1			
			BRA $474C		; $04(R0)	
						
			CTRL $1, #$08			
			BRA $474E		; $02(R0)	
						
			CTRL $1, #$04			
			SUB R13, #$04			
			MOVE R7, (R13)			
			ADD R13, #$04			
			SZ R7			
			BRA $475E		; $06(R0)	
						
			MHL R8, R7			
			SNZ R8			
			BRA $47FA		; $9C(R0)	
						
			LBI R8, #$00			
			MLH R8, R8			
			LBI R8, #$0E			
			PUTB $1, (R8)+			
			PUTB $1, (R8)			
			BRA $4769		; -> -$01(R0)	
						
			GETB R8, $1			
			SNS R8			
			BRA $47FA		; $8A(R0)	
						
			SE R8, R10			
			BRA $47B4		; $40(R0)	
						
			GETB R8, $1			
			SNZ R8			
			BRA $47C4		; $4A(R0)	
						
			NOP			
			GETB R9, $1			
			MLH R9, R9			
			NOP			
			GETB R9, $1			
			LBI R10, #$00			
			MLH R10, R10			
			LBI R10, #$12			
			PUTB $1, (R10)+			
			PUTB $1, (R10)			
			BRA $478F		; -> -$01(R0)	
						
			GETB R10, $1			
			MOVB (R5), R10			
			ADD R4, #$01			
			LBI R1, #$49			
			MLH R1, R1			
			LBI R1, #$B0			
			INC2 R2, R0			
			RET R1			
						
			MOVE R5, R12			
			MOVE R7, R4			
			ADD R5, R7			
			MHL R7, R5			
			ADDH R7, R7			
			MLH R5, R7			
			SUB R8, #$01			
			SZ R8			
			BRA $4790		; -> -$22(R0)	
						
			BRA $47FA		; $46(R0)	
						
			ADD R7, #$03			
			LBI R8, #$00			
			MLH R8, R8			
			LBI R8, #$0E			
			PUTB $1, (R8)+			
			PUTB $1, (R8)			
			NOP			
			BRA $476A		; -> -$5A(R0)	
						
			GETB R8, $1			
			MLH R8, R8			
			NOP			
			GETB R8, $1			
			BRA $47CD		; -> -$01(R0)	
						
			GETB R9, $1			
			MLH R9, R9			
			NOP			
			GETB R9, $1			
			MOVB R10, (R9)			
			MOVB R11, (R8)+			
			MOVB (R5), R11			
			ADD R4, #$01			
			LBI R1, #$49			
			MLH R1, R1			
			LBI R1, #$B0			
			INC2 R2, R0			
			RET R1			
						
			MOVE R5, R12			
			MOVE R7, R4			
			ADD R5, R7			
			MHL R7, R5			
			ADDH R7, R7			
			MLH R5, R7			
			SUB R10, #$01			
			SZ R10			
			BRA $47D8		; -> -$22(R0)	
						
			CTRL $1, #$02			
			CTRL $0, #$5F			
			LBI R1, #$44			
			MLH R1, R1			
			LBI R1, #$6E			
			RET R1			
						
			MOVE R14, $A4			
			CLR R14, #$01			
			MOVE $A4, R14			
			MOVE (R13), R4			
			MOVE R2, $B4			
			MOVE R8, R2			
			JMP ($00AC)			
						
			MOVE R1, $A2			
			SET R1, #$02			
			MOVE $A2, R1			
			MOVE R1, $BE			
			MOVE (R1)+, R2			
			MOVE (R1)+, R3			
			MOVE (R1)+, R4			
			MOVE (R1)+, R5			
			MOVE (R1)+, R6			
			MOVE (R1)+, R7			
			MOVE (R1)+, R8			
			MOVE (R1)+, R9			
			MOVE (R1)+, R10			
			MOVE (R1)+, R11			
			MOVE (R1)+, R12			
			MOVE (R1)+, R13			
			MOVE (R1)+, R14			
			MOVE (R1), R15			
			BRA $4842		; $08(R0)	
						
			MOVE R1, $A2			
			SET R1, #$03			
			MOVE $A2, R1			
			MOVE $BC, R2			
						
			LBI R1, #$49			
			MLH R1, R1			
			LBI R1, #$34			
			INC2 R2, R0			
			RET R1			
						
			MOVE R13, $BE			
			ADD R13, #$6C			
			LBI R1, #$05			
			MLH R1, R1			
			LBI R1, #$00			
			MOVE (R13)+, R1			
			LBI R1, #$02			
			MLH R1, R1			
			LBI R1, #$00			
			MOVE (R13)+, R1			
			LBI R1, #$02			
			MLH R1, R1			
			LBI R1, #$00			
			MOVE R6, R1			
			MOVE R7, R13			
			MOVE (R13)+, R1			
			MLH R1, R1			
			LBI R1, #$40			
			MOVE (R13)+, R1			
			LBI R1, #$01			
			MOVE (R13)+, R1			
			LBI R1, #$00			
			MLH R1, R1			
			MOVE (R13)+, R1			
			MOVE (R13), R1			
			LBI R8, #$10			
			MOVE R1, $BE			
			ADD R1, #$60			
			MOVE (R1)+, R6			
			MOVE (R1)+, R7			
			MOVE (R1)+, R13			
			MOVE (R1), R8			
			MOVE R13, $BE			
			ADD R13, #$6C			
			MOVE R3, R13			
			MOVE R8, $C4			
			INC2 R2, R0			
			JMP ($00AC)			
						
			BRA $492C		; $92(R0)	
						
			MOVE R4, $D8			
			ADD R4, #$14			
			MOVE R5, (R4)			
			MHL R6, R5			
			SZ R6			
			BRA $48AC		; $06(R0)	
						
			MOVE R13, R3			
			ADD R13, #$0C			
			BRA $4920		; $74(R0)	
						
			MOVE R8, $0A			
			INC2 R2, R0			
			JMP ($00AC)			
						
			MOVE R8, $C4			
			INC2 R2, R0			
			JMP ($00AC)			
						
			BRA $492C		; $72(R0)	
						
			CTRL $0, #$77			
			MOVE R1, $BE			
			ADD R1, #$60			
			MOVE R6, (R1)+			
			MOVE R7, (R1)+			
			MOVE R13, (R1)+			
			MOVE R8, (R1)			
			MOVE R9, (R13)			
			SZ R9			
			BRA $4928		; $5A(R0)	
						
			SUB R8, #$01			
			SNZ R8			
			BRA $48DA		; $06(R0)	
						
			ADD R6, #$40			
			MOVE (R7), R6			
			BRA $4880		; -> -$5A(R0)	
						
			LBI R1, #$49			
			MLH R1, R1			
			LBI R1, #$34			
			INC2 R2, R0			
			RET R1			
						
			CTRL $4, #$4A			
			MOVE R4, $A2			
			LBI R1, #$01			
			SBC R4, R1			
			BRA $4914		; $26(R0)	
						
			MOVE R1, $BE			
			MOVE R2, (R1)+			
			MOVE R3, (R1)+			
			MOVE R4, (R1)+			
			MOVE R5, (R1)+			
			MOVE R6, (R1)+			
			MOVE R7, (R1)+			
			MOVE R8, (R1)+			
			MOVE R9, (R1)+			
			MOVE R10, (R1)+			
			MOVE R11, (R1)+			
			MOVE R12, (R1)+			
			MOVE R13, (R1)+			
			MOVE R14, (R1)+			
			MOVE R15, (R1)			
						
			MOVE R1, $A2			
			CLR R1, #$06			
			MOVE $A2, R1			
			RET R2			
						
						
			MOVE R1, $A2			
			CLR R1, #$07			
			MOVE $A2, R1			
			MOVE R2, $BC			
			MOVE R8, R2			
			JMP ($00AC)			
						
			LBI R6, #$F1			
			MLH R6, R6			
			LBI R6, #$F3			
			MOVE (R13), R6			
			MOVE R3, $BE			
			ADD R3, #$6C			
			MOVE R8, $FA			
			INC2 R2, R0			
			JMP ($00AC)			
						
			BRA $48E4		; -> -$50(R0)	
						
			MOVE $BA, R3			
			MOVE $B8, R2			
			MOVE R13, $BE			
			ADD R13, #$6C			
			MOVE R3, R13			
			LBI R5, #$05			
			MLH R5, R5			
			LBI R5, #$00			
			MOVE (R13)+, R5			
			MOVE R5, $A0			
			LBI R6, #$09			
			MOVE (R13)+, R5			
			SUB R6, #$01			
			SZ R6			
			BRA $494A		; -> -$08(R0)	
						
			MOVE R3, $BE			
			ADD R3, #$6C			
			MOVE R4, $D8			
			ADD R4, #$14			
			MOVE R5, (R4)			
			MHL R6, R5			
			SZ R6			
			BRA $4976		; $14(R0)	
						
			MOVE R13, R3			
			ADD R13, #$0C			
			LBI R1, #$F1			
			MLH R1, R1			
			LBI R1, #$F3			
			MOVE (R13), R1			
			MOVE R8, $FA			
			INC2 R2, R0			
			JMP ($00AC)			
						
			BRA $49A4		; $2E(R0)	
						
			MOVE R8, $0A			
			INC2 R2, R0			
			JMP ($00AC)			
						
			MOVE R13, R3			
			ADD R13, #$0C			
			MOVE R5, (R13)			
			SNZ R5			
			BRA $499C		; $16(R0)	
						
			MOVE R6, $A2			
			LBI R1, #$02			
			SBC R6, R1			
			BRA $496E		; -> -$20(R0)	
						
			LBI R1, #$F1			
			SE R5, R1			
			BRA $496E		; -> -$26(R0)	
						
			MHL R5, R5			
			LBI R1, #$F5			
			SE R5, R1			
			BRA $496E		; -> -$2E(R0)	
						
			MOVE R8, $C4			
			INC2 R2, R0			
			JMP ($00AC)			
						
			BRA $496E		; -> -$36(R0)	
						
			MOVE R13, $BA			
			MOVE R3, $BA			
			CTRL $4, #$42			
			MOVE R2, $B8			
			CTRL $0, #$77			
			RET R2			
						
			SUB R13, #$08			
			MOVE R7, (R13)			
			ADD R13, #$08			
			MOVE R9, R4			
			SUB R7, R9			
			MHL R9, R7			
			MLH R7, R7			
			MHL R7, R9			
			SUB R9, R7			
			MHL R7, R7			
			MLH R7, R9			
			MHL R9, R7			
			OR R9, R7			
			SZ R9			
			BRA $49D2		; $04(R0)	
						
			MOVE R4, $A0			
			BRA $49E0		; $0E(R0)	
						
			MHL R7, R4			
			SS R7			
			BRA $49E0		; $08(R0)	
						
			SUB R13, #$08			
			MOVE R4, (R13)			
			ADD R13, #$08			
			SUB R4, #$01			
						
			RET R2			
						
						
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
			HALT			
						
						
						
						
						
						
			MOVE $D2, R2		; Save R2	
						
			INC2 R13, R3			
			MOVB R14, (R13)		; IOCB_Cmd	
			LBI R15, #$E0			
			ADD R13, #$0E		; IOCB_Stat1	
						
			MOVB R12, (R13)			
			LBI R9, #$48			
			SNZ R14			; Sense ?
			MOVE R12, R9		; Yes	
			SE R12, R9			
			BRA $4AD0		; Error 02	
			MOVB (R13)+, R12			
						
			MOVB R12, (R13)			
			LBI R9, #$24			
			SNZ R14			; Sense ?
			MOVE R12, R9		; Yes	
			SE R12, R9			
			BRA $4AD0		; Error 02	
			MOVB (R13), R12		; IOCB_Stat1 is now $4824	
						
			SZ R14			; Sense ?
			BRA $4A66		; No	
						
			; Sense			
						
			MOVE R8, $C4			
			INC2 R2, R0			
			JMP ($00AC)			
			BRA $4A36		; $04(R0)	
						
			MOVE R14, $A0			
			BRA $4A66		; $30(R0)	
						
			LBI R15, #$F0			
			MOVE R12, $C6			
			LBI R1, #$80			
			SBS R12, R1			
			BRA $4AD0		; Jump to $50BC	
						
			MOVE R1, $A0			
			MOVE $C6, R1			
			LBI R14, #$F7			
			MLH R14, R14			
			LBI R14, #$F1			
			MOVE R13, R3			
			ADD R13, #$0C			
			MOVE (R13)++, R14	; IOCB_Ret		
			CTRL $F, #$10			
			MOVE R13, $46		; R3L2	
			MOVB R14, (R13)			
			LBI R1, #$05			
			SE R14, R1			
			BRA $4A64		; $08(R0)	
						
			ADD R13, #$10			
			MOVE R14, (R13)			
			CLR R14, #$10			
			MOVE (R13), R14			
			MOVE R14, $A0			
						
			; Command other than Sense			
						
			LBI R15, #$E8			
			GETB R10, $5		; Status byte A	
			SNS R10			; Printer there ?
			BRA $4AD0		; No, error 13	
						
			LBI R13, #$00			
			MLH R13, R13			
			LBI R13, #$A4			
			MOVB R12, (R13)			
			SET R12, #$02			
			MOVB (R13)+, R12	; Set I/O active flag		
			MOVB R12, (R13)			
			SET R12, #$08		; Set printer busy flag	
			CLR R12, #$20		; Level 2 RWS	
			MOVB (R13), R12			
			PUTB $0, (R13)			
						
			GETB R10, $5		; Status byte A	
			LBI R1, #$10		; Wire check or not ready	
			SBS R10, R1			
			BRA $4A98		; $0C(R0)	
						
			SZ R14			; Sense ?
			BRA $4A98		; No	
						
			INC2 R2, R0			
			BRA $4B28		; $94(R0)	
						
			SZ R14			
			BRA $4AC6		; $2E(R0)	
						
			LBI R15, #$04			
			STAT R13, $5		; Status byte B	
			LBI R1, #$80		; Print motor latch B	
			SNBS R13, R1			
			BRA $4AC6		; $24(R0)	
						
			LBI R15, #$10			
			STAT R13, $5			
			LBI R1, #$40		; Print motor latch A	
			SBS R13, R1			
			BRA $4AC6		; $1A(R0)	
						
			LBI R15, #$00			
			LBI R1, #$02		; Not end of forms	
			SBS R10, R1			
			BRA $4AC6		; $12(R0)	
						
			MOVE R12, $C6			
			LBI R1, #$40			
			SBS R12, R1			
			BRA $4AD8		; $1C(R0)	
						
			LBI R15, #$38			
			SZ R14			
			BRA $4AC6		; $04(R0)	
						
			MOVE R12, $A0			
			BRA $4AD8		; $12(R0)	
						
			MOVE $80, R1			
			LBI R1, #$50			
			MLH R1, R1			
			LBI R1, #$A8			
			RET R1			
						
			LBI R1, #$50			
			MLH R1, R1			
			LBI R1, #$BC			
			RET R1			
						
			SZ R14			
			BRA $4AE4		; $08(R0)	
						
			SET R12, #$B2			
			CLR R12, #$01			
			MOVE $C6, R12			
			BRA $4B9A		; $B6(R0)	
						
			LBI R13, #$00			
			MLH R13, R13			
			LBI R13, #$A2			
			MOVE R1, (R13)			
			SET R1, #$04			
			MOVE (R13), R1			
			LBI R1, #$03			
			SNE R14, R1			
			BRA $4AFC		; $06(R0)	
						
			LBI R1, #$02			
			SE R14, R1			
			BRA $4B08		; $0C(R0)	
						
			SET R12, #$88			
			MOVE $C6, R12			
			MOVE R12, $A0			
			LBI R12, #$0A			
			MOVE $80, R12			
			BRA $4B18		; $10(R0)	
						
			LBI R1, #$0D			
			SE R14, R1			
			BRA $4B20		; $12(R0)	
						
			SET R12, #$84			
			MOVE $C6, R12			
			MOVE R12, $A0			
			LBI R12, #$01			
			MOVE $80, R12			
			LBI R1, #$4C			
			MLH R1, R1			
			LBI R1, #$70			
			RET R1			
						
			LBI R15, #$E0			
			SS R14			
			BRA $4AC6		; -> -$60(R0)	
						
			BRA $4AFC		; -> -$2C(R0)	
						
			CTRL $F, #$10			
			LBI R14, #$0F			
			MOVE R1, $A0			
			MOVE $56, R1			
			LBI R1, #$4E			
			MOVE $5E, R1			
			LBI R15, #$30			
			MLH R15, R15			
			LBI R15, #$00			
			MOVE $5C, R15			
			INC2 R1, R0			
			BRA $4B6E		; $2E(R0)	
						
			MHL R11, R10			
			GETB R11, $5			
			LBI R1, #$32			
			LBI R13, #$01			
			SNBC R11, R1			
			SBS R11, R13			
			BRA $4B64		; $16(R0)	
						
			MOVE $1E, R14			
			SUB R15, #$01			
			SNZ R15			
			BRA $4B5C		; $06(R0)	
						
			MOVE R11, $A0			
			CTRL $5, #$52		; Reset timer interrupt	
			BRA $4B40		; -> -$1C(R0)	
						
			CTRL $5, #$51		; Disable timer interrupts	
			MOVE $1C, R15			
			MOVE R11, $A0			
			CTRL $5, #$52		; Reset timer interrupt	
			LBI R15, #$14			
			LBI R1, #$FF			
			MOVE $1C, R1			
			CTRL $F, #$10		; Reset printer	
			HALT			
			MOVE $40, R1			
			LBI R10, #$2C			
			MLH R10, R10			
			GETB R10, $5			
			MOVE $54, R10			
			CTRL $5, #$D8		; Preset timer counter	
			NOP			
			CTRL $5, #$D1		; Enable timer interrupts	
						
			SUB R15, #$01			
			MHL R13, R15			
			OR R13, R15			
			SNZ R14			
			RET R2			
			SZ R13			
			SNS R14			
			BRA $4B90		; Exit loop	
			BRA $4B7E		; Loop	
						
			LBI R15, #$20			
			SNS R14			
			MOVE R15, $5E			
			LBI R14, #$FF			
			RET R2			
						
			CTRL $F, #$10		; Reset printer	
			MOVE R13, R3			
			ADD R13, #$06			
			MOVE R1, $A0			
			LBI R1, #$84		; 132 characters/line	
			MOVE (R13), R1		; preset IOCB_BS	
			ADD R13, #$04			
			MOVE R1, $A0			
			MOVE (R13), R1		; clear IOCB_WA	
			INC2 R2, R0			
			BRA $4BEA		; $3A(R0)	
						
			LBI R13, #$77			
			MLH R13, R13			
			MOVE $F4, R13			
			MOVE $F6, R13			
			MOVE $C8, R13			
			MOVE R13, $A0			
			MOVE $F2, R13			
			LBI R13, #$FF			
			MLH R13, R13			
			LBI R13, #$D4			
			LBI R1, #$01			
			SBS R10, R1			
			BRA $4BDA		; $10(R0)	
						
			MOVE $F4, R13			
			MOVE R13, $8A			
			SET R13, #$84			
			MOVE $8A, R13			
			MOVE R13, $48			
			SET R13, #$88			
			MOVE $48, R13			
			BRA $4BE2		; $08(R0)	
						
			MOVE $F2, R13			
			MOVE R13, $48			
			SET R13, #$84			
			MOVE $48, R13			
			LBI R1, #$51			
			MLH R1, R1			
			LBI R1, #$4E			
			RET R1			
						
			MOVE R13, R3			
			MOVE $46, R13			
			ADD R13, #$10			
			MOVE R12, (R13)			
			SET R12, #$10			
			MOVE (R13), R12			
			MOVE R13, $A0			
			MOVE R12, R13			
			MOVE R9, R13			
			LBI R9, #$F6			
			LBI R12, #$EA			
			MOVE (R12)+, R13			
			SGT R12, R9			
			BRA $4C00		; -> -$06(R0)	
						
			LBI R12, #$82			
			LBI R9, #$9E			
			MOVE (R12)+, R13			
			SGT R12, R9			
			BRA $4C0A		; -> -$06(R0)	
						
			LBI R12, #$48			
			LBI R9, #$5E			
			MOVE (R12)+, R13			
			SGT R12, R9			
			BRA $4C14		; -> -$06(R0)	
						
			LBI R1, #$08			
			MLH R13, R1			
			MOVE $56, R13			
			GETB R10, $5			
			MOVE R5, $80			
			MOVE R4, $A0			
			INC2 R9, R3			
			MOVB R12, (R9)			
			SNZ R12			
			BRA $4C38		; $0A(R0)	
						
			MOVE R9, R3			
			ADD R9, #$09			
			MOVB R12, (R9)			
			SZ R12			
			SET R4, #$40			
			STAT R12, $5			
			LBI R1, #$20			
			SBC R12, R1			
			SET R4, #$80			
			MOVE $48, R4			
			MOVE R9, R3			
			ADD R9, #$02			
			MOVE R7, (R9)			
			LBI R1, #$01			
			MOVE R14, $A0			
			SBC R7, R1			
			SET R14, #$10			
			MLH R4, R14			
			LBI R1, #$01			
			SNE R5, R1			
			BRA $4C5C		; $04(R0)	
						
			MOVE R13, $A0			
			BRA $4C64		; $08(R0)	
						
			MOVE R9, R3			
			ADD R9, #$0E			
			MOVE R13, (R9)			
			SET R4, #$01			
			MOVE $8A, R4			
			MOVE $8C, R4			
			LBI R12, #$2E			
			MOVE $8E, R12			
			RET R2			
						
			BRA $4BE2		; -> -$8E(R0)	
						
			INC2 R2, R0			
			BRA $4BEA		; -> -$8A(R0)	
						
			MOVE R9, R3			
			ADD R9, #$04			
			MOVE R14, (R9)+			
			MOVE R15, (R9)			
			MHL R9, R15			
			MHL R1, R15			
			OR R1, R15			
			SNZ R1			
			BRA $4CD4		; $4E(R0)	
						
			MHL R12, R14			
			ADD R9, R12			
			MLH R15, R9			
			ADD R15, R14			
			SUB R15, #$01			
			INC2 R9, R3			
			MOVB R12, (R9)			
			SS R12			
			BRA $4CC2		; $2A(R0)	
						
			MOVE $98, R14			
			MOVE $9A, R15			
			ADD R9, #$04			
			MOVE R12, (R9)			
			SUB R12, #$01			
			MOVE R9, R12			
			ADD R9, R12			
			ADD R9, R12			
			ADD R9, R12			
			ADD R9, R12			
			ADD R9, R12			
			ADD R9, R12			
			ADD R9, R12			
			ADD R9, R12			
			ADD R9, R12			
			MOVE $92, R9			
			MOVE R9, $8A			
			SET R9, #$20			
			MOVE $8A, R9			
			MOVE $8C, R9			
			BRA $4DA4		; $E2(R0)	
						
			MOVE R8, R14			
			INC2 R2, R0			
			BRA $4DAC		; $E4(R0)	
						
			BRA $4D6E		; $A4(R0)	
						
			ADD R13, R5			
			ADD R14, #$01			
			INC2 R2, R0			
			BRA $4D9A		; $C8(R0)	
						
			BRA $4CC2		; -> -$12(R0)	
						
			MOVE R1, $8A			
			MOVE R13, $8C			
			OR R13, R1			
			LBI R1, #$42			
			SNBC R13, R1			
			BRA $4D5E		; $7E(R0)	
						
			MOVE R9, R3			
			ADD R9, #$08			
			MOVE R12, (R9)			
			MHL R9, R12			
			LBI R1, #$80			
			AND R9, R1			
			MOVE R1, $A0			
			MLH R12, R1			
			MOVE R1, $48			
			OR R13, R1			
			LBI R1, #$01			
			SBC R13, R1			
			BRA $4D44		; $4A(R0)	
						
			INC2 R1, R3			
			MOVE R1, (R1)			
			CLR R1, #$FD			
			SNZ R1			
			BRA $4D08		; $04(R0)	
						
			MLH R12, R9			
			BRA $4D16		; $0E(R0)	
						
			SWAP R12			
			LBI R1, #$0F			
			AND R1, R12			
			OR R1, R9			
			MLH R12, R1			
			LBI R1, #$F0			
			AND R12, R1			
			MOVE $84, R12			
			LBI R1, #$02			
			SBS R13, R1			
			BRA $4D5E		; $40(R0)	
						
			LBI R1, #$80			
			SBC R9, R1			
			BRA $4D40		; $1C(R0)	
						
			MHL R9, R12			
			SZ R9			
			BRA $4D30		; $06(R0)	
						
			LBI R1, #$03			
			SGT R12, R1			
			BRA $4D34		; $04(R0)	
						
			SUB R12, #$04			
			BRA $4D5C		; $28(R0)	
						
			LBI R1, #$80			
			MLH R12, R1			
			MOVE R13, R12			
			LBI R12, #$04			
			SUB R12, R13			
			BRA $4D5C		; $1C(R0)	
						
			ADD R12, #$04			
			BRA $4D5C		; $18(R0)	
						
			MOVE R13, R12			
			MLH R12, R9			
			ADD R12, R13			
			ADD R12, R13			
			ADD R12, R13			
			ADD R12, R13			
			ADD R12, R13			
			ADD R12, R13			
			ADD R12, R13			
			ADD R12, R13			
			ADD R12, R13			
			ADD R12, R13			
			MOVE $84, R12			
			LBI R1, #$01			
			SBS R10, R1			
			BRA $4D6A		; $06(R0)	
						
			MOVE R13, $48			
			SET R13, #$08			
			MOVE $48, R13			
			MOVE R4, $A0			
			BRA $4C6E		; -> -$100(R0)	
						
			MOVE R14, R8			
			MOVE $90, R13			
			MOVE $98, R14			
			MOVE R9, $8A			
			SET R9, #$20			
			MOVE $8A, R9			
			MOVE $8C, R9			
			LBI R1, #$6D			
			MHL R9, R4			
			SNE R12, R1			
			SET R9, #$80			
			MLH R4, R9			
			MOVE R14, R8			
			MOVE $92, R13			
			MOVE $9A, R14			
			INC2 R2, R0			
			BRA $4E58		; $C8(R0)	
						
			BRA $4DB2		; $20(R0)	
						
			MOVE R14, R8			
			ADD R13, R5			
			ADD R14, #$01			
			INC2 R2, R0			
			BRA $4E6E		; $D2(R0)	
						
			BRA $4DA8		; $0A(R0)	
						
			MOVE R13, $8C			
			CLR R13, #$01			
			MOVE $8C, R13			
			BRA $4E1E		; $78(R0)	
						
			BRA $4CD4		; -> -$D4(R0)	
						
			MOVE R8, R14			
			INC2 R2, R0			
			BRA $4E5E		; $B0(R0)	
						
			BRA $4D86		; -> -$2A(R0)	
						
			BRA $4D92		; -> -$20(R0)	
						
			MOVE $94, R13			
			MOVE $9C, R14			
			MOVE R9, $8C			
			LBI R1, #$08			
			SBSH R4, R1			
			BRA $4DCE		; $10(R0)	
						
			MHL R7, R9			
			SET R7, #$40			
			MLH R9, R7			
			MOVE R1, $8A			
			MHL R7, R1			
			SET R7, #$40			
			MLH R1, R7			
			MOVE $8A, R1			
			LBI R1, #$01			
			SBS R4, R1			
			SET R9, #$42			
			MOVE $8C, R9			
			MOVE $96, R13			
			MOVE $9E, R14			
			MHL R9, R4			
			CLR R9, #$40			
			LBI R1, #$08			
			SBC R9, R1			
			SET R9, #$40			
			MLH R4, R9			
			ADD R13, R5			
			MOVE R14, R8			
			ADD R14, #$01			
			INC2 R2, R0			
			BRA $4E6E		; $7E(R0)	
						
			BRA $4E3A		; $48(R0)	
						
			MOVE R13, $96			
			ADD R13, R5			
			SUB R13, #$01			
			MOVE $96, R13			
			MOVE R13, $8C			
			MOVE R12, $8A			
			LBI R1, #$80			
			SBSH R4, R1			
			BRA $4E08		; $04(R0)	
						
			SET R12, #$02			
			CLR R13, #$02			
			LBI R1, #$40			
			SBSH R4, R1			
			BRA $4E1A		; $0C(R0)	
						
			MHL R9, R12			
			SET R9, #$08			
			MLH R12, R9			
			MHL R9, R13			
			SET R9, #$08			
			MLH R13, R9			
			MOVE $8C, R13			
			MOVE $8A, R12			
			MOVE R13, $92			
			ADD R13, R5			
			SUB R13, #$01			
			MOVE $92, R13			
			MOVE R13, $56			
			MHL R12, R13			
			LBI R1, #$06			
			SNBS R12, R1			
			SET R12, #$40			
			MLH R13, R12			
			MOVE $56, R13			
			INC2 R2, R0			
			BRA $4E76		; $3E(R0)	
						
			BRA $4DA6		; -> -$94(R0)	
						
			MOVE R8, R14			
			INC2 R2, R0			
			BRA $4E5E		; $1E(R0)	
						
			BRA $4E44		; $02(R0)	
						
			BRA $4DE6		; -> -$5E(R0)	
						
			MOVE R14, R8			
			MOVE $92, R13			
			MOVE $9A, R14			
			LBI R1, #$6D			
			SNE R12, R1			
			BRA $4E56		; $06(R0)	
						
			MHL R1, R4			
			CLR R1, #$80			
			MLH R4, R1			
			INC2 R2, R0			
			BRA $4E66		; $0C(R0)	
						
			BRA $4DD6		; -> -$86(R0)	
						
			BRA $4DE6		; -> -$78(R0)	
						
			LBI R1, #$5A			
			MLH R1, R1			
			LBI R1, #$EA			
			RET R1			
						
			LBI R1, #$5B			
			MLH R1, R1			
			LBI R1, #$34			
			RET R1			
						
			LBI R1, #$5C			
			MLH R1, R1			
			LBI R1, #$62			
			RET R1			
						
			MOVE $EC, R2			
			LBI R5, #$00			
			MLH R5, R5			
			LBI R5, #$F2			
			LBI R13, #$77			
			MLH R13, R13			
			MOVE $F6, R13			
			LBI R6, #$11			
			LBI R7, #$07			
			LBI R1, #$80			
			SBC R4, R1			
			LBI R6, #$1A			
			MOVE R8, $90			
			SUB R8, R6			
			MOVE R9, $92			
			ADD R9, R6			
			MOVE R14, R8			
			MOVE R15, R9			
			MHL R13, R15			
			MHL R12, R14			
			ADD R13, R12			
			MLH R15, R13			
			ADD R15, R14			
			MOVE R14, $A0			
			MHL R14, R15			
			SHR R14			
			SHR R15			
			MLH R15, R14			
			MOVE R14, R15			
			MOVE R15, $C8			
			INC2 R2, R0			
			BRA $4F60		; $AA(R0)	
						
			BRA $4F4E		; $96(R0)	
						
			LBI R14, #$FF			
			MLH R14, R14			
			LBI R14, #$FD			
			INC2 R2, R0			
			BRA $4F60		; $9E(R0)	
						
			BRA $4EC6		; $02(R0)	
						
			BRA $4F34		; $6E(R0)	
						
			MOVE R14, R15			
			MOVE R15, R8			
			INC2 R2, R0			
			BRA $4F60		; $92(R0)	
						
			BRA $4F34		; $64(R0)	
						
			MOVE R13, $48			
			SET R13, #$04			
			MOVE $48, R13			
			MOVE R13, $8C			
			SET R13, #$04			
			MOVE $8C, R13			
			MOVE (R5)+, R8			
			LBI R1, #$03			
			SBC R13, R1			
			BRA $4EEA		; $06(R0)	
						
			SUB R9, R7			
			MOVE (R5), R9			
			BRA $4F22		; $38(R0)	
						
			MOVE R15, $96			
			ADD R15, R6			
			SUB R15, R7			
			MOVE R14, $92			
			INC2 R2, R0			
			BRA $4F60		; $6A(R0)	
						
			BRA $4EFC		; $04(R0)	
						
			MOVE (R5)+, R14			
			BRA $4F00		; $04(R0)	
						
			MOVE (R5)+, R15			
			MOVE R14, $90			
			MOVE R15, $94			
			MOVE R13, R15			
			SE R14, R13			
			BRA $4F14		; $0C(R0)	
						
			MHL R14, R14			
			MHL R13, R13			
			SE R14, R13			
			BRA $4F14		; $04(R0)	
						
			MOVE (R5), R8			
			BRA $4F16		; $02(R0)	
						
			MOVE (R5), R15			
			MOVE R15, $94			
			MOVE R14, $96			
			ADD R15, #$02			
			ADD R14, #$02			
			MOVE $94, R15			
			MOVE $96, R14			
			INC2 R2, R0			
			BRA $4FEC		; $C6(R0)	
						
			MOVE R15, $90			
			MOVE R14, $92			
			SUB R15, #$01			
			SUB R14, #$01			
			MOVE $90, R15			
			MOVE $92, R14			
			BRA $500E		; $DA(R0)	
						
			MOVE R15, $8A			
			MOVE $48, R15			
			MOVE R15, $8C			
			SET R15, #$04			
			MOVE $8A, R15			
			LBI R1, #$03			
			SBC R15, R1			
			BRA $4EEA		; -> -$5A(R0)	
						
			SUB R9, R7			
			MOVE (R5)++, R9			
			MOVE R13, (R5)			
			MOVE $F4, R13			
			BRA $4F22		; -> -$2C(R0)	
						
			MOVE R14, R9			
			INC2 R2, R0			
			BRA $4F60		; $0C(R0)	
						
			BRA $4FC6		; $70(R0)	
						
			MOVE R14, R15			
			LBI R15, #$05			
			MLH R15, R15			
			LBI R15, #$29			
			INC2 R2, R0			
			BRA $4FE4		; $82(R0)	
						
			BRA $4F66		; $02(R0)	
						
			BRA $4FC6		; $60(R0)	
						
			MOVE R13, $8A			
			SET R13, #$04			
			MOVE $8A, R13			
			MOVE (R5)+, R9			
			MOVE R13, $8C			
			LBI R1, #$03			
			SBC R13, R1			
			BRA $4F7C		; $06(R0)	
						
			ADD R8, R7			
			MOVE (R5), R8			
			BRA $4FB4		; $38(R0)	
						
			MOVE R14, $94			
			SUB R14, R6			
			ADD R14, R7			
			MOVE R15, $90			
			INC2 R2, R0			
			BRA $4FE4		; $5C(R0)	
						
			BRA $4F8E		; $04(R0)	
						
			MOVE (R5)+, R15			
			BRA $4F92		; $04(R0)	
						
			MOVE (R5)+, R14			
			MOVE R14, $92			
			MOVE R15, $96			
			MOVE R13, R15			
			SE R14, R13			
			BRA $4FA6		; $0C(R0)	
						
			MHL R14, R14			
			MHL R13, R13			
			SE R14, R13			
			BRA $4FA6		; $04(R0)	
						
			MOVE (R5), R9			
			BRA $4FA8		; $02(R0)	
						
			MOVE (R5), R15			
			MOVE R15, $94			
			MOVE R14, $96			
			SUB R15, #$01			
			SUB R14, #$01			
			MOVE $94, R15			
			MOVE $96, R14			
			INC2 R2, R0			
			BRA $4FEC		; $34(R0)	
						
			MOVE R15, $90			
			MOVE R14, $92			
			ADD R15, #$02			
			ADD R14, #$02			
			MOVE $90, R15			
			MOVE $92, R14			
			BRA $500E		; $48(R0)	
						
			MOVE R15, $8A			
			SET R15, #$04			
			MOVE $48, R15			
			MOVE R15, $8C			
			MOVE $8A, R15			
			SET R15, #$04			
			MOVE $8C, R15			
			LBI R1, #$03			
			SBC R15, R1			
			BRA $4F7C		; -> -$5E(R0)	
						
			ADD R8, R7			
			MOVE (R5)++, R8			
			MOVE R13, (R5)			
			MOVE $F4, R13			
			BRA $4FB4		; -> -$30(R0)	
						
			LBI R1, #$59			
			MLH R1, R1			
			LBI R1, #$E4			
			RET R1			
						
			MOVE $EE, R2			
			MOVE R14, $92			
			LBI R15, #$05			
			MLH R15, R15			
			LBI R15, #$27			
			LBI R1, #$5C			
			MLH R1, R1			
			LBI R1, #$62			
			INC2 R2, R0			
			RET R1			
						
			JMP ($00EE)			
						
			MOVE $80, R0			
			LBI R15, #$0C			
			LBI R1, #$50			
			MLH R1, R1			
			LBI R1, #$A8			
			RET R1			
						
			MOVE R6, $48			
			LBI R1, #$04			
			SBS R6, R1			
			BRA $5028		; $12(R0)	
						
			MOVE R7, $8A			
			MHL R9, R7			
			CLR R9, #$08			
			LBI R1, #$40			
			SBC R9, R1			
			SET R9, #$08			
			MLH R7, R9			
			MOVE $8A, R7			
			BRA $5048		; $20(R0)	
						
			MOVE R7, $48			
			MHL R9, R7			
			CLR R9, #$08			
			LBI R1, #$40			
			SBC R9, R1			
			SET R9, #$08			
			MLH R7, R9			
			MOVE $48, R7			
			MOVE R7, $8C			
			MHL R9, R7			
			CLR R9, #$08			
			LBI R1, #$40			
			SBC R9, R1			
			SET R9, #$08			
			MLH R7, R9			
			MOVE $8C, R7			
			LBI R7, #$00			
			MLH R7, R7			
			LBI R7, #$8A			
			LBI R8, #$03			
			LBI R9, #$00			
			MLH R9, R9			
			LBI R9, #$F2			
			LBI R1, #$04			
			SBC R6, R1			
			BRA $5076		; $1A(R0)	
						
			LBI R14, #$05			
			MLH R14, R14			
			LBI R14, #$15			
			MOVE R15, (R9)			
			INC2 R2, R0			
			BRA $4FE4		; -> -$84(R0)	
						
			BRA $506C		; $02(R0)	
						
			BRA $508E		; $22(R0)	
						
			LBI R12, #$05			
			MLH R12, R12			
			LBI R12, #$25			
			MOVE (R9), R12			
			BRA $508E		; $18(R0)	
						
			LBI R15, #$00			
			MLH R15, R15			
			LBI R15, #$15			
			MOVE R14, (R9)			
			INC2 R2, R0			
			BRA $4FE4		; -> -$9E(R0)	
						
			BRA $5086		; $02(R0)	
						
			BRA $508E		; $08(R0)	
						
			LBI R12, #$00			
			MLH R12, R12			
			LBI R12, #$01			
			MOVE (R9), R12			
			MOVE R6, (R7)+			
			ADD R9, #$02			
			MOVE R13, (R9)			
			LBI R1, #$77			
			SE R13, R1			
			BRA $50A0		; $06(R0)	
						
			MHL R13, R13			
			SNE R13, R1			
			BRA $50A6		; $06(R0)	
						
			SUB R8, #$01			
			SZ R8			
			BRA $5056		; -> -$50(R0)	
						
			JMP ($00EC)			
						
			LBI R1, #$57			
			MLH R1, R1			
			LBI R1, #$0A			
			INC2 R2, R0			
			RET R1			
						
			MOVE R12, $C6			
			SET R12, #$40			
			CLR R12, #$80			
			MLH R12, R15			
			MOVE $C6, R12			
						
			; Some error condition exists, make			
			; error code			
						
			LBI R1, #$40			
			SGT R15, R1			
			BRA $50E6		; Error 50	
						
			CLR R15, #$E0			
			ADD R0, R15			
						
			; Error 02			
						
			LBI R15, #$F0			
			MLH R15, R15			
			LBI R15, #$F2			
			BRA $5132			
						
			; Error 13			
						
			LBI R15, #$F1			
			MLH R15, R15			
			LBI R15, #$F3			
			BRA $5132			
						
			; Error 70:			
			; ???			
						
			LBI R15, #$F7			
			MLH R15, R15			
			LBI R15, #$F0			
			BRA $5132			
						
			; Error 71:			
			; ???			
						
			LBI R15, #$F7			
			MLH R15, R15			
			LBI R15, #$F1			
			BRA $5132			
						
			LBI R1, #$F5			
			MLH R15, R1			
						
			; Error 50:			
			; End of forms - '+End of forms' line is shown			
						
			ADD R0, R15			
			LBI R15, #$F0			
			BRA $5132		; $42(R0)	
						
			; Error 51:			
			; Printer not ready			
						
			LBI R15, #$F1			
			BRA $5132		; $3E(R0)	
						
			; Error 52:			
			; Forms step time-out			
						
			LBI R15, #$F2			
			BRA $5132		; $3A(R0)	
						
			; Error 53:			
			; Line length too long			
						
			LBI R15, #$F3			
			BRA $5132		; $36(R0)	
						
			; Error 54:			
			; Wire check - Indicates that a print wire driver			
			; was on too long			
						
			LBI R15, #$F4			
			BRA $5132		; $32(R0)	
						
			; Error 55:			
			; Undefined interrupt			
						
			LBI R15, #$F5			
			BRA $5132		; $2E(R0)	
						
			; Error 56:			
			; Incorrect print emitter sequence			
						
			LBI R15, #$F6			
			BRA $5132		; $2A(R0)	
						
			; Error 57:			
			; Missing print emitter pulses			
						
			LBI R15, #$F7			
			BRA $5132		; $26(R0)	
						
			; Error 58:			
			; Timer interrupt time-out			
						
			LBI R15, #$F8			
			BRA $5132		; $22(R0)	
						
			; Error 59:			
			; Overspeed error			
						
			LBI R15, #$F9			
			BRA $5132		; $1E(R0)	
						
			; Error 47:			
			; Print position error -			
			; The print head was not in the position indicated			
			; by the microprogram			
						
			LBI R15, #$F4			
			MLH R15, R15			
			LBI R15, #$F7			
			BRA $5132		; $16(R0)	
						
			; Error 48:			
			; Undetermined unrecoverable error on a sense command			
						
			LBI R15, #$F4			
			MLH R15, R15			
			LBI R15, #$F8			
			BRA $5132		; $0E(R0)	
						
			; Error 72:			
			; ???			
						
			LBI R15, #$F7			
			MLH R15, R15			
			LBI R15, #$F2			
			BRA $5132		; $06(R0)	
						
			; Error 49:			
			; Two or more underscores with a delete			
						
			LBI R15, #$F4			
			MLH R15, R15			
			LBI R15, #$F9			
						
			; Set return value and exit supervisor			
						
			MOVE R13, R3			
			ADD R13, #$0C		; IOCB_Ret	
			MOVE (R13), R15			
			LBI R12, #$51			
			MLH R12, R12			
			LBI R12, #$48			
			MOVE $40, R12		; R2L0 <- $5148 (null handler)	
			CTRL $F, #$10		; Reset printer	
						
			MOVE R2, $D2		; Restore R2	
			MOVE R8, R2			
			JMP ($00AC)		; Exit	
						
						
						
						
						
						
			CTRL $F, #$10		; Reset printer adapter	
			BRA $5148		; Loop on next IRQ	
						
						
			BRA $50A8		; -> -$A6(R0)	
						
			LBI R13, #$03			
			MOVE $4C, R13			
			LBI R10, #$49			
			MLH R10, R10			
			GETB R10, $5			
			MOVE $54, R10			
			LBI R12, #$52			
			MLH R12, R12			
			LBI R12, #$9C			
			CTRL $5, #$D8		; Preset timer counter	
			MOVE $40, R12			
			CTRL $5, #$D1		; Enable timer interrupts	
			LBI R13, #$0A			
			MLH R13, R13			
			LBI R13, #$00			
			SUB R13, #$01			
			MHL R1, R13			
			OR R1, R13			
			SZ R1			
			BRA $517A		; $04(R0)	
						
			LBI R15, #$20			
			BRA $50A8		; -> -$D2(R0)	
						
			MOVE R12, $4C			
			SZ R12			
			BRA $516C		; -> -$14(R0)	
						
			MOVE R13, R3			
			ADD R13, #$02			
			MOVB R12, (R13)			
			LBI R9, #$52			
			MLH R9, R9			
			LBI R9, #$AE			
			MOVE $40, R9			
			CTRL $5, #$E1		; ?	
			SNZ R12			
			BRA $51AC		; $18(R0)	
						
			ADD R13, #$04			
			MOVE R12, (R13)			
			MHL R13, R12			
			OR R12, R13			
			SNZ R12			
			BRA $5214		; $74(R0)	
						
			MOVE R13, $48			
			MOVE R12, $8A			
			OR R12, R13			
			LBI R1, #$20			
			SBS R12, R1			
			BRA $5214		; $68(R0)	
						
			CTRL $5, #$A1		; Enable print emitter int.	
			MHL R10, R10			
			GETB R10, $5			
			LBI R13, #$0B			
			MOVE $4C, R13			
			CTRL $5, #$A0		; Print go latch	
			LBI R13, #$53			
			MLH R13, R13			
			LBI R13, #$F0			
			MOVE $EA, R13			
			MOVE R12, $48			
			MHL R1, R12			
			SET R1, #$02			
			MLH R12, R1			
			CTRL $5, #$D8		; Preset timer counter	
			MOVE $48, R12			
			CTRL $5, #$D1		; Enable timer interrupts	
			MOVE R12, $48			
			LBI R1, #$02			
			SBC R12, R1			
			BRA $520E		; $38(R0)	
						
			MOVE R12, $C6			
			LBI R1, #$20			
			SBS R12, R1			
			BRA $5202		; $24(R0)	
						
			MOVE R8, $C4			
			INC2 R2, R0			
			JMP ($00AC)			
						
			BRA $51FC		; $16(R0)	
						
			MOVE R12, $C6			
			CLR R12, #$20			
			MOVE $C6, R12			
			MOVE R15, $5E			
			MOVE R13, R3			
			ADD R13, #$0C			
			LBI R1, #$40			
			SBC R12, R1			
			MOVE (R13), R15			
			CTRL $F, #$10		; Reset printer	
			BRA $5208		; $0C(R0)	
						
			MOVE $80, R0			
			LBI R15, #$30			
			BRA $514C		; -> -$B6(R0)	
						
			LBI R10, #$49			
			MLH R10, R10			
			GETB R10, $5			
			MOVE R2, $D2			
			MOVE R8, R2			
			JMP ($00AC)			
						
			MOVE R13, $A0			
			LBI R13, #$04			
			BRA $522A		; $16(R0)	
						
			LBI R13, #$56			
			MLH R13, R13			
			LBI R13, #$6E			
			MOVE $EA, R13			
			MHL R10, R10			
			GETB R10, $5			
			LBI R13, #$0B			
			CTRL $5, #$D8		; Preset timer counter	
			MOVE $4C, R13			
			CTRL $5, #$D1		; Enable timer interrupts	
			MOVE R13, $84			
			MOVE $4A, R13			
			MHL R1, R13			
			CLR R1, #$80			
			OR R13, R1			
			SNZ R13			
			BRA $5286		; $50(R0)	
						
			LBI R1, #$80			
			CTRL $5, #$60		; ROS address byte 7	
			MOVE R13, $4A			
			MOVE R5, R13			
			SBSH R13, R1			
			CTRL $5, #$E0		; ROS address byte 6	
			MHL R10, R10			
			GETB R10, $5			
			LBI R14, #$0C			
			MHL R11, R10			
			GETB R11, $5			
			AND R14, R11			
			SE R10, R14			
			BRA $525C		; $0A(R0)	
						
			SUB R13, #$01			
			LBI R1, #$80			
			SBSH R13, R1			
			ADD R13, #$02			
			BRA $526C		; $10(R0)	
						
			LBI R1, #$0C			
			XOR R10, R1			
			SE R10, R14			
			BRA $526C		; $08(R0)	
						
			ADD R13, #$01			
			LBI R1, #$80			
			SBSH R13, R1			
			SUB R13, #$02			
			MOVE $4A, R13			
			INC2 R2, R0			
			BRA $529A		; $28(R0)	
						
			CTRL $5, #$90		; Forms go latch	
			MOVE R4, $48			
			MHL R13, R4			
			CTRL $5, #$91		; Enable forms interrupt	
			SET R13, #$24			
			MLH R4, R13			
			MOVE $48, R4			
			MOVE R13, $A0			
			MOVE $86, R13			
			BRA $5202		; -> -$84(R0)	
						
			LBI R1, #$57			
			MLH R1, R1			
			LBI R1, #$0A			
			INC2 R2, R0			
			RET R1			
						
			MOVE R12, $C6			
			CLR R12, #$9C			
			MOVE $C6, R12			
			CTRL $F, #$10		; Reset printer	
			BRA $5202		; -> -$98(R0)	
						
			BRA $5378		; $DC(R0)	
						
			SUB R6, #$01			
			SNZ R6			
			BRA $52A6		; $04(R0)	
						
			CTRL $5, #$52		; Reset timer interrupt	
			BRA $529C		; -> -$0A(R0)	
						
			CTRL $5, #$51		; Disable timer interrupts	
			NOP			
			CTRL $5, #$52		; Reset timer interrupt	
			HALT			
			MHL R11, R10			
			GETB R11, $5			
			LBI R1, #$01			
			SNBS R11, R1			
			BRA $530A		; $52(R0)	
						
			MHL R10, R10			
			GETB R10, $5			
			LBI R1, #$20			
			SBS R11, R1			
			BRA $52E4		; $22(R0)	
						
			LBI R1, #$E0			
			SNBC R10, R1			
			BRA $52E0		; $18(R0)	
						
			MOVE R13, R10			
			CLR R13, #$1F			
			LBI R1, #$60			
			SNE R13, R1			
			BRA $52E0		; $0E(R0)	
						
			LBI R1, #$A0			
			SLT R13, R1			
			BRA $52E0		; $08(R0)	
						
			LBI R1, #$57			
			MLH R1, R1			
			LBI R1, #$22			
			RET R1			
						
			CTRL $5, #$22		; Reset print emitter int.	
			BRA $52AE		; -> -$36(R0)	
						
			LBI R1, #$02			
			SNBS R11, R1			
			BRA $5302		; $18(R0)	
						
			LBI R1, #$10			
			SBC R11, R1			
			BRA $52F4		; $04(R0)	
						
			LBI R15, #$14			
			BRA $52FE		; $0A(R0)	
						
			LBI R15, #$10			
			STAT R13, $5			
			LBI R1, #$40			
			SNBS R13, R1			
			LBI R15, #$04			
			MOVE $80, R1			
			BRA $5334		; $32(R0)	
						
			LBI R1, #$56			
			MLH R1, R1			
			LBI R1, #$AC			
			RET R1			
						
			LBI R1, #$53			
			MLH R1, R1			
			LBI R1, #$3C			
			MOVE $E8, R1			
			MOVE R13, $86			
			ADD R13, #$01			
			MOVE $86, R13			
			LBI R1, #$10			
			SBS R4, R1			
			BRA $5340		; $22(R0)	
						
			INC2 R2, R0			
			BRA $53D2		; $B0(R0)	
						
			MOVE R13, $86			
			MOVE R1, $8E			
			SLE R13, R1			
			BRA $5330		; $06(R0)	
						
			MOVE R13, $A0			
			MOVE $88, R13			
			JMP ($00EA)			
						
			LBI R15, #$1C			
			MOVE $80, R1			
			LBI R1, #$59			
			MLH R1, R1			
			LBI R1, #$72			
			RET R1			
						
			CTRL $5, #$52		; Reset timer interrupt	
			BRA $52AE		; -> -$92(R0)	
						
			LBI R1, #$20			
			SBSH R4, R1			
			BRA $5350		; $0A(R0)	
						
			LBI R1, #$37			
			SGE R13, R1			
			BRA $5350		; $04(R0)	
						
			LBI R15, #$08			
			BRA $5332		; -> -$1E(R0)	
						
			MOVE R13, $A0			
			MOVE $88, R13			
			MOVE R1, $F0			
			SNZ R1			
			BRA $5388		; $2E(R0)	
						
			MOVE R13, $F0			
			SUB R13, #$01			
			MOVE $F0, R13			
			LBI R1, #$04			
			SNBSH R4, R1			
			BRA $5370		; $0A(R0)	
						
			SZ R13			
			BRA $5388		; $1E(R0)	
						
			CTRL $5, #$10		; Reset forms go latch	
			CLR R4, #$40			
			BRA $5388		; $18(R0)	
						
			MHL R13, R4			
			CLR R13, #$04			
			MLH R4, R13			
			INC2 R2, R0			
			BRA $53D0		; $56(R0)	
						
			MOVE R13, $A0			
			LBI R13, #$0B			
			MOVE $F0, R13			
			LBI R6, #$0C			
			LBI R10, #$49			
			MLH R10, R10			
			GETB R10, $5			
			SUB R6, #$01			
			SNZ R6			
			JMP ($00EA)			
						
			LBI R1, #$02			
			SBSH R4, R1			
			JMP ($00E8)			
						
			MHL R10, R10			
			GETB R10, $5			
			MOVE R13, $CA			
			MOVE R1, R10			
			CLR R1, #$1F			
			SNE R13, R1			
			JMP ($00E8)			
						
			SNZ R1			
			JMP ($00E8)			
						
			MOVE R13, R1			
			LBI R1, #$60			
			SNE R13, R1			
			JMP ($00E8)			
						
			LBI R1, #$A0			
			SLT R13, R1			
			JMP ($00E8)			
						
			LBI R1, #$03			
			MOVE R13, $C6			
			SBC R13, R1			
			JMP ($00E8)			
						
			LBI R1, #$08			
			SBSH R13, R1			
			JMP ($00E8)			
						
			MHL R1, R11			
			SET R1, #$20			
			MLH R11, R1			
			LBI R1, #$57			
			MLH R1, R1			
			LBI R1, #$32			
			RET R1			
						
			BRA $5494		; $C2(R0)	
						
			LBI R13, #$C0			
			LBI R1, #$04			
			SNBC R4, R1			
			XOR R11, R13			
			AND R13, R11			
			STAT R13, $0			
			ADD R0, R13			
			CTRL $5, #$AB		; Print motot latch B	
			RET R2			
						
			CTRL $5, #$A3		; Not print motor latches A+B	
			RET R2			
						
			CTRL $5, #$AF		; Print motor latches A+B	
			RET R2			
						
			CTRL $5, #$A7		; Print motor latch A	
			RET R2			
						
			LBI R1, #$04			
			SNBSH R4, R1			
			BRA $5418		; $22(R0)	
						
			MOVE R13, $F0			
			SZ R13			
			JMP ($00E8)			
						
			LBI R6, #$01			
			INC2 R2, R0			
			BRA $53D2		; -> -$30(R0)	
						
			LBI R13, #$54			
			MLH R13, R13			
			LBI R13, #$24			
			MOVE $EA, R13			
			LBI R10, #$5C			
			MLH R10, R10			
			GETB R10, $5			
			MHL R1, R4			
			CLR R1, #$02			
			MLH R4, R1			
			JMP ($00E8)			
						
			MOVE R6, $A0			
			MLH R4, R13			
			MHL R13, R4			
			SET R13, #$20			
			MLH R4, R13			
			JMP ($00E8)			
						
			INC2 R2, R0			
			BRA $53D2		; -> -$56(R0)	
						
			LBI R13, #$54			
			MLH R13, R13			
			LBI R13, #$3A			
			MOVE $EA, R13			
			LBI R6, #$01			
			LBI R10, #$52			
			MLH R10, R10			
			GETB R10, $5			
			JMP ($00E8)			
						
			INC2 R2, R0			
			BRA $53D2		; -> -$6C(R0)	
						
			LBI R6, #$01			
			LBI R1, #$80			
			SNBC R4, R1			
			BRA $5452		; $0C(R0)	
						
			LBI R10, #$31			
			LBI R13, #$54			
			MLH R13, R13			
			LBI R13, #$B4			
			MOVE $EA, R13			
			BRA $545C		; $0A(R0)	
						
			LBI R13, #$54			
			MLH R13, R13			
			LBI R13, #$62			
			LBI R10, #$3F			
			MOVE $EA, R13			
			MLH R10, R10			
			GETB R10, $5			
			JMP ($00E8)			
						
			INC2 R2, R0			
			BRA $53D2		; -> -$94(R0)	
						
			LBI R13, #$54			
			MLH R13, R13			
			LBI R13, #$78			
			MOVE $EA, R13			
			LBI R10, #$33			
			MLH R10, R10			
			GETB R10, $5			
			LBI R6, #$01			
			JMP ($00E8)			
						
			INC2 R2, R0			
			BRA $53D2		; -> -$AA(R0)	
						
			LBI R13, #$54			
			MLH R13, R13			
			LBI R13, #$90			
			MOVE $EA, R13			
			SET R4, #$10			
			MHL R1, R11			
			SET R1, #$80			
			MLH R11, R1			
			LBI R6, #$01			
			JMP ($00E8)			
						
			LBI R6, #$01			
			JMP ($00E8)			
						
			MHL R10, R10			
			GETB R10, $5			
			LBI R14, #$0C			
			LBI R1, #$80			
			SNBSH R5, R1			
			XOR R10, R14			
			AND R14, R10			
			ADD R0, R14			
			CTRL $5, #$93			
			RET R2			
						
			CTRL $5, #$97			
			RET R2			
						
			CTRL $5, #$9B			
			RET R2			
						
			CTRL $5, #$9F			
			RET R2			
						
			INC2 R2, R0			
			BRA $547A		; -> -$3E(R0)	
						
			LBI R13, #$54			
			MLH R13, R13			
			LBI R13, #$CA			
			MOVE $EA, R13			
			LBI R10, #$20			
			MLH R10, R10			
			GETB R10, $5			
			LBI R6, #$01			
			JMP ($00E8)			
						
			INC2 R2, R0			
			BRA $547A		; -> -$54(R0)	
						
			SET R4, #$10			
			LBI R13, #$54			
			MLH R13, R13			
			LBI R13, #$E2			
			MOVE $EA, R13			
			LBI R10, #$28			
			MLH R10, R10			
			GETB R10, $5			
			LBI R6, #$01			
			JMP ($00E8)			
						
			LBI R13, #$54			
			MLH R13, R13			
			LBI R13, #$F4			
			MOVE $EA, R13			
			LBI R10, #$31			
			MLH R10, R10			
			GETB R10, $5			
			LBI R6, #$01			
			JMP ($00E8)			
						
			LBI R13, #$55			
			MLH R13, R13			
			LBI R13, #$06			
			MOVE $EA, R13			
			LBI R10, #$2C			
			MLH R10, R10			
			GETB R10, $5			
			LBI R6, #$01			
			JMP ($00E8)			
						
			LBI R13, #$55			
			MLH R13, R13			
			LBI R13, #$12			
			MOVE $EA, R13			
			LBI R6, #$01			
			JMP ($00E8)			
						
			LBI R13, #$55			
			MLH R13, R13			
			LBI R13, #$24			
			MOVE $EA, R13			
			LBI R10, #$22			
			MLH R10, R10			
			GETB R10, $5			
			LBI R6, #$01			
			JMP ($00E8)			
						
			MHL R1, R11			
			SET R1, #$80			
			MLH R11, R1			
			LBI R6, #$01			
			JMP ($00E8)			
						
			INC2 R2, R0			
			BRA $547A		; -> -$B8(R0)	
						
			CLR R4, #$10			
			LBI R6, #$01			
			LBI R1, #$80			
			SNBC R4, R1			
			BRA $5546		; $0A(R0)	
						
			LBI R10, #$6F			
			MLH R10, R10			
			GETB R10, $5			
			LBI R10, #$3F			
			BRA $554E		; $08(R0)	
						
			LBI R10, #$3F			
			MLH R10, R10			
			GETB R10, $5			
			LBI R10, #$6F			
			CTRL $5, #$D8			
			MLH R10, R10			
			GETB R10, $5			
			LBI R13, #$55			
			MLH R13, R13			
			LBI R13, #$60			
			MOVE $EA, R13			
			JMP ($00E8)			
						
			BRA $5494		; -> -$CC(R0)	
						
			INC2 R2, R0			
			BRA $5530		; -> -$34(R0)	
						
			LBI R10, #$49			
			MLH R10, R10			
			GETB R10, $5			
			LBI R6, #$01			
			LBI R13, #$55			
			MLH R13, R13			
			LBI R13, #$76			
			MOVE $EA, R13			
			JMP ($00E8)			
						
			INC2 R2, R0			
			BRA $5530		; -> -$4A(R0)	
						
			LBI R1, #$20			
			SBS R4, R1			
			BRA $55B2		; $32(R0)	
						
			MOVE R13, $94			
			MOVE $90, R13			
			MOVE R2, $96			
			MOVE $92, R2			
			LBI R1, #$40			
			SBSH R11, R1			
			BRA $55A4		; $16(R0)	
						
			ADD R13, #$03			
			ADD R2, #$03			
			MOVE $F6, R13			
			LBI R1, #$04			
			SBC R4, R1			
			BRA $55A0		; $06(R0)	
						
			SUB R13, #$06			
			SUB R2, #$06			
			MOVE $F6, R2			
			MOVE $96, R2			
			MOVE $94, R13			
			MHL R1, R11			
			CLR R1, #$44			
			MLH R11, R1			
			MOVE R13, $9E			
			MOVE $9A, R13			
			MOVE R13, $9C			
			MOVE $98, R13			
			MOVE R13, $F4			
			MOVE $F2, R13			
			MOVE R13, $F6			
			MOVE $F4, R13			
			LBI R13, #$77			
			MLH R13, R13			
			MOVE $F6, R13			
			MOVE R1, $8A			
			LBI R13, #$08			
			AND R4, R13			
			OR R1, R4			
			MHL R4, R1			
			SET R4, #$02			
			MLH R1, R4			
			MOVE R4, R1			
			MOVE R13, $8C			
			MOVE $8A, R13			
			LBI R1, #$04			
			XOR R13, R1			
			MOVE $8C, R13			
			MOVE R13, $F2			
			LBI R1, #$77			
			SE R13, R1			
			BRA $55FA		; $18(R0)	
						
			MHL R13, R13			
			SE R13, R1			
			BRA $55FA		; $12(R0)	
						
			LBI R13, #$56			
			MLH R13, R13			
			LBI R13, #$6E			
			MOVE $EA, R13			
			LBI R6, #$0B			
			LBI R1, #$40			
			SNBS R4, R1			
			BRA $5616		; $1E(R0)	
						
			JMP ($00E8)			
						
			LBI R6, #$08			
			LBI R1, #$80			
			SBC R4, R1			
			LBI R6, #$16			
			LBI R13, #$53			
			MLH R13, R13			
			LBI R13, #$F0			
			MOVE $EA, R13			
			LBI R1, #$02			
			SBS R4, R1			
			JMP ($00E8)			
						
			MOVE R5, $A0			
			LBI R5, #$04			
			BRA $5618		; $02(R0)	
						
			MOVE R5, $84			
			LBI R1, #$80			
			CTRL $5, #$60			
			SBSH R5, R1			
			CTRL $5, #$E0			
			LBI R1, #$02			
			SBS R10, R1			
			BRA $5668		; $42(R0)	
						
			LBI R1, #$04			
			SNBSH R4, R1			
			JMP ($00E8)			
						
			MHL R10, R10			
			GETB R10, $5			
			LBI R14, #$0C			
			AND R10, R14			
			AND R14, R11			
			SE R10, R14			
			BRA $5644		; $0A(R0)	
						
			LBI R1, #$80			
			SUB R5, #$01			
			SBSH R5, R1			
			ADD R5, #$02			
			BRA $5654		; $10(R0)	
						
			LBI R1, #$0C			
			XOR R14, R1			
			SE R14, R10			
			BRA $5654		; $08(R0)	
						
			ADD R5, #$01			
			LBI R1, #$80			
			SBSH R5, R1			
			SUB R5, #$02			
			INC2 R2, R0			
			BRA $555E		; -> -$FA(R0)	
						
			CTRL $5, #$90			
			MHL R13, R4			
			CTRL $5, #$91			
			SET R13, #$24			
			MLH R4, R13			
			MOVE R13, $A0			
			MOVE $86, R13			
			JMP ($00E8)			
						
			LBI R15, #$00			
			MOVE $80, R1			
			BRA $5708		; $9A(R0)	
						
			CTRL $5, #$20			
			LBI R1, #$40			
			SNBC R4, R1			
			BRA $568C		; $16(R0)	
						
			MHL R13, R4			
			CLR R13, #$02			
			MLH R4, R13			
			MOVE R1, $F0			
			SNZ R1			
			BRA $5686		; $04(R0)	
						
			MOVE R6, $F0			
			JMP ($00E8)			
						
			SET R13, #$20			
			MLH R4, R13			
			JMP ($00E8)			
						
			CTRL $5, #$21			
			MOVE R12, $C6			
			CLR R12, #$9C			
			CTRL $5, #$51			
			MOVE $C6, R12			
			CTRL $5, #$61			
			INC2 R2, R0			
			BRA $570A		; $6E(R0)	
						
			CTRL $5, #$52			
			NOP			
			CTRL $5, #$22			
			NOP			
			CTRL $5, #$62			
			NOP			
			CTRL $5, #$12			
			BRA $569C		; -> -$10(R0)	
						
			CTRL $5, #$11			
			MHL R13, R4			
			CLR R13, #$20			
			MLH R4, R13			
			LBI R1, #$04			
			SBS R13, R1			
			BRA $56FE		; $44(R0)	
						
			SUB R5, #$01			
			CLR R13, #$20			
			MLH R4, R13			
			MHL R13, R5			
			CLR R13, #$80			
			SZ R13			
			BRA $56CE		; $06(R0)	
						
			LBI R1, #$01			
			SNE R5, R1			
			BRA $56D6		; $08(R0)	
						
			CTRL $5, #$91			
			INC2 R2, R0			
			BRA $5656		; -> -$7E(R0)	
						
			BRA $56FE		; $28(R0)	
						
			LBI R1, #$80			
			MHL R13, R5			
			XOR R13, R1			
			MLH R5, R13			
			LBI R6, #$01			
			MOVE $F0, R6			
			LBI R10, #$10			
			MLH R10, R10			
			GETB R10, $5			
			LBI R10, #$49			
			CTRL $5, #$D8			
			NOP			
			CTRL $5, #$D1			
			MLH R10, R10			
			GETB R10, $5			
			INC2 R2, R0			
			BRA $5656		; -> -$A2(R0)	
						
			LBI R1, #$80			
			XOR R13, R1			
			MLH R5, R13			
			CTRL $5, #$12			
			LBI R1, #$52			
			MLH R1, R1			
			LBI R1, #$AE			
			RET R1			
						
			BRA $57E8		; $DE(R0)	
						
			MOVE R13, R3			
			ADD R13, #$10			
			MOVE R12, (R13)			
			CLR R12, #$10			
			MOVE (R13), R12			
			MOVE R13, $A4			
			MHL R12, R13			
			CLR R12, #$02			
			MLH R13, R12			
			CLR R13, #$08			
			MOVE $A4, R13			
			RET R2			
						
			LBI R1, #$80			
			SBSH R11, R1			
			BRA $5732		; $0A(R0)	
						
			MHL R11, R10			
			GETB R11, $5			
			LBI R1, #$01			
			SBC R11, R1			
			BRA $579C		; $6A(R0)	
						
			MOVE R13, $C8			
			MOVE R12, R10			
			LBI R1, #$E0			
			AND R12, R1			
			MOVE R9, $CA			
			SNE R12, R9			
			BRA $57D0		; $90(R0)	
						
			ADD R9, R9			
			SNZ R9			
			LBI R9, #$20			
			SE R9, R12			
			BRA $5756		; $0C(R0)	
						
			ADD R13, #$01			
			MOVE $C8, R13			
			LBI R1, #$04			
			SBC R4, R1			
			BRA $57D0		; $7C(R0)	
						
			BRA $5760		; $0A(R0)	
						
			SUB R13, #$01			
			MOVE $C8, R13			
			LBI R1, #$04			
			SBS R4, R1			
			BRA $57D0		; $70(R0)	
						
			LBI R1, #$80			
			SBSH R11, R1			
			BRA $5774		; $0E(R0)	
						
			MHL R11, R10			
			GETB R11, $5			
			LBI R1, #$01			
			SBC R11, R1			
			BRA $579C		; $2C(R0)	
						
			LBI R9, #$05			
			BRA $577C		; $08(R0)	
						
			LBI R1, #$10			
			SBS R4, R1			
			BRA $5786		; $0C(R0)	
						
			LBI R9, #$06			
			MOVE R13, $88			
			ADD R13, #$01			
			MOVE $88, R13			
			SLT R13, R9			
			BRA $57E4		; $5E(R0)	
						
			MOVE R1, $A0			
			MOVE $86, R1			
			MLH R12, R1			
			MOVE $CA, R12			
			LBI R1, #$20			
			SNBSH R11, R1			
			BRA $57EA		; $56(R0)	
						
			MHL R11, R10			
			GETB R11, $5			
			LBI R1, #$01			
			SBC R11, R1			
			BRA $5894		; $F6(R0)	
						
			LBI R1, #$03			
			MOVE R13, $C6			
			SBC R13, R1			
			BRA $57B8		; $12(R0)	
						
			MOVE R13, $C8			
			MHL R1, R13			
			SNS R1			
			BRA $57B8		; $0A(R0)	
						
			SZ R1			
			BRA $5862		; $B0(R0)	
						
			LBI R1, #$01			
			SLT R13, R1			
			BRA $5862		; $AA(R0)	
						
			LBI R1, #$01			
			SBS R10, R1			
			BRA $5804		; $46(R0)	
						
			LBI R1, #$08			
			SNBS R4, R1			
			BRA $5862		; $9E(R0)	
						
			SET R4, #$08			
			MOVE R13, $C6			
			LBI R1, #$02			
			SBS R13, R1			
			BRA $5862		; $94(R0)	
						
			BRA $57F2		; $22(R0)	
						
			LBI R1, #$10			
			SBS R4, R1			
			BRA $5786		; -> -$50(R0)	
						
			LBI R1, #$08			
			SBC R4, R1			
			BRA $5786		; -> -$56(R0)	
						
			LBI R15, #$18			
			BRA $57E2		; $02(R0)	
						
			LBI R15, #$28			
			BRA $57E6		; $02(R0)	
						
			LBI R15, #$24			
			MOVE $80, R1			
			BRA $58C0		; $D6(R0)	
						
			MHL R1, R11			
			CLR R1, #$28			
			MLH R11, R1			
			JMP ($00E8)			
						
			LBI R13, #$FF			
			MLH R13, R13			
			LBI R13, #$FC			
			MOVE $C8, R13			
			MOVE R13, $C6			
			SET R13, #$01			
			CLR R13, #$02			
			MOVE $C6, R13			
			BRA $5862		; $5E(R0)	
						
			LBI R1, #$80			
			SBS R10, R1			
			BRA $5862		; $58(R0)	
						
			LBI R1, #$08			
			SBS R4, R1			
			BRA $5862		; $52(R0)	
						
			CLR R4, #$08			
			MOVE R13, $C6			
			LBI R1, #$01			
			SBC R13, R1			
			BRA $5856		; $3C(R0)	
						
			MOVE R13, $C8			
			MHL R1, R13			
			OR R13, R1			
			SNZ R13			
			BRA $5856		; $32(R0)	
						
			LBI R1, #$FF			
			MOVE R13, $C8			
			SNE R13, R1			
			BRA $5832		; $06(R0)	
						
			LBI R1, #$FE			
			SE R13, R1			
			BRA $583A		; $08(R0)	
						
			LBI R1, #$FF			
			MHL R13, R13			
			SNE R13, R1			
			BRA $5856		; $1C(R0)	
						
			LBI R1, #$D4			
			MOVE R13, $F2			
			SE R13, R1			
			BRA $5848		; $06(R0)	
						
			MHL R13, R13			
			SNS R13			
			BRA $5856		; $0E(R0)	
						
			LBI R1, #$D4			
			MOVE R13, $F4			
			SE R13, R1			
			BRA $57E0		; -> -$70(R0)	
						
			MHL R13, R13			
			SS R13			
			BRA $57E0		; -> -$76(R0)	
						
			LBI R13, #$FF			
			MLH R13, R13			
			MOVE $C8, R13			
			MOVE R13, $C6			
			CLR R13, #$03			
			MOVE $C6, R13			
			MHL R11, R10			
			GETB R11, $5			
			LBI R1, #$01			
			SBC R11, R1			
			BRA $5894		; $28(R0)	
						
			MOVE R1, $F2			
			MOVE R13, $C8			
			SE R13, R1			
			BRA $588C		; $18(R0)	
						
			MHL R1, R1			
			MHL R13, R13			
			SE R13, R1			
			BRA $588C		; $10(R0)	
						
			LBI R13, #$55			
			MLH R13, R13			
			LBI R13, #$2E			
			MOVE $EA, R13			
			MHL R13, R11			
			CLR R13, #$80			
			MLH R11, R13			
			CLR R4, #$10			
			MHL R11, R10			
			GETB R11, $5			
			LBI R1, #$01			
			SBC R11, R1			
			BRA $598C		; $F6(R0)	
						
			LBI R1, #$20			
			SBS R4, R1			
			BRA $599A		; $FE(R0)	
						
			MOVE R15, $C8			
			MHL R13, R15			
			LBI R1, #$10			
			SBSH R11, R1			
			BRA $58D6		; $30(R0)	
						
			LBI R1, #$04			
			SBC R4, R1			
			BRA $58C2		; $16(R0)	
						
			MOVE R14, $92			
			MHL R12, R14			
			SE R13, R12			
			BRA $5900		; $4C(R0)	
						
			SE R15, R14			
			BRA $5900		; $48(R0)	
						
			MHL R1, R11			
			CLR R1, #$10			
			MLH R11, R1			
			BRA $5900		; $40(R0)	
						
			BRA $5972		; $B0(R0)	
						
			MOVE R14, $90			
			MHL R12, R14			
			SE R13, R12			
			BRA $5940		; $76(R0)	
						
			SE R15, R14			
			BRA $5940		; $72(R0)	
						
			MHL R1, R11			
			CLR R1, #$10			
			MLH R11, R1			
			BRA $5940		; $6A(R0)	
						
			LBI R1, #$04			
			SBC R4, R1			
			BRA $591C		; $40(R0)	
						
			MOVE R14, $90			
			MHL R12, R14			
			SE R13, R12			
			BRA $59C0		; $DC(R0)	
						
			SE R15, R14			
			BRA $59C0		; $D8(R0)	
						
			MOVE R14, $92			
			MHL R12, R14			
			SE R13, R12			
			BRA $58F4		; $04(R0)	
						
			SNE R14, R15			
			BRA $58FA		; $06(R0)	
						
			MHL R1, R11			
			SET R1, #$10			
			MLH R11, R1			
			MOVE R8, $98			
			MOVE R15, $9A			
			BRA $5908		; $08(R0)	
						
			ADD R7, #$01			
			MOVE R1, $80			
			SE R7, R1			
			BRA $5946		; $3E(R0)	
						
			MOVE R7, $A0			
			MHL R11, R10			
			GETB R11, $5			
			LBI R1, #$01			
			SBC R11, R1			
			BRA $598C		; $78(R0)	
						
			INC2 R2, R0			
			BRA $5A08		; $F0(R0)	
						
			ADD R8, #$01			
			BRA $5946		; $2A(R0)	
						
			MOVE R14, $92			
			MHL R12, R14			
			SE R13, R12			
			BRA $59C0		; $9C(R0)	
						
			SE R14, R15			
			BRA $59C0		; $98(R0)	
						
			MOVE R14, $90			
			MHL R12, R14			
			SE R13, R12			
			BRA $5934		; $04(R0)	
						
			SNE R14, R15			
			BRA $593A		; $06(R0)	
						
			MHL R1, R11			
			SET R1, #$10			
			MLH R11, R1			
			MOVE R8, $9A			
			MOVE R15, $98			
			BRA $59C4		; $84(R0)	
						
			SNZ R7			
			BRA $59C4		; $80(R0)	
						
			SUB R7, #$01			
			MHL R11, R10			
			GETB R11, $5			
			LBI R1, #$01			
			SBC R11, R1			
			BRA $598C		; $3C(R0)	
						
			LBI R1, #$03			
			SNBC R4, R1			
			BRA $597C		; $26(R0)	
						
			LBI R1, #$02			
			SBS R4, R1			
			BRA $597E		; $22(R0)	
						
			MOVE R9, $A0			
			LBI R1, #$01			
			SBSH R4, R1			
			BRA $597E		; $1A(R0)	
						
			LBI R1, #$F8			
			SBC R7, R1			
			BRA $597E		; $14(R0)	
						
			LBI R1, #$01			
			SBC R7, R1			
			LBI R9, #$05			
			BRA $597E		; $0C(R0)	
						
			CTRL $5, #$00			
			LBI R1, #$50			
			MLH R1, R1			
			LBI R1, #$A8			
			RET R1			
						
			MOVE R9, R7			
			LBI R1, #$59			
			MLH R1, R1			
			LBI R1, #$98			
			ADD R9, R9			
			ADD R9, R9			
			ADD R1, R9			
			RET R1			
						
			MOVE $E8, R1			
			CTRL $5, #$52			
			LBI R1, #$53			
			MLH R1, R1			
			LBI R1, #$12			
			RET R1			
						
			CTRL $5, #$60			
			BRA $59DA		; $3E(R0)	
						
			CTRL $5, #$EC			
			BRA $59DA		; $3A(R0)	
						
			CTRL $5, #$6C			
			BRA $59DA		; $36(R0)	
						
			CTRL $5, #$E4			
			BRA $59DA		; $32(R0)	
						
			CTRL $5, #$64			
			BRA $59DA		; $2E(R0)	
						
			CTRL $5, #$E8			
			BRA $59DA		; $2A(R0)	
						
			CTRL $5, #$68			
			BRA $59DA		; $26(R0)	
						
			CTRL $5, #$E0			
			BRA $59DA		; $22(R0)	
						
			CTRL $5, #$60			
			BRA $59DA		; $1E(R0)	
						
			CTRL $5, #$60			
			BRA $59DA		; $1A(R0)	
						
			CTRL $5, #$54			
			BRA $59DA		; $16(R0)	
						
			MOVE R7, $80			
			SUB R7, #$01			
			MHL R11, R10			
			GETB R11, $5			
			LBI R1, #$01			
			SBC R11, R1			
			BRA $598C		; -> -$46(R0)	
						
			INC2 R2, R0			
			BRA $5A08		; $32(R0)	
						
			SUB R8, #$01			
			BRA $5946		; -> -$94(R0)	
						
			CTRL $5, #$22			
			LBI R1, #$52			
			MLH R1, R1			
			LBI R1, #$AE			
			RET R1			
						
			MHL R13, R15			
			MHL R12, R14			
			LBI R1, #$80			
			SBC R13, R1			
			BRA $5A00		; $12(R0)	
						
			SBC R12, R1			
			RET R2			
						
			SLE R12, R13			
			BRA $59FC		; $06(R0)	
						
			SE R13, R12			
			RET R2			
						
			SLE R14, R15			
			ADD R2, #$02			
			RET R2			
						
			LBI R1, #$80			
			SBS R12, R1			
			BRA $59FC		; -> -$0A(R0)	
						
			BRA $59FA		; -> -$0E(R0)	
						
			MOVE $EE, R2			
			LBI R1, #$01			
			SBC R4, R1			
			BRA $5A5A		; $4A(R0)	
						
			LBI R1, #$02			
			SBC R4, R1			
			BRA $5A34		; $1E(R0)	
						
			INC2 R2, R0			
			BRA $5AEA		; $D0(R0)	
						
			NOP			
			MHL R11, R10			
			GETB R11, $5			
			LBI R1, #$01			
			SBC R11, R1			
			BRA $598C		; -> -$9A(R0)	
						
			CTRL $5, #$D4			
			LBI R1, #$00			
			MLH R1, R1			
			LBI R1, #$58			
			ADD R1, #$01			
			PUTB $5, (R1)			
			JMP ($00EE)			
						
			INC2 R2, R0			
			BRA $5AEA		; $B2(R0)	
						
			NOP			
			INC2 R2, R0			
			BRA $5B34		; $F6(R0)	
						
			BRA $5A4E		; $0E(R0)	
						
			MOVE R12, $A0			
			MOVE R9, R12			
			MHL R1, R4			
			CLR R1, #$01			
			MLH R4, R1			
			BRA $5A1A		; -> -$32(R0)	
						
			BRA $5972		; -> -$DC(R0)	
						
			MOVE R12, $A0			
			LBI R12, #$00			
			MHL R1, R4			
			SET R1, #$01			
			MLH R4, R1			
			BRA $5A1A		; -> -$40(R0)	
						
			LBI R1, #$44			
			MHL R13, R11			
			SBC R13, R1			
			BRA $5AD0		; $6E(R0)	
						
			MOVE R13, $F4			
			LBI R1, #$77			
			SE R13, R1			
			BRA $5A70		; $06(R0)	
						
			MHL R13, R13			
			SNE R13, R1			
			BRA $5A7C		; $0C(R0)	
						
			INC2 R2, R0			
			BRA $5A9C		; $28(R0)	
						
			BRA $5A7C		; $06(R0)	
						
			LBI R1, #$01			
			SBS R8, R1			
			BRA $5A40		; -> -$3C(R0)	
						
			MHL R11, R10			
			GETB R11, $5			
			LBI R1, #$01			
			SBC R11, R1			
			BRA $598C		; -> -$FA(R0)	
						
			MOVE R12, $A0			
			MOVB R12, (R8)			
			MOVE R9, R12			
			SHR R12			
			SHR R12			
			ADD R9, R9			
			CLR R9, #$F9			
			ADD R9, #$01			
			MOVE R1, $A0			
			MOVB (R8), R1			
			BRA $5A1A		; -> -$82(R0)	
						
			MOVE $EC, R2			
			MHL R11, R10			
			GETB R11, $5			
			LBI R1, #$01			
			SBC R11, R1			
			BRA $5A84		; -> -$24(R0)	
						
			MOVE R15, $9E			
			MOVE R14, R8			
			INC2 R2, R0			
			BRA $5BA4		; $F4(R0)	
						
			BRA $5AB4		; $02(R0)	
						
			JMP ($00EC)			
						
			MOVE R15, R14			
			MOVE R14, $9C			
			INC2 R2, R0			
			BRA $5BA4		; $E8(R0)	
						
			BRA $5AC0		; $02(R0)	
						
			JMP ($00EC)			
						
			MHL R11, R10			
			GETB R11, $5			
			LBI R1, #$01			
			SBC R11, R1			
			BRA $5A84		; -> -$46(R0)	
						
			MOVE R2, $EC			
			ADD R2, #$02			
			RET R2			
						
			INC2 R2, R0			
			BRA $5A9C		; -> -$38(R0)	
						
			BRA $5A7C		; -> -$5A(R0)	
						
			MHL R14, R6			
			ADD R14, #$01			
			CLR R14, #$FC			
			MLH R6, R14			
			LBI R1, #$03			
			SE R14, R1			
			BRA $5A40		; -> -$A4(R0)	
						
			LBI R14, #$00			
			MLH R6, R14			
			BRA $5A7C		; -> -$6E(R0)	
						
			MOVB R12, (R8)			
			LBI R1, #$01			
			SBC R4, R1			
			BRA $5B10		; $1E(R0)	
						
			LBI R1, #$40			
			SGT R12, R1			
			BRA $5B0A		; $12(R0)	
						
			SS R12			
			RET R2			
						
			MHL R12, R4			
			LBI R1, #$08			
			XOR R12, R1			
			MLH R4, R12			
			LBI R1, #$10			
			SBC R12, R1			
			BRA $5B16		; $0C(R0)	
						
			LBI R12, #$40			
			ADD R2, #$02			
			RET R2			
						
			SZ R12			
			RET R2			
						
			BRA $5B0C		; -> -$0A(R0)	
						
			SE R8, R15			
			BRA $5B22		; $08(R0)	
						
			MHL R1, R8			
			MHL R12, R15			
			SNE R12, R1			
			BRA $5B0A		; -> -$18(R0)	
						
			ADD R8, #$01			
			LBI R1, #$04			
			SBC R4, R1			
			SUB R8, #$02			
			MOVB R12, (R8)			
			SS R12			
			BRA $5AEA		; -> -$46(R0)	
						
			LBI R15, #$40			
			BRA $5A4C		; -> -$E8(R0)	
						
			LBI R1, #$01			
			SBC R4, R1			
			BRA $5B8E		; $54(R0)	
						
			LBI R1, #$6D			
			SNE R12, R1			
			RET R2			
						
			MOVE R1, $A2			
			MLH R1, R1			
			LBI R1, #$20			
			SNBSH R1, R1			
			BRA $5B84		; $3A(R0)	
						
			LBI R1, #$40			
			SNE R12, R1			
			INC2 R0, R2			
			SGT R12, R1			
			BRA $5B84		; $30(R0)	
						
			LBI R1, #$74			
			SLT R12, R1			
			BRA $5B84		; $2A(R0)	
						
			LBI R1, #$4A			
			SGE R12, R1			
			RET R2			
						
			LBI R1, #$50			
			SGT R12, R1			
			BRA $5B84		; $1E(R0)	
						
			LBI R1, #$5A			
			SGE R12, R1			
			RET R2			
						
			LBI R1, #$61			
			SGT R12, R1			
			BRA $5B84		; $12(R0)	
						
			LBI R1, #$6A			
			SGE R12, R1			
			RET R2			
						
			LBI R1, #$70			
			SNE R12, R1			
			RET R2			
						
			LBI R1, #$73			
			SNE R12, R1			
			RET R2			
						
			MHL R9, R4			
			LBI R1, #$08			
			SBC R9, R1			
			RET R2			
						
			INC2 R0, R2			
			MOVE R6, R2			
			MLH R12, R12			
			MOVE R9, $56			
			LBI R1, #$40			
			SNBSH R9, R1			
			BRA $5C3C		; $A2(R0)	
						
			LBI R1, #$04			
			SNBSH R9, R1			
			BRA $5C3C		; $9C(R0)	
						
			ADD R14, #$09			
			INC2 R2, R0			
			BRA $5C62		; $BC(R0)	
						
			BRA $5BAA		; $02(R0)	
						
			BRA $5BD0		; $26(R0)	
						
			MOVE R2, R6			
			INC R6, R14			
			MLH R6, R6			
			INC2 R7, R8			
			MOVE R14, R8			
			MHL R12, R12			
			MOVB R9, (R7)++			
			AND R12, R9			
			SE R7, R6			
			BRA $5BB6		; -> -$08(R0)	
						
			SNBS R12, R0			
			BRA $5BD6		; $14(R0)	
						
			MOVE R9, $56			
			MHL R1, R9			
			SET R1, #$05			
			MLH R9, R1			
			MOVE $56, R9			
			MHL R6, R6			
			BRA $5BD6		; $06(R0)	
						
			MOVE R2, R6			
			INC R6, R15			
			MOVE R14, R8			
			MOVE R9, $A0			
			MHL R12, R9			
			MOVB R9, (R14)+			
			SZ R9			
			BRA $5BE6		; $06(R0)	
						
			SE R14, R6			
			BRA $5BDA		; -> -$0A(R0)	
						
			BRA $5C02		; $1C(R0)	
						
			LBI R1, #$01			
			SBS R9, R1			
			BRA $5BF4		; $08(R0)	
						
			ADD R12, #$01			
			LBI R1, #$19			
			SLT R12, R1			
			BRA $5BF8		; $04(R0)	
						
			SHR R9			
			BRA $5BDC		; -> -$1C(R0)	
						
			MOVE R9, $56			
			MHL R1, R9			
			SET R1, #$41			
			MLH R9, R1			
			MOVE $56, R9			
			MOVE R14, R8			
			MHL R12, R12			
			MOVE R1, R15			
			SE R8, R1			
			BRA $5C14		; $08(R0)	
						
			MHL R1, R15			
			MHL R9, R8			
			SNE R9, R1			
			INC2 R0, R2			
			MOVE R9, R14			
			ADD R9, #$01			
			MOVB R9, (R9)			
			AND R9, R12			
			SNZ R9			
			BRA $5C2A		; $0A(R0)	
						
			MOVE R9, $56			
			MHL R1, R9			
			SET R1, #$03			
			MLH R9, R1			
			MOVE $56, R9			
			MOVE R9, $56			
			LBI R1, #$01			
			SBSH R9, R1			
			INC2 R0, R2			
			MHL R1, R9			
			CLR R1, #$01			
			MLH R9, R1			
			MOVE $56, R9			
			RET R2			
						
			MOVE R7, R15			
			SUB R14, #$09			
			MOVE R15, R14			
			MOVE R14, $98			
			INC2 R2, R0			
			BRA $5C62		; $1A(R0)	
						
			BRA $5C52		; $08(R0)	
						
			MOVE R2, R6			
			INC R6, R8			
			MOVE R15, R7			
			BRA $5BD6		; -> -$7C(R0)	
						
			MOVE R2, R6			
			MOVE R14, R15			
			MOVE R15, R7			
			INC2 R6, R8			
			INC R7, R14			
			INC R1, R8			
			MLH R6, R1			
			BRA $5BB4		; -> -$AE(R0)	
						
			MHL R9, R15			
			MHL R12, R14			
			SLE R9, R12			
			BRA $5C70		; $06(R0)	
						
			SNE R9, R12			
			SLE R14, R15			
			ADD R2, #$02			
			RET R2			
						
						
			dw 0			
						
						
						
						
      ORG $5FDE						
			LBI R1, #$05			
			MLH R1, R1			
			LBI R1, #$03			
			MOVE $1C4, R1		; $1C4 <- $0503	
						
			; Put address of printer I/O supervisor routine			
			; into vector table (entry for system device 5)			
			LBI R1, #$4A			
			MLH R1, R1			
			LBI R1, #$00		; $4A00	
			MOVE R4, $D8			
			ADD R4, #$14			
			MOVE (R4), R1			
						
			; Setup system variable for I/O supervisor			
			LBI R1, #$40			
			MLH R1, R1			
			LBI R1, #$00			
			MOVE $AE, R1			
						
			; Return to caller			
			MOVE R8, R2			
			JMP ($00AC)			
						
			; Entry point of setup routine			
			BRA $5FDE			
						
						
						
						
						
						
						
						
						
						
						
						
						
			MOVE $D2, R2		; Save R2	
			CTRL $F, #$40		; Reset tape adapter	
						
			MOVE R8, $A6			
			INC2 R2, R0			
			JMP ($00AC)		; Test device	
			BRA $6054		; Device error	
						
			MOVE R14, R3			
			ADD R14, #$10		; IOCB_Stat1	
			LBI R5, #$E2			
			MLH R5, R5			
			LBI R5, #$84			
			MOVE (R14), R5		; IOCB_Stat1 <- $E284	
			MOVE R8, $C4			
			INC2 R2, R0			
			JMP ($00AC)			
			BRA $6054		; Error	
						
			DEC R5, R3			
			MOVE $80, R5			
						
			MOVE R14, $80			
			ADD R14, #$05			
			MOVE R5, (R14)		; IOCB_BA	
			SUB R5, #$01			
			MOVE $84, R5			
						
			MOVE R14, $80			
			ADD R14, #$0B			
			MOVE R5, (R14)		; IOCB_WA	
			MOVE R15, R5			
			SUB R5, #$01			
			MOVE $82, R5			
			ADD R15, #$26			
						
			MOVE R14, $80			
			ADD R14, #$01			
			MOVB R5, (R14)		; IOCB_DA	
			LBI R1, #$0E			
			SE R1, R5			
			BRA $605C		; Error, not device E	
						
			MOVE R14, $80			
			ADD R14, #$03		; IOCB_Cmd	
			MOVB R5, (R14)			
			SNZ R5			
			BRA $614E		; Sense	
			BRA $6064		; Other command	
						
						
			; Exit			
			LBI R1, #$61			
			MLH R1, R1			
			LBI R1, #$AE			
			RET R1			; JMP $61AE
						
						
			; Error 02			
			LBI R1, #$61			
			MLH R1, R1			
			LBI R1, #$98			
			RET R1			; JMP $6198
						
						
			; Command other than Sense			
			MOVE R14, $80			
			ADD R14, #$0B		; IOCB_WA	
			MOVE R5, (R14)			
			MHL R5, R5			
			SNZ R5			
			BRA $605C		; Error, no WA specified	
						
			LBI R5, #$61			
			MLH R5, R5			
			LBI R5, #$50		; R5 <- $6150	
			MOVE $9A, R5			
						
			LBI R5, #$7B			
			MLH R5, R5			
			LBI R5, #$1A		; R5 <- $7B1A	
			MOVE $9C, R5			
						
			MOVE R14, $82			
			ADD R14, #$11			
			MOVE R5, (R14)		; IOCB_WA+$10	
			MOVE $92, R5			
						
			; CLR 3FFF			
			MOVE R1, $92			
			CLR R1, #$FF			
			MHL R14, R1			
			CLR R14, #$3F			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Save several IOCB values			
			MOVE R14, $82			
			ADD R14, #$03			
			MOVE R5, (R14)			
			MOVE $EC, R5		; IOCB_WA+2	
			ADD R14, #$02			
			MOVE R5, (R14)			
			MOVE $EE, R5		; IOCB_WA+4	
			ADD R14, #$04			
			MOVE R5, (R14)			
			MOVE $F0, R5		; IOCB_WA+8	
			ADD R14, #$02			
			MOVE R5, (R14)			
			MOVE $F2, R5		; IOCB_WA+A	
			ADD R14, #$0A			
			MOVE R5, (R14)			
			MOVE $F4, R5		; IOCB_WA+14	
			ADD R14, #$04			
			MOVE R5, (R14)			
			MOVE $F6, R5		; IOCB_WA+18	
			MOVE R14, $80			
			ADD R14, #$09			
			MOVE R5, (R14)			
			MOVE $E8, R5		; IOCB_CI1	
			ADD R14, #$04			
			MOVE R5, (R14)			
			MOVE $EA, R5		; IOCB_Ret	
						
			; Call I/O switch			
			LBI R1, #$61			
			MLH R1, R1			
			LBI R1, #$B4			
			MOVE $96, R0		; save return address	
			JMP ($009A)			
						
			; Restore IOCB			
			MOVE R5, $EC			
			MOVE R14, $82			
			ADD R14, #$03			
			MOVE (R14), R5		; IOCB_WA+2	
			ADD R14, #$02			
			MOVE R5, $EE			
			MOVE (R14), R5		; IOCB_WA+4	
			ADD R14, #$04			
			MOVE R5, $F0			
			MOVE (R14), R5		; IOCB_WA+8	
			ADD R14, #$02			
			MOVE R5, $F2			
			MOVE (R14), R5		; IOCB_WA+A	
			ADD R14, #$0A			
			MOVE R5, $F4			
			MOVE (R14), R5		; IOCB_WA+14	
			ADD R14, #$04			
			MOVE R5, $F6			
			MOVE (R14), R5		; IOCB_WA+18	
			MOVE R5, $E8			
			MOVE R14, $80			
			ADD R14, #$09			
			MOVE (R14), R5		; IOCB_CI1	
			ADD R14, #$04			
			MOVE R5, $EA			
			MOVE (R14), R5		; IOCB_Ret	
						
			; Test for error 02			
			MOVE R14, $80			
			ADD R14, #$0D			
			MOVE R5, (R14)		; IOCB_Ret	
			LBI R1, #$F2			
			SE R1, R5			
			BRA $611C		; $0A(R0)	
			MHL R5, R5			
			LBI R1, #$F0			
			SE R1, R5			
			BRA $611C		; $02(R0)	
			BRA $6128		; $0C(R0)	
						
			; No error 02			
			MOVE R14, $80			
			ADD R14, #$03			
			MOVB R5, (R14)		; IOCB_Cmd	
			MOVE R14, $82			
			ADD R14, #$0F			
			MOVE (R14), R5		; Save last command in WA	
						
			; CLR 0200			
			MOVE R1, $92			
			CLR R1, #$00			
			MHL R14, R1			
			CLR R14, #$02			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Store copy of IOCB_WA+10 back in IOCB_WA+10			
			MOVE R5, $92			
			MOVE R14, $82			
			ADD R14, #$11			
			MOVE (R14), R5			
						
			; Reset system flags			
			MOVE R5, $A4			
			MHL R1, R5			
			CLR R1, #$02		; clear I/O active	
			MLH R5, R1			
			CLR R5, #$08		; ?	
			MOVE $A4, R5			
						
			; Return to caller			
			MOVE R2, $D2			
			MOVE R8, R2			
			JMP ($00AC)			
						
						
			BRA $615C		; $0C(R0)	
						
						
			MOVE $98, R1			
						
			MOVE R1, $96		; return address	
			ADD R15, #$02			
			ADD R1, #$02			
			MOVE (R15), R1			
						
			JMP ($0098)		; jump to desired routine	
						
						
			; Tape Sense			
						
			CTRL $E, #$FF			
			GETB R5, $E			
						
			LBI R5, #$40			
			STAT R5, $E			
			MOVE $8E, R5		; Tape status byte	
						
			CLR R5, #$93			
			LBI R1, #$04			
			SE R5, R1			
			BRA $61A0		; LED or erase defective	
						
			; Setup tape IOCB			
						
			LBI R5, #$02			
			MLH R5, R5			
			LBI R5, #$00		; R5 <- $0200	
			MOVE R14, $80			
			ADD R14, #$07		; IOCB_BS	
			MOVE (R14), R5			
						
			LBI R5, #$00			
			MLH R5, R5			
			LBI R5, #$3A		; R5 <- $003A	
			MOVE R14, $80			
			ADD R14, #$09		; IOCB_CI1	
			MOVE (R14), R5			
						
			LBI R5, #$E2			
			MLH R5, R5			
			LBI R5, #$84		; R5 <- $E284	
			MOVE R14, $80			
			ADD R14, #$11		; IOCB_Stat1	
			MOVE (R14), R5			
						
			MOVE R2, $D2		; Restore R2	
			MOVE R8, R2			
			JMP ($00AC)		; Exit	
						
						
			; Error 02			
			LBI R5, #$F0			
			MLH R5, R5			
			LBI R5, #$F2			
			BRA $61A6		; $06(R0)	
						
			; Error 13			
			LBI R5, #$F1			
			MLH R5, R5			
			LBI R5, #$F3			
						
			MOVE R14, $80			
			ADD R14, #$0D			
			MOVE (R14), R5			
			MOVE $90, R0			
						
			MOVE R2, $D2		; Restore R2	
			MOVE R8, R2			
			JMP ($00AC)		; Exit	
						
						
			; Set processor flags			
			MOVE R5, $A4			
			MHL R1, R5			
			SET R1, #$02		; set I/O active	
			MLH R5, R1			
			CLR R5, #$20		; level 2 ROS	
			SET R5, #$08			
			LBI R1, #$08			
			SBSH R5, R1			
			BRA $61D4		; no ATTN	
						
			; SET 0200 - ATTN pressed			
			MOVE R1, $92			
			SET R1, #$00			
			MHL R14, R1			
			SET R14, #$02			
			MLH R1, R14			
			MOVE $92, R1			
						
			CTRL $4, #$46			
						
			MOVE $A4, R5			
			LBI R2, #$00			
			MLH R2, R2			
			LBI R2, #$A5			
			PUTB $0, (R2)			
						
			; Check flags whether ATTN should be ignored			
			MOVE R14, $80			
			ADD R14, #$04			
			MOVB R5, (R14)		; IOCB_Flags	
			LBI R1, #$80			
			SNBC R5, R1			
			BRA $61F6			
						
			; SET 0100 - ignore ATTN			
			MOVE R1, $92			
			SET R1, #$00			
			MHL R14, R1			
			SET R14, #$01			
			MLH R1, R14			
			MOVE $92, R1			
						
			MOVE R14, $80			
			ADD R14, #$03			
			MOVB R5, (R14)		; IOCB_Cmd	
			LBI R1, #$0D			
			SLE R5, R1			
			BRA $62DE		; error 02	
						
			; Command 00..0D			
			SUB R5, #$01			
			ADD R5, R5			
						
			; Check previous command and fail if it was			
			; Translate Only (or anything not strictly			
			; tape related)			
			MOVE R14, $82			
			ADD R14, #$0F			
			MOVE R6, (R14)		; get previous command	
			LBI R1, #$0B			
			SLE R6, R1			
			BRA $62DE		; error 02	
			ADD R6, R6			
						
			; Command switch			
			ADD R0, R5			
			BRA $622C		; Read	
			BRA $6246		; Write	
			BRA $6246		; Write Last	
			BRA $6260		; Find	
			BRA $6262		; Mark	
			BRA $627C		; Initialize and Mark	
			BRA $628A		; Rewind	
			BRA $628C		; Forward Space Record	
			BRA $62A6		; Backward Space Record	
			BRA $62C0		; Find Next Header	
			BRA $62C2		; Write Header	
						
			; Previous commands allowed for Read			
			ADD R0, R6			
			BRA $62DE		; error 02	
			BRA $62F6		; Read	
			BRA $62F6		; Write	
			BRA $62F6		; Write Last	
			BRA $62F6		; Find	
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
			BRA $62F6		; Forward Space Record	
			BRA $62F6		; Backward Space Record	
			BRA $62F6		; Find Next Header	
			BRA $62DE		; error 02	
						
			; Previous commands allowed for Write/Write Last			
			ADD R0, R6			
			BRA $62DE		; error 02	
			BRA $62EA		; Read	
			BRA $62EA		; Write	
			BRA $62EA		; Write Last	
			BRA $62EA		; Find	
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
			BRA $62EA		; Forward Space Record	
			BRA $62EA		; Backward Space Record	
			BRA $62EA		; Find Next Header	
			BRA $62EA		; Write Header	
						
			; Find			
			BRA $633E		; $DC(R0)	
						
			; Previous commands allowed for Mark			
			ADD R0, R6			
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
			BRA $62EA		; Find	
			BRA $62EA		; Mark	
			BRA $62EA		; Initialize and Mark	
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
			BRA $62EA		; Find Next Header	
			BRA $62DE		; error 02	
						
			; Initialize and Mark			
			LBI R5, #$40			
			STAT R5, $E			
			MOVE $8E, R5			
			LBI R1, #$15			
			SE R5, R1			
			BRA $62E4		; error 05	
			BRA $633E		; $B4(R0)	
						
			; Rewind			
			BRA $633E		; $B2(R0)	
						
			; Previous commands allowed for Forward Space Record			
			ADD R0, R6			
			BRA $62DE		; error 02	
			BRA $62F6		; Read	
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
			BRA $62F6		; Find	
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
			BRA $62F6		; Forward Space Record	
			BRA $62DE		; error 02	
			BRA $62F6		; Find Next Header	
			BRA $62F6		; Write Header	
						
			; Previous commands allowed for Backward Space Record			
			ADD R0, R6			
			BRA $62DE		; error 02	
			BRA $62F6		; Read	
			BRA $62F6		; Write	
			BRA $62F6		; Write Last	
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
			BRA $62F6		; Forward Space Record	
			BRA $62F6		; Backward Space Record	
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
						
			; Find Next Header			
			BRA $633E		; $7C(R0)	
						
			; Previous commands allowed for Write Header			
			ADD R0, R6			
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
			BRA $62EA		; Find	
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
			BRA $62DE		; error 02	
			BRA $62EA		; Find Next Header	
			BRA $62DE		; error 02	
			NOP			
						
						
			; Error 02			
			; Invalid command or sequence			
			LBI R1, #$02			
			MOVE $90, R0			
			JMP ($009C)			
						
			; Error 05			
			; Cartridge not inserted			
			LBI R1, #$00			
			MOVE $90, R0			
			JMP ($009C)			
						
						
			; Entry for: Write / Write Last / Mark / Write Header			
						
			; Check drive and cartridge			
			LBI R5, #$40			
			STAT R5, $E			
			MOVE $8E, R5			
			LBI R1, #$15			
			SE R5, R1			
			BRA $62E4		; error 05	
						
			; Entry for: Read / Forward Space Record /			
			; Backward Space Record			
						
			MOVE R6, $EC		; current file number	
			MHL R1, R6			
			OR R1, R6			
			SNZ R1			
			BRA $62DE		; error 02	
						
			MOVE R14, $80			
			ADD R14, #$03			
			MOVB R5, (R14)		; IOCB_Cmd	
			MOVE R6, $F2			
			ADD R5, R5			
			ADD R0, R5			
						
			HALT			; Sense
			BRA $6324		; Read	
			BRA $6324		; Write	
			BRA $6324		; Write Last	
			HALT			; Find
			BRA $633E		; Mark	
			HALT			; Initialize and Mark
			HALT			; Rewind
			BRA $6336		; Forward Space Record	
			BRA $6336		; Backward Space Record	
			HALT			; Find Next Header
			BRA $633A		; Write Header	
						
			; Check if IOCB_BS is $0200			
			MOVE R14, $80			
			ADD R14, #$07			
			MOVE R5, (R14)		; IOCB_BS	
			SZ R5			
			BRA $62DE		; error 02	
			LBI R14, #$02			
			MHL R5, R5			
			SE R5, R14			
			BRA $62DE		; error 02	
						
			; Check file number			
			SNZ R6			
			BRA $62DE		; error 02	
			SNS R6			
			BRA $63EA		; error 11	
						
			; Entry for: Find / Rewind / Find Next Header /			
			; Initialize and Mark			
						
			MOVE R14, $80			
			ADD R14, #$03		; IOCB_Cmd	
			MOVB R5, (R14)			
			SUB R5, #$01			
			SWAP R5			
			ROR R5			
			MOVE R6, R5			
			ROR R6			
			ADD R5, R6			
			ADD R0, R5			
						
			; Read			
			LBI R1, #$63			
			MLH R1, R1			
			LBI R1, #$F0			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $63D8		; $7A(R0)	
						
			; Write			
			LBI R1, #$64			
			MLH R1, R1			
			LBI R1, #$54			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $63D8		; $6E(R0)	
						
			; Write Last			
			LBI R1, #$64			
			MLH R1, R1			
			LBI R1, #$54			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $63D8		; $62(R0)	
						
			; Find			
			LBI R1, #$65			
			MLH R1, R1			
			LBI R1, #$3C			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $63D8		; $56(R0)	
						
			; Mark			
			LBI R1, #$65			
			MLH R1, R1			
			LBI R1, #$68			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Initialize and Mark			
			LBI R1, #$65			
			MLH R1, R1			
			LBI R1, #$68			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Rewind			
			LBI R1, #$67			
			MLH R1, R1			
			LBI R1, #$A4			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Forward Space Record			
			LBI R1, #$67			
			MLH R1, R1			
			LBI R1, #$B6			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $63D8		; $26(R0)	
						
			; Backward Space Record			
			LBI R1, #$67			
			MLH R1, R1			
			LBI R1, #$DC			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $63D8		; $1A(R0)	
						
			; Find Next Header			
			LBI R1, #$68			
			MLH R1, R1			
			LBI R1, #$0E			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $63D8		; $0E(R0)	
						
			; Write Header			
			LBI R1, #$68			
			MLH R1, R1			
			LBI R1, #$48			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $63D8		; $02(R0)	
						
			NOP			
						
			; Handle end of tape			
			LBI R1, #$71			
			MLH R1, R1			
			LBI R1, #$8A			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Clear file number and return			
			MOVE R5, $A0			
			MOVE $EC, R5			
			JMP (R15)-			
						
						
			; Error 11			
			LBI R1, #$0B			
			MOVE $90, R0			
			JMP ($009C)			
						
						
						
						
						
						
			LBI R1, #$69			
			MLH R1, R1			
			LBI R1, #$0C			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-		; Error return	
						
			; CLR 0040 - read data into buffer			
			MOVE R1, $92			
			CLR R1, #$40			
			MHL R14, R1			
			CLR R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Read one file block			
			LBI R1, #$6B			
			MLH R1, R1			
			LBI R1, #$32			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-		; Error return	
						
			; Check data record ID byte			
			MOVE R5, $88			
			LBI R1, #$42		; EOD?	
			SNE R1, R5			
			BRA $6434		; yes	
						
			LBI R1, #$24		; Bad Record?	
			SE R1, R5			
			BRA $644C		; no, return	
						
			; Bad Record, check if it should be skipped			
			MOVE R14, $80			
			ADD R14, #$04			
			MOVB R5, (R14)		; IOCB_Flags	
			LBI R1, #$08			
			SBS R5, R1			
			BRA $6408		; yes, skip	
						
			; Error 07			
			; CRC error			
			LBI R1, #$07			
			MOVE $90, R0			
			JMP ($009C)			
						
			; End of Data			
			LBI R1, #$6E			
			MLH R1, R1			
			LBI R1, #$0E			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Error 09			
			; End of Data			
			MOVE R5, $EE			
			SUB R5, #$01			
			MOVE $E8, R5			
			LBI R1, #$09			
			MOVE $90, R0			
			JMP ($009C)			
						
			; Return			
			MOVE R5, $EE			
			SUB R5, #$01			
			MOVE $E8, R5			
			JMP (R15)-			
						
						
						
						
						
						
			; Position tape			
			LBI R1, #$69			
			MLH R1, R1			
			LBI R1, #$0C			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Record ID byte			
			LBI R5, #$18		; data record	
			MOVE $8A, R5			
						
			; Write file block			
			LBI R1, #$6C			
			MLH R1, R1			
			LBI R1, #$7A			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-		; general error	
			BRA $6494		; OK	
						
			; Write error			
						
			; Record ID			
			LBI R5, #$24		; bad record	
			MOVE $8A, R5			
						
			; Write file block			
			LBI R1, #$6C			
			MLH R1, R1			
			LBI R1, #$7A			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-		; general error	
			BRA $6486		; OK	
			BRA $6536		; error 07	
						
			; Record ID successfully changed to 'bad'			
						
			; Skip bad blocks?			
			MOVE R14, $80			
			ADD R14, #$04		; IOCB_Flags	
			MOVB R5, (R14)			
			LBI R1, #$08			
			SBC R5, R1			
			BRA $6536		; no, error 07	
			BRA $6454		; yes, write data to next block	
						
			; Tape block successfully written without error			
						
			; Store last tape block number as result			
			; in IOCB_CI1			
			MOVE R5, $EE			
			SUB R5, #$01			
			MOVE $E8, R5			
						
			; Update EOD if block written was pas previous EOD			
			MOVE R7, R5			
			MOVE R14, $82			
			ADD R14, #$07			
			MOVE R6, (R14)		; EOD	
			SUB R6, R5			
			MHL R5, R6			
			MLH R6, R6			
			MHL R6, R5			
			SUB R5, R6			
			MHL R6, R6			
			MLH R6, R5			
			LBI R1, #$80			
			SBSH R6, R1			
			BRA $64BC			
			MOVE R14, $82			
			ADD R14, #$07			
			MOVE (R14), R7			
						
			; Was command a 'Write Last' ?			
			MOVE R14, $80			
			ADD R14, #$03		; IOCB_Cmd	
			MOVB R5, (R14)			
			LBI R1, #$03		; Write Last	
			SE R1, R5			
			JMP (R15)-		; no, return	
						
			; Update EOD to last written block number			
			MOVE R5, $EE			
			SUB R5, #$01			
			MOVE R14, $82			
			ADD R14, #$07			
			MOVE (R14), R5			
						
			MOVE R5, $F0		; marked file size	
			MOVE R1, R5			
			ADD R5, R1			
			MHL R1, R5			
			ADDH R1, R1			
			MLH R5, R1			
						
			MOVE R6, $EE			
			SUB R5, R6			
			MHL R6, R5			
			MLH R5, R5			
			MHL R5, R6			
			SUB R6, R5			
			MHL R5, R5			
			MLH R5, R6			
			LBI R1, #$80			
			SNBSH R5, R1			
			JMP (R15)-		; file completely filled	
						
			; Record ID byte			
			LBI R5, #$42		; last data block	
			MOVE $8A, R5			
						
			; Write file block (again, now with updated ID)			
			LBI R1, #$6C			
			MLH R1, R1			
			LBI R1, #$7A			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-		; general error	
			BRA $6528		; OK	
						
			; Write error, mark block as bad			
						
			; Record ID byte			
			LBI R5, #$24		; bad record	
			MOVE $8A, R5			
						
			; Write file block			
			LBI R1, #$6C			
			MLH R1, R1			
			LBI R1, #$7A			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-		; general error	
			BRA $651A		; OK	
			BRA $6536		; very bad... error 07	
						
			; Record ID successfully changed to 'bad'			
						
			; Skip bad blocks?			
			MOVE R14, $80			
			ADD R14, #$04			
			MOVB R5, (R14)			
			LBI R1, #$08			
			SBC R5, R1			
			BRA $6536		; no, error 07	
			BRA $64C8		; yes, write data to next block	
						
			; Write Last succeeded without error			
						
			; Backspace one file block and return			
			LBI R1, #$6E			
			MLH R1, R1			
			LBI R1, #$0E			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
			JMP (R15)-			
						
			; Error 07			
			LBI R1, #$07			
			MOVE $90, R0			
			JMP ($009C)			
						
						
						
						
						
						
			MOVE R5, $E8		; IOCB_CI1	
			MHL R1, R5			
			OR R1, R5			
			SNZ R1			; file number <> 0 ?
			BRA $6562		; no, error 02	
						
			LBI R1, #$80			
			SNBSH R5, R1		; file number positive?	
			BRA $6562		; no, error 02	
						
			MOVE R5, $E8			
			MOVE R14, $82			
			ADD R14, #$01		; IOCB_WA	
			MOVE (R14), R5		; store file number in WA	
						
			LBI R1, #$69			
			MLH R1, R1			
			LBI R1, #$D6			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
			JMP (R15)-			
						
			; Error 02			
			LBI R1, #$02			
			MOVE $90, R0			
			JMP ($009C)			
						
						
						
						
						
			; SET 0100			
			MOVE R1, $92			
			SET R1, #$00			
			MHL R14, R1			
			SET R14, #$01			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Clear tape buffer			
			LBI R1, #$6B			
			MLH R1, R1			
			LBI R1, #$16			
			MOVE $96, R0			
			JMP ($009A)			
						
			MOVE R5, $A0			
			MOVE $F6, R5			
						
			MOVE R5, $E8			
			MHL R1, R5			
			OR R1, R5			
			SNZ R1			
			BRA $6592			
			MHL R6, R5			
			CLR R6, #$3F			
			SZ R6			
			BRA $6674		; error 02	
			MOVE $F0, R5			
						
			MOVE R14, $80			
			ADD R14, #$0F			
			MOVE R5, (R14)		; IOCB_CI2	
			MHL R1, R5			
			OR R1, R5			
			SNZ R1			
			BRA $6674		; error 02	
			LBI R1, #$80			
			SNBSH R5, R1			
			BRA $6674		; error 02	
						
			MOVE R14, $80			
			ADD R14, #$03			
			MOVB R7, (R14)		; IOCB_Cmd	
			LBI R1, #$06			
			SNE R1, R7			
			BRA $65C8		; Initialize and Mark	
						
			; Mark			
			MOVE R6, $EC			
			ADD R5, R6			
			MHL R6, R5			
			ADDH R6, R6			
			MLH R5, R6			
			LBI R1, #$80			
			SNBSH R5, R1			
			BRA $6674		; error 02	
			BRA $6610		; $48(R0)	
						
			; Initialize and Mark			
			; SET 0010			
			MOVE R1, $92			
			SET R1, #$10			
			MHL R14, R1			
			SET R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			LBI R1, #$71			
			MLH R1, R1			
			LBI R1, #$46			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			MOVE R5, $A0			
			MOVE $EE, R5			
						
			LBI R5, #$00			
			MLH R5, R5			
			LBI R5, #$01			
			MOVE $EC, R5			
						
			; Record type			
			LBI R5, #$81		; header record	
			MOVE $86, R5			
			MOVE $8A, R5			
						
			; Write tape record			
			LBI R1, #$70			
			MLH R1, R1			
			LBI R1, #$FA			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $6608		; $0A(R0)	
						
			LBI R5, #$00			
			MLH R5, R5			
			LBI R5, #$01			
			MOVE $EE, R5			
			BRA $6610		; $08(R0)	
						
			LBI R1, #$67			
			MLH R1, R1			
			LBI R1, #$86			
			RET R1			
						
			LBI R1, #$6A			
			MLH R1, R1			
			LBI R1, #$74			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $667A		; $5E(R0)	
						
			MOVE R5, $F6			
			MOVE R14, $80			
			ADD R14, #$0F			
			MOVE R6, (R14)			
			SUB R5, R6			
			MHL R6, R5			
			MLH R5, R5			
			MHL R5, R6			
			SUB R6, R5			
			MHL R5, R5			
			MLH R5, R6			
			MHL R1, R5			
			OR R1, R5			
			SZ R1			
			BRA $6610		; -> -$2A(R0)	
						
			LBI R1, #$6E			
			MLH R1, R1			
			LBI R1, #$0E			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $667A		; $34(R0)	
						
			LBI R5, #$FF			
			MOVE R14, $84			
			ADD R14, #$01			
			MOVB (R14), R5			
			MOVE $F2, R5			
						
			MOVE R5, $EC			
			MOVE R14, $84			
			ADD R14, #$02			
			MHL R1, R5			
			MOVB (R14)+, R1			
			MOVB (R14)-, R5			
						
			LBI R5, #$81			
			MOVE $8A, R5			
						
			LBI R1, #$6C			
			MLH R1, R1			
			LBI R1, #$7A			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $667A		; $0E(R0)	
			JMP (R15)-			
						
			; Error 07			
			LBI R1, #$07			
			MOVE $90, R0			
			JMP ($009C)			
						
			; Error 02			
			LBI R1, #$02			
			MOVE $90, R0			
			JMP ($009C)			
						
			; CLR 0010			
			MOVE R1, $92			
			CLR R1, #$10			
			MHL R14, R1			
			CLR R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			LBI R1, #$71			
			MLH R1, R1			
			LBI R1, #$8A			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			MOVE R5, $A0			
			MOVE $EA, R5			
						
			MOVE R5, $EE			
			SUB R5, #$02			
			LBI R1, #$80			
			SNBSH R5, R1			
			BRA $66DE		; $3E(R0)	
						
			SUB R5, #$03			
			LBI R1, #$80			
			SNBSH R5, R1			
			BRA $672A		; $82(R0)	
						
			ADD R5, #$02			
			MOVE R6, R5			
			CLR R6, #$7F			
			MHL R1, R6			
			OR R1, R6			
			SZ R1			
			SUB R5, #$02			
			MHL R6, R5			
			ROR R5			
			ROR R6			
			MOVE R7, R6			
			CLR R5, #$80			
			CLR R6, #$80			
			CLR R7, #$7F			
			OR R5, R7			
			MLH R5, R6			
			MOVE $E8, R5			
						
			MOVE R5, $F6			
			ADD R5, #$01			
			MOVE R14, $80			
			ADD R14, #$0F			
			MOVE (R14), R5			
						
			MOVE R5, $EC			
			MOVE R14, $82			
			ADD R14, #$01			
			MOVE (R14), R5			
			BRA $670C		; $2E(R0)	
						
			MOVE R5, $F6			
			MHL R1, R5			
			OR R1, R5			
			SNZ R1			
			BRA $672A		; $42(R0)	
						
			MOVE R5, $F0			
			SUB R5, #$01			
			MOVE R6, R5			
			CLR R6, #$3F			
			MHL R1, R6			
			OR R1, R6			
			SZ R1			
			SUB R5, #$01			
			MOVE $E8, R5			
			MOVE R5, $F6			
			MOVE R14, $80			
			ADD R14, #$0F			
			MOVE (R14), R5			
						
			MOVE R5, $EC			
			SUB R5, #$01			
			MOVE R14, $82			
			ADD R14, #$01			
			MOVE (R14), R5			
						
			LBI R1, #$69			
			MLH R1, R1			
			LBI R1, #$D6			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $6786		; $6E(R0)	
						
			MOVE R5, $E8			
			MOVE $F0, R5			
						
			LBI R1, #$6A			
			MLH R1, R1			
			LBI R1, #$74			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $6786		; $5E(R0)	
			BRA $6746		; $1C(R0)	
						
			MOVE R5, $F6			
			MOVE R14, $80			
			ADD R14, #$0F			
			MOVE (R14), R5			
						
			MOVE R5, $EC			
			MOVE R14, $82			
			ADD R14, #$01			
			MOVE (R14), R5			
						
			LBI R1, #$69			
			MLH R1, R1			
			LBI R1, #$D6			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $6786		; $40(R0)	
						
			LBI R1, #$6E			
			MLH R1, R1			
			LBI R1, #$0E			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $6786		; $34(R0)	
						
			LBI R5, #$FF			
			MOVE R14, $84			
			ADD R14, #$01			
			MOVB (R14), R5			
			MOVE $F2, R5			
						
			MOVE R5, $EC			
			MOVE R14, $84			
			ADD R14, #$02			
			MHL R1, R5			
			MOVB (R14)+, R1			
			MOVB (R14)-, R5			
						
			LBI R5, #$81			
			MOVE $8A, R5			
						
			LBI R1, #$6C			
			MLH R1, R1			
			LBI R1, #$7A			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $6786		; OK	
			BRA $6780		; error 12	
						
			; Error 07			
			LBI R1, #$07			
			MOVE $90, R0			
			JMP ($009C)			
						
			; Error 12			
			LBI R1, #$0C			
			MOVE $90, R0			
			JMP ($009C)			
						
			; CLR 0010			
			MOVE R1, $92			
			CLR R1, #$10			
			MHL R14, R1			
			CLR R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			LBI R1, #$71			
			MLH R1, R1			
			LBI R1, #$8A			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Error 03			
			LBI R1, #$03			
			MOVE $90, R0			
			JMP ($009C)			
						
			MOVE R5, $A0			
			MOVE $EC, R5			
						
			LBI R1, #$71			
			MLH R1, R1			
			LBI R1, #$46			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
			JMP (R15)-			
						
						
			; SET 0040			
			MOVE R1, $92			
			SET R1, #$40			
			MHL R14, R1			
			SET R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			MOVE R14, $80			
			ADD R14, #$04			
			MOVB R5, (R14)			
			LBI R1, #$08			
			SBC R5, R1			
			BRA $67D6		; error 02	
						
			LBI R1, #$64			
			MLH R1, R1			
			LBI R1, #$08			
			RET R1			
						
			; Error 02			
			LBI R1, #$02			
			MOVE $90, R0			
			JMP ($009C)			
						
						
			MOVE R14, $80			
			ADD R14, #$04			
			MOVB R5, (R14)			
			LBI R1, #$08			
			SBC R5, R1			
			BRA $6802		; error 02	
						
			MOVE R5, $EE			
			SUB R5, #$01			
			MHL R1, R5			
			OR R1, R5			
			SNZ R1			
			BRA $6808		; error 10	
						
			LBI R1, #$6E			
			MLH R1, R1			
			LBI R1, #$0E			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
			JMP (R15)-			
						
			; Error 02			
			LBI R1, #$02			
			MOVE $90, R0			
			JMP ($009C)			
						
			; Error 10			
			LBI R1, #$0A			
			MOVE $90, R0			
			JMP ($009C)			
						
						
			MOVE R5, $EC			
			MHL R1, R5			
			OR R1, R5			
			SZ R1			
			BRA $6828		; $10(R0)	
						
			LBI R1, #$70			
			MLH R1, R1			
			LBI R1, #$C6			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $6836		; $12(R0)	
						
			MOVE R5, $A0			
			MOVE $F2, R5			
						
			LBI R1, #$6E			
			MLH R1, R1			
			LBI R1, #$8E			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
			JMP (R15)-			
						
			LBI R1, #$71			
			MLH R1, R1			
			LBI R1, #$8A			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			MOVE R5, $A0			
			MOVE $EA, R5			
			BRA $6828		; -> -$20(R0)	
						
						
			MOVE R14, $84			
			ADD R14, #$07			
			MOVB R1, (R14)+			
			MOVB R5, (R14)-			
			MLH R5, R1			
			LBI R1, #$80			
			SNBSH R5, R1			
			BRA $6906		; error 02	
						
			MOVE R6, $F0			
			MOVE R1, R6			
			ADD R6, R1			
			MHL R1, R6			
			ADDH R1, R1			
			MLH R6, R1			
			MOVE R1, R5			
			SUB R6, R1			
			MHL R1, R6			
			MLH R6, R6			
			MHL R6, R1			
			SUB R1, R6			
			MHL R6, R6			
			MLH R6, R1			
			LBI R1, #$80			
			SNBSH R6, R1			
			BRA $6906		; error 02	
						
			MOVE R14, $82			
			ADD R14, #$0D			
			MOVE R5, (R14)			
			SZ R5			
			BRA $68A0		; $1C(R0)	
						
			MOVE R14, $84			
			ADD R14, #$06			
			MOVB R5, (R14)			
			SNZ R5			
			BRA $68A0		; $12(R0)	
						
			MOVE R14, $84			
			ADD R14, #$07			
			MOVB R1, (R14)+			
			MOVB R5, (R14)-			
			MLH R5, R1			
			MHL R1, R5			
			OR R1, R5			
			SZ R1			
			BRA $6906		; error 02	
						
			MOVE R14, $84			
			ADD R14, #$01			
			MOVB R5, (R14)			
			MOVE $F2, R5			
						
			MOVE R14, $84			
			ADD R14, #$07			
			MOVB R1, (R14)+			
			MOVB R5, (R14)-			
			MLH R5, R1			
			MOVE R14, $82			
			ADD R14, #$07			
			MOVE (R14), R5			
						
			MOVE R14, $84			
			ADD R14, #$06			
			MOVB R5, (R14)			
			MOVE R14, $82			
			ADD R14, #$0D			
			MOVE (R14), R5			
						
			MOVE R5, $EC			
			MOVE R14, $84			
			ADD R14, #$02			
			MHL R1, R5			
			MOVB (R14)+, R1			
			MOVB (R14)-, R5			
						
			MOVE R5, $F0			
			MOVE R14, $84			
			ADD R14, #$04			
			MHL R1, R5			
			MOVB (R14)+, R1			
			MOVB (R14)-, R5			
						
			LBI R1, #$6E			
			MLH R1, R1			
			LBI R1, #$0E			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			LBI R5, #$81			
			MOVE $8A, R5			
						
			LBI R1, #$6C			
			MLH R1, R1			
			LBI R1, #$7A			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-		; return	
			BRA $6900		; return	
						
			; Error 07			
			LBI R1, #$07			
			MOVE $90, R0			
			JMP ($009C)			
						
			; Return			
			MOVE R5, $A0			
			MOVE $E8, R5			
			JMP (R15)-			
						
			; Error 02			
			LBI R1, #$02			
			MOVE $90, R0			
			JMP ($009C)			
						
						
						
						
						
						
			MOVE R14, $80			
			ADD R14, #$04		; IOCB_Flags	
			MOVB R5, (R14)			
			LBI R1, #$08			
			SBC R5, R1			
			BRA $6930		; skip bad records	
						
			; Is it a read?			
			MOVE R14, $80			
			ADD R14, #$03			
			MOVB R5, (R14)		; IOCB_Cmd	
			LBI R1, #$01			
			SNE R1, R5			
			BRA $69C6		; yes, return	
						
			; No, check for sequence rel. indicator			
			MOVE R14, $82			
			ADD R14, #$0D			
			MOVE R5, (R14)			
			SZ R5			
			BRA $69CA		; set, error 02	
			BRA $69C6		; not set, return	
						
			; Skip bad records			
						
			; Is it a read?			
			MOVE R14, $80			
			ADD R14, #$03			
			MOVB R5, (R14)		; IOCB_Cmd	
			LBI R1, #$01			
			SNE R1, R5			
			BRA $6946		; yes	
						
			; No, check for sequence rel. indicator			
			MOVE R14, $82			
			ADD R14, #$0D			
			MOVE R5, (R14)			
			SNZ R5			
			BRA $69CA		; not set, error 02	
						
			; Check requested tape block number			
			MOVE R5, $E8			
			LBI R1, #$80			
			SNBSH R5, R1			
			BRA $69CA		; negative, error 02	
						
			; Check if request is past EOD			
			MOVE R14, $82			
			ADD R14, #$07			
			MOVE R6, (R14)		; EOD	
			SUB R5, R6			
			MHL R6, R5			
			MLH R5, R5			
			MHL R5, R6			
			SUB R6, R5			
			MHL R5, R5			
			MLH R5, R6			
			LBI R1, #$80			
			SNBSH R5, R1			
			BRA $697C		; past EOD	
						
			; Is it a read?			
			MOVE R14, $80			
			ADD R14, #$03			
			MOVB R6, (R14)			
			LBI R1, #$01			
			SNE R1, R6			
			BRA $69D0		; yes	
						
			; No, then operation must be at EOD			
			MHL R1, R5			
			OR R1, R5			
			SZ R1			
			BRA $69CA		; error 02	
						
			; Check if requested block equal to current block			
			MOVE R5, $E8			
			ADD R5, #$01			
			MOVE R6, $EE		; current block number	
			SUB R5, R6			
			MHL R6, R5			
			MLH R5, R5			
			MHL R5, R6			
			SUB R6, R5			
			MHL R5, R5			
			MLH R5, R6			
						
			MHL R1, R5			
			OR R1, R5			
			SNZ R1			
			BRA $69C6		; equal, return	
			LBI R1, #$80			
			SNBSH R5, R1			
			BRA $69B8		; less than, backspace	
						
			; Greater than, forward space			
			; SET 0040 - don't store in buffer			
			MOVE R1, $92			
			SET R1, #$40			
			MHL R14, R1			
			SET R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Read file block			
			LBI R1, #$6B			
			MLH R1, R1			
			LBI R1, #$32			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
			BRA $697C		; loop	
						
			; Backspace one file block			
			LBI R1, #$6E			
			MLH R1, R1			
			LBI R1, #$0E			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
			BRA $697C		; loop	
						
			; Return			
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
						
			; Error 02			
			; Invalid command or sequence			
			LBI R1, #$02			
			MOVE $90, R0			
			JMP ($009C)			
						
			; Error 09			
			; End of Data			
			LBI R1, #$09			
			MOVE $90, R0			
			JMP ($009C)			
						
						
						
						
						
						
			; Preset retry counter			
			MOVE R5, $A2			
			LBI R1, #$80			
			SBSH R5, R1			
			BRA $69E2			
			LBI R5, #$02			
			BRA $69E4			
			LBI R5, #$07			
			MOVE R14, $82			
			ADD R14, #$13			
			MOVE (R14), R5			
						
			; Check current file number (i.e. position of tape)			
			MOVE R6, $EC			
			MHL R1, R6			
			OR R1, R6			
			SZ R1			
			BRA $69FC			
						
			; Not set, set it to file counter			
			MOVE R14, $82			
			ADD R14, #$01			
			MOVE R5, (R14)			
			MOVE $EC, R5		; file counter	
						
			; file counter > file number ?			
			MOVE R14, $82			
			ADD R14, #$01			
			MOVE R5, (R14)			
			MOVE R6, $EC			
			SUB R6, R5			
			MHL R5, R6			
			MLH R6, R6			
			MHL R6, R5			
			SUB R5, R6			
			MHL R6, R6			
			MLH R6, R5			
			LBI R1, #$80			
			SBSH R6, R1			
			BRA $6A5C		; no, past BOF	
						
			; Find next file			
			LBI R1, #$6E			
			MLH R1, R1			
			LBI R1, #$8E			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Compare file counter with file number			
			MOVE R14, $82			
			ADD R14, #$01			
			MOVE R5, (R14)			
			MOVE R6, $EC			
			SUB R6, R5			
			MHL R5, R6			
			MLH R6, R6			
			MHL R6, R5			
			SUB R5, R6			
			MHL R6, R6			
			MLH R6, R5			
						
			MHL R1, R6			
			OR R1, R6			
			SNZ R1			
			BRA $6A70		; equal, file found	
						
			LBI R1, #$80			
			SNBSH R6, R1			
			BRA $69FC		; loop	
						
			; Retry			
			MOVE R14, $82			
			ADD R14, #$13			
			MOVE R5, (R14)			
			SUB R5, #$01			
			MOVE (R14), R5			
			SZ R5			
			BRA $69FC		; loop	
						
			; Error 08			
			; Records or files out of sequence			
			LBI R1, #$08			
			MOVE $90, R0			
			JMP ($009C)			
						
			; Find previous file			
			LBI R1, #$6F			
			MLH R1, R1			
			LBI R1, #$92			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Decrement file counter			
			MOVE R5, $EC			
			SUB R5, #$01			
			MOVE $EC, R5			
			BRA $69FC		; loop	
						
			; Return			
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
						
			; Copy file number to header			
			MOVE R5, $EC		; file number	
			MOVE R14, $84			
			ADD R14, #$02			
			MHL R1, R5			
			MOVB (R14)+, R1			
			MOVB (R14)-, R5			
						
			; Copy marked size to header			
			MOVE R5, $F0		; marked size of file	
			MOVE R14, $84			
			ADD R14, #$04			
			MHL R1, R5			
			MOVB (R14)+, R1			
			MOVB (R14)-, R5			
						
			LBI R1, #$6E			
			MLH R1, R1			
			LBI R1, #$0E			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			LBI R5, #$81			
			MOVE $8A, R5			
						
			LBI R1, #$6C			
			MLH R1, R1			
			LBI R1, #$7A			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
			BRA $6AAC		; $02(R0)	
			BRA $6B10		; error 07	
						
			LBI R5, #$18			
			MOVE $86, R5			
			MOVE $8A, R5			
						
			LBI R1, #$70			
			MLH R1, R1			
			LBI R1, #$FA			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			MOVE R5, $EE			
			ADD R5, #$01			
			MOVE $EE, R5			
			MOVE R6, $F0			
			MOVE R1, R6			
			ADD R6, R1			
			MHL R1, R6			
			ADDH R1, R1			
			MLH R6, R1			
			SUB R6, R5			
			MHL R5, R6			
			MLH R6, R6			
			MHL R6, R5			
			SUB R5, R6			
			MHL R6, R6			
			MLH R6, R5			
			LBI R1, #$80			
			SBSH R6, R1			
			BRA $6AB2		; -> -$32(R0)	
						
			MOVE R5, $A0			
			MOVE $EE, R5			
						
			LBI R5, #$81			
			MOVE $86, R5			
			MOVE $8A, R5			
						
			MOVE R5, $F6			
			ADD R5, #$01			
			MOVE $F6, R5			
						
			MOVE R5, $EC			
			ADD R5, #$01			
			MOVE $EC, R5			
						
			LBI R1, #$70			
			MLH R1, R1			
			LBI R1, #$FA			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			MOVE R5, $EE			
			ADD R5, #$01			
			MOVE $EE, R5			
						
			; Return			
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
			; Error 07			
			LBI R1, #$07			
			MOVE $90, R0			
			JMP ($009C)			
						
						
						
						
						
						
			; Fill IOCB_BA with zeroes			
			MOVE R14, $80			
			ADD R14, #$05			
			MOVE R2, (R14)		; IOCB_BA	
			LBI R11, #$02			
			MLH R11, R11			
			LBI R11, #$00		; 512 bytes	
			MOVE R5, $A0		; zero	
			MOVB (R2)+, R5			
			SUB R11, #$01			
			MHL R1, R11			
			OR R1, R11			
			SZ R1			
			BRA $6B24		; loop	
						
			; Return			
			JMP (R15)-			
						
						
						
						
						
						
			; Preset retry counter			
			; The high byte is used to find the correct record,			
			; the low byte when reading the record			
			MOVE R5, $A2			
			LBI R1, #$80			
			SBSH R5, R1			
			BRA $6B42			
			LBI R5, #$01			
			MLH R5, R5			
			LBI R5, #$01			
			BRA $6B48			
			LBI R5, #$07			
			MLH R5, R5			
			LBI R5, #$0A			
			MOVE $F4, R5			
						
			MOVE R5, $F0		; marked file size [KB]	
			MOVE R1, R5			
			ADD R5, R1			
			MHL R1, R5			
			ADDH R1, R1			
			MLH R5, R1		; size in tape blocks [࠵12 b.]	
						
			; Compare file size with current block number			
			MOVE R6, $EE		; current tape block	
			SUB R5, R6			
			MHL R6, R5			
			MLH R5, R5			
			MHL R5, R6			
			SUB R6, R5			
			MHL R5, R5			
			MLH R5, R6			
			LBI R1, #$80			
			SBSH R5, R1			
			BRA $6B74		; greater or equal, OK	
						
			; Less than, error 10 (end of file)			
			LBI R1, #$6C			
			MLH R1, R1			
			LBI R1, #$62			
			RET R1			
						
			; Read tape block			
			LBI R1, #$70			
			MLH R1, R1			
			LBI R1, #$20			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; TST 0004 - format record error?			
			MOVE R14, $92			
			CLR R14, #$FB			
			SZ R14			
			BRA $6B8E		; yes, retry	
			MHL R14, R14			
			CLR R14, #$FF			
			SZ R14			
			BRA $6BD2			
						
			; TST 0002 - wrong record number?			
			MOVE R14, $92			
			CLR R14, #$FD			
			SZ R14			
			BRA $6B9E		; yes, find correct one	
			MHL R14, R14			
			CLR R14, #$FF			
			SZ R14			
			BRA $6BEA			
						
			; Bad Record?			
			MOVE R5, $88			
			LBI R1, #$24			
			SNE R1, R5			
			BRA $6BC8		; yes, return	
						
			; TST 0040 - verify only?			
			MOVE R14, $92			
			CLR R14, #$BF			
			SZ R14			
			BRA $6BB6		; yes, return	
			MHL R14, R14			
			CLR R14, #$FF			
			SZ R14			
			BRA $6BC8			
						
			; TST 0001 - error?			
			MOVE R14, $92			
			CLR R14, #$FE			
			SZ R14			
			BRA $6BC6		; yes, retry	
			MHL R14, R14			
			CLR R14, #$FF			
			SZ R14			
			BRA $6BD2			
						
			; Return			
			MOVE R5, $EE			
			ADD R5, #$01			
			MOVE $EE, R5			
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
			; Retry			
			MOVE R5, $F4			
			SUB R5, #$01			
			MOVE $F4, R5			
			SNZ R5			
			BRA $6C68		; error 07	
						
			; Find previous format record			
			LBI R1, #$70			
			MLH R1, R1			
			LBI R1, #$C6			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
			BRA $6B4A		; jump back	
						
			; Wrong record, try to find correct one			
						
			; Decrement 'locate' retry counter			
			MOVE R5, $F4			
			SUB R5, #$100			
			MOVE $F4, R5			
			MHL R5, R5			
			SNZ R5			
			BRA $6C74		; error 08	
						
			MOVE R5, $EE		; current file block number	
			MHL R1, R5			
			OR R1, R5			
			SNZ R1			
			BRA $6C3E		; zero	
						
			MOVE R6, $8C		; actual tape record number	
			MHL R1, R6			
			OR R1, R6			
			SNZ R1			
			BRA $6C50		; zero	
						
			SUB R5, R6			
			MHL R6, R5			
			MLH R5, R5			
			MHL R5, R6			
			SUB R6, R5			
			MHL R5, R5			
			MLH R5, R6			
			LBI R1, #$80			
			SBSH R5, R1			
			BRA $6B4A		; OK, try with next block	
						
			; We're behind the desired block number, backspace			
						
			; Find previous format record...			
			LBI R1, #$70			
			MLH R1, R1			
			LBI R1, #$C6			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; ...and a second time			
			LBI R1, #$70			
			MLH R1, R1			
			LBI R1, #$C6			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; OK, now try this block			
			LBI R1, #$6B			
			MLH R1, R1			
			LBI R1, #$4A			
			RET R1			
						
			; Current file block is zero			
			MOVE R5, $8C			
			SUB R5, #$02			
			LBI R1, #$80			
			SNBSH R5, R1			
			BRA $6C1E		; backspace	
						
			; Try this block			
			LBI R1, #$6B			
			MLH R1, R1			
			LBI R1, #$4A			
			RET R1			
						
			; Current tape record number is zero			
			MOVE R5, $EE			
			SUB R5, #$02			
			LBI R1, #$80			
			SBSH R5, R1			
			BRA $6C1E		; backspace	
						
			; Try this block			
			LBI R1, #$6B			
			MLH R1, R1			
			LBI R1, #$4A			
			RET R1			
						
			; Error 10			
			; End of File			
			LBI R1, #$0A			
			MOVE $90, R0			
			JMP ($009C)			
						
			; Error 07			
			; CRC error			
			MOVE R5, $EE			
			ADD R5, #$01			
			MOVE $EE, R5			
			LBI R1, #$07			
			MOVE $90, R0			
			JMP ($009C)			
						
			; Error 08			
			; Records or Files out of Sequence			
			LBI R1, #$08			
			MOVE $90, R0			
			JMP ($009C)			
						
						
						
						
						
						
			; Preset retry counter			
			; The high byte is used to find the correct record,			
			; the low byte when reading the record			
			MOVE R5, $A2			
			LBI R1, #$80			
			SBSH R5, R1			
			BRA $6C8A			
			LBI R5, #$01			
			MLH R5, R5			
			LBI R5, #$01			
			BRA $6C90			
			LBI R5, #$07			
			MLH R5, R5			
			LBI R5, #$0A			
			MOVE $F4, R5			
						
			MOVE R5, $F0		; marked file size [KB]	
			MOVE R1, R5			
			ADD R5, R1			
			MHL R1, R5			
			ADDH R1, R1			
			MLH R5, R1		; size in tape blocks [࠵12 b.]	
						
			; Compare file size with current block number			
			MOVE R6, $EE			
			SUB R5, R6			
			MHL R6, R5			
			MLH R5, R5			
			MHL R5, R6			
			SUB R6, R5			
			MHL R5, R5			
			MLH R5, R6			
			LBI R1, #$80			
			SBSH R5, R1			
			BRA $6CBC		; greater or equal, OK	
						
			; Less than, error 10 (end of file)			
			LBI R1, #$6D			
			MLH R1, R1			
			LBI R1, #$F0			
			RET R1			
						
			; Write tape block			
			LBI R1, #$70			
			MLH R1, R1			
			LBI R1, #$60			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; TST 0004 - format record error?			
			MOVE R14, $92			
			CLR R14, #$FB			
			SZ R14			
			BRA $6CD6		; yes, retry	
			MHL R14, R14			
			CLR R14, #$FF			
			SZ R14			
			BRA $6D58			
						
			; TST 0002 - wrong record number?			
			MOVE R14, $92			
			CLR R14, #$FD			
			SZ R14			
			BRA $6CE6		; yes, find correct one	
			MHL R14, R14			
			CLR R14, #$FF			
			SZ R14			
			BRA $6D70			
						
			; Find previous format record			
			LBI R1, #$70			
			MLH R1, R1			
			LBI R1, #$C6			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; SET 0040 - verify only			
			MOVE R1, $92			
			SET R1, #$40			
			MHL R14, R1			
			SET R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Verify tape block just written			
			LBI R1, #$70			
			MLH R1, R1			
			LBI R1, #$20			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; TST 0004 - format record error?			
			MOVE R14, $92			
			CLR R14, #$FB			
			SZ R14			
			BRA $6D1A		; yes, retru	
			MHL R14, R14			
			CLR R14, #$FF			
			SZ R14			
			BRA $6D58			
						
			; TST 0002 - wrong record number?			
			MOVE R14, $92			
			CLR R14, #$FD			
			SZ R14			
			BRA $6D2A		; yes, find correct one	
			MHL R14, R14			
			CLR R14, #$FF			
			SZ R14			
			BRA $6D70			
						
			; Bad header record?			
			MOVE R5, $8A			
			LBI R1, #$24			
			SE R1, R5			
			BRA $6D3E		; no	
						
			; Yes, then data record must also be marked bad			
			MOVE R5, $88			
			LBI R1, #$24			
			SNE R1, R5			
			BRA $6D4E		; equal	
			BRA $6D58		; not equal, retry	
						
			; TST 0001 - error?			
			MOVE R14, $92			
			CLR R14, #$FE			
			SZ R14			
			BRA $6D4C		; yes, retry	
			MHL R14, R14			
			CLR R14, #$FF			
			SZ R14			
			BRA $6D58			
						
			; Increment current block number			
			MOVE R5, $EE			
			ADD R5, #$01			
			MOVE $EE, R5			
						
			; Return			
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
			; Decrement retry counter			
			MOVE R5, $F4			
			SUB R5, #$01			
			MOVE $F4, R5			
			SNZ R5			
			BRA $6DF6		; retries failed	
						
			; Find previous format record			
			LBI R1, #$70			
			MLH R1, R1			
			LBI R1, #$C6			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
			BRA $6C92		; jump back	
						
			; Wrong record, try to find correct one			
						
			; Decrement 'locate' retry counter			
			MOVE R5, $F4			
			SUB R5, #$100			
			MOVE $F4, R5			
			MHL R5, R5			
			SNZ R5			
			BRA $6E08		; error 08	
						
			MOVE R5, $EE		; current file block number	
			MHL R1, R5			
			OR R1, R5			
			SNZ R1			
			BRA $6DCC		; zero	
						
			MOVE R6, $8C		; actual tape record number	
			MHL R1, R6			
			OR R1, R6			
			SNZ R1			
			BRA $6DDE		; zero	
						
			SUB R5, R6			
			MHL R6, R5			
			MLH R5, R5			
			MHL R5, R6			
			SUB R6, R5			
			MHL R5, R5			
			MLH R5, R6			
			LBI R1, #$80			
			SNBSH R5, R1			
			BRA $6DAC		; past block, backspace	
						
			; Ok, try this block			
			LBI R1, #$6C			
			MLH R1, R1			
			LBI R1, #$92			
			RET R1			
						
			; Find previous format record...			
			LBI R1, #$70			
			MLH R1, R1			
			LBI R1, #$C6			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; ...and a second time			
			LBI R1, #$70			
			MLH R1, R1			
			LBI R1, #$C6			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; OK, now try this block			
			LBI R1, #$6C			
			MLH R1, R1			
			LBI R1, #$92			
			RET R1			
						
			MOVE R5, $8C			
			SUB R5, #$02			
			LBI R1, #$80			
			SNBSH R5, R1			
			BRA $6DAC			
						
			; Try this block			
			LBI R1, #$6C			
			MLH R1, R1			
			LBI R1, #$92			
			RET R1			
						
			MOVE R5, $EE			
			SUB R5, #$02			
			LBI R1, #$80			
			SBSH R5, R1			
			BRA $6DAC			
						
			; Try this block			
			LBI R1, #$6C			
			MLH R1, R1			
			LBI R1, #$92			
			RET R1			
						
			; Error 10			
			; End of File			
			LBI R1, #$0A			
			MOVE $90, R0			
			JMP ($009C)			
						
			; Find previous format record			
			LBI R1, #$70			
			MLH R1, R1			
			LBI R1, #$C6			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Return			
			MOVE R1, (R15)-			
			ADD R1, #$04			
			RET R1			
						
			; Error 08			
			; Records or Files out of Sequence			
			LBI R1, #$08			
			MOVE $90, R0			
			JMP ($009C)			
						
						
						
						
						
						
			; Preset retry counter			
			MOVE R5, $A2			
			LBI R1, #$80			
			SBSH R5, R1			
			BRA $6E1A			
			LBI R5, #$01			
			BRA $6E1C			
			LBI R5, #$0A			
			MOVE $F4, R5			
						
			; SET 0040 - don't read into buffer			
			MOVE R1, $92			
			SET R1, #$40			
			MHL R14, R1			
			SET R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Find previous format record			
			LBI R1, #$70			
			MLH R1, R1			
			LBI R1, #$C6			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; TST 0004 - format record error?			
			MOVE R14, $92			
			CLR R14, #$FB			
			SZ R14			
			BRA $6E44		; yes, retry	
			MHL R14, R14			
			CLR R14, #$FF			
			SZ R14			
			BRA $6E70			
						
			; Was it a header record?			
			MOVE R5, $86			
			LBI R1, #$81			
			SE R1, R5			
			BRA $6E66		; no, return	
						
			; Yes			
			MOVE R5, $EE		; current tape block	
			SUB R5, #$01			
			MHL R1, R5			
			OR R1, R5			
			SNZ R1			
			BRA $6E66		; BOF, return	
						
			; Read tape block			
			LBI R1, #$70			
			MLH R1, R1			
			LBI R1, #$20			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Decrement tape block number			
			MOVE R5, $EE			
			SUB R5, #$01			
			MOVE $EE, R5			
						
			; Return			
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
			; Decrement retry counter...			
			MOVE R5, $F4			
			SUB R5, #$01			
			MOVE $F4, R5			
			SNZ R5			
			BRA $6E88		; error 07	
						
			; ...and retry			
			LBI R1, #$70			
			MLH R1, R1			
			LBI R1, #$20			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
			BRA $6E2A			
						
			; Error 07			
			; CRC error			
			LBI R1, #$07			
			MOVE $90, R0			
			JMP ($009C)			
						
						
						
						
						
						
			MOVE R5, $EC		; current file number	
			MHL R1, R5			
			OR R1, R5			
			SNZ R1			
			BRA $6EA4		; no current file	
			LBI R1, #$80			
			SNBSH R5, R1			
			BRA $6EA4		; no current file	
						
			; Check last header record file type			
			MOVE R5, $F2			
			SNS R5			
			BRA $6F5E		; error 11	
						
			; OK, not at end of marked tape			
			; Preset retry counter			
			MOVE R5, $A2			
			LBI R1, #$80			
			SBSH R5, R1			
			BRA $6EB0			
			LBI R5, #$01			
			BRA $6EB2			
			LBI R5, #$0A			
			MOVE $F4, R5			
						
			; CLR 0040 - Read into buffer			
			MOVE R1, $92			
			CLR R1, #$40			
			MHL R14, R1			
			CLR R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			; TST 0100 - ignore ATTN?			
			MOVE R14, $92			
			CLR R14, #$FF			
			SZ R14			
			BRA $6ECE			
			MHL R14, R14			
			CLR R14, #$FE			
			SZ R14			
			BRA $6ED8			
						
			; Check ATTN flag			
			MOVE R5, $A4			
			LBI R1, #$80			
			SNBSH R5, R1			
			BRA $6F8C		; ATTN pressed, error 01	
						
			; Read tape header			
			LBI R1, #$70			
			MLH R1, R1			
			LBI R1, #$20			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; TST 0004 - record type error?			
			MOVE R14, $92			
			CLR R14, #$FB			
			SZ R14			
			BRA $6EF2		; yes, retry	
			MHL R14, R14			
			CLR R14, #$FF			
			SZ R14			
			BRA $6F6E			
						
			; Check format record type			
			MOVE R5, $86			
			LBI R1, #$81			
			SE R1, R5			
			BRA $6F64		; not a header record	
						
			; Header record, check data record type			
			MOVE R5, $8C			
			MHL R1, R5			
			OR R1, R5			
			SZ R1			
			BRA $6F6E			
						
			; TST 0001 - error?			
			MOVE R14, $92			
			CLR R14, #$FE			
			SZ R14			
			BRA $6F14		; yes, retry	
			MHL R14, R14			
			CLR R14, #$FF			
			SZ R14			
			BRA $6F6E			
						
			; File type from header record			
			MOVE R14, $84			
			ADD R14, #$01			
			MOVB R5, (R14)			
			MOVE $F2, R5			
						
			; File number from header record			
			MOVE R14, $84			
			ADD R14, #$02			
			MOVB R1, (R14)+			
			MOVB R5, (R14)-			
			MLH R5, R1			
			MOVE $EC, R5			
						
			; Marked file size from header record			
			MOVE R14, $84			
			ADD R14, #$04			
			MOVB R1, (R14)+			
			MOVB R5, (R14)-			
			MLH R5, R1			
			MOVE $F0, R5			
						
			; Sequence relocate indicator			
			MOVE R14, $84			
			ADD R14, #$06			
			MOVB R5, (R14)			
			MOVE R14, $82			
			ADD R14, #$0D			
			MOVE (R14), R5			
						
			; EOD (number of used tape blocks)			
			MOVE R14, $84			
			ADD R14, #$07			
			MOVB R1, (R14)+			
			MOVB R5, (R14)-			
			MLH R5, R1			
			MOVE R14, $82			
			ADD R14, #$07			
			MOVE (R14), R5			
						
			; Preset current record number			
			LBI R5, #$00			
			MLH R5, R5			
			LBI R5, #$01			
			MOVE $EE, R5			
						
			; Return			
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
			; Error 11			
			; Specified file number cannot be found			
			LBI R1, #$0B			
			MOVE $90, R0			
			JMP ($009C)			
						
			; Record was not a header			
			MOVE R5, $8C			
			MHL R1, R5			
			OR R1, R5			
			SZ R1			
			BRA $6E8E		; loop	
						
			; Retry			
			MOVE R5, $F4			
			SUB R5, #$01			
			MOVE $F4, R5			
			SNZ R5			
			BRA $6F86		; error 07	
						
			; Find previous format record			
			LBI R1, #$70			
			MLH R1, R1			
			LBI R1, #$C6			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
			BRA $6EC0		; loop	
						
			; Error 07			
			; CRC error			
			LBI R1, #$07			
			MOVE $90, R0			
			JMP ($009C)			
						
			; Error 01			
			LBI R1, #$01			
			MOVE $90, R0			
			JMP ($009C)			
						
						
						
						
						
						
			; Preset retry counter			
			MOVE R5, $A2			
			LBI R1, #$80			
			SBSH R5, R1			
			BRA $6F9E			
			LBI R5, #$01			
			BRA $6FA0			
			LBI R5, #$0A			
			MOVE $F4, R5			
						
			; TST 0100 - ignore ATTN?			
			MOVE R14, $92			
			CLR R14, #$FF			
			SZ R14			
			BRA $6FB0			
			MHL R14, R14			
			CLR R14, #$FE			
			SZ R14			
			BRA $6FBA		; yes	
						
			; Check ATTN flag			
			MOVE R5, $A4			
			LBI R1, #$80			
			SNBSH R5, R1			
			BRA $701A		; ATTN pressed, error 01	
						
			; Find previous format record			
			LBI R1, #$70			
			MLH R1, R1			
			LBI R1, #$C6			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $6FFE		; error	
						
			; TST 0004 - record type error?			
			MOVE R14, $92			
			CLR R14, #$FB			
			SZ R14			
			BRA $6FD4		; yes, retry	
			MHL R14, R14			
			CLR R14, #$FF			
			SZ R14			
			BRA $6FE6			
						
			; Check format record type			
			MOVE R5, $86			
			LBI R1, #$81			
			SE R1, R5			
			BRA $6F92		; not a header record	
						
			; Clear file type (unknown)			
			MOVE R5, $A0			
			MOVE $F2, R5			
						
			; Return			
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
			; Retry			
			MOVE R5, $F4			
			SUB R5, #$01			
			MOVE $F4, R5			
			SNZ R5			
			BRA $7014		; error 07	
						
			; Read tape header			
			LBI R1, #$70			
			MLH R1, R1			
			LBI R1, #$20			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $6FFE		; error	
			BRA $6FA2		; try again	
						
			; Handle BOT/EOT			
			LBI R1, #$71			
			MLH R1, R1			
			LBI R1, #$8A			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-		; error	
						
			; Clear return code and file number			
			MOVE R5, $A0			
			MOVE $EA, R5			
			MOVE $EC, R5			
						
			; Return			
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
			; Error 07			
			LBI R1, #$07			
			MOVE $90, R0			
			JMP ($009C)			
						
			; Error 01			
			LBI R1, #$01			
			MOVE $90, R0			
			JMP ($009C)			
						
						
						
						
						
						
			; CLR 0038 - don't erase, check status			
			MOVE R1, $92			
			CLR R1, #$38			
			MHL R14, R1			
			CLR R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Start forward tape motion			
			LBI R1, #$73			
			MLH R1, R1			
			LBI R1, #$60			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Read format record			
			LBI R1, #$75			
			MLH R1, R1			
			LBI R1, #$0A			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Read data record			
			LBI R1, #$76			
			MLH R1, R1			
			LBI R1, #$BA			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Stop tape			
			LBI R1, #$74			
			MLH R1, R1			
			LBI R1, #$86			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Return			
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
						
						
			; Calculate CRC of buffer			
			LBI R1, #$74			
			MLH R1, R1			
			LBI R1, #$D2			
			MOVE $96, R0			
			JMP ($009A)			
						
			; SET 0020			
			MOVE R1, $92			
			SET R1, #$20			
			MHL R14, R1			
			SET R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			; CLR 0018			
			MOVE R1, $92			
			CLR R1, #$18			
			MHL R14, R1			
			CLR R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Start forward tape motion			
			LBI R1, #$73			
			MLH R1, R1			
			LBI R1, #$60			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Read format record			
			LBI R1, #$75			
			MLH R1, R1			
			LBI R1, #$0A			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; TST 0006 - record error (e.g. wrong record)?			
			MOVE R14, $92			
			CLR R14, #$F9			
			SZ R14			
			BRA $70A8		; yes	
			MHL R14, R14			
			CLR R14, #$FF			
			SZ R14			
			BRA $70B6			
						
			LBI R1, #$78			
			MLH R1, R1			
			LBI R1, #$80			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Stop tape			
			LBI R1, #$74			
			MLH R1, R1			
			LBI R1, #$86			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Return			
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
						
						
						
						
						
			; CLR 0038 - don't erase, check status			
			MOVE R1, $92			
			CLR R1, #$38			
			MHL R14, R1			
			CLR R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Start reverse tape motion			
			LBI R1, #$74			
			MLH R1, R1			
			LBI R1, #$18			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Read format record			
			LBI R1, #$75			
			MLH R1, R1			
			LBI R1, #$0A			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Stop tape			
			LBI R1, #$74			
			MLH R1, R1			
			LBI R1, #$86			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Return			
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
						
						
						
						
						
			; SET 0030 - erase			
			MOVE R1, $92			
			SET R1, #$30			
			MHL R14, R1			
			SET R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			; CLR 0008			
			MOVE R1, $92			
			CLR R1, #$08			
			MHL R14, R1			
			CLR R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Start tape			
			LBI R1, #$73			
			MLH R1, R1			
			LBI R1, #$60			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Write format record			
			LBI R1, #$78			
			MLH R1, R1			
			LBI R1, #$02			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Write data record			
			LBI R1, #$78			
			MLH R1, R1			
			LBI R1, #$80			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Stop tape			
			LBI R1, #$74			
			MLH R1, R1			
			LBI R1, #$86			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Return			
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
						
			; CLR 00A0			
			MOVE R1, $92			
			CLR R1, #$A0			
			MHL R14, R1			
			CLR R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			; SET 0008			
			MOVE R1, $92			
			SET R1, #$08			
			MHL R14, R1			
			SET R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Start reverse tape motion			
			LBI R1, #$74			
			MLH R1, R1			
			LBI R1, #$18			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $7174		; $0A(R0)	
						
			LBI R1, #$72			
			MLH R1, R1			
			LBI R1, #$E2			
			MOVE $96, R0			
			JMP ($009A)			
						
			; Handle BOT/EOT			
			LBI R1, #$71			
			MLH R1, R1			
			LBI R1, #$8A			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-		; error	
						
			; Clear return code and file number			
			MOVE R5, $A0			
			MOVE $EA, R5			
			MOVE $EC, R5			
						
			; Return			
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
						
						
						
						
						
			; Preset retry counter			
			MOVE R5, $A2			
			LBI R1, #$80			
			SBSH R5, R1			
			BRA $7196			
			LBI R5, #$02			
			BRA $7198			
			LBI R5, #$04			
			MOVE $F4, R5			
						
			; Check for 'physical end of tape' error			
			MOVE R5, $EA			
			LBI R6, #$F1			
			MLH R6, R6			
			LBI R6, #$F2		; compare with '12'	
			SUB R5, R6			
			MHL R6, R5			
			MLH R5, R5			
			MHL R5, R6			
			SUB R6, R5			
			MHL R5, R5			
			MLH R5, R6			
			MHL R1, R5			
			OR R1, R5			
			SZ R1			
			JMP (R15)-		; not end of tape, return	
						
			; SET 0080 - physical end of tape			
			MOVE R1, $92			
			SET R1, #$80			
			MHL R14, R1			
			SET R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Decrement retry counter			
			MOVE R5, $F4			
			SUB R5, #$01			
			MOVE $F4, R5			
			SZ R5			
			BRA $71D6		; retry	
						
			; Error 03			
			; Status error			
			LBI R1, #$72			
			MLH R1, R1			
			LBI R1, #$DC			
			RET R1			
						
						
			; TST 1000			
			MOVE R14, $92			
			CLR R14, #$FF			
			SZ R14			
			BRA $71E4			
			MHL R14, R14			
			CLR R14, #$EF			
			SZ R14			
			BRA $72A6			
						
			; TST 8000 - forward tape motion ?			
			MOVE R14, $92			
			CLR R14, #$FF			
			SZ R14			
			BRA $71F4			
			MHL R14, R14			
			CLR R14, #$7F			
			SZ R14			
			BRA $728C		; yes	
						
			; CLR 3000 - clear BOT and EOT			
			MOVE R1, $92			
			CLR R1, #$00			
			MHL R14, R1			
			CLR R14, #$30			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Start forward tape motion			
			LBI R1, #$73			
			MLH R1, R1			
			LBI R1, #$60			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $7218		; error	
						
			LBI R1, #$72			
			MLH R1, R1			
			LBI R1, #$E2			
			MOVE $96, R0			
			JMP ($009A)			
						
			; Check for 'physical end of tape' error			
			MOVE R5, $EA			
			LBI R6, #$F1			
			MLH R6, R6			
			LBI R6, #$F2			
			SUB R5, R6			
			MHL R6, R5			
			MLH R5, R5			
			MHL R5, R6			
			SUB R6, R5			
			MHL R5, R5			
			MLH R5, R6			
			MHL R1, R5			
			OR R1, R5			
			SZ R1			
			JMP (R15)-			
						
			; TST 1000 - BOT?			
			MOVE R14, $92			
			CLR R14, #$FF			
			SZ R14			
			BRA $7244			
			MHL R14, R14			
			CLR R14, #$EF			
			SZ R14			
			BRA $719A		; yes	
						
			; TST 4000 - backward tape motion?			
			MOVE R14, $92			
			CLR R14, #$FF			
			SZ R14			
			BRA $7256			
			MHL R14, R14			
			CLR R14, #$BF			
			SNZ R14			
			BRA $727C		; no	
						
			; Start backward tape motion			
			LBI R1, #$74			
			MLH R1, R1			
			LBI R1, #$18			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $7218		; error	
						
			; Delay 20000			
			LBI R14, #$4E			
			MLH R14, R14			
			LBI R14, #$20			
			SUB R14, #$01			
			LBI R1, #$80			
			SBSH R14, R1			
			BRA $7268			
						
			; Stop tape			
			LBI R1, #$74			
			MLH R1, R1			
			LBI R1, #$86			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $7218		; error	
						
			; CLR 2080 - clear end of tape and EOT flag			
			MOVE R1, $92			
			CLR R1, #$80			
			MHL R14, R1			
			CLR R14, #$20			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Return			
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
			; CLR 3000 - clear BOT and EOT flags			
			MOVE R1, $92			
			CLR R1, #$00			
			MHL R14, R1			
			CLR R14, #$30			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Start backward tape motion			
			LBI R1, #$74			
			MLH R1, R1			
			LBI R1, #$18			
			MOVE $96, R0			
			JMP ($009A)			
			BRA $7218		; -> -$8C(R0)	
			BRA $720E		; -> -$98(R0)	
						
						
			MOVE R14, $82			
			ADD R14, #$17			
			MOVE (R14), R15			
						
			; Reset tape adapter and reselect tape			
			MOVE R3, $80			
			ADD R3, #$01			
			CTRL $F, #$40		; reset tape adapter	
			MOVE R8, $A6			
			INC2 R2, R0			
			JMP ($00AC)			
			BRA $72D2		; I/O error	
						
			MOVE R14, $82			
			ADD R14, #$17			
			MOVE R15, (R14)			
						
			; TST 2000 - EOT?			
			MOVE R14, $92			
			CLR R14, #$FF			
			SZ R14			
			BRA $72D0			
			MHL R14, R14			
			CLR R14, #$DF			
			SNZ R14			
			BRA $728C		; no, then BOT	
			BRA $71F6		; yes	
						
			; Error			
			MOVE R14, $82			
			ADD R14, #$17			
			MOVE R15, (R14)			
			MOVE $90, R0			
			JMP (R15)-			
						
			; Error 03			
			; Status error			
			LBI R1, #$03			
			MOVE $90, R0			
			JMP ($009C)			
						
						
			; Timeout value $487FFF			
			LBI R11, #$00			
			MLH R11, R11			
			LBI R11, #$90			
			LBI R12, #$7F			
			MLH R12, R12			
			LBI R12, #$FF			
						
			; TST 8190			
			MOVE R14, $92			
			CLR R14, #$6F			
			SZ R14			
			BRA $72FC		; $06(R0)	
			MHL R14, R14			
			CLR R14, #$7E			
			SZ R14			
			BRA $7306		; $08(R0)	
						
			MOVE R5, $A4			
			LBI R1, #$80			
			SNBSH R5, R1			
			BRA $732A		; error 01	
						
			; Check status			
			LBI R5, #$40			
			STAT R5, $E			
			MOVE $8E, R5			
			CLR R5, #$0A			
			LBI R1, #$35			
			SE R5, R1			
			BRA $7330		; OK	
						
			; Decrement timeout value			
			SUB R12, #$01			
			LBI R1, #$80			
			SBSH R12, R1			
			BRA $72EE		; loop	
			SUB R11, #$01			
			LBI R1, #$80			
			SBSH R11, R1			
			BRA $72E8		; loop	
						
			; Error 04			
			LBI R1, #$04			
			MOVE $90, R0			
			JMP ($009C)			
						
			; Error 01			
			LBI R1, #$01			
			MOVE $90, R0			
			JMP ($009C)			
						
			; TST 8000			
			MOVE R14, $92			
			CLR R14, #$FF			
			SZ R14			
			BRA $7340		; $08(R0)	
			MHL R14, R14			
			CLR R14, #$7F			
			SNZ R14			
			BRA $735A		; $1A(R0)	
						
			; TST 0010			
			MOVE R14, $92			
			CLR R14, #$EF			
			SZ R14			
			BRA $7350		; $08(R0)	
			MHL R14, R14			
			CLR R14, #$FF			
			SNZ R14			
			BRA $735A		; $0A(R0)	
						
			MOVE $90, R0			
			LBI R1, #$7B			
			MLH R1, R1			
			LBI R1, #$3E			
			RET R1			
						
			LBI R1, #$00			
			MOVE $90, R0			
			JMP ($009C)			
						
						
						
						
						
						
			; TST 8000 - was forward tape motion?			
			MOVE R14, $92			
			CLR R14, #$FF			
			SZ R14			
			BRA $736E			
			MHL R14, R14			
			CLR R14, #$7F			
			SZ R14			
			BRA $737E			
						
			; No, delay 12000			
			LBI R14, #$2E			
			MLH R14, R14			
			LBI R14, #$E0			
			SUB R14, #$01			
			LBI R1, #$80			
			SBSH R14, R1			
			BRA $7376			
						
			; TST 0010 - erase?			
			MOVE R14, $92			
			CLR R14, #$EF			
			SZ R14			
			BRA $738E			
			MHL R14, R14			
			CLR R14, #$FF			
			SNZ R14			
			BRA $73BA		; not erase, read	
						
			; Check status			
			LBI R5, #$40			
			STAT R5, $E			
			MOVE $8E, R5			
			CLR R5, #$08		; mask out 'Erase on'	
			LBI R1, #$15		; tape stopped?	
			SE R5, R1			
			BRA $7412		; no, error	
						
			; Erase forward both tracks			
			CTRL $E, #$13		; fwd erase ch0+1	
						
			; CLR 4000 - clear backward motion flag			
			MOVE R1, $92			
			CLR R1, #$00			
			MHL R14, R1			
			CLR R14, #$40			
			MLH R1, R14			
			MOVE $92, R1			
						
			; SET 8000 - set forward motion flag			
			MOVE R1, $92			
			SET R1, #$00			
			MHL R14, R1			
			SET R14, #$80			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Return			
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
						
			; Check Status			
			LBI R5, #$40			
			STAT R5, $E			
			MOVE $8E, R5			
			CLR R5, #$02		; mask out 'Write Protected'	
			LBI R1, #$15		; tape stopped?	
			SE R5, R1			
			BRA $7412		; no, error	
						
			; Forward read data track			
			CTRL $E, #$3F		; fwd read ch1	
						
			; CLR 4000 - clear backward motion flag			
			MOVE R1, $92			
			CLR R1, #$00			
			MHL R14, R1			
			CLR R14, #$40			
			MLH R1, R14			
			MOVE $92, R1			
						
			; SET 8000 - set forward motion flag			
			MOVE R1, $92			
			SET R1, #$00			
			MHL R14, R1			
			SET R14, #$80			
			MLH R1, R14			
			MOVE $92, R1			
						
			; TST 0008			
			MOVE R14, $92			
			CLR R14, #$F7			
			SZ R14			
			BRA $73F0		; $06(R0)	
			MHL R14, R14			
			CLR R14, #$FF			
			SZ R14			
			BRA $740E		; return	
						
			; Delay 5000			
			LBI R14, #$13			
			MLH R14, R14			
			LBI R14, #$88			
			SUB R14, #$01			
			LBI R1, #$80			
			SBSH R14, R1			
			BRA $73F8		; -> -$08(R0)	
						
			; Check status			
			LBI R5, #$40			
			STAT R5, $E			
			MOVE $8E, R5			
			CLR R5, #$02		; mask out 'Write Protected'	
			LBI R1, #$35		; tape running?	
			SE R5, R1			
			BRA $7412		; no, error	
						
			; Return			
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
			; Error			
			LBI R1, #$00			
			MOVE $90, R0			
			JMP ($009C)			
						
						
						
						
						
						
			; TST 4000			
			MOVE R14, $92			
			CLR R14, #$FF			
			SZ R14			
			BRA $7426		; $06(R0)	
			MHL R14, R14			
			CLR R14, #$BF			
			SZ R14			
			BRA $7436		; tape running backwards	
						
			; Delay 12000			
			LBI R14, #$2E			
			MLH R14, R14			
			LBI R14, #$E0			
			SUB R14, #$01			
			LBI R1, #$80			
			SBSH R14, R1			
			BRA $742E		; -> -$08(R0)	
						
			; Check status			
			LBI R5, #$40			
			STAT R5, $E			
			MOVE $8E, R5			
			CLR R5, #$0A			
			LBI R1, #$15		; tape stopped and OK?	
			SE R5, R1			
			BRA $7480		; no, error	
						
			; Rewind			
			CTRL $E, #$7F		; read rev. ch0	
						
			; TST 0008			
			MOVE R14, $92			
			CLR R14, #$F7			
			SZ R14			
			BRA $7454		; $06(R0)	
			MHL R14, R14			
			CLR R14, #$FF			
			SZ R14			
			BRA $7464		; $0E(R0)	
						
			; Delay 5000			
			LBI R14, #$13			
			MLH R14, R14			
			LBI R14, #$88			
			SUB R14, #$01			
			LBI R1, #$80			
			SBSH R14, R1			
			BRA $745C		; -> -$08(R0)	
						
			; CLR 8000			
			MOVE R1, $92			
			CLR R1, #$00			
			MHL R14, R1			
			CLR R14, #$80			
			MLH R1, R14			
			MOVE $92, R1			
						
			; SET 4000			
			MOVE R1, $92			
			SET R1, #$00			
			MHL R14, R1			
			SET R14, #$40			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Return			
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
			; Error			
			LBI R1, #$00			
			MOVE $90, R0			
			JMP ($009C)			
						
						
						
						
						
						
			; TST 4000 - backward tape motion?			
			MOVE R14, $92			
			CLR R14, #$FF			
			SZ R14			
			BRA $7496			
			MHL R14, R14			
			CLR R14, #$BF			
			SNZ R14			
			BRA $74A4		; no	
						
			; Yes, delay 3000			
			LBI R14, #$0B			
			MLH R14, R14			
			LBI R14, #$B8			
			SUB R14, #$01			
			LBI R1, #$80			
			SBSH R14, R1			
			BRA $749C		; -> -$08(R0)	
						
			; TST 0010 - erase both tracks?			
			MOVE R14, $92			
			CLR R14, #$EF			
			SZ R14			
			BRA $74B4		; yes	
			MHL R14, R14			
			CLR R14, #$FF			
			SNZ R14			
			BRA $74C6			
						
			; Check status			
			LBI R5, #$40			
			STAT R5, $E			
			MOVE $8E, R5			
			LBI R1, #$3D			
			SE R5, R1		; tape running/erase/not BOT?	
			BRA $74CC		; no, error	
						
			CTRL $E, #$F3		; tape stop, erase 0+1 on (?)	
			MOVE R1, (R15)-			
			INC2 R0, R1		; return	
						
			CTRL $E, #$FF		; full stop	
			MOVE R1, (R15)-			
			INC2 R0, R1		; return	
						
			; Error			
			LBI R1, #$00			
			MOVE $90, R0			
			JMP ($009C)			
						
						
						
						
						
						
			; Preset CRC			
			LBI R6, #$FF			
			MLH R6, R6			
			LBI R6, #$FF			
						
			; Address of buffer			
			MOVE R14, $80			
			ADD R14, #$05			
			MOVE R2, (R14)			
						
			; Size			
			LBI R11, #$02			
			MLH R11, R11			
			LBI R11, #$00			
						
			; Calculate first CRC byte			
			MOVE R5, $8A		; record type	
			LBI R1, #$79			
			MLH R1, R1			
			LBI R1, #$1C			
			MOVE $96, R0			
			JMP ($009A)			
						
			; Get next byte from buffer and calculate new CRC			
			MOVB R5, (R2)+			
			LBI R1, #$79			
			MLH R1, R1			
			LBI R1, #$1C			
			MOVE $96, R0			
			JMP ($009A)			
						
			; Loop until done			
			SUB R11, #$01			
			MHL R1, R11			
			OR R1, R11			
			SZ R1			
			BRA $74F0		; loop	
						
			; Return			
			MOVE $9E, R6		; store CRC	
			JMP (R15)-			
						
						
						
						
						
						
			; Preset level 2 registers			
			LBI R5, #$79			
			MLH R5, R5			
			LBI R5, #$4E			
			MOVE $40, R5		; R0L2	
						
			LBI R5, #$10			
			MLH R5, R5			
			LBI R5, #$50		; 	
			MOVE $56, R5		; R11L2	
						
			LBI R5, #$35		; tape status to monitor	
			MOVE $4C, R5		; R6L0	
						
			LBI R5, #$E7		; sync byte	
			MOVE $4E, R5		; R7L2	
						
			LBI R5, #$80			
			MOVE $50, R5		; R8L0	
						
			LBI R5, #$02			
			MOVE $52, R5		; R9L2	
						
			LBI R5, #$00			
			MLH R5, R5			
			LBI R5, #$53		; Address of Lo(R9L2)	
			MOVE $44, R5		; R2L2	
						
			MOVE R5, $A0			
			MOVE $54, R5		; R10L2	
						
			; CLR 0006 - clear error flags			
			MOVE R1, $92			
			CLR R1, #$06			
			MHL R14, R1			
			CLR R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Check tape status			
			LBI R5, #$40			
			STAT R5, $E			
			MOVE $8E, R5			
			CLR R5, #$02			
			LBI R1, #$35		; tape running?	
			SE R5, R1			
			BRA $7552		; no, error	
			BRA $755A		; yes	
						
			LBI R1, #$76			
			MLH R1, R1			
			LBI R1, #$B4			
			RET R1			
						
			; Change to bit mode			
			LBI R5, #$22			
			LBI R2, #$00			
			MLH R2, R2			
			LBI R2, #$0B		; Lo(R5L0)	
			PUTB $E, (R2)			
						
			; Turn off display			
			CTRL $0, #$6F			
						
			; TST 8000 - forward tape motion?			
			MOVE R14, $92			
			CLR R14, #$FF			
			SZ R14			
			BRA $7576			
			MHL R14, R14			
			CLR R14, #$7F			
			SNZ R14			
			BRA $757C		; reverse	
						
			; Find start of a format record			
						
			; Read fwd format track			
			GETB R5, $E			
			CTRL $E, #$1E		; read fwd ch0 IRQ	
			BRA $7580			
						
			; Read rev format track			
			GETB R5, $E			
			CTRL $E, #$5E		; read rev ch0 IRQ	
						
			; Timeout value 00D000			
			LBI R11, #$00			
			MLH R11, R11			
			LBI R11, #$D0			
			MOVE R12, $A0			
						
			; Wait for first data byte (record type)			
			LBI R1, #$77			
			MLH R1, R1			
			LBI R1, #$CA			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Store record type			
			MOVE $86, R5			
						
			; Check for header record or data record			
			LBI R1, #$81		; header record?	
			SNE R1, R5			
			BRA $75AE		; yes	
			LBI R1, #$18		; data record	
			SNE R1, R5			
			BRA $75AE		; yes	
						
			; Record is neither header nor data			
			; SET 0004			
			MOVE R1, $92			
			SET R1, #$04			
			MHL R14, R1			
			SET R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Wait for second data byte			
			LBI R1, #$77			
			MLH R1, R1			
			LBI R1, #$CA			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Store record number high byte			
			MOVE $8C, R5			
						
			; Wait for third data byte			
			LBI R1, #$77			
			MLH R1, R1			
			LBI R1, #$CA			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Store complete record number			
			MOVE R6, $8C			
			MLH R5, R6			
			MOVE $8C, R5			
						
			; Check for correct record number			
			MOVE R6, $EE			
			SUB R5, R6			
			MHL R6, R5			
			MLH R5, R5			
			MHL R5, R6			
			SUB R6, R5			
			MHL R5, R5			
			MLH R5, R6			
			MHL R1, R5			
			OR R1, R5			
			SNZ R1			
			BRA $75F4		; record found	
						
			; Wrong record number			
			; SET 0002			
			MOVE R1, $92			
			SET R1, #$02			
			MHL R14, R1			
			SET R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
			BRA $7612		; $1E(R0)	
						
			; TST 0020 - erase data track			
			MOVE R14, $92			
			CLR R14, #$DF			
			SZ R14			
			BRA $7604		; $08(R0)	
			MHL R14, R14			
			CLR R14, #$FF			
			SNZ R14			
			BRA $7612		; $0E(R0)	
						
			; Check status			
			LBI R5, #$40			
			STAT R5, $E			
			MOVE $8E, R5			
			LBI R1, #$35			
			SE R5, R1		; tape running?	
			BRA $76B4		; no, error	
						
			; Read format/erase data track			
			CTRL $E, #$1A		; fwd read ch0/erase ch1 IRQ	
						
			; Read 27 bytes (zeroes)			
			LBI R10, #$00			
			MLH R10, R10			
			LBI R10, #$1A			
						
			LBI R1, #$77			
			MLH R1, R1			
			LBI R1, #$CA			
			MOVE $96, R0			
			JMP ($009A)		; wait for next data byte	
			JMP (R15)-			
						
			SUB R10, #$01		; decrement counter	
			LBI R1, #$80			
			SBSH R10, R1			
			BRA $7618		; loop	
						
			; Find second sync byte at end of format record			
						
			LBI R5, #$00			
			MLH R5, R5			
			LBI R5, #$20			
			MOVE $56, R5		; R11L2	
						
			LBI R5, #$79			
			MLH R5, R5			
			LBI R5, #$86			
			MOVE $40, R5		; R0L2	
						
			; Change to bit mode			
			LBI R5, #$22			
			LBI R2, #$00			
			MLH R2, R2			
			LBI R2, #$0B			
			PUTB $E, (R2)			
						
			; Wait for data byte			
			LBI R1, #$77			
			MLH R1, R1			
			LBI R1, #$CA			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			LBI R1, #$E7			
			SNE R1, R5		; sync byte?	
			BRA $7666		; yes	
						
			; Not sync byte, set format record error flag			
			; SET 0004			
			MOVE R1, $92			
			SET R1, #$04			
			MHL R14, R1			
			SET R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
			BRA $7698		; $32(R0)	
						
			; Sync byte found			
			; TST 0020			
			MOVE R14, $92			
			CLR R14, #$DF			
			SZ R14			
			BRA $7676		; $08(R0)	
			MHL R14, R14			
			CLR R14, #$FF			
			SNZ R14			
			BRA $7698		; $22(R0)	
						
			; TST 4006 - backward or error?			
			MOVE R14, $92			
			CLR R14, #$F9			
			SZ R14			
			BRA $7684		; yes	
			MHL R14, R14			
			CLR R14, #$BF			
			SZ R14			
			BRA $7698		; yes	
						
			; Check status			
			LBI R5, #$40			
			STAT R5, $E			
			MOVE $8E, R5			
			LBI R1, #$3D			
			SE R5, R1		; tape running/erase/not BOT?	
			BRA $76B4		; no, error	
						
			; Return			
			CTRL $E, #$3B		; read fwd ch1/erase ch1, no IRQ	
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
			; TST 4000 - backward tape motion?			
			MOVE R14, $92			
			CLR R14, #$FF			
			SZ R14			
			BRA $76A6			
			MHL R14, R14			
			CLR R14, #$BF			
			SZ R14			
			BRA $76AE		; backward	
						
			; Return			
			CTRL $E, #$3F		; read fwd ch1	
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
			; Return			
			CTRL $E, #$7F		; read rev ch1	
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
			; Error			
			LBI R1, #$00			
			MOVE $90, R0			
			JMP ($009C)			
						
						
						
						
						
						
			; Setup registers for level 2			
			LBI R5, #$79			
			MLH R5, R5			
			LBI R5, #$AE			
			MOVE $40, R5		; R0L2	
						
			LBI R5, #$00			
			MLH R5, R5			
			LBI R5, #$40			
			MOVE $56, R5		; R11L2	
						
			LBI R5, #$35			
			MOVE $4C, R5		; R6L2	
						
			LBI R5, #$E7			
			MOVE $4E, R5		; R7L2	
						
			LBI R5, #$80			
			MOVE $50, R5		; R8L2	
						
			LBI R5, #$02			
			MOVE $52, R5		; R9L2	
						
			LBI R5, #$00			
			MLH R5, R5			
			LBI R5, #$53			
			MOVE $44, R5		; R2L2	
						
			MOVE R5, $A0			
			MOVE $54, R5		; R10L2	
						
			; Clear CRC error flag			
			; CLR 0001			
			MOVE R1, $92			
			CLR R1, #$01			
			MHL R14, R1			
			CLR R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Check status			
			LBI R5, #$40			
			STAT R5, $E			
			MOVE $8E, R5			
			CLR R5, #$02			
			LBI R1, #$35			
			SE R5, R1			
			BRA $77C4		; error	
						
			; Change to bit mode			
			LBI R5, #$22			
			LBI R2, #$00			
			MLH R2, R2			
			LBI R2, #$0B			
			PUTB $E, (R2)			
						
			; Enable read interrupts			
			GETB R5, $E			
			CTRL $E, #$3E		; read fwd ch1 irq	
						
			; Timeout 30000			
			LBI R11, #$75			
			MLH R11, R11			
			LBI R11, #$30			
						
			; Buffer address			
			MOVE R14, $80			
			ADD R14, #$05			
			MOVE R2, (R14)			
						
			; Buffer size: 512 bytes			
			LBI R10, #$02			
			MLH R10, R10			
			LBI R10, #$00			
						
			; CRC preset			
			LBI R6, #$FF			
			MLH R6, R6			
			LBI R6, #$FF			
						
			; Wait for first byte (record type)			
			LBI R1, #$77			
			MLH R1, R1			
			LBI R1, #$CA			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Check for error (noteably a timeout)			
			; TST 0001			
			MOVE R14, $92			
			CLR R14, #$FE			
			SZ R14			
			BRA $7740			
			MHL R14, R14			
			CLR R14, #$FF			
			SZ R14			
			BRA $77BE		; read error, return	
						
			; Store record type			
			MOVE $88, R5			
						
			; Calculate initial CRC			
			LBI R1, #$79			
			MLH R1, R1			
			LBI R1, #$1C			
			MOVE $96, R0			
			JMP ($009A)			
						
			; Wait for next byte			
			LBI R1, #$77			
			MLH R1, R1			
			LBI R1, #$CA			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; TST 0040 - verify?			
			MOVE R14, $92			
			CLR R14, #$BF			
			SZ R14			
			BRA $776A		; yes, don't store data byte	
			MHL R14, R14			
			CLR R14, #$FF			
			SNZ R14			
						
			; Store byte read			
			MOVB (R2)+, R5			
						
			; Calculate CRC			
			LBI R1, #$79			
			MLH R1, R1			
			LBI R1, #$1C			
			MOVE $96, R0			
			JMP ($009A)			
						
			; Loop until entire buffer read			
			SUB R10, #$01			
			MHL R1, R10			
			OR R1, R10			
			SZ R1			
			BRA $774E		; loop	
						
			; Wait for next byte			
			LBI R1, #$77			
			MLH R1, R1			
			LBI R1, #$CA			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Calculate CRC			
			LBI R1, #$79			
			MLH R1, R1			
			LBI R1, #$1C			
			MOVE $96, R0			
			JMP ($009A)			
						
			; Wait for next byte			
			LBI R1, #$77			
			MLH R1, R1			
			LBI R1, #$CA			
			MOVE $96, R0			
			JMP ($009A)			
			JMP (R15)-			
						
			; Calculate CRC			
			LBI R1, #$79			
			MLH R1, R1			
			LBI R1, #$1C			
			MOVE $96, R0			
			JMP ($009A)			
						
			; Check CRC			
			MHL R1, R6			
			OR R1, R6			
			SNZ R1			
			BRA $77BE		; OK, return	
						
			; CRC error			
			; SET 0001			
			MOVE R1, $92			
			SET R1, #$01			
			MHL R14, R1			
			SET R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Return			
			CTRL $E, #$3F		; keep tape running	
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
			; Error			
			LBI R1, #$00			
			MOVE $90, R0			
			JMP ($009C)			
						
						
						
						
						
						
						
						
						
						
			; Check status			
			LBI R5, #$40			
			STAT R5, $E			
			MOVE $8E, R5			
			CLR R5, #$0A			
			LBI R1, #$35			
			SE R5, R1		; tape running?	
			BRA $77FC		; no, error	
						
			MOVE R5, $54		; check ISR flag (R10L2)	
			SNZ R5			
			BRA $77E8			
						
			; Byte found, return			
			MOVE R5, $4A		; get byte (R5L2)	
			LBI R1, #$00			
			MOVE $54, R1		; clear ISR flag	
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
			; Decrement timeout counter and loop			
			SUB R12, #$01			
			SZ R12			
			BRA $77CA		; loop	
			SUB R11, #$01			
			LBI R1, #$80			
			SBSH R11, R1			
			BRA $77CA		; loop	
						
			; Error 04			
			LBI R1, #$04			
			MOVE $90, R0			
			JMP ($009C)			
						
			LBI R1, #$00			
			MOVE $90, R0			
			JMP ($009C)			
						
						
						
						
						
						
			LBI R5, #$7A			
			MLH R5, R5			
			LBI R5, #$1A			
			MOVE $40, R5		; R0L2	
						
			LBI R5, #$3D		; tape status to monitor	
			MOVE $4C, R5		; R6L2	
						
			MOVE R5, $EE		; record number	
			MOVE $4E, R5		; R7L2	
						
			LBI R5, #$80		; test byte count for sign bit	
			MOVE $50, R5		; R8L2	
						
			LBI R5, #$02		; first transition	
			MOVE $52, R5		; R9L2	
						
			LBI R5, #$00			
			MLH R5, R5			
			LBI R5, #$4A		; address if Hi(R5L2)	
			MOVE $44, R5		; R2L2	
						
			LBI R5, #$00			
			MLH R5, R5			
			LBI R5, #$F9		; byte count (249 bytes)	
			MOVE $56, R5		; R11L2	
						
			LBI R5, #$00			
			MLH R5, R5			
			LBI R5, #$AA		; first byte SHL 1	
			MOVE $4A, R5		; R5L2	
						
			LBI R5, #$07		; bit count - 1	
			MOVE $58, R5		; R12L2	
						
			; Check status			
			GETB R1, $E			
			LBI R5, #$40			
			STAT R5, $E			
			MOVE $8E, R5			
			LBI R1, #$3D			
			SE R5, R1			
			BRA $787A		; $36(R0)	
						
			LBI R2, #$00			
			MLH R2, R2			
			LBI R2, #$4A			
			PUTB $E, (R2)			
			CTRL $0, #$6F			
			CTRL $4, #$43			
			CTRL $E, #$22		; write fwd ch0/erase ch0+1	
						
			; Timeout value 12000			
			LBI R11, #$2E			
			MLH R11, R11			
			LBI R11, #$E0			
						
			; Check status			
			LBI R5, #$40			
			STAT R5, $E			
			MOVE R6, $50		; R8L2	
			SNZ R6			; has ISR finished its work?
			BRA $7876		; yes, return	
			LBI R1, #$3D			
			SE R5, R1			
			BRA $787A		; error	
						
			; Decrement timeout value			
			SUB R11, #$01			
			LBI R1, #$80			
			SBSH R11, R1			
			BRA $7858		; loop	
						
			; Error 04			
			LBI R1, #$04			
			MOVE $90, R0			
			JMP ($009C)			
						
			; Return			
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
			; Error			
			LBI R1, #$00			
			MOVE $90, R0			
			JMP ($009C)			
						
						
						
						
						
			LBI R5, #$7A			
			MLH R5, R5			
			LBI R5, #$F4			
			MOVE $40, R5		; R0L2	
						
			LBI R5, #$3D			
			MOVE $4C, R5		; R6L2	
						
			LBI R5, #$80			
			MOVE $50, R5		; R8L2	
						
			LBI R5, #$02			
			MOVE $52, R5		; R9L2	
						
			LBI R5, #$00			
			MLH R5, R5			
			LBI R5, #$4A			
			MOVE $44, R5		; R2L2	
						
			LBI R5, #$01			
			MLH R5, R5			
			LBI R5, #$FF			
			MOVE $56, R5		; R11L2	
						
			MOVE R14, $80			
			ADD R14, #$05			
			MOVE R5, (R14)			
			MOVE $46, R5		; R3L2	
						
			LBI R5, #$7A			
			MLH R5, R5			
			LBI R5, #$8E			
			MOVE $48, R5		; R4L2	
						
			MOVE R5, $A0			
			MOVE $4A, R5		; R5L2	
						
			LBI R5, #$07			
			MOVE $58, R5		; R12L2	
						
			; Check status			
			GETB R1, $E			
			LBI R5, #$40			
			STAT R5, $E			
			MOVE $8E, R5			
			LBI R1, #$3D			
			SE R5, R1			
			BRA $7916		; $4C(R0)	
						
			LBI R2, #$00			
			MLH R2, R2			
			LBI R2, #$4A			
						
			; TST 0010			
			MOVE R14, $92			
			CLR R14, #$EF			
			SZ R14			
			BRA $78DE		; $06(R0)	
			MHL R14, R14			
			CLR R14, #$FF			
			SZ R14			
			BRA $78E8		; $08(R0)	
						
			PUTB $E, (R2)			
			CTRL $4, #$43			
			CTRL $E, #$0A		; write fwd ch1/erase ch1 irq	
			BRA $78EE		; $06(R0)	
						
			PUTB $E, (R2)			
			CTRL $4, #$43			
			CTRL $E, #$02		; write fwd ch1/erase ch0+1 irq	
						
			; Timeout value 12000			
			LBI R11, #$2E			
			MLH R11, R11			
			LBI R11, #$E0			
						
			; Check status			
			LBI R5, #$40			
			STAT R5, $E			
			MOVE R6, $50			
			SNZ R6			
			BRA $7912		; return	
			LBI R1, #$3D			
			SE R5, R1			
			BRA $7916		; error	
						
			; Decrement timeout value			
			SUB R11, #$01			
			LBI R1, #$80			
			SBSH R11, R1			
			BRA $78F4		; loop	
						
			; Error 04			
			LBI R1, #$04			
			MOVE $90, R0			
			JMP ($009C)			
						
			; Return			
			MOVE R1, (R15)-			
			INC2 R0, R1			
						
			; Error			
			LBI R1, #$00			
			MOVE $90, R0			
			JMP ($009C)			
						
						
						
			MHL R7, R6			
			XOR R7, R5			
			MOVE R1, R7			
			MOVE R8, R7			
			SWAP R8			
			XOR R7, R8			
			CLR R7, #$0F			
			XOR R7, R6			
			MOVE R6, R1			
			CLR R8, #$F0			
			XOR R6, R8			
			ROR3 R1			
			MOVE R8, R1			
			CLR R8, #$E0			
			XOR R7, R8			
			CLR R1, #$1F			
			XOR R6, R1			
			SWAP R8			
			MOVE R1, R8			
			CLR R8, #$1F			
			XOR R6, R8			
			CLR R1, #$FE			
			XOR R7, R1			
			MLH R6, R7			
						
			JMP (R15)-			
						
						
						
						
						
						
			; We're in bit mode here...			
						
			; Wait for 0 byte			
						
			; Check status			
			LBI R5, #$40			
			STAT R5, $E			
			CLR R5, #$0A			
			SE R5, R6			
			BRA $7A06			
						
			; Status OK, read data latch			
			LBI R5, #$80			
			STAT R5, $E			
			SNZ R5			
			BRA $7982		; 0 byte found	
						
			SUB R11, #$01			
			SNBSH R11, R8			
			BRA $79A2		; timeout	
						
			GETB R5, $E		; reset interrupt 2	
			BRA $794E		; loop	
						
			; Wait for sync byte $E7			
						
			; Check status			
			LBI R5, #$40			
			STAT R5, $E			
			CLR R5, #$0A			
			SE R5, R6			
			BRA $7A06			
						
			; Status OK, read data latch			
			LBI R5, #$80			
			STAT R5, $E			
			SNE R5, R7			
			BRA $79E6		; sync byte found	
						
			SUB R11, #$01			
			SNBSH R11, R8			
			BRA $79A2		; timeout	
						
			GETB R5, $E			
			BRA $796A		; loop	
						
						
						
						
						
						
			; Reset interruot			
			GETB R5, $E			
						
			; Check status			
			LBI R5, #$40			
			STAT R5, $E			
			CLR R5, #$0A			
			SE R5, R6			
			BRA $7A06		; error	
						
			; Synchronize to sync byte			
			LBI R5, #$80			
			STAT R5, $E			
			SNE R5, R7			
			BRA $7A00		; sync byte found	
						
			SUB R11, #$01			
			SNBSH R11, R8			
			BRA $7A00		; timeout	
			BRA $7986		; loop	
						
						
						
			; Error 04			
			LBI R6, #$04			
			MOVE $90, R0			
						
			LBI R1, #$7C			
			MLH R1, R1			
			LBI R1, #$84			
			RET R1			
						
						
						
						
						
						
						
			; Check status			
			LBI R5, #$40			
			STAT R5, $E			
			CLR R5, #$0A			
			SE R5, R6			
			BRA $7A06		; error	
						
			; Read data latch, loop until non-zero			
			LBI R5, #$80			
			STAT R5, $E			
			SNZ R5			
			BRA $79E2		; zero found	
						
			SUB R11, #$01			
			SNBSH R11, R8			
			BRA $79F4		; timeout	
						
			GETB R5, $E		; reset interrupt	
			BRA $79AE		; loop	
						
			; Check status			
			LBI R5, #$40			
			STAT R5, $E			
			CLR R5, #$0A			
			SE R5, R6			
			BRA $7A06		; error	
						
			; Read data latch, loop until match			
			LBI R5, #$80			
			STAT R5, $E			
			SNE R5, R7			
			BRA $79E6		; sync byte found	
						
			SUB R11, #$01			
			SNBSH R11, R8			
			BRA $79F4		; timeout	
						
			GETB R5, $E		; reset interrupt	
			BRA $79CA		; loop	
						
						
						
						
						
						
			; Synchronized, change to byte mode			
			PUTB $E, (R2)			
						
			; Reset interrupt (wait for byte to arrive)			
			GETB R1, $E			
						
			; Get data byte			
			NOP			
			LBI R5, #$80			
			STAT R5, $E			
						
			LBI R10, #$FF		; set flag	
			BRA $79E8		; loop	
						
						
						
			; SET 0001			
			MOVE R1, $92			
			SET R1, #$01			
			MHL R14, R1			
			SET R14, #$00			
			MLH R1, R14			
			MOVE $92, R1			
						
			; Bit/Byte read loop			
			LBI R10, #$FF		; set flag	
			GETB R1, $E		; clear interrupt	
			BRA $7A00		; loop	
						
						
			MOVE $8E, R5			
			LBI R6, #$00			
			MOVE $90, R0			
			LBI R1, #$7C			
			MLH R1, R1			
			LBI R1, #$84			
			RET R1			
						
						
						
						
						
						
			; 1. Write bit pattern $55			
						
			LBI R5, #$55		; bit pattern	
			LBI R12, #$08		; bit count	
						
			GETB R1, $E		; reset interrupt	
						
			; Check status			
			LBI R14, #$40			
			STAT R14, $E			
			SE R14, R6			
			BRA $7B0A		; error	
						
			; Write bit			
			MLH R5, R9			
			ADD R5, R5			
			PUTB $E, (R2)			
						
			; Decrement bit count			
			SUB R12, #$01			
			SZ R12			
			BRA $7A18		; bit loop	
						
			; Decrement byte count			
			SUB R11, #$01			
			SBSH R11, R8			
			BRA $7A14		; byte loop	
						
			; 2. Write format record data			
						
			INC2 R4, R0			
			BRA $7AF0		; write 00	
						
			INC2 R4, R0			
			BRA $7AF0		; write 00	
						
			LBI R5, #$E7			
			INC2 R4, R0			
			BRA $7AF0		; write E7 (sync. byte)	
						
			MOVE R5, $86			
			INC2 R4, R0			
			BRA $7AF0		; write record ID	
						
			MHL R5, R7			
			INC2 R4, R0			
			BRA $7AF0		; write Hi(record number)	
						
			MOVE R5, R7			
			INC2 R4, R0			
			BRA $7AF0		; write Lo(record number)	
						
			; 3. Write 29 zeroes			
						
			LBI R11, #$1D		; 29 bytes	
			LBI R12, #$08		; bit count	
			GETB R1, $E			
			LBI R14, #$40			
			STAT R14, $E			
			SE R14, R6			
			BRA $7B0A		; error	
						
			; Write bit			
			MLH R5, R9			
			ADD R5, R5			
			PUTB $E, (R2)			
						
			SUB R12, #$01			
			SZ R12			
			BRA $7A58		; bit loop	
						
			SUB R11, #$01			
			SZ R11			
			BRA $7A56		; byte loop	
						
			; 4. Write data in reverse order			
						
			MOVE R5, $86			
			INC2 R4, R0			
			BRA $7AF0		; write record ID	
						
			LBI R5, #$E7			
			INC2 R4, R0			
			BRA $7AF0		; write E7 (sync. byte)	
						
			INC2 R4, R0			
			BRA $7AF0		; write 00	
						
			INC2 R4, R0			
			BRA $7AF0		; write 00	
						
			GETB R1, $E		; reset interrupt	
						
			; Done, clear flag and disable interrupt			
						
			LBI R8, #$00		; done	
			CTRL $E, #$13		; keep erasing ch0+1, dis. IRQ	
						
						
						
						
						
						
			; Write zero			
			INC2 R4, R0			
			BRA $7AF0			
						
			; Write sync byte			
			LBI R5, #$E7			
			INC2 R4, R0			
			BRA $7AF0			
						
			; Write record type			
			MOVE R5, $8A			
			INC2 R4, R0			
			BRA $7AF0			
						
			; Write data data buffer			
			MOVB R5, (R3)+		; get next byte from buffer	
			LBI R12, #$08		; bit count	
			GETB R1, $E			
			LBI R14, #$40			
			STAT R14, $E			
			SE R14, R6			
			BRA $7B0A		; error	
			MLH R5, R9			
			ADD R5, R5			
			PUTB $E, (R2)			
			SUB R12, #$01			
			SZ R12			
			BRA $7AA2		; bit loop	
			SUB R11, #$01			
			SBSH R11, R8			
			BRA $7A9E		; byte loop	
						
			; Write high byte of CRC			
			MOVE R5, $9E			
			MHL R5, R5			
			INC2 R4, R0			
			BRA $7AF0			
						
			; Write low byte of CRC			
			MOVE R5, $9E			
			INC2 R4, R0			
			BRA $7AF0			
						
			; Write zero			
			INC2 R4, R0			
			BRA $7AF0			
						
			; Write zero			
			INC2 R4, R0			
			BRA $7AF0			
						
			; TST 0010			
			MOVE R14, $92			
			CLR R14, #$EF			
			SZ R14			
			BRA $7AE2			
			MHL R14, R14			
			CLR R14, #$FF			
			SZ R14			
			BRA $7AEA			
						
			GETB R1, $E		; reset interrupt	
			LBI R8, #$00		; done	
			CTRL $E, #$3F		; fwd read, dis. IRQ	
						
			GETB R1, $E		; reset interrupt	
			LBI R8, #$00		; done	
			CTRL $E, #$13		; keep erasing ch0+1, dis. IRQ	
						
						
						
						
						
						
						
			LBI R12, #$08		; bit count	
			GETB R1, $E		; reset interrupt	
						
			; Check status			
			LBI R14, #$40			
			STAT R14, $E			
			SE R14, R6			
			BRA $7B0A		; error	
						
			MLH R5, R9			
			ADD R5, R5			
			PUTB $E, (R2)			
						
			; Decrement bit count			
			SUB R12, #$01			
			SZ R12			
			BRA $7AF2		; bit loop	
						
			; Return			
			RET R4			
						
						
						
			; Error			
			MOVE $8E, R14		; save tape status	
						
			MOVE R5, R14			
			LBI R6, #$00			
			MOVE $90, R0			
						
			LBI R1, #$7C			
			MLH R1, R1			
			LBI R1, #$82			
			RET R1			
						
						
						
			; Error code routine			
						
			CTRL $E, #$FF			
			ADD R1, R1			
			ADD R0, R1			
			BRA $7B3E		; $1C(R0)	
			BRA $7B60		; $3C(R0)	
			BRA $7B88		; error 02	
			BRA $7B90		; error 03	
			BRA $7B98		; error 04	
			HALT			
			HALT			
			BRA $7BB4		; error 07	
			BRA $7BBC		; error 08	
			BRA $7BC4		; error 09	
			BRA $7BCC		; error 10	
			BRA $7BD4		; error 11	
			BRA $7BDC		; error 12	
			HALT			
			HALT			
						
			LBI R1, #$10		; cartridge in place?	
			SNBC R5, R1			
			BRA $7B50		; no	
						
			LBI R1, #$01		; beginning of tape?	
			SNBC R5, R1			
			BRA $7BE6		; yes	
						
			LBI R1, #$80		; end of tape?	
			SBC R5, R1			
			BRA $7BE6		; yes	
						
			CTRL $E, #$FF		; stop all	
			LBI R1, #$10		; cartridge in place?	
			SNBC R5, R1			
			BRA $7BA0		; no, error 05	
						
			LBI R1, #$02		; file protected?	
			SBC R5, R1			
			BRA $7BAC		; yes, error 06	
			BRA $7B90		; no, error 03	
						
			; Delay 12000			
			LBI R14, #$2E			
			MLH R14, R14			
			LBI R14, #$E0			
			SUB R14, #$01			
			LBI R1, #$80			
			SBSH R14, R1			
			BRA $7B66			
						
			LBI R5, #$40			
			STAT R5, $E			
			MOVE $8E, R5			
			CLR R5, #$02			
			LBI R1, #$15		; tape stopped?	
			SE R5, R1			
			BRA $7B80		; no	
						
			; Tape stopped, this is OK (why?!?)			
			MOVE R5, $A0			
			BRA $7BE2		; return	
						
			CLR R5, #$02			
			LBI R1, #$00			
			MOVE $90, R0			
			JMP ($009C)			
						
			; Error 02			
			LBI R5, #$F0			
			MLH R5, R5			
			LBI R5, #$F2			
			BRA $7BE2		; $52(R0)	
						
			; Error 03			
			LBI R5, #$F0			
			MLH R5, R5			
			LBI R5, #$F3			
			BRA $7BE2		; $4A(R0)	
						
			; Error 04			
			LBI R5, #$F0			
			MLH R5, R5			
			LBI R5, #$F4			
			BRA $7BE2		; $42(R0)	
						
			; Error 05			
			MOVE R5, $A0			
			MOVE $EC, R5			
			LBI R5, #$F0			
			MLH R5, R5			
			LBI R5, #$F5			
			BRA $7BE2		; $36(R0)	
						
			; Error 06			
			LBI R5, #$F0			
			MLH R5, R5			
			LBI R5, #$F6			
			BRA $7BE2		; $2E(R0)	
						
			; Error 07			
			LBI R5, #$F0			
			MLH R5, R5			
			LBI R5, #$F7			
			BRA $7BE2		; $26(R0)	
						
			; Error 08			
			LBI R5, #$F0			
			MLH R5, R5			
			LBI R5, #$F8			
			BRA $7BE2		; $1E(R0)	
						
			; Error 09			
			LBI R5, #$F0			
			MLH R5, R5			
			LBI R5, #$F9			
			BRA $7BE2		; $16(R0)	
						
			; Error 10			
			LBI R5, #$F1			
			MLH R5, R5			
			LBI R5, #$F0			
			BRA $7BE2		; $0E(R0)	
						
			; Error 11			
			LBI R5, #$F1			
			MLH R5, R5			
			LBI R5, #$F1			
			BRA $7BE2		; $06(R0)	
						
			; Error 12			
			LBI R5, #$F1			
			MLH R5, R5			
			LBI R5, #$F2			
						
			; Return			
			MOVE $EA, R5		; store code in IOCB_Ret	
			JMP (R15)-			
						
						
						
			LBI R1, #$01			
			SBC R5, R1			
			BRA $7BF8		; $0C(R0)	
						
			; SET 2000			
			MOVE R1, $92			
			SET R1, #$00			
			MHL R14, R1			
			SET R14, #$20			
			MLH R1, R14			
			MOVE $92, R1			
						
			LBI R1, #$80			
			SNBC R5, R1			
			BRA $7C0A			
						
			; SET 1000			
			MOVE R1, $92			
			SET R1, #$00			
			MHL R14, R1			
			SET R14, #$10			
			MLH R1, R14			
			MOVE $92, R1			
						
			; TST 8090			
			MOVE R14, $92			
			CLR R14, #$6F			
			SZ R14			
			BRA $7C18		; $06(R0)	
			MHL R14, R14			
			CLR R14, #$7F			
			SZ R14			
			BRA $7C2A		; $10(R0)	
						
			; Delay 12000			
			LBI R14, #$2E			
			MLH R14, R14			
			LBI R14, #$E0			
			SUB R14, #$01			
			LBI R1, #$80			
			SBSH R14, R1			
			BRA $7C20		; -> -$08(R0)	
			BRA $7C38		; $0E(R0)	
						
			; Delay 5000			
			LBI R14, #$13			
			MLH R14, R14			
			LBI R14, #$88			
			SUB R14, #$01			
			LBI R1, #$80			
			SBSH R14, R1			
			BRA $7C30		; -> -$08(R0)	
						
			; Check status			
			; [now this really looks like the output from			
			;  a macro expansion...]			
			LBI R5, #$40			
			STAT R5, $E			
			MOVE $8E, R5			
			LBI R1, #$00			
			SE R5, R1			
			NOP			
			LBI R1, #$01			
			SBC R5, R1			
			BRA $7C56		; $0C(R0)	
						
			; SET 2000			
			MOVE R1, $92			
			SET R1, #$00			
			MHL R14, R1			
			SET R14, #$20			
			MLH R1, R14			
			MOVE $92, R1			
						
			LBI R1, #$80			
			SNBC R5, R1			
			BRA $7C68		; $0C(R0)	
						
			; SET 1000			
			MOVE R1, $92			
			SET R1, #$00			
			MHL R14, R1			
			SET R14, #$10			
			MLH R1, R14			
			MOVE $92, R1			
						
			; CMP 8x9x			
			MOVE R14, $92			
			CLR R14, #$6F			
			LBI R1, #$90			
			SBS R14, R1			
			BRA $7C7A		; $08(R0)	
			LBI R1, #$80			
			MHL R14, R14			
			CLR R14, #$7F			
			SBS R14, R1			
			BRA $7C7E		; $02(R0)	
						
			CTRL $E, #$F3			
						
			GETB R5, $E			
			BRA $7BDC		; error 12	
						
						
						
						
						
						
			GETB R14, $E		; reset interrupt	
						
			MOVE $02, R6		; R1L0	
			MOVE $0A, R5		; R5L0	
			MOVE R1, $9C			
			MOVE $00, R1		; R0L0	
			CTRL $E, #$FF		; stop all	
						
						
						
			HALT			
						ORG $7EFE
			HALT			
						
						
						
						
						
			MOVE R1, $D8		; Vector table for I/O routines	
			ADD R1, #$3C		; Vector to device F	
			MOVE R7, (R1)			
			INC2 R15, R3			
			MOVB R14, (R15)+	; IOCB_Cmd		
			MOVB R13, (R15)---	; IOCB_Flags		
			SNZ R14			
			BRA $7F1C		; "Sense" command	
						
			LBI R12, #$30			
						
			LBI R1, #$03			
			SLE R14, R1		; Read or Write ?	
			BRA $7F20		; No	
						
			SBC R13, R12			
			BRA $7F48		; Bit 2 or 3 set	
						
			MOVE R8, $0E		; R7L0, contains vector	
			JMP ($00AC)		; Do I/O and return to caller	
						
						
			; Commands other than Read or Write			
						
			LBI R1, #$FD		; Is it "Translate only" ?	
			SE R14, R1			
			BRA $7F1C		; No, do I/O	
						
			; Translate only			
						
			SBC R13, R12			
			BRA $7F38		; Bit 2 or 3 set	
						
			; Bit 2 and 3 clear -> error			
						
			LBI R12, #$F0			
			MLH R12, R12			
			LBI R12, #$F2			
			ADD R15, #$0C		; IOCB_Ret	
			MOVE (R15), R12		; Error 02	
			MOVE R8, R2			
			JMP ($00AC)		; Return to caller	
						
						
			LBI R10, #$00		; Tape code -> EBCDIC	
			LBI R1, #$10			
			SBS R13, R1		; Is bit 3 set ?	
			LBI R10, #$FF		; Yes: EBCDIC -> tape code	
						
			INC2 R8, R0			
			BRA $7F94		; Convert	
						
			MOVE R8, R2			
			JMP ($00AC)		; Return to caller	
						
						
			LBI R1, #$01			
			SGT R14, R1		; Write ?	
			BRA $7F5A		; No	
						
			; Write: Convert buffer first			
						
			LBI R10, #$00			
			LBI R1, #$10			
			SBS R13, R1			
			LBI R10, #$FF			
			INC2 R8, R0			
			BRA $7F94		; Convert	
						
			; Do I/O (read or write)			
						
			MOVE $D4, R2		; Save R2	
			MOVE R8, $0E		; R7L0 contains I/O vector	
			INC2 R2, R0			
			JMP ($00AC)		; Do I/O	
			MOVE R2, $D4		; Restore R2	
						
			INC2 R15, R3			
			MOVB R14, (R15)+	; IOCB_Cmd		
			MOVB R13, (R15)---	; IOCB_Flags		
						
			LBI R10, #$FF			
			LBI R1, #$20			
			SBS R13, R1		; Bit 2 set ?	
			LBI R10, #$00			
						
			LBI R1, #$01			
			SNE R14, R1		; Read ?	
			BRA $7F8C		; Yes, convert after read	
						
			; Write			
						
			ADD R15, #$0C			
			MOVE R12, (R15)		; Get IOCB_Ret	
			SZ R12			; Error occured ?
			BRA $7F84		; Yes	
						
			MOVE R8, R2		; No	
			JMP ($00AC)		; Return to caller	
						
						
			LBI R10, #$FF			
			LBI R1, #$10			
			SBS R13, R1			
			LBI R10, #$00			
						
			INC2 R8, R0			
			BRA $7F94		; Convert	
						
			MOVE R8, R2			
			JMP ($00AC)		; Return to caller	
						
						
						
						
						
			MOVE R15, R3			
			ADD R15, #$04			
			MOVE R14, (R15)+	; IOCB_BA		
			MOVE R13, (R15)		; IOCB_BS	
			LBI R15, #$0B			
			MLH R15, R15			
			LBI R15, #$F2		; R15 <- $0BF2 (word address!)	
			MOVE R12, $A0			
			LBI R12, #$1E		; Address of R15L0	
			CTRL $1, #$02		; Select Common ROS	
			PUTB $1, (R12)+		; Hi(Address)	
			PUTB $1, (R12)-		; Lo(Address)	
			BRA $7FAD		; Delay jump	
						
			; Get word address of conversion code table			
						
			GETB R11, $1		; Get Hi-byte	
			MLH R11, R11			
			NOP			
			GETB R11, $1		; Get Lo-byte	
						
			MOVE R15, R11			
			MOVB R9, (R14)		; Get character from buffer	
			ADD R15, R9			
			PUTB $1, (R12)+			
			PUTB $1, (R12)-			
			BRA $7FC1		; Delay jump	
						
			GETB R9, $1		; Get converted character	
			NOP			
			SZ R10			; Which conversion direction ?
			GETB R9, $1		; Get other character	
						
			MOVB (R14)+, R9		; Put converted character back	
						
			SUB R13, #$01			
			MHL R1, R13			
			OR R1, R13			
			SZ R1			
			BRA $7FB6		; Loop over all characters	
						
			RET R8			; Return to caller
						
						
			HALT			
			HALT			
			HALT			
						
						
						
						
						
						
						
			LBI R1, #$02			
			MLH R1, R1			
			LBI R1, #$04			
			MOVE $1C6, R1		; $01C6 <- $0204	
						
			LBI R1, #$7F			
			MLH R1, R1			
			LBI R1, #$00		; R1 <- Address of dev. E rout.	
			MOVE R4, $D8			
			ADD R4, #$38			
			MOVE (R4)++, R1		; Set vector for device E	
						
			LBI R1, #$60			
			MLH R1, R1			
			LBI R1, #$00		; R1 <- Address of dev. F rout.	
			MOVE (R4), R1		; Set vector for device F	
						
			MOVE R8, R2			
			JMP ($00AC)		; Return to caller	
						
			BRA $7FDE		; Entry point for above routine	
						
						
						
						
