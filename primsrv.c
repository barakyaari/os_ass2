#include "types.h"
#include "user.h"
int numberOfWorkers;
struct worker
{
	int request;
	int result;
	int pid;
	struct worker* nextWorker;
	struct worker* prevWorker;
}worker;

int isPrime(int n)
{
	if (n == 1 || (n%2 == 0)){
		return 0;
	}
	int i;
	for(i = 3; i * i < n; i = i + 2){
		if(n%i == 0)
			return 0;
	}
	return 1;
}

void workerHandler(int pid, int value){
	if(value == 0){
		//On Zero all workers should exit.
		printf(1, "worker %d exit\n", getpid());
		exit();
	}
	if(value < 0){
		sigsend(pid, 1);
	}
	while(1){
		if(isPrime(value)){
			break;
		}
		value++;
	}
	sigsend(pid, value);
}

void work(){
	while(1){
		sigpause();
	}
}

void initializeWorkers(int n, struct worker* head){
	int pid;
	struct worker* newWorker;
	//Initialize the first worker:
	head->prevWorker = 0;
	pid = fork();
	if(pid == 0){//is a worker
		sigset(workerHandler);
		work();
	}
	else{//is Primsrv:
		printf(1, "workers pids:\n");
		printf(1, "%d\n", pid);
		head->nextWorker = 0;
		head->pid = pid;

		//Init the rest of the workers:
		int i;
		for(i = 1; i < numberOfWorkers; i++){
			pid = fork();
			if(pid == 0){//Is a worker
				sigset(workerHandler);
				work();
			}
			else{//is primsrv:
				//add a new worker to the worker's list:
				printf(1, "%d\n", pid);
				newWorker = malloc(sizeof(worker));
				newWorker->nextWorker = 0;
				newWorker->prevWorker = head;
				newWorker->pid = pid;
				head->nextWorker = newWorker;
				head = newWorker;
			}
		}
	}


}

void myHandler(int pid, int value){
	struct worker * pointer = &worker;

	//get the correct worker (by pid):
	while (pointer->pid != pid)
	{
		pointer = pointer->nextWorker;
	}
	pointer->result = value;
}

void getResults(struct worker* head){
	struct worker* pointer = head;
	while(pointer!=0){
		if(pointer->result != 0){//Worker has result:
			printf(1, "worker %d returned %d as a result for %d\n", pointer->pid, pointer->result, pointer->request);
			pointer->result = 0;
			pointer->request = 0;
		}
		pointer = pointer->nextWorker;
	}
}

void sendSignalToWorker(int num, struct worker* head){
	while(head->request != 0){
		head = head->nextWorker;
		if(head == 0){
			printf(1, "no idle workers\n");
			return;
		}
	}
	head->request = num;
	sigsend(head->pid, num);
}

void endExecution(struct worker* head){
	struct worker* pointer = head;
	while(pointer != 0){//Send 0 to all workers:
		sigsend(pointer->pid, 0);
		pointer = pointer->nextWorker;
		sleep(15);
	}
	pointer = head;
	while(pointer != 0){//Wait for the workers to actually exit:
		wait();
		pointer = pointer->nextWorker;
	}
	printf(1, "primsrv exit\n");

}

int
main(int argc, char *argv[]){
	if(argc <= 1){
		printf(1, "Please enter a number of threads to start as an argument\n");
		return 0;
	}
	numberOfWorkers = atoi(argv[1]);
	initializeWorkers(numberOfWorkers, &worker);
	sigset(myHandler);
	while(1){
		char input[128];
		printf(1, "Please enter a number:\n");
		read(0, input, 1);

		if(*input == '\n'){
			getResults(&worker);
			continue;
		}

		int i = 0;
		while(input[i] != '\n' && i < 128){
			i++;
			read(0, input+i, 1);
		}
		input[i] = 0;
		int num = atoi(input);
		if (num == 0){
			break;
		}
		sendSignalToWorker(num, &worker);

	}
	endExecution(&worker);
	exit();
	return 0;
}

