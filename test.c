#include "types.h"
#include "user.h"
typedef void (*sig_handler)(int pid, int value);

void myHandler(int pid, int value){
  printf(1, "myHandler!\n");
}

int
main(int argc, char *argv[]){
	// printf(1, "     Welcome to Testing File!!!\n");
	// printf(1, "*************************************\n");

	// printf(1, "My pid is: %d\n", getpid());
	int i = 0;
	for(i = 0; i < 10; i++){
		if(fork() == 0){
			goto done;
		}
	}
	done:
	// printf(1, "Pid: %d\n", getpid());
	// exit();
	return 0;
}
