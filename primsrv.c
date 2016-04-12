#include "types.h"
#include "user.h"

// static void myHandler(int pid, int value){

// }

int
main(int argc, char *argv[]){
	if(argc <= 1){
		printf(1, "Please enter a number of threads to start as an argument\n");
		return 0;
	}
	printf(1, "     Welcome to Testing File!!!\n");
	printf(1, "*************************************\n");

	int n = atoi(argv[1]);
	int workerPids[n];
	int workerIndex = 0;
	printf(1, "workers pids:\n");
	int myPid = getpid();
	int i;
	for(i = 0; i < n; i++){
		if(getpid() == myPid){
			int pid = fork();
			if(getpid() == myPid){
				printf(1, "%d\n", pid);
				workerPids[workerIndex++] = pid;

			}

		}
	}
	if(getpid() == myPid){
		int i;
		for(i = 0; i < n; i++){
			printf(1, "[%d-%d]\n", i, workerPids[i]);
		}
		while(1){
			printf(1, "Please enter a number:\n");
			char input[10];
			gets(input, 10);
			int num = atoi(input);
			if(input != 0){
				for(i = 0; i < n; i++){
					//Check if the worker is idle...
				}
				sigsend(getpid()+1, num);
			}
			printf(1, "got: %s\n", input);

		}
	}
	else{
		sigpause();
	}
	exit();
}

