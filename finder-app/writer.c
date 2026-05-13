/**
 * writer.c
 *
**/

#include <stdio.h>        // TODO: remove
#include <string.h>       // for `strlen` invocation
// #include <sys/klog.h>  // for `syslog` (syscall)
#include <syslog.h>	  // for `syslog`
#include <unistd.h>	  // for `write`
#include <sys/types.h>	  // for `open`
#include <sys/stat.h>	  // ibid
#include <sys/fcntl.h>	  // ibid
#include "writer.h"	  // my header

int main(int argc, char * argv[]){
    int ret;
    openlog("writer", 0, LOG_USER);
    syslog(LOG_NOTICE, "Invoking writer.");
    if (argc != 3) {
	syslog(LOG_ERR, "Invoked writer with incorrect number of arguments: %d instead of required 2.", argc-1);
        return 1; // better error msg? for faulty # args...
    }
    char * filetowrite = argv[1];
    char * strtowrite = argv[2];
    ret = writer(filetowrite, strtowrite);
    if ( ret == -1 ) {
	closelog();
	return 1;
    }
    syslog(LOG_NOTICE, "Wrote %d characters to %s file.", (int) strlen(strtowrite),filetowrite);
    closelog();
    return 0;
}

int writer(char * file, char * str){
    int fd; ssize_t nr; ssize_t nr2; int res;
    // printf("Write %s to the file %s",str,file);
    fd = open(file, O_WRONLY | O_CREAT, S_IRUSR | S_IWUSR);
    if (fd == -1) {
	syslog(LOG_ERR, "%m: Failed to open file located at: %s", file);
	return -1;
    }
    nr = write(fd, str, strlen(str));
    if( nr == -1) {
	syslog(LOG_ERR, "%m: Failed to write to file %s", file);
	// Try once more:
	nr = write(fd, str, strlen(str));
	if ( nr != -1 ) goto next ;
	return -1;
    } else {
	syslog(LOG_DEBUG, "Writing %s to file %s", str, file);
    }
    next:
    if (nr != strlen(str) ) {
	syslog(LOG_WARNING, "Unable to write full message %s to %s. Attempting again...", str, file);
	nr2 = write(fd, str + nr, strlen(str) - nr);
	if( (nr + nr2) != strlen(str) ) {
	    syslog(LOG_ERR, "Unable to write full message.");
	    return -1;
	} else if ( nr2 == -1 ) {
	    syslog(LOG_ERR, "Unable to write full message.");
	    return -1;
	}
    }
    res = close(fd);
    if (res == -1) {
	syslog(LOG_ERR, "%m: Failed to close file %s", file);
	return -1;
    }
    return 0;
}
