//
//  MADDirectoryMonitorTests.m
//  MADFileManagerTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADDirectoryMonitor, the VNODE dispatch-source watcher behind
//  MADLocalFileCoordinator.  Everything runs against a per-test temp directory;
//  the monitor itself never touches the application's document store.
//
//  The source is private, so the tests reach it through KVC (the object pointer
//  is all the association tests need).  A monitor over a path that does not
//  exist opens no descriptor and silently refuses to start -- that is the
//  current contract, not an error path.
//
//  Every monitor here is stopped and drained before it is released.  The
//  source's cancel handler loads its owner through a weak reference and then
//  dereferences it directly, so releasing a monitor with a cancel still pending
//  segfaults in the handler (SIGSEGV at 0x8 in
//  -[MADDirectoryMonitor startMonitoring]_block_invoke.2).  See BUGS.md; the
//  stop-and-drain is the workaround, not the fix.
//

#import <XCTest/XCTest.h>

#import "MADDirectoryMonitor.h"
#import "MADDirectoryMonitorProtocol.h"

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

#pragma mark - Tests

@interface MADDirectoryMonitorTests : XCTestCase

@property (nonatomic, strong) NSURL *directory;
// Held strongly so the monitor cannot deallocate while its source is still
// pending cancellation -- see -tearDown: and BUGS.md.
@property (nonatomic, strong) MADDirectoryMonitor *monitor;

@end

@implementation MADDirectoryMonitorTests

- (void)setUp {
	[super setUp];
	self.directory = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString]
								isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:self.directory
							 withIntermediateDirectories:YES attributes:nil error:NULL];
}

- (void)tearDown {
	[self stopAndDrain:self.monitor];
	self.monitor = nil;

	[[NSFileManager defaultManager] removeItemAtURL:self.directory error:NULL];
	self.directory = nil;
	[super tearDown];
}

// Cancelling a source is asynchronous.  The cancel handler reads its owner
// through a weak reference and dereferences it without a nil check, so a
// monitor released before the handler runs crashes the process (BUGS.md).
// Stopping here and letting the queue drain keeps the owner alive long enough.
- (void)stopAndDrain:(MADDirectoryMonitor *)monitor {
	[monitor stopMonitoring];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
}

- (NSURL *)fileURLNamed:(NSString *)name {
	return [self.directory URLByAppendingPathComponent:name];
}

#pragma mark - Description

- (void)testInitStoresTheURLAndReportsNoDescriptor {
	MADDirectoryMonitor *monitor = [[MADDirectoryMonitor alloc] initWithURL:self.directory];

	NSString *debug = [monitor debugQuickLookObject];
	XCTAssertTrue([debug containsString:[[NSStringFromClass([MADDirectoryMonitor class]) uppercaseString] copy]]);
	XCTAssertTrue([debug containsString:(self.directory.absoluteString ?: @"")]);
	// NotListening is -1; the monitor reports it until it is started.
	XCTAssertTrue([debug containsString:@"File descriptor: -1"]);
}

#pragma mark - Start / stop

- (void)testStartMonitoringAMissingDirectoryIsANoOp {
	NSURL *missing = [self.directory URLByAppendingPathComponent:@"not-there" isDirectory:YES];
	MADDirectoryMonitor *monitor = [[MADDirectoryMonitor alloc] initWithURL:missing];
	MADRecordingDirectoryMonitorDelegate *delegate = [[MADRecordingDirectoryMonitorDelegate alloc] init];
	monitor.delegate = delegate;

	XCTAssertNoThrow([monitor startMonitoring]);

	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
	XCTAssertEqual(delegate.changeCount, (NSUInteger)0);

	// Never started, so stopping is a no-op as well.
	XCTAssertNoThrow([monitor stopMonitoring]);
}

- (void)testStartingTwiceKeepsOneSource {
	MADDirectoryMonitor *monitor = [[MADDirectoryMonitor alloc] initWithURL:self.directory];
	self.monitor = monitor;

	[monitor startMonitoring];
	id firstSource = [monitor valueForKey:@"directoryMonitorSource"];
	XCTAssertNotNil(firstSource);

	// The second start must not build (and resume) a second source.
	XCTAssertNoThrow([monitor startMonitoring]);
	XCTAssertEqual([monitor valueForKey:@"directoryMonitorSource"], firstSource);
}

- (void)testStopMonitoringWithoutStartingIsSafe {
	MADDirectoryMonitor *monitor = [[MADDirectoryMonitor alloc] initWithURL:self.directory];
	self.monitor = monitor;

	XCTAssertNoThrow([monitor stopMonitoring]);
	XCTAssertNil([monitor valueForKey:@"directoryMonitorSource"]);
}

- (void)testObservesAChangeInTheMonitoredDirectory {
	MADDirectoryMonitor *monitor = [[MADDirectoryMonitor alloc] initWithURL:self.directory];
	self.monitor = monitor;
	MADRecordingDirectoryMonitorDelegate *delegate = [[MADRecordingDirectoryMonitorDelegate alloc] init];
	monitor.delegate = delegate;

	[monitor startMonitoring];
	XCTAssertNotNil([monitor valueForKey:@"directoryMonitorSource"]);

	// The first change after the source is armed is not always delivered (seen
	// roughly one run in five against the simulator's file-system watcher), so
	// each retry makes a fresh, distinct change and any one of them landing is
	// enough to show the monitor is observing.
	NSUInteger attempt = 0;
	while (delegate.changeCount == 0 && attempt < 5) {
		attempt++;
		NSString *name = [NSString stringWithFormat:@"change%lu.mad", (unsigned long)attempt];
		[@"contents" writeToURL:[self fileURLNamed:name]
					 atomically:YES encoding:NSUTF8StringEncoding error:NULL];
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
	}

	XCTAssertGreaterThan(delegate.changeCount, (NSUInteger)0);
}

- (void)testStoppedMonitorStopsObserving {
	MADDirectoryMonitor *monitor = [[MADDirectoryMonitor alloc] initWithURL:self.directory];
	self.monitor = monitor;
	MADRecordingDirectoryMonitorDelegate *delegate = [[MADRecordingDirectoryMonitorDelegate alloc] init];
	monitor.delegate = delegate;

	[monitor startMonitoring];
	[self stopAndDrain:monitor];

	[@"contents" writeToURL:[self fileURLNamed:@"b.mad"]
				 atomically:YES encoding:NSUTF8StringEncoding error:NULL];

	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
	XCTAssertEqual(delegate.changeCount, (NSUInteger)0);
}

@end
