//
//  MADMetaDataCloud.m
//  MADFileManager
//
//  Created by Michael Thomason on 6/22/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADMetaDataCloud.h"
#import <Foundation/NSMetadata.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSURL.h>

@interface MADMetaDataCloud ()

    @property (nonatomic, copy) NSURL *origionalURL;
    @property (nonatomic, strong) NSMetadataItem *metadataItem;

@end

@implementation MADMetaDataCloud

- (instancetype)initWithMetadataItem:(NSMetadataItem *)item {
    
    if (self = [super init]) {
        self.metadataItem = item;
        NSURL *url = [item valueForAttribute: NSMetadataItemURLKey];
        _origionalURL = url.copy;

    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    id copy = [[[self class] alloc] initWithMetadataItem: _metadataItem];
    return copy;
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
    displayName = [_metadataItem valueForAttribute: NSMetadataItemDisplayNameKey];
    displayName = displayName.stringByDeletingPathExtension.copy;
    return displayName;
}

- (NSString *)fileSystemName {
    id name = [_metadataItem valueForAttribute: NSMetadataItemFSNameKey];
    return  name;
}

- (unsigned long long)fileSystemFileSize {
    NSNumber *fileSize;
    fileSize = [self.metadataItem valueForAttribute: NSMetadataItemFSSizeKey];
    return fileSize.unsignedLongLongValue;
}

- (NSString *)contentType {
    id key = [[self.metadataItem valueForAttribute: NSMetadataItemContentTypeKey] copyWithZone:nil];
    return key;
}

- (NSString *)ubiquitousItemContainerDisplayName {
    NSString *name;
    name = [_metadataItem valueForAttribute:NSMetadataUbiquitousItemContainerDisplayNameKey];
    return name;
}

- (NSURL *)URL {
    NSURL *URL = [[_metadataItem valueForAttribute: NSMetadataItemURLKey] copyWithZone:nil];
    return URL;
}

- (BOOL)isSyncing {
    return self.ubiquitous &&
        (self.ubiquitousItemIsDownloading || self.ubiquitousItemIsUploading);
}

- (BOOL)isUbiquitous {
    NSNumber *isUbiquitous;
    isUbiquitous = [self.metadataItem valueForAttribute: NSMetadataItemIsUbiquitousKey];
    return isUbiquitous.boolValue;
}

- (NSData *)fileSystemFileCreationDate {
    id date = [[_metadataItem valueForAttribute:NSMetadataItemFSCreationDateKey] copyWithZone:nil];
    return date;
}

- (NSData *)fileSystemContentChangeDate {
    id date = [[_metadataItem valueForAttribute:NSMetadataItemFSContentChangeDateKey]
                        copyWithZone:nil];
    return date;
}

- (NSURL *)ubiquitousItemURLInLocalContainer {
    id url = [[_metadataItem valueForAttribute:NSMetadataUbiquitousItemURLInLocalContainerKey]
                copyWithZone:nil];
    return url;
}

- (BOOL)ubiquitousItemDownloadRequested {
    NSNumber *result = [_metadataItem valueForAttribute:NSMetadataUbiquitousItemDownloadRequestedKey];
    return result.boolValue;
}

- (BOOL)ubiquitousItemIsDownloading {
    NSNumber *result;
    result = [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemIsDownloadingKey];
    return result.boolValue;
}

- (BOOL)ubiquitousItemIsUploading {
    NSNumber *result;
    result = [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemIsUploadingKey];
    return result.boolValue;
}

- (BOOL)ubiquitousItemIsUploaded {
    NSNumber *result;
    result = [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemIsUploadedKey];
    return result.boolValue;
}

- (double)ubiquitousItemPercentUploaded {
    NSNumber *result;
    result = [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemPercentUploadedKey];
    return result.doubleValue;
}

- (double)ubiquitousItemPercentDownloaded {
    NSNumber *result;
    result = [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemPercentDownloadedKey];
    return result.doubleValue;
}

- (BOOL)ubiquitousItemIsExternalDocument {
    NSNumber *result;
    result = [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemIsExternalDocumentKey];
    return result.boolValue;
}

- (BOOL)isUbiquitousItemDownloadingStatusNotDownloaded {
    NSString *status = self.ubiquitousItemDownloadingStatus;
    return [status isEqualToString:NSMetadataUbiquitousItemDownloadingStatusNotDownloaded] ?
                                                                                        YES : NO;
}

- (BOOL)isUbiquitousItemDownloadingStatusDownloaded {
        NSString *status = self.ubiquitousItemDownloadingStatus;
        return [status isEqualToString:NSMetadataUbiquitousItemDownloadingStatusDownloaded] ?
                                                                                        YES : NO;
}

- (BOOL)isUbiquitousItemDownloadingStatusCurrent {
        NSString *status = self.ubiquitousItemDownloadingStatus;
        return [status isEqualToString:NSMetadataUbiquitousItemDownloadingStatusCurrent] ?
                                                                                        YES : NO;
}

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    NSString *classname = NSStringFromClass([self class]);
    NSString *url = _origionalURL.absoluteString;
    id uppercaseClassname = [classname uppercaseString];
    [debug appendFormat:@"--%@--\n", uppercaseClassname];
    [debug appendFormat:@"\tOrigional URL: %@\n", url];
    return debug;
}

@end
