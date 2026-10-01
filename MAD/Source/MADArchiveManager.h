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

@end

#endif
