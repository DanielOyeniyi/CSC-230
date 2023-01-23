/* a4.c
 * CSC Fall 2022
 * 
 * Student name: Daniel Oyeniyi
 * Student UVic ID: v00937920
 * Date of completed work: 12/1/2022
 *
 *
 * Code provided for Assignment #4
 *
 * Author: Mike Zastre (2022-Nov-22)
 *
 * This skeleton of a C language program is provided to help you
 * begin the programming tasks for A#4. As with the previous
 * assignments, there are "DO NOT TOUCH" sections. You are *not* to
 * modify the lines within these section.
 *
 * You are also NOT to introduce any new program-or file-scope
 * variables (i.e., ALL of your variables must be local variables).
 * YOU MAY, however, read from and write to the existing program- and
 * file-scope variables. Note: "global" variables are program-
 * and file-scope variables.
 *
 * UNAPPROVED CHANGES to "DO NOT TOUCH" sections could result in
 * either incorrect code execution during assignment evaluation, or
 * perhaps even code that cannot be compiled.  The resulting mark may
 * be zero.
 */


/* =============================================
 * ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
 * =============================================
 */

#define __DELAY_BACKWARD_COMPATIBLE__ 1
#define F_CPU 16000000UL

#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>

#define DELAY1 0.000001
#define DELAY3 0.01

#define PRESCALE_DIV1 8
#define PRESCALE_DIV3 64
#define TOP1 ((int)(0.5 + (F_CPU/PRESCALE_DIV1*DELAY1))) 
#define TOP3 ((int)(0.5 + (F_CPU/PRESCALE_DIV3*DELAY3)))

#define PWM_PERIOD ((long int)500)

volatile long int count = 0;
volatile long int slow_count = 0;


ISR(TIMER1_COMPA_vect) {
	count++;
}


ISR(TIMER3_COMPA_vect) {
	slow_count += 5;
}

/* =======================================
 * ==== END OF "DO NOT TOUCH" SECTION ====
 * =======================================
 */


/* *********************************************
 * **** BEGINNING OF "STUDENT CODE" SECTION ****
 * *********************************************
 */

void led_state(uint8_t LED, uint8_t state) {
	DDRL = 0xff;				
	uint8_t mask = 0x2;			//mask for PLB1/LED0
	switch(LED) {
		case 3:							// PLB1 or LED3, do nothing in this case
			break;			
		case 2:
			mask = mask << 2;			//PLB3 or LED2
			break;		
		case 1:
			mask = mask << 4;			//PLB5 or LED1
			break;
		default:						//PLB7 or LED0
			mask = mask << 6;
			break;
	}
	if(state) {
		PORTL |= mask;
	} else {
		PORTL &= ~(mask);
	}
}



void SOS() {
    uint8_t light[] = {
        0x1, 0, 0x1, 0, 0x1, 0,
        0xf, 0, 0xf, 0, 0xf, 0,
        0x1, 0, 0x1, 0, 0x1, 0,
        0x0
    };

    int duration[] = {
        100, 250, 100, 250, 100, 500,
        250, 250, 250, 250, 250, 500,
        100, 250, 100, 250, 100, 250,
        250
    };

	int length = 19;
	
	for (int i = 0; i<length; i++){
		uint8_t tmp = light[i];
		uint8_t mask = 0x1;	
		tmp &= mask;						//LED0
		led_state(0,tmp);
		
		tmp = light[i];						//LED1
		tmp = tmp >> 1; 
		tmp &= mask;
		led_state(1,tmp);
		
		tmp = light[i];						//LED2
		tmp = tmp >> 2;
		tmp &= mask;
		led_state(2,tmp);		
		
		tmp = light[i];						//LED3
		tmp = tmp >> 3;
		tmp &= mask;
		led_state(3,tmp);
		
		_delay_ms(duration[i]);		//adding duration
	}
}


void glow(uint8_t LED, float brightness) {
	for (;;) {
		float threshold = PWM_PERIOD * brightness;           //referenced directly from assignment right up     
		if (count < threshold) {							//did not check if led was already on or off as it broke the code...
			led_state(LED,1);								//it 'should' have minimal impact on the codes efficiency 
			} else if (count < PWM_PERIOD) {
			led_state(LED,0);
			} else {
			count = 0;
			led_state(LED,0);								//turned the led off instead otherwise the led doesn't turn off when brightness is 0
		}
	}
}

void pulse_glow(uint8_t LED) {
	uint8_t state = 0x0;					// state 1 means we increased brightness, state 0 means we decrease brightness
	float brightness = 0;
	int speed = 5000;
	for (;;) {
		if (slow_count >= speed) {
			slow_count = 0;
			state = ~(state);
		}
		if (!state) {
			brightness = slow_count;
		}else {
			brightness = speed - slow_count;
		}
		
		float threshold = PWM_PERIOD * brightness/speed;    //10 milliseconds is a 10000 micro seconds
		if (count < threshold) {							//used this fact to help find the speed
			led_state(LED,1);
			} else if (count < PWM_PERIOD) {
			led_state(LED,0);
			} else {
			count = 0;
			led_state(LED,0);
		}
	
	}
}


void light_show() {
    uint8_t light[] = {
		0xf, 0, 0xf, 0, 0xf, 0,
		0x6, 0, 0x9, 0, 
		0xf, 0, 0xf, 0, 0xf, 0,
		0x6, 0, 0x9, 0, 
		0x8, 0xc, 0x6, 0x3, 0x1, 
		0x1, 0x3, 0x6, 0xc, 0x8,
		0x8, 0xc, 0x6, 0x3, 0x1,
		0x1, 0x3, 0x6, 0,
		0xf, 0, 0xf, 0,
		0x6, 0, 0x6, 0
    };

    int duration[] = {
	    100, 250, 100, 250, 100, 250,
		100, 100, 100, 100, 
	    100, 250, 100, 250, 100, 250,
		100, 100, 100, 100, 
		75, 75, 75, 75, 75,
		75, 75, 75, 75, 75,
		75, 75, 75, 75, 75,
		75, 75, 75, 250,
		100, 250, 100, 250,
		250, 100, 250 ,100
    };

    int length = 47;
    
    for (int i = 0; i<length; i++){
	    uint8_t tmp = light[i];
	    uint8_t mask = 0x1;
	    tmp &= mask;						//LED0
	    led_state(0,tmp);
	    
	    tmp = light[i];						//LED1
	    tmp = tmp >> 1;
	    tmp &= mask;
	    led_state(1,tmp);
	    
	    tmp = light[i];						//LED2
	    tmp = tmp >> 2;
	    tmp &= mask;
	    led_state(2,tmp);
	    
	    tmp = light[i];						//LED3
	    tmp = tmp >> 3;
	    tmp &= mask;
	    led_state(3,tmp);
	    
	    _delay_ms(duration[i]);		//adding duration
    }
}


/* ***************************************************
 * **** END OF FIRST "STUDENT CODE" SECTION **********
 * ***************************************************
 */


/* =============================================
 * ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
 * =============================================
 */

int main() {
    /* Turn off global interrupts while setting up timers. */

	cli();

	/* Set up timer 1, i.e., an interrupt every 1 microsecond. */
	OCR1A = TOP1;
	TCCR1A = 0;
	TCCR1B = 0;
	TCCR1B |= (1 << WGM12);
    /* Next two lines provide a prescaler value of 8. */
	TCCR1B |= (1 << CS11);
	TCCR1B |= (1 << CS10);
	TIMSK1 |= (1 << OCIE1A);

	/* Set up timer 3, i.e., an interrupt every 10 milliseconds. */
	OCR3A = TOP3;
	TCCR3A = 0;
	TCCR3B = 0;
	TCCR3B |= (1 << WGM32);
    /* Next line provides a prescaler value of 64. */
	TCCR3B |= (1 << CS31);
	TIMSK3 |= (1 << OCIE3A);


	/* Turn on global interrupts */
	sei();

/* =======================================
 * ==== END OF "DO NOT TOUCH" SECTION ====
 * =======================================
 */


/* *********************************************
 * **** BEGINNING OF "STUDENT CODE" SECTION ****
 * *********************************************
 */

/* This code could be used to test your work for part A.*/
/*
	led_state(0, 1);
	_delay_ms(1000);
	led_state(2, 1);
	_delay_ms(1000);
	led_state(1, 1);
	_delay_ms(1000);
	led_state(2, 0);
	_delay_ms(1000);
	led_state(0, 0);
	_delay_ms(1000);
	led_state(1, 0);
	_delay_ms(1000);
 */

/* This code could be used to test your work for part B.*/

/*

	SOS();
*/

/* This code could be used to test your work for part C.*/

	//glow(1, 0.7);
 /*/



/* This code could be used to test your work for part D.*/
//*
	//pulse_glow(2);
 
/*/

/* This code could be used to test your work for the bonus part.*/

	//light_show();
 /*/

/* ****************************************************
 * **** END OF SECOND "STUDENT CODE" SECTION **********
 * ****************************************************
 */
}
