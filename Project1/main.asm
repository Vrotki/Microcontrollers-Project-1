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

	; Configure registers for individual features

	;Viktor Butkovich individual feature - when the 3rd button is pressed, toggle a timer than, when activated, increments the counter by 1 every second
	;Feature requires timer 0, button SW3, and the R2, R3, and R4 registers, along with temporarily using the R25 register but not needing to keep any values stored there
	LDI R25, -125; calculated that a delay of 0.02 seconds would require a 156.25 clock cycle timer - based on testing, 125 clock cycles achieves timing closer to the desired result
	MOV R2, R2;
	LDI R25, 0
	MOV R3, R25; timer feature enable - R3 is set to 0x00 is off, and 0xFF when it is on
	MOV R4, R25; R4 is loop counter
	

	MAIN_LOOP:
		MOV R20, R18; copies previous buttons pressed values to R20 for comparison
		IN R19, PINA; set R19 to current buttons pressed
		MOV R21, R19; copies current buttons pressed values to R21 for comparison

		;monitor PINA, 0 - if bit was 0 and is now 1, positive key was just released and the counter should be incremented, returning to 0 if passing 30
		LSR R20; shifts positive key previous pressed to carry bit
		BRLO FINISH_POSITIVE_SHIFT; branch if c == 1 - skip if button was not being pressed
								  ; while INC_COUNT needs to be skipped, subsequent buttons will only work if R21 is still
		LSR R21; shifts positive key current pressed to carry bit
		BRSH POSITIVE_NOT_RELEASED; branch if c == 0 - skip if button is still being pressed
		CALL INC_COUNT; increment if button was being pressed and is no longer being pressed
		POSITIVE_NOT_RELEASED:

		;monitor PINA, 1 - if bit was 0 and is now 1, negative key was just released and the counter should be decremented, returning to 30 if passing 0
		LSR R20; shifts negative key previous pressed to carry bit
		BRLO FINISH_NEGATIVE_SHIFT; branch if c == 1 - skip if button was not being pressed
								  ; while DEC_COUNT needs to be skipped, subsequent buttons will only work if R21 is still shifted
		LSR R21; shifts negative key current pressed to carry bit
		BRSH NEGATIVE_NOT_RELEASED; branch if c == 0 - skip if button is still being pressed
		
		CALL DEC_COUNT; decrement if button was being pressed and is no longer being pressed
		NEGATIVE_NOT_RELEASED:

		; Detect button releases for individual features
		LSR R20
		BRLO FINISH_TIMER_SHIFT; 
		LSR R21
		BRSH TIMER_NOT_RELEASED
		COM R3; toggle timer enable
		SBRC R3, 0; if timer not enabled (if R3 bit 0 is 0), skip
		RCALL VIKTOR_ENABLE_TIMER; if timer just enabled, start timer loop
		TIMER_NOT_RELEASED:

		; Format to add new feature called featurename on the next available button - put the code here
		LSR R20
		BRLO FINISH_featurename_SHIFT
		LSR R21
		BRSH featurename_NOT_RELEASED
		;RCALL FEATURE_x_subroutine - this call is skipped by the branch statements if the button was not just released
		featurename_NOT_RELEASED:

		; Update any timers
		SBRC R3, 0; if timer not enabled (if R3 bit 0 is 0), skip
		RCALL VIKTOR_UPDATE_TIMER; if timer enabled, update timer

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
	FINISH_TIMER_SHIFT:
		LSR R21
		RJMP TIMER_NOT_RELEASED
	FINISH_featurename_SHIFT:
		LSR R21
		RJMP featurename_NOT_RELEASED

.ORG 400
INC_COUNT:
	INC R16
	LDI R25, 32

	SBRC R16, 5; if 32's place is 1, overflow just occurred
	RCALL SOUND; if overflowed, play sound and return to 0

	SBRC R16, 5
	LDI R16, 0

	CALL BUTTON_DELAY
	RET

.ORG 425
DEC_COUNT:
	DEC R16

	SBRC R16, 7; if 128's place is 1, overflow just occurred
	RCALL SOUND; if overflowed, play sound and return to 31

	SBRC R16, 5
	LDI R16, 31

	CALL BUTTON_DELAY
	RET

.ORG 450
SOUND_DELAY: ;for 1000 HZ frequency, each half-wave should have a 0.5 ms delay, or about 8000 machine cycles: 32 * 250 = 8000
	LDI R29, 32 ;incorrect calculation - remember that each inner loop is more than 1 machine cycle
	repeat_1:
	LDI R30, 32
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
VIKTOR_UPDATE_TIMER:; checks each main loop for whether a 0.02 second timer
	IN R25, TIFR0
	SBRC R25, TOV0; skip command if TOV0 is 0
	RCALL VIKTOR_COMPLETE_TIMER; if TOV0, 0.02 second timer just completed
	RET

.ORG 675
VIKTOR_COMPLETE_TIMER:; resolves a 0.02 second timer ending
	DEC R4; decrement timer loop each time timer finishes
	BRNE CONTINUE_TIMER_LOOP
	; if 1 second timer loop not done, start timer again

	RCALL VIKTOR_START_TIMER_LOOP; if 1 second timer loop reached 0, increment counter and start loop again
	RCALL INC_COUNT
	RET

	CONTINUE_TIMER_LOOP:
	RCALL VIKTOR_START_TIMER
	RET

.ORG 700
VIKTOR_START_TIMER:; starts 0.02 second timer
	LDI R25, 0b00000000
	LDI R25, (1 << TOV0)
	OUT TIFR0, R25; resets TOV0

	OUT TCNT0, R2; loads pre-load timer value
	LDI R25, 0b00000101
	OUT TCCR0B, R25; configure timer to start with 1024 scale multiplier

	RET

.ORG 725
VIKTOR_START_TIMER_LOOP:; starts 1 second timer loop
	LDI R25, 50
	MOV R4, R25; set loop counter to 50
	LDI R25, 0xFF
	MOV R3, R25; enable timer feature, causing update timer to be called in each main loop iteration
	RCALL VIKTOR_START_TIMER; start 1st 0.02 second timer
	RET

.ORG 750
VIKTOR_ENABLE_TIMER: ; call when timer first enabled with button toggle
	RCALL INC_COUNT
	RCALL VIKTOR_START_TIMER_LOOP
	RET
; For your first project, you will design a simple, self-contained AVR-based device (Simon Board) that will, at a minimum, monitor two keys – one is a positive key that
; increments the counter, and the other is a negative key that decrements the counter; display the current count in binary on a set of 5 LEDs; and sound an alarm when
; the count “turns over” (cycles from a binary 30 to 0 or 0 to 30). The counter should be 0 initially.
