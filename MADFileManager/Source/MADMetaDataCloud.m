//
//  MADMetaDataCloud.m
//  MADFileManager
//
//  Created by Michael Thomason on 6/22/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMetaDataCloud.h"
#import <Foundation/NSMetadata.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSURL.h>

@interface MADMetaDataCloud ()
	@property (nonatomic, strong) NSMetadataItem *metadataItem;
@end

@implementation MADMetaDataCloud

- (instancetype)initWithMetadataItem:(NSMetadataItem *)item {
	
	if (self = [super init]) {
		self.metadataItem = item;
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
	unsigned long long size;
	NSNumber *fileSize;
	
	fileSize = [self.metadataItem valueForAttribute: NSMetadataItemFSSizeKey];
	size = fileSize.unsignedLongLongValue;
	
	return size;
}

- (NSString *)contentType {
	id value, result;
	
	value = [self.metadataItem valueForAttribute: NSMetadataItemContentTypeKey];
	result = [value copyWithZone:nil];
	
	return result;
}

- (NSString *)ubiquitousItemContainerDisplayName {
	NSString *value, *name;
	value = [_metadataItem valueForAttribute:NSMetadataUbiquitousItemContainerDisplayNameKey];
	name = [value copyWithZone:nil];
	return name;
}

- (NSURL *)URL {
	NSURL *value, *result;
	value = [_metadataItem valueForAttribute: NSMetadataItemURLKey];
	result = value.copy;
	return result;
}

- (BOOL)isSyncing {
	return self.isUbiquitous &&
		(self.ubiquitousItemIsDownloading || self.ubiquitousItemIsUploading);
}

- (BOOL)isUbiquitous {
	BOOL isUbiquitous = NO;
	NSNumber *wrapper;
	wrapper = [_metadataItem valueForAttribute: NSMetadataItemIsUbiquitousKey];
	isUbiquitous = wrapper.boolValue;
	return isUbiquitous;
}

- (NSDate *)fileSystemFileCreationDate {
	id value = [_metadataItem valueForAttribute:NSMetadataItemFSCreationDateKey];
	id date = [value copyWithZone:nil];
	return date;
}

- (NSDate *)fileSystemContentChangeDate {
	id value = [_metadataItem valueForAttribute:NSMetadataItemFSContentChangeDateKey];
	id date = [value copyWithZone:nil];
	return date;
}

- (NSURL *)ubiquitousItemURLInLocalContainer {
	id value = [_metadataItem valueForAttribute:NSMetadataUbiquitousItemURLInLocalContainerKey];
	id url = [value copyWithZone:nil];
	return url;
}

- (BOOL)ubiquitousItemDownloadRequested {
	BOOL result = NO;
	NSNumber *valuse = [_metadataItem valueForAttribute:NSMetadataUbiquitousItemDownloadRequestedKey];
	result = valuse.boolValue;
	return result;
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
	NSNumber *result = [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemPercentUploadedKey];
	return result.doubleValue;
}

- (double)ubiquitousItemPercentDownloaded {
	NSNumber *status = [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemPercentDownloadedKey];
	return status.doubleValue;
}

- (BOOL)ubiquitousItemIsExternalDocument {
	NSNumber *status = [self.metadataItem valueForAttribute:NSMetadataUbiquitousItemIsExternalDocumentKey];
	return status.boolValue;
}

- (BOOL)isUbiquitousItemDownloadingStatusNotDownloaded {
	BOOL result;
	NSString *status = [self ubiquitousItemDownloadingStatus];
	result = [status isEqualToString:NSMetadataUbiquitousItemDownloadingStatusNotDownloaded] ? YES : NO;
	return result;
}

- (BOOL)isUbiquitousItemDownloadingStatusDownloaded {
	NSString *status = [self ubiquitousItemDownloadingStatus ];
	return [status isEqualToString:NSMetadataUbiquitousItemDownloadingStatusDownloaded] ? YES : NO;
}

- (BOOL)isUbiquitousItemDownloadingStatusCurrent {
	NSString *status = [self ubiquitousItemDownloadingStatus];
	return [status isEqualToString:NSMetadataUbiquitousItemDownloadingStatusCurrent] ? YES : NO;
}

- (BOOL)downloaded {
	return [self isDownloaded];
}
- (BOOL)isDownloaded {
	BOOL downloaded = YES;
	if ([self isUbiquitous]) {
		if ([self isUbiquitousItemDownloadingStatusCurrent]) {
			downloaded = YES;
		} else {
			downloaded = NO;
		}
	}
	return downloaded;
}

- (id)debugQuickLookObject {
	NSMutableString *debug = [[NSMutableString alloc] init];
	NSString *classname = NSStringFromClass([self class]);
	NSURL *url = [self.metadataItem valueForAttribute: NSMetadataItemURLKey];
	id uppercaseClassname = [classname uppercaseString];
	[debug appendFormat:@"--%@--\n", uppercaseClassname];
	[debug appendFormat:@"\tOrigional URL: %@\n", url];
	return debug;
}

@end
