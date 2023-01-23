;
; a3part-C.asm
;
; Part C of assignment #3
;
;
; Student name: Daniel Oyeniyi
; Student ID: V00937920
; Date of completed work: 11/20/2022 
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

ldi r16, low(RAMEND)						;initializing the stack pointer
out SPL, r16
ldi r16, high(RAMEND)
out SPH, r16	
rcall lcd_init								;clearing the lcd screen
clr r16
sts CURRENT_CHAR_INDEX, r16					;initializing the character index

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
	ldi XL, low(TOP_LINE_CONTENT)					
	ldi XH, high(TOP_LINE_CONTENT)

	ldi YL, low(CURRENT_CHARSET_INDEX)
	ldi YH, high(CURRENT_CHARSET_INDEX)
	ldi r17,0x10									; set so we loop through 16 times
	rjmp top_line_init

top_line_init:										
	cpi r17, 0x00									
	breq timer3 

	ldi r16, ' '
	st X+, r16

	ldi r16, 0xff									;initializes the top lcd's to ' ' and all character set indexes to -1 or 0xff (8 bit 2's)
	st Y+, r16										;this is so that when up is the first button pressed it starts at index 0

	dec r17
	rjmp top_line_init

timer3:
	in r16, TIFR3									;we use in because TIFR3 is refering to a memory adress. ldi still compiles but causes error
	sbrs r16, OCF3A									;checking if the timer has reached the top value
	rjmp timer3

	ldi r16, 1<<OCF3A								;reseting timer 3
	out TIFR3, r16

	lds r16, BUTTON_IS_PRESSED						;checking if a button is pressed
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

	rjmp timer3

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

	ldi r16, 0x00			;row 0
	ldi r17, 0x00			;column 0
	push r16
	push r17
	call lcd_gotoxy
	pop r17
	pop r16

	ldi XL, low(TOP_LINE_CONTENT)
	ldi XH, high(TOP_LINE_CONTENT)
	ldi r17,0x10
	rjmp put_top_line

put_top_line:
	cpi r17, 0x00
	breq put_bottom_line				;reading the TOP_LINE_CONTENT and storing it in the lcd

	ld r16, X+
	
	push r16
	call lcd_putchar	
	pop r16

	dec r17
	rjmp put_top_line

put_bottom_line:
	lds r18, LAST_BUTTON_PRESSED		;Putting the last button pressed on the screen, does nothing if select button was pressed
										
	cpi r18, 'R'
	breq put_right

	cpi r18, 'U'
	breq put_up

	cpi r18, 'D'
	breq put_down

	cpi r18, 'L'
	breq put_left				
														
	rjmp timer3

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

	rjmp timer3

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

	rjmp timer3

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
	rjmp timer3

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

	rjmp timer3

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
rjmp timer1_exit

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
	ldi r16,'S'
	sts LAST_BUTTON_PRESSED, r16		
	rjmp timer1_exit

right_pressed:									;update LAST_BUTTON_PRESSED with... last button pressed
	ldi r16,'R'
	sts LAST_BUTTON_PRESSED, r16		
	rjmp timer1_exit

up_pressed:
	ldi r16, 'U'
	sts LAST_BUTTON_PRESSED, r16
	rjmp timer1_exit

down_pressed:
	ldi r16, 'D'
	sts LAST_BUTTON_PRESSED, r16
	rjmp timer1_exit

left_pressed:
	ldi r16, 'L'
	sts LAST_BUTTON_PRESSED, r16
	rjmp timer1_exit

timer1_exit:
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
	push r16 
	in r16, SREG
	push r16
	push r17
	push r26
	push r27
	push r28
	push r29
	push r30
	push r31

	lds r16, LAST_BUTTON_PRESSED						;checking which button was pressed so it can do respective action
	lds r17, CURRENT_CHAR_INDEX

	;cpi r16, 'R'
	;breq is_right_valid

	;cpi r16, 'L'
	;breq is_left_valid

	ldi XL, low(TOP_LINE_CONTENT)
	ldi XH, high(TOP_LINE_CONTENT)

	ldi YL, low(CURRENT_CHARSET_INDEX)
	ldi YH, high(CURRENT_CHARSET_INDEX)					;stores the the charset val at an index

	ldi ZL, low(AVAILABLE_CHARSET<<1)
	ldi ZH, high(AVAILABLE_CHARSET<<1)
	
	cpi r16, 'U'
	breq is_up_valid

	cpi r16, 'D'
	breq is_down_valid

	rjmp timer4_exit
	
is_right_valid:										;if right is at the end of the lcd screen do nothing, else increment char index
	cpi r17, 0x0f
	brne inc_char_index
	rjmp timer4_exit

is_left_valid:										;if left is at the end of the lcd screen do nothing, else decrement char index
	cpi r17, 0x00
	brne dec_char_index
	rjmp timer4_exit

inc_char_index:
	inc r17
	sts CURRENT_CHAR_INDEX, r17
	rjmp timer4_exit

dec_char_index:
	dec r17
	sts CURRENT_CHAR_INDEX, r17
	rjmp timer4_exit

is_up_valid:
	clr r16
	add XL, r17
	adc XH, r16								;setting TOP_LINE_CONTENT and CURRENT_CHARSET_INDEX to the correct index
	
	add YL, r17
	adc	YH, r16

	ld r17, Y								;getting the current index for AVAILABLE_CHARSET
	inc r17

	add ZL, r17								
	adc ZH, r16
	
	lpm r16, Z
	cpi r16, 0x00							;if the next character is a null pointer then exit the loop
	breq timer4_exit						;else store the character into TOP_LINE_CONTENT
										
	st Y, r17
	st X, r16
	rjmp timer4_exit

is_down_valid:
	clr r16
	add XL, r17
	adc XH, r16

	add YL, r17
	adc YH, r16

	ld r17, Y
	
	cpi r17, 0xff							;if it's the first time the char index is being accessed set it to 0 
	breq is_first_press						;again charset indexes are 0xff by default so that that when up is pressed it goes to 0

	add ZL, r17
	adc ZH, r16
	lpm r16, Z
	st X, r16

	cpi r17, 0x00							;if the charset index is 0 do nothing, else decrement
	breq timer4_exit

	sbiw ZH:ZL, 1
	lpm r16, Z
	st X, r16

	dec r17
	st Y, r17
	rjmp timer4_exit

is_first_press:
	inc r17
	st Y, r17
	lpm r16, Z
	st X, r16
	rjmp timer4_exit



timer4_exit:
	pop r31								
	pop r30
	pop r29
	pop r28
	pop r27
	pop r26
	pop r17
	pop r16
	out SREG, r16
	pop r16
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
