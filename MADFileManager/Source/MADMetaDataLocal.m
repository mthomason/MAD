//
//  MADMetaDataLocal.m
//  MADFileManager
//
//  Created by Michael Thomason on 6/22/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMetaDataLocal.h"
#import <Foundation/NSURL.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSMetadataAttributes.h>
#if __APPLE__
#import <MobileCoreServices/UTType.h>
#import <UniformTypeIdentifiers/UTType.h>
#endif

@interface MADMetaDataLocal ()

	@property (nonatomic, copy, readwrite) NSURL *origionalURL;
	@property (nonatomic, strong) NSDictionary *attributes;

@end

@implementation MADMetaDataLocal

- (instancetype)initWithURL:(NSURL *)url {
	
	if (self = [super init]) {
		
		NSString *path;
		if ((path = url.path)) {
			NSDictionary *attributes;
			NSError *__autoreleasing error = nil;
			attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: path
																		  error: &error];
			_attributes = attributes;
		}
		
		_origionalURL = url.copy;
		
	}
	return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
	id copy = [[[self class] alloc] initWithURL: _origionalURL];
	return copy;
}

- (NSURL *)URL {
	return _origionalURL;
}

- (NSError *)ubiquitousItemUploadingError { return nil; }

- (NSError *)ubiquitousItemDownloadingError { return nil; }

- (NSString *)ubiquitousItemDownloadingStatus {
	return NSMetadataUbiquitousItemDownloadingStatusCurrent;
}

- (NSString *)name {
	NSString *displayName, *path;
	if ((path = _origionalURL.path)) {
		displayName = [[NSFileManager defaultManager] displayNameAtPath:path].copy;
	} else {
		displayName = @"";
	}
	return displayName.stringByDeletingPathExtension.copy;
}

- (NSString *)fileSystemName {
	id name = _origionalURL.path.lastPathComponent.copy;
	return  name;
}

- (unsigned long long)fileSystemFileSize {
	NSNumber *fileSize;
	fileSize = _attributes[NSFileSize];
	return fileSize.unsignedLongLongValue;
}

- (NSString *)contentType {
	if (!_origionalURL) return nil;
	NSString *pathExtension = _origionalURL.pathExtension;
	if (!pathExtension || pathExtension.length == 0) {
		return nil;
	}

#if __APPLE__
	UTType *type = [UTType typeWithFilenameExtension:pathExtension];
	return type.identifier;
#else
	// There is no UTI database off Apple, so there is no type to report.
	return nil;
#endif
}

- (NSString *)ubiquitousItemContainerDisplayName {
	NSString *path = _origionalURL.path.lastPathComponent.copy;
	return path;
}

- (NSDate *)fileSystemFileCreationDate {
	id date = [_attributes[NSFileCreationDate] copyWithZone:nil];
	return date;
}

- (NSDate *)fileSystemContentChangeDate {
	id date = [_attributes[NSFileModificationDate] copyWithZone:nil];
	return date;
}

- (NSURL *)ubiquitousItemURLInLocalContainer {
	id url = _origionalURL.copy;
	return url;
}

- (BOOL)downloaded { return YES; }
- (BOOL)isDownloaded { return YES; }

- (BOOL)isSyncing { return NO; }
- (BOOL)isUbiquitous { return NO; }
- (BOOL)ubiquitousItemDownloadRequested { return NO; }
- (BOOL)ubiquitousItemIsDownloading { return NO; }
- (BOOL)ubiquitousItemIsUploading { return NO; }
- (BOOL)ubiquitousItemIsUploaded { return NO; }
- (BOOL)ubiquitousItemIsExternalDocument { return NO; }
- (BOOL)isUbiquitousItemDownloadingStatusNotDownloaded { return NO; }
- (BOOL)isUbiquitousItemDownloadingStatusDownloaded { return NO; }
- (BOOL)isUbiquitousItemDownloadingStatusCurrent {
	// A local item is always fully present, so this must agree with
	// -ubiquitousItemDownloadingStatus above, which reports Current.
	return [self.ubiquitousItemDownloadingStatus isEqualToString:NSMetadataUbiquitousItemDownloadingStatusCurrent];
}
- (double)ubiquitousItemPercentUploaded { return 100.0; }
- (double)ubiquitousItemPercentDownloaded { return 100.0; }

- (id)debugQuickLookObject {
	NSMutableString *debug = [[NSMutableString alloc] init];
	NSString *classname = NSStringFromClass([self class]);
	id uppercaseClassname = [classname uppercaseString];
	[debug appendFormat:@"--%@--\n", uppercaseClassname];
	return debug;
}

@end
