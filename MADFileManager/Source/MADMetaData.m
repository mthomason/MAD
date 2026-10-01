//
//  MADMetadata.m
//  MAD
//
//  Created by Michael Thomason on 10/7/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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

	//@property (nonatomic, strong) NSMetadataItem *metadataItem;
	//@property (nonatomic, strong) NSDictionary *attributes;

@end

@implementation MADMetaData

// Both initialisers deliberately return a *different* object than self: the caller gets
// the concrete subclass (Local for a URL, Cloud for a metadata item), and `self` is
// discarded.  This reads like a defect, but every producer -- MADFilesController's
// insert/remove/update paths and +newMetaDatumForMetadataItems: below -- depends on the
// concrete subclass coming back; the base MADMetaData throws exceptionNotImplemented from
// every accessor.  Do not "fix" this by initialising and returning self.  The real faults
// here are only the ARC leak of the discarded allocation and the instancetype type-lie;
// fixing those means a proper class cluster (+allocWithZone:), keeping the return value
// identical.
- (instancetype)initWithURL:(NSURL *)url {
	id metadata = [[MADMetaDataLocal alloc] initWithURL:url];
	return metadata;
}

- (instancetype)initWithMetadataItem:(NSMetadataItem *)item {
	id metadata = [[MADMetaDataCloud alloc] initWithMetadataItem:item];
	return metadata;
}

+ (NSArray <MADMetaData *> *)newMetaDatumForMetadataItems:(NSArray <NSMetadataItem *> *)metadataItems {
	NSMutableArray *madMetaDataItems = [[NSMutableArray alloc] initWithCapacity:metadataItems.count];
	for (NSMetadataItem *metadataItem in metadataItems) {
		MADMetaData *metaData = [[MADMetaData alloc] initWithMetadataItem:metadataItem];
		[madMetaDataItems addObject:metaData];
	}
	return madMetaDataItems;
}

- (instancetype)copyWithZone:(NSZone *)zone { @throw exceptionNotImplemented(_cmd); }

- (NSDate *)fileSystemFileCreationDate { @throw exceptionNotImplemented(_cmd); }

- (NSDate *)fileSystemContentChangeDate { @throw exceptionNotImplemented(_cmd); }

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

- (BOOL)isDownloaded { @throw exceptionNotImplemented(_cmd); }

- (BOOL)isSyncing {
	return self.isUbiquitous &&
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
		return [fileSystemName isEqualToString:fileSystemNameUnknown];
	}
	return  NO;
}

- (NSUInteger)hash {
	return self.fileSystemName.hash;
}

- (id)debugQuickLookObject {
	NSMutableString *debug = [[NSMutableString alloc] init];
	NSString *classname = NSStringFromClass([self class]);
	id uppercaseClassname = [classname uppercaseString];
	[debug appendFormat:@"--%@--\n", uppercaseClassname];
	return debug;
}

@end
