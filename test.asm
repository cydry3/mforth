	section .data
testdata:
	db "cfa", 0

	section .text

find_test_impl:
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

cfa_test_impl:
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
	call find_test_impl
	call test_bye

cfa_test:
	mov rdi, w_bye 	; w_find is test word
	call cfa_test_impl
	call test_bye

find_and_cfa_test:
	mov rdi, testdata
	mov rsi, w_dict_entry_stub
	call find_test_impl
	mov rdi, rax
	call cfa_test_impl
	call test_bye

test_bye:
	mov rax, 60
	xor rdi, rdi
	syscall
