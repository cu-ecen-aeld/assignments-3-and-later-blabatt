default compile: writer.c
	$(CROSS_COMPILE)gcc -g -Wall -c -o writer.o writer.c
	$(CROSS_COMPILE)gcc -g -Wall -I/ writer.o -o writer

run: compile
	./writer a b

clean:
	rm -f *.o writer *.elf *.map

test:
	./finder-test.sh

