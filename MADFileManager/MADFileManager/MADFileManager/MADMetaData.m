//
//  MADMetadata.m
//  MAD
//
//  Created by Michael Thomason on 10/7/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADMetaData.h"
#import <Foundation/NSURL.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSMetadataAttributes.h>
#import <Foundation/NSMetadata.h>
#import <MobileCoreServices/UTType.h>
#import <sys/stat.h>

@interface MADMetaData ()

    @property (nonatomic, copy, readwrite) NSURL *URL;

    @property (nonatomic, strong) NSMetadataItem *metadataItem;
    @property (nonatomic, strong) NSDictionary *attributes;

@end

@implementation MADMetaData

- (instancetype)initWithURL:(NSURL *)url {

    if (self = [super init]) {
        
        NSString *path;
        if ((path = url.path)) {
            NSDictionary *attributes;
            NSError *__autoreleasing * error = nil;
            attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: path
                                                                          error: error];
            _attributes = attributes;
        }

        _URL = url.copy;
        
    }
    return self;
}

- (instancetype)initWithMetadataItem:(NSMetadataItem *)item {

    if (self = [super init]) {
        self.metadataItem = item;
        
        NSURL *url = [item valueForAttribute: NSMetadataItemURLKey];
        _URL = url.copy;
        
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    id copy = self.metadataItem == nil ?
                [[[self class] alloc] initWithURL: self.URL] :
                [[[self class] alloc] initWithMetadataItem:self.metadataItem];
    return copy;
}

- (NSData *)fileSystemFileCreationDate {
    id date = _metadataItem ? [_metadataItem valueForAttribute:NSMetadataItemFSCreationDateKey] :
                              _attributes[NSFileCreationDate];
    return date;
}

- (NSData *)fileSystemContentChangeDate {
    id date = _metadataItem ?
                [_metadataItem valueForAttribute:NSMetadataItemFSContentChangeDateKey] :
                _attributes[NSFileModificationDate];
    return date;
}

- (bool)isUbiquitous {
    if (_metadataItem) {
        NSNumber *isUbiquitous;
        isUbiquitous = [self.metadataItem valueForAttribute: NSMetadataItemIsUbiquitousKey];
        return isUbiquitous.boolValue;
    } else {
        return false;
    }
}

- (NSError *)ubiquitousItemUploadingError {
    return self.metadataItem ?
        [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemUploadingErrorKey] :
        nil;
}

- (NSError *)ubiquitousItemDownloadingError {
    return self.metadataItem ?
        [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemDownloadingErrorKey] :
        nil;
}

- (NSString *)ubiquitousItemDownloadingStatus {
    return self.metadataItem ?
        [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemDownloadingStatusKey] :
        NSMetadataUbiquitousItemDownloadingStatusCurrent;
}

- (NSString *)name {
    NSString *displayName;
    if (self.metadataItem) {
        displayName = [self.metadataItem valueForAttribute: NSMetadataItemDisplayNameKey];
    } else {
        NSString *path;
        if ((path = _URL.path)) {
            displayName = [[NSFileManager defaultManager] displayNameAtPath:path];
        } else {
            displayName = @"";
        }
    }
    return displayName.stringByDeletingPathExtension;
}

- (NSString *)fileSystemName {
    id name = _metadataItem ? [_metadataItem valueForAttribute: NSMetadataItemFSNameKey] :
                              _URL.path.lastPathComponent;
    return  name;
}

- (unsigned long long)fileSystemFileSize {
    NSNumber *fileSize;
    fileSize = _metadataItem ? [self.metadataItem valueForAttribute: NSMetadataItemFSSizeKey] :
                               (self.attributes)[NSFileSize];
    return fileSize.unsignedLongLongValue;
}

- (NSString *)contentType {
    if (_metadataItem) {
        id key = [self.metadataItem valueForAttribute: NSMetadataItemContentTypeKey];
        return key;
    } else {
        NSString * __nonnull pathExtension = (_URL.pathExtension) ?
                                (NSString * __nonnull)_URL.pathExtension :@"";
        __nullable CFStringRef cfkey;
        cfkey = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                      (__bridge CFStringRef)pathExtension,
                                                      NULL);
        id key = CFBridgingRelease(cfkey);
        return key;
    }
}

- (NSString *)ubiquitousItemContainerDisplayName {
    if (_metadataItem) {
        NSString *name;
        name = [_metadataItem valueForAttribute:NSMetadataUbiquitousItemContainerDisplayNameKey];
        return name;
    } else {
        NSString *path = _URL.path;
        return path.lastPathComponent;
    }
}

- (NSURL *)ubiquitousItemURLInLocalContainer {
    id url;
    url = _metadataItem ?
        [_metadataItem valueForAttribute:NSMetadataUbiquitousItemURLInLocalContainerKey] :
        _URL;
    return url;
}

- (bool)ubiquitousItemDownloadRequested {
    if (_metadataItem) {
        NSNumber *result;
        result = [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemDownloadRequestedKey];
        return result.boolValue;
    } else {
        return false;
    }
}

- (bool)ubiquitousItemIsDownloading {
    if (_metadataItem) {
        NSNumber *result;
        result = [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemIsDownloadingKey];
        return result.boolValue;
    } else {
        return false;
    }
}

- (bool)ubiquitousItemIsUploading {
    if (_metadataItem) {
        NSNumber *result;
        result = [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemIsUploadingKey];
        return result.boolValue;
    } else {
        return false;
    }
}

- (bool)ubiquitousItemIsUploaded {
    if (_metadataItem) {
        NSNumber *result;
        result = [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemIsUploadedKey];
        return result.boolValue;
    } else {
        return false;
    }
}

- (double)ubiquitousItemPercentUploaded {
    if (_metadataItem) {
        NSNumber *result;
        result = [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemPercentUploadedKey];
        return result.doubleValue;
    } else {
        return 100.0;
    }
}

- (double)ubiquitousItemPercentDownloaded {
    if (_metadataItem) {
        NSNumber *result;
        result = [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemPercentDownloadedKey];
        return result.doubleValue;
    } else {
        return 100.0;
    }
}

- (bool)ubiquitousItemIsExternalDocument {
    if (_metadataItem) {
        NSNumber *result;
        result = [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemIsExternalDocumentKey];
        return result.boolValue;
    } else {
        return false;
    }
}

- (bool)isUbiquitousItemDownloadingStatusNotDownloaded {
    if (self.ubiquitous) {
        NSString *status = self.ubiquitousItemDownloadingStatus;
        return [status isEqualToString:NSMetadataUbiquitousItemDownloadingStatusNotDownloaded] ?
                YES : NO;
    } else {
        return false;
    }
}

- (bool)isUbiquitousItemDownloadingStatusDownloaded {
    if (self.ubiquitous) {
        NSString *status = self.ubiquitousItemDownloadingStatus;
        return [status isEqualToString:NSMetadataUbiquitousItemDownloadingStatusDownloaded] ?
                YES : NO;
    } else {
        return false;
    }
}

- (bool)isUbiquitousItemDownloadingStatusCurrent {
    if (self.ubiquitous) {
        NSString *status = self.ubiquitousItemDownloadingStatus;
        return [status isEqualToString:NSMetadataUbiquitousItemDownloadingStatusCurrent] ?
                YES : NO;
    } else {
        return false;
    }
}

- (bool)isSyncing {
    return self.ubiquitous &&
            (self.ubiquitousItemIsDownloading || self.ubiquitousItemIsUploading);
}

+ (MADMetaDataArray *)madMetaDataItemsForNSMetadataItems:(NSArray <NSMetadataItem *> *)metadataItems {
    NSMutableArray *madMetaDataItems = [[NSMutableArray alloc] initWithCapacity:metadataItems.count];
    for (NSMetadataItem *metadataItem in metadataItems) {
        MADMetaData *metaData = [[MADMetaData alloc] initWithMetadataItem:metadataItem];
        [madMetaDataItems addObject:metaData];
    }
    return madMetaDataItems;
}

- (unsigned long long)fileSystemFileNumber {
    NSString *path;
    if ((path = _URL.path)) {
        NSError *error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: path
                                                                                    error: &error];
        NSNumber *fsfn = attributes[NSFileSystemFileNumber];
        return fsfn.unsignedLongLongValue;
    } else {
        return 0;
    }
}

- (unsigned long long)fileSystemNumber {
    NSString *path;
    if ((path = _URL.path)) {
        NSError *error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: path
                                                                                    error: &error];
        NSNumber * __weak fsf = attributes[NSFileSystemNumber];
        return fsf.unsignedLongLongValue;
    } else {
        return 0;
    }
}

- (unsigned long long)st_ino {
    struct stat sa;
    if (stat(self.URL.path.UTF8String, &sa) < 0)
        return 0;
    return sa.st_ino;
}

- (BOOL)sameFile:(MADMetaData *)unknown {
    return [self fileSystemNumber] == [unknown fileSystemNumber] &&
           [self fileSystemFileNumber] == [unknown fileSystemFileNumber];
}

- (unsigned long long)sameFileHash {
    return [self fileSystemNumber] * 2 + [self fileSystemFileNumber] * 3;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[MADMetaData class]]) {
        NSString *fileSystemNameUnknown = ((MADMetaData *)object).fileSystemName;
        NSString *fileSystemName = self.fileSystemName;
        return [fileSystemName compare:fileSystemNameUnknown] == NSOrderedSame;
    }
    return  NO;
}

- (NSUInteger)hash {
    return self.fileSystemName.hash;
}

@end
