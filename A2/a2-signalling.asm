; a2-signalling.asm
; CSC 230: Fall 2022
;
; Student name:
; Student ID:
; Date of completed work:
;
; *******************************
; Code provided for Assignment #2
;
; Author: Mike Zastre (2022-Oct-15)
;
 
; This skeleton of an assembly-language program is provided to help you
; begin with the programming tasks for A#2. As with A#1, there are "DO
; NOT TOUCH" sections. You are *not* to modify the lines within these
; sections. The only exceptions are for specific changes changes
; announced on Brightspace or in written permission from the course
; instructor. *** Unapproved changes could result in incorrect code
; execution during assignment evaluation, along with an assignment grade
; of zero. ****

.include "m2560def.inc"
.cseg
.org 0

; ***************************************************
; **** BEGINNING OF FIRST "STUDENT CODE" SECTION ****
; ***************************************************

	; initializion code will need to appear in this
    ; section
	ldi r16, 0xff
	sts DDRL, r16		;set DDRL port to output
	out DDRB, r16		;set DDRB port to output
	out SPL, r16		;set stack pointer to higest memory location 0x21ff
	ldi r16, 0x21
	out SPH, r16

	.def mask = r17
	.def temp = r18
	.def tempa = r19
	.def tempb = r20
	.def count = r21
	.def countb = r22


; ***************************************************
; **** END OF FIRST "STUDENT CODE" SECTION **********
; ***************************************************

; ---------------------------------------------------
; ---- TESTING SECTIONS OF THE CODE -----------------
; ---- TO BE USED AS FUNCTIONS ARE COMPLETED. -------
; ---------------------------------------------------
; ---- YOU CAN SELECT WHICH TEST IS INVOKED ---------
; ---- BY MODIFY THE rjmp INSTRUCTION BELOW. --------
; -----------------------------------------------------

	rjmp test_part_e
	; Test code


test_part_a:
	ldi r16, 0b00100001
	rcall set_leds
	rcall delay_long

	clr r16
	rcall set_leds
	rcall delay_long

	ldi r16, 0b00111000
	rcall set_leds
	rcall delay_short

	clr r16
	rcall set_leds
	rcall delay_long

	ldi r16, 0b00100001
	rcall set_leds
	rcall delay_long

	clr r16
	rcall set_leds

	rjmp end


test_part_b:
	ldi r17, 0b00101010
	rcall slow_leds
	ldi r17, 0b00010101
	rcall slow_leds
	ldi r17, 0b00101010
	rcall slow_leds
	ldi r17, 0b00010101
	rcall slow_leds

	rcall delay_long
	rcall delay_long

	ldi r17, 0b00101010
	rcall fast_leds
	ldi r17, 0b00010101
	rcall fast_leds
	ldi r17, 0b00101010
	rcall fast_leds
	ldi r17, 0b00010101
	rcall fast_leds
	ldi r17, 0b00101010
	rcall fast_leds
	ldi r17, 0b00010101
	rcall fast_leds
	ldi r17, 0b00101010
	rcall fast_leds
	ldi r17, 0b00010101
	rcall fast_leds

	rjmp end

test_part_c:
	ldi r16, 0b11111000
	push r16
	rcall leds_with_speed
	pop r16

	ldi r16, 0b11011100
	push r16
	rcall leds_with_speed
	pop r16

	ldi r20, 0b00100000
test_part_c_loop:
	push r20
	rcall leds_with_speed
	pop r20
	lsr r20
	brne test_part_c_loop

	rjmp end


test_part_d:
	ldi r21, 'E' 
	push r21
	rcall encode_letter
	pop r21
	push r25
	rcall leds_with_speed
	pop r25

	rcall delay_long

	ldi r21, 'A'
	push r21
	rcall encode_letter
	pop r21
	push r25
	rcall leds_with_speed
	pop r25

	rcall delay_long


	ldi r21, 'M'
	push r21
	rcall encode_letter
	pop r21
	push r25
	rcall leds_with_speed
	pop r25

	rcall delay_long

	ldi r21, 'H'
	push r21
	rcall encode_letter
	pop r21
	push r25
	rcall leds_with_speed
	pop r25

	rcall delay_long

	rjmp end


test_part_e:
	ldi r25, HIGH(WORD02 << 1)
	ldi r24, LOW(WORD02 << 1)
	rcall display_message
	rjmp end

end:
    rjmp end






; ****************************************************
; **** BEGINNING OF SECOND "STUDENT CODE" SECTION ****
; ****************************************************

;r16 stores position of leds we want to turn on
set_leds:
	push r17
	push r18
	push r19
	push r20
	push r21

	ldi mask, 0x01
	clr tempa
	clr tempb

	mov temp, r16      ;checking 1st bit for port L
	and temp, mask
	ldi count, 0x07
	call lsl_temp	   ;shifting 1st bit to bit7 position	   
	or tempa, temp
	lsl mask

	mov temp, r16      ;checking 2nd bit for port L
	and temp, mask
	ldi count, 0x04
	call lsl_temp      ;shifting 2nd bit to bit5 position 
	or tempa, temp
	lsl mask

	mov temp, r16      ;checking 3rd bit for port L
	and temp, mask
	ldi count, 0x01			 
	call lsl_temp	   ;shifting 3rd bit to bit3 position 	  
	or tempa, temp
	lsl mask

	mov temp, r16      ;checking 4th bit for port L
	and temp, mask
	ldi count, 0x02
	call lsr_temp	   ;shifting 4th bit to bit1 position 
	or tempa, temp
	lsl mask
 
	mov temp, r16      ;checking 5th bit for port B
	and temp, mask
	ldi count, 0x01
    call lsr_temp	   ;shifting 5th bit to bit3 position 
	or tempb, temp
	lsl mask

	mov temp, r16      ;checking 6th bit for port B
	and temp, mask
	ldi count, 0x04
	call lsr_temp	   ;shifting 6th bit to bit1 position 
	or tempb, temp

	sts PORTL, tempa  ;store values in each port
	out PORTB, tempb

	pop r21
	pop r20
	pop r19
	pop r18
	pop r17
	ret


lsl_temp:					;lsl n times where n is the value stored in count(r21)
	lsl temp
	dec count
	breq lsl_lsr_end
	rjmp lsl_temp

lsr_temp:					;lsr n times where n is the value stored in count(r21)
	lsr temp
	dec count
	breq lsl_lsr_end
	rjmp lsr_temp
	
lsl_lsr_end:
	ret

slow_leds:
	push r16			;take value in r17 and store it in r16 as set_leds takes r16 as a paramenter
	mov r16, r17		;call set_leds to turn on leds, apply a long delay then clear r16 and call set_leds to turn leds off
	call set_leds
	call delay_long
	clr r16
	sts PORTL, r16
	out PORTB, r16
	pop r16
	ret


fast_leds:				; same concept as slow_leds but with a short delay 
	push r16
	mov r16, r17
	call set_leds
	call delay_short
	clr r16
	sts PORTL, r16
	out PORTB, r16
	pop r16
	ret


leds_with_speed:			
	push r17
	push r18
	push r30
	push r31

	in ZH, SPH
	in ZL, SPL	
	ldd r18, Z + 8

	mov r17, r18
	andi temp, 0b11000000				;get value from the stack. if the first two bits are set then call fast_leds , else call short_leds
	breq leds_with_speed_fast
	rjmp leds_with_speed_slow

leds_with_speed_fast:
	call fast_leds
	pop r31
	pop r30
	pop r18
	pop r17
	ret

leds_with_speed_slow:
	call slow_leds
	pop r31
	pop r30
	pop r18
	pop r17
	ret


; Note -- this function will only ever be tested
; with upper-case letters, but it is a good idea
; to anticipate some errors when programming (i.e. by
; accidentally putting in lower-case letters). Therefore
; the loop does explicitly check if the hyphen/dash occurs,
; in which case it terminates with a code not found
; for any legal letter.

encode_letter:
	push r18	;temp but it's used to store our parameter for the first portion of our code
	push r19
	push r22    ;countb
	push r28
	push r29
	push r30
	push r31

	in YH, SPH
	in YL, SPL

	ldd r18, Y + 11
	ldi ZH, high(PATTERNS << 1)
	ldi ZL, low(PATTERNS << 1)
	ldi countb, 0x1A			
	rjmp encode_letter_loop


encode_letter_loop:						;loop to check each letter in memory
	lpm r19, Z+							;loop exits when a match is found or the alphabet is exhausted
	cp r18, r19
	breq encode_letter_end
	dec countb
	breq encode_letter_end
	
	lpm r19, Z+
	lpm r19, Z+
	lpm r19, Z+
	lpm r19, Z+
	lpm r19, Z+
	lpm r19, Z+
	lpm r19, Z+
	rjmp encode_letter_loop

encode_letter_end:					
	push r20					;tempb
	push r21					;count
	clr tempb

	lpm r19, z+					;storing bit 5 for final value
	ldi count, 0x05
	call store_truth_a
	call lsl_temp			
	or tempb, temp
	
	lpm r19, z+					;storing bit 4  for final value
	ldi count, 0x04 				
	call store_truth_a
	call lsl_temp
	or tempb, temp

	lpm r19, z+					;storing bit 3 for final value
	ldi count, 0x03 				
	call store_truth_a
	call lsl_temp
	or tempb, temp
	 
	lpm r19, z+					;storing bit 2 for final value
	ldi count, 0x02 				
	call store_truth_a
	call lsl_temp
	or tempb, temp	

	lpm r19, z+					;storing bit 1 for final value
	ldi count, 0x01 				
	call store_truth_a
	call lsl_temp
	or tempb, temp				

	lpm r19, z+					;storing bit 0 for final value			
	call store_truth_a
	or tempb, temp

	lpm r19, z+					;storing bit 6 and bit 7 for final value
	ldi count, 0x06				
	call store_truth_b
	call lsl_temp
	or tempb, temp
	
	mov r25,  tempb

	pop r21
	pop r20

	pop r31
	pop r30
	pop r29
	pop r28
	pop r22
	pop r19
	pop r18
	ret

store_truth_a: 
	cpi r19, 0x6f				;asci code for "o" meaning the bit should be set		
	brne set_bit_to_zero 
	ldi temp, 0x01
	ret

store_truth_b:
	cpi r19, 0x01
	brne set_bit_to_zero
	ldi temp, 0x03
	ret

set_bit_to_zero:
	ldi temp, 0x00
	ret


display_message:
	push r30
	push r31
	push r25
	push r19


	mov ZH, r25
	mov ZL, r24 
	rjmp display_message_loop


display_message_loop:
	lpm r19, Z+
	cpi r19, 0x00					;case to check when the word is finished i.e null pointer check
	breq display_message_end
	push r19
	call encode_letter
	pop r19
	push r25
	call leds_with_speed
	pop r25
	call delay_short
	rjmp display_message_loop

display_message_end:
	
	pop r19	
	pop r25
	pop r31
	pop r30
	ret

; ****************************************************
; **** END OF SECOND "STUDENT CODE" SECTION **********
; ****************************************************




; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================

; about one second
delay_long:
	push r16

	ldi r16, 14
delay_long_loop:
	rcall delay
	dec r16
	brne delay_long_loop

	pop r16
	ret


; about 0.25 of a second
delay_short:
	push r16

	ldi r16, 4
delay_short_loop:
	rcall delay
	dec r16
	brne delay_short_loop

	pop r16
	ret

; When wanting about a 1/5th of a second delay, all other
; code must call this function
;
delay:
	rcall delay_busywait
	ret


; This function is ONLY called from "delay", and
; never directly from other code. Really this is
; nothing other than a specially-tuned triply-nested
; loop. It provides the delay it does by virtue of
; running on a mega2560 processor.
;
delay_busywait:
	push r16
	push r17
	push r18

	ldi r16, 0x08
delay_busywait_loop1:
	dec r16
	breq delay_busywait_exit

	ldi r17, 0xff
delay_busywait_loop2:
	dec r17
	breq delay_busywait_loop1

	ldi r18, 0xff
delay_busywait_loop3:
	dec r18
	breq delay_busywait_loop2
	rjmp delay_busywait_loop3

delay_busywait_exit:
	pop r18
	pop r17
	pop r16
	ret


; Some tables
.cseg
.org 0x600

PATTERNS:
	; LED pattern shown from left to right: "." means off, "o" means
    ; on, 1 means long/slow, while 2 means short/fast.
	.db "A", "..oo..", 1
	.db "B", ".o..o.", 2
	.db "C", "o.o...", 1
	.db "D", ".....o", 1
	.db "E", "oooooo", 1
	.db "F", ".oooo.", 2
	.db "G", "oo..oo", 2
	.db "H", "..oo..", 2
	.db "I", ".o..o.", 1
	.db "J", ".....o", 2
	.db "K", "....oo", 2
	.db "L", "o.o.o.", 1
	.db "M", "oooooo", 2
	.db "N", "oo....", 1
	.db "O", ".oooo.", 1
	.db "P", "o.oo.o", 1
	.db "Q", "o.oo.o", 2
	.db "R", "oo..oo", 1
	.db "S", "....oo", 1
	.db "T", "..oo..", 1
	.db "U", "o.....", 1
	.db "V", "o.o.o.", 2
	.db "W", "o.o...", 2
	.db "W", "oo....", 2
	.db "Y", "..oo..", 2
	.db "Z", "o.....", 2
	.db "-", "o...oo", 1   ; Just in case!

WORD00: .db "HELLOWORLD", 0, 0
WORD01: .db "THE", 0
WORD02: .db "QUICK", 0
WORD03: .db "BROWN", 0
WORD04: .db "FOX", 0
WORD05: .db "JUMPED", 0, 0
WORD06: .db "OVER", 0, 0
WORD07: .db "THE", 0
WORD08: .db "LAZY", 0, 0
WORD09: .db "DOG", 0

; =======================================
; ==== END OF "DO NOT TOUCH" SECTION ====
; =======================================

