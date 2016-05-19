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
@class MADMetaData;

typedef NSArray <MADMetaData *> MADMetaDataArray;

@interface MADMetaData : NSObject
    <NSCopying>

    + (MADMetaDataArray *)madMetaDataItemsForNSMetadataItems:(NSArray *)metadataItems;

    - (instancetype)initWithURL:(NSURL *)url;
    - (instancetype)initWithMetadataItem:(NSMetadataItem *)item;

    - (bool)isSyncing;

    - (unsigned long long)fileSystemFileNumber;
    - (unsigned long long)fileSystemNumber;

    @property (nonatomic, copy, readonly) NSURL *URL;
    @property (readonly) NSString  *fileSystemName;
    @property (readonly) NSString  *name;

    @property (readonly) unsigned long long fileSystemFileSize;

    @property (readonly) NSDate    *fileSystemFileCreationDate;
    @property (readonly) NSDate    *fileSystemContentChangeDate;

    @property (readonly) NSString  *contentType;

    @property (getter=isUbiquitous, readonly) bool ubiquitous;

    // Download status of this item. The values are the three strings defined below.
    @property (readonly) NSString *ubiquitousItemDownloadingStatus;

    // this item has not been downloaded yet. Use startDownloadingUbiquitousItemAtURL:error: to download it.
    @property (getter=isUbiquitousItemDownloadingStatusNotDownloaded, readonly) bool ubiquitousItemDownloadingStatusNotDownloaded;

    // there is a local version of this item available. The most current version will get downloaded as soon as possible.
    @property (getter=isUbiquitousItemDownloadingStatusDownloaded, readonly) bool ubiquitousItemDownloadingStatusDownloaded;

    // there is a local version of this item and it is the most up-to-date version known to this device.
    @property (getter=isUbiquitousItemDownloadingStatusCurrent, readonly) bool ubiquitousItemDownloadingStatusCurrent;

    @property (readonly) bool ubiquitousItemIsDownloading;
    @property (readonly) bool ubiquitousItemIsUploaded;
    @property (readonly) bool ubiquitousItemIsUploading;
    @property (readonly) bool ubiquitousItemDownloadRequested;
    @property (readonly) bool ubiquitousItemIsExternalDocument;

    @property (readonly) double ubiquitousItemPercentDownloaded;
    @property (readonly) double ubiquitousItemPercentUploaded;

    @property (readonly) NSError *ubiquitousItemDownloadingError;                 // The error when downloading the item from iCloud failed, see the NSUbiquitousFile section in FoundationErrors.h
    @property (readonly) NSError *ubiquitousItemUploadingError;                   // The error when uploading the item to iCloud failed, see the NSUbiquitousFile section in FoundationErrors.h

    @property (readonly) NSString *ubiquitousItemContainerDisplayName;
    @property (readonly) NSURL *ubiquitousItemURLInLocalContainer;

@end

#endif
