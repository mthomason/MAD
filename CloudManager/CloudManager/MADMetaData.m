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
@property (nonatomic, strong, readwrite) NSString  *name;
@property (nonatomic, strong, readwrite) NSURL     *URL;

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

@property (nonatomic, strong) NSNumberFormatter *numberFormatterFileSize;

@property (nonatomic, strong) NSString *path;

@property (nonatomic, strong) NSMetadataItem *metadataItem;

@end

@implementation MADMetaData

- (id)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        
        NSError *__autoreleasing error = nil;

        self.URL = url;
        
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:&error];

        NSString *fileSystemName = url.path.lastPathComponent;
        self.fileSystemName = fileSystemName;
        
        self.path = url.path;
        
        NSNumber *filesize = [attributes objectForKey:NSFileSize];
        self.fileSystemFileSize = filesize.unsignedLongLongValue;
        
        NSDate *creationDate = [attributes objectForKey:NSFileCreationDate];
        self.fileSystemFileCreationDate = creationDate;
        
        NSDate *lastChangeDate = [attributes objectForKey:NSFileModificationDate];
        self.fileSystemContentChangeDate = lastChangeDate;
        
        NSString *uti = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)(url.pathExtension), NULL));
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

- (NSString *)name {
    NSString *displayName;
    if (self.metadataItem) {
        displayName = [self.metadataItem valueForAttribute: NSMetadataItemDisplayNameKey];
    } else {
        displayName = [[NSFileManager defaultManager] displayNameAtPath:self.URL.path];
    }
    return displayName;
}

- (id)initWithMetadataItem:(NSMetadataItem *)item {
    self = [super init];
    if (self) {

        self.metadataItem = item;
        
        NSString *itemFsName = [item valueForAttribute: NSMetadataItemFSNameKey];
        self.fileSystemName = itemFsName;
        
        NSString *path = [item valueForAttribute:NSMetadataItemPathKey];
        self.path = path;
                
        NSURL *url =            [item valueForAttribute: NSMetadataItemURLKey];
        self.URL = url;
        
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
            
            self.ubiquitousItemHasUnresolvedConflicts = ((NSNumber *)[item valueForAttribute:NSMetadataUbiquitousItemHasUnresolvedConflictsKey]).boolValue;
            
            self.ubiquitousItemDownloadingStatus = [item valueForAttribute:NSMetadataUbiquitousItemDownloadingStatusKey];
            
            self.ubiquitousItemIsDownloading = ((NSNumber *)[item valueForAttribute:NSMetadataUbiquitousItemIsDownloadingKey]).boolValue;
            
            self.ubiquitousItemIsUploaded = ((NSNumber *)[item valueForAttribute:NSMetadataUbiquitousItemIsUploadedKey]).boolValue;
            self.ubiquitousItemIsUploading = ((NSNumber *)[item valueForAttribute:NSMetadataUbiquitousItemIsUploadedKey]).boolValue;
            
            self.ubiquitousItemPercentDownloaded = ((NSNumber *)[item valueForAttribute:NSMetadataUbiquitousItemPercentDownloadedKey]).doubleValue;
            
            self.ubiquitousItemPercentUploaded = ((NSNumber *)[item valueForAttribute:NSMetadataUbiquitousItemPercentUploadedKey]).doubleValue;
            
            self.ubiquitousItemDownloadingError = [item valueForAttribute:NSMetadataUbiquitousItemDownloadingErrorKey];
            self.ubiquitousItemUploadingError = [item valueForAttribute:NSMetadataUbiquitousItemUploadingErrorKey];
            
            self.ubiquitousItemDownloadRequested = ((NSNumber *)[item valueForAttribute:NSMetadataUbiquitousItemDownloadRequestedKey]).boolValue;
            
            self.ubiquitousItemIsExternalDocument = ((NSNumber *)[item valueForAttribute:NSMetadataUbiquitousItemIsExternalDocumentKey]).boolValue;
            self.ubiquitousItemContainerDisplayName = [item valueForAttribute:NSMetadataUbiquitousItemContainerDisplayNameKey];
            self.ubiquitousItemURLInLocalContainer = [item valueForAttribute:NSMetadataUbiquitousItemURLInLocalContainerKey];
            
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
    return [NSString stringWithFormat:@"MADMetaData: %@, %llu, %f, %@, %@", self.fileSystemName,
                                                                        self.fileSystemFileSize,
                                                                        self.ubiquitousItemPercentDownloaded,
                                                                        self.fileSystemContentChangeDate,
                                                                        self.fileSystemFileCreationDate];
}

- (NSString *)fileSystemSizeMB {
    NSNumber *fileSizeMB = @((double)self.fileSystemFileSize / 1000000);
    NSString *sizeInMB = [self.numberFormatterFileSize stringFromNumber:fileSizeMB];
    return [NSString stringWithFormat:@"%@ MB", sizeInMB];

}

- (BOOL)isSyncing {
    return self.isUbiquitous && (self.ubiquitousItemIsDownloading ||
                                 self.ubiquitousItemIsUploading);
}

+ (NSArray *)madMetaDataItemsForNSMetadataItems:(NSArray *)metadataItems {
    NSMutableArray *madMetaDataItems = [[NSMutableArray alloc] initWithCapacity:metadataItems.count];
    MADMetaData *metaData;
    NSMetadataItem *metadataItem;
    for (metadataItem in metadataItems) {
        metaData = [[MADMetaData alloc] initWithMetadataItem:metadataItem];
        [madMetaDataItems addObject:metaData];
    }
    return madMetaDataItems;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    } else {
        return [self.URL.absoluteString isEqual:((MADMetaData *)object).URL.absoluteString];
    }
}

- (NSUInteger)hash {
    return self.URL.absoluteString.hash;
}

@end
