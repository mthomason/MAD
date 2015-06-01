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
#import <sys/stat.h>

@interface MADMetaData ()

@property (nonatomic, strong, readwrite) NSURL     *URL;

//@property (nonatomic, strong) NSNumberFormatter *numberFormatterFileSize;

@property (nonatomic, strong) NSMetadataItem *metadataItem;
@property (nonatomic, strong) NSDictionary *attributes;

@end

@implementation MADMetaData

- (id)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        
        NSError *__autoreleasing error = nil;

        self.URL = url.copy;
        
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:&error];
        self.attributes = attributes;

    }
    return self;
}

- (id)initWithMetadataItem:(NSMetadataItem *)item {
    self = [super init];
    if (self) {

        self.metadataItem = item;
        
        NSURL *url =            [item valueForAttribute: NSMetadataItemURLKey];
        self.URL = url;
        
    }
    return self;
}

- (NSData *)fileSystemFileCreationDate {
    return self.metadataItem ? [self.metadataItem valueForAttribute:NSMetadataItemFSCreationDateKey] :
                                [self.attributes objectForKey:NSFileCreationDate];
}

- (NSData *)fileSystemContentChangeDate {
    return self.metadataItem ? [self.metadataItem valueForAttribute:NSMetadataItemFSContentChangeDateKey] :
    [self.attributes objectForKey:NSFileModificationDate];
}

- (BOOL)isUbiquitous {
    return self.metadataItem ? ((NSNumber *)[self.metadataItem valueForAttribute:NSMetadataItemIsUbiquitousKey]).boolValue : NO;
}

- (NSError *)ubiquitousItemUploadingError {
    return self.metadataItem ? [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemUploadingErrorKey] : nil;
}

- (NSError *)ubiquitousItemDownloadingError {
    return self.metadataItem ? [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemDownloadingErrorKey] : nil;
}

- (NSString *)ubiquitousItemDownloadingStatus {
    return self.metadataItem ? [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemDownloadingStatusKey] : NSMetadataUbiquitousItemDownloadingStatusCurrent;
}

- (NSString *)name {
    NSString *displayName;
    if (self.metadataItem) {
        displayName = [self.metadataItem valueForAttribute: NSMetadataItemDisplayNameKey];
    } else {
        displayName = [[NSFileManager defaultManager] displayNameAtPath:self.URL.path];
    }
    return [displayName stringByDeletingPathExtension];
}

- (NSString *)fileSystemName {
    return self.metadataItem ? [self.metadataItem valueForAttribute: NSMetadataItemFSNameKey] : self.URL.path.lastPathComponent;
}

- (unsigned long long)fileSystemFileSize {
    return self.metadataItem ? ((NSNumber *)[self.metadataItem valueForAttribute: NSMetadataItemFSSizeKey]).unsignedLongLongValue :
                                ((NSNumber *)[self.attributes objectForKey:NSFileSize]).unsignedLongLongValue;
}

- (NSString *)contentType {
    return self.metadataItem ? [self.metadataItem valueForAttribute: NSMetadataItemContentTypeKey] :
                                    CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)(self.URL.pathExtension), NULL));
}

- (NSString *)ubiquitousItemContainerDisplayName {
    return self.metadataItem ? ((NSString *)[self.metadataItem valueForAttribute:NSMetadataUbiquitousItemContainerDisplayNameKey]) : self.URL.path.lastPathComponent;
}

- (NSURL *)ubiquitousItemURLInLocalContainer {
    return self.metadataItem ? ((NSURL *)[self.metadataItem valueForAttribute:NSMetadataUbiquitousItemURLInLocalContainerKey]) : self.URL;
}

- (BOOL)ubiquitousItemDownloadRequested {
    return self.metadataItem ? (((NSNumber *)[self.metadataItem valueForAttribute:NSMetadataUbiquitousItemDownloadRequestedKey]).boolValue) : NO;
}

- (BOOL)ubiquitousItemIsDownloading {
    return self.metadataItem ? (((NSNumber *)[self.metadataItem valueForAttribute:NSMetadataUbiquitousItemIsDownloadingKey]).boolValue) : NO;
}

- (BOOL)ubiquitousItemIsUploading {
    return self.metadataItem ? (((NSNumber *)[self.metadataItem valueForAttribute:NSMetadataUbiquitousItemIsUploadingKey]).boolValue) : NO;
}

- (BOOL)ubiquitousItemIsUploaded {
    return self.metadataItem ? (((NSNumber *)[self.metadataItem valueForAttribute:NSMetadataUbiquitousItemIsUploadedKey]).boolValue) : NO;
}

- (double)ubiquitousItemPercentUploaded {
    return self.metadataItem ? (((NSNumber *)[self.metadataItem valueForAttribute:NSMetadataUbiquitousItemPercentUploadedKey]).doubleValue) : 100.0;
}

- (double)ubiquitousItemPercentDownloaded {
    NSLog(@"Percent d %@", [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemPercentDownloadedKey]);
    return self.metadataItem ? (((NSNumber *)[self.metadataItem valueForAttribute:NSMetadataUbiquitousItemPercentDownloadedKey]).doubleValue) : 100.0;
}

- (BOOL)ubiquitousItemIsExternalDocument {
    return self.metadataItem ? (((NSNumber *)[self.metadataItem valueForAttribute:NSMetadataUbiquitousItemIsExternalDocumentKey]).boolValue) : NO;
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

- (NSString *)description {
    return [NSString stringWithFormat:@"MADMetaData: %@, %llu, %f, %@, %@", self.fileSystemName, self.fileSystemFileSize, self.ubiquitousItemPercentDownloaded, self.fileSystemContentChangeDate, self.fileSystemFileCreationDate];
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

- (BOOL)sameFile:(MADMetaData *)unknown {
    struct stat sa, sb;
    if (stat(self.URL.path.UTF8String, &sa) < 0 || stat(unknown.URL.path.UTF8String, &sb) < 0)
        return 0;
    return  sa.st_dev == sb.st_dev && sa.st_ino == sb.st_ino;
}

- (BOOL)samePercentages:(MADMetaData *)unknown {
    return self.ubiquitousItemPercentDownloaded == unknown.ubiquitousItemPercentDownloaded &&
            self.ubiquitousItemPercentUploaded == unknown.ubiquitousItemPercentUploaded;
}

- (NSUInteger)samePercentageHash {
    return self.ubiquitousItemPercentDownloaded * 5 + self.ubiquitousItemPercentUploaded * 7;
}

- (NSUInteger)sameFileHash {
    struct stat sa;
    int r = stat(self.URL.path.UTF8String, &sa);
    return r < 0 ? 0 : (NSUInteger)(sa.st_dev * 2 + sa.st_ino * 3);
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    } else {
        return  [self sameFile:object];
    }
    
}

- (NSUInteger)hash {
    return [self sameFileHash] * 11;
}

@end
