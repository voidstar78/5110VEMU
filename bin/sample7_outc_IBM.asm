; Sample assembly code for IBM 5110 using Alfred Arnold Macro Assembler AS
; -----------------------------------------------------------------------------
; voidstar - 2023  (contact.steve.usa@gmail.com)
;
; The IBM 5110 uses a processor known as "PALM": Put All Logic in Microcode
; This same processor is used in the IBM 5100/5110/5120 that were sold between
; 1975 to 1980.  The processor contains four sets of 16 registers. 
;
; There are four sets of registers to accommodate the four interrupt levels.
; The registers themselves are located on the processor card.  The interrupt
; levels are defined as follows: (each register is 16-bits)
; Level 0 is main processing
; Level 1 is BSCA/asynchronous communication
; Level 2 is tape, disk, printer, serial I/O
; Level 3 is keyboard processing (Common and Language ROS)
;
; The registers are designated R0 to R15.  R0 is used as an "instruction
; address" register (a.k.a. Program Counter).  Each remaining register can
; be used for general purpose.  However, R1 is reserved as a return/target
; address for when JUMP/SKIP instructions are used.
;
; NOTE: R10 = RA, R11 = RB, R12 = RC, R13 = RD, R14 = RE, R15 = RF
;
; The following example is intended as a "capability demonstration" of PALM
; and various nuances about its instruction set.
;
; NOTE: Example $xxFF is used where "xx" portion is unchanged or not-impacted.
; -----------------------------------------------------------------------------
        cpu         IBM5110

        include     "ebcdic_5110.inc"  ; or use ebcdic.inc
        intsyntax   +$hex,-x'hex'      ; support $-style hex (not IBM 0x style)
        codepage    cp037              ; activate the EBCDIC mapping of chars

; CONSTANTS
ADDR_SCREEN                            equ $0200
SCREENSIZE                             equ 16*64       ; default as decimal
SAMPLE1                                equ $BB         ; $ for hex
COL_PER_ROW                            equ 64
ADDR_RWS_KEY_INPUT                     equ $69  ; (can also use #$6B or #$B0)
KEY_W                                  equ $CD  ; move string1 UP
KEY_S                                  equ $CB  ; move string1 DOWN
KEY_A                                  equ $0B  ; move string1 LEFT
KEY_D                                  equ $AB  ; move string1 RIGHT
KEY_E                                  equ $AD  ; increment beep duration
KEY_Q                                  equ $0D  ; decrement beep duration

        ; The following code should be "relocatable" due to using relative
				; branching (not absolute-fixed addresses).  The first ORG decides
				; where it is expected that this code will be loaded into.  Specifying
				; this helps establish where any "db" "dw" reserved-data regions
				; will be located.
        ORG   $2000

        MVM1  R6, R6
        MVM1  R6, R6 
        
        ; In order to later determine if a key has been pressed, we need to
				; first set the "nominal conditions" that indicate that no key has
				; yet been pressed.  As a convention, R2 will be used as the register
				; to store the return address of CALL instructions.
        CALL  InitKey, R2

; -----------------------------------------------------------------------------
        ; The above initialization need only be done once.  When we "restart"
        ; the program later, this will be the designated starting point.				
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

        ; NOTE: If we wanted to use another local register instead of 
				; RWS/RAM main memory, we could do "INC2 R15, R0" instead.
				; This would set "R15 = R0+2" allowing R15 to be used as a future
				; return point.  The decision just depends on what we are about to do.
				
				; CALL ==> "INC2 Rx, R0" followed by "JMP (Rx)+"
				; JMP is opcode "D 0 Ry 1" which means to jump by setting R0 = Ry+2
				; i.e. JMP is a special form of "LWI R0, xxxx"
				; Rx should be left alone for the duration of the call.
				; If Rx must be used (such as to do another nested-call), then Rx 
				; must be buffered into memory and recalled prior to calling 
				; the "RET Rx"
				; (INC2 is used since all instructions are word-aligned)
				;
        CALL ClrScrA, R2   ; Call the (alternate and slower) Clear Screen
				                   ; Using R2 to hold the return register
        ; NOTE  "INC2 Rx, R0" increments the PC first before execution, 
				; which means that really Rx = R0+4 (e.g. 2008 becomes as 200C)
                           
        CALL ClrScr, R2    ; Call the fast Clear Screen

; -----------------------------------------------------------------------------
; Loading/initialization register values.

        ; The following section is no specific purpose, it is just
				; a sequence to step through and observe the changes made 
				; to the registers to understand the behavior of the instructions.
        EMIT   R2,  #'A'    ; LO(R2) = $xxC1 (only lower half is changed)
        EMIT   R3,  #'B'    ; LO(R3) = $xxC2 
        EMIT   R4,  #'C'    ; LO(R4) = $xxC3 
        EMIT   R5,  #$A     ; LO(R5) = $xx0A ("$A" same as "$0A")
        EMIT   R6,  #$B     ; LO(R6) = $xx0B (upper half not changed)
        EMIT   R7,  #$C     ; LO(R7) = $xx0C (upper half not changes)
        EMIT   R8,  #$FF    ; LO(R8) = $xxFF
        EMIT   R9,  SAMPLE1 ; LO(R9) = $xxBB (value-of, not address-of)
        EMIT   R9,  #$AA    ; LO(R9) = $xxAA
				
        LTH   R9,  R8      ; HI(R9) = LO(R8) --> R9 = $FFAA  
        ;^ The low of R8 is copied to high of R9.
													 
        EMIT   R10, #$BB    ; LO(R10) = $xxBB
        LWI   R11, #$40CC  ; R11     = $40CC (4-byte, load full word)

        EMIT   R12, #$A     ; LO(R12) = $xx0A (LBI will only use 2-bytes)
        EMIT   R12, #123    ; LO(R12) = $xx7B (123 decimal becomes $7B hex)
				
; -----------------------------------------------------------------------------
; Rotations, Shifts and Register Swap/Move
				
        SRR3  R12          ; LO(R12) = $xx6F  
				; ROR is a "pure rotation" of the bits, in-place and as-is
        ; ... 0111 1011 initial value (0x7B)
        ; ... 1011 1101 right rotation #1
        ; ... 1101 1110 right rotation #2
        ; ... 0110 1111 right rotation #3 == 6F

        ; SHR pads with "1" on the left
        SHFTR   R12          ; LO(R12) = $xxB7  1011 0111
        SHFTR   R12          ; LO(R12) = $xxDB  1101 1011  shifted right #1
        SHFTR   R12          ; LO(R12) = $xxED  1110 1101  shifted right #2
        SHFTR   R12          ; LO(R12) = $xxF6  1111 0110  shifted right #3
        SHFTR   R12          ; LO(R12) = $xxFB  1111 1011  shifted right #4

        ROTR   R12          ; LO(R12) = $xxFD  1111 1101  rotate right #1
        ROTR   R12          ; LO(R12) = $xxFE  1111 1110  rotate right #2
        ROTR   R12          ; LO(R12) = $xx7F  0111 1111  rotate right #3

        ; NOTE: There is no ROR2 (only ROR and ROR3)

        LTH   R12, R12     ; HI(R12) = LO(R12)
				;^ R12 lower half of "7F" is moved (copied) to upper half of R12.
				;                  ; R12 = F7F7

        ROTR   R12          ; LO(R12) right rotated once (R12 = F7BF)
                           ; ... 1111 0111  original          (xxF7)
                           ; ... 1111 1011  rotate right once (xxBF)
													 ;     ^pad

        SRR4  R12          ; LO(R12) = ..FB 
				                   ; ("swapped" lower half via rotate of 4)

        MOVE  R13, R12     ; R13 = R12 --> R13 = R12 = 7FFB
				                   ; (full word copy)

; -----------------------------------------------------------------------------
; Increment and basic logic operations

        MVP2  R12, R9      ; R12 = R9+2  (R12 = $FFAA + 2 = $FFAC)
				;^ Full word addition, note that entire value of R12 is overwritten.

        MVP1   R12, R9      ; R12 = R9+1  (R12 = $FFAA + 1 = $FFAB)
        SETI   R12, #$FF    ; LO(R12) = xxFF
        MVP1   R12, R12          ; R12 = $0000 (rollover of FFFF to 0000)
        LWI   R10, #9      ; R10 = $0009 (entire word is loaded)

        AND   R9,  R10     ; LO(R9) = LO(R9) & LO(R10) --> R9 = $FF80
				                   ;
                           ; LO(R9)  = FF|AA ..  1010 1010 (initial value)
                           ; LO(R10) = 00|09 ..  0000 1001 (initial value)
                           ;                 AND
                           ; LO(R9)  = FF|08 ..  0000 1000
													 ;           ^ HI portions not impacted

        SRR3  R9           ; LO(R9)  = FF|01 (rotate LO half right 3x times)
        OR    R11, R9      ; LO(R11) = LO(R11) | LO(R9) --> R11 = $40CD
				                   ;
                           ; LO(R11) = 40|CC .. 1100 1100 (initial value)
                           ; LO(R9)  = FF|08 .. 0000 0001 (initial value)
                           ;                 OR
                           ; LO(R11) = 40|CD .. 1100 1101
													 ;           ^ HI portions not impacted

        ADD   R9,  R10     ; LO(R9) = LO(R9) + LO(R10)  --> R9 = $FF0A
				; ADD will rollover to HI-portion if LO(Rx) is $FF
				
        HTL   R9,  R10     ; LO(R9) = HI(R10)           --> R9  = $FF00
        LTH   R10, R11     ; HI(R10) = LO(R11)          --> R10 = $CD09
        
; -----------------------------------------------------------------------------
; Interaction between RWS/RAM and registers (and SET/CLR logic)

        MOVE  R2,  #$0B00  ; Equivalent to LWI R2, #$0B00 (uses 4-bytes)

        MOVE  R3,  (R2)    ; R3 = RWS[R2]  (full word) --> R3 = $8C8C
        MOVE  (R2), R2     ; RWS[R2] = R2 = $0B00  (address $0B00 = $0B00)

        MOVB  (R2)+, R10   ; RWS[R2] = LO(R10)  --> RWS[R2] = $0900 
				                   ;   and then R2 = R2+1 = 0B01 (move to next byte)

        MOVB  (R2), R8     ; RWS[R2] = LO(R8)   --> RWS[R2] = $09FF

        MOVB  R4,  (R2)    ; R4 = RWS[R2] = $00FF
				                   ; !* possibly issue here *!

        SETI   R4,  #$55    ; LO(R4) = $00FF (R4 unchanged, remains $00FF)
				                   ; .. 1111 1111 ($  FF)
													 ; .. 0101 0101 ($  55)
													 ;     ^ ^  ^ ^ mask/flag to set on and they
													 ;              are already on, so no change
                           ; (set only sets the specified bits, does not clear)

        CLRI   R4,  #$55    ; LO(R4) = $00AA 
				                   ; .. 1111 1111 ($  FF)
													 ; .. 0101 0101 ($  55)
													 ;     ^ ^  ^ ^ mask/flag to clear...
													 ; .. 1010 1010 ($xxAA)
				                   ; (only 0101 0101 bits cleared, so 1010 1010 remains)

; -----------------------------------------------------------------------------
; Addition/subtraction (and rollover)

        ADD   R4,  #3      ; LO(R4) = LO(R4) + 3 = $xxAD
				                   ; (AA->AB->AC->AD but notice opcode is $A402)

        SUBI   R4,  #3      ; LO(R4) = LO(R4) - 3 = $xxAA
				                   ; (AD->AC->AB->AA but notice opcode is $F402)

        LTH   R4,  R4      ; HI(R4) = LO(R4) --> R4 = $AAAA
				                   ;                           ^ ^-LO
													 ;                           +---HI

        SUB   R4,  R4      ; LO(R4) = LO(R4) - LO(R4) = $AA00

        DEC   R2           ; R2 = R2 - 1 (step back from $0B01 to $0B00)

        LBI   R12, #$FF    ; LO(R12) = FF
        INC   R12          ; R12 rolls over from $00FF to $0100
        LBI   R12, 255     ; R12 = $01FF
        ADD   R12, #1      ; R12 rolls over from $01FF to $0200

        ; Intentional space, easy to spot.
				NOP
				NOP
				NOP
				NOP
				NOP
				NOP

; -----------------------------------------------------------------------------
; Loop demonstration

        LBI   R12, #3      ; R12 = $ xx03 (prepare to loop 3 times)
DEMO1:
        ; Copy full word value of R11 to three consecutive RWS/RAM addresses.
        MOVE  (R2)+, R11   ; RWS[R2] = R11 ($40CD) --> R2 = R2 + 1 = 0B02
        DEC   R12          ; LO(R12) = LO(R12) - 1 (decrement loop counter)
        SZ    R12          ; SKIP IF LO(R12) IS ZERO  ("while R12 not zero")
        BRA   DEMO1        ; not skipped: repeat loop
				;SKIP: Program Counter implicitly skipped to here when R12 == 0

; -----------------------------------------------------------------------------
; Sub-function call examples (with inputs and outputs)

; SAMPLE #1
        ; R12  IN: Address containing ROW/COL to write the text string at
				; R5  OUT: Screen offset to print the start of the string at
				; R5 = ComputeRowCol(R12)
        LWI   R12, ADDR_SAMPLE_BYTES      ; HI is ROW, LO is COL
        CALL  ComputeRowCol, R2
; Alternative:
;        LWI   R5, $0200+(9*64+0)     ; R5 = static/fixed location to print at

        ; R5   IN: Address to draw the string at on the screen
        ; R6   IN: Address of the string to print (terminated with $FF)
				; PrintString(R5, R6)
        LWI   R6, SAMPLE_STRING1     ; R6 = address of string to print
        CALL  PrintString, R2        ; R5 is location to print at

; SAMPLE #2
				; R5 = ComputeRowCol(R12)
        LWI   R12, (ADDR_SAMPLE_BYTES+2)  ; HI is ROW, LO is COL
				;                            ^ +2 to get next word address
				;                              could define its own label instead
        CALL  ComputeRowCol, R2
; Alternative:
;        LWI   R5, $0200+(12*64+10)   ; R5 = static/fixed location to print at

				; PrintString(R5, R6)
        LWI   R6, SAMPLE_STRING2     ; R6 = address of string to print
        CALL  PrintString, R2        ; R5 is location to print at

; -----------------------------------------------------------------------------
; Excursion: INC/ADD rollover

        LWI   R6, #$FEFF   ; R6 = $FEFF  (FE / FF)
        INC   R6           ; R6 = $FF00

        LWI   R6, #$FEFF   ; (reset R6 back to $FEFF)
        MLH   R5, R6       ; HI(R5) = LO(R6) --> R5 = $FFxx   [!double check!]
                           ;	("copy the LO byte of R6 to the HI byte of R5")

        ADD   R6, #1       ; R6 = $FF00

; -----------------------------------------------------------------------------
; Demonstrate a 32-bit counter

; A incremental count across R5 and R6 will be coordinated, which represents
; using these two registers as a 32-bit counter.
;
; [ R5 MSB | R6 LSB ]

        MOVE  R5,  $A0     ; RWS[A0] is know to be initialized to 00
				                   ; during powerup of system.  
													 ; Move (copy) the entire address at $A) to R5
													 ; R5 = $0000

        MOVE  R6,  R5      ; Clear also R6 to a known initial value (R6 = R5)

				; There are other ways to clear/zeroize a registers. The above shows
				; the concept of using RWS to reserve/park commonly used values.

        ; The following shows how we can use the assembler syntax to more
				; easily define initial values using symbolic labels.

				; Because the "hard part" of a 32-bit counter is the roll over from
				; 16-bit, we'll start the initial value closer to $0000 FFFF.
        LWI   R6,  #ADDR_START_LOW   ; R6 = address value that we will load
        MOVE  R6,  (R6)              ; R6 = RWS[R6]
				; could use (ADDR_START_HIGH+2) instead

        LWI   R5,  #ADDR_START_HIGH  ; R5 = address value that we will load
        MOVE  R5,  (R5)              ; R5 = RWS[R5]

        ; Start of 32-bit counter, using R5 and R6
DO_INCREMENT:
				; R11 = CheckKey((R8)
        CALL  CheckKey, R2 ; Check for a key press to restart the counter
        SZ    R11          ; IF (R11 == 0) THEN SKIP NEXT INSTRUCTION
        BRA   NextStage    ;   GOTO NextStage  (i.e. a key was pressed)
                           ; SKIP TO HERE...
        ADD   R6,  #1      ;   R6 = R6 + 1
        SZ    R6           ;   Did LO(R6) roll over to 0? ("skip if zero")
        BRA   DO_INCREMENT ;     Not zero - continue to increment
				                   ;   SKIP TO HERE...
        MHL   R7,  R6      ;     LO(R7) = HI(R6)
                           ; (test if R6=$00xx, using LO R7 as a scratch area)
													 ; (scratch area needed to avoid corrupting R6)
        OR    R7,  R6      ;   LO(R7) = LO(R7) | LO(R6) (are both zero?)
        SNZ   R7           ;   If LO(R7) [aka HI(R6)] is zero...
        ADD   R5,  #1      ;     THEN: R5=R5+1 (MSB increase by one)
        BRA   DO_INCREMENT ;     ELSE: Continue incrementing

; -----------------------------------------------------------------------------
; Putting it all together, a simple fun application:  We examine what key has
; been pressed and use certain keys to relocate (move) a string on the screen.
;
NextStage:

;        LWI   R0, #$3000
;        ORG   $3000
; The above is a reminder of how a different section of code can be placed
; somewhere else in memory.  Doing so can give easier to observe debug points.
; e.g. typically data regions are placed significantly away from the code 
; regions, so that they stand out better.

        ; Increment counter that records number of key presses.
				; No specific purpose, just an example of how to do so.
        LWI   R12, (ADDR_SAMPLE_BYTES+4)  ; +4 to use the "next word"
        MOVE  R11, (R12)             ; R11 = RWS[R12]
        INC   R11                    ; R11 = R11 + 1
        MOVE  (R12), R11             ; RWS[R12] = R11

; This label is not used explicitly, but helps indicate the
; starting point of examing for key presses.
CHECK_UP:  ; Key code processing for "W" (up)

        LBI   R9,  KEY_W        ; R9 = kbd scan code for 'W'
        SUB   R9,  R8           ; R9 = R9 - R8
                                ; Way earlier in CheckKey was called, register
                                ; R8 was set as a copy of the pressed key.  As
                                ; long as R8 hasn't been modified since then, 
                                ; we can continue to reference that value.

                                ; (if R9 == 0 then the key pressed is 'W')
        SZ    R9                ; SKIP if LO(R9) = xx00
        BRA   CHECK_DOWN  ; Did not press W, check next key...

        ; Pressed W: Decrease COLUMN of first SAMPLE_BYTES
        LWI   R12, ADDR_SAMPLE_BYTES  ; ROW_COL data for first string
        MOVE  R11, (R12)         ; R11 = RWS[R12]     READ RWS
        MHL   R15, R11           ; LO(R15) = HI(R11)  [scratch area]

        DEC   R15                ; R15 = R15 - 1
                                 ; We can't subtract the HI portion of a
                                 ; register directly, so we have to copy the
                                 ; HI portion to the LO half of another
                                 ; register.
                                 
        MLH   R11, R15           ; HI(R11) = LO(R15)  [put it back...]
        MOVE  (R12), R11         ; RWS[R12] = R11     WRITE RWS

        BRA   nextStage_cont ; done examining keys, resume program

CHECK_DOWN:  ; Key code processing for "S" (down)

        LBI   R9,  KEY_S         ; The notes here are same as 'W' case above.
        SUB   R9,  R8
        SZ    R9
        BRA   CHECK_LEFT  ; Did not press S, check next key...

        ; Pressed S: Increase COLUMN of first SAMPLE_BYTES
        LWI   R12, ADDR_SAMPLE_BYTES  ; ROW_COL data for first string
        MOVE  R11, (R12)
        MHL   R15, R11           ; LO(R15) = HI(R11)
        INC   R15
        MLH   R11, R15
        MOVE  (R12), R11
        BRA   nextStage_cont

CHECK_LEFT:  ; Key code processing for "A" (left)

        LBI   R9,  KEY_A         ; The notes here are same as 'W' case above.
        SUB   R9,  R8
        SZ    R9
        BRA   CHECK_RIGHT

        ; Pressed A: Decrease ROW of first SAMPLE_BYTES
        LWI   R12, ADDR_SAMPLE_BYTES  ; ROW_COL data for first string
        MOVE  R11, (R12)
        DEC   R11
        MOVE  (R12), R11
        BRA   nextStage_cont

CHECK_RIGHT:  ; Key code processing for "D" (right)

        LBI   R9,  KEY_D         ; The notes here are same as 'W' case above.
        SUB   R9,  R8
        SZ    R9
        BRA   CHECK_DURATION_UP

        ; Increase ROW of first SAMPLE_BYTES
        LWI   R12, ADDR_SAMPLE_BYTES  ; ROW_COL data for first string
        MOVE  R11, (R12)
        INC   R11
        MOVE  (R12), R11
        BRA   nextStage_cont
        
CHECK_DURATION_UP:  ; Key code processing for "E"

        LBI   R9,  KEY_E
        SUB   R9,  R8
        SZ    R9
        BRA   CHECK_DURATION_DOWN

        ; Increase beep duration
        LWI   R12, ADDR_BEEP_DURATION
        MOVE  R11, (R12)
        LBI   R13, #10
        ADD   R11, R13    ; R11 = R11 + R13 (increase by 10)
        MOVE  (R12), R11
        BRA   nextStage_cont

CHECK_DURATION_DOWN:  ; Key code processing for "Q"

        LBI   R9,  KEY_Q
        SUB   R9,  R8
        SZ    R9
        BRA   CHECK_CASE_NOA

        ; Decrease beep duration
        LWI   R12, ADDR_BEEP_DURATION
        MOVE  R11, (R12)
        LBI   R13, #10
        SUB   R11, R13    ; R11 = R11 - R13 (decrease by 10)
        MOVE  (R12), R11
        BRA   nextStage_cont

; -----------------------------------------------------------------------------
CHECK_CASE_NOA:  ; Default "none-of-above" case (if no valid key pressed)
        NOP   ; Not necessary, just left as a placeholder.
              ; Hadn't used NOP anywhere else, so just example of doing so.

; The following is only performed when an "invalid" key has been pressed.
MAKE_NOISE:   
        ; Do an audio beep when an invalid key is pressed.
        LWI   R9,  ADDR_BEEP_DURATION
        MOVE  R9,  (R9)  ; Set audio duration counter ( R9=RWS[R9] )
        CTRL  $0,  #$7E  ; Alarm on
mn1:
        DEC   R9         ; R6 = R6 -1 --> decrease the duration counter
        MHL   R8,  R9    ; LO[R8] = HI[R9]
                         ; (we have to copy this since "SZ" below only works
                         ; on LO half of the word)
        OR    R8,  R9    ; LO[R8] = LO[R8] | LO[R9]   
                         ; (is both the HIGH and LOW portion of R6 zero?)
        SZ    R8         ; Skip if LO[R8] is zero: have we reached zero yet?
        BRA   mn1        ; No, repeat "busy-wait" duration loop
        CTRL  $0,  #$7D  ; Alarm off

; -----------------------------------------------------------------------------
nextStage_cont:
        ; The following is "busy work" just to intentionally consume 
				; code space.   Each of the following is 4-bytes.  Use this to 
				; quickly make a section that is more than 256 bytes of code.
        LWI   R2,  #$AAAA
        LWI   R3,  #$BBBB
        LWI   R4,  #$CCCC
        LWI   R5,  #$DDDD
        LWI   R6,  #$EEEE
        LWI   R7,  #$FFFF
        LWI   R8,  #$0000
        LWI   R9,  #$1111
        LWI   R10, #$2222
        LWI   R11, #$3333
        LWI   R12, #$4444
        LWI   R13, #$5555
        LWI   R14, #$6666
        LWI   R15, #$7777
        LWI   R2,  #$AAAA
        LWI   R3,  #$BBBB
        LWI   R4,  #$CCCC
        LWI   R5,  #$DDDD
        LWI   R6,  #$EEEE
        LWI   R7,  #$FFFF
        LWI   R8,  #$0000
        LWI   R9,  #$1111
        LWI   R10, #$2222
        LWI   R11, #$3333
        LWI   R12, #$4444

;        BRA   STARTOVER  ; This fails because "distance too far" 
                          ; (beyond 256 bytes)
              
        ; To workaround the above, we have to had previously 
				; stored the desired return point.  We did this earlier by saving
				; the PC (program counter) into main memory (RWS)
        ; so we can reload that address value from memory, 
				; and set the PC to that value to a "long distance"
				; (full word) address location.
        LWI   R15, CALL_STACK_START  ; R15 address of the call stack
        MOVE  R0,  (R15)             ; R0 = RWS[R15]

        HALT

; -----------------------------------------------------------------------------

; *****************************
; ClrScr version A  (this is the ALTERNATE version which is slower)
ClrScrA:  
        LWI   R5,  #ADDR_SCREEN  ; R5 = addrss of text screen memory map
        LWI   R6,  #SCREENSIZE   ; R6 = number of bytes to write (64*16=1024)
;        LBI   R7, #$40    ; 0x40 is SPACE on IBM 5110
        LBI   R7,  #'*'   ; Can use ' ' or '*' etc. (assembler converts)
cs_1:   MOVB  (R5)+, R7   ; RWS[R5] = R7 (clear), then increment the
                          ;   address pointed to by R5 (R5 = R5+1)
        DEC   R6          ; R6 = R6 -  1 --> Decrease the number of SPACE
                          ;   character remaining that we need to write

        MHL   R8,  R6     ; LO[R8] = HI[R6]            
                          ; (we have to copy this since "SZ" below only
                          ; works on LO half of the word)

        OR    R8,  R6     ; LO[R8] = LO[R8] | LO[R6]   
                          ; (is both the HIGH and LOW portion of R6 zero?)
        SZ    R8          ; Skip if LO[R8] is zero: have we reached zero yet?
        BRA   cs_1        ; no, keep writing SPACE to the next address
        RET   R2          ; return using the agreed upon return register
                          ; for this function
; *****************************
; *****************************
; ClrScr
ClrScr:
        LWI   R14, #ADDR_SCREEN   ; R14 used as the screen offset
        LWI   R9,  #".,"    ; R9 full word is used as screen code that is
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
; R12 is the address of the coordinates (HI=ROW, LO=COL) to be computed
; into a linear address (result stored in into R5).
ComputeRowCol:
        MOVE  R13, (R12)    ; R13 = RWS[R12]
        MHL   R11, R13      ; LO(R11) = HI(R13) 
        LWI   R5,  #$0200   ; CRT memory mapped output starts at address $0200
        LBI   R4,  #COL_PER_ROW
ComputeRowCol_again:
        SZ    R11
        BRA   nextRow
        BRA   nextStage_addCol
nextRow:
        DEC   R11
        ADD   R5, R4        ; add 64 (full row)
        BRA   ComputeRowCol_again
nextStage_addCol:
        ADD   R5, R13       ; 
        RET   R2
; *************************
; *************************
InitKey:
        LWI   R11, ADDR_RWS_KEY_INPUT  ; R11 = value of the ADDR_RWS_KEY_INPUT
        MOVE  R11, (R11)           ; R11 = RWS[R11] = last reported key press
        
        LWI   R13, ADDR_LAST_KEY   ; R13 = value of ADDR_LAST_KEY address
                                   ; (our programs copy of it)
        MOVE  (R13), R11   ; RWS[R13] = R11
                           ; Store this key as the initial "baseline" to
                           ; establish that no key has currently been pressed
                           ; (relative to the start of the program)
                           ; NOTE: This writes the full word (16-bit), 
                           ;   the ADDR_RWS_KEY_INPUT is in the byte at the low 
                           ;   portion (ADDR_LAST_KEY+1)
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

        LBI   R11,  #$01  ; Return R11 = 1 (flag indicating a key was pressed)
        RET   R2
; *************************
; *************************        
; Print the string pointed to in R6 into the address pointed by R5
PrintString: 
        MOVB  R7, (R6)+     ; R7 = RWS[R6], R6 = R6+1
        SNS   R7            ; Skip if not all set (i.e. 0xFF)
        RET   R2            ; Return from subroutine 
        MOVB  (R5)+, R7     ; RWS[R5] = R7, R5 = R5+1
                            ; The above prints the string starting at the
                            ; address offset indicated in R5.  R5 is
                            ; "destructively incremented" to the next
                            ; screen address after each prior part of the
                            ; string is written.  That is, the original
                            ; starting value of R5 will be lost.
        BRA   PrintString
; *************************        

; -----------------------------------------------------------------------------        
; Reserved Data Locations
ADDR_START_HIGH:
        dw    $FFFE
ADDR_START_LOW:
        dw    $FFFA
ADDR_BEEP_DURATION:
        dw    $00FF
        
ADDR_LAST_KEY:
        dw    $0000
        dw    $0000   ; copy
        
ADDR_SAMPLE_BYTES:
; used for location of string1
        db    9    ; row string1
        db    3    ; col
; used for location of string2    (this is @ ADDR_SAMPLE_BYTES+2)
        db    $C   ; row string2
        db    $A   ; col
; used for main loop counter      (this is @ ADDR_SAMPLE_BYTES+4)
        dw    $0000

CALL_STACK_START:
        dw    $1000 ; This is an address of where the call stack starts.
                    ; This is an incomplete implementation, as the call stack
                    ; depth is not maintained.
; -----------------------------------------------------------------------------
SAMPLE_STRING1:
; NOTE: The IBM 5100 system has a dilema because its "display code" for SPACE
; is the value 0.  In contrast, the IBM 5110 uses "display code" value of 64.
; This makes it difficult to implement the idea of null-terminated (C-style)
; strings for the IBM 5100, since very likely a string is going to
; contain spaces.  This is why, as a compromise, the example below is using
; "$FF"-terminated strings (as a choice that can work across both 5100/5110).
;
;                       1         2         3         4         5         6
;              1234567890123456789012345678901234567890123456789012345678901234
        db    "The One who comes after me is greater than I am!", $FF
SAMPLE_STRING2:
        db    "ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz "
        db    "0123456789 !@#$%^&*()-+[]{}:;\"'<>?/\\A|~`_=", $FF
;                              ?        ??  x      x     

        HALT  ; This shouldn't get reached - but just in case...
