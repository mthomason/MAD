//
//  MADLocalFileCoordinatorTests.m
//  Linux/Tests
//
//  Ported from MADFileManagerTests/MADLocalFileCoordinatorTests.m: the local
//  file coordinator -- initialization against the documents directory, the
//  name check, refresh reporting, and the remove/duplicate/rename operations.
//
//  The Xcode suite works against the App Group's Documents directory, which is
//  baked into MADURLFactory and cannot be redirected, so every test claims a
//  private path extension (a UUID-suffixed one) and creates/removes only files
//  carrying it.  Off Apple there is no app-group container: MADURLFactory's
//  fallback is the per-user Documents directory, which it returns but does not
//  create, so the fixture creates it.  Cleanup walks the directory by path
//  (the coordinator's own URL listing is what -refresh exercises).
//
//  Two live defects are pinned as the Xcode suite pins them:
//    - -removeFileAtURL: reports the removed URL in the *updatedURLs* box and
//      leaves removedURLs empty (the local arrays are handed over swapped).
//    - -documentsDirectory is @dynamic with only a getter, so the protocol's
//      setter raises.
//
//  Two GNUstep divergences were found here and fixed, each of which had left
//  its tests as needs:
//    - -refresh reported no contents: MADURLFactory's fallback built its
//      directory URL with -initWithString: (scheme-less) and GNUstep's
//      -contentsOfDirectoryAtURL: answers nil for anything that is not a
//      file:// URL.  MADURLFactory now builds it with +fileURLWithPath:
//      (MADFoundation/Source/MADURLFactory.m).
//    - -removeFileAtURL: crashed the process: GNUstep's
//      -coordinateAccessWithIntents:queue:byAccessor: faults when it runs the
//      accessor.  The Compat category calls the accessor on the given queue
//      instead (Linux/Compat/NSFileCoordinator+Presenter.m).
//

#import "MADTestSupport.h"
#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADURLFactory.h>
#import <MADFileManager/MADFileCoordinatorDelegate.h>
#import <MADFileManager/MADLocalFileCoordinator.h>

// Implemented but not declared in the header.
@interface MADLocalFileCoordinator (TestAccess)
- (id)debugQuickLookObject;
@end

#pragma mark - Test delegate

@interface MADRecordingFileCoordinatorDelegate : NSObject <MADFileCoordinatorDelegate>

@property (nonatomic, strong) NSArray *lastInsertedURLs;
@property (nonatomic, strong) NSArray *lastRemovedURLs;
@property (nonatomic, strong) NSArray *lastUpdatedURLs;
@property (nonatomic, strong) NSError *lastFailureError;
@property (nonatomic, assign) NSUInteger updateCount;
@property (nonatomic, assign) NSUInteger failureCount;

@end

@implementation MADRecordingFileCoordinatorDelegate {
	// The XCTestExpectation stand-in: set last, read by -waitForRecord, so the
	// arrays above are visible once the wait returns.
	volatile BOOL _recorded;
}

- (void)record {
	_recorded = YES;
}

- (BOOL)waitForRecordWithTimeout:(NSTimeInterval)timeout {
	return MADWaitForFlag(&_recorded, timeout);
}

- (void)fileCoordinatorDidUpdateContentsWithInsertedURLs:(NSArray *)insertedURLs
											 removedURLs:(NSArray *)removedURLs
											 updatedURLs:(NSArray *)updatedURLs {
	self.lastInsertedURLs = insertedURLs;
	self.lastRemovedURLs = removedURLs;
	self.lastUpdatedURLs = updatedURLs;
	self.updateCount++;
	[self record];
}

- (void)fileCoordinatorDidUpdateContentsWithInsertedMetaDatum:(NSArray *)insertedMetaDatum
											 removedMetaDatum:(NSArray *)removedMetaDatum
											 updatedMetaDatum:(NSArray *)updatedMetaDatum
												   completion:(void (^)(BOOL success, NSError *error))completion { }

- (void)fileCoordinatorDidFailRemovingFileAtURL:(NSURL *)URL withError:(NSError *)error {
	self.lastFailureError = error;
	self.failureCount++;
	[self record];
}

- (void)fileCoordinatorDidFailDuplicatingFileAtURL:(NSURL *)URL withError:(NSError *)error {
	self.lastFailureError = error;
	self.failureCount++;
	[self record];
}

- (void)fileCoordinatorDidFailRenamingFileAtURL:(NSURL *)URL withError:(NSError *)error {
	self.lastFailureError = error;
	self.failureCount++;
	[self record];
}

- (void)fileCoordinatorDidFailCreatingFileAtURL:(NSURL *)URL withError:(NSError *)error {
	self.lastFailureError = error;
	self.failureCount++;
	[self record];
}

@end

#pragma mark - Fixture

static NSString *gExtensionName = nil;

static NSURL *MADCoordinatorDocumentsDirectory(void) {
#if __APPLE__
	NSURL *container = [[NSFileManager defaultManager]
						containerURLForSecurityApplicationGroupIdentifier:[MADApplication groupIdentifier]];
	return [container URLByAppendingPathComponent:@"Documents" isDirectory:YES];
#else
	// No app-group containers off Apple: the coordinator is wired to the
	// per-user Documents fallback (MADURLFactoryTests pins the factory).
	return [MADURLFactory newURLLocalDocumentsDirectoryForGroupIdentifier:[MADApplication groupIdentifier]];
#endif
}

static void MADCoordinatorBeginTest(void) {
	gExtensionName = [@"mft" stringByAppendingString:[NSUUID UUID].UUIDString.lowercaseString];
	// The Apple path creates the container's Documents directory on first use;
	// the Linux fallback does not, so the fixture does it here.
	[[NSFileManager defaultManager] createDirectoryAtURL:MADCoordinatorDocumentsDirectory()
							 withIntermediateDirectories:YES attributes:nil error:NULL];
}

static void MADCoordinatorEndTest(void) {
	// Only the files this test wrote: the directory is the shared Documents
	// directory, not a private one.  Walked by path because GNUstep's
	// -contentsOfDirectoryAtURL: refuses the fallback URL (see the header).
	NSString *path = MADCoordinatorDocumentsDirectory().path;
	NSArray <NSString *> *names = path != nil
		? [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL] : @[];
	for (NSString *name in names) {
		if ([name.pathExtension isEqualToString:gExtensionName]) {
			[[NSFileManager defaultManager] removeItemAtPath:[path stringByAppendingPathComponent:name] error:NULL];
		}
	}
	gExtensionName = nil;
}

static MADLocalFileCoordinator *MADCoordinator(void) {
	return [[MADLocalFileCoordinator alloc] initWithPathExtension:gExtensionName
													   identifier:[MADApplication groupIdentifier]
										  firstQueryUpdateHandler:nil];
}

static NSString *MADCoordinatorFileName(NSString *handle) {
	return [handle stringByAppendingPathExtension:gExtensionName];
}

static NSURL *MADCoordinatorWriteFileNamed(NSString *name) {
	NSURL *URL = [MADCoordinatorDocumentsDirectory() URLByAppendingPathComponent:name];
	// By path: GNUstep's -writeToURL: refuses the scheme-less fallback URL
	// (answers NO, no error, no file); the file it writes is the same one.
	[@"report" writeToFile:(URL.path ?: @"") atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	return URL;
}

static NSURL *MADCoordinatorDocumentURLForName(NSString *name) {
	return [[MADCoordinatorDocumentsDirectory() URLByAppendingPathComponent:name]
			URLByAppendingPathExtension:gExtensionName];
}

#pragma mark - Initialization

static void testInitTargetsTheGroupDocumentsDirectory(void) {
	MADCoordinatorBeginTest();
	MADLocalFileCoordinator *coordinator = MADCoordinator();

#if __APPLE__
	NSURL *container = [[NSFileManager defaultManager]
						containerURLForSecurityApplicationGroupIdentifier:[MADApplication groupIdentifier]];
	MAD_PASS(container != nil, "the group container exists");
	MAD_PASS([coordinator.documentsDirectory.path hasPrefix:(container.path ?: @"")], "the directory is inside the container");
#else
	// Divergence: the fallback is the per-user directory (MADURLFactoryTests
	// pins the factory's answer); the coordinator is asserted to use it.
	MAD_PASS_EQUAL(coordinator.documentsDirectory,
				   [MADURLFactory newURLLocalDocumentsDirectoryForGroupIdentifier:[MADApplication groupIdentifier]],
				   "the per-user Documents fallback");
#endif
	MAD_PASS_EQUAL(coordinator.documentsDirectory.lastPathComponent, @"Documents", "the directory is Documents");

	MADCoordinatorEndTest();
}

static void testDocumentsDirectoryHasNoSetter(void) {
	MADCoordinatorBeginTest();
	// The protocol declares documentsDirectory readwrite, but the class
	// declares it @dynamic and only -documentsDirectory is implemented.
	MADLocalFileCoordinator *coordinator = MADCoordinator();

	MAD_PASS(![coordinator respondsToSelector:@selector(setDocumentsDirectory:)],
			 "there is no setter");
	MAD_THROWS_NAMED([coordinator setDocumentsDirectory:coordinator.documentsDirectory],
					 NSInvalidArgumentException, "setting documentsDirectory raises");

	MADCoordinatorEndTest();
}

static void testDebugQuickLookObjectListsTheGroupAndContents(void) {
	MADCoordinatorBeginTest();
	MADLocalFileCoordinator *coordinator = MADCoordinator();

	NSString *debug = [coordinator debugQuickLookObject];
	MAD_PASS([debug containsString:[NSStringFromClass([MADLocalFileCoordinator class]) uppercaseString]], "the description names the class");
	MAD_PASS([debug containsString:[MADApplication groupIdentifier]], "the description names the file group");
	MAD_PASS([debug containsString:@"Current contents:"], "the description lists the contents");

	MADCoordinatorEndTest();
}

#pragma mark - canCreateFileWithName:extention:fileGroup:

static void testAnEmptyNameCannotBeCreated(void) {
	MADCoordinatorBeginTest();
	MADLocalFileCoordinator *coordinator = MADCoordinator();

	MAD_PASS(![coordinator canCreateFileWithName:@""
									   extention:gExtensionName
									   fileGroup:[MADApplication groupIdentifier]],
			 "an empty name cannot be created");

	MADCoordinatorEndTest();
}

static void testAFreshNameCanBeCreatedAndAnExistingOneCannot(void) {
	MADCoordinatorBeginTest();
	MADLocalFileCoordinator *coordinator = MADCoordinator();

	MAD_PASS([coordinator canCreateFileWithName:@"Fresh"
									  extention:gExtensionName
									  fileGroup:[MADApplication groupIdentifier]],
			 "a fresh name can be created");

	MADCoordinatorWriteFileNamed(MADCoordinatorFileName(@"Fresh"));

	MAD_PASS(![coordinator canCreateFileWithName:@"Fresh"
									   extention:gExtensionName
									   fileGroup:[MADApplication groupIdentifier]],
			 "an existing name cannot be created");

	MADCoordinatorEndTest();
}

#pragma mark - refresh

static void testRefreshReportsANewFileAsInsertedAndRunsTheFirstQueryHandler(void) {
	MADCoordinatorBeginTest();
	MADLocalFileCoordinator *coordinator = MADCoordinator();
	MADRecordingFileCoordinatorDelegate *delegate = [[MADRecordingFileCoordinatorDelegate alloc] init];
	coordinator.delegate = delegate;

	NSURL *inserted = MADCoordinatorWriteFileNamed(MADCoordinatorFileName(@"One"));

	__block volatile BOOL handlerCalled = NO;
	MADLocalFileCoordinator *handlerCoordinator =
		[[MADLocalFileCoordinator alloc] initWithPathExtension:gExtensionName
													identifier:[MADApplication groupIdentifier]
									   firstQueryUpdateHandler:^{
			handlerCalled = YES;
		}];
	handlerCoordinator.delegate = delegate;

	[handlerCoordinator refresh];
	MAD_PASS([delegate waitForRecordWithTimeout:5.0], "the contents update is reported");

	MAD_PASS_EQUAL(delegate.lastInsertedURLs, @[inserted], "the new file is inserted");
	MAD_PASS_EQUAL(delegate.lastRemovedURLs, @[], "nothing is removed");
	MAD_PASS_EQUAL(delegate.lastUpdatedURLs, @[], "nothing is updated");

	MAD_PASS(MADWaitForFlag(&handlerCalled, 5.0), "the first query handler runs");

	MADCoordinatorEndTest();
}

static void testRefreshReportsARemovedFileWhenFilesRemain(void) {
	MADCoordinatorBeginTest();
	MADLocalFileCoordinator *coordinator = MADCoordinator();
	MADRecordingFileCoordinatorDelegate *delegate = [[MADRecordingFileCoordinatorDelegate alloc] init];
	coordinator.delegate = delegate;

	NSURL *first = MADCoordinatorWriteFileNamed(MADCoordinatorFileName(@"First"));
	NSURL *second = MADCoordinatorWriteFileNamed(MADCoordinatorFileName(@"Second"));

	[coordinator refresh];
	MAD_PASS([delegate waitForRecordWithTimeout:5.0], "the initial contents are reported");
	MAD_PASS(delegate.lastInsertedURLs.count == (NSUInteger)2, "both files are inserted");

	[[NSFileManager defaultManager] removeItemAtURL:first error:NULL];

	MADRecordingFileCoordinatorDelegate *second_delegate = [[MADRecordingFileCoordinatorDelegate alloc] init];
	coordinator.delegate = second_delegate;
	[coordinator refresh];
	MAD_PASS([second_delegate waitForRecordWithTimeout:5.0], "the removal is reported");

	MAD_PASS_EQUAL(second_delegate.lastRemovedURLs, @[first], "the removed file is reported");
	MAD_PASS_EQUAL(second_delegate.lastInsertedURLs, @[], "nothing is inserted");
	MAD_PASS(second_delegate.lastUpdatedURLs.count == (NSUInteger)0, "nothing is updated");
	MAD_PASS([[NSFileManager defaultManager] fileExistsAtPath:(second.path ?: @"")], "the other file remains");

	MADCoordinatorEndTest();
}

static void testRefreshIsSilentWhenTheLastMatchingFileIsGone(void) {
	// Quirk: an empty result set skips the whole comparison block, so losing the
	// last matching file produces no delegate callback at all.
	MADCoordinatorBeginTest();
	MADLocalFileCoordinator *coordinator = MADCoordinator();
	MADRecordingFileCoordinatorDelegate *delegate = [[MADRecordingFileCoordinatorDelegate alloc] init];
	coordinator.delegate = delegate;

	NSURL *only = MADCoordinatorWriteFileNamed(MADCoordinatorFileName(@"Only"));

	[coordinator refresh];
	MAD_PASS([delegate waitForRecordWithTimeout:5.0], "the initial contents are reported");
	MAD_PASS(delegate.updateCount == (NSUInteger)1, "one update is reported");

	[[NSFileManager defaultManager] removeItemAtURL:only error:NULL];

	MADRecordingFileCoordinatorDelegate *second_delegate = [[MADRecordingFileCoordinatorDelegate alloc] init];
	coordinator.delegate = second_delegate;
	[coordinator refresh];

	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
	MAD_PASS(second_delegate.updateCount == (NSUInteger)0, "the empty result is silent");

	MADCoordinatorEndTest();
}

#pragma mark - remove / duplicate / rename

static void testRemoveReportsTheURLAsUpdatedNotRemoved(void) {
	MADCoordinatorBeginTest();
	MADLocalFileCoordinator *coordinator = MADCoordinator();
	MADRecordingFileCoordinatorDelegate *delegate = [[MADRecordingFileCoordinatorDelegate alloc] init];
	coordinator.delegate = delegate;

	NSURL *URL = MADCoordinatorWriteFileNamed(MADCoordinatorFileName(@"Doomed"));


	[coordinator removeFileAtURL:URL];
	MAD_PASS([delegate waitForRecordWithTimeout:5.0], "the remove is reported");

	// The success branch hands the arrays over swapped.  The file is deleted,
	// but the delegate is told the URL was updated.
	MAD_PASS_EQUAL(delegate.lastUpdatedURLs, @[URL], "the URL is reported as updated");
	MAD_PASS_EQUAL(delegate.lastRemovedURLs, @[], "nothing is reported as removed");
	MAD_PASS_EQUAL(delegate.lastInsertedURLs, @[], "nothing is inserted");
	MAD_PASS(![[NSFileManager defaultManager] fileExistsAtPath:(URL.path ?: @"")], "the file is gone");

	MADCoordinatorEndTest();
}

static void testRemoveOfAMissingFileReportsAFailure(void) {
	MADCoordinatorBeginTest();
	MADLocalFileCoordinator *coordinator = MADCoordinator();
	MADRecordingFileCoordinatorDelegate *delegate = [[MADRecordingFileCoordinatorDelegate alloc] init];
	coordinator.delegate = delegate;

	NSURL *URL = MADCoordinatorDocumentURLForName(@"NeverWritten");

	[coordinator removeFileAtURL:URL];
	MAD_PASS([delegate waitForRecordWithTimeout:5.0], "the failure is reported");

	MAD_PASS(delegate.failureCount == (NSUInteger)1, "the failure is counted");
	MAD_PASS(delegate.lastFailureError != nil, "the failure carries an error");
	MAD_PASS(delegate.updateCount == (NSUInteger)0, "no update is reported");

	MADCoordinatorEndTest();
}

static void testDuplicateReportsTheCopyAsInserted(void) {
	MADCoordinatorBeginTest();
	MADLocalFileCoordinator *coordinator = MADCoordinator();
	MADRecordingFileCoordinatorDelegate *delegate = [[MADRecordingFileCoordinatorDelegate alloc] init];
	coordinator.delegate = delegate;

	NSURL *URL = MADCoordinatorWriteFileNamed(MADCoordinatorFileName(@"Original"));

	[coordinator duplicateFileAtURL:URL];
	MAD_PASS([delegate waitForRecordWithTimeout:5.0], "the duplicate is reported");

	MAD_PASS(delegate.lastInsertedURLs.count == (NSUInteger)1, "the copy is inserted");
	NSURL *copy = delegate.lastInsertedURLs.firstObject;
	MAD_PASS(![copy isEqual:URL], "the copy is a different URL");
	MAD_PASS([[NSFileManager defaultManager] fileExistsAtPath:(copy.path ?: @"")], "the copy exists");
	MAD_PASS([[NSFileManager defaultManager] fileExistsAtPath:(URL.path ?: @"")], "the original remains");

	MADCoordinatorEndTest();
}

static void testRenameReportsTheOldURLRemovedAndTheNewURLInserted(void) {
	MADCoordinatorBeginTest();
	MADLocalFileCoordinator *coordinator = MADCoordinator();
	MADRecordingFileCoordinatorDelegate *delegate = [[MADRecordingFileCoordinatorDelegate alloc] init];
	coordinator.delegate = delegate;

	NSURL *URL = MADCoordinatorWriteFileNamed(MADCoordinatorFileName(@"Before"));

	[coordinator renameFileAtURL:URL toName:@"After"];
	MAD_PASS([delegate waitForRecordWithTimeout:5.0], "the rename is reported");

	MAD_PASS(delegate.lastRemovedURLs.count == (NSUInteger)1, "the old URL is removed");
	MAD_PASS(delegate.lastInsertedURLs.count == (NSUInteger)1, "the new URL is inserted");
	NSURL *renamed = delegate.lastInsertedURLs.firstObject;
	MAD_PASS_EQUAL(renamed.pathExtension, gExtensionName, "the renaming keeps the extension");
	MAD_PASS_EQUAL(renamed.lastPathComponent.stringByDeletingPathExtension, @"After", "the new name");
	MAD_PASS([[NSFileManager defaultManager] fileExistsAtPath:(renamed.path ?: @"")], "the renamed file exists");
	MAD_PASS(![[NSFileManager defaultManager] fileExistsAtPath:(URL.path ?: @"")], "the old file is gone");

	MADCoordinatorEndTest();
}

MAD_TEST_MAIN("MADLocalFileCoordinatorTests",
	MAD_TEST(testInitTargetsTheGroupDocumentsDirectory),
	MAD_TEST(testDocumentsDirectoryHasNoSetter),
	MAD_TEST(testDebugQuickLookObjectListsTheGroupAndContents),
	MAD_TEST(testAnEmptyNameCannotBeCreated),
	MAD_TEST(testAFreshNameCanBeCreatedAndAnExistingOneCannot),
	MAD_TEST(testRefreshReportsANewFileAsInsertedAndRunsTheFirstQueryHandler),
	MAD_TEST(testRefreshReportsARemovedFileWhenFilesRemain),
	MAD_TEST(testRefreshIsSilentWhenTheLastMatchingFileIsGone),
	MAD_TEST(testRemoveReportsTheURLAsUpdatedNotRemoved),
	MAD_TEST(testRemoveOfAMissingFileReportsAFailure),
	MAD_TEST(testDuplicateReportsTheCopyAsInserted),
	MAD_TEST(testRenameReportsTheOldURLRemovedAndTheNewURLInserted));
