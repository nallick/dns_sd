//
//  Cfdset.h
//
//  Provides wrapper functions for the platform fd_set macros.
//
//  Copyright © 2024 Purgatory Design. Licensed under the MIT License.
//

#ifndef Cfdset_h
#define Cfdset_h

#include <sys/select.h>

extern void InvokeMacro_FD_ZERO(fd_set* fdset);
extern void InvokeMacro_FD_CLR(int fd, fd_set* fdset);
extern void InvokeMacro_FD_SET(int fd, fd_set* fdset);
extern int InvokeMacro_FD_ISSET(int fd, const fd_set* fdset);

#endif
