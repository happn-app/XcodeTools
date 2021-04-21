#include <dispatch/dispatch.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>



// CC=clang CFLAGS='-I/usr/lib/swift -fblocks' LDFLAGS='-L/usr/lib/swift/linux -lpthread -ldispatch -lBlocksRuntime' make signal-test-blocked
// LD_LIBRARY_PATH=/usr/lib/swift/linux ./signal-test-blocked

static int s = SIGTERM;

typedef enum thread_action_e {
	INIT = 0,
	WAIT_INIT,
	NOP,
	UNBLOCK_SIGNAL
} thread_action_t;

static thread_action_t thread_action = INIT;

static pthread_cond_t cond;
static pthread_mutex_t mutex;

static void action(int signal) {
	const char *str = "🚦 Got signal in sigaction\n";
	write(2, str, strlen(str));
}

static void *threadMain(void *info) {
	fprintf(stderr, "🧵 Thread starts!\n");
	
	pthread_mutex_lock(&mutex);
	thread_action = WAIT_INIT;
	pthread_mutex_unlock(&mutex);
	pthread_cond_signal(&cond);
	
	do {
		pthread_mutex_lock(&mutex);
		while (thread_action != UNBLOCK_SIGNAL)
			pthread_cond_wait(&cond, &mutex);
		pthread_mutex_unlock(&mutex);
		
		sigset_t set;
		sigemptyset(&set);
		sigaddset(&set, s);
		pthread_sigmask(SIG_UNBLOCK, &set, NULL);
		
		pthread_mutex_lock(&mutex);
		thread_action = NOP;
		pthread_mutex_unlock(&mutex);
		pthread_cond_signal(&cond);
	} while (1);
	
//	fprintf(stderr, "🧵 Thread ends\n");
	return NULL;
}

int main(int argc, const char * argv[]) {
	fprintf(stderr, "✊ Program starts!\n");
	
	sigset_t set;
	sigemptyset(&set);
	sigaddset(&set, s);
	pthread_sigmask(SIG_BLOCK, &set, NULL);
	
	pthread_cond_init(&cond, NULL);
	pthread_mutex_init(&mutex, NULL);
	
	pthread_t thread;
	pthread_create(&thread, NULL, &threadMain, NULL);
	
	pthread_mutex_lock(&mutex);
	while (thread_action != WAIT_INIT)
		pthread_cond_wait(&cond, &mutex);
	pthread_mutex_unlock(&mutex);
	
	fprintf(stderr, "✊ Thread is inited\n");
	
	/* On Linux, eat signals */
//	dispatch_queue_t signal_queue = dispatch_queue_create("signal-dispatch", NULL);
//	dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, s, 0, signal_queue);
//	dispatch_source_set_event_handler(source, ^{
//		fprintf(stderr, "🪡 Event from dispatch!\n");
//	});
//	dispatch_activate(source);
	
	struct sigaction act = {};
	act.sa_flags = 0;
	sigemptyset(&act.sa_mask);
	act.sa_handler = &action;
	sigaction(s, &act, NULL);
	
	fprintf(stderr, "✊ Killing myself\n");
	kill(getpid(), s);
	
	sigpending(&set);
	fprintf(stderr, "✊ Main thread pending: %d\n", sigismember(&set, s));
	
	sleep(3);
	/* On macOS, signal stays blocked on main thread after unblock in separate
	 * thread;
	 * On Linux, signal is “moved” to separate thread and sigaction is correctly
	 * triggerred. */
	fprintf(stderr, "✊ Unblocking signal\n");
	pthread_mutex_lock(&mutex);
	thread_action = UNBLOCK_SIGNAL;
	pthread_mutex_unlock(&mutex);
	pthread_cond_signal(&cond);
	
	sleep(1);
	sigpending(&set);
	fprintf(stderr, "✊ Main thread pending: %d\n", sigismember(&set, s));
	
//	dispatch_source_cancel(source);
//	dispatch_release(source);
//	dispatch_release(signal_queue);
	
	return 0;
}
