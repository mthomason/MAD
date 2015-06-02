//
//  MADMetadata.h
//  MAD
//
//  Created by Michael Thomason on 10/7/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADMetaData_h
#define MAD_MADMetaData_h

#import <Foundation/Foundation.h>

@interface MADMetaData : NSObject

@property (nonatomic, strong, readonly) NSString  *fileSystemName;
@property (nonatomic, strong, readonly) NSString  *name;
@property (nonatomic, strong, readonly) NSURL     *URL;

@property (nonatomic, assign, readonly) unsigned long long fileSystemFileSize;

@property (nonatomic, strong, readonly) NSDate    *fileSystemFileCreationDate;
@property (nonatomic, strong, readonly) NSDate    *fileSystemContentChangeDate;

@property (nonatomic, strong, readonly) NSString  *contentType;

@property (nonatomic, assign, getter=isUbiquitous, readonly) BOOL ubiquitous;
@property (nonatomic, strong, readonly) NSString *ubiquitousItemDownloadingStatus;                // Download status of this item. The values are the three strings defined below:

@property (nonatomic, assign, getter=isUbiquitousItemDownloadingStatusNotDownloaded, readonly)
                                    BOOL ubiquitousItemDownloadingStatusNotDownloaded;        // this item has not been downloaded yet. Use startDownloadingUbiquitousItemAtURL:error: to download it.

@property (nonatomic, assign, getter=isUbiquitousItemDownloadingStatusDownloaded, readonly)
                                    BOOL ubiquitousItemDownloadingStatusDownloaded;           // there is a local version of this item available. The most current version will get downloaded as soon as possible.

@property (nonatomic, assign, getter=isUbiquitousItemDownloadingStatusCurrent, readonly)
                                    BOOL ubiquitousItemDownloadingStatusCurrent;              // there is a local version of this item and it is the most up-to-date version known to this device.

@property (nonatomic, assign, readonly) BOOL ubiquitousItemIsDownloading;
@property (nonatomic, assign, readonly) BOOL ubiquitousItemIsUploaded;
@property (nonatomic, assign, readonly) BOOL ubiquitousItemIsUploading;

@property (nonatomic, assign, readonly) double ubiquitousItemPercentDownloaded;
@property (nonatomic, assign, readonly) double ubiquitousItemPercentUploaded;


@property (nonatomic, strong, readonly) NSError * ubiquitousItemDownloadingError;                 // The error when downloading the item from iCloud failed, see the NSUbiquitousFile section in FoundationErrors.h
@property (nonatomic, strong, readonly) NSError * ubiquitousItemUploadingError;                   // The error when uploading the item to iCloud failed, see the NSUbiquitousFile section in FoundationErrors.h

@property (nonatomic, assign, readonly) BOOL ubiquitousItemDownloadRequested;
@property (nonatomic, assign, readonly) BOOL ubiquitousItemIsExternalDocument;

@property (nonatomic, strong, readonly) NSString *ubiquitousItemContainerDisplayName;
@property (nonatomic, strong, readonly) NSURL *ubiquitousItemURLInLocalContainer;

+ (NSArray *)madMetaDataItemsForNSMetadataItems:(NSArray *)metadataItems;

- (id)initWithURL:(NSURL *)url;
- (id)initWithMetadataItem:(NSMetadataItem *)item;

- (BOOL)isSyncing;

@end

#endif
