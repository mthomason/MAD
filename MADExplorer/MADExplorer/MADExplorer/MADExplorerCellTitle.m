//
//  MADExplorerCellTitle.m
//  MADExplorer
//
//  Created by Michael on 1/25/18.
//  Copyright © 2018 Michael Thomason. All rights reserved.
//

#import "MADExplorerCellTitle.h"
#import "MADStandard.h"
#import <MADFileManager/MADMetaData.h>
#import <Foundation/NSBundle.h>

NSString * const MADTextNotDownloaded = @"Not Downloaded";
NSString * const Syncing              = @"Syncing";
NSString * const Downloading          = @"Downloading";

@implementation MADExplorerCellTitle

+ (NSString *)explorerCellTitle:(MADMetaData *)data {
	if (data.isUbiquitousItemDownloadingStatusNotDownloaded) {
		return [[NSString alloc] initWithString:NSLocalizedString(@"Not Downloaded", @"Not Downloaded")];
	} else {
		return [MADStandard standardStringForFileSize:data.fileSystemFileSize];
	}
}

+ (NSString *)explorerCellTitleSubtitle:(MADMetaData *)data {
	if (data.ubiquitousItemIsDownloading) {
		return NSLocalizedString(@"Downloading", @"Downloading");
	} else if (data.ubiquitousItemIsUploading) {
		return NSLocalizedString(@"Syncing", @"Syncing");
	} else {
		return [MADExplorerCellTitle explorerCellTitle: data];
	}
}

@end
