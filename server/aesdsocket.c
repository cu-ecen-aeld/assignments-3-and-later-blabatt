#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <syslog.h>

int main() {
    openlog(LOG_INFO,...);

    // printf("Attempting to write to syslog\n");
    openlog(NULL, LOG_PID, LOG_USER);
    syslog(LOG_INFO, "Writing syslog logs...");

    fd = socket(AF_INET,SOCKET_STREAM,0);
    if(!fd) {
	syslog(LOG_ERR,"Unable to secure a socket file descriptor.");
	return -1;
    }

    // other steps

    return 0;
}
