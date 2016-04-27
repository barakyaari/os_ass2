#include "types.h"
#include "user.h"
typedef void (*sig_handler)(int pid, int value);

void myHandler(int pid, int value){
  printf(1, "myHandler!\n");
}

int
main(int argc, char *argv[]){
	printf(1, "     Welcome to Testing File!!!\n");
	printf(1, "*************************************\n");

	printf(1, "My pid is: %d\n", getpid());
		sigset((void*)myHandler);

	if(fork() == 0){
		printf(1, "calling Sigsend\n");
		sigsend(4, 11);
		//sigsend(4, 12);
		//sigsend(4, 13);
		sigpause();
		sigsend(1, 101);

	}
	printf(1, "Pid: %d\n", getpid());
	exit();
}
