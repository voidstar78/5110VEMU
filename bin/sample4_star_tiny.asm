; For Vintage Computing Christmas Challenge 2022
; written by voidstar  12/18/2022
;
; assembled using Alfred Arnold Macro Assembler 1.42 Beta [Bld 231]
; asw -i ..\include sample3_star.asm
;
; remove header and convert .p to a raw binary:
; p2bin sample3_star.p
;
; demo using VEMU 5110 emulator:
; emu5110_release_x64 a -1 command_input_ASM_GO2000.txt sample3_star.bin
; NOTE: a (APL) or b (BASIC) will work at 0x2000 offset.  If using 0x0B00, sometimes BASIC
; won't work (it writes 0x0000 to 0xB2E0, depending on when and how long you let it run).
;
        cpu IBM5110

        include     "ebcdic.inc"
        intsyntax	  +$hex,-x'hex'  ; < support $-style hex instead of IBM 0x style
        codepage    cp037          ; < activate the EBCDIC mapping of chars
        
; BEGIN: CLEAR SCREEN
        LWI	        R14,  #$0200   ; set start of CRT screen address
        LWI         R9,   #$4040   ; let R9 be the space/blank screen character  (for IBM 5110 use $4040, for IBM 5100 use $0000)
cs_1:	
        MOVE        (R14)+, R9     ; move all of R9 to address of R14, then increment R14+2
        LBI         R1,   #$06     ; load Lo(R1) back to #$06 (can't guarantee R1 wasn't modified by interrupt)
        SBSH        R14,  R1       ; skip if Hi(R14) == R1 (i.e. have we reached #$0600, which is one past the memory-mapped screen addresses)
        BRA         cs_1           ; if did not skip, then keep clearing next two characters

; BEGIN: MAKE STAR
        ; prepare some registers to hold the screen character values that will be drawn
        LWI         R7, #$5C5C            ; draw "two" **'s at a time
        LWI         R8, #$5C40            ; left STAR then space/blank
        LWI         R9, #$405C            ; space/blank then RIGHT star

        MOVE        R11,  R0              ; R11 = R0  (store starting addressing)        
        
; do vertical lines first
; vertical 1
bw_v1:
        LWI         R5, #$0200+(1*64)+29  ; set R5 to address of row 1, col 29  (0-based index)
        LBI         R6, #14               ; 14 vertical rows to draw
bw_v1a:
        MOVE        (R5), R7              ; draw at whatever screen address that R5 is pointing at
        SUB         R6, #1                ; decrement "number of rows drawn" counter
        SNZ         R6                    ; skip if not-zero
        BRA         bw_v2                 ; go to the next block (if R6 is zero)
        ADD         R5, #64               ; increment screen address to the next row address (64 characters per row)
        BRA         bw_v1a                ; continue drawing vertically at the next row

; vertical 2
bw_v2:
        LWI         R5, #$0200+(3*64)+31  ; set R5 to address of row 3, col 31  (0-based index)
        LBI         R6, #10               ; 10 vertical rows to draw
bw_v2a:
        MOVE        (R5), R7
        SUB         R6, #1
        SNZ         R6                    ; skip if not-zero
        BRA         bw_v3                 ; go to the next block
        ADD         R5, #64               ; go to next row (address)
        BRA         bw_v2a

; vertical 3
bw_v3:
        LWI         R5, #$0200+(4*64)+33
        LBI         R6, #8
bw_v3a:
        MOVE        (R5), R7
        SUB         R6, #1
        SNZ         R6                    ; skip if not-zero
        BRA         bw_v4                 ; go to the next block
        ADD         R5, #64               ; go to next row (address)
        BRA         bw_v3a

; vertical 4
bw_v4:
        LWI         R5, #$0200+(2*64)+35
        LBI         R6, #12
bw_v4a:
        MOVE        (R5), R7
        SUB         R6, #1
        SNZ         R6                    ; skip if not-zero
        BRA         bw_v5                 ; go to the next block
        ADD         R5, #64               ; go to next row (address)
        BRA         bw_v4a

; vertical 5
bw_v5:
        LWI         R5, #$0200+(4*64)+37
        LBI         R6, #8
bw_v5a:
        MOVE        (R5), R7
        SUB         R6, #1
        SNZ         R6                    ; skip if not-zero
        BRA         bw_h1                 ; go to the next block
        ADD         R5, #64               ; go to next row (address)
        BRA         bw_v5a

; now draw the horizontals
; the vertical loops above has drawn the majority of the star.
; the following just adds in the few missing stars row-by-row as needed.
; (horizontals)
bw_h1:
; row 0: top left tip
        LWI         R5, #$0200+(0*64)+29
        MOVE        (R5),  R8
; row 0: top right tip
        LWI         R5, #$0200+(0*64)+37
        MOVE        (R5),  R8
; row 1: top right
        LWI         R5, #$0200+(1*64)+35
        MOVE        (R5)+, R9              ; "draw" and then increment R5 by two
        MOVE        (R5),  R8              ; "draw" the next pair 
; row 2
        LWI         R5, #$0200+(2*64)+31
        MOVE        (R5),  R8
        LWI         R5, #$0200+(2*64)+37
        MOVE        (R5),  R8
; row 3
        LWI         R5, #$0200+(3*64)+33
        MOVE        (R5),  R9
        LWI         R5, #$0200+(3*64)+37
        MOVE        (R5),  R8
; row 4: left side
        LWI         R5, #$0200+(4*64)+25
        MOVE        (R5)+, R7
        MOVE        (R5), R7
; row 4: right side   
        LWI         R5, #$0200+(4*64)+39
        MOVE        (R5)+, R7
        MOVE        (R5), R8
; row 5: left side
        LWI         R5, #$0200+(5*64)+25
        MOVE        (R5)+, R9
        MOVE        (R5), R7
; row 5: right side   
        LWI         R5, #$0200+(5*64)+39
        MOVE        (R5), R7
; row 6: left side
        LWI         R5, #$0200+(6*64)+27
        MOVE        (R5), R7
        ADD         R5, #64   ; row 7 left side
        MOVE        (R5), R9  ; row 8 left side
        ADD         R5, #64
        MOVE        (R5), R9
; row 6: right side   
        LWI         R5, #$0200+(6*64)+39
        MOVE        (R5), R8

; row 7 already handled inline above
; row 8 already handled inline above

; row 9: left side
        LWI         R5, #$0200+(9*64)+27
        MOVE        (R5), R7
; row 9: right side   
        LWI         R5, #$0200+(9*64)+39
        MOVE        (R5), R8

; row 10: left side
        LWI         R5, #$0200+(10*64)+25
        MOVE        (R5)+, R9
        MOVE        (R5), R7
; row 10: right side   
        LWI         R5, #$0200+(10*64)+39
        MOVE        (R5), R7

; row 11: left side
        LWI         R5, #$0200+(11*64)+25
        MOVE        (R5)+, R7
        MOVE        (R5), R7
; row 11: right side   
        LWI         R5, #$0200+(11*64)+39
        MOVE        (R5)+, R7
        MOVE        (R5), R8

; row 12
        LWI         R5, #$0200+(12*64)+33
        MOVE        (R5),  R9
        LWI         R5, #$0200+(12*64)+37
        MOVE        (R5),  R8

; row 13
        LWI         R5, #$0200+(13*64)+31
        MOVE        (R5),  R8
        LWI         R5, #$0200+(13*64)+37
        MOVE        (R5),  R8

; row 14: bottom right
        LWI         R5, #$0200+(14*64)+35
        MOVE        (R5)+, R9
        MOVE        (R5),  R8
        
; row 15: bottom left tip
        LWI         R5, #$0200+(15*64)+29
        MOVE        (R5),  R8
; row 15: bottom right tip
        LWI         R5, #$0200+(15*64)+37
        MOVE        (R5),  R8
        
; BEGIN: MAIN LOOP
        LWI         R13,   #$39      ; space bar
        LWI         R5,    #$69      ; can also use #$6B or #$B0
poll:
        MOVE        R12,   (R5)      ; let R12 = MEM[addr @ R5]
        SBS         R13,   R12       ; does R13 == R12 (key code for spacebar)        
        BRA         poll             ; no (not skipped), keep polling

; increment R7, R8, R9
;        MOVE        (R5),  R5        ; clear key stroke  (comment this out to loop continuously)
        
        ADD         R7,    #1        ; increment lo[R7]  (does carry, but doesn't matter since we do MLH below)
        MLH         R7,    R7        ; copy, hi[R7] = lo[R7]

        MLH         R8,    R7        ; copy, hi[R8] = lo[R7]  (update R8 to be whatever R7 became)   R8 == "xx40"

        ADD         R9,    #1        ; increment lo[R9]  (this does a carry which will "destroy" the space in hi[R9])
        MLH         R9,    R8
        
        MOVE        R0,    R11       ; restart the program
        
        HALT
