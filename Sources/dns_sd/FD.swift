//
//  FD.swift
//
//  The C structure fd_set is an OS system defined bit field containing FD_SETSIZE (e.g. 1024) bits.
//  In C, this is implemented as a fixed size array of integers which Swift interprets as a tuple.
//  Unfortunately various Linux distributions (as well as Darwin) vary regarding integer size and count.
//  This means the number of tuple elements Swift imports from C varies from platform to platform.
//  Platform C headers define C macros to perform bitfield functions on fd_set. This file provides those as Swift functions.
//  Previous versions of this file have reimplemented the macros in pure Swift, but since Swift doesn't allow compile-time
//  variations to account for the number of elements in the fd_set tuple, this solution isn't portable.
//  The portable solution used here calls the platform's C macros through C language wrapper functions visible to Swift.
//
//  Copyright © 2024 Purgatory Design. Licensed under the MIT License.
//

import Cfdset
import Foundation

internal enum FD {

    /// Replacement for FD_ZERO macro.
    ///
    /// - Parameter set: A pointer to a fd_set structure.
    ///
    /// - Returns: The set that is pointed at is filled with all zero's.
    ///
    @inlinable internal static func zero(_ set: UnsafeMutablePointer<fd_set>) {
        InvokeMacro_FD_ZERO(set)
    }

    /// Replacement for FD_SET macro.
    ///
    /// - Parameter fd: A file descriptor that offsets the bit to be set to 1 in the fd_set pointed at by 'set'.
    /// - Parameter set: A pointer to a fd_set structure.
    ///
    /// - Returns: The given set is updated in place, with the bit at offset 'fd' set to 1.
    ///
    /// - Note: If you receive an EXC_BAD_INSTRUCTION at the mask statement, then most likely the socket was already closed.
    ///
    @inlinable internal static func set(_ fd: Int32, set: UnsafeMutablePointer<fd_set>) {
        InvokeMacro_FD_SET(fd, set)
    }

    /// Replacement for FD_CLR macro.
    ///
    /// - Parameter fd: A file descriptor that offsets the bit to be cleared in the fd_set pointed at by 'set'.
    /// - Parameter set: A pointer to a fd_set structure.
    ///
    /// - Returns: The given set is updated in place, with the bit at offset 'fd' cleared to 0.
    ///
    @inlinable internal static func clr(_ fd: Int32, set: UnsafeMutablePointer<fd_set>) {
        InvokeMacro_FD_CLR(fd, set)
    }

    /// Replacement for FD_ISSET macro.
    ///
    /// - Parameter fd: A file descriptor that offsets the bit to be tested in the fd_set pointed at by 'set'.
    /// - Parameter set: A pointer to a fd_set structure.
    ///
    /// - Returns: 'true' if the bit at offset 'fd' is 1, 'false' otherwise.
    ///
    @inlinable internal static func isSet(_ fd: Int32, set: UnsafePointer<fd_set>) -> Bool {
        return InvokeMacro_FD_ISSET(fd, set) != 0
    }
}
