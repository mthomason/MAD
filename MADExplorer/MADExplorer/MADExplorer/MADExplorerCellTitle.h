//
//  MADExplorerCellTitle.h
//  MADExplorer
//
//  Created by Michael on 1/25/18.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADExplorerCellTitle_h
#define Reports_MADExplorerCellTitle_h

#import <Foundation/NSObject.h>

extern NSString * const MADTextNotDownloaded;
extern NSString * const Syncing;
extern NSString * const Downloading;

@class MADMetaData;

@interface MADExplorerCellTitle : NSObject
+ (NSString *)explorerCellTitle:(MADMetaData *)data;
+ (NSString *)explorerCellTitleSubtitle:(MADMetaData *)data;
@end

#endif
