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
#import <Foundation/NSException.h>
#import <MobileCoreServices/UTType.h>
#import <sys/stat.h>
#import "MADMetaDataLocal.h"
#import "MADMetaDataCloud.h"

NSException *exceptionNotImplemented(SEL);
NSException *exceptionNotImplemented(SEL thwoingSelector) {
    NSString *functionName = NSStringFromSelector(thwoingSelector);
    NSString *format = @"You must override %@ in a subclass";
    NSString *message = [[NSString alloc] initWithFormat:format, functionName];
    return [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:message
                                 userInfo:nil];
}

@interface MADMetaData ()

    @property (nonatomic, strong) NSMetadataItem *metadataItem;
    @property (nonatomic, strong) NSDictionary *attributes;

@end

@implementation MADMetaData

- (instancetype)initWithURL:(NSURL *)url {
    id metadata = [[MADMetaDataLocal alloc] initWithURL:url];
    return metadata;
}

- (instancetype)initWithMetadataItem:(NSMetadataItem *)item {
    id metadata = [[MADMetaDataCloud alloc] initWithMetadataItem:item];
    return metadata;
}

+ (MADMetaDatum *)madMetaDataItemsForNSMetadataItems:(NSArray <NSMetadataItem *> *)metadataItems {
    NSMutableArray *madMetaDataItems = [[NSMutableArray alloc] initWithCapacity:metadataItems.count];
    for (NSMetadataItem *metadataItem in metadataItems) {
        MADMetaData *metaData = [[MADMetaData alloc] initWithMetadataItem:metadataItem];
        [madMetaDataItems addObject:metaData];
    }
    return madMetaDataItems;
}

- (instancetype)copyWithZone:(NSZone *)zone { @throw exceptionNotImplemented(_cmd); }
- (NSData *)fileSystemFileCreationDate { @throw exceptionNotImplemented(_cmd); }
- (NSData *)fileSystemContentChangeDate { @throw exceptionNotImplemented(_cmd); }
- (BOOL)isUbiquitous { @throw exceptionNotImplemented(_cmd); }

- (NSError *)ubiquitousItemUploadingError { @throw exceptionNotImplemented(_cmd); }

- (NSError *)ubiquitousItemDownloadingError { @throw exceptionNotImplemented(_cmd); }

- (NSString *)ubiquitousItemDownloadingStatus { @throw exceptionNotImplemented(_cmd); }

- (NSString *)name { @throw exceptionNotImplemented(_cmd); }

- (NSString *)fileSystemName { @throw exceptionNotImplemented(_cmd); }

- (unsigned long long)fileSystemFileSize { @throw exceptionNotImplemented(_cmd); }

- (NSString *)contentType { @throw exceptionNotImplemented(_cmd); }

- (NSString *)ubiquitousItemContainerDisplayName { @throw exceptionNotImplemented(_cmd); }

- (NSURL *)ubiquitousItemURLInLocalContainer { @throw exceptionNotImplemented(_cmd); }

- (BOOL)ubiquitousItemDownloadRequested { @throw exceptionNotImplemented(_cmd); }

- (BOOL)ubiquitousItemIsDownloading { @throw exceptionNotImplemented(_cmd); }

- (BOOL)ubiquitousItemIsUploading { @throw exceptionNotImplemented(_cmd); }

- (BOOL)ubiquitousItemIsUploaded { @throw exceptionNotImplemented(_cmd); }

- (double)ubiquitousItemPercentUploaded { @throw exceptionNotImplemented(_cmd); }

- (double)ubiquitousItemPercentDownloaded { @throw exceptionNotImplemented(_cmd); }

- (BOOL)ubiquitousItemIsExternalDocument { @throw exceptionNotImplemented(_cmd); }

- (BOOL)isUbiquitousItemDownloadingStatusNotDownloaded { @throw exceptionNotImplemented(_cmd); }

- (BOOL)isUbiquitousItemDownloadingStatusDownloaded { @throw exceptionNotImplemented(_cmd); }

- (BOOL)isUbiquitousItemDownloadingStatusCurrent { @throw exceptionNotImplemented(_cmd); }

- (BOOL)isSyncing {
    return self.ubiquitous &&
            (self.ubiquitousItemIsDownloading || self.ubiquitousItemIsUploading);
}

- (unsigned long long)fileSystemFileNumber {
    NSString *path;
    if ((path = self.URL.path)) {
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
    if ((path = self.URL.path)) {
        NSError *error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: path
                                                                                    error: &error];
        NSNumber *fsf = attributes[NSFileSystemNumber];
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

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    NSString *classname = NSStringFromClass([self class]);
    NSString *url = _URL.absoluteString;
    id uppercaseClassname = [classname uppercaseString];
    [debug appendFormat:@"--%@--\n", uppercaseClassname];
    [debug appendFormat:@"\tMetadata item: %@\n", self.metadataItem];
    return debug;
}

@end
