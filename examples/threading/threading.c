#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param)
{
    int ret;

    // hint: use a cast like the one below to obtain thread arguments from your parameter
    //struct thread_data* thread_func_args = (struct thread_data *) thread_param;
    struct thread_data* thread_func_args = (struct thread_data *) thread_param;

    // wait
    usleep(thread_func_args->wait_obtain);

    // obtain mutex (assume already initialized via:
    // pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
    // per p236 in LSP.
    ret = pthread_mutex_lock(thread_func_args->mutex);
    if(ret) {
	perror("mutex lock");
	thread_func_args->thread_complete_success = false;
	return thread_param;
    }

    // wait
    usleep(thread_func_args->wait_release);

    // release mutex as described by thread_data structure
    ret = pthread_mutex_unlock(thread_func_args->mutex);
    if(ret) {
	perror("mutex unlock");
	thread_func_args->thread_complete_success = false;
	return thread_param;
    }

    thread_func_args->thread_complete_success = true;
    // pthread_exit(thread_param);
    return thread_func_args; // thread_param; // question: no need to use `pthread_exit()` here instead?
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex, int wait_to_obtain_ms, int wait_to_release_ms)
{
     int ret;

     // allocate memory for thread_data:
     struct thread_data* the_thread_data = malloc(sizeof(struct thread_data));

     // setup mutex and wait arguments:
     // mutex = PTHREAD_MUTEX_INITIALIZER; // <-- is this line needed for initializing mutex?
     //if (pthread_mutex_init(mutex, NULL) != 0) {
     //    printf("Mutex initialization failed\n");
     //    return 1;
     //}

     the_thread_data->mutex = mutex;
     the_thread_data->wait_obtain  = wait_to_obtain_ms;
     the_thread_data->wait_release = wait_to_release_ms;

     // pass thread_data to created thread using threadfunc() as entry point.
     // if successful, @param thread should be filled with the pthread_create thread ID 
     ret = pthread_create(thread, NULL, threadfunc, the_thread_data);

     // if successful:
     if(!ret) { // success
	return true;
     }

    return false;
}

