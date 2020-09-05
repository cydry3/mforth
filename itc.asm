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
	push rsi
	.loop:
	;; check if word header is NOT NULL
	pop rsi
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

cfa:
;;; previous word
	add rdi, 8
;;; word
	.loop:
	push rdi
	mov al, [rdi]
	test al, al
	jz .exit
	pop rdi
	add rdi, 1
	jmp .loop
	.exit:
	pop rdi
	add rdi, 1
;;; flag
	add rdi, 1
	mov rax, rdi
	ret

find_test:
	mov rdi, testdata
	mov rsi, w_dict_entry_stub
	call i_find
	call test_exit

cfa_test:
	mov rdi, w_exit 	; w_find is test word
	call cfa
	call test_exit

find_and_cfa_test:
	mov rdi, testdata
	mov rsi, w_dict_entry_stub
	call i_find
	mov rdi, rax
	call cfa
	call test_exit

test_exit:
	mov rax, 60
	xor rdi, rdi
	syscall

_start:
	jmp find_and_cfa_test
	
