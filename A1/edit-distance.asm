; main.asm for edit-distance assignment
;
; CSC 230: Fall 2022
;
; Code provided for Assignment #1
;
; Mike Zastre (2022-Sept-22)

; This skeleton of an assembly-language program is provided to help you
; begin with the programming task for A#1, part (a). In this and other
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
;
; Your task: To compute the edit distance between two byte values,
; one in R16, the other in R17. If the first byte is:
;    0b10101111
; and the second byte is:
;    0b10011010
; then the edit distance -- that is, the number of corresponding
; bits whose values are not equal -- would be 4 (i.e., here bits 5, 4,
; 2 and 0 are different, where bit 0 is the least-significant bit).
; 
; Your solution must, of course, work for other values than those
; provided in the example above.
;
; In your code, store the computed edit distance value in R25.
;
; Your solution is free to modify the original values in R16
; and R17.
;
; ANY SIGNIFICANT IDEAS YOU FIND ON THE WEB THAT HAVE HELPED
; YOU DEVELOP YOUR SOLUTION MUST BE CITED AS A COMMENT (THAT
; IS, WHAT THE IDEA IS, PLUS THE URL).

    .cseg
    .org 0

; ==== END OF "DO NOT TOUCH" SECTION ==========

	ldi r16, 0xa7
	ldi r17, 0x9a

; **** BEGINNING OF "STUDENT CODE" SECTION **** 

	; Your solution in here.

	; THE RESULT **MUST** END UP IN R25

	.def count = r18	;r18 holds count of final ditance 
	.def mask = r19		;r19 holds the mask that will test each bit
	.def result = r20	;r20 hold the value that shows the exclusive or between each bit location
	ldi count, 0x00		;set the count to 0
	ldi mask, 0x01		;set mask to 0b00000001
	
	eor r16, r17	    ;exclusive or the value in r16 with the value in r17, the result will show which bit locations are diffrerent
	breq end
	rjmp loop_a

	loop_a: 
		mov result, r16		;store the result of eor r16, r17 in r20
		and result, mask    ;check if the the xth bit location is set
		brne increment		;if z flag is not set the bit location has different values so increment the counter
		rjmp loop_b			;go to the second half of the loop 

	loop_b:
		clz					;clear the zero flag so that the next step works even if the mask is not equal to 0 
		lsl mask			;shift the mask so that it checks the next (x+1th) bit
		brne loop_a			;if the mask hasn't checked the last bit then loop again 
		rjmp end			;otherwise the mask is 0b00000000 and all bits have been checked

	increment: 
		inc count			;increment the counter
		rjmp loop_b			;go back to the loop

	end: 
		mov r25, count		    ;store the final distance(count) in r25
		jmp edit_distance_stop	;end the program



; **** END OF "STUDENT CODE" SECTION ********** 

; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
edit_distance_stop:
    rjmp edit_distance_stop



; ==== END OF "DO NOT TOUCH" SECTION ==========
