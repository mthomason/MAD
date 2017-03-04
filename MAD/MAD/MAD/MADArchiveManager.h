//
//  MADArchiveManager.h
//  MAD
//
//  Created by Michael Thomason on 6/24/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADArchiveManager_h
#define Reports_MADArchiveManager_h

#import <Foundation/NSObject.h>

@class NSURL;

@interface MADArchiveManager : NSObject

    - (instancetype)initWithFileWrapperURL:(NSURL *)fileWrapper archiveURL:(NSURL *)archive;
    - (BOOL)archive:(BOOL)overwrite;
    - (BOOL)unarchive;
    
@end

#endif
