		cpu         IBM5110

        include     "ebcdic_5110.inc"  ; or use ebcdic.inc
        intsyntax	+$hex,-x'hex'      ; support $-style hex (not IBM 0x style)
        codepage    cp037              ; activate a string mapping of chars


SCREENSIZE                             equ 16*64       ; static computed
COL_PER_ROW                            equ 64
ROW_PER_COL                            equ 16
NULL_TERM                              equ $FF   ; used at end of strings
ADDR_SCREEN                            equ $0200 ; Address of CRT display
ADDR_RWS_KEY_INPUT                     equ $69   ; Possibly also $6B or $B0
SCRPOS function xpos,ypos,$0200+xpos+ypos*64


; Keyboard "scan codes" for IBM 5110
KEY_A  equ  $0B  ;38
KEY_B  equ  $9D  ;56
KEY_C  equ  $B9  ;54
KEY_D  equ  $AB  ;40
KEY_E  equ  $AD  ;26
KEY_F  equ  $2B  ;41
KEY_G  equ  $EB  ;42
KEY_H  equ  $6B  ;43
KEY_I  equ  $FD  ;31
KEY_J  equ  $7B  ;44
KEY_K  equ  $FB  ;45
KEY_L  equ  $8B  ;46
KEY_M  equ  $79  ;58
KEY_N  equ  $69  ;57
KEY_O  equ  $8D  ;32
KEY_P  equ  $3D  ;33
KEY_Q  equ  $0D  ;24
KEY_R  equ  $2D  ;27
KEY_S  equ  $CB  ;39
KEY_T  equ  $ED  ;28
KEY_U  equ  $7D  ;30
KEY_V  equ  $29  ;55
KEY_W  equ  $CD  ;25
KEY_X  equ  $C9  ;53
KEY_Y  equ  $6D  ;29
KEY_Z  equ  $F9  ;52
  
KEY_0  equ  $8F  ;19
KEY_1  equ  $4D  ;10
KEY_2  equ  $0F  ;11
KEY_3  equ  $CF  ;12
KEY_4  equ  $AF  ;13
KEY_5  equ  $2F  ;14
KEY_6  equ  $EF  ;15
KEY_7  equ  $6F  ;16
KEY_8  equ  $7F  ;17
KEY_9  equ  $FF  ;18

        ORG   $2000
		
		CALL  ClrScr, R2
		
		LWI   R5, #SCRPOS(1,5)
		LWI   R6, PROMPT_STRING1
		CALL  ComputeRowCol, R2
		
		LWI   R5, #SCRPOS(1,6)
		LWI   R6, $1000
		LWI   R7, 60
		CALL  PromptStringInput, R2
		
PromptStringInput:

        CALL  CheckKey, R2 ; Check for a key press to restart the counter
        SZ    R11          ; IF (R11 == 0) THEN SKIP NEXT INSTRUCTION
        BRA   NextStage    ;   GOTO NextStage  (i.e. a key was pressed)


        RET   R2


ClrScr:
        LWI   R14, #ADDR_SCREEN   ; R14 used as the screen offset
        LWI   R9,  #"  "    ; R9 full word is used as screen code that is
                            ;   to be written (e.g. double space: "  ")
 		LBI   R3,  #$06     ; LO[R3] = $06 (checking to see if our address
                            ;   pointer has reached $0600 yet)
cs_2:   MOVE  (R14)+, R9    ; RWS[R14] = R9, then R14 = R14 + 2 (next addr)
                            ;   (^ this does the actual drawing)
 		SBSH  R14, R3       ; Have we reached $0600 yet? 
                            ;   (one past end of screen)
                            ; Skip if all set bits in R3 are also set 
                            ;   in HI(R14)
                            ; (note the above SBSH will set R1 = R0+4 -- this
                            ; is in case the code after the jump goes to a
                            ; subroutine -- as documented in IBM 5100 
                            ; MIM Appendix C-16)
 		BRA   cs_2
        RET   R2
		
; *************************
; R8  OUT: Copy of the pressed key.
; R11 OUT: LO(R11) == 0 if no key pressed, else LO(R11) == 1 if key pressed
CheckKey:
        LWI   R11, ADDR_RWS_KEY_INPUT  ; R11 = value of ADDR_RWS_KEY_INPUT
        MOVE  R14, (R11)      ; R14 = RWS[R11]
                              ; (capture last reported key press)

        ; Make two copies of the current last key pressed...
        MOVE  R8,  R14        ; R8 = R14 (make copy)

        LWI   R13, (ADDR_LAST_KEY+2)   ; R13 = extra copy of last key
        MOVE  (R13), R14          ; RWS[R13] = R14 (store the copy)
        ; This is done because when a key press does end up detected, 
        ;   ADDR_LAST_KEY will get reset.  In case the R8 register copy
        ;   gets overwrite, we still have an extra copy of the last 
        ;   if it is needed.

        LWI   R13, ADDR_LAST_KEY  ; R13 = address of last key (copy)
        MOVE  R12, (R13)          ; R12 = RWS[R13]
        
        SUB   R14, R12       ; R14 = R14 - R12  (if same, result is 0)
        SZ    R14            ; does R11 == R12?         
        BRA   StoreKey    ; <-- no, new key detected, go store it...
        LBI   R11, #$00   ; <-- yes, no new key, return R11 = 0
        RET   R2
        
StoreKey:
        LBI   R10, #$00     ; We can't write directly to memory from an opcode
                            ; We have to go through a register that has the
                            ; value we want to write.

        MOVB  (R11), R10    ; RWS[R11] = R10 (0) (R11 is ADDR_RWS_KEY_INPUT)
        MOVE  (R13), R10    ; RWS[R13] = R10 (0) (R13 is ADDR_LAST_KEY)
        ; The above is done to zeroize the key reference. That is, to set a
        ;   "baseline" state that indicates that "relative to the last time
        ;   we checked, no new key has been pressed."  This is similar to 
        ;   calling InitKey again, except that we're not setup to do
        ;   nested calls.
        ; NOTE: The key that was last pressed is preserved in R8 or
        ; in memory (the second "backup" copy at ADDR_LAST_KEY+2)

        LBI   R11, #$01  ; Return R11 = 1 (flag indicating a key was pressed)
        RET   R2
; *************************
; *************************	
		
PROMPT_STRING:
        db    "BANNER:", NULL_TERM
		