start:
	.ORG 0
	LDI R16, HIGH(RAMEND);set up stack pointer
	OUT SPH, R16
	LDI R16, LOW(RAMEND)
	OUT SPL, R16

	;button 1 sends input to PA0, active low
	;button 2 sends input to PA1, active low
	;PE4 sends output to speaker, active high(?)
	;LED's can be in 3x3 or 2x4 pattern, based on a switch on the board
	; - if using 2x4, PD0 goes to LED1, PD1 goes to LED2, PD2 goes to LED3, PD3 goes to LED4B, and PD4 goes to LED6B

	LDI R17, 0x00
	OUT DDRA, R17; set PA to input
	LDI R17, 0xFF
	OUT PORTA, R17; pull-up PA

	; Configure PE4 to send output to speaker
	SBI DDRE, 4; set PE4 to output
	CBI PORTE, 4; clear PE4

	; Configure all PD bits to send output to LED's
	LDI R17, 0b11111111
	OUT DDRD, R17; set all PD bits to output
	OUT PORTD, R16; set PORTD to initial count

	LDI R18, 0b11111111; Set previous buttons to not pressed
	LDI R19, 0b11111111; Set current buttons to not pressed

	LDI R16, 0; initialize counter

	; Configure registers for individual features

	; Viktor Butkovich individual feature - when the 3rd button is pressed, toggle a timer than, when activated, increments the counter by 1 every second
	; Feature requires timer 0, button SW3, and the R2, R3, and R4 registers, along with temporarily using the R25 register but not needing to keep any values stored there
	LDI R25, -125; calculated that a delay of 0.02 seconds would require a 156.25 clock cycle timer - based on testing, 125 clock cycles achieves timing closer to the desired result
	MOV R2, R2;
	LDI R25, 0
	MOV R3, R25; timer feature enable - R3 is set to 0x00 is off, and 0xFF when it is on
	MOV R4, R25; R4 is loop counter
	

	MAIN_LOOP:
		MOV R20, R18; Copies previous buttons pressed values to R20 for comparison
		IN R19, PINA; Sets R19 to current buttons pressed
		MOV R21, R19; Copies current buttons pressed values to R21 for comparison

		; Monitors PINA, 0 - if bit was 0 and is now 1, positive key was just released and the counter should be incremented, returning to 0 if passing 31
		LSR R20; Shifts positive key previous pressed to carry bit
		BRLO FINISH_POSITIVE_SHIFT; Branches if c == 1 - skips if button was not being pressed
								  ; While INC_COUNT needs to be skipped, subsequent buttons will only work if R21 is still
		LSR R21; Shifts positive key current pressed to carry bit
		BRSH POSITIVE_NOT_RELEASED; Branches if c == 0 - skip if button is still being pressed
		CALL INC_COUNT; Increments if button was being pressed and is no longer being pressed
		POSITIVE_NOT_RELEASED:

		; Monitors PINA, 1 - if bit was 0 and is now 1, negative key was just released and the counter should be decremented, returning to 31 if passing 0
		LSR R20; Shifts negative key previous pressed to carry bit
		BRLO FINISH_NEGATIVE_SHIFT; Branches if c == 1 - skip if button was not being pressed
								  ; While DEC_COUNT needs to be skipped, subsequent buttons will only work if R21 is still shifted
		LSR R21; Shifts negative key current pressed to carry bit
		BRSH NEGATIVE_NOT_RELEASED; Branches if c == 0 - skip if button is still being pressed
		
		CALL DEC_COUNT; Decrements if button was being pressed and is no longer being pressed
		NEGATIVE_NOT_RELEASED:

		; Detect button releases for individual features
		LSR R20
		BRLO FINISH_TIMER_SHIFT; 
		LSR R21
		BRSH TIMER_NOT_RELEASED
		COM R3; Toggles timer enable
		SBRC R3, 0; If timer not enabled (if R3 bit 0 is 0), skips
		RCALL VIKTOR_ENABLE_TIMER; If timer just enabled, starts timer loop
		TIMER_NOT_RELEASED:

		LSR R20
		BRLO FINISH_DOUBLECOUNT_SHIFT
		LSR R21
		BRSH DOUBLECOUNT_NOT_RELEASED
		RCALL SYDNEY_DOUBLECOUNT
		DOUBLECOUNT_NOT_RELEASED:

		LSR R20
		BRLO FINISH_HALFCOUNT_SHIFT
		LSR R21
		BRSH HALFCOUNT_NOT_RELEASED
		RCALL SYDNEY_HALFCOUNT
		HALFCOUNT_NOT_RELEASED:

		LSR R20
		BRLO FINISH_BLINK_SHIFT
		LSR R21
		BRSH BLINK_NOT_RELEASED
		RCALL JORGE_BLINK_TEST
		BLINK_NOT_RELEASED:

		; Format to add new feature called featurename on the next available button - put the code here
		LSR R20
		BRLO FINISH_featurename_SHIFT
		LSR R21
		BRSH featurename_NOT_RELEASED
		;RCALL FEATURE_x_subroutine - this call is skipped by the branch statements if the button was not just released
		featurename_NOT_RELEASED:

		; Update any timers
		SBRC R3, 0; If timer not enabled (if R3 bit 0 is 0), skip
		RCALL VIKTOR_UPDATE_TIMER; If timer enabled, update timer

		MOV R18, R19; Moves current buttons pressed to previous buttons pressed

		; Display LED's for 000xxxxx counter value by setting PORTD to complement of the counter value
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
	FINISH_TIMER_SHIFT:
		LSR R21
		RJMP TIMER_NOT_RELEASED
	FINISH_DOUBLECOUNT_SHIFT:
		LSR R21
		RJMP DOUBLECOUNT_NOT_RELEASED
	FINISH_HALFCOUNT_SHIFT:
		LSR R21
		RJMP HALFCOUNT_NOT_RELEASED
	FINISH_BLINK_SHIFT:
		LSR R21
		RJMP BLINK_NOT_RELEASED
	FINISH_featurename_SHIFT:
		LSR R21
		RJMP featurename_NOT_RELEASED

.ORG 350
CHECK_LOW_OVERFLOW:
	SBRC R16, 7; If 128's place is 1, negative overflow just occurred
	RCALL SOUND; If overflowed, play sound

	SBRC R16, 7; If overflowed, return counter to 30
	LDI R16, 30

	RET

.ORG 375
CHECK_HIGH_OVERFLOW:
	MOV R25, R16
	LDI R29, 0b11100000
	AND R25, R29
	CPI R25, 0x00; If 128's, 64's, or 32's place is 1, counter is greater than 31 - positive overflow just occurred
	BRNE resolve_high_overflow
	MOV R25, R16
	SUBI R25, 31
	BREQ resolve_high_overflow; If counter equals 31, then counter is greater than 30 - positive overflow just occurred
	RET

	resolve_high_overflow:; If overflowed, subtract 31, play sound, and repeatedly overflow until counter is below 31
	SUBI R16, 31
	RCALL SOUND;
	RJMP CHECK_HIGH_OVERFLOW;
	RET

.ORG 400
INC_COUNT:
	INC R16
	RCALL CHECK_HIGH_OVERFLOW
	RCALL BUTTON_DELAY
	RET

.ORG 425
DEC_COUNT:
	DEC R16
	RCALL CHECK_LOW_OVERFLOW
	RCALL BUTTON_DELAY
	RET

.ORG 450
SOUND_DELAY: ; For 1000 HZ frequency, each half-wave should have a 0.5 ms delay, or about 8000 machine cycles
			 ; 65 and 40 were calculated to result in 8002 machine cycles for each RCALL SOUND_DELAY
	LDI R29, 65
	repeat_1:
	LDI R30, 40
	repeat_2:
	DEC R30
	BRNE repeat_2
	DEC R29
	BRNE repeat_1
	RET
	
.ORG 475
SOUND:
	LDI R25, 200
	repeat_sound:
	SBI PORTE, 4
	RCALL SOUND_DELAY
	CBI PORTE, 4
	RCALL SOUND_DELAY
	DEC R25
	BRNE repeat_sound
	RET

.ORG 500
BUTTON_DELAY:  LDI R31, 10
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

.ORG 650
VIKTOR_UPDATE_TIMER:; Checks each main loop for whether a 0.02 second timer
	IN R25, TIFR0
	SBRC R25, TOV0; Skips command if TOV0 is 0
	RCALL VIKTOR_COMPLETE_TIMER; If TOV0 is 1, 0.02 second timer just completed
	RET

.ORG 675
VIKTOR_COMPLETE_TIMER:; Resolves a 0.02 second timer ending
	DEC R4; Decrements timer loop each time timer finishes
	BRNE CONTINUE_TIMER_LOOP; If 1 second timer loop not done, start timer again

	RCALL VIKTOR_START_TIMER_LOOP; If 1 second timer loop reached 0, increment counter and start loop again
	RCALL INC_COUNT
	RET

	CONTINUE_TIMER_LOOP:
	RCALL VIKTOR_START_TIMER
	RET

.ORG 700
VIKTOR_START_TIMER:; Starts 0.02 second timer
	LDI R25, 0b00000000
	LDI R25, (1 << TOV0)
	OUT TIFR0, R25; Resets TOV0

	OUT TCNT0, R2; Loads pre-load timer value
	LDI R25, 0b00000101
	OUT TCCR0B, R25; Configure timer to start with 1024 scale multiplier

	RET

.ORG 725
VIKTOR_START_TIMER_LOOP:; Starts 1 second timer loop
	LDI R25, 50
	MOV R4, R25; Set loop counter to 50
	LDI R25, 0xFF
	MOV R3, R25; Enables timer feature, causing update timer to be called in each main loop iteration
	RCALL VIKTOR_START_TIMER; Starts 1st 0.02 second timer
	RET

.ORG 750
VIKTOR_ENABLE_TIMER:; Call when timer first enabled with button toggle
	RCALL INC_COUNT
	RCALL VIKTOR_START_TIMER_LOOP
	RET

;Sydney - My individual feature is meant to double or half the count at a specific button
.ORG 775
SYDNEY_DOUBLECOUNT:
	LSL R16 ; should multiply count by 2
	RCALL CHECK_HIGH_OVERFLOW
	CALL BUTTON_DELAY
	RET

;Sydney - half the count
.ORG 800
SYDNEY_HALFCOUNT:
	LSR R16 ; should half the count, if odd rounds down 
	RCALL BUTTON_DELAY
	RET

;Jorge - 'Lucky 7' When the counter is 7, LEDs should blink
.ORG 825
JORGE_BLINK_TEST:
	MOV R28, R16
	LDI R27, 0b00000111
	CP R28, R27
	BREQ JORGE_BLINK
	RET

.ORG 850
JORGE_BLINK:
	LDI R26, 0xFF
	LDI R24, 0x00
	OUT PORTD, R26
	RCALL BUTTON_DELAY
	OUT PORTD, R24
	RCALL BUTTON_DELAY
	OUT PORTD, R26
	RCALL BUTTON_DELAY
	OUT PORTD, R24
	OUT PORTD, R16
	RET


; For your first project, you will design a simple, self-contained AVR-based device (Simon Board) that will, at a minimum, monitor two keys – one is a positive key that
; increments the counter, and the other is a negative key that decrements the counter; display the current count in binary on a set of 5 LEDs; and sound an alarm when
; the count “turns over” (cycles from a binary 30 to 0 or 0 to 30). The counter should be 0 initially.
