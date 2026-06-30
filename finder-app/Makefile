# CROSS_COMPILE ?= aarch64-none-linux-gnu-gcc # shouldn't need this from buildroot if using $(CC)
BUILD ?= .
DEST ?= ${BUILD}
CC ?= $(CROSS_COMPILE)gcc

default writer: writer.c
	$(CC) $(CFLAGS) $(INCLUDES) -g -Wall -c -o $(BUILD)/writer.o writer.c
	$(CC) $(CFLAGS) $(INCLUDES) -g -Wall -I/ $(BUILD)/writer.o -o $(BUILD)/writer
	# $(CC) -g -Wall -c -o $(BUILD)/writer.o writer.c

install:
	mkdir -p $(DEST)
	cp $(BUILD)/writer.o $(DEST)/writer
	cp writer.sh $(DEST)/
	cp finder.sh $(DEST)/
	chmod 744 $(DEST)/writer
	chmod 744 $(DEST)/writer.sh
	chmod 744 $(DEST)/finder.sh

clean:
	-rm $(BUILD)/writer.o
	-rm $(BUILD)/writer

