#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdbool.h>
#include <stdlib.h>
#define F_CPU 16000000UL

int sec = 0;
int score = 0;
int led = 0;

int previous_buttons_pressed = 0b11111111; // Set previous buttons to not pressed
int current_buttons_pressed = 0b11111111; // Set current buttons to not pressed
int previous_E_buttons_pressed = 0b11111111; // Set previous PE5 to not pressed
int current_E_buttons_pressed = 0b11111111; // Set current PE5 to not pressed

bool startup = true;
bool game = false;
bool gameover = false;

ISR(TIMER1_COMPA_vect){	// Every Second the Interrupt Service Routine will be performed
	TCNT1 = 0x00;
	PORTD = 0xFF; // Set PD (LEDs are off)
	
	if(game){
		led = randomLED();
		PORTD ^= (1 << led);           // Turn on the corresponding LED
		sec--;
	}
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

void sound(){
	for(int repeats = 0; repeats < 400; repeats++){
		PORTE ^= 0b00010000;
		sound_delay();
	}
	return;
}

void sound_delay(){
	TCNT0 = 130; // 125 * 64 = 8000
	TCCR0B = 0b00000011; // 64 timer pre-scale
	while(!(TIFR0 << TOV0)){} // Waits 8000 machine cycles for 1000 Hz half wave
	TCCR0B = 0;
	TIFR0 = (1 << TOV0);
	return;
}

int randomLED() {
	int randomNum = rand() % 8;  // Generate a random number between 0 and 7
	return randomNum;
}

void check_buttons(){
	current_buttons_pressed = PINA; // Get current button pressed values
	for(int button_index = 0; button_index < 8; button_index++){
		bool previous_button_pressed = !((previous_buttons_pressed >> button_index) & 0b00000001); // Set to true if was pressed, false if was not pressed
		bool current_button_pressed = !((current_buttons_pressed >> button_index) & 0b00000001); // Set to true if pressed, false if not pressed
		if(previous_button_pressed && !current_button_pressed){
			switch(button_index){
				case 0: // SW1
				sound();
				break;
				
				case 1: // SW2
				sound();
				break;
				
				case 2: // SW3
				sound(); //test
				break;
				
				case 3: // SW4
				sound();
				break;
				
				case 4: // SW6
				sound();
				break;
				
				case 5: // SW7
				sound();
				break;
				
				case 6: // SW8
				sound();
				break;
				
				case 7: // SW9
				sound();
				break;
			}
		}
	}
	
	previous_buttons_pressed = current_buttons_pressed;
	
	current_E_buttons_pressed = PINE;
	int button_index = 6;
	bool previous_button_pressed = !((previous_E_buttons_pressed >> button_index) & 0b00000001); // Set to true if was pressed, false if was not pressed
	bool current_button_pressed = !((current_E_buttons_pressed >> button_index) & 0b00000001); // Set to true if pressed, false if not pressed
	if(previous_button_pressed && !current_button_pressed){ // SW5
		sound();
	}
	previous_E_buttons_pressed = current_E_buttons_pressed;
}

void start_up(){
	while(startup){
		if(~PINA & (1<<PINA0)){			// If SW1 is pressed, start the game
			while(~PINA & (1<<PINA0));
			sei();
			timer1_start();
			sec = 30;
			PORTD = 0xFF; // Set PD (LEDs are off)
			startup = false;
			game = true;
		}
	}
}

void gameplay(){
    while (game) {
		if(~PINA & (1<<led)){			// If correct button is pressed, score += 1
			while(~PINA & (1<<led));
			score += 1;
			PORTD = 0xFF; // Set PD (LEDs are off)
			sound();
		}
		
	    if(sec == 0){	// After 30 Seconds, game is finished
		    PORTD = 0x00;	// Clear PD (LEDs are on)
		    sound();
		    game = false;
			gameover = true;
	    }
    }
}

void game_over(){
	while (gameover){
		
		timer1_stop();
		
		///////////////////
		// Display Score //
		///////////////////
		
	}
}

int main(void) {
	DDRA = 0x00; // Configure all PA bits to receive input from buttons
	PORTA = 0xFF; // Enable pull-up for PA
	
	DDRE |= 0b00010000; // Set PE4 to send output to speaker
	PORTE &= 0b11101111; // Clear PE4
	
	DDRD = 0xFF; // Configure all PD bits to send output to LED's
	PORTD = 0x00; // Clear PD (LEDs are on)
	
	timer_init_ctc();
	
	start_up();
	gameplay();
	game_over();

	return 0;
}













/* 
#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdbool.h>
#define F_CPU 16000000UL

int sec = 0;
int game_score = 0;
int previous_buttons_pressed = 0b11111111; // Set previous buttons to not pressed
int current_buttons_pressed = 0b11111111; // Set current buttons to not pressed
int previous_E_buttons_pressed = 0b11111111; // Set previous PE5 to not pressed
int current_E_buttons_pressed = 0b11111111; // Set current PE5 to not pressed

bool startup = true;
bool game = false;

ISR(TIMER1_COMPA_vect){	// Every Second the Interrupt Service Routine will be performed
	TCNT1 = 0x00;
	if(game)
	{
		sec--;
		// Pseudo-randomly generate a number from 1-6:
		//	1 corresponds to SW1 (PA0) and LED1 (PD0)
		//	2 corresponds to SW2 (PA1) and LED2 (PD1)
		//  3 corresponds to SW3 (PA2) and LED3 (PD2)
		//	4 corresponds to SW7 (PA5) and LED7 (PD5)
		//	5 corresponds to SW8 (PA6) and LED8 (PD6)
		//	6 corresponds to SW9 (PA7) and LED9 (PD7)
		// During the game, a new number will be chosen each second - the number must be different from the previous number (keep choosing new numbers until different from previous)
		// When a number is chosen, the corresponding LED will light up
		// If the corresponding button is pressed before the next number is chosen, the score will increment, the LED will turn off, and a happy sound will play
		//		- nothing else will happen until the next number is chosen
		// If the corresponding button is not pressed before the next number is chosen, the LED will turn off and an unpleasant sound will play
	}
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

void sound(){
	for(int repeats = 0; repeats < 400; repeats++){
		PORTE ^= 0b00010000;
		sound_delay();
	}
	return;
}

void sound_delay(){
	TCNT0 = 130; // 125 * 64 = 8000
	TCCR0B = 0b00000011; // 64 timer pre-scale
	while(!(TIFR0 << TOV0)){} // Waits 8000 machine cycles for 1000 Hz half wave
	TCCR0B = 0;
	TIFR0 = (1 << TOV0);
	return;
}

void check_buttons(){
	current_buttons_pressed = PINA; // Get current button pressed values
	for(int button_index = 0; button_index < 8; button_index++){
		bool previous_button_pressed = !((previous_buttons_pressed >> button_index) & 0b00000001); // Set to true if was pressed, false if was not pressed
		bool current_button_pressed = !((current_buttons_pressed >> button_index) & 0b00000001); // Set to true if pressed, false if not pressed
		if(previous_button_pressed && !current_button_pressed){
			switch(button_index){
				case 0: // SW1
				if(startup){
					start_game();
				}
				sound();
				break;
				
				case 1: // SW2
				sound();
				game_score++;
				break;
				
				case 2: // SW3
				sound(); //test
				break;
				
				case 3: // SW4
				sound();
				break;
				
				case 4: // SW6
				sound();
				break;
				
				case 5: // SW7
				break;
				
				case 6: // SW8
				break;
				
				case 7: // SW9
				break;
			}
		}
	}
	
	previous_buttons_pressed = current_buttons_pressed;
	
	current_E_buttons_pressed = PINE;
	int button_index = 6;
	bool previous_button_pressed = !((previous_E_buttons_pressed >> button_index) & 0b00000001); // Set to true if was pressed, false if was not pressed
	bool current_button_pressed = !((current_E_buttons_pressed >> button_index) & 0b00000001); // Set to true if pressed, false if not pressed
	if(previous_button_pressed && !current_button_pressed){ // SW5
		sound();
	}
	previous_E_buttons_pressed = current_E_buttons_pressed;
}

void start_game(){ // If SW1 is pressed during start mode, start the game
	sec = 5; // 30 second game is eventually planned, but 5 is easier for testing
	PORTD = 0xFF; // Set PD (LEDs are off)
	startup = false;
	game = true;
}

void end_game(){
	PORTD = game_score ^ 0b11111111; // Set PD to display score
	game_score = 0;
	startup = true;
	game = false;
	sound();
}

void start_update(){ // Conducts any main-loop updates during start mode
	check_buttons();
} 

void game_update(){ // Conducts any main-loop updates during game mode
	check_buttons();
	if(sec == 0) end_game(); // After 30 Seconds, game is finished
}

int main(void)
{
	DDRA = 0x00; // Configure all PA bits to receive input from buttons
	PORTA = 0xFF; // Enable pull-up for PA
	
	DDRE |= 0b00010000; // Set PE4 to send output to speaker
	PORTE &= 0b11101111; // Clear PE4
	
	DDRD = 0xFF; // Configure all PD bits to send output to LED's
	PORTD = 0x00; // Clear PD (LEDs are on)
	
	timer_init_ctc();
	sei();
	timer1_start();

	while(1){
		if(startup) start_update();
		if (game) game_update();
	}
	return 0;
}

*/