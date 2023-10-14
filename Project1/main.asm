start:
	.ORG 0
	.EQU COUNT = 0
	LDI R16, COUNT
	;button 1 sends input to PA0, active low
	;button 2 sends input to PA1, active low
	;PE4 sends output to speaker, active high(?)
	;LED's can be in 3x3 or 2x4 pattern, based on a switch on the board
	; - if using 2x4, PD0 goes to LED1, PD1 goes to LED2, PD2 goes to LED3, PD3 goes to LED4B, and PD4 goes to LED6B

	;configure PA0 and PA1 to take input from buttons, with pull-up enabled
	CBI DDRA, 0; set PA0 to input
	SBI PORTA, 0; pull-up PA0

	CBI DDRA, 1; set PA1 to input
	SBI PORTA, 1; pull-up PA1

	;configure PE4 to send output to speaker
	SBI DDRE, 4; set PE4 to output
	CBI PORTE, 4; clear PE4

	;configure all PD bits to send output to LED's
	LDI R17, 0b11111111
	OUT DDRD, R17; set all PD bits to output
	OUT PORTD, R16; set PORTD to initial count

	LDI R18, 0b11111111; set previous buttons to not pressed
	LDI R19, 0b11111111; set current buttons to not pressed

	MAIN_LOOP:
		MOV R20, R18; copies previous buttons pressed values to R20 for comparison
		IN R19, PINA; set R19 to current buttons pressed
		MOV R21, R19; copies current buttons pressed values to R21 for comparison
		
		;monitor PINC, 0 - if bit was 0 and is now 1, positive key was just released and the counter should be incremented, returning to 0 if passing 30
		LSR R20; shifts positive key previous pressed to carry bit
		BRLO POSITIVE_NOT_RELEASED; branch if c == 1 - skip if button was not being pressed
		LSR R21; shifts positive key current pressed to carry bit
		BRSH POSITIVE_NOT_RELEASED; branch if c == 0 - skip if button is still being pressed
		
		CALL INC_COUNT; increment if button was being pressed and is no longer being pressed
		POSITIVE_NOT_RELEASED:

		;monitor PINC, 1 - if bit was 0 and is now 1, negative key was just released and the counter should be decremented, returning to 30 if passing 0
		LSR R20; shifts negative key previous pressed to carry bit
		BRLO NEGATIVE_NOT_RELEASED; branch if c == 1 - skip if button was not being pressed
		LSR R21; shifts negative key current pressed to carry bit
		BRSH NEGATIVE_NOT_RELEASED; branch if c == 0 - skip if button is still being pressed
		
		CALL DEC_COUNT; decrement if button was being pressed and is no longer being pressed
		NEGATIVE_NOT_RELEASED:

		MOV R18, R19; moves current buttons pressed to previous buttons pressed

		;if counter moved past 0 or 30, send 1000 HZ square wave to PE4 for some amount of time

		;display LED's for 000xxxxx counter value by setting PORTD to the counter value
		OUT PORTD, R16

		RJMP MAIN_LOOP

.ORG 400
INC_COUNT: RET

.ORG 500
DEC_COUNT: RET

.ORG 0x600
Delay: LDI R23, 250       ;8004 MCs 1 + 250(1 + 7(1 + 1 + 2) - 1 + 1 + 1 + 2) - 1 + 4   
	Loop1: LDI R24, 7		
		Loop2:	NOP			 
			DEC R23
			BRNE Loop2
		NOP
		DEC R24
		BRNE Loop1
	RET

; For your first project, you will design a simple, self-contained AVR-based device (Simon Board) that will, at a minimum, monitor two keys – one is a positive key that
; increments the counter, and the other is a negative key that decrements the counter; display the current count in binary on a set of 5 LEDs; and sound an alarm when
; the count “turns over” (cycles from a binary 30 to 0 or 0 to 30). The counter should be 0 initially.
