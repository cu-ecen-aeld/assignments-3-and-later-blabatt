BUILD := ../build
DEST ?= ${BUILD}

default writer: writer.c
	$(CROSS_COMPILE)gcc -g -Wall -c -o $(BUILD)/writer.o writer.c

install:
	cp $(BUILD)/writer.o $(DEST)/writer
	chmod 744 $(DEST)/writer

clean:
	rm $(BUILD)/writer.o

