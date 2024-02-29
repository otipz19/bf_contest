nasm -f elf32 bf_contest.asm -o bin/bf_contest.o &&
ld -m elf_i386 -s -o bin/bf_contest.out bin/bf_contest.o &&
rm bin/bf_contest.o
