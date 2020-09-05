%include "lib.inc"
%include "macro.inc"

	global _start

	%define pc r14
	%define w  r15

%include "word.asm"
%include "test.asm"

	section .text

main: dq xt_interpreter

init:
	mov pc, main
	jmp next

next:
	mov w, [pc]
	add pc, 8
	jmp [w]

xt_interpreter: dq i_interpreter
i_interpreter:
	jmp i_bye
	
_start:
	jmp init
