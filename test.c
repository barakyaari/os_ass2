#include "types.h"
#include "user.h"

// static void myHandler(int pid, int value){

// }

int
main(int argc, char *argv[]){
	printf(1, "     Welcome to Testing File!!!\n");
	printf(1, "*************************************\n");
    //sig_handler handler = (sig_handler)myHandler;
    //sigsend(handler);
	printf(1, "My pid is: %d\n", getpid());

	printf(1, "My pid is: %d\n", getpid());
	fork();
	if(getpid() == 4){
		sigpause();
	}
	if(getpid() == 3){
		printf(1, "calling Sigsend\n");
		sigsend(4, 11);	
		sigsend(4, 12);	
		sigsend(4, 13);	
		wait();
	}
	sigsend(1, 101);
	printf(1, "Pid: %d\n", getpid());
	exit();
}

