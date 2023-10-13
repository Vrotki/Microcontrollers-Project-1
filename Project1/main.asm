;
; Project1.asm
;
; Created: 10/10/2023 10:57:08 AM
; Author : vikto
;


; Replace with your application code
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
	;configure PE4 to send output to speaker
	;configure all PD bits to send output to LED's

	;main loop:
		;monitor PINC, 0 - if bit was 0 and is now 1, positive key was just released and the counter should be incremented, returning to 0 if passing 30
		;monitor PINC, 1 - if bit was 0 and is now 1, negative key was just released and the counter should be decremented, returning to 30 if passing 0

		;if counter moved past 0 or 30, send 1000 HZ square wave to PE4 for some amount of time

		;display LED's for 000xxxxx counter value by setting PORTD to the counter value

; For your first project, you will design a simple, self-contained AVR-based device (Simon Board) that will, at a minimum, monitor two keys – one is a positive key that
; increments the counter, and the other is a negative key that decrements the counter; display the current count in binary on a set of 5 LEDs; and sound an alarm when
; the count “turns over” (cycles from a binary 30 to 0 or 0 to 30). The counter should be 0 initially.
