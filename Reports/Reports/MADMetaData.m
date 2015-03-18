//
//  MADMetadata.m
//  MAD
//
//  Created by Michael Thomason on 10/7/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADMetaData.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>

@interface MADMetaData ()

@property (nonatomic, strong, readwrite) NSString  *fileSystemName;
@property (nonatomic, strong, readwrite) NSString  *displayName;
@property (nonatomic, strong, readwrite) NSURL     *url;

@property (nonatomic, assign, readwrite) unsigned long long fileSystemFileSize;

@property (nonatomic, strong, readwrite) NSDate    *fileSystemFileCreationDate;
@property (nonatomic, strong, readwrite) NSDate    *fileSystemContentChangeDate;

@property (nonatomic, strong, readwrite) NSString  *contentType;
@property (nonatomic, strong, readwrite) NSString  *contentTypeTree;

@property (nonatomic, assign, getter=isUbiquitous, readwrite) BOOL ubiquitous;
@property (nonatomic, assign, readwrite) BOOL ubiquitousItemHasUnresolvedConflicts;
@property (nonatomic, strong, readwrite) NSString *ubiquitousItemDownloadingStatus;                // Download status of this item. The values are the three strings defined below:

@property (nonatomic, assign, readwrite) BOOL ubiquitousItemIsDownloading;
@property (nonatomic, assign, readwrite) BOOL ubiquitousItemIsUploaded;
@property (nonatomic, assign, readwrite) BOOL ubiquitousItemIsUploading;

@property (nonatomic, assign, readwrite) double ubiquitousItemPercentDownloaded;
@property (nonatomic, assign, readwrite) double ubiquitousItemPercentUploaded;


@property (nonatomic, strong, readwrite) NSError * ubiquitousItemDownloadingError;                 // The error when downloading the item from iCloud failed, see the NSUbiquitousFile section in FoundationErrors.h
@property (nonatomic, strong, readwrite) NSError * ubiquitousItemUploadingError;                   // The error when uploading the item to iCloud failed, see the NSUbiquitousFile section in FoundationErrors.h

@property (nonatomic, assign, readwrite) BOOL ubiquitousItemDownloadRequested;
@property (nonatomic, assign, readwrite) BOOL ubiquitousItemIsExternalDocument;

@property (nonatomic, strong, readwrite) NSString *ubiquitousItemContainerDisplayName;
@property (nonatomic, strong, readwrite) NSURL *ubiquitousItemURLInLocalContainer;

@property (nonatomic, retain) NSNumberFormatter *numberFormatterFileSize;

@end

@implementation MADMetaData

- (instancetype)initWithLocalUrl:(NSURL *)url {
    self = [super init];
    if (self) {
        
        NSError *__autoreleasing error = nil;

        self.url = url;
        
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:&error];

        NSString *fileSystemName = url.path.lastPathComponent;
        self.fileSystemName = fileSystemName;
        
        NSString *displayName = [[NSFileManager defaultManager] displayNameAtPath:url.path];
        self.displayName = displayName;
        
        NSNumber *filesize = [attributes objectForKey:NSFileSize];
        self.fileSystemFileSize = filesize.unsignedLongLongValue;
        
        NSDate *creationDate = [attributes objectForKey:NSFileCreationDate];
        self.fileSystemFileCreationDate = creationDate;
        
        NSDate *lastChangeDate = [attributes objectForKey:NSFileModificationDate];
        self.fileSystemContentChangeDate = lastChangeDate;
        
        NSString *uti = (__bridge NSString *)(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)(url.pathExtension), NULL));
        self.contentType = uti;
        
        self.contentTypeTree = nil;
        
        self.ubiquitous = NO;
        self.ubiquitousItemHasUnresolvedConflicts = NO;
        self.ubiquitousItemDownloadingStatus = NSMetadataUbiquitousItemDownloadingStatusCurrent;
        self.ubiquitousItemIsDownloading = NO;
        self.ubiquitousItemIsUploaded = NO;
        self.ubiquitousItemPercentDownloaded = 1;
        self.ubiquitousItemPercentUploaded = 0;
        self.ubiquitousItemDownloadingError = nil;
        self.ubiquitousItemUploadingError = nil;
        self.ubiquitousItemDownloadRequested = NO;
        self.ubiquitousItemIsExternalDocument = NO;
        self.ubiquitousItemContainerDisplayName = @"";
        self.ubiquitousItemURLInLocalContainer = nil;

        [self commonInit];

    }
    return self;
}

- (instancetype)initWithMetadataItem:(NSMetadataItem *)item {
    self = [super init];
    if (self) {

        NSString *itemFsName = [item valueForAttribute: NSMetadataItemFSNameKey];
        self.fileSystemName = itemFsName;
        
        NSString *itemDisplayName = [item valueForAttribute: NSMetadataItemDisplayNameKey];
        self.displayName = itemDisplayName;
        
        NSURL *url =            [item valueForAttribute: NSMetadataItemURLKey];
        self.url = url;
        
        NSNumber *fileSize =    [item valueForAttribute: NSMetadataItemFSSizeKey];
        self.fileSystemFileSize = fileSize.unsignedLongLongValue;
        
        NSDate *itemFsCreationDate = [item valueForAttribute: NSMetadataItemFSCreationDateKey];
        self.fileSystemFileCreationDate = itemFsCreationDate;
        
        NSDate *itemFsContentChangeDate = [item valueForAttribute: NSMetadataItemFSContentChangeDateKey];
        self.fileSystemContentChangeDate = itemFsContentChangeDate;
        
        NSString *itemContentType = [item valueForAttribute: NSMetadataItemContentTypeKey];
        self.contentType = itemContentType;
        
        id itemContentTypeTree = [item valueForAttribute: NSMetadataItemContentTypeTreeKey];
        self.contentTypeTree = itemContentTypeTree;
        
        NSNumber *itemIsUbiquitous = [item valueForAttribute:NSMetadataItemIsUbiquitousKey];
        self.ubiquitous = itemIsUbiquitous.boolValue;
        if (self.ubiquitous) {   //If the result of the assignment is true...
            
            NSNumber *ubiquitousItemHasUnresolvedConflictsKey = [item valueForAttribute:NSMetadataUbiquitousItemHasUnresolvedConflictsKey];
            self.ubiquitousItemHasUnresolvedConflicts = ubiquitousItemHasUnresolvedConflictsKey.boolValue;
            
            NSString *ubiquitousItemDownloadingStatus = [item valueForAttribute:NSMetadataUbiquitousItemDownloadingStatusKey];
            self.ubiquitousItemDownloadingStatus = ubiquitousItemDownloadingStatus;
            
            NSNumber *ubiquitousItemIsDownloading = [item valueForAttribute:NSMetadataUbiquitousItemIsDownloadingKey];
            self.ubiquitousItemIsDownloading = ubiquitousItemIsDownloading.boolValue;
            
            NSNumber *ubiquitousItemIsUploaded = [item valueForAttribute:NSMetadataUbiquitousItemIsUploadedKey];
            self.ubiquitousItemIsUploaded = ubiquitousItemIsUploaded.boolValue;
            
            NSNumber *ubiquitousItemPercentDownloaded = [item valueForAttribute:NSMetadataUbiquitousItemPercentDownloadedKey];
            self.ubiquitousItemPercentDownloaded = ubiquitousItemPercentDownloaded.doubleValue;
            
            NSNumber *ubiquitousItemPercentUploaded = [item valueForAttribute:NSMetadataUbiquitousItemPercentUploadedKey];
            self.ubiquitousItemPercentUploaded = ubiquitousItemPercentUploaded.doubleValue;
            
            NSError *ubiquitousItemDownloadingError = [item valueForAttribute:NSMetadataUbiquitousItemDownloadingErrorKey];
            self.ubiquitousItemDownloadingError = ubiquitousItemDownloadingError;
            
            NSError *ubiquitousItemUploadingError = [item valueForAttribute:NSMetadataUbiquitousItemUploadingErrorKey];
            self.ubiquitousItemUploadingError = ubiquitousItemUploadingError;
            
            NSNumber *ubiquitousItemDownloadRequested = [item valueForAttribute:NSMetadataUbiquitousItemDownloadRequestedKey];
            self.ubiquitousItemDownloadRequested = ubiquitousItemDownloadRequested.boolValue;
            
            NSNumber *ubiquitousItemIsExternalDocument = [item valueForAttribute:NSMetadataUbiquitousItemIsExternalDocumentKey];
            self.ubiquitousItemIsExternalDocument = ubiquitousItemIsExternalDocument.boolValue;
            
            NSString *ubiquitousItemContainerDisplayName = [item valueForAttribute:NSMetadataUbiquitousItemContainerDisplayNameKey];
            self.ubiquitousItemContainerDisplayName = ubiquitousItemContainerDisplayName;
            
            NSURL *ubiquitousItemURLInLocalContainer = [item valueForAttribute:NSMetadataUbiquitousItemURLInLocalContainerKey];
            self.ubiquitousItemURLInLocalContainer = ubiquitousItemURLInLocalContainer;
            
        }

        [self commonInit];
        
    }
    return self;
}

- (UIImage *)imageForCloudStatus {
    UIImage *result;
    if ([self.ubiquitousItemDownloadingStatus isEqualToString:NSMetadataUbiquitousItemDownloadingStatusNotDownloaded]) {
        result = [UIImage imageNamed:@"MADImageToolbarCloudDownload"];
    } else {
        result = [UIImage imageNamed:@"MADImageToolbarCloud"];
    }
    return result;
}

- (void)commonInit {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setMaximumFractionDigits:2];
    [numberFormatter setDecimalSeparator:@"."];
    [numberFormatter setGroupingSeparator:@""];
    self.numberFormatterFileSize = numberFormatter;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"MADMetaData: %@, %llu, %@, %@", self.fileSystemName,
                                                                        self.fileSystemFileSize,
                                                                        self.fileSystemContentChangeDate,
                                                                        self.fileSystemFileCreationDate];
}

- (NSString *)fileSystemSizeMB {
    NSNumber *fileSizeMB = @((double)self.fileSystemFileSize / 1000000);
    NSString *sizeInMB = [self.numberFormatterFileSize stringFromNumber:fileSizeMB];
    return [NSString stringWithFormat:@"%@ MB", sizeInMB];

}

@end
