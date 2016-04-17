#include "types.h"
#include "user.h"
typedef void (*sig_handler)(int pid, int value);

sig_handler myHandler(int pid, int value){
  printf(1, "myHandler!\n");
  return (sig_handler)-1;  	
}

int
main(int argc, char *argv[]){
	printf(1, "     Welcome to Testing File!!!\n");
	printf(1, "*************************************\n");

	printf(1, "My pid is: %d\n", getpid());
		sigset((sig_handler)myHandler);

	if(fork() == 0){
		printf(1, "calling Sigsend\n");
		sigsend(4, 11);
		//sigsend(4, 12);
		//sigsend(4, 13);
		wait();
		sigsend(1, 101);

	}
	else{
		sigset((sig_handler)myHandler);
		printf(1, "Signal set!!!!!\n");
		sigpause();
	}
	printf(1, "Pid: %d\n", getpid());
	exit();
}
