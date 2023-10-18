start:
	.ORG 0
	;button 1 sends input to PA0, active low
	;button 2 sends input to PA1, active low
	;PE4 sends output to speaker, active high(?)
	;LED's can be in 3x3 or 2x4 pattern, based on a switch on the board
	; - if using 2x4, PD0 goes to LED1, PD1 goes to LED2, PD2 goes to LED3, PD3 goes to LED4B, and PD4 goes to LED6B

	LDI R16, 0; counter
	;configure PA0 and PA1 to take input from buttons, with pull-up enabled
	LDI R17, 0x00
	OUT DDRA, R17; set PA to input
	LDI R17, 0xFF
	OUT PORTA, R17; pull-up PA

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

		;monitor PINA, 0 - if bit was 0 and is now 1, positive key was just released and the counter should be incremented, returning to 0 if passing 30
		LSR R20; shifts positive key previous pressed to carry bit
		BRLO FINISH_POSITIVE_SHIFT; branch if c == 1 - skip if button was not being pressed
		LSR R21; shifts positive key current pressed to carry bit
		BRSH POSITIVE_NOT_RELEASED; branch if c == 0 - skip if button is still being pressed
		CALL INC_COUNT; increment if button was being pressed and is no longer being pressed
		POSITIVE_NOT_RELEASED:

		;monitor PINA, 1 - if bit was 0 and is now 1, negative key was just released and the counter should be decremented, returning to 30 if passing 0
		LSR R20; shifts negative key previous pressed to carry bit
		BRLO FINISH_NEGATIVE_SHIFT; branch if c == 1 - skip if button was not being pressed
								  ; while DEC_COUNT needs to be skipped, subsequent buttons will only work if R21 is also shifted
		LSR R21; shifts negative key current pressed to carry bit
		BRSH NEGATIVE_NOT_RELEASED; branch if c == 0 - skip if button is still being pressed
		
		CALL DEC_COUNT; decrement if button was being pressed and is no longer being pressed
		NEGATIVE_NOT_RELEASED:

		MOV R18, R19; moves current buttons pressed to previous buttons pressed

		;if counter moved past 0 or 30, send 1000 HZ square wave to PE4 for some amount of time

		;display LED's for 000xxxxx counter value by setting PORTD to complement of the counter value
		COM R16
		OUT PORTD, R16
		COM R16

		RJMP MAIN_LOOP
	FINISH_POSITIVE_SHIFT:
		LSR R21
		RJMP POSITIVE_NOT_RELEASED
	FINISH_NEGATIVE_SHIFT:
		LSR R21
		RJMP NEGATIVE_NOT_RELEASED

.ORG 400
INC_COUNT:
	INC R16
	CALL DELAY
	RET

.ORG 500
DEC_COUNT:
	DEC R16
	RET

.ORG 0x600
DELAY:  LDI R31, 0xFF
	a:  LDI R30, 0xFF

	b:  LDI R29, 0xFF

	c:  NOP
		NOP
		DEC R29
		BRNE c

		DEC R30
		BRNE b 

		DEC R31
		BRNE a
		RET

; For your first project, you will design a simple, self-contained AVR-based device (Simon Board) that will, at a minimum, monitor two keys – one is a positive key that
; increments the counter, and the other is a negative key that decrements the counter; display the current count in binary on a set of 5 LEDs; and sound an alarm when
; the count “turns over” (cycles from a binary 30 to 0 or 0 to 30). The counter should be 0 initially.
