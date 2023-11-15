/*
 * Project2Game.c
 *
 * Created: 11/15/2023 2:30:41 PM
 * Author : vikto
 */ 

#include <avr/io.h>
#include <avr/interrupt.h>
#define F_CPU 16000000UL
#include "util/delay.h"

int sec = 5;

ISR(TIMER1_COMPA_vect){		//Every Second the Interrupt Service Routine will be performed
	TCNT1 = 0x00;
	sec--;
}

void timer_init_ctc(){
	TCCR1A = 0x00;
	TCCR1B |= 0x00 | (1 << WGM13) | (1 << WGM12);
	TCNT1 |= 0x00;
	TIMSK1 |= (1 << OCIE1A);
	OCR1A = 0xF424;				//Pre-Scaler for 1 second intervals
}

void timer1_start(){
	TCCR1B |= (1 << CS12);
}

void timer1_stop(){
	TCCR1B &= ~( (1 << CS12) | (1 << CS11) | (1 << CS10));
}


int main(void)
{
	DDRD = 0xFF;
	PORTD = 0x00;
	
	timer_init_ctc();
	sei();
	timer1_start();
	
    while (1) {
		if(sec <= 0){
			timer1_stop();
			PORTD = 0xFF;
		}
    }
}

