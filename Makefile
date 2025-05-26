all: main.out

main.out: main.o logic.o
	ld -o main.out main.o m

main.o: main.asm
	fasm main.asm

life_logic.o: life_logic.asm
	fasm life_logic.asm

clean:
	rm -f *.o *.out