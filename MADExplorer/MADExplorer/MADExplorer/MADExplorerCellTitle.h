//
//  MADExplorerCellTitle.h
//  MADExplorer
//
//  Created by Michael on 1/25/18.
//  Copyright © 2018 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADExplorerCellTitle_h
#define Reports_MADExplorerCellTitle_h

#import <Foundation/Foundation.h>

extern NSString * const MADTextNotDownloaded;
extern NSString * const Syncing;
extern NSString * const Downloading;

@class MADMetaData;

@interface MADExplorerCellTitle : NSObject
    + (NSString *)newExplorerCellTitle:(MADMetaData *)data;
    + (NSString *)newExplorerCellTitleSubtitle:(MADMetaData *)data;
@end

#endif
