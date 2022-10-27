; ***********************************************************
;
; Moves a "ball" within the screen boundaries. In addition
; some walls as obstacles are added.
;
; ***********************************************************

        cpu IBM5110

        include "ebcdic.inc"
        intsyntax       +$hex,-x'hex'   ; < support $-style hex instead of IBM 0x style
	codepage cp037                  ; < activate the EBCDIC mapping of chars
        org $0B00

Start:

        ; Set processor state
        MOVE R1, $A4
        LWI R15, #Status_Save
        MOVE (R15), R1

        MHL R2, R1
        CLR R2, #$04
        SET R2, #$01
        MLH R1, R2
        MOVE $A4, R1

        CTRL $0, #$77        ; turn screen on

Main:

SCREENSIZE equ 16*64

        CALL ClrScr, R2
        CALL BuildWalls, R2

        MOVE R1, $A0
        LWI R2, #XPos
        LBI R1, #17
        MOVE (R2)+, R1        ; XPos
        LBI R1, #3
        MOVE (R2)+, R1        ; YPos
        LBI R1, #$11
        MOVE (R2), R1        ; direction

Loop:
        LWI R7, #$0200

        ; Calculate a screen address from line and column
        LWI R4, #YPos
        MOVE R3, (R4)-
        SNZ R3
        BRA l2
l1:     ADD R7, #64
        DEC R3, R3
        SZ R3
        BRA l1

l2:     MOVE R3, (R4)--
        ADD R7, R3

        MOVE R3, (R4)+

        MOVB R6, (R7)        ; save contents of prev. location
        MOVB (R7), R3        ; writes "ball" into location

        CALL Delay, R2
        CALL CalcNewPos, R2

;
;
        MOVB (R7), R6        ; restore prev. location

        BRA Loop

        JMP Ende

; ********

ClrScr:
        LWI R5, #$0200
        LWI R6, #SCREENSIZE
        LBI R7, #' '
cs_1:   MOVB (R5)+, R7
        DEC R6, R6
        MHL R8, R6
        OR R8, R6
        SZ R8
        BRA cs_1
        RET R2

; ********

BuildWalls:
        LWI R5, #$0200+(11*64)+10
        LBI R6, #5
        LWI R7, #$FFFF

bw_1:   MOVE (R5), R7
        SUB R6, #1
        SNZ R6
        BRA bw_2
        ADD R5, #64
        BRA bw_1

bw_2:   LWI R5, #$0200+(2*64)+50
        LBI R6, #3
bw_4:   MOVE (R5), R7
        SUB R6, #1
        SNZ R6
        BRA bw_5
        ADD R5, #64
        BRA bw_4

bw_5:   LWI R5, #$0200+(4*64)+30
        LBI R6, #8
bw_6:   MOVE (R5), R7
        SUB R6, #1
        SNZ R6
        BRA bw_7
        ADD R5, #64
        BRA bw_6

bw_7:   LWI R5, #$0200+(12*64)+38
        LBI R6, #4
bw_8:   MOVE (R5)+, R7
        SUB R6, #1
        SZ R6
        BRA bw_8

bw_9:   LWI R5, #$0200+(8*64)+20
        LBI R6, #3
bw_10:  MOVE (R5)+, R7
        SUB R6, #1
        SZ R6
        BRA bw_10

bw_99:  RET R2

; ********

Delay:
        LWI R15, #3000
del_1:  SUB R15, #1
        MHL R14, R15
        OR R14, R15
        SZ R14
        BRA del_1
        RET R2

; ********

CalcNewPos:
        LWI R5, #Richt
        MOVE R15, (R5)

        ; X-Position

        LWI R5, #XPos
        MOVE R10, (R5)
        MOVE R13, R10                ; store old X-pos.
        LBI R3, #$10
        SNBS R15, R3
        BRA cnp1

        ADD R10, #1
        LBI R12, #63
        SGE R10, R12
        BRA cnp2
        SET R15, #$10
        CALL Sound, R8
        BRA cnp2

cnp1:   SUB R10, #1
        SZ R10
        BRA cnp2
        CLR R15, #$10
        CALL Sound, R8

cnp2:
        ; Check if ball touched the side of a wall
        SGT R10, R13
        BRA cnp2_1
        INC R14, R7
        BRA cnp2_2
cnp2_1: DEC R14, R7
cnp2_2:
        MOVB R8, (R14)
        LBI R9, #$FF
        SE R8, R9
        BRA cnp2_3

        ; Collision with wall
        MOVE R10, R13        ; return to old X-pos.
        LBI R9, #$10
        XOR R15, R9          ; reverse X direction
        CALL Sound, R8
        BRA cnp5             ; keep Y-pos.

cnp2_3: MOVE (R5), R10


        ; Y-Position

        LWI R5, #YPos
        MOVE R10, (R5)
        LBI R3, #$01
        SNBS R15, R3
        BRA cnp3

        ADD R10, #1
        LBI R12, #15
        SGE R10, R12
        BRA cnp4
        SET R15, #$01
        CALL Sound, R8
        BRA cnp4

cnp3:   SUB R10, #1
        SZ R10
        BRA cnp4
        CLR R15, #$01
        CALL Sound, R8

cnp4:
        ; Check if ball touched the top or bottom of a wall
        MOVE R11, (R5)        ; store old Y-pos.
        SGT R10, R11
        BRA cnp4_1
        ADD R14, #64
        BRA cnp4_2
cnp4_1: SUB R14, #64
cnp4_2:
        MOVB R8, (R14)
        LBI R9, #$FF
        SE R8, R9
        BRA cnp4_3
        ; Collision with wall
        LWI R5, #XPos
        MOVE (R5), R13        ; return to old X-pos.
        LWI R5, #YPos
        MOVE R10, R11         ; return to old Y-pos.
        LBI R9, #$01
        XOR R15, R9           ; reverse Y direction
        CALL Sound, R8

cnp4_3: MOVE (R5), R10


cnp5:   LWI R5, #Richt
        MOVE (R5), R15

        RET R2

; ********

Sound:
        LBI R9, #255
        CTRL $0, #$7E
snd1:   SUB R9, #1
        SZ R9
        BRA snd1
        CTRL $0, #$7D

        RET R8

; ********

Ende:
        ; restore processor status
        LWI R15, #Status_Save
        MOVE R1, (R15)
        MOVE $A4, R1

        ; select APL- or BASIC-ROS
        MOVE R8, $1F8
        LBI R2, #$20
        SNBC R8, R2
        CTRL $1, #$04        ; select APL-ROS


        MOVE R8, $1CE
        MOVE $D0, R8

        ; jump back to the interpreter
        MOVE R8, $CE
        DEC2 R8, R8
        JMP ($AC)

Ball:   dw $FD
Blank:  dw ' '
XPos:   dw 10
YPos:   dw 10
Richt:  dw $11


Status_Save:        dw 0

        end
