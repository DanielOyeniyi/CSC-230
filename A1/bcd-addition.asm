; bcd-addition.asm
; CSC 230: Fall 2022
;
; Code provided for Assignment #1
;
; Mike Zastre (2022-Sept-22)

; This skeleton of an assembly-language program is provided to help you
; begin with the programming task for A#1, part (c). In this and other
; files provided through the semester, you will see lines of code
; indicating "DO NOT TOUCH" sections. You are *not* to modify the
; lines within these sections. The only exceptions are for specific
; changes announced on conneX or in written permission from the course
; instructor. *** Unapproved changes could result in incorrect code
; execution during assignment evaluation, along with an assignment grade
; of zero. ****
;
; In a more positive vein, you are expected to place your code with the
; area marked "STUDENT CODE" sections.

; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; Your task: Two packed-BCD numbers are provided in R16
; and R17. You are to add the two numbers together, such
; the the rightmost two BCD "digits" are stored in R25
; while the carry value (0 or 1) is stored R24.
;
; For example, we know that 94 + 9 equals 103. If
; the digits are encoded as BCD, we would have
;   *  0x94 in R16
;   *  0x09 in R17
; with the result of the addition being:
;   * 0x03 in R25
;   * 0x01 in R24
;
; Similarly, we know than 35 + 49 equals 84. If 
; the digits are encoded as BCD, we would have
;   * 0x35 in R16
;   * 0x49 in R17
; with the result of the addition being:
;   * 0x84 in R25
;   * 0x00 in R24
;

; ANY SIGNIFICANT IDEAS YOU FIND ON THE WEB THAT HAVE HELPED
; YOU DEVELOP YOUR SOLUTION MUST BE CITED AS A COMMENT (THAT
; IS, WHAT THE IDEA IS, PLUS THE URL).



    .cseg
    .org 0

	; Some test cases below for you to try. And as usual
	; your solution is expected to work with values other
	; than those provided here.
	;
	; Your code will always be tested with legal BCD
	; values in r16 and r17 (i.e. no need for error checking).

	; 94 + 9 = 03, carry = 1
	 ;ldi r16, 0x94
	 ;ldi r17, 0x09

	; 86 + 79 = 65, carry = 1
	 ;ldi r16, 0x86
	 ;ldi r17, 0x79

	; 35 + 49 = 84, carry = 0
	 ;ldi r16, 0x35
	 ;ldi r17, 0x49

	; 32 + 41 = 73, carry = 0
	ldi r16, 0x32
	ldi r17, 0x41


; ==== END OF "DO NOT TOUCH" SECTION ==========

; **** BEGINNING OF "STUDENT CODE" SECTION **** 
.def high_a = r18		;spliting up the high and low nibbles for the values in r16 and r17
.def low_a = r19
.def high_b = r20
.def low_b = r21
.def neg_ten = r22	
.def temp = r23	

ldi neg_ten, 0x0f6		; -10 (2's)

mov high_a, r16
mov low_a, r16
mov high_b, r17
mov low_b, r17

swap high_a				;isolating the high nibble
cbr high_a, 0xf0
cbr low_a, 0xf0			;isolating the low nibble

swap high_b
cbr high_b, 0xf0		
cbr low_b, 0xf0

add low_a, low_b
mov temp, low_a
add temp, neg_ten				;working with 2's complement for the addition portions of this code, not the final result
brcs low_greater_than_nine		;if the carry flag is set then the result of low_a + low_b is greater than 9 otherwise the value stored in low_a is the final value
rjmp high_addition


high_addition:
	add high_a, high_b
	mov temp, high_a
	add temp, neg_ten
	brcs high_greater_than_nine	;checking if high_a + high_b is greater than 9  otherwise the value stored in high_a is the final value
	rjmp end


low_greater_than_nine:
	mov low_a, temp					;store the correct value in low_a				
	inc high_a						;add the carry(from low_a + low_b) to high_a
	mov temp, high_a
	add temp, neg_ten
	brcs high_a_greater_than_nine	;checking if adding the carry made high_a greater than 9 otherwise the value stores in high_a is the correct value
	rjmp high_addition


high_a_greater_than_nine:
	mov high_a, temp	;store the correct value in high_a 
	ldi r24, 0x01		;there will be a carry from the overall adition, so store 0x01 in r24 as per the details of the assignment
	rjmp high_addition


high_greater_than_nine:
	mov high_a, temp	;store the final value in high_a
	ldi r24, 0x01		;there will be a carry from the overall adition, so store 0x01 in r24 as per the details of the assignment
	rjmp end


end:
	swap high_a				;getting the final result in the format AAAAaaaa (high nibble then low nibble) 
	add high_a, low_a
	mov r25, high_a
	jmp bcd_addition_end					



; **** END OF "STUDENT CODE" SECTION ********** 

; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
bcd_addition_end:
	rjmp bcd_addition_end



; ==== END OF "DO NOT TOUCH" SECTION ==========
