%include "lib.inc"
%include "macro.inc"

	global _start

%include "word.asm"
%include "test.asm"

	section .text

interpreter:
	call find_and_cfa_test
	jmp i_exit
	
_start:
	jmp interpreter
