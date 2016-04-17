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
	if(argc <= 1){
		printf(1, "Please enter a number of threads to start as an argument\n");
		return 0;
	}
	printf(1, "     Welcome to Primsrv testing!!!\n");
	printf(1, "*************************************\n");

	int n = atoi(argv[1]);
	int workerPids[n];
	int working[n];
	printf(1, "workers pids:\n");
	int i;
	for(i = 0; i < n; i++){
			int pid = fork();
			if(pid == 0){ // Is child process?
				sigset((int*)myHandler);
				sigpause();
				exit();
			}

			else{
				printf(1, "%d\n", pid);
				workerPids[i] = pid;
			}
	}
		for(i = 0; i < n; i++){
			printf(1, "[%d-%d]\n", i, workerPids[i]);
		}

		while(1){
			printf(1, "Please enter a number:\n");
			char input[128];
			gets(input, 128);
			int num = atoi(input);

			if(num != 0 && num !=atoi("\n")){
				for(i = 0; i < n; i++){
					if(!working[i]){//check if worker i is working
						sigsend(workerPids[i], num);
						working[i] = 1;
						break;
					}
				}
				printf(1, "no idle workers\n");
			}
			else if (num == 0){
				printf(1, "Sending exit to all workers!\n");
				for(i = 0; i < n; i++){
					sigsend(workerPids[i], 101);
				}
			}
		}
}

