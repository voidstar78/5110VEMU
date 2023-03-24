; Sample assembly code for IBM 5110 using Alfred Arnold Macro Assembler AS
; -----------------------------------------------------------------------------
; voidstar - 2023  (contact.steve.usa@gmail.com)
;
; The following example is intended as a "capability demonstration" of the
; PALM instruction set and IBM 5100/5110/5120 systems.
;
; The registers are designated R0 to R15.  R0 is the Program Counter.
; R1 is adjusted as the return address of SKIP/JUMP instructions.
;
; NOTE: R10 = RA, R11 = RB, R12 = RC, R13 = RD, R14 = RE, R15 = RF
; Each register has a "HI" (high) and "LO" (low) portion.
; Rx = HILO (HI is upper 8-bits, LO is lower 8-bits)
;
; NOTE: Example $xxFF is used where "xx" portion is unchanged or not-impacted.
; -----------------------------------------------------------------------------
				cpu         IBM5110

        include     "ebcdic_5110.inc"  ; or use ebcdic.inc
        intsyntax	  +$hex,-x'hex'      ; support $-style hex (not IBM 0x style)
        codepage    cp037              ; activate a string mapping of chars

;--- CONSTANTS ----------------------------------------------------------------
SCREENSIZE                             equ 16*64       ; static computed
COL_PER_ROW                            equ 64
ROW_PER_COL                            equ 16
DURATION_STEP                          equ $01    ; during E and Q, incr. step
INITIAL_32BIT_COUNTER_HIGH             equ $FFFE
INITIAL_32BIT_COUNTER_LOW              equ $FFFA
NULL_TERM                              equ $FF   ; used at end of strings

SAMPLE1                                equ $BB   ; example of expressing hex

ADDR_SCREEN                            equ $0200 ; Address of CRT display
ADDR_RWS_KEY_INPUT                     equ $69   ; Possibly also $6B or $B0

; Keyboard "scan codes" for IBM 5110
KEY_A  equ  $0B  ;38    move string1 LEFT
KEY_B  equ  $9D  ;56
KEY_C  equ  $B9  ;54
KEY_D  equ  $AB  ;40    move string1 RIGHT
KEY_E  equ  $AD  ;26    increment beep duration
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
KEY_Q  equ  $0D  ;24    decrement beep duration
KEY_R  equ  $2D  ;27
KEY_S  equ  $CB  ;39    move string1 DOWN
KEY_T  equ  $ED  ;28
KEY_U  equ  $7D  ;30
KEY_V  equ  $29  ;55
KEY_W  equ  $CD  ;25    move string1 UP
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

        ; The following code should be "relocatable" due to using relative
				; branching (not absolute-fixed addresses).  The first ORG decides
				; where it is expected that this code will be loaded into.  Specifying
				; this helps establish where any "db" "dw" reserved-data regions
				; will be located.
        ORG   $2000
        
; -----------------------------------------------------------------------------
; Initial example exercise.  This section isn't critical to the remainder.
; It is a placeholder to "experiment" upfront in the emulator debugger.        
again:
        MOVE $A2, R15
        MOVE R15, $A0     ; R15 = RWS[A0] = xx00
        LBI R15, #$14     ; R15 =         = xx14 
        LBI R10, #$0B     ; R10 =         = xx0B
        MLH R10, R10      ; R10 =         = 0B0B
        LBI R10, #$F6     ; R10 =         = 0BF6
        CTRL $4, #$43
        CTRL $1, #$02
        PUTB $1, (R15)+
        PUTB $1, (R15)
        
        NOP
        NOP
;        BRA test1		; -> -$01(R0)
;test1:
        GETB R11, $1
        MLH R11, R11
        NOP
        GETB R11, $1
        MOVE $1FA, R11
        
        BRA  again
        RET R4

        
        
; -----------------------------------------------------------------------------

        ; The above initialization need only be done once.

        ; When we "restart" the program later, the following will be 
        ; the designated starting point.				
STARTOVER:

        ; First save the current Program Counter (R0) into memory (to use as
				; "long range" return point in future).
				; NOTE: LWI is 4-bytes - 2 bytes code followed by 2 byte address data
        LWI   R15, CALL_STACK_START   ; R15 = value of CALL_STACK_START (addr)				
        MOVE  (R15), R0    ; RWS[R15] = R0 (store the entire word)
        ; NOTE: R0 is incremented by 2 before this MOVE/STORE is executed.
        ; We then use this to return the point after this MOVE (rather than
				; returning and repeating this MOVE)
				
				; The above is an example start of what could become a call stack.
				; CALL_STACK_START would represent the starting address of such a
				; stack,


        HALT

; -----------------------------------------------------------------------------

; *****************************
; *****************************
; ClrScr
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
; *************************        
CALL_STACK_START:
        dw    $1000 ; This is an address of where the call stack starts.
                    ; This is an incomplete implementation, as the call stack
                    ; depth is not maintained.

        NOP
        NOP
        NOP

        HALT  ; This shouldn't get reached - but just in case...

; Tempus edax rerum,
; El Psy Kongroo