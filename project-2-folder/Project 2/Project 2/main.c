#include <avr/io.h>
#include <avr/interrupt.h>
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
			if(previous_button_pressed && !current_button_pressed){
				switch(button_index){
					case 0: 
						inc_count();
						break;
					case 1:
						dec_count();
						break;
					// Add a new case statement corresponding with the button's input pin to implement any other buttons
				}
			}
		}
		previous_buttons_pressed = current_buttons_pressed;
		PORTD = count ^ 0xFF; // Output complement of counter to LED's
    }
}

void inc_count(){
	count += 1;
	button_delay();
	return;
}

void dec_count(){
	count -= 1;
	button_delay();
	return;
}

void button_delay(){
	for(int a = 0; a < 10; a++){
		for(int b = 0; b < 255; b++){
			for(int c = 0; c < 255; c++){
				int delay = 10;
				delay += 1;
				delay += 1;
			}
		}
	}
	return;
}

