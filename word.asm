%include "macro.inc"

	;; ( addr -- addr )
	;; ptr to string
	;; ptr to word header, or zero if nothing
native "find", find, 0
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


native "cfa", cfa, 0
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

native "exit", exit, 0
	mov rax, 60
	xor rdi, rdi
	syscall

native "dict_entry_stub", dict_entry_stub, 0
