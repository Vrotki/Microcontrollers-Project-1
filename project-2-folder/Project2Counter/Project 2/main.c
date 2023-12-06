#include <avr/io.h>
#include <stdbool.h>

int count;

int main(void)
{
	count = 0;
	int previous_buttons_pressed = 0b11111111; // Set previous buttons to not pressed
	int current_buttons_pressed = 0b11111111; // Set current buttons to not pressed

	DDRA = 0x00; // Configure all PA bits to receive input from buttons
	PORTA = 0xFF; // Enable pull-up for PA
	DDRE |= 0b00010000; // Set PE4 to send output to speaker
	PORTE &= 0b11101111; // Clear PE4
	DDRD = 0xFF; // Configure all PD bits to send output to LED's

    while (1)
    {
		current_buttons_pressed = PINA; // Get current button pressed values
		for(int button_index = 0; button_index < 8; button_index++){
			bool previous_button_pressed = !((previous_buttons_pressed >> button_index) & 0b00000001); // Set to true if was pressed, false if was not pressed
			bool current_button_pressed = !((current_buttons_pressed >> button_index) & 0b00000001); // Set to true if pressed, false if not pressed
			if(previous_button_pressed && !current_button_pressed){ // If button was pressed and is now released, call the corresponding button handling code
				switch(button_index){
					case 0:
						inc_count();
						break;
					case 1:
						dec_count();
						break;
				}
			}
		}
		previous_buttons_pressed = current_buttons_pressed;
		PORTD = count ^ 0xFF; // Output complement of counter to LED's
    }
}

void inc_count(){
	count += 1;
	if(count > 30){
		count = 0;
		overflow_sound();
	}
	button_delay();
	return;
}

void dec_count(){
	count -= 1;
	if(count < 0){
		count = 30;
		overflow_sound();
	}
	button_delay();
	return;
}

void overflow_sound(){
	for(int repeats = 0; repeats < 800; repeats++){
		PORTE ^= 0b00010000; // Repeatedly complement PE4 to create sound square wave
		sound_delay(); // Delay to create 1000 Hz frequency
	}
	return;
}

void sound_delay(){
	TCNT0 = 130; // 125 * 64 = 8000, 255 - 125 = 130
	TCCR0B = 0b00000011; // 64 timer pre-scale
	while(!(TIFR0 << TOV0)){} // Wait 8000 machine cycles for 1000 Hz half wave
	TCCR0B = 0;
	TIFR0 = (1 << TOV0); // Reset timer after completion
	return;
}

void button_delay(){
	for(int i = 0; i < 10; i++) { // Repeat 10 times
		TCNT0 = 0; // 255 * 1024 = 261120
		TCCR0B = 0b00000101; // 1024 timer pre-scale
		while(!(TIFR0 << TOV0)){} // Wait 261120 machine cycles for button press
		TCCR0B = 0;
		TIFR0 = (1 << TOV0); // Reset timer after completion
	}
	return;
}

