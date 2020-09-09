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
stack_base:	resq 1
stack_cur:	resq 1
forth_mem:	resq 65536
last_def_word:	resq 1
extended_dict:	resq 65536
ext_dict_here:	resq 1
mode:		resq 1

%include "word.asm"

	section .data
interpreter_stub: dq 0
interpreter_loop: dq interpreter_stub

	section .data
compiler_stub: dq 0
compiler_loop: dq compiler_stub

	section .text
init:
	mov qword[mode], 0
	mov qword[ext_dict_here], extended_dict
	mov qword[last_def_word], w_dict_entry_stub
	mov [stack_base], rsp
	mov rax, [stack_base]
	mov [stack_cur], rax
	mov rstack, rstack_start
	mov qword[interpreter_stub], xt_interpreter
	mov pc, interpreter_stub
	jmp next

next:
	mov w, [pc]
	add pc, 8
	jmp [w]

_start:
	jmp init
