#include "systemcalls.h"
#include <stdlib.h>
#include <syslog.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <aio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

/**
 * @param cmd the command to execute with system()
 * @return true if the command in @param cmd was executed
 *   successfully using the system() call, false if an error occurred,
 *   either in invocation of the system() call, or if a non-zero return
 *   value was returned by the command issued in @param cmd.
*/
bool do_system(const char *cmd)
{

/*
 * TODO  add your code here
 *  Call the system() function with the command set in the cmd
 *   and return a boolean true if the system() call completed with success
 *   or false() if it returned a failure
*/
    openlog("do_system", LOG_PID, LOG_USER);
    syslog(LOG_NOTICE, "Opened log. Starting attempt to call `system`.");

    int res = system(cmd);
    int err = errno;

    if( WIFEXITED(res) ) {
	syslog(LOG_NOTICE, "`system` call exited correctly.");
	return true;
    }
    else {
	syslog(LOG_ERR, "Error number is ");
	fprintf(stderr, "Failure: %s\n", strerror(err));
	return false;
    }

}

/**
* @param count -The numbers of variables passed to the function. The variables are command to execute.
*   followed by arguments to pass to the command
*   Since exec() does not perform path expansion, the command to execute needs
*   to be an absolute path.
* @param ... - A list of 1 or more arguments after the @param count argument.
*   The first is always the full path to the command to execute with execv()
*   The remaining arguments are a list of arguments to pass to the command in execv()
* @return true if the command @param ... with arguments @param arguments were executed successfully
*   using the execv() call, false if an error occurred, either in invocation of the
*   fork, waitpid, or execv() command, or if a non-zero return value was returned
*   by the command issued in @param arguments with the specified arguments.
*/

bool do_exec(int count, ...)
{
    va_list args;
    va_start(args, count);
    char * command[count+1];
    char whole_cmd[100] = "";
    int i;
    for(i=0; i<count; i++)
    {
        command[i] = va_arg(args, char *);
	strcat(whole_cmd, command[i]);
        if (i < count - 1)
            strcat(whole_cmd, " ");
    }
    command[count] = NULL;
    // this line is to avoid a compile warning before your implementation is complete
    // and may be removed
    // command[count] = command[count];
    va_end(args);

/*
 * TODO:
 *   Execute a system command by calling fork, execv(),
 *   and wait instead of system (see LSP page 161).
 *   Use the command[0] as the full path to the command to execute
 *   (first argument to execv), and use the remaining arguments
 *   as second argument to the execv() command.
 *
*/
    int status;
    pid_t pid;
    int ret;
    int err;
    // char * arr[] = {"this", "is", "a", "test", NULL};


    openlog("do_exec", LOG_PID, LOG_USER);
    syslog(LOG_NOTICE, "Opened log. Calling `fork`.");
    pid = fork();
    if( pid == -1 ) {        // fork errored
	perror("Error invoking `fork`.");
	syslog( LOG_ERR, "Error invoking `fork`.");
	return false;
    } else if ( pid == 0 ) { // we are the child
	syslog(LOG_NOTICE, "Calling `execv` with args: %s, %s, ...",command[0],whole_cmd);
	ret = execv(command[0],command);
	if( ret == -1 ){
	    err = errno;
	    fprintf(stderr,"Error invoking `execv`: %s", strerror(err) );
	    syslog( LOG_ERR, "Error invoking `execv`.");
	    exit(-1);
	}
	syslog( LOG_NOTICE, "`execv` completed with result: %d", ret);
	return ret;
    }

    syslog(LOG_NOTICE, "Calling `wait`.");
    pid = wait( &status );
    if ( pid == -1 ) {
	perror("Error waiting on child");
	syslog(LOG_ERR, "Error waiting on child.");
	return false;
    }

    if ( WIFEXITED(status) ) {
	syslog(LOG_NOTICE, "Child exited sucessfully.");
	syslog(LOG_NOTICE, "Child exit code: %d", WEXITSTATUS(status) );
	if ( WEXITSTATUS(status) == 0 )
	    return true;
    }

    return false;
}

/**
* @param outputfile - The full path to the file to write with command output.
*   This file will be closed at completion of the function call.
* All other parameters, see do_exec above
*/
bool do_exec_redirect(const char *outputfile, int count, ...)
{
    va_list args;
    va_start(args, count);
    char * command[count+1];
    int i;
    for(i=0; i<count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;
    // this line is to avoid a compile warning before your implementation is complete
    // and may be removed
    command[count] = command[count];


/*
 * TODO
 *   Call execv, but first using https://stackoverflow.com/a/13784315/1446624 as a refernce,
 *   redirect standard out to a file specified by outputfile.
 *   The rest of the behaviour is same as do_exec()
 *
*/

    va_end(args);

    return true;
}
