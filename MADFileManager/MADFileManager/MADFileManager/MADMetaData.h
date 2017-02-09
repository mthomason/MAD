//
//  MADMetadata.h
//  MAD
//
//  Created by Michael Thomason on 10/7/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADMetaData_h
#define MAD_MADMetaData_h

#import <Foundation/NSObject.h>

@class NSMetadataItem;

@interface MADMetaData : NSObject
    <NSCopying>

    + (NSArray <MADMetaData *> *)newMetaDatumForMetadataItems:(NSArray *)metadataItems;

    - (instancetype)initWithURL:(NSURL *)url;
    - (instancetype)initWithMetadataItem:(NSMetadataItem *)item;

    - (BOOL)isSyncing;

    - (unsigned long long)fileSystemFileNumber;
    - (unsigned long long)fileSystemNumber;

    @property (nonatomic, readonly) NSURL *URL;
    @property (nonatomic, readonly) NSString  *fileSystemName;
    @property (readonly) NSString  *name;

    @property (readonly) unsigned long long fileSystemFileSize;

    @property (readonly) NSDate    *fileSystemFileCreationDate;
    @property (readonly) NSDate    *fileSystemContentChangeDate;

    @property (readonly) NSString  *contentType;

    // Download status of this item. The values are the three strings defined below.
    @property (readonly) NSString *ubiquitousItemDownloadingStatus;

    - (BOOL)isUbiquitous;
    - (BOOL)isUbiquitousItemDownloadingStatusNotDownloaded;
    - (BOOL)isUbiquitousItemDownloadingStatusDownloaded;

    - (BOOL)isUbiquitousItemDownloadingStatusCurrent;

    - (BOOL)isDownloaded;
    - (BOOL)ubiquitousItemIsDownloading;
    - (BOOL)ubiquitousItemIsUploaded;
    - (BOOL)ubiquitousItemIsUploading;
    - (BOOL)ubiquitousItemDownloadRequested;
    - (BOOL)ubiquitousItemIsExternalDocument;

    - (double)ubiquitousItemPercentDownloaded;
    - (double)ubiquitousItemPercentUploaded;

    @property (readonly) NSError *ubiquitousItemDownloadingError;                 // The error when downloading the item from iCloud failed, see the NSUbiquitousFile section in FoundationErrors.h
    @property (readonly) NSError *ubiquitousItemUploadingError;                   // The error when uploading the item to iCloud failed, see the NSUbiquitousFile section in FoundationErrors.h

    @property (readonly) NSString *ubiquitousItemContainerDisplayName;
    @property (readonly) NSURL *ubiquitousItemURLInLocalContainer;

@end

#endif
