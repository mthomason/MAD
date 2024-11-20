//
//  MADExplorerCellTitle.m
//  MADExplorer
//
//  Created by Michael on 1/25/18.
//  Copyright © 2018 Michael Thomason. All rights reserved.
//

#import "MADExplorerCellTitle.h"
#import <MADFileManager/MADMetaData.h>
#import "MADStandard.h"

NSString * const MADTextNotDownloaded = @"Not Downloaded";
NSString * const Syncing              = @"Syncing";
NSString * const Downloading          = @"Downloading";

@implementation MADExplorerCellTitle

+ (NSString *)newExplorerCellTitle:(MADMetaData *)data {
    id result;
    if (data.isUbiquitousItemDownloadingStatusNotDownloaded) {
        NSString *textNotDownloaded;
        textNotDownloaded = NSLocalizedString(MADTextNotDownloaded, MADTextNotDownloaded);
        result = [[NSString alloc] initWithString:textNotDownloaded];
    } else {
        result = [MADStandard newStandardStringForFileSize:data.fileSystemFileSize];
    }
    return result;
}

+ (NSString *)newExplorerCellTitleSubtitle:(MADMetaData *)data {
    NSString *subtitle;
    if (data.ubiquitousItemIsDownloading) {
        subtitle = NSLocalizedString(Downloading, Downloading);
    } else if (data.ubiquitousItemIsUploading) {
        subtitle = NSLocalizedString(Syncing, Syncing);
    } else {
        subtitle = [MADExplorerCellTitle newExplorerCellTitle: data];
    }
    return subtitle;
}

@end
