build: asm
asm:
	as -g --32 $(ASM).s -o $(ASM).o
	ld -m elf_i386 $(ASM).o -o run
	rm $(ASM).o

clean:
	rm run
