	section .data
testdata:
	db "cfa", 0

	section .text
find_test:
	mov rdi, testdata
	mov rsi, w_dict_entry_stub
	call i_find
	call test_exit

cfa_test:
	mov rdi, w_exit 	; w_find is test word
	call i_cfa
	call test_exit

find_and_cfa_test:
	mov rdi, testdata
	mov rsi, w_dict_entry_stub
	call i_find
	mov rdi, rax
	call i_cfa
	call test_exit

test_exit:
	mov rax, 60
	xor rdi, rdi
	syscall
