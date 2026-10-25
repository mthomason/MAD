//
//  NSUndoManager+Handler.h
//  Linux/Compat
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Apple's NSUndoManager registers a block with
//  -registerUndoWithTarget:handler:; GNUstep stops at the classic
//  target/selector/object form.  The shim answers through that form, with a
//  small proxy the undo manager retains and calls.  Non-Apple only.
//

#ifndef MADCompat_NSUndoManager_Handler_h
#define MADCompat_NSUndoManager_Handler_h

#if !__APPLE__
#import <Foundation/NSUndoManager.h>

@interface NSUndoManager (MADCompatHandler)

- (void)registerUndoWithTarget:(id)target handler:(void (^)(id target))handler;

@end

#endif /* !__APPLE__ */

#endif /* MADCompat_NSUndoManager_Handler_h */
