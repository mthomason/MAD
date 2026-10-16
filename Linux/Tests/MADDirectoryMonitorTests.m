//
//  MADDirectoryMonitorTests.m
//  Linux/Tests
//
//  Ported from MADFileManagerTests/MADDirectoryMonitorTests.m: the directory
//  watcher behind MADLocalFileCoordinator.  Everything runs against a per-test
//  temp directory; the monitor itself never touches the application's document
//  store.  The Xcode setUp/tearDown pair is a fresh temp directory per test here.
//
//  The source is private, so the tests reach it through KVC on Apple.  Off
//  Apple a dispatch source is a plain C pointer and GNUstep's KVC refuses
//  pointer-typed state ("Unable to find value for key"), so Linux reads the
//  synthesized ivar through the runtime instead (MADMonitorSourcePointer).
//
//  The source's cancel handler used to load its owner through a weak reference
//  and dereference it, so releasing a monitor with a cancel still pending
//  segfaulted in the handler.  The handler now holds the monitor for its one and
//  only run, which the last test below exercises -- holding the queue so the
//  handler cannot have run first; see BUGS.md.  The other monitors here are
//  still stopped and drained before release.
//

#import "MADTestSupport.h"
#import <MADFileManager/MADDirectoryMonitor.h>
#import <MADFileManager/MADDirectoryMonitorProtocol.h>
#import <objc/runtime.h>

// Xcode's Quick Look hook is implemented but not declared in the header.
@interface MADDirectoryMonitor (TestAccess)
- (id)debugQuickLookObject;
@end

#pragma mark - Test delegate

@interface MADRecordingDirectoryMonitorDelegate : NSObject <MADDirectoryMonitorProtocol>

@property (nonatomic, assign) NSUInteger changeCount;

@end

@implementation MADRecordingDirectoryMonitorDelegate

- (void)directoryMonitorDidObserveChange:(MADDirectoryMonitor *)directoryMonitor {
	self.changeCount++;
}

@end

#pragma mark - Lifetime spy

static BOOL MADSpyMonitorDeallocated = NO;

// Records that the monitor really was released: a fix that kept the cancel
// handler's owner alive forever would leak it, and the flag would stay NO.
@interface MADLifetimeSpyMonitor : MADDirectoryMonitor
@end

@implementation MADLifetimeSpyMonitor

- (void)dealloc {
	MADSpyMonitorDeallocated = YES;
	[super dealloc];
}

@end

#pragma mark - Fixture helpers

static NSURL *MADMonitorMakeTempDirectory(void) {
	NSURL *directory = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]]
								  isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:directory
							 withIntermediateDirectories:YES attributes:nil error:NULL];
	return directory;
}

static void MADMonitorRemoveTempDirectory(NSURL *directory) {
	[[NSFileManager defaultManager] removeItemAtURL:directory error:NULL];
}

// Cancelling a source is asynchronous, so stopping here and letting the queue
// drain releases nothing until the handler has run.
static void MADMonitorStopAndDrain(MADDirectoryMonitor *monitor) {
	[monitor stopMonitoring];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
}

// The queue is a plain C pointer off Apple, so GNUstep's KVC refuses it; read
// the synthesized ivar through the runtime, as MADMonitorSourcePointer does.
static const void *MADMonitorQueuePointer(MADDirectoryMonitor *monitor) {
	Ivar ivar = class_getInstanceVariable([MADDirectoryMonitor class], "_directoryMonitorQueue");
	return ivar == NULL ? NULL
		: *(void *const *)((const char *)(__bridge const void *)monitor + ivar_getOffset(ivar));
}

// On Apple the source is an object and KVC answers it (nil before it is
// built).  Off Apple it is a plain C pointer, which GNUstep's KVC refuses with
// an NSUnknownKeyException, so the synthesized ivar is read through the runtime.
static const void *MADMonitorSourcePointer(MADDirectoryMonitor *monitor) {
#if __APPLE__
	return (__bridge const void *)[monitor valueForKey:@"directoryMonitorSource"];
#else
	Ivar ivar = class_getInstanceVariable([MADDirectoryMonitor class], "_directoryMonitorSource");
	return ivar == NULL ? NULL
		: *(void *const *)((const char *)(__bridge const void *)monitor + ivar_getOffset(ivar));
#endif
}

static BOOL MADMonitorHasSource(MADDirectoryMonitor *monitor) {
	return MADMonitorSourcePointer(monitor) != NULL;
}

static BOOL MADMonitorWaitForChange(MADRecordingDirectoryMonitorDelegate *delegate, NSTimeInterval timeout) {
	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:timeout];
	while (delegate.changeCount == 0 && deadline.timeIntervalSinceNow > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
	}
	return delegate.changeCount > 0;
}

#pragma mark - Description

static void testInitStoresTheURLAndReportsNoDescriptor(void) {
	NSURL *directory = MADMonitorMakeTempDirectory();
	MADDirectoryMonitor *monitor = [[MADDirectoryMonitor alloc] initWithURL:directory];

	NSString *debug = [monitor debugQuickLookObject];
	MAD_PASS([debug containsString:[NSStringFromClass([MADDirectoryMonitor class]) uppercaseString]], "the description names the class");
	MAD_PASS([debug containsString:(directory.absoluteString ?: @"")], "the description names the URL");
	// NotListening is -1; the monitor reports it until it is started.
	MAD_PASS([debug containsString:@"File descriptor: -1"], "the descriptor is unopened");

	MADMonitorRemoveTempDirectory(directory);
}

#pragma mark - Start / stop

static void testStartMonitoringAMissingDirectoryIsANoOp(void) {
	NSURL *directory = MADMonitorMakeTempDirectory();
	NSURL *missing = [directory URLByAppendingPathComponent:@"not-there" isDirectory:YES];
	MADDirectoryMonitor *monitor = [[MADDirectoryMonitor alloc] initWithURL:missing];
	MADRecordingDirectoryMonitorDelegate *delegate = [[MADRecordingDirectoryMonitorDelegate alloc] init];
	monitor.delegate = delegate;

	MAD_NO_THROW([monitor startMonitoring], "starting on a missing directory does not throw");

	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
	MAD_PASS(delegate.changeCount == (NSUInteger)0, "no change is reported");

	// Never started, so stopping is a no-op as well.
	MAD_NO_THROW([monitor stopMonitoring], "stopping a never-started monitor does not throw");

	MADMonitorRemoveTempDirectory(directory);
}

static void testStartingTwiceKeepsOneSource(void) {
	NSURL *directory = MADMonitorMakeTempDirectory();
	MADDirectoryMonitor *monitor = [[MADDirectoryMonitor alloc] initWithURL:directory];

	[monitor startMonitoring];
	const void *firstSource = MADMonitorSourcePointer(monitor);
	MAD_PASS(firstSource != NULL, "the first start builds a source");

	// The second start must not build (and resume) a second source.
	MAD_NO_THROW([monitor startMonitoring], "the second start does not throw");
	MAD_PASS(MADMonitorSourcePointer(monitor) == firstSource, "the source is unchanged");

	MADMonitorStopAndDrain(monitor);
	MADMonitorRemoveTempDirectory(directory);
}

static void testStopMonitoringWithoutStartingIsSafe(void) {
	NSURL *directory = MADMonitorMakeTempDirectory();
	MADDirectoryMonitor *monitor = [[MADDirectoryMonitor alloc] initWithURL:directory];

	MAD_NO_THROW([monitor stopMonitoring], "stopping without starting does not throw");
	MAD_PASS(!MADMonitorHasSource(monitor), "there was no source to stop");

	MADMonitorRemoveTempDirectory(directory);
}

static void testObservesAChangeInTheMonitoredDirectory(void) {
	NSURL *directory = MADMonitorMakeTempDirectory();
	MADDirectoryMonitor *monitor = [[MADDirectoryMonitor alloc] initWithURL:directory];
	MADRecordingDirectoryMonitorDelegate *delegate = [[MADRecordingDirectoryMonitorDelegate alloc] init];
	monitor.delegate = delegate;

	[monitor startMonitoring];
	MAD_PASS(MADMonitorHasSource(monitor), "the source is armed");

	// The first change after the source is armed is not always delivered (seen
	// on Apple's file-system watcher), so each retry makes a fresh, distinct
	// change and any one of them landing is enough to show the monitor is
	// observing.
	NSUInteger attempt = 0;
	while (delegate.changeCount == 0 && attempt < 5) {
		attempt++;
		NSString *name = [[NSString alloc] initWithFormat:@"change%lu.mad", (unsigned long)attempt];
		NSURL *file = [directory URLByAppendingPathComponent:name];
		[@"contents" writeToURL:file atomically:YES encoding:NSUTF8StringEncoding error:NULL];
		MADMonitorWaitForChange(delegate, 0.5);
	}

	MAD_PASS(delegate.changeCount > (NSUInteger)0, "the change is observed");

	MADMonitorStopAndDrain(monitor);
	MADMonitorRemoveTempDirectory(directory);
}

static void testStoppedMonitorStopsObserving(void) {
	NSURL *directory = MADMonitorMakeTempDirectory();
	MADDirectoryMonitor *monitor = [[MADDirectoryMonitor alloc] initWithURL:directory];
	MADRecordingDirectoryMonitorDelegate *delegate = [[MADRecordingDirectoryMonitorDelegate alloc] init];
	monitor.delegate = delegate;

	[monitor startMonitoring];
	MADMonitorStopAndDrain(monitor);

	NSURL *file = [directory URLByAppendingPathComponent:@"b.mad"];
	[@"contents" writeToURL:file atomically:YES encoding:NSUTF8StringEncoding error:NULL];

	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
	MAD_PASS(delegate.changeCount == (NSUInteger)0, "a stopped monitor reports nothing");

	MADMonitorRemoveTempDirectory(directory);
}

static void testReleasingAMonitorWithACancelPendingDoesNotCrash(void) {
	// BUGS.md: with the cancel pending, the handler used to dereference a nil owner.
	// The source's queue is held down so the handler cannot have run before the
	// monitor is released, then let go: the handler runs with nothing else retaining
	// the monitor.  Against the old code the process faults here; with the fix the
	// handler is the monitor's last owner and releases it when it finishes.
	MADSpyMonitorDeallocated = NO;
	NSURL *directory = MADMonitorMakeTempDirectory();
	MADLifetimeSpyMonitor *monitor = [[MADLifetimeSpyMonitor alloc] initWithURL:directory];
	[monitor startMonitoring];
	dispatch_queue_t queue = (dispatch_queue_t)MADMonitorQueuePointer(monitor);
	MAD_PASS(queue != NULL, "the source's queue exists");

	dispatch_suspend(queue);
	[monitor stopMonitoring];
	[monitor release];
	dispatch_resume(queue);

	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	MAD_PASS(MADSpyMonitorDeallocated, "the monitor is released only by its cancel handler");

	MADMonitorRemoveTempDirectory(directory);
}

MAD_TEST_MAIN("MADDirectoryMonitorTests",
	MAD_TEST(testInitStoresTheURLAndReportsNoDescriptor),
	MAD_TEST(testStartMonitoringAMissingDirectoryIsANoOp),
	MAD_TEST(testStartingTwiceKeepsOneSource),
	MAD_TEST(testStopMonitoringWithoutStartingIsSafe),
	MAD_TEST(testObservesAChangeInTheMonitoredDirectory),
	MAD_TEST(testStoppedMonitorStopsObserving),
	MAD_TEST(testReleasingAMonitorWithACancelPendingDoesNotCrash));
