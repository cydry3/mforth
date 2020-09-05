%include "lib.inc"
%include "macro.inc"


	global _start

	section .data
testdata:
	db "cfa", 0

%include "word.inc"

	section .text

	;; ( addr -- addr )
	;; ptr to string
	;; ptr to word header, or zero if nothing
i_find:
	.loop:
	;; check if word header is NOT NULL
	push rsi
	test rsi, rsi
	jz .exit
	pop rsi

	;; next pointer is NOT NULL
	mov rsi, [rsi]
	push rsi
	test rsi, rsi
	jz .exit
	pop rsi

	;; successive headerpointer
	push rsi
	add rsi, 8

	call string_equals
	test al, al
	jz .loop

	pop rsi
	mov rax, rsi
	ret

	.exit:
	pop rsi
	xor rsi, rsi
	xor rax, rax
	ret

find_test:
	mov rdi, testdata
	mov rsi, w_dict_entry_stub
	call i_find
	mov rax, 60
	xor rdi, rdi
	syscall

_start:
	jmp find_test
	
