%include "lib.inc"
%include "macro.inc"

	global _start

	%define pc r14
	%define w  r15
	%define rstack r13

	section .bss
	resq 1023
rstack_start:	 resq 1
input_buffer:	 resb 1024

%include "word.asm"
%include "test.asm"

	section .text

main: dq xt_interpreter
	dq xt_bye

init:
	mov rstack, rstack_start
	mov pc, main
	jmp next

next:
	mov w, [pc]
	add pc, 8
	jmp [w]

;;; interpreter loop
	section .data
interpreter_stub: dq 0
	section .text
xt_interpreter: dq i_docol
i_interpreter:
	dq xt_scan
	dq xt_loop

_start:
	jmp init
