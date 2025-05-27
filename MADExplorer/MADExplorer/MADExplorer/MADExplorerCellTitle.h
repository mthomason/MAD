//
//  MADExplorerCellTitle.h
//  MADExplorer
//
//  Created by Michael on 1/25/18.
//  Copyright © 2018 Michael Thomason. All rights reserved.
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
