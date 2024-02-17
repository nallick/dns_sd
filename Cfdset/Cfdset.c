//
//  Cfdset.c
//
//  Provides wrapper functions for the platform fd_set macros.
//
//  Copyright © 2024 Purgatory Design. Licensed under the MIT License.
//

#include "include/Cfdset.h"

void InvokeMacro_FD_ZERO(fd_set* fdset)
{
    FD_ZERO(fdset);
}

void InvokeMacro_FD_CLR(int fd, fd_set* fdset)
{
    FD_CLR(fd, fdset);
}

void InvokeMacro_FD_SET(int fd, fd_set* fdset)
{
    FD_SET(fd, fdset);
}

int InvokeMacro_FD_ISSET(int fd, const fd_set* fdset)
{
    return FD_ISSET(fd, fdset);
}
