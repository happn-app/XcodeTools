#ifndef exports_h
# define exports_h

/* Using the following would technically work to export execvpe directly (with a dummy C file),
 * but it would also export the rest of unistd, which is already available through Glibc,
 * thus creating conflicts when using Glibc stuff.
 * So instead we create an execvpe shim explicitly (xct_execvpe). */
//#define _GNU_SOURCE
//#include <unistd.h>

int xct_execvpe(const char *file, char *const argv[], char *const envp[]);

#endif /* exports_h */
