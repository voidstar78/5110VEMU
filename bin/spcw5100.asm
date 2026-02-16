;; IBM 5110 PALM
;
; *************
; * SPACE WAR *
; *************
;
; Ported from IBM 5100 to IBM 5110 by Christian Corti (03.2024)
;
	cpu		IBM5100
	intsyntax	+$hex,-x'hex'
	include		"ebcdic.inc"
	codepage        cp5110
	dottedstructs	on

IBM5110		equ	0		; 0 for IBM 5100, 1 for IBM 5110/5120
AUXIPL		equ	0		; set to 1 if to be loaded by AUX IPL


KEY_1		equ	$4D
KEY_Q		equ	$4F
KEY_W	 	equ	$4C
KEY_E		equ	$4A
KEY_R		equ	$4B
KEY_A		equ	$2F
KEY_S		equ	$2C
KEY_D		equ	$2A
KEY_F		equ	$2B
KEY_X		equ	$6C
KEY_C		equ	$6A
KEY_V		equ	$6B
KEY_KP3		equ	$27
KEY_KP6		equ	$47
KEY_KP9		equ	$07
KEY_DN		equ	$0D
KEY_KP2		equ	$64
KEY_KP5		equ	$24
KEY_KP8		equ	$44
KEY_UP		equ	$04
KEY_KP1		equ	$25
KEY_KPMUL	equ	$46
KEY_KPDIV	equ	$06
KEY_HOLD	equ	$93
KEY_CMD_EXEC	equ	$B6

CH_CIRCBIG	equ	$3B
CH_CIRCSMALL	equ	$36
CH_CIRCPLUS	equ	$5C



; -----------------------------------------------------------

R0L0	equ	$00
R7L0	equ	$0E
R0L3	equ	$60


; -----------------------------------------------------------

SCRPOS function xpos,ypos,$0200+xpos+ypos*64

; FLAGS (common to ships and bombs)
;	all bits = 0: inactive
;	bit 0 = 1: (active?)
;	bit 1 = 1: ship stopped
;	bit 2 = 1: phaser active
;	bit 3 = 1: turn phaser off
;	bit 4 = 1: ship is invisible
;	bit 5 = 1: collision
;	bit 6 = 1: switching ship
;	bit 7 = 1: detonate

SHIP struct
FLAGS		db ?	; flags, see above
CHAR		db ?	; character for ship or bomb
SHIPPOS		dw ?	; screen address of ship or bomb
DIR		db ?	; direction of movement
SHOT_LEN	db ?	; current length of shot (e.g. phaser)
POWER		dw ?	; remaining power
ROT		db ?	; turn ship cw(>0) or ccw(<0) ROT times
GUN_ORI		db ?	; orientation of gun (position next to ship)
MIRV		dw ?	; pointer to fired bomb object
GUN_POS		dw ?	; screen address of gun
PH_POS		dw ?	; screen address of last phaser char
SHIP endstruct

; FLAGS:
;	bit 0 = 1: active
;	bit 5 = 1: has detonated
;	bit 6 = 1: newly created object
;	bit 7 = 1: detonate
BOMB struct
FLAGS		db ?	; flags
CHAR		db ?	; screen character
POS		dw ?	; screen position
DIR		db ?	; flight direction
MAX		db ?	; max. flight distance
BOMB endstruct

_DORET_ macro reg
	LWI reg, #.ret+2
	MOVE (reg)+, R1
_DORET_ endm
	
; -----------------------------------------------------------

	org $2000		; address for UTIL MODE COM

START:
	CALL INIT, R1		; Initialize

MAIN:
	CALL MOVE_SHIPS, R1	; Ship movement
	CALL DELAY, R1		; Delay
	CALL DO_BOMBS, R1	; Bombs handling
	CALL PHASER_ON, R1	; Bit 2 handling
	CALL DELAY, R1		; Delay
	CALL PHASER_OFF, R1	; Bit 3 handling
	CALL DO_BOMBS, R1	; Bombs handling
	CALL DELAY, R1		; Delay
	CALL DO_BOMBS, R1	; Bombs handling

	BRA MAIN		; Loop

; ******************************

EXIT:	JMP ($EA)


; ******************************

; *****
; DELAY
; *****

DELAY:	
	MOVE R3, R1

	LBI R11, #$FF
	LWI R2, #$2FFF
-	SUB R2, #1
	SZ R2
	BRA -
	SBSH R2, R11
	BRA -

	RET R3

; ******************************

; **********
; INITIALIZE
; **********

INIT:
	_DORET_ R12

	; Clear screen and buffer

	; Screen
	LBI R12, #' '
	MLH R12, R12		; R12 = '  '
	LWI R4, #bomb_buffer	; object buffer
	LWI R2, #$0200		; start of screen
	MOVE (R2), R12		; clear first two chars
	MOVE (R4), R12		; clear first word in buffer

	INC2 R3, R2		; R3 = addr of next two chars
	LBI R12, #$00		; 256 words
-	MOVE R13, (R2)+		; R13 := current two chars
	MOVE (R3)+, R13		; copy to next two chars
	SUB R12, #$01		; decrement word counter
	SZ R12			; done?
	BRA -			; no, loop

	; second half of screen
	LBI R12, #$FF		; 255 words left
-	MOVE R13, (R2)+
	MOVE (R3)+, R13
	SUB R12, #$01		; decrement word counter
	SZ R12			; done?
	BRA -			; no, loop

 if 1
	; Clear words 2..257 of buffer
	INC2 R5, R4
	LBI R12, #$00
-	MOVE R13, (R4)+
	MOVE (R5)+, R13
	SUB R12, #$01
	SZ R12
	BRA -

	; rest of buffer (258..300)
	LBI R12, #43
-	MOVE R13, (R4)+
	MOVE (R5)+, R13
	SUB R12, #$01
	SZ R12
	BRA -
 else
	INC2 R5, R4
 	LWI R12, #299
-	MOVE R13, (R4)+
	MOVE (R5)+, R13
	SUB R12, #1
	MHL R1, R12
	OR R1, R12
	SZ R1
	BRA -
 endif

	LBI R12, #$FF
	MLH R12, R12
	MOVE (R5), R12		; end of buffer marker

	LWI R2, #ship_buffer		; address of current objects
	LWI R3, #init_ships		; address of initial objects
	LBI R12, #(SHIP.LEN/2)*6+1	; 49 words, i.e. 6 objects plus end marker
-	MOVE R13, (R3)+
	MOVE (R2)+, R13
	SUB R12, #1
	SZ R12
	BRA -			; loop

	; draw initial ships

	LWI R2, #init_ships
-	INC R3, R2		; SHIP.CHAR
	INC2 R5, R2		; SHIP.SHIPPOS
	MOVE R5, (R5)		; get address
	MOVB R12, (R3)		; get character
	MOVB (R5), R12		; write character to screen
	ADD R2, #SHIP.LEN	; next entry
	MOVB R3, (R2)		; get ptr
	SS R3			; done?
	BRA -			; no, loop

	; print "IBM INTERNAL USE ONLY"

	LWI R3, #msg_ibm
	LWI R2, #SCRPOS(21,7)
	LBI R12, #11		; word count
-	MOVE R13, (R3)+
	MOVE (R2)+, R13
	SUB R12, #1
	SZ R12
	BRA -

	; print "PRESS ANY KEY TO START"

	LWI R2, #SCRPOS(21,9)
	LBI R12, #11
-	MOVE R13, (R3)+
	MOVE (R2)+, R13
	SUB R12, #1
	SZ R12
	BRA -

	LWI R2, #KBD_INT	; address of kbd int routine
	MOVE R0L3, R2		; set new kbd int
	MOVE R12, R12		; delay ?
	MOVE R12, R12		; delay ?
	CTRL $0, #$74		; display on

.ret:	JMP 0			; return address will be patched

; ******************************

MOVE_SHIPS:
	_DORET_	R12

	LWI R2, #ship_buffer
	MOVB R3, (R2)		; get flags

.loop:	SNZ R3			; flags zero?
	BRA .next		; yes, next entry

	LBI R12, #$0A
	SBC R3, R12		; bit 4 or 6 set?
	BRA +			; yes, skip

	; normal ship
	INC R4, R2		; SHIP.CHAR
	INC2 R5, R2		; SHIP.SHIPPOS
	MOVE R5, (R5)		; current screen address
	MOVB R12, (R4)		; get ship char
	MOVB R13, (R5)		; get screen char
	SNE R12, R13		; same?
	BRA +			; yes, ship still there

	; ship has been destroyed
	LBI R12, #$00		; clear flags (=remove ship)
	MOVB (R2), R12		; update entry
	BRA .next		; next entry
	; -----

	; has ship stopped?
+	LBI R13, #$40
	SBC R3, R13		; bit 1 set?
	BRA .next		; yes, next entry
	; -----

	; ship in movement
	MOVE R3, R2
	ADD R3, #SHIP.DIR	; direction

	MOVE R4, R2
	ADD R4, #SHIP.ROT	; rotation
	MOVB R13, (R4)
	SNZ R13
	BRA .rot_done

	; ship rotates
	LBI R12, #$7F
	SLT R12, R13
	BRA .rot_r

	; R13 >= 127
	; ship rotates left
	ADD R13, #1
	MOVB (R4), R13		; SHIP.ROT

	MOVB R13, (R3)		; SHIP.DIR
	SUB R13, #$01
	SNS R13
	LBI R13, #$07
	MOVB (R3), R13		; SHIP.DIR
	BRA .rot_done

	; R13 < 127
	; ship rotates right
.rot_r	SUB R13, #1
	MOVB (R4), R13		; SHIP.ROT

	MOVB R13, (R3)		; SHIP.DIR
	ADD R13, #$01
	LBI R12, #$07
	SLE R13, R12
	LBI R13, #$00
	MOVB (R3), R13		; SHIP.DIR

.rot_done
	LBI R7, #$01		; update gun
	LBI R12, #$0A
	MOVB R3, (R2)
	SBC R3, R12		; ship invisible or switching?
	BRA +			; yes, skip

	; clear gun
	MOVE R12, R2
	ADD R12, #SHIP.GUN_POS
	MOVE R5, (R12)
	LBI R12, #' '
	MOVB (R5), R12

+	CALL UPDATE_SHIP, R1	; process bits 4 and 6

.next	ADD R2, #SHIP.LEN	; next entry
	MOVB R3, (R2)		; get flags
	SS R3			; done?
	BRA .loop		; no, loop

.ret	JMP 0			; return address patched

; ******************************

; Handle all bomb objects

DO_BOMBS:
	_DORET_ R12

	LWI R2, #bomb_buffer
.loop	INC2 R4, R2		; BOMB.POS
	MOVE R5, (R4)		; screen position
	MOVB R3, (R2)		; BOMB.FLAGS
	SNZ R3
	BRA .next		; inactive -> next object

	LBI R13, #$04
	SBS R3, R13		; bit 5 set?
	BRA +			; no, skip

	; bomb has detonated
	LBI R12, #$00
	MOVB (R2), R12		; clear flags
	MOVB R12, (R5)		; get current char
	LBI R13, #'*'
	SE R12, R13		; equal to detonation character?
	BRA .next		; no -> done
	LBI R12, #' '
	MOVB (R5), R12		; clear it
	BRA .next		; done

+	LBI R13, #$01
	SBS R3, R13		; bit 7 set?
	BRA .continue		; no, skip

	; detonate bomb
	LBI R12, #$04		; set bit 5
	MOVB (R2), R12		; store new flags
	INC R3, R2		; BOMB.CHAR
	MOVB R12, (R5)		; get screen char
	MOVB R13, (R3)		; get bomb char
	SE R12, R13
	BRA .next		; not same, skip

	; put detonation char on screen
	LBI R12, #'*'
	MOVB (R5), R12		; put * on screen

	; check for bomb tyoe
	MOVB R12, (R3)		; new char
	LBI R13, #CH_CIRCSMALL
	SNE R12, R13		; is it "small circle" ° ?
	BRA .next		; yes, done

	LWI R15, #circle_big	; "big circle" table
	MOVB R12, (R3)		; new char
 	LBI R13, #CH_CIRCPLUS
	SNE R12, R13		; is it "o with plus" ?
	BRA +			; yes, use "big circle" table
	LWI R15, #circle_small	; no, use "small circle" table
+	CALL EXPLODE, R1	; update all objects
	BRA .next		; done

	; remaining flight distance was not zero
.continue
	MOVE R3, R2
	ADD R3, #BOMB.MAX
	LBI R4, #$01
	MOVB R6, (R3)
	SUB R6, #1		; decrement distance
	SNZ R6			; zero?
	MOVB (R2), R4		; yes, set flags bit 7
	MOVB (R3), R6		; store remaining distance
	LBI R7, #0
	CALL UPDATE_SHIP, R1

.next	ADD R2, #BOMB.LEN	; go to next object
	MOVB R3, (R2)		; get its flags
	SS R3			; end marker?
	BRA .loop		; no, do next object

.ret:	JMP 0			; return address patched

; ******************************

; Process objects with flag bit 2 set:
; Phaser shot

PHASER_ON:
	_DORET_ R12

.again	LWI R2, #ship_buffer
	LBI R7, #0		; only 1 iteration

	MOVB R3, (R2)		; get flags
.loop	LBI R12, #$20
	SBS R3, R12		; phaser active?
	BRA .next		; no, next object

	MOVE R3, R2
	ADD R3, #SHIP.GUN_POS
	MOVE R8, R2
	ADD R8, #SHIP.SHOT_LEN
	MOVE R9, R2
	ADD R9, #SHIP.GUN_ORI
	MOVE R6, R2
	ADD R6, #SHIP.PH_POS
	INC R4, R8		; SHIP.POWER

	MOVE R12, (R3)		; GUN_POS
	MOVE R5, (R6)		; PH_POS
	MHL R13, R5
	SNZ R13			; phaser already visible?
	MOVE R5, R12		; no, start at gun position
	MOVE R10, R5		; save last pos in R10

	LWI R12, #add_sub
	MOVB R13, (R9)		; orientation
	ADD R12, R13
	ADD R12, R13
	MOVE R13, (R12)
	MOVE (R0), R13
	SUB R5, #$01		; **patched**

	; new pos in R5
	; limit phaser to screen boundaries

	MHL R12, R5
	LBI R13, #$01
	SNE R12, R13		; < $0200 ?
	BRA .off		; yes, out of screen (above top)

	LBI R13, #$06
	SNE R12, R13		; >= $0600 ?
	BRA .off		; yes, out of screen (below bottom)

	LBI R13, #$3F
	SBS R10, R13		; old pos at right screen border?
	BRA +			; no
	SNBC R5, R13		; new pos at left screen border (i.e. wrapped)?
	BRA .off		; yes, out of screen

+	SBC R10, R13		; old pos at left screen border?
	BRA +			; no
	SNBS R5, R13		; new pos at right screen border (i.e. wrapped)?
	BRA .off		; yes, out of screen

	; ok, new position within screen boundaries

+	MOVB R12, (R5)		; get char from new position
	LBI R13, #' '
	SNE R12, R13		; was it blank?
	BRA .fire		; yes, all ok

	MOVB R12, (R5)		; get char from new position
	LBI R13, #'*'
	SNE R12, R13		; was it * ?
	BRA .fire		; yes, still ok

	MOVB R12, (R5)		; get char from new position
	LBI R13, #CH_CIRCSMALL
	SE R12, R13		; was it the small circle?
	BRA +			; no
	LBI R12, #' '
	MOVB (R5), R12		; clear new position
	BRA .off

+	LWI R15, #circle_small
	CALL EXPLODE, R1

.off	MOVB R3, (R2)		; get flags
	CLR R3, #$20		; clear bit 2
	SET R3, #$10		; set bit 3
	MOVB (R2), R3		; update flags
	BRA .next		; done

.fire	MOVE R12, (R4)		; get remaining power
	SUB R12, #4		; fixed costs of a phaser shot
	MHL R13, R12
	SNS R13			; enough power?
	BRA .off		; no, done
	MOVE (R4), R12		; yes, update

	MOVB R12, (R9)		; gun orientation
	LWI R13, #char_phaser
	ADD R13, R12
	MOVB R12, (R13)		; get phaser character
	MOVB (R5), R12		; write to screen
	MOVE (R6), R5		; save address in PH_POS
	MOVB R7, (R8)		; SHOT_LEN
	ADD R7, #1		; increase shot length
	MOVB (R8), R7

.next	ADD R2, #SHIP.LEN	; next object
	MOVB R3, (R2)
	SS R3			; done?
	BRA .loop		; no -> loop

	SZ R7			; rescan objects?
	BRA .again		; yes

.ret:	JMP 0

; ******************************

; process objects with flag bit 3 set
; Turn phaser off

PHASER_OFF:
	_DORET_ R12

	LWI R2, #ship_buffer
	MOVB R3, (R2)		; flags

.loop	LBI R13, #$10
	SBS R3, R13		; bit 3 set?
	BRA .next		; no, next object
	CLR R3, #$10
	MOVB (R2), R3		; clear bit 3

	; clear phaser position
	MOVE R4, R2
	ADD R4, #SHIP.PH_POS
	LBI R13, #$00
	MLH R13, R13
	MOVE (R4), R13

	MOVE R4, R2
	ADD R4, #SHIP.SHOT_LEN
	MOVE R3, R2
	ADD R3, #SHIP.GUN_POS
	MOVE R5, (R3)		; gun screen address
	MOVB R3, (R4)		; actual phaser length
	MOVB (R4), R13		; reset phaser length

	; clear entire phaser path on screen
	MOVE R4, R2
	ADD R4, #SHIP.GUN_ORI
	MOVB R4, (R4)
	LWI R6, #add_sub
	ADD R6, R4
	ADD R6, R4
	MOVE R4, (R6)
	MOVE (R0), R4

-	SUB R5, #$01		; **patched**
	SNZ R3
	BRA .next
	LBI R12, #' '
	MOVB (R5), R12		; clear position
	SUB R3, #1
	BRA -

.next	ADD R2, #SHIP.LEN	; next object
	MOVB R3, (R2)
	SS R3			; done?
	BRA .loop		; no -> loop

.ret	JMP 0

; ******************************

; Update ship
;
; Move object with gun (R7!=0) or without (R7=0)

UPDATE_SHIP:
	_DORET_	R12

	INC2 R4, R2		; SHIP.SHIPPOS
	MOVE R5, (R4)		; screen address
	MOVB R3, (R2)		; flags
	LBI R12, #$0A
	SNBC R3, R12		; invisible or switching?
	BRA +			; no, skip

	; ship is in hyperspace
	CLR R3, #$02		; clear switching flag
	MOVB (R2), R3
	INC R3, R2		; SHIP.CHAR
	MOVB R11, (R3)		; get char
	JMP .update

	; normal ship
+	INC R3, R2		; SHIP.CHAR
	MOVB R11, (R3)		; get char to R11
	MOVB R12, (R3)		; also to R12
	MOVB R13, (R5)		; get screen char
	SNE R12, R13		; same?
	BRA +			; yes, process it

	; ship has disappeared, mark inactive
	LBI R12, #$00
	MOVB (R2), R12		; clear flags
	BRA .ret		; return

	; move ship
+	LBI R12, #' '
	MOVB (R5), R12		; clear old screen pos

.update	LWI R6, #add_sub	; add/sub instruction table
	MOVE R3, R2
	ADD R3, #SHIP.DIR
	MOVB R3, (R3)		; get direction
	ADD R6, R3		; calculate offset ..
	ADD R6, R3		; .. into table
	MOVE R3, (R6)		; get correct add or sub instruction
	MOVE (R0), R3		; ** patch next instruction **
	SUB R5, #$01		; ** new screen pos **
	MHL R12, R5		; test screen boundaries
	LBI R13, #$01		; < row 0 ?
	SNE R12, R13		; no
	LBI R12, #$05		; yes, wrap to row 15
	LBI R13, #$06		; > row 15 ?
	SNE R12, R13		; no
	LBI R12, #$02		; yes, wrap to row 0
	MLH R5, R12		; R5 points to the final screen position

	MOVB R12, (R2)		; get flags
	LBI R13, #$08
	MOVE (R4), R5		; update screen address
	SBC R12, R13		; invisible?
	BRA .done		; yes, done

	; ship is visible, move it on the screen
	MOVB R12, (R5)		; get current char from new screen pos
	LBI R13, #' '		; is it a blank?
	SNE R12, R13
	BRA .ok			; yes

	; test collision

	MOVB R12, (R5)		; get current char from new screen pos
	LBI R13, #'*'		; is it an explosion (safe)?
	SNE R12, R13
	BRA .ok			; yes

	INC R12, R2		; SHIP.CHAR
	MOVB R12, (R12)
	MOVB R13, (R5)		; current char
	SE R12, R13		; same?
	BRA .explode		; no

	; collision

	LBI R12, #'*'
	MOVB (R5), R12		; put an asterisk
	LBI R12, #$04		; collision flag
	MOVB (R2), R12		; new flags
	BRA .ret		; return
	; -----

	; old and new screen char different

.explode
	LWI R15, #circle_small
	CALL EXPLODE, R1
	LBI R12, #$00		; make ship inactive
	MOVB (R2), R12
	BRA .ret		; return
	; -----

.ok	LBI R12, #$08		; bit 4
	MOVB R13, (R2)
	SBS R13, R12		; skip if invisible
	MOVB (R5), R11		; put new char

.done	SNZ R7			; done?
	BRA .ret		; yes, return
	; -----

	; R7!=0, move also gun
	LBI R7, #$00
	MOVE R4, R2
	ADD R4, #SHIP.GUN_POS
	MOVE R5, (R4)
	MOVE R12, R2
	ADD R12, #SHIP.GUN_ORI
	MOVB R12, (R12)

	LWI R13, #char_gun
	ADD R13, R12
	MOVB R11, (R13)
	BRA .update

.ret	JMP 0

; ******************************

; Process explosion

EXPLODE:
	_DORET_ R12

	LBI R6, #0		; current object number

	LBI R12, #' '
	MOVB (R5), R12		; clear screen pos

.loop	MOVE R8, (R15)+		; get "small/big circle" table entry
	SNS R8			; end of table?
	BRA .ret		; yes -> return

	LWI R14, #free_bomb
	MOVE R3, (R14)		; ptr to bomb object
	MOVB R4, (R3)		; get flags
	LBI R12, #$82		; set bits 0 and 6
	MOVB (R3)+, R12		; active & new
	MOVB (R3)+, R8		; explosion character

	; clear old explosion location if object is reused
	SNZ R4			; old flags zero?
	BRA +			; yes, skip
	MOVE R4, (R3)		; old screen pos
	LBI R12, #' '
	MOVB (R4), R12		; clear old screen pos

+	MOVE (R3)+, R5		; store current screen pos
	MOVB (R3)+, R6		; store direction
	ADD R6, #1		; next number
	MHL R8, R8
	MOVB (R3)+, R8		; store max. distance

	MOVB R12, (R3)		; next explosion object
	LBI R13, #$FF
	SE R12, R13		; end of table?
	BRA +			; no
	LWI R3, #bomb_buffer	; yes, reset explosion buffer ptr
+	MOVE (R14), R3		; store new explosion buffer ptr
	BRA .loop		; process next explosion

.ret:	JMP 0			; return address patched

; ******************************

; **************************
; KEYBOARD INTERRUPT ROUTINE
; **************************
;
; This is the interrupt routine.
; On first entry, it clears the welcome messages and keeps two of six ships.
; Upon reentry, handle the keypress.

KBD_INT:
	; clear message "IBM INTERNAL USE ONLY"
	LWI R2, #SCRPOS(19, 7)
	INC2 R3, R2		; row 7 col 21
	LBI R12, #11
-	MOVE R13, (R2)+
	MOVE (R3)+, R13
	SUB R12, #1
	SZ R12
	BRA -

	; clear message "PRESS ANY KEY TO START"
	LWI R2, #SCRPOS(19, 9)
	INC2 R3, R2		; row 9 col 21
	LBI R12, #11
-	MOVE R13, (R2)+
	MOVE (R3)+, R13
	SUB R12, #1
	SZ R12
	BRA -

	; Reset ships
	LWI R2, #ship_1
	LWI R3, #ship_buffer
	MOVE (R2)+, R3

	; clear screen area of objects 2 to 5
	LBI R15, #4		; number of objects
-	ADD R3, #SHIP.LEN	; next object

	MOVB R12, (R3)		; get flags
	SET R12, #$08		; set bit 4 (invisible)
	MOVB (R3), R12		; save flags

	INC2 R5, R3		; SHIP.SHIPPOS
	MOVE R5, (R5)
	LBI R12, #' '
	MOVB (R5), R12		; clear character

	MOVE R5, R3
	ADD R5, #SHIP.GUN_POS
	MOVE R5, (R5)
	LBI R12, #' '
	MOVB (R5), R12		; clear character

	SUB R15, #1
	SZ R15
	BRA -			; loop

	ADD R3, #SHIP.LEN
	MOVE (R2)+, R3		; store ptr to last object

KBINT_DONE:
.exit
	CTRL $4, #$12
	
; This is the entry point for all successive keyboard interrupts.
; Exit program with CMD-Space
; Restart program with CMD-Execute

	LWI R3, #scancode
	LBI R12, #$40
	STAT R12, $4		; get scancode
	MOVB (R3), R12		; save

	; Exit program?

	MOVB R12, (R3)
	LBI R13, #$31		; CMD-Space?
	SE R12, R13		
	BRA +			; no

	LWI R4, #EXIT
	MOVE R0L0, R4
	CTRL $4, #$12		; return from kbd int

	; Restart program?

+	MOVB R12, (R3)
	LBI R13, #KEY_CMD_EXEC	; CMD-Execute?
	SE R12, R13
	BRA +			; no

	LWI R4, #START		; entry point of this program
	MOVE R0L0, R4		; modify R0L0
 	CTRL $4, #$12
 
	; Normal keypress

+	LWI R2, #ship_1
	MOVE R2, (R2)		; ptr to first object
	INC2 R5, R2		; SHIP.SHIPPOS
	MOVE R5, (R5)
	LWI R3, #keys_player1	; scancode vector table for this object
	CALL DOKEY, R14		; handle scancode

	LWI R2, #ship_2
	MOVE R2, (R2)		; ptr to last object
	INC2 R5, R2		; SHIP.SHIPPOS
	MOVE R5, (R5)
	LWI R3, #keys_player2	; scancode vector table for this object
	CALL DOKEY, R14		; handle scancode

	BRA .exit		; return from kbd int
; ----------------------

DOKEY:
; Handle scancode
; R2: pointer to object
; R3: pointer to scancode->vector table

	LWI R4, #scancode
	MOVB R4, (R4)		; get stored scancode
-	MOVE R6, (R3)++		; get entry from scancode vector table
	SNS R6			; end of list?
	RET R14			; yes, return
	SE R4, R6		; compare scancode
	BRA -			; mismatch, next entry

	MOVE R4, R2		; ptr to object
	ADD R4, #SHIP.POWER
	MOVE R7, (R4)		; power left
	MHL R6, R6		; get power needed for this key
	LBI R12, #1
	SNE R12, R6		; is it = 1?
	BRA +			; yes, then unlimited

	MOVB R12, (R2)		; get flags
	SNZ R12			; enabled?
	BRA KBINT_DONE		; no, return from kbd int
	; -----

	SUB R7, R6		; subtract from power
	MHL R12, R7		; check borrow
	SNS R12
	BRA KBINT_DONE		; negative, return from kbd int
	; -----

	MOVE (R4), R7		; store remaining power

	; jump to vector
+	SUB R3, #2		; backoff to vector entry
	JMP (R3)		; jump to vector

scancode:	db 0, 0		; keyboard scancode and status bytes

; Key 1 and KP 1
;
; Turn ship counter-clockwise
TURN_CCW:
	LBI R12, #-1		; decrement
	BRA _turn

; Key A and KP 3
;
; Turn ship clockwise
TURN_CW:
	LBI R12, #1		; increment
_turn:	MOVE R3, R2		; pointer to ship
	ADD R3, #SHIP.ROT
	MOVB R4, (R3)		; get value
	ADD R4, R12		; update rotation
	MOVB (R3), R4		; write back

	JMP KBINT_DONE		; return from kbd int

; Key Q and KP 2
;
; Stop/Start spaceship movement
START_STOP:
	LBI R12, #$40
	MOVB R13, (R2)		; get flags

	; toggle bit 1
 if 0
	; (why not just a XOR R13, R12 ???)
	SBS R13, R12		; bit 1 set?
	BRA +			; no
	CLR R13, #$40		; clear bit 1
	BRA ++
+	SET R13, #$40		; set bit 1
 else
	XOR R13, R12
 endif
+	MOVB (R2), R13		; write flags

	JMP KBINT_DONE		; return from kbd int

; Key F and KP Down
;
; Turn gun clockwise
GUN_CW:
	MOVE R3, R2
	ADD R3, #SHIP.GUN_ORI
	MOVB R4, (R3)
	ADD R4, #1

	BRA _gun

; Key S and KP 6
;
; Turn gun counter-clockwise
GUN_CCW:
	MOVE R3, R2
	ADD R3, #SHIP.GUN_ORI
	MOVB R4, (R3)		; get current orientation
	SUB R4, #1		; decrement

_gun:	LBI R13, #$30
	MOVB R12, (R2)		; get flags
	SBC R12, R13		; bit 2 or 3 set?
	BRA .ret		; yes, return

	LBI R12, #$07		; modulo 8
	AND R4, R12
	MOVB (R3), R4		; new orientation

	; clear current gun position
	MOVE R7, R2
	ADD R7, #SHIP.GUN_POS
	MOVE R5, (R7)		; current gun position
	LBI R12, ' '
	MOVB (R5), R12		; clear position

	; derive new gun position
	; from ship position and orientation
	INC2 R5, R2
	MOVE R5, (R5)		; ship position
	LWI R6, #add_sub	; add/sub table
	ADD R6, R4
	ADD R6, R4
	MOVE R12, (R6)		; get instruction
	MOVE (R0), R12		; ** patch next instruction **
	ADD R5, #$40		; ** patched **

	; check screen boundaries
	MHL R12, R5
	LBI R13, #$01
	SNE R12, R13
	LBI R12, #$05
	LBI R13, #$06
	SNE R12, R13
	LBI R12, #$02
	MLH R5, R12
	MOVE (R7), R5		; new gun position

	MOVB R12, (R5)		; get char at new position
	LBI R13, #' '
	SE R12, R13		; blank?
	BRA .ret		; no, i.e. there's an obstacle

	; no obstacle
	LWI R12, #char_gun
	ADD R12, R4		; add orientation
	MOVB R13, (R12)		; get character according to orientation
	MOVB (R5), R13		; write on screen

.ret	JMP KBINT_DONE		; return from kbd int

; Key R and KP Up
;
; Fire/explode MIRV
; (only one at a time)
MIRV:
	MOVE R3, R2		
	ADD R3, #SHIP.MIRV
	MOVE R4, (R3)		
	MHL R12, R4		
	SNZ R12			; already active?
	BRA +			; no
				
	INC2 R7, R4		; BOMB.POS
	MOVE R7, (R7)		; get current position
	MOVB R12, (R7)		; get bomb character
	LBI R13, #CH_CIRCPLUS	; circle with plus
	SE R12, R13		; same?
	BRA +			; no, create new bomb

	; detonate this MIRV
	LBI R12, #$01		; flag for detonation
	MOVB (R4), R12
	LBI R12, #$00		
	MOVB (R3), R12		; clear MIRV
	BRA _bombret		

	; create a new bomb object
+	LWI R4, #free_bomb
	MOVE R4, (R4)
	MOVE (R3), R4		; SHIP.MIRV
	LBI R3, #CH_CIRCPLUS	; circle with plus
	LBI R4, #$FF		; unlimited distance
	BRA _newbomb

; Key E and KP 8
;
; Fire photon bomb
PHOTON_BOMB:
	LBI R3, #CH_CIRCBIG	; big circle
	LBI R4, #$28		; max length 40
	BRA _newbomb

; Key D and KP 9 
;
; Fire photon torpedo
PHOTON_TORPEDO:
	LBI R3, #CH_CIRCSMALL	; small circle
	LBI R4, #$2A		; max length 42

_newbomb:
	MOVE R6, R2
	ADD R6, #SHIP.GUN_ORI	; gun orientation
	MOVE R5, R2
	ADD R5, #SHIP.GUN_POS
	MOVE R5, (R5)		; gun position

	; create new bomb object
	LWI R14, #free_bomb
	MOVE R7, (R14)		; current object
	MOVB R8, (R7)		; BOMB.FLAGS
	LBI R12, #$82
	MOVB (R7)+, R12		; new flags
	MOVB (R7)+, R3		; BOMB.CHAR

	SNZ R8			; was object already active?
	BRA +			; no
	MOVE R3, (R7)		; yes, get bomb position
	LBI R12, #' '
	MOVB (R3), R12		; clear old bomb position

+	MOVE (R7)+, R5		; gun pos. -> BOMB.POS
	MOVB R13, (R6)		; get gun orientation
	MOVB (R7)+, R13		; BOMB.DIR
	MOVB (R7)+, R4		; max. bomb flight distance

	MOVB R12, (R7)		; next object entry
	LBI R13, #$FF		; end of table reached?
	SE R12, R13
	BRA +
	LWI R7, #bomb_buffer	; yes, reset object list
+	MOVE (R14), R7		; update free bomb pointer

_bombret:
	JMP KBINT_DONE		; done, return from kbd int

; Key W and KP 5
;
; Fire phaser
PHASER:
	MOVB R12, (R2)
	SET R12, #$20		; set phaser flag
	MOVB (R2), R12
	JMP KBINT_DONE		; done, return from kbd int

; Key X
;
; Player 1: switch to ship 1/3
PLAY1_SHIP1:
	LBI R12, #0*SHIP.LEN
	BRA _switch_1		; $06(R0)

; Key C
;
; Player 1: switch to ship 2/3
PLAY1_SHIP2:
	LBI R12, #1*SHIP.LEN
	BRA _switch_1		; $02(R0)

; Key V
;
; Player 1: switch to ship 3/3
PLAY1_SHIP3:
	LBI R12, #2*SHIP.LEN
_switch_1:
	LWI R4, #ship_1
	BRA _switch		; $0E(R0)

; Key KP *
;
; Player 2: switch to ship 1/3
PLAY2_SHIP1:
	LBI R12, #3*SHIP.LEN
	BRA _switch_2		; $06(R0)

; Key KP /
;
; Player 2: switch to ship 2/3
PLAY2_SHIP2:
	LBI R12, #4*SHIP.LEN
	BRA _switch_2		; $02(R0)

; Key HOLD
;
; Player 2: switch to ship 3/3
PLAY2_SHIP3:
	LBI R12, #5*SHIP.LEN
_switch_2:
	LWI R4, #ship_2
_switch:
	LWI R2, #ship_buffer
	ADD R2, R12
	MOVB R7, (R2)		; SHIP.FLAGS
	SNZ R7
	BRA .ret		; inactive

	LBI R12, #$08
	SNBC R7, R12		; is it invisible?
	BRA .ret		; no, already visible, return

	MOVE R3, R2
	ADD R3, #SHIP.POWER

	MOVE R6, (R3)
	LBI R12, #$40		; fixed costs for switching the ship
	SUB R6, R12
	MHL R12, R6
	SS R12			; enough power?
	BRA +			; yes

	; not enough power for switch
	LBI R12, #$00
	MOVB (R2), R12		; clear flags
	BRA .ret

+	MOVE (R3), R6		; store remaining power
	CLR R7, #$48
	SET R7, #$02		; bit 6
	MOVB (R2), R7

	MOVE R3, (R4)		; get player's current ship
	MOVB R7, (R3)		; SHIP.FLAGS
	SNZ R7
	BRA +			; inactive

	SET R7, #$08
	MOVB (R3), R7		; make old ship invisible
	INC2 R5, R3		; SHIP.SHIPPOS
	MOVE R5, (R5)
	LBI R12, #' '
	MOVB (R5), R12		; clear it from screen
	ADD R3, #SHIP.GUN_POS
	MOVE R5, (R3)
	LBI R12, #' '
	MOVB (R5), R12		; also clear gun from screen

+	MOVE (R4), R2		; store player's new ship

.ret	JMP KBINT_DONE		; done, return from kbd int

; -----------------------------------------------------------

msg_ibm:	db 'I'!$80, 'B'!$80, 'M'!$80, ' ', 'I'!$80, 'N'!$80, 'T'!$80
		db 'E'!$80, 'R'!$80, 'N'!$80, 'A'!$80, 'L'!$80, ' '
		db 'U'!$80, 'S'!$80, 'E'!$80, ' ', 'O'!$80, 'N'!$80, 'L'!$80
		db 'Y'!$80, ' '
msg_press:	db "PRESS ANY KEY TO START"

	align 2

; Start configuration of all ships
init_ships:
		db $80, $DE
		dw SCRPOS(6, 1)
		db 2, 0
		dw $09FF		; 2560 = power of 1000
		dw 3
		dw 0
		dw SCRPOS(7, 2)
		dw 0

		db $80, $EE
		dw SCRPOS(3, 2)
		db 2, 0
		dw $09FF
		dw 3, 0
		dw SCRPOS(4, 3)
		dw 0

		db $80, $90
		dw SCRPOS(0, 3)
		db 2, 0
		dw $09FF
		dw 3, 0
		dw SCRPOS(1, 4)
		dw 0

		db $80, $BB
		dw SCRPOS(63, 12)
		db 6, 0
		dw $09FF
		dw 7, 0
		dw SCRPOS(62, 11)
		dw 0

		db $80, $DD
		dw SCRPOS(60, 13)
		db 6, 0
		dw $09FF
		dw 7, 0
		dw SCRPOS(59, 12)
		dw 0

		db $80, $BA
		dw SCRPOS(57, 14)
		db 6, 0
		dw $09FF
		dw 7, 0
		dw SCRPOS(56, 13)
		dw 0

		dw $FFFF

; Scancode->Vector table for first object
; Format:
;  byte 0: costs
;  byte 1: scancode
;  word 2: address of subroutine
keys_player1:
	; Key A
	db $08, KEY_A
	dw TURN_CW
	; Key S
	db $02, KEY_S
	dw GUN_CCW
	; Key D
	db $20, KEY_D
	dw PHOTON_TORPEDO
	; Key F
	db $02, KEY_F
	dw GUN_CW
	; Key Q
	db $20, KEY_Q
	dw START_STOP
	; Key W
	db $20, KEY_W
	dw PHASER
	; Key E
	db $40, KEY_E
	dw PHOTON_BOMB
	; Key R
	db $80, KEY_R
	dw MIRV
	; Key 1
	db $08, KEY_1
	dw TURN_CCW
	; Key X
	db $01, KEY_X
	dw PLAY1_SHIP1
	; Key C
	db $01, KEY_C
	dw PLAY1_SHIP2
	; Key V
	db $01, KEY_V
	dw PLAY1_SHIP3
	
	dw $FFFF

; Scancode->Vector table for last object
keys_player2:
	; Key KP 3
	db $08, KEY_KP3
	dw TURN_CW
	; Key KP 6
	db $02, KEY_KP6
	dw GUN_CCW
	; Key KP 9
	db $20, KEY_KP9
	dw PHOTON_TORPEDO
	; Key KP Down
	db $02, KEY_DN
	dw GUN_CW
	; Key KP 2
	db $20, KEY_KP2
	dw START_STOP
	; Key KP 5
	db $20, KEY_KP5
	dw PHASER
	; Key KP 8
	db $40, KEY_KP8
	dw PHOTON_BOMB
	; Key KP Up
	db $80, KEY_UP
	dw MIRV
	; Key KP 1
	db $08, KEY_KP1
	dw TURN_CCW
	; Key KP *
	db $01, KEY_KPMUL
	dw PLAY2_SHIP1
	; Key KP /
	db $01, KEY_KPDIV
	dw PLAY2_SHIP2
	; Key HOLD
	db $01, KEY_HOLD
	dw PLAY2_SHIP3
	
	dw $FFFF

ship_1:		dw ?	; ptr to ship of player 1
ship_2:		dw ?	; ptr to ship of player 2

circle_small:	db 5, $36
		db 4, $36
		db 6, $36
		db 4, $36
		db 5, $36
		db 4, $36
		db 6, $36
		db 4, $36
		dw $FFFF

circle_big:	db  8, $36
		db  2, $3B
		db 15, $36
		db  2, $3B
		db  8, $36
		db  2, $3B
		db 15, $36
		db  2, $3B
		dw $FFFF
 

free_bomb:	dw bomb_buffer		; pointer to next free explosion object
		
		;   .    .    -    '    '    '    -    .

char_gun:	db $2C, $2C, $52, $37, $37, $37, $52, $2C
		;   |    /    -    \    |    /    -    \

char_phaser:	db $39, $25, $52, $51, $39, $25, $52, $51


; add/sub instruction table for new screen position
add_sub:
	SUB R5, #$40		; up
	SUB R5, #$3F		; up-right
	ADD R5, #$01		; right
	ADD R5, #$41		; down-right
	ADD R5, #$40		; down
	ADD R5, #$3F		; down-left
	SUB R5, #$01		; left
	SUB R5, #$41		; up-left

ship_buffer:	SHIP [6]
		dw $FFFF

bomb_buffer:	BOMB [100]
		dw $FFFF

	end
