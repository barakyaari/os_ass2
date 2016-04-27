#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "x86.h"
#include "proc.h"
#include "spinlock.h"

typedef void (*sig_handler)(int pid, int value);

struct {
  struct spinlock lock;
  struct proc proc[NPROC];
} ptable;

static struct proc *initproc;


int nextpid = 1;
extern void forkret(void);
extern void trapret(void);
struct cstackframe;
static void wakeup1(void *chan);

void printpending_signals(){
  struct cstackframe *frame = proc->pending_signals.head;
  int i = 0;
  cprintf("----------- Printing pending signals: ----------\n");

  while(frame != 0){
    cprintf("------ #%d -------\n", i);
    cprintf("sender_pid: %d\n", frame->sender_pid);
    cprintf("recepient_pid: %d\n", frame->recepient_pid);
    cprintf("value: %d\n", frame->value);
    cprintf("used: %d\n", frame->used);
    cprintf("------------------\n\n");
    frame = frame->next;
    i++;
  }
}

void
pinit(void)
{
  struct proc * p;
  int i;

  initlock(&ptable.lock, "ptable");
  acquire(&ptable.lock);
//Set the pendingSignals and signal variables:
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  {
    p->pending_signals.head = &(p->pending_signals.frames[0]);

    p->pending_signals.frames[9].next = 0;

    for(i = 0; i < 9; i++){
      //Set the next signal for the frames:
      p->pending_signals.frames[i].next = &p->pending_signals.frames[i + 1];
    }

    p->isHandlingSignal = 0;
  }
  release(&ptable.lock);}

  int 
  allocpid(void) 
  {
    int pid;
    pid = nextpid;
    while(!cas(&nextpid, nextpid, nextpid+1)){
     pid = nextpid;
   }
   return pid;
 }
//PAGEBREAK: 32
// Look in the process table for an UNUSED proc.
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
 static struct proc*
 allocproc(void)
 {
  struct proc *p;
  char *sp;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
   if(cas(&(p->state), UNUSED, EMBRYO)){
    goto found;
  }

}
return 0;
found:
p->pid = allocpid();

  // Allocate kernel stack.
if((p->kstack = kalloc()) == 0){
  p->state = UNUSED;
  return 0;
}
sp = p->kstack + KSTACKSIZE;

  // Leave room for trap frame.
sp -= sizeof *p->tf;
p->tf = (struct trapframe*)sp;

  // Set up new context to start executing at forkret,
  // which returns to trapret.
sp -= 4;
*(uint*)sp = (uint)trapret;

sp -= sizeof *p->context;
p->context = (struct context*)sp;
memset(p->context, 0, sizeof *p->context);
p->context->eip = (uint)forkret;
    //Initialize handler:
p->handler = (void*) -1;

int i;

for(i = 0; i < 10; i++){
  p->pending_signals.frames[i].sender_pid = 0;
  p->pending_signals.frames[i].recepient_pid = 0;
  p->pending_signals.frames[i].value = 0;
  p->pending_signals.frames[i].used = 0;
  p->pending_signals.frames[i].next = 0;
}

return p;
}

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
  initproc = p;
  if((p->pgdir = setupkvm()) == 0)
    panic("userinit: out of memory?");
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
  p->sz = PGSIZE;
  memset(p->tf, 0, sizeof(*p->tf));
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
  p->tf->es = p->tf->ds;
  p->tf->ss = p->tf->ds;
  p->tf->eflags = FL_IF;
  p->tf->esp = PGSIZE;
  p->tf->eip = 0;  // beginning of initcode.S

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  //Initialize handler:
  p->handler = (void*) -1;

  p->state = RUNNABLE;
}

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  uint sz;
  
  sz = proc->sz;
  if(n > 0){
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
      return -1;
  } else if(n < 0){
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
      return -1;
  }
  proc->sz = sz;
  switchuvm(proc);
  return 0;
}

// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
    return -1;

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
    kfree(np->kstack);
    np->kstack = 0;
    np->state = UNUSED;
    return -1;
  }
  np->sz = proc->sz;
  np->parent = proc;
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
    np->cwd = idup(proc->cwd);

    safestrcpy(np->name, proc->name, sizeof(proc->name));

    pid = np->pid;


    np->handler = proc->handler;
    np->isHandlingSignal = 0;
    np->pending_signals.head = &(np->pending_signals.frames[0]);
    for (i = 0; i < 10; i++){
      np->pending_signals.frames[i].used = 0;
    }
  // lock to force the compiler to emit the np->state write last.
    acquire(&ptable.lock);
    np->state = RUNNABLE;
    release(&ptable.lock);

    return pid;
  }

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
  void
  exit(void)
  {
    struct proc *p;
    int fd;

    if(proc == initproc)
      panic("init exiting");

  // Close all open files.
    for(fd = 0; fd < NOFILE; fd++){
      if(proc->ofile[fd]){
        fileclose(proc->ofile[fd]);
        proc->ofile[fd] = 0;
      }
    }

    begin_op();
    iput(proc->cwd);
    end_op();
    proc->cwd = 0;

    acquire(&ptable.lock);

    proc->state = ZOMBIE;

  // Parent might be sleeping in wait().
    wakeup1(proc->parent);

  // Pass abandoned children to init.
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent == proc){
        p->parent = initproc;
        if(p->state == ZOMBIE)
          wakeup1(initproc);
      }
    }

  // Jump into the scheduler, never to return.

    sched();
    panic("zombie exit");
  }

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
  int
  wait(void)
  {
    struct proc *p;
    int havekids, pid;

    acquire(&ptable.lock);
    for(;;){
      proc->chan = (int)proc;
      proc->state = SLEEPING;    
    // Scan through table looking for zombie children.
      havekids = 0;
      for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
        if(p->parent != proc)
          continue;
        havekids = 1;
        if(p->state == ZOMBIE){
        // Found one.
          pid = p->pid;
          p->state = UNUSED;
          p->pid = 0;
          p->parent = 0;
          p->name[0] = 0;

          proc->chan = 0;
          proc->state = RUNNING;
          release(&ptable.lock);
          return pid;
        }
      }

    // No point waiting if we don't have any children.
      if(!havekids || proc->killed){
        proc->chan = 0;
        proc->state = RUNNING;      
        release(&ptable.lock);
        return -1;
      }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
      sched();
    }
  }

  void 
  freeproc(struct proc *p)
  {
    if (!p || p->state != ZOMBIE)
      panic("freeproc not zombie");
    kfree(p->kstack);
    p->kstack = 0;
    freevm(p->pgdir);
    p->killed = 0;
    p->chan = 0;
  }

//PAGEBREAK: 42
// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
  void
  scheduler(void)
  {
    struct proc *p;

    for(;;){
    // Enable interrupts on this processor.
      sti();

    // Loop over process table looking for process to run.
      acquire(&ptable.lock);
      for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
        if(p->state != RUNNABLE)
          continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
        proc = p;
        switchuvm(p);
        p->state = RUNNING;
        swtch(&cpu->scheduler, proc->context);
        switchkvm();

      // Process is done running for now.
      // It should have changed its p->state before coming back.
        proc = 0;
        if (p->state == ZOMBIE)
          freeproc(p);
      }
      release(&ptable.lock);

    }
  }

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
  void
  sched(void)
  {
    int intena;

    if(!holding(&ptable.lock))
      panic("sched ptable.lock");
    if(cpu->ncli != 1)
      panic("sched locks");
    if(proc->state == RUNNING)
      panic("sched running");
    if(readeflags()&FL_IF)
      panic("sched interruptible");
    intena = cpu->intena;
    swtch(&proc->context, cpu->scheduler);
    cpu->intena = intena;
  }

// Give up the CPU for one scheduling round.
  void
  yield(void)
  {
  acquire(&ptable.lock);  //DOC: yieldlock
  proc->state = RUNNABLE;
  sched();
  release(&ptable.lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);

  if (first) {
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
    initlog();
  }

  // Return to "caller", actually trapret (see allocproc).
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  if(proc == 0)
    panic("sleep");

  if(lk == 0)
    panic("sleep without lk");

  // Must acquire ptable.lock in order to
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
    acquire(&ptable.lock);  //DOC: sleeplock1
    release(lk);
  }

  // Go to sleep.
  proc->chan = (int)chan;
  proc->state = SLEEPING;


  sched();

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
    release(&ptable.lock);
    acquire(lk);
  }
}

//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == SLEEPING && p->chan == (int)chan){
      // Tidy up.
      p->chan = 0;
      p->state = RUNNABLE;
    }
  }

// Wake up all processes sleeping on chan.
  void
  wakeup(void *chan)
  {
    acquire(&ptable.lock);
    wakeup1(chan)
    ;release(&ptable.lock);
  }

// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
  int
  kill(int pid)
  {
    struct proc *p;


    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->pid == pid){
        p->killed = 1;
      // Wake process from sleep if necessary.
        if(p->state == SLEEPING)
          p->state = RUNNABLE;
        release(&ptable.lock);
        return 0;
      }
    }
    release(&ptable.lock);
    return -1;
  }

//PAGEBREAK: 36
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
  void
  procdump(void)
  {
    static char *states[] = {
      [UNUSED]    "unused",
      [EMBRYO]    "embryo",
      [SLEEPING]  "sleep ",
      [RUNNABLE]  "runble",
      [RUNNING]   "run   ",
      [ZOMBIE]    "zombie"
    };
    int i;
    struct proc *p;
    char *state;
    uint pc[10];

    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state == UNUSED)
        continue;
      if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
        state = states[p->state];
      else
        state = "???";
      cprintf("%d %s %s", p->pid, state, p->name);
      if(p->state == SLEEPING){
        getcallerpcs((uint*)p->context->ebp+2, pc);
        for(i=0; i<10 && pc[i] != 0; i++)
          cprintf(" %p", pc[i]);
      }
      cprintf("\n");
    }
  }

  sig_handler sigset(sig_handler sigHandler){
    proc->handler = sigHandler;
    return sigHandler;
  }

  int sigsend(int dest_pid, int value){
    struct proc* process;
    for(process = ptable.proc; process < &ptable.proc[NPROC]; process++){
     if(process->pid == dest_pid){
      break;
    }
  }
  if(process >= &ptable.proc[NPROC] && process->state < 2 && process-> state > 4){
    return -1;
  }

  return push(&process->pending_signals, proc->pid, dest_pid, value);
}


void sigret(void){
  //Copy the trapframe:
  memmove(proc->tf, &proc->trapFrameCopy, sizeof(proc->trapFrameCopy) );
  proc->isHandlingSignal = 0;
}

//Suspend the process until a new signal is received
int sigpause(void){
  struct proc* tmpProcess = proc;
  if(proc->pending_signals.head->used == 0){
    acquire(&ptable.lock);
    tmpProcess->chan = (int)&tmpProcess->handler;
    tmpProcess->state = SLEEPING; 
    sched(); 
    release(&ptable.lock);
  }
  return 0;
}

//adds a new frame to the cstack which is initialized with
//values sender_pid, recepient_pid and value, then returns 1 on success
//and 0 if the stack is full.
int push(struct cstack *cstack, int sender_pid, int recepient_pid, int value){
              //Allocate a free cstackframe:
  int i;
  struct cstackframe *frame;
  int foundFrame = -1;
  for(i = 0; i < 10; i++){
   frame = &cstack->frames[i];
   if(!frame->used){
    foundFrame = i;
    break;
  }
}
if(foundFrame == -1){
 return 0;
}

//add the free cstackframe to the head of the cstack:
//Check for empty stack:
if(cstack->head == 0){
  frame->next = 0;
  cstack->head = frame;
}
else{
  frame->next = cstack->head;
  cstack->head = frame;
}
cstack->signalsCount++;
frame->sender_pid = sender_pid;
frame->recepient_pid = recepient_pid;
frame->value = value;
frame->used = 1;
//Wakeup the process that is sleeping on channel:
struct proc* p;
for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  if(p->pid==recepient_pid){
    wakeup((void*)&p->handler);
    return 1;
  }
}
return 1;
}

struct cstackframe *pop(struct cstack *cstack){
  if(cstack->head == 0)
    return 0;

  struct cstackframe *ans = cstack->head;
  ans->next = cstack->head;
  while(!cas((int*)&cstack->head, (int)ans, (int)ans->next)){
    ans = cstack->head;
  }
  //Should "used" be changed here??
  cstack->signalsCount--;
  return ans;
}

extern int code_start();
extern int code_end();


void do_signal(void){
  struct cstackframe *stackframe;

  if(!proc)
    return;

  if(!(proc->pending_signals.head->used>0 && (proc->tf->cs&3) == 3))
    return;

  if(proc->isHandlingSignal)
    return;

  if((int)proc->handler == -1)
  {
    do{
      stackframe = pop(&proc -> pending_signals);
    } //Should be only once maybe?
    while(stackframe);
  }

  else if (!proc->isHandlingSignal){

    proc->isHandlingSignal = 1;
    //Copy trapframe:
    memmove(&proc->trapFrameCopy, proc->tf, sizeof(proc->trapFrameCopy));
    stackframe = pop(&proc->pending_signals);
    int bytesToCopy = (int)&code_end - (int)&code_start;
    stackframe->used = 0;
		 	//Set esp to include padding:
    proc->tf->esp -= bytesToCopy;

			//Copy the call to sigret and interrupt to the
			//User stack:
    void * espBackup = (void *)(proc->tf->esp - bytesToCopy); //backup the return address from sig_handler which we wish to postpone after calling to sig_ret
    memmove((void *)(proc->tf->esp - bytesToCopy),  code_start, bytesToCopy);//copy the injected code to the users stack
    proc->tf->esp -= bytesToCopy;

    memmove((int *)(proc->tf->esp - sizeof(stackframe->value)),  &(stackframe->value), sizeof(stackframe->value)); //push sig_handler args to the stack
    proc->tf->esp -= sizeof(stackframe->value);
    memmove( (int *)((proc->tf->esp) - sizeof(stackframe->sender_pid)),  &(stackframe->sender_pid), sizeof(stackframe->sender_pid));
    proc->tf->esp -= sizeof(stackframe->sender_pid);

    memmove( (void **)((proc->tf->esp) - sizeof(void *)), &espBackup, sizeof(espBackup) ); //return address:
    proc->tf->esp -= sizeof (void*);

    void * ebp = (void *) (proc->tf->ebp);
    memmove( (void **)((proc->tf->esp) - sizeof(void *)), &ebp, sizeof(ebp) ); //stack pointer restore:

		    //The signal handler's code should run after returning from the
		    //Kernnel/
    proc->tf->ebp = proc->tf->esp;

    proc->tf->eip = (uint)proc->handler;
  }
}