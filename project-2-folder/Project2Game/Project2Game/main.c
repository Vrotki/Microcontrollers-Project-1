#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdbool.h>
#include <stdlib.h>
#define F_CPU 16000000UL

int sec = 0;
int score = 0;
int led = 0;
int highscore = 0;
int streak = 0;

bool startup = true;
bool game = false;
bool gameover = false;

ISR(TIMER1_COMPA_vect){	// Every Second the Interrupt Service Routine will be performed
	TCNT1 = 0x00;
	
	if(game){
		if(led != -1){
			streak = 0;
		}
		led = randomLED();
		PORTD = 0xFF ^ (1 << led); // Turn on the corresponding LED       
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


//repeats are 1/2 for 500Hz
void incorrect_sound(){
	for(int repeats = 0; repeats < 200; repeats++){
		PORTE ^= 0b00010000;
		incorrect_sound_delay();
	}
	return;
}

//should delay for 500Hz sound
void incorrect_sound_delay(){
	TCNT0 = 5; // 125 * 64 = 8000, 255 - 250 = 5
	TCCR0B = 0b00000011; // 64 timer pre-scale
	while(!(TIFR0 << TOV0)){} // Waits 8000 machine cycle
	TCCR0B = 0;
	TIFR0 = (1 << TOV0);
	return;
}

void sound(){
	for(int repeats = 0; repeats < 400; repeats++){
		PORTE ^= 0b00010000;
		sound_delay();
	}
	return;
}

void new_highscore_sound() {

	for(int repeats = 0; repeats < 3000; repeats++){
		PORTE ^= 0b00010000;
		sound_delay();
	}
	return;

}

void streak_sound(){
	for(int repeats = 0; repeats < 50; repeats++){
		PORTE ^= 0b00010000;
		sound_delay();
	}
	return;
}

void sound_delay(){
	TCNT0 = 130; // 125 * 64 = 8000, 255 - 125 = 130
	TCCR0B = 0b00000011; // 64 timer pre-scale
	while(!(TIFR0 << TOV0)){} // Waits 8000 machine cycles for 1000 Hz half wave
	TCCR0B = 0;
	TIFR0 = (1 << TOV0);
	return;
}

int randomLED() {
	int randomNum = led;
	while(randomNum == led){ // If last LED was not scored, LED should be distinct from the previous LED
							 // At start of game, led == 0, preventing pressing the start button from giving a point
							 // If an LED is scored, it turns off and led is set to -1, so it is allowed to be the next LED
		randomNum = rand() % 6;  // Generate a random number between 0 and 5
		// 0, 1, 2, 5, 6, and 7 correspond to LED's that have corresponding buttons - should only return these numbers
		// Can achieve by generating number from 0 to 5 and adding 2 to any results >= 3
		if(randomNum >= 3) randomNum += 2;
	}
	return randomNum;
}

void start_up(){
	startup = true;
	int rand_seed = 0;
	
	
	while(startup){
		rand_seed++;
		rand_seed %= 100000; // Random seed will be a pseudo-random number from 0-99999 based on how many loops occur before the game starts

		//if user presses button for highscore
		if(~PINE & (1<<PINE6)){
			PORTD = highscore ^ 0xFF; //display highscore
		}

		if(~PINA & (1<<PINA0)){			// If SW1 is pressed, start the game
		
			sound();
			incorrect_sound();
			sound(); //plays series of tones to start up game

			while(~PINA & (1<<PINA0));
			srand(rand_seed);
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
		if((~PINA & (1<<led)) && (led != -1)){            // If correct button is pressed, score += 1
			while(~PINA & (1<<led));
			streak += 1;
			score += 1;
			led = -1; // Prevent further scoring until new LED starts
			PORTD = 0xFF; // Set PD (LEDs are off)
			if(streak > 4)
			{
				for(int i = 0; i < streak; i++)
				{
					streak_sound();
				}
			}
			else
			{
				sound();
			}

		}
		else if((PINA | (0b00011000 | (1 << led))) != 0b11111111)//((PINA | 0b00011000) != 0b11111111) // If any incorrect LED button pressed, play incorrect sound
		{
			while((PINA | (0b00011000 | (1 << led))) != 0b11111111);
			streak = 0;
			incorrect_sound();
		}
		if((~PINA & (1<<PINA3)) ){            // If correct button is pressed, score += 1
			while(~PINA & (1<<PINA3));
			return;
		}
	    if(sec <= 0){	// After 30 Seconds, game is finished
		    PORTD = 0x00;	// Clear PD (LEDs are on)
		    sound();
		    game = false;
		    gameover = true;
	    }
	}
}

void game_over(){
	timer1_stop();
	
	incorrect_sound();
	sound();
	incorrect_sound(); //plays series of tones to end game
	
	PORTD = score ^ 0xFF; // Display score
	//if score is higher than high score set highscore to new score
	if (score > highscore)
	{
		highscore = score;
		new_highscore_sound();
	}
	score = 0;
	led = 0; // Reset LED to default value
}

int main(void) {
	DDRA = 0x00; // Configure all PA bits to receive input from buttons
	PORTA = 0xFF; // Enable pull-up for PA

	DDRE &= ~(1 << PINE6); // Configure PE6 to receive input from SW5
	PORTE |= (1 << PORTE6); // Enable pull-up for PE6
	
	DDRE |= 0b00010000; // Set PE4 to send output to speaker
	PORTE &= 0b11101111; // Clear PE4
	
	DDRD = 0xFF; // Configure all PD bits to send output to LED's
	PORTD = 0x00; // Clear PD (LEDs are on)

	timer_init_ctc();
	
	while(1){
		start_up();
		gameplay();
		game_over();
	}

	return 0;
}