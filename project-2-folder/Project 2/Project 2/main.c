#include <avr/io.h>
#include <avr/interrupt.h>

int main(void)
{
	DDRD = 0xFF;
	int count;
	count = 10;
    while (1) 
    {
		PORTD = count ^ 0xFF; // Output complement of counter to LED's
    }
}

