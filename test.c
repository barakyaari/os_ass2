#include "types.h"
#include "user.h"

int myHandler(int value){
  printf(1, "myHandler!\n");
  if(value == 0){
  	printf(1, "workder %d exit\n", getpid());
  }
  return -1;
}

int
main(int argc, char *argv[]){
	printf(1, "     Welcome to Testing File!!!\n");
	printf(1, "*************************************\n");

	printf(1, "My pid is: %d\n", getpid());
		sigset((int*) myHandler);

	if(fork() == 0){
		printf(1, "calling Sigsend\n");
		sigsend(4, 11);
		//sigsend(4, 12);
		//sigsend(4, 13);
		wait();
		sigsend(1, 101);

	}
	else{
		sigset((int*) myHandler);
		printf(1, "Signal set!!!!!\n");
		sigpause();
	}
	printf(1, "Pid: %d\n", getpid());
	exit();
}
