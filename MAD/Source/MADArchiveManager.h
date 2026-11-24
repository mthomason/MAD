//
//  MADArchiveManager.h
//  MAD
//
//  Created by Michael Thomason on 6/24/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADArchiveManager_h
#define Reports_MADArchiveManager_h

#import <Foundation/NSObject.h>

@class NSURL;

@interface MADArchiveManager : NSObject

- (instancetype)initWithFileWrapperURL:(NSURL *)fileWrapper archiveURL:(NSURL *)archive;
- (BOOL)archive:(BOOL)overwrite;
- (BOOL)unarchive;

/// Like -unarchive, but an unsupported container version fills `error` with the
/// upgrade message instead of looking like an unreadable archive.
- (BOOL)unarchiveWithError:(NSError * __autoreleasing *)error;

/// Whether the store was checkpointed before archiving, recorded as bit 0 of the v1
/// header's flags.  The caller decides this and sets it before -archive:.
@property (nonatomic, assign) BOOL checkpointed;

/// Write an archive whose bytes depend on nothing but its members: a fixed
/// modification time (MADArchiveReproducibleModificationTime), owner and group 0, and
/// a sorted member walk.  Off by default -- an ordinary save keeps recording the real
/// metadata -- and set before -archive:, the way -checkpointed is.  Two archives of
/// the same members are then equal on any machine and on either platform, which is
/// what the user's .mad byte-identity requirement needs (docs/project/registers/BUGS.md, that entry).
@property (nonatomic, assign) BOOL reproducible;

/// YES when the document is composed: the archive is written as container 1.1 and
/// carries a versioned requirements record declaring `query-composition`.  Set
/// before -archive:, the way -checkpointed is.
@property (nonatomic, assign) BOOL composed;

/// Reads the requirements record in the (already-extracted) file wrapper and
/// checks every required capability against this build.  A missing or malformed
/// record, or an unknown required capability, fills `error`.  Called by
/// -unarchiveWithError: for a 1.1 container.
- (BOOL)checkRequirementsWithError:(NSError * __autoreleasing *)error;

@end

#endif
