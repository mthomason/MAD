//
//  MADMetaDataTests.m
//  Linux/Tests
//
//  Ported from MADFileManagerTests/MADMetaDataTests.m: MADMetaData and its
//  Local/Cloud subclasses -- the factory-style initializers, the
//  NSDate/NSData return-type lie on the two file-date properties, and the
//  downloading-status reporting.  The Xcode setUp/tearDown pair is a fresh
//  temp directory with two files per test here.
//

#import "MADTestSupport.h"
#import <MADFileManager/MADMetaData.h>
#import <MADFileManager/MADMetaDataLocal.h>
#import <MADFileManager/MADMetaDataCloud.h>

static NSURL *makeTempDirectory(void) {
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath:path
							  withIntermediateDirectories:YES
											   attributes:nil
													error:nil];
	return [NSURL fileURLWithPath:path];
}

static NSURL *makeFileInDirectory(NSURL *directory, NSString *name) {
	NSURL *url = [directory URLByAppendingPathComponent:name];
	NSData *data = [@"hello" dataUsingEncoding:NSUTF8StringEncoding];
	[data writeToURL:url options:NSDataWritingAtomic error:nil];
	return url;
}

static void removeDirectory(NSURL *directory) {
	[[NSFileManager defaultManager] removeItemAtURL:directory error:nil];
}

#pragma mark - Factory initializers

static void testInitWithURLReturnsLocalSubclass(void) {
	// -initWithURL: does not initialize `self`; it allocates a fresh
	// MADMetaDataLocal and returns that instead.
	NSURL *directory = makeTempDirectory();
	NSURL *textFile = makeFileInDirectory(directory, @"report.txt");
	MADMetaData *meta = [[MADMetaData alloc] initWithURL:textFile];
	MAD_PASS([meta isKindOfClass:[MADMetaDataLocal class]], "the URL initializer returns the Local subclass");
	MAD_PASS([meta isKindOfClass:[MADMetaData class]], "the result is still a MADMetaData");
	removeDirectory(directory);
}

static void testInitWithMetadataItemReturnsCloudSubclass(void) {
	MADMetaData *meta = [[MADMetaData alloc] initWithMetadataItem:nil];
	MAD_PASS([meta isKindOfClass:[MADMetaDataCloud class]], "the metadata-item initializer returns the Cloud subclass");
	MAD_PASS([meta isKindOfClass:[MADMetaData class]], "the result is still a MADMetaData");
}

static void testNewMetaDatumForEmptyItems(void) {
	MAD_PASS_EQUAL([MADMetaData newMetaDatumForMetadataItems:@[]], @[], "no items yields an empty array");
}

static void testNewMetaDatumWrapsEachItemAsCloud(void) {
	NSArray *items = @[[NSNull null], [NSNull null]];
	NSArray *meta = [MADMetaData newMetaDatumForMetadataItems:items];
	MAD_PASS(meta.count == 2u, "every item is wrapped");
	MAD_PASS([meta.firstObject isKindOfClass:[MADMetaDataCloud class]], "the first wrapper is a Cloud metadata");
	MAD_PASS([meta.lastObject isKindOfClass:[MADMetaDataCloud class]], "the last wrapper is a Cloud metadata");
}

#pragma mark - MADMetaDataLocal

static void testLocalNameStripsExtension(void) {
	NSURL *directory = makeTempDirectory();
	NSURL *textFile = makeFileInDirectory(directory, @"report.txt");
	MADMetaData *meta = [[MADMetaData alloc] initWithURL:textFile];
	MAD_PASS_EQUAL(meta.name, @"report", "the name drops the extension");
	MAD_PASS_EQUAL(meta.fileSystemName, @"report.txt", "the file-system name keeps it");
	removeDirectory(directory);
}

static void testLocalFileSize(void) {
	NSURL *directory = makeTempDirectory();
	NSURL *textFile = makeFileInDirectory(directory, @"report.txt");
	MADMetaData *meta = [[MADMetaData alloc] initWithURL:textFile];
	MAD_PASS(meta.fileSystemFileSize == (unsigned long long)5, "the five-byte file reports five bytes");
	removeDirectory(directory);
}

static void testLocalContentType(void) {
	NSURL *directory = makeTempDirectory();
	NSURL *textFile = makeFileInDirectory(directory, @"report.txt");
	MADMetaData *meta = [[MADMetaData alloc] initWithURL:textFile];
#if __APPLE__
	MAD_PASS_EQUAL(meta.contentType, @"public.plain-text", "a .txt file reports the plain-text UTI");
#else
	// UTType is Apple-only: there is no UTI database off Apple, and
	// MADMetaDataLocal's contentType answers nil (asserted per-platform
	// rather than counted as a need -- the nil is the platform's answer).
	MAD_PASS(meta.contentType == nil, "contentType is nil without a UTI database");
#endif
	removeDirectory(directory);
}

static void testLocalContentTypeNilWithoutExtension(void) {
	NSURL *directory = makeTempDirectory();
	NSURL *noExtensionFile = makeFileInDirectory(directory, @"noextension");
	MADMetaData *meta = [[MADMetaData alloc] initWithURL:noExtensionFile];
	MAD_PASS(meta.contentType == nil, "a file with no extension has no content type");
	removeDirectory(directory);
}

static void testLocalNameEmptyForNilURL(void) {
	MADMetaData *meta = [[MADMetaData alloc] initWithURL:nil];
	MAD_PASS_EQUAL(meta.name, @"", "a nil URL yields an empty name");
}

static void testLocalCreationDateIsActuallyNSDate(void) {
	// The header declares these properties as NSDate, but the implementation
	// returns NSData (the compiler sees the wrong type).  The object that
	// actually comes back is an NSDate.
	NSURL *directory = makeTempDirectory();
	NSURL *textFile = makeFileInDirectory(directory, @"report.txt");
	MADMetaData *meta = [[MADMetaData alloc] initWithURL:textFile];
	MAD_PASS([meta.fileSystemFileCreationDate isKindOfClass:[NSDate class]], "the creation date is an NSDate");
	MAD_PASS([meta.fileSystemContentChangeDate isKindOfClass:[NSDate class]], "the change date is an NSDate");
	removeDirectory(directory);
}

static void testLocalUbiquitousFlags(void) {
	NSURL *directory = makeTempDirectory();
	NSURL *textFile = makeFileInDirectory(directory, @"report.txt");
	MADMetaData *meta = [[MADMetaData alloc] initWithURL:textFile];
	MAD_PASS(!meta.isUbiquitous, "a local file is not ubiquitous");
	MAD_PASS(meta.isDownloaded, "a local file counts as downloaded");
	MAD_PASS(!meta.isSyncing, "a local file is not syncing");
	MAD_PASS(meta.ubiquitousItemPercentDownloaded == 100.0, "the local download percentage is 100");
	MAD_PASS(meta.ubiquitousItemPercentUploaded == 100.0, "the local upload percentage is 100");
	removeDirectory(directory);
}

static void testLocalDownloadingStatusIsConsistent(void) {
	NSURL *directory = makeTempDirectory();
	NSURL *textFile = makeFileInDirectory(directory, @"report.txt");
	MADMetaData *meta = [[MADMetaData alloc] initWithURL:textFile];
	MAD_PASS_EQUAL(meta.ubiquitousItemDownloadingStatus, @"NSMetadataUbiquitousItemDownloadingStatusCurrent",
				   "the status is the current one");
	MAD_PASS(meta.isUbiquitousItemDownloadingStatusCurrent, "the derived boolean agrees with the status string");
	removeDirectory(directory);
}

static void testLocalCopy(void) {
	NSURL *directory = makeTempDirectory();
	NSURL *textFile = makeFileInDirectory(directory, @"report.txt");
	MADMetaData *meta = [[MADMetaData alloc] initWithURL:textFile];
	MADMetaData *copy = [meta copy];
	MAD_PASS(copy != nil, "the copy exists");
	MAD_PASS([copy isKindOfClass:[MADMetaDataLocal class]], "the copy is a Local metadata");
	MAD_PASS_EQUAL(copy.fileSystemName, meta.fileSystemName, "the copy carries the same name");
	MAD_PASS(copy != meta, "the copy is a different object");
	removeDirectory(directory);
}

static void testEqualityAndHash(void) {
	NSURL *directory = makeTempDirectory();
	NSURL *textFile = makeFileInDirectory(directory, @"report.txt");
	NSURL *noExtensionFile = makeFileInDirectory(directory, @"noextension");
	MADMetaData *a = [[MADMetaData alloc] initWithURL:textFile];
	MADMetaData *b = [[MADMetaData alloc] initWithURL:textFile];
	MAD_PASS_EQUAL(a, b, "metadata for the same file is equal");
	MAD_PASS(a.hash == b.hash, "equal metadata hashes equally");

	MADMetaData *c = [[MADMetaData alloc] initWithURL:noExtensionFile];
	MAD_PASS(![a isEqual:c], "metadata for a different file is not equal");
	removeDirectory(directory);
}

#pragma mark - MADMetaDataCloud (nil metadata item)

static void testCloudNilMetadataItem(void) {
	MADMetaDataCloud *cloud = [[MADMetaDataCloud alloc] initWithMetadataItem:nil];
	MAD_PASS(cloud.name == nil, "a nil item has no name");
	MAD_PASS(cloud.fileSystemName == nil, "a nil item has no file-system name");
	MAD_PASS(cloud.fileSystemFileSize == (unsigned long long)0, "a nil item has size 0");
	MAD_PASS(!cloud.isUbiquitous, "a nil item is not ubiquitous");
	MAD_PASS_EQUAL(cloud.ubiquitousItemDownloadingStatus, @"NSMetadataUbiquitousItemDownloadingStatusCurrent",
				   "a nil item reports the current status");
	MAD_PASS(cloud.isUbiquitousItemDownloadingStatusCurrent, "the derived boolean agrees");
	MAD_PASS(cloud.isDownloaded, "a nil item counts as downloaded");
	MAD_PASS(!cloud.isSyncing, "a nil item is not syncing");
}

MAD_TEST_MAIN("MADMetaDataTests",
	MAD_TEST(testInitWithURLReturnsLocalSubclass),
	MAD_TEST(testInitWithMetadataItemReturnsCloudSubclass),
	MAD_TEST(testNewMetaDatumForEmptyItems),
	MAD_TEST(testNewMetaDatumWrapsEachItemAsCloud),
	MAD_TEST(testLocalNameStripsExtension),
	MAD_TEST(testLocalFileSize),
	MAD_TEST(testLocalContentType),
	MAD_TEST(testLocalContentTypeNilWithoutExtension),
	MAD_TEST(testLocalNameEmptyForNilURL),
	MAD_TEST(testLocalCreationDateIsActuallyNSDate),
	MAD_TEST(testLocalUbiquitousFlags),
	MAD_TEST(testLocalDownloadingStatusIsConsistent),
	MAD_TEST(testLocalCopy),
	MAD_TEST(testEqualityAndHash),
	MAD_TEST(testCloudNilMetadataItem));
