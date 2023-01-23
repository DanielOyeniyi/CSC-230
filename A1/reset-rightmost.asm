; reset-rightmost.asm
; CSC 230: Fall 2022
;
; Code provided for Assignment #1
;
; Mike Zastre (2022-Sept-22)

; This skeleton of an assembly-language program is provided to help you
; begin with the programming task for A#1, part (b). In this and other
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
; Your task: You are to take the bit sequence stored in R16,
; and to reset the rightmost contiguous sequence of set
; by storing this new value in R25. For example, given
; the bit sequence 0b01011100, resetting the right-most
; contigous sequence of set bits will produce 0b01000000.
; As another example, given the bit sequence 0b10110110,
; the result will be 0b10110000.
;
; Your solution must work, of course, for bit sequences other
; than those provided in the example. (How does your
; algorithm handle a value with no set bits? with all set bits?)

; ANY SIGNIFICANT IDEAS YOU FIND ON THE WEB THAT HAVE HELPED
; YOU DEVELOP YOUR SOLUTION MUST BE CITED AS A COMMENT (THAT
; IS, WHAT THE IDEA IS, PLUS THE URL).

    .cseg
    .org 0

; ==== END OF "DO NOT TOUCH" SECTION ==========

	ldi R16, 0b01011100
	 ;ldi R16, 0b10110110
	 

	.def bit_traverser = r17		;mask to travel through each bit location 
	.def unsetter = r18				;mask to unset the contiguous bits
	.def prev = r19					;value to represent the previous bit
	.def state = r20				;value to represent if a rightmost contiguous bit has occured
	.def copy = r21					;a copy of the value in r16
	
	ldi bit_traverser, 0x01			;set bit mask to 00000001 to check first bit value
	clr unsetter
	clr prev
	clr state

loop:
	mov copy, r16					;reset copy to have the original value from r16
	and copy, bit_traverser			;check if bit is set at xth bit location 
	brne update						;if the bit is set then branch, else continue
	lsl bit_traverser				;update the mask to check the next bit
	breq end						;if the 7th bit has already been checked then branch 
	mov prev, copy					;record whether the previously checked bit was set or unset
	rjmp loop						;jump back to start of loop
	



update:
	cpi prev, 0x00					;check if the previous bit was unset
	breq check_state				;if the previous bit was unset then branch, else continue
	or unsetter, bit_traverser		;record what bit positions need to be unset 
	ldi state, 0x01					;change state to indicate that a contiguous bit has been encountered
	lsl bit_traverser				;repeated in loop
	breq end
	mov prev, copy
	rjmp loop

	
check_state:
	cpi state, 0x01					;check if the a contiguous bit has been encountered before
	breq end						;if there has already been a contiguous bit then branch
	or unsetter, bit_traverser		;repeated in update
	ldi state, 0x01
	lsl bit_traverser
	breq end
	mov prev, copy
	rjmp loop


end:
	mov copy, r16					
	eor copy, unsetter				;unset the contiguous bits
	mov r25, copy					;store final value in r25
	jmp reset_rightmost_stop		;end code


	; THE RESULT **MUST** END UP IN R25

; **** BEGINNING OF "STUDENT CODE" SECTION **** 

; Your solution here.

; **** END OF "STUDENT CODE" SECTION ********** 



; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
reset_rightmost_stop:
    rjmp reset_rightmost_stop


; ==== END OF "DO NOT TOUCH" SECTION ==========
