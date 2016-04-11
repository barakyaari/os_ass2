#include "types.h"
#include "user.h"

// static void myHandler(int pid, int value){

// }

int
main(int argc, char *argv[]){
    printf(1, "     Welcome to Testing File!!!\n");
    printf(1, "*************************************\n");
    //sig_handler handler = (sig_handler)myHandler;
    //sigset(handler);
    printf(1, "Pid: %d\n", getpid());
    exit();
}
