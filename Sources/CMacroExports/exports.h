#ifndef exports_h
# define exports_h

# include <stddef.h>
# include <sys/socket.h>

size_t XCT_CMSG_LEN(size_t s);
size_t XCT_CMSG_SPACE(size_t s);

unsigned char *XCT_CMSG_DATA(struct cmsghdr *cmsg);
struct cmsghdr *XCT_CMSG_FIRSTHDR(struct msghdr *msgh);

#endif /* exports_h */
