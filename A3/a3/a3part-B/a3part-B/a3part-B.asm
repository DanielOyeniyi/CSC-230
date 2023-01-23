;
; a3part-B.asm
;
; Part B of assignment #3
;
;
; Student name: Daniel Oyeniyi
; Student ID: V00937920
; Date of completed work: 11/18/2022 
;
; **********************************
; Code provided for Assignment #3
;
; Author: Mike Zastre (2022-Nov-05)
;
; This skeleton of an assembly-language program is provided to help you 
; begin with the programming tasks for A#3. As with A#2 and A#1, there are
; "DO NOT TOUCH" sections. You are *not* to modify the lines within these
; sections. The only exceptions are for specific changes announced on
; Brightspace or in written permission from the course instruction.
; *** Unapproved changes could result in incorrect code execution
; during assignment evaluation, along with an assignment grade of zero. ***
;


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================
;
; In this "DO NOT TOUCH" section are:
; 
; (1) assembler direction setting up the interrupt-vector table
;
; (2) "includes" for the LCD display
;
; (3) some definitions of constants that may be used later in
;     the program
;
; (4) code for initial setup of the Analog-to-Digital Converter
;     (in the same manner in which it was set up for Lab #4)
;
; (5) Code for setting up three timers (timers 1, 3, and 4).
;
; After all this initial code, your own solutions's code may start
;

.cseg
.org 0
	jmp reset

; Actual .org details for this an other interrupt vectors can be
; obtained from main ATmega2560 data sheet
;
.org 0x22
	jmp timer1

; This included for completeness. Because timer3 is used to
; drive updates of the LCD display, and because LCD routines
; *cannot* be called from within an interrupt handler, we
; will need to use a polling loop for timer3.
;
; .org 0x40
;	jmp timer3

.org 0x54
	jmp timer4

.include "m2560def.inc"
.include "lcd.asm"

.cseg
#define CLOCK 16.0e6
#define DELAY1 0.01
#define DELAY3 0.1
#define DELAY4 0.5

#define BUTTON_RIGHT_MASK 0b00000001	
#define BUTTON_UP_MASK    0b00000010
#define BUTTON_DOWN_MASK  0b00000100
#define BUTTON_LEFT_MASK  0b00001000

#define BUTTON_RIGHT_ADC  0x032
#define BUTTON_UP_ADC     0x0b0   ; was 0x0c3
#define BUTTON_DOWN_ADC   0x160   ; was 0x17c
#define BUTTON_LEFT_ADC   0x22b
#define BUTTON_SELECT_ADC 0x316

.equ PRESCALE_DIV=1024   ; w.r.t. clock, CS[2:0] = 0b101

; TIMER1 is a 16-bit timer. If the Output Compare value is
; larger than what can be stored in 16 bits, then either
; the PRESCALE needs to be larger, or the DELAY has to be
; shorter, or both.
.equ TOP1=int(0.5+(CLOCK/PRESCALE_DIV*DELAY1))
.if TOP1>65535
.error "TOP1 is out of range"
.endif

; TIMER3 is a 16-bit timer. If the Output Compare value is
; larger than what can be stored in 16 bits, then either
; the PRESCALE needs to be larger, or the DELAY has to be
; shorter, or both.
.equ TOP3=int(0.5+(CLOCK/PRESCALE_DIV*DELAY3))
.if TOP3>65535
.error "TOP3 is out of range"
.endif

; TIMER4 is a 16-bit timer. If the Output Compare value is
; larger than what can be stored in 16 bits, then either
; the PRESCALE needs to be larger, or the DELAY has to be
; shorter, or both.
.equ TOP4=int(0.5+(CLOCK/PRESCALE_DIV*DELAY4))
.if TOP4>65535
.error "TOP4 is out of range"
.endif

reset:
; ***************************************************
; **** BEGINNING OF FIRST "STUDENT CODE" SECTION ****
; ***************************************************

; Anything that needs initialization before interrupts
; start must be placed here.

ldi r16, low(RAMEND)
out SPL, r16
ldi r16, high(RAMEND)
out SPH, r16					
rcall lcd_init

; ***************************************************
; ******* END OF FIRST "STUDENT CODE" SECTION *******
; ***************************************************

; =============================================
; ====  START OF "DO NOT TOUCH" SECTION    ====
; =============================================

	; initialize the ADC converter (which is needed
	; to read buttons on shield). Note that we'll
	; use the interrupt handler for timer 1 to
	; read the buttons (i.e., every 10 ms)
	;
	ldi temp, (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
	sts ADCSRA, temp
	ldi temp, (1 << REFS0)
	sts ADMUX, r16

	; Timer 1 is for sampling the buttons at 10 ms intervals.
	; We will use an interrupt handler for this timer.
	ldi r17, high(TOP1)
	ldi r16, low(TOP1)
	sts OCR1AH, r17
	sts OCR1AL, r16
	clr r16
	sts TCCR1A, r16
	ldi r16, (1 << WGM12) | (1 << CS12) | (1 << CS10)
	sts TCCR1B, r16
	ldi r16, (1 << OCIE1A)
	sts TIMSK1, r16

	; Timer 3 is for updating the LCD display. We are
	; *not* able to call LCD routines from within an 
	; interrupt handler, so this timer must be used
	; in a polling loop.
	ldi r17, high(TOP3)
	ldi r16, low(TOP3)
	sts OCR3AH, r17
	sts OCR3AL, r16
	clr r16
	sts TCCR3A, r16
	ldi r16, (1 << WGM32) | (1 << CS32) | (1 << CS30)
	sts TCCR3B, r16
	; Notice that the code for enabling the Timer 3
	; interrupt is missing at this point.

	; Timer 4 is for updating the contents to be displayed
	; on the top line of the LCD.
	ldi r17, high(TOP4)
	ldi r16, low(TOP4)
	sts OCR4AH, r17
	sts OCR4AL, r16
	clr r16
	sts TCCR4A, r16
	ldi r16, (1 << WGM42) | (1 << CS42) | (1 << CS40)
	sts TCCR4B, r16
	ldi r16, (1 << OCIE4A)
	sts TIMSK4, r16

	sei

; =============================================
; ====    END OF "DO NOT TOUCH" SECTION    ====
; =============================================

; ****************************************************
; **** BEGINNING OF SECOND "STUDENT CODE" SECTION ****
; ****************************************************

start:
	in r16, TIFR3			;we use in because TIFR3 is refering to a memory adress. ldi still compiles but causes error
	sbrs r16, OCF3A			;checking if the timer has reached the top value
	rjmp start

	ldi r16, 1<<OCF3A		;reseting timer 3
	out TIFR3, r16

	lds r16, BUTTON_IS_PRESSED		;checking if a button is pressed
	cpi r16, 0x01
	breq pressed
												;if button was pressed update the letter on the screen, otherwise use the letter corresponding to the last button pressed
	ldi r16, 0x01			;row 1
	ldi r17, 0x0f			;column 15
	push r16
	push r17
	call lcd_gotoxy
	pop r17
	pop r16

	ldi r16, '-'
	push r16
	call lcd_putchar	
	pop r16

	rjmp start

pressed:
	ldi r16, 0x01			;row 1
	ldi r17, 0x0f			;column 15
	push r16
	push r17
	call lcd_gotoxy
	pop r17
	pop r16

	ldi r16, '*'
	push r16
	call lcd_putchar	
	pop r16

	lds r18, LAST_BUTTON_PRESSED						;now we want to do the case checks for the lcd screen

	cpi r18, 'R'
	breq put_right

	cpi r18, 'U'
	breq put_up

	cpi r18, 'D'
	breq put_down

	cpi r18, 'L'
	breq put_left				
														;otherwise select was pressed so do nothing
	rjmp start

put_right:
	ldi r16, 0x01			;row 1
	ldi r17, 0x03			;column 3
	push r16
	push r17
	call lcd_gotoxy
	pop r17
	pop r16

	ldi r16, 'R'
	push r16
	call lcd_putchar	
	pop r16

	call clear_up
	call clear_down
	call clear_left

	rjmp start

put_up:
	ldi r16, 0x01			;row 1
	ldi r17, 0x02			;column 2
	push r16
	push r17
	call lcd_gotoxy
	pop r17
	pop r16

	ldi r16, 'U'
	push r16
	call lcd_putchar	
	pop r16

	call clear_right
	call clear_down
	call clear_left

	rjmp start

put_down:
	ldi r16, 0x01			;row 1
	ldi r17, 0x01			;column 1
	push r16
	push r17
	call lcd_gotoxy
	pop r17
	pop r16

	ldi r16, 'D'
	push r16
	call lcd_putchar	
	pop r16

	call clear_right
	call clear_up
	call clear_left

	rjmp start

put_left:
	ldi r16, 0x01			;row 1
	clr r17					;column 0
	push r16
	push r17
	call lcd_gotoxy
	pop r17
	pop r16

	ldi r16, 'L'
	push r16
	call lcd_putchar	
	pop r16
	
	call clear_right
	call clear_up
	call clear_down

	rjmp start

clear_right:
	ldi r16, 0x01			;row 1
	ldi r17, 0x03			;column 3
	push r16
	push r17
	call lcd_gotoxy
	pop r17
	pop r16

	ldi r16, ' '
	push r16
	call lcd_putchar	
	pop r16
	ret

clear_up:
	ldi r16, 0x01			;row 1
	ldi r17, 0x02			;column 2
	push r16
	push r17
	call lcd_gotoxy
	pop r17
	pop r16

	ldi r16, ' '
	push r16
	call lcd_putchar	
	pop r16
	ret

clear_down:
	ldi r16, 0x01			;row 1
	ldi r17, 0x01			;column 1
	push r16
	push r17
	call lcd_gotoxy
	pop r17
	pop r16

	ldi r16, ' '
	push r16
	call lcd_putchar	
	pop r16
	ret

clear_left:
	ldi r16, 0x01			;row 1
	clr r17					;column 0
	push r16
	push r17
	call lcd_gotoxy
	pop r17
	pop r16

	ldi r16, ' '
	push r16
	call lcd_putchar	
	pop r16
	ret

stop:
	rjmp stop


timer1:
	push r16
	in r16, SREG						;storing status registser
	push r16 

	lds r16, ADCSRA
	ori r16, 0x40						;starting the analog to digital conversion
	sts ADCSRA, r16 

wait:
	lds r16, ADCSRA
	andi r16, 0x40						;waiting for the conversion to finish		
	brne wait

	push r17
	push r18
	push r19

	ldi r16, low(BUTTON_SELECT_ADC)
	ldi r17, high(BUTTON_SELECT_ADC)
	lds r18, ADCL					;why does the program break if we load ADCH before loading in ADCL
	lds r19, ADCH


	cp r16, r18						;branch if BUTTON_SELECT_ADC >= ADC
	cpc r17, r19
	brsh pressed_state

	clr r16							; no button pressed, update BUTTON_IS_PRESSED then exit interrupt
	sts BUTTON_IS_PRESSED, r16

	pop r19
	pop r18
	pop r17
	pop r16
	out SREG, r16
	pop r16
	reti

pressed_state:
	ldi r16, 0x01
	sts BUTTON_IS_PRESSED, r16

	ldi r16, low(BUTTON_RIGHT_ADC)				;checking if right button was pressed
	ldi r17, high(BUTTON_RIGHT_ADC)
	cp r16, r18
	cpc r17, r19
	brsh right_pressed

	ldi r16, low(BUTTON_UP_ADC)					;checking if up button was pressed
	ldi r17, high(BUTTON_UP_ADC)
	cp r16, r18
	cpc r17, r19
	brsh up_pressed
		
	ldi r16, low(BUTTON_DOWN_ADC)				;checking if down button was pressed		
	ldi r17, high(BUTTON_DOWN_ADC)
	cp r16, r18
	cpc r17, r19
	brsh down_pressed

	ldi r16, low(BUTTON_LEFT_ADC)				;checking if left button was pressed		
	ldi r17, high(BUTTON_LEFT_ADC)
	cp r16, r18
	cpc r17, r19
	brsh left_pressed
												;if none of these then the select button was pressed and we exit the loop
												;for LAST_BUTTON_PRESSED 0 = right, 1 = up, 2 = down, 3 = left
	pop r19
	pop r18
	pop r17
	pop r16
	out SREG, r16
	pop r16
	reti

right_pressed:
	ldi r16,'R'
	sts LAST_BUTTON_PRESSED, r16		;JUST STORE THE CHARACTER
	pop r19
	pop r18
	pop r17
	pop r16
	out SREG, r16
	pop r16
	reti

up_pressed:
	ldi r16, 'U'
	sts LAST_BUTTON_PRESSED, r16
	pop r19
	pop r18
	pop r17
	pop r16
	out SREG, r16
	pop r16
	reti

down_pressed:
	ldi r16, 'D'
	sts LAST_BUTTON_PRESSED, r16
	pop r19
	pop r18
	pop r17
	pop r16
	out SREG, r16
	pop r16
	reti

left_pressed:
	ldi r16, 'L'
	sts LAST_BUTTON_PRESSED, r16
	pop r19
	pop r18
	pop r17
	pop r16
	out SREG, r16
	pop r16
	reti

; timer3:
;
; Note: There is no "timer3" interrupt handler as you must use
; timer3 in a polling style (i.e. it is used to drive the refreshing
; of the LCD display, but LCD functions cannot be called/used from
; within an interrupt handler).


timer4:
	reti


; ****************************************************
; ******* END OF SECOND "STUDENT CODE" SECTION *******
; ****************************************************


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================

; r17:r16 -- word 1
; r19:r18 -- word 2
; word 1 < word 2? return -1 in r25
; word 1 > word 2? return 1 in r25
; word 1 == word 2? return 0 in r25
;
compare_words:
	; if high bytes are different, look at lower bytes
	cp r17, r19
	breq compare_words_lower_byte

	; since high bytes are different, use these to
	; determine result
	;
	; if C is set from previous cp, it means r17 < r19
	; 
	; preload r25 with 1 with the assume r17 > r19
	ldi r25, 1
	brcs compare_words_is_less_than
	rjmp compare_words_exit

compare_words_is_less_than:
	ldi r25, -1
	rjmp compare_words_exit

compare_words_lower_byte:
	clr r25
	cp r16, r18
	breq compare_words_exit

	ldi r25, 1
	brcs compare_words_is_less_than  ; re-use what we already wrote...

compare_words_exit:
	ret

.cseg
AVAILABLE_CHARSET: .db "0123456789abcdef_", 0


.dseg

BUTTON_IS_PRESSED: .byte 1			; updated by timer1 interrupt, used by LCD update loop
LAST_BUTTON_PRESSED: .byte 1        ; updated by timer1 interrupt, used by LCD update loop

TOP_LINE_CONTENT: .byte 16			; updated by timer4 interrupt, used by LCD update loop
CURRENT_CHARSET_INDEX: .byte 16		; updated by timer4 interrupt, used by LCD update loop
CURRENT_CHAR_INDEX: .byte 1			; ; updated by timer4 interrupt, used by LCD update loop


; =============================================
; ======= END OF "DO NOT TOUCH" SECTION =======
; =============================================


; ***************************************************
; **** BEGINNING OF THIRD "STUDENT CODE" SECTION ****
; ***************************************************

.dseg

; If you should need additional memory for storage of state,
; then place it within the section. However, the items here
; must not be simply a way to replace or ignore the memory
; locations provided up above.


; ***************************************************
; ******* END OF THIRD "STUDENT CODE" SECTION *******
; ***************************************************
