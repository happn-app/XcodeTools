#define _GNU_SOURCE
#include <unistd.h>



int xct_execvpe(const char *file, char *const argv[], char *const envp[]) {
	return execvpe(file, argv, envp);
}
