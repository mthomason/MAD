//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADCLIContainer.m
//  MAD Designer
//

#import "MADCLIContainer.h"
#import "MADCLI.h"	// for the exit codes the errors carry

// Reusing the app's archiver is the point: two implementations of the container
// would be two things to keep in step.  MADArchiveManager is a public MAD header,
// so this resolves on both platforms without an extra include path.
#import <MAD/MADArchiveManager.h>

static NSString * const MADCLIMetaPlistName		= @"meta.plist";
static NSString * const MADCLIStoreDirectory	= @"StoreContent";
static NSString * const MADCLIStoreName			= @"analyitics";	// misspelled on disk; see MAD_FORMAT.md section 2
static NSString * const MADCLIPortableStoreName	= @"store.sqlite";	// MAD_DocumentStore's name for it
static NSString * const MADCLIAdditionalContent	= @"AdditionalContent";

static const char MADCLIMagic[8] = { 'M', 'A', 'D', 'F', 'I', 'L', 'E', '\0' };

static NSError *MADCLIContainerError(NSInteger code, NSString *message) {
	return [NSError errorWithDomain: @"MADCLI" code: code
						   userInfo: @{ NSLocalizedDescriptionKey: message }];
}

static uint16_t MADCLIReadUInt16LE(const uint8_t *bytes) {
	return (uint16_t)(bytes[0] | (bytes[1] << 8));
}

static uint32_t MADCLIReadUInt32LE(const uint8_t *bytes) {
	return (uint32_t)bytes[0] | ((uint32_t)bytes[1] << 8) | ((uint32_t)bytes[2] << 16) | ((uint32_t)bytes[3] << 24);
}

static uint16_t MADCLIReadUInt16BE(const uint8_t *bytes) {
	return (uint16_t)((bytes[0] << 8) | bytes[1]);
}

static uint32_t MADCLIReadUInt32BE(const uint8_t *bytes) {
	return ((uint32_t)bytes[0] << 24) | ((uint32_t)bytes[1] << 16) | ((uint32_t)bytes[2] << 8) | (uint32_t)bytes[3];
}

NSString *MADCLISQLiteVersionString(uint32_t versionNumber) {
	return [NSString stringWithFormat: @"%u.%u.%u",
			(versionNumber / 1000000) % 1000,
			(versionNumber / 1000) % 1000,
			versionNumber % 1000];
}

@interface MADCLIContainer ()
@property (nonatomic, copy) NSURL *archiveURL;
@property (nonatomic, copy) NSURL *gutsURL;
@property (nonatomic) MADCLIFormatVersion formatVersion;
@property (nonatomic) uint32_t formatFlags;
@property (nonatomic, copy) NSDictionary *meta;
@property (nonatomic, copy) NSURL *strippedURL;	// the headerless copy, for a v1 document
@end

@implementation MADCLIContainer

- (void)discard {
	if (self.gutsURL) {
		[[NSFileManager defaultManager] removeItemAtURL: self.gutsURL error: NULL];
	}
	if (self.strippedURL) {
		[[NSFileManager defaultManager] removeItemAtURL: self.strippedURL error: NULL];
	}
}

+ (instancetype)containerWithContentsOfURL:(NSURL *)url error:(NSError **)error {

	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL isDirectory = NO;
	if (![fileManager fileExistsAtPath: url.path isDirectory: &isDirectory] || isDirectory) {
		if (error) *error = MADCLIContainerError(MADCLIExitBadDocument,
												 [NSString stringWithFormat: @"No such document: %@", url.path]);
		return nil;
	}

	NSData *header = [NSData dataWithContentsOfURL: url
										   options: NSDataReadingMappedIfSafe
											 error: error];
	if (header.length < 16) {
		if (error) *error = MADCLIContainerError(MADCLIExitBadDocument,
												 [NSString stringWithFormat: @"%@ is too short to be a .mad document.", url.lastPathComponent]);
		return nil;
	}

	MADCLIContainer *container = [[MADCLIContainer alloc] init];
	container.archiveURL = url;

	const uint8_t *bytes = header.bytes;
	if (memcmp(bytes, MADCLIMagic, sizeof(MADCLIMagic)) == 0) {
		container.formatVersion = (MADCLIFormatVersion)MADCLIReadUInt16LE(bytes + 8);
		container.formatFlags = MADCLIReadUInt32LE(bytes + 12);
	} else {
		container.formatVersion = MADCLIFormatVersion0;
		container.formatFlags = 0;
	}

	// The guts live in a directory of our own making, in the temporary directory,
	// so a run leaves nothing behind but what --out asks for.
	NSString *gutsName = [NSString stringWithFormat: @"mad-cli-%@-%@",
						  url.lastPathComponent.stringByDeletingPathExtension,
						  NSUUID.UUID.UUIDString];
	NSURL *temporaryDirectory = [NSURL fileURLWithPath: NSTemporaryDirectory() isDirectory: YES];
	container.gutsURL = [temporaryDirectory URLByAppendingPathComponent: gutsName isDirectory: YES];

	NSURL *archiveToUnpack = url;
	if (container.formatVersion != MADCLIFormatVersion0) {
		// A header is 16 bytes the archiver does not know about, so hand it a copy
		// with the header taken off rather than teaching libarchive to seek.
		NSData *stream = [header subdataWithRange: NSMakeRange(16, header.length - 16)];
		container.strippedURL = [temporaryDirectory URLByAppendingPathComponent:
								 [gutsName stringByAppendingPathExtension: @"tar.bz2"]];
		if (![stream writeToURL: container.strippedURL options: NSDataWritingAtomic error: error]) {
			return nil;
		}
		archiveToUnpack = container.strippedURL;
	}

	MADArchiveManager *manager = [[MADArchiveManager alloc] initWithFileWrapperURL: container.gutsURL
																	   archiveURL: archiveToUnpack];
	if (![manager unarchive]) {
		if (error) *error = MADCLIContainerError(MADCLIExitBadDocument,
												 [NSString stringWithFormat: @"Could not unpack %@.", url.lastPathComponent]);
		[container discard];
		return nil;
	}

	NSURL *metaURL = [container.gutsURL URLByAppendingPathComponent: MADCLIMetaPlistName];
	container.meta = [NSDictionary dictionaryWithContentsOfURL: metaURL] ?: @{};

	return container;
}

#pragma mark - Members

- (NSURL *)storeURL {
	NSURL *directory = [self.gutsURL URLByAppendingPathComponent: MADCLIStoreDirectory isDirectory: YES];
	NSURL *portable = [directory URLByAppendingPathComponent: MADCLIPortableStoreName];
	if ([[NSFileManager defaultManager] fileExistsAtPath: portable.path]) {
		return portable;
	}
	NSURL *legacy = [directory URLByAppendingPathComponent: MADCLIStoreName];
	if ([[NSFileManager defaultManager] fileExistsAtPath: legacy.path]) {
		return legacy;
	}
	return nil;
}

- (MADCLIContainerStoreKind)storeKind {
	NSURL *directory = [self.gutsURL URLByAppendingPathComponent: MADCLIStoreDirectory isDirectory: YES];
	if ([[NSFileManager defaultManager] fileExistsAtPath:
		 [directory URLByAppendingPathComponent: MADCLIPortableStoreName].path]) {
		return MADCLIContainerStoreKindPortable;
	}
	if ([[NSFileManager defaultManager] fileExistsAtPath:
		 [directory URLByAppendingPathComponent: MADCLIStoreName].path]) {
		return MADCLIContainerStoreKindLegacyCoreData;
	}
	return MADCLIContainerStoreKindNone;
}

// The journal siblings are named after whichever store is there: analyitics-wal
// for a legacy Core Data document, store.sqlite-wal for a portable one.
- (NSURL *)journalURLWithSuffix:(NSString *)suffix {
	NSURL *store = self.storeURL;
	if (store == nil) return nil;
	NSURL *url = [store.URLByDeletingLastPathComponent
				  URLByAppendingPathComponent: [store.lastPathComponent stringByAppendingString: suffix]];
	return [[NSFileManager defaultManager] fileExistsAtPath: url.path] ? url : nil;
}

- (NSURL *)walURL {
	return [self journalURLWithSuffix: @"-wal"];
}

- (NSURL *)shmURL {
	return [self journalURLWithSuffix: @"-shm"];
}

- (NSURL *)additionalContentURL {
	NSURL *url = [self.gutsURL URLByAppendingPathComponent: MADCLIAdditionalContent isDirectory: YES];
	BOOL isDirectory = NO;
	if ([[NSFileManager defaultManager] fileExistsAtPath: url.path isDirectory: &isDirectory] && isDirectory) {
		return url;
	}
	return nil;
}

- (NSArray <NSString *> *)memberPaths {
	// -subpathsAtPath: rather than -enumeratorAtURL:...: GNUstep's directory
	// enumerator drops the containing directory from the URLs it yields (measured
	// 2026-10-16 -- file:///repo/.../London.dataset yields file:///Contents.json),
	// and the relative paths are what this list is made of anyway.  Both platforms
	// answer the same thing here.  See Linux/README.md.
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray <NSString *> *paths = [fileManager subpathsAtPath: self.gutsURL.path];
	return [paths sortedArrayUsingSelector: @selector(compare:)];
}

#pragma mark - Store

- (MADCLISQLiteHeader)storeHeader {

	MADCLISQLiteHeader result;
	memset(&result, 0, sizeof(result));

	NSURL *storeURL = self.storeURL;
	if (storeURL == nil) return result;

	NSData *data = [NSData dataWithContentsOfURL: storeURL
										 options: NSDataReadingMappedIfSafe
										   error: NULL];
	if (data.length < 100) return result;

	const uint8_t *bytes = data.bytes;
	if (memcmp(bytes, "SQLite format 3\0", 16) != 0) return result;

	result.present = YES;
	// Page size is stored big-endian, except that the value 1 means 65536.
	uint32_t pageSize = MADCLIReadUInt16BE(bytes + 16);
	result.pageSize = (pageSize == 1) ? 65536 : pageSize;
	result.writeVersionWAL = (bytes[18] == 2);
	result.pageCount = MADCLIReadUInt32BE(bytes + 28);
	result.textEncoding = MADCLIReadUInt32BE(bytes + 56);
	result.sqliteVersion = MADCLIReadUInt32BE(bytes + 96);
	return result;
}

@end
