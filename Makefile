AFLAGS=-felf64 -g -F dwarf
ASM=nasm

all: main

main: itc.o 
	ld -o main itc.o 

itc.o: itc.asm lib.inc macro.inc word.asm
	$(ASM) $(AFLAGS) itc.asm 

clean:
	rm -f main itc.o

asm:
	nasm -E word.inc

.PHONY:
	clean asm
