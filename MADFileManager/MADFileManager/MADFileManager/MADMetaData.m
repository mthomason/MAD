//
//  MADMetadata.m
//  MAD
//
//  Created by Michael Thomason on 10/7/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADMetaData.h"

@interface MADMetaData ()

@property (nonatomic, strong, readwrite) NSURL *URL;
@property (nonatomic, strong, readwrite) NSString  *fileSystemName;
@property (nonatomic, strong, readwrite) NSString  *name;
@property (nonatomic, strong) NSMetadataItem *metadataItem;
@property (nonatomic, strong) NSDictionary *attributes;

@end

@implementation MADMetaData

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        
        NSError *__autoreleasing error = nil;

        NSURL *urlc = url.copy;
        self.URL = urlc;
        
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:urlc.path error:&error];
        self.attributes = attributes;

    }
    return self;
}

- (instancetype)initWithMetadataItem:(NSMetadataItem *)item {
    self = [super init];
    if (self) {

        self.metadataItem = item;
        
        NSURL *url =            [item valueForAttribute: NSMetadataItemURLKey];
        self.URL = url.copy;
        
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
    if (_name == nil) {
        NSString *displayName;
        if (self.metadataItem) {
            displayName = [self.metadataItem valueForAttribute: NSMetadataItemDisplayNameKey];
        } else {
            displayName = [[NSFileManager defaultManager] displayNameAtPath:self.URL.path];
        }
        _name = [displayName stringByDeletingPathExtension];
    }
    return _name;
}

- (NSString *)fileSystemName {
    if (_fileSystemName == nil) {
        _fileSystemName = self.metadataItem ? [self.metadataItem valueForAttribute: NSMetadataItemFSNameKey] : self.URL.path.lastPathComponent;
    }
    return _fileSystemName;
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
    return self.metadataItem ? (((NSNumber *)[self.metadataItem valueForAttribute:NSMetadataUbiquitousItemPercentDownloadedKey]).doubleValue) : 100.0;
}

- (BOOL)ubiquitousItemIsExternalDocument {
    return self.metadataItem ? (((NSNumber *)[self.metadataItem valueForAttribute:NSMetadataUbiquitousItemIsExternalDocumentKey]).boolValue) : NO;
}

- (BOOL)isUbiquitousItemDownloadingStatusNotDownloaded {
    return self.isUbiquitous ? [self.ubiquitousItemDownloadingStatus isEqualToString:NSMetadataUbiquitousItemDownloadingStatusNotDownloaded] : NO;
}
- (BOOL)isUbiquitousItemDownloadingStatusDownloaded {
    return self.isUbiquitous ? [self.ubiquitousItemDownloadingStatus isEqualToString:NSMetadataUbiquitousItemDownloadingStatusDownloaded] : NO;
}
- (BOOL)isUbiquitousItemDownloadingStatusCurrent {
    return self.isUbiquitous ? [self.ubiquitousItemDownloadingStatus isEqualToString:NSMetadataUbiquitousItemDownloadingStatusCurrent] : NO;
}

- (BOOL)isSyncing {
    return self.isUbiquitous && (self.ubiquitousItemIsDownloading ||
                                 self.ubiquitousItemIsUploading);
}

+ (NSArray *)madMetaDataItemsForNSMetadataItems:(NSArray *)metadataItems {
    NSMutableArray *madMetaDataItems = [[NSMutableArray alloc] initWithCapacity:metadataItems.count];
    for (NSMetadataItem *metadataItem in metadataItems) {
        MADMetaData *metaData = [[MADMetaData alloc] initWithMetadataItem:metadataItem];
        [madMetaDataItems addObject:metaData];
    }
    return madMetaDataItems;
}

- (BOOL)samePercentages:(MADMetaData *)unknown {
    return self.ubiquitousItemPercentDownloaded == unknown.ubiquitousItemPercentDownloaded &&
            self.ubiquitousItemPercentUploaded == unknown.ubiquitousItemPercentUploaded;
}

- (NSUInteger)samePercentageHash {
    return self.ubiquitousItemPercentDownloaded * 5 + self.ubiquitousItemPercentUploaded * 7;
}

- (unsigned long long)fileSystemFileNumber {
    NSError *error = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.URL.path error:&error];
    NSNumber *fsfn = [attributes objectForKey:NSFileSystemFileNumber];
    return fsfn.longLongValue;
}

- (unsigned long long)fileSystemNumber {
    NSError *error = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.URL.path error:&error];
    NSNumber *fsf = [attributes objectForKey:NSFileSystemNumber];
    return fsf.longLongValue;
}

- (unsigned long long)st_ino {
    struct stat sa;
    if (stat(self.URL.path.UTF8String, &sa) < 0) return 0;
    return sa.st_ino;
}

- (BOOL)sameFile:(MADMetaData *)unknown {
    return self.fileSystemNumber == unknown.fileSystemNumber &&
            self.fileSystemFileNumber == self.fileSystemFileNumber;
}

- (unsigned long long)sameFileHash {
    return self.fileSystemNumber * 2 + self.fileSystemFileNumber * 3;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[MADMetaData class]]) {
        return [self.fileSystemName compare:((MADMetaData *)object).fileSystemName] == NSOrderedSame;
    }
    return  NO;
}

- (NSUInteger)hash {
    return self.fileSystemName.hash;
}

@end
