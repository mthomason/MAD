//
//  MADArchiveManager.h
//  MAD
//
//  Created by Michael Thomason on 6/24/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADArchiveManager_h
#define Reports_MADArchiveManager_h

#import <Foundation/NSObject.h>

@class NSURL;

@interface MADArchiveManager : NSObject

- (instancetype)initWithFileWrapperURL:(NSURL *)fileWrapper archiveURL:(NSURL *)archive;
- (BOOL)archive:(BOOL)overwrite;
- (BOOL)unarchive;

/// Whether the store was checkpointed before archiving, recorded as bit 0 of the v1
/// header's flags.  The caller decides this and sets it before -archive:.
@property (nonatomic, assign) BOOL checkpointed;

/// Write an archive whose bytes depend on nothing but its members: a fixed
/// modification time (MADArchiveReproducibleModificationTime), owner and group 0, and
/// a sorted member walk.  Off by default -- an ordinary save keeps recording the real
/// metadata -- and set before -archive:, the way -checkpointed is.  Two archives of
/// the same members are then equal on any machine and on either platform, which is
/// what the user's .mad byte-identity requirement needs (BUGS.md, that entry).
@property (nonatomic, assign) BOOL reproducible;

@end

#endif
