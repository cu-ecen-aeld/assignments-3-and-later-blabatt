SRC := finder-app
BUILD := build

default writer: $(SRC)/writer.c
	$(CROSS_COMPILE)gcc -g -Wall -c -o $(BUILD)/writer.o $(SRC)/writer.c
	cp $(BUILD)/writer.o $(BUILD)/writer
	chmod 644 $(BUILD)/writer

clean:
	rm $(BUILD)/writer.o

