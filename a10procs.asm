; *****************************************************************
;  Name: Kevin Barrios
;  NSHE ID: 2001697903
;  Section: cs218 - 1003
;  Assignment: 10
;  Description:  Write a simple assembly language program using Open
;					GL to calculate and display the output from a 
;					series of provided functions

; -----
;  Function: getParams
;	Gets, checks, converts, and returns command line arguments.

;  Function drawWheels()
;	Plots functions

; ---------------------------------------------------------

;	MACROS (if any) GO HERE boi you built like a macro


; ---------------------------------------------------------

section  .data

; -----
;  Define standard constants.

TRUE		equ	1
FALSE		equ	0

SUCCESS		equ	0			; successful operation
NOSUCCESS	equ	1

STDIN		equ	0			; standard input
STDOUT		equ	1			; standard output
STDERR		equ	2			; standard error

SYS_read	equ	0			; code for read
SYS_write	equ	1			; code for write
SYS_open	equ	2			; code for file open
SYS_close	equ	3			; code for file close
SYS_fork	equ	57			; code for fork
SYS_exit	equ	60			; code for terminate
SYS_creat	equ	85			; code for file open/create
SYS_time	equ	201			; code for get time

LF		equ	10
SPACE		equ	" "
NULL		equ	0
ESC		equ	27

; -----
;  OpenGL constants

GL_COLOR_BUFFER_BIT	equ	16384
GL_POINTS		equ	0
GL_POLYGON		equ	9
GL_PROJECTION		equ	5889

GLUT_RGB		equ	0
GLUT_SINGLE		equ	0

; -----
;  Define program specific constants.

SPD_MIN		equ	1
SPD_MAX		equ	50			; 101(7) = 50

CLR_MIN		equ	0
CLR_MAX		equ	0xFFFFFF		; 0xFFFFFF = 262414110(7)

SIZ_MIN		equ	100			; 202(7) = 100
SIZ_MAX		equ	2000			; 5555(7) = 2000

; -----
;  Local variables for getParams functions.

STR_LENGTH	equ	12

errUsage	db	"Usage: ./wheels -sp <septNumber> -cl <septNumber> "
		db	"-sz <septNumber>"
		db	LF, NULL
errBadCL	db	"Error, invalid or incomplete command line argument."
		db	LF, NULL

errSpdSpec	db	"Error, speed specifier incorrect."
		db	LF, NULL
errSpdValue	db	"Error, speed value must be between 1 and 101(7)."
		db	LF, NULL

errClrSpec	db	"Error, color specifier incorrect."
		db	LF, NULL
errClrValue	db	"Error, color value must be between 0 and 262414110(7)."
		db	LF, NULL

errSizSpec	db	"Error, size specifier incorrect."
		db	LF, NULL
errSizValue	db	"Error, size value must be between 202(7) and 5555(7)."
		db	LF, NULL


; -----
;  Local variables for drawWheels routine.

t		dq	0.0			; loop variable
s		dq	0.0
tStep		dq	0.001			; t step
sStep		dq	0.0
x		dq	0			; current x
y		dq	0			; current y
scale		dq	7500.0			; speed scale

fltZero		dq	0.0
fltOne		dq	1.0
fltTwo		dq	2.0
fltThree	dq	3.0
fltFour		dq	4.0
fltSix		dq	6.0
fltTwoPiS	dq	0.0

pi		dq	3.14159265358

fltTmp1		dq	0.0
fltTmp2		dq	0.0

red		dd	0			; 0-255
green		dd	0			; 0-255
blue		dd	0			; 0-255


; ------------------------------------------------------------

section  .text

; -----
; Open GL routines.

extern	glutInit, glutInitDisplayMode, glutInitWindowSize, glutInitWindowPosition
extern	glutCreateWindow, glutMainLoop
extern	glutDisplayFunc, glutIdleFunc, glutReshapeFunc, glutKeyboardFunc
extern	glutSwapBuffers, gluPerspective, glutPostRedisplay
extern	glClearColor, glClearDepth, glDepthFunc, glEnable, glShadeModel
extern	glClear, glLoadIdentity, glMatrixMode, glViewport
extern	glTranslatef, glRotatef, glBegin, glEnd, glVertex3f, glColor3f
extern	glVertex2f, glVertex2i, glColor3ub, glOrtho, glFlush, glVertex2d

extern	cos, sin

; ******************************************************************
;  i was about to write a print string function but it's literally 
;	provided
; whtvr ascii to int function then
; FUNCTION atoint(argv[x])
global atoint
atoint:
    ; arguments rdi = argv[x] where argv[x] is valid sept int
    ; returns base10 integer in rax 
    push rbp 
    mov rbp, rsp 
    ;sub
    push r12 
    push r13 
    push r14 
    push r15 

    ;rdi = argv[x]
    mov r13, 0 ; digit count 
    mov r14, 0 ; index 
;first get digit count of number 
_getDigits: ;(something u cant do!)
    cmp byte[rdi+r14], NULL 
    je _countDone 
    inc r13 
    inc r14 
    jmp _getDigits 
_countDone:
    ;next get correct power of 7 to multiply digit with
    mov r14, 0  ; index 
    mov r15, 0  ; running sum 
    ;r13 = digit count (from prev loop)
    mov r11, 0  ; single digit from sept number
_septoint:
;firstcheckNULL
    cmp byte[rdi+r14], NULL 
    je _conversionDone 
    dec r13 ; digitcount - 1 (to get correct place value)
    mov rax, 1 ; for 7 to power of n
    mov rcx, r13 ; n
_mul7loop:
    cmp rcx, 0
    je _nomul 
    mov r10, 7
    mul r10 
    loop _mul7loop
_nomul:  ; rax holding what to mul digit with
         ; multiply digit with proper place value digit
    mov r11b, byte[rdi+r14]
    sub r11b, 0x30 ; ascii to dec int
    mul r11 ; (7^n) * digit
    add r15, rax ; running sum
    inc r14 ; index++
    jmp _septoint
_conversionDone:
    mov rax, r15 ; return base10 num in rax

    pop r15 
    pop r14 
    pop r13 
    pop r12 
    mov rsp, rbp 
    pop rbp
ret 

; ******************************************************************

; ******************************************************************
;  Function getParams()
;	Gets draw speed, draw color, and screen size
;	from the command line arguments.

;	Performs error checking, converts ASCII/septenary to integer.
;	Command line format (fixed order):
;	  "-sp <septNumber> -cl <septNumber> -sz <septyNumber>"

; -----
;  Arguments:
;	ARGC, double-word, value
;	ARGV, double-word, address
;	speed, double-word, address
;	color, double-word, address
;	size, double-word, address

; Returns:
;	speed, color, and size via reference (of all valid)
;	TRUE or FALSE


global getParams
getParams:
	;prologue 
	push rbp 
	mov rbp, rsp 
	sub rsp, 12 ; holds speed,color,size addys  
	push rbx 
	push r12 
	push r13
	push r14 
	push r15

;intialize values
	mov rbx, 0
	mov r12, rsi ; r12 will hold argv vector
	mov r13, 0
	mov r14, 0
	mov r15, 0
	mov dword[rbp-4], edx ; speed
	mov dword[rbp-8], ecx ; color
	mov dword[rbp-12], r8d ; size

	; IF THERE ARE ANY ERROR, DISPLAY ERROR MESSAGE AND RETURN TO MAIN
	; WITH A RETURN VALUE OF FALSE (0)


;APPROACH: First im going to make sure the argument count is 7, if not error. Then
;			I will check if all the specifiers are correct "-sp", "-cl", "-sz" if not
;		    then error. Then will get each number and make sure its a valid sept num
;			if not then error. then convert sept num to integer and then check if its
;			valid range. if not then error. if there is no errors pass back new int
;			values of speed, color, and size and return true .


	; ** code grade made me realize if argc is 1 show usage message
;;
	cmp rdi, 1
	jne _notone
	mov rdi, errUsage 
	call printString
	mov al, FALSE
	jmp _endfunction
_notone:
	;	argc must equal 7
	;   if argc is not equal 7 errBadCL
	cmp rdi, 7
	je isSeven
	mov rdi, errBadCL 
	call printString 
	mov al, FALSE 	; return false
	jmp _endfunction ; end function
isSeven: ;  **continue to check speed secifier**
	;	argv will be used to access the data entered
	;	argv[1] must be -sp
		; if argv[1] does not equal -sp errSpdSpec
	mov rbx, qword[r12+(8*1)] ; rbx = argv[1]
	cmp byte[rbx], '-'
	jne _spdspecErr 
	cmp byte[rbx+1], 's'
	jne _spdspecErr 
	cmp byte[rbx+2], 'p'
	jne _spdspecErr
	cmp byte[rbx+3], NULL
	jne _spdspecErr
	mov r13, 1 ; flag showing no errors
_spdspecErr:
	cmp r13, 1
	je _nospdspecErr
	mov rdi, errSpdSpec 
	call printString
	mov al, FALSE 
	jmp _endfunction
_nospdspecErr: ; **continue to check color specifier**
	mov r13, 0	; reset flag
	;   argv[3] must be -cl 
		; if argv[3] does not equal -cl errClrSpec
	mov rbx, qword[r12+(8*3)] ; rbx = argv[3]
	cmp byte[rbx], '-'
	jne _clrspecErr 
	cmp byte[rbx+1], 'c'
	jne _clrspecErr 
	cmp byte[rbx+2], 'l'
	jne _clrspecErr
	cmp byte[rbx+3], NULL
	jne _clrspecErr
	mov r13, 1 ; flag showing no errors
_clrspecErr:
	cmp r13, 1
	je _noclrspecErr
	mov rdi, errClrSpec 
	call printString
	mov al, FALSE 
	jmp _endfunction
_noclrspecErr: ; ** continue to check size specifier **
	mov r13, 0 ; reset flag
	;	argv[5] must be -sz 
		; if argv[5] does not equal -sz errSizSpec
	mov rbx, qword[r12+(8*5)] ; rbx = argv[5]
	cmp byte[rbx], '-'
	jne _szspecErr 
	cmp byte[rbx+1], 's'
	jne _szspecErr 
	cmp byte[rbx+2], 'z'
	jne _szspecErr
	cmp byte[rbx+3], NULL
	jne _szspecErr
	mov r13, 1 ; flag showing no errors
_szspecErr:
	cmp r13, 1
	je _noszspecErr
	mov rdi, errSizSpec 
	call printString
	mov al, FALSE 
	jmp _endfunction
_noszspecErr:
	mov r13, 0 ; reset flag.. (used in next checks but not as flag)
	; ARGUMENT COUNT AND ALL SPECIFIERS HAVE BEEN CHECKED


	; now we check if the numbers are sept 
	; the ascii/sept to integer should check if its valid sept and ofc if its 
	; all digit values 0x30 - 0x36
	mov rbx, qword[r12+(8*2)] ; rbx = argv[2]
	mov r13, 0
_spvaluecheck: ;LOOP
	cmp byte[rbx+r13], NULL 
	je _spvalDone	; null our check is done
	cmp byte[rbx+r13], 0x30 
	jb _spvalErr ; error if digit < 0 
	cmp byte[rbx+r13], 0x36
	ja _spvalErr ; error if digit > 6
	inc r13
	jmp _spvaluecheck 
_spvalErr: 
	mov rdi, errSpdValue
	call printString
	mov al, FALSE ; return false
	jmp _endfunction
_spvalDone: ;** speed is valid septnum ** 

	;*color check*
	mov rbx, qword[r12+(8*4)] ; rbx = argv[4] 
	mov r13, 0
_clrvaluecheck: ;LOOP 
	cmp byte[rbx+r13], NULL 
	je _clrvalDone   ; null our check is done
	cmp byte[rbx+r13], 0x30 
	jb _clrvalErr ; error if digit < 0 
	cmp byte[rbx+r13], 0x36
	ja _clrvalErr ; error if digit > 6
	inc r13 
	jmp _clrvaluecheck
_clrvalErr:
	mov rdi, errClrValue
	call printString
	mov al, FALSE ; return false 
	jmp _endfunction
_clrvalDone: ;** color is valid septnum **

	;*size check*
	mov rbx, qword[r12+(8*6)] ; rbx = argv[6] 
	mov r13, 0
_szvaluecheck: ;LOOP 
	cmp byte[rbx+r13], NULL 
	je _szvalDone   ; null our check is done
	cmp byte[rbx+r13], 0x30 
	jb _szvalErr ; error if digit < 0 
	cmp byte[rbx+r13], 0x36
	ja _szvalErr ; error if digit > 6
	inc r13 
	jmp _szvaluecheck
_szvalErr:
	mov rdi, errSizValue
	call printString
	mov al, FALSE ; return false 
	jmp _endfunction
_szvalDone: ;** size is valid septnum **

	; then we can go ahead and convert it to an integer 
	; then we check if its in between the range 
	; then we go ahead and return values if all is valid 


	; OUR RANGES OUR DEFINED WITH CONSTANTS ( nice:) )
	; oouuu and we can use same error labels :) 

	; 	argv[2] (speed) must be between 1 and 101 base 7
		; if argv[2] is not a sept number between 1 and 101 errSpdValue
	mov rdi, qword[r12+(8*2)] ; rbx = argv[2]
	call atoint ;**septnum to decimal passing valid sep string**
	mov r13, rax ; r13 = decimal value of speed 
	;check range
	cmp r13, SPD_MIN 
	jb _spvalErr    ; error if value < min 
	cmp r13, SPD_MAX
	ja _spvalErr    ; error if value > max 

	;   argv[4] (color) must be between 0 and 262414110 base 7
		; if argv[4] is not a sept number between 0 and 262414110 errClrValue
	mov rdi, qword[r12+(8*4)] ; rbx = argv[4]
	call atoint ;**septnum to decimal passing valid sep string**
	mov r14, rax ; r14 = decimal value of color 
	;check range
	cmp r14, CLR_MIN
	jb _clrvalErr ; error if value < min
	cmp r14, CLR_MAX
	ja _clrvalErr ; error if value > max

	;   argv[6] (size value) must be between 202 and 5555 base 7
		; if argv[6] is not a sept number between 202 and 5555 errSizValue
	mov rdi, qword[r12+(8*6)] ; rbx = argv[6]
	call atoint ;**septnum to decimal passing valid sep string**
	mov r15, rax ; r15 = decimal value of color 
	;check range
	cmp r15, SIZ_MIN
	jb _szvalErr ; error if value < min
	cmp r15, SIZ_MAX
	ja _szvalErr ; error if value > max

;r13 = speed r14 = color r15 = size
; now we gotta return these -_-
	mov rdx, 0
	mov rcx, 0
	mov r8, 0
;pass back the copied values back to arg
	mov edx, dword[rbp-4] 
	mov ecx, dword[rbp-8]
	mov r8d, dword[rbp-12]
;return new values by reference 
	mov dword[edx], r13d
	mov dword[ecx], r14d
	mov dword[r8d], r15d 

_endfunction: ;*end of function yay!*
	;epilogue
	pop r15 
	pop r14
	pop r13
	pop r12 
	pop rbx 
	mov rsp, rbp 
	pop rbp
ret 

; ******************************************************************
;  Draw wheels function.
;	Plot the provided functions (see PDF).

; -----
;  Arguments:
;	none -> accesses global variables.
;	nothing -> is void

; -----
;  Gloabl variables Accessed:

common	speed		1:4			; draw speed, dword, integer value
common	color		1:4			; draw color, dword, integer value
common	size		1:4			; screen size, dword, integer value

global drawWheels
drawWheels:
	push	rbp

; do NOT push any additional registers.
; If needed, save regitser to quad variable... what do you mean

; -----
;  Set draw speed step
;	sStep = speed / scale

;	sStep dq = 0.00
	cvtsi2sd xmm0, dword[speed] ; turn dword speed to 64 floating point
	divsd	xmm0, qword[scale]
	movsd	qword[sStep], xmm0
	;ez

; -----
;  Prepare for drawing
	; glClear(GL_COLOR_BUFFER_BIT);
	mov	rdi, GL_COLOR_BUFFER_BIT
	call	glClear

	; glBegin();
	mov	rdi, GL_POINTS
	call	glBegin

; -----
;  Set draw color(r,g,b)
;	uses glColor3ub(r,g,b)

;run -sp 2 -cl 100564263 -sz 1313
	mov r8, 0 ; will hold color
	mov r9, 0 ; register to use for whtv
	movsxd r8, dword[color] ; get color in r8

; okay im kinda writing this approach after i did this part
; but basically i get the blue color first then shift the color 
; register over 8 bits then save the green color then shift the 
; color register again 8 bits then save the red color 

;blue 
	mov r9b, r8b 
	mov dword[blue], r9d 
;green 
	mov r9, 0
	shr r8, 8 ; shifts color register
	mov r9b, r8b 
	mov dword[green], r9d 
;red 
	mov r9, 0
	shr r8, 8 ; shifts color register
	mov r9b, r8b 
	mov dword[red], r9d

	; call glColor3ub
	; rdi=red, rsi=green, rdx=blue
	movsxd rdi, dword[red]
	movsxd rsi, dword[green]
	movsxd rdx, dword[blue]
	call glColor3ub 

; -----
;  main plot loop
;	iterate t from 0.0 to 2*pi by tStep
;	uses glVertex2d(x,y) for each formula


;	get 2*pi
	movsd xmm0, qword[fltTwo]
	mulsd xmm0, qword[pi]
	movsd qword[fltTwoPiS], xmm0 


	;set t = 0.0 ***needed this or wont work****
	movsd xmm0, qword[fltZero]
	movsd qword[t], xmm0 
_plotloop:
	movsd xmm0, qword[t]
	movsd xmm1, qword[fltTwoPiS]  ; while t < fltTwoPis
	ucomisd xmm0, xmm1
	jae _exitplot

;x1 y1
	;x1
	movsd qword[fltTmp1], xmm0 ; hold value of t
	;xmm0 has the value of t so call cos
	call cos 
	movsd qword[x], xmm0 ; x = xmm0
	;y1
	movsd xmm0, qword[fltTmp1] ; xmm0 = t
	call sin;(t) 
	movsd qword[y], xmm0
	;x=xmm0 y=xmm1
	movsd xmm0, qword[x]
	movsd xmm1, qword[y]
	;plot 
	call glVertex2d

;x2 y2
	; x2
	; get cos(t)/3 in fltTmp2 
	movsd xmm0, qword[fltTmp1] ; xmm0 = t 
	call cos
	;cos(t) is in xmm0
	divsd xmm0, qword[fltThree]
	movsd qword[fltTmp2], xmm0 ; fltTmp2 = cos(t)/3
	; get 2cos(2pi*s) in a register
	movsd xmm0, qword[fltTwoPiS]
	mulsd xmm0, qword[s]
	;xmm0 is (2pi * s)
	call cos 
	;cos(2pi*s) is in xmm0 
	mulsd xmm0, qword[fltTwo]
	;xmm0 is 2 * cos(2pi*s)
	divsd xmm0, qword[fltThree]
	;xmm0 is 2*cos(2pi*s) / 3
	addsd xmm0, qword[fltTmp2] ; result
	movsd qword[x], xmm0 
	;y2
	; get sin(t)/3 in fltTmp2 
	movsd xmm0, qword[fltTmp1] ; xmm0 = t 
	call sin 
	;sin(t) is in xmm0 
	divsd xmm0, qword[fltThree]
	movsd qword[fltTmp2], xmm0 ; fltTmp2 = sin(t)/3
	; get 2sin(2pi*s) in a register
	movsd xmm0, qword[fltTwoPiS]
	mulsd xmm0, qword[s]
	;xmm0 is (2pi * s)
	call sin 
	;sin(2pi*s) is in xmm0
	mulsd xmm0, qword[fltTwo]
	; xmm0 is 2 * sin(2pi*s)
	divsd xmm0, qword[fltThree]
	; xmm0 is 2*sin(2pi*s) / 3
	addsd xmm0, qword[fltTmp2] ; result
	movsd qword[y], xmm0 
	;x=xmm0 y=xmm1
	movsd xmm0, qword[x]
	movsd xmm1, qword[y]
	;plot 
	call glVertex2d

;x3y3 lets try n make these effecient 
; fltTmp1 won't be t anymore!
	;x3
	movsd xmm0, qword[fltTwoPiS]
	mulsd xmm0, qword[s]
	call cos
	mulsd xmm0, qword[fltTwo]
	divsd xmm0, qword[fltThree]
	movsd qword[fltTmp1], xmm0 ; fltTmp1 = 2cos(2pi*s) / 3
	;get tcos(4pi*s)/6pi in a register
	; get 6pi first 
	movsd xmm0, qword[pi]
	mulsd xmm0, qword[fltSix]
	movsd qword[fltTmp2], xmm0 ; fltTmp2 = 6pi
	;get tcos(4pi*s)
	movsd xmm0, qword[pi]
	mulsd xmm0, qword[fltFour]
	mulsd xmm0, qword[s]
	;xmm0 is 4pi*2
	call cos 
	mulsd xmm0, qword[t] ; cos(4pi*s) * t
	divsd xmm0, qword[fltTmp2] 
	addsd xmm0, qword[fltTmp1]
	movsd qword[x], xmm0 ; x = tcos(4pi*s)/6pi + 2cos(2pi*s) / 3
	;y3
	movsd xmm0, qword[fltTwoPiS]
	mulsd xmm0, qword[s]
	call sin 
	mulsd xmm0, qword[fltTwo]
	divsd xmm0, qword[fltThree]
	movsd qword[fltTmp1], xmm0 ; fltTmp1 = 2sin(2pi*s) / 3
	;get tsin(4pi*s)/6pi in a register
	; get 6pi
	movsd xmm0, qword[pi]
	mulsd xmm0, qword[fltSix]
	movsd qword[fltTmp2], xmm0 ; fltTmp2 = 6pi
	;get tsin(4pi*s)
	movsd xmm0, qword[pi]
	mulsd xmm0, qword[fltFour]
	mulsd xmm0, qword[s]
	;xmm0 is 4pi*2
	call sin 
	mulsd xmm0, qword[t] ; sin(4pi*s) * t
	divsd xmm0, qword[fltTmp2]
	; xmm0 is 2sin(4pi*s) / 6pi
	movsd xmm1, xmm0 ; xmm1 = tsin(4pi*s) / 6pi
	movsd xmm0, qword[fltTmp1]
	subsd xmm0, xmm1 
	movsd qword[y], xmm0 ; x = 2sin(2pi*s)/3 - tsin(4pi*s)/6pi 
	;x=xmm0 y=xmm1
	movsd xmm0, qword[x]
	movsd xmm1, qword[y]
	;plot 
	call glVertex2d

;x4 y4
	; get cos(2pi*s) in fltTmp1 
	movsd xmm0, qword[fltTwoPiS]
	mulsd xmm0, qword[s]
	call cos
	movsd qword[fltTmp1], xmm0 ;fltTmp1 = cos 2pi*s
	; get cos(4pi*s + (2pi/3)) in fltTmp2
	movsd xmm0, qword[fltTwoPiS]
	divsd xmm0, qword[fltThree]
	movsd xmm1, qword[pi]
	mulsd xmm1, qword[fltFour]
	mulsd xmm1, qword[s]
	addsd xmm0, xmm1
	call cos  
	movsd qword[fltTmp2], xmm0 ;fltTmp2 = cos 4pi*s + (2pi/3)

	;x4
	movsd xmm0, qword[fltTmp1]
	mulsd xmm0, qword[fltTwo]
	divsd xmm0, qword[fltThree] 

	;6pi
	movsd xmm1, qword[pi]
	mulsd xmm1, qword[fltSix]

	;tcos....
	movsd xmm2, qword[fltTmp2]
	mulsd xmm2, qword[t]
	divsd xmm2, xmm1 

	addsd xmm0, xmm2 
	movsd qword[x], xmm0 

	; get sin(2pi*s) in fltTmp1
	movsd xmm0, qword[fltTwoPiS]
	mulsd xmm0, qword[s]
	call sin 
	movsd qword[fltTmp1], xmm0 ;fltTmp1 = sin 2pi*s
	; get sin(4pi*s + (2pi/3)) in fltTmp2
	movsd xmm0, qword[fltTwoPiS]
	divsd xmm0, qword[fltThree]
	movsd xmm1, qword[pi]
	mulsd xmm1, qword[fltFour]
	mulsd xmm1, qword[s]
	addsd xmm0, xmm1 
	call sin 
	movsd qword[fltTmp2], xmm0 ;fltTmp2 = sin 4pi*s + (2pi/3)

	;y4
	movsd xmm0, qword[fltTmp1]
	mulsd xmm0, qword[fltTwo]
	divsd xmm0, qword[fltThree]

	;6pi
	movsd xmm1, qword[pi]
	mulsd xmm1, qword[fltSix]

	;tsin...
	movsd xmm2, qword[fltTmp2]
	mulsd xmm2, qword[t]
	divsd xmm2, xmm1 

	; xmm0 - xmm2 
	subsd xmm0, xmm2 
	movsd qword[y], xmm0 


	;x=xmm0 y=xmm1
	movsd xmm0, qword[x]
	movsd xmm1, qword[y]
	;plot 
	call glVertex2d

;x5 y5 (last oneeeeeee)
	;get cos(2pi*s) in fltTmp1
	movsd xmm0, qword[fltTwoPiS]
	mulsd xmm0, qword[s]
	call cos 
	movsd qword[fltTmp1], xmm0 ; fltTmp1 = cos(2pi*s)
	;get cos(4pi*s - (2pi/3)) in fltTmp2
	movsd xmm0, qword[pi]
	mulsd xmm0, qword[fltFour]
	mulsd xmm0, qword[s] 

	movsd xmm1, qword[fltTwoPiS]
	divsd xmm1, qword[fltThree]
	
	subsd xmm0, xmm1 
	call cos 
	movsd qword[fltTmp2], xmm0 ; fltTmp2 = cos(4pi*s - (2pi/3))

	;x5
	; xmm0 = 2cos(2pi*s) / 3
	movsd xmm0, qword[fltTmp1]
	mulsd xmm0, qword[fltTwo]
	divsd xmm0, qword[fltThree]

	; xmm1 = 6pi
	movsd xmm1, qword[pi]
	mulsd xmm1, qword[fltSix]

	; xmm2 = tcos(4pi*s - (2pi/3))
	movsd xmm2, qword[fltTmp2]
	mulsd xmm2, qword[t]
	divsd xmm2, xmm1 ; xmm2 = tcos(4pi*s - (2pi/3)) / 6pi 

	; xmm0 + xmm2
	addsd xmm0, xmm2
	movsd qword[x], xmm0 

	;get sin(2pi*s) in fltTmp1
	movsd xmm0, qword[fltTwoPiS]
	mulsd xmm0, qword[s]
	call sin 
	movsd qword[fltTmp1], xmm0 ; fltTmp1 = sin(2pi*s)
	;get sin(4pi*s - (2pi/3)) in fltTmp2
	movsd xmm1, qword[fltTwoPiS]
	divsd xmm1, qword[fltThree]

	movsd xmm0, qword[pi]
	mulsd xmm0, qword[fltFour]
	mulsd xmm0, qword[s]

	subsd xmm0, xmm1 
	call sin 
	movsd qword[fltTmp2], xmm0 ; fltTmp2 = sin(4pi*s - (2pi/3))

	;y5 
	; xmm0 = 2sin(2pi*s) / 3
	movsd xmm0, qword[fltTmp1]
	mulsd xmm0, qword[fltTwo]
	divsd xmm0, qword[fltThree]

	; xmm1 = 6pi
	movsd xmm1, qword[pi]
	mulsd xmm1, qword[fltSix]

	; xmm2 = tsin(4pi*s - (2pi/3))
	movsd xmm2, qword[fltTmp2]
	mulsd xmm2, qword[t]
	divsd xmm2, xmm1 ; xmm2 = tsin(4pi*s - (2pi/3)) / 6pi

	; xmm0 - xmm2 
	subsd xmm0, xmm2 
	movsd qword[y], xmm0 
	;x=xmm0 y=xmm1
	movsd xmm0, qword[x]
	movsd xmm1, qword[y]
	;plot 
	call glVertex2d

; finally

	; t += tStep
	movsd xmm0, qword[t]
	addsd xmm0, qword[tStep]
	movsd qword[t], xmm0
	jmp _plotloop 
_exitplot:
; -----
;  Display image

	call	glEnd
	call	glFlush

; -----
;  Update s, s += sStep;
;  if (s > 1.0)
;	s = 0.0;

	movsd	xmm0, qword [s]			; s+= sStep
	addsd	xmm0, qword [sStep]
	movsd	qword [s], xmm0

	movsd	xmm0, qword [s]
	movsd	xmm1, qword [fltOne]
	ucomisd	xmm0, xmm1			; if (s > 1.0)
	jbe	resetDone

	movsd	xmm0, qword [fltZero]
	movsd	qword [sStep], xmm0
resetDone:

	call	glutPostRedisplay

; -----
_endend:
	pop	rbp
	ret

; ******************************************************************
;  Generic function to display a string to the screen.
;  String must be NULL terminated.
;  Algorithm:
;	Count characters in string (excluding NULL)
;	Use syscall to output characters

;  Arguments:
;	1) address, string
;  Returns:
;	nothing

global	printString
printString:
	push	rbx

; -----
;  Count characters in string.

	mov	rbx, rdi			; str addr
	mov	rdx, 0
strCountLoop:
	cmp	byte [rbx], NULL
	je	strCountDone
	inc	rbx
	inc	rdx
	jmp	strCountLoop
strCountDone:

	cmp	rdx, 0
	je	prtDone

; -----
;  Call OS to output string.

	mov	rax, SYS_write			; system code for write()
	mov	rsi, rdi			; address of characters to write
	mov	rdi, STDOUT			; file descriptor for standard in
						; EDX=count to write, set above
	syscall					; system call

; -----
;  String printed, return to calling routine.

prtDone:
	pop	rbx
	ret

; ******************************************************************

