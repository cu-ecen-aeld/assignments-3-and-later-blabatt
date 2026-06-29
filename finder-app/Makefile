BUILD ?= .
DEST ?= ${BUILD}

default writer: writer.c
	$(CROSS_COMPILE)gcc -g -Wall -c -o $(BUILD)/writer.o writer.c
	$(CROSS_COMPILE)gcc -g -Wall -I/ $(BUILD)/writer.o -o $(BUILD)/writer
	# $(CROSS_COMPILE)gcc -g -Wall -c -o $(BUILD)/writer.o writer.c

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

