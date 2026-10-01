//
//  MADDataTableFastBenchmarkTests.m
//  MADSqlite3Tests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Throughput and footprint baseline for the one row path the app actually pays for
//  on a report refresh:
//
//      sqlite source -> driver row loop -> <MADDataTableWriting> -> the on-disk
//      .maddb cache -> read back out
//
//  MAD Designer is a data processing app and its reports are meant to hold hundreds of
//  thousands of rows, so the two things these tests exist to catch are a path that got
//  slower and a path that started holding memory it used to stream.  Nothing else in
//  this repository measures either: the only other measurement in the tree is Xcode's
//  generated -testPerformanceExample template.
//
//  They are skipped at scale zero, which is the default, because the scale is the point and
//  no ordinary green run should pay for it.  Set the scale as a build setting, which is the
//  way that survives to a simulator test bundle:
//
//      xcodebuild test -workspace Reports.xcworkspace -scheme MADSqlite3 \
//          -destination 'platform=iOS Simulator,id=<UDID>' \
//          GCC_PREPROCESSOR_DEFINITIONS='$(inherited) MAD_BENCH_ROWS=200000'
//
//  MAD_BENCH_ROWS in the scheme's test-action environment overrides it too, for running
//  from the IDE.
//
//  The two footprint tests are the important ones, and they measure different failures.
//  The retained test ingests N rows and then 2N and asserts the table held neither set --
//  a cache that has to be resident to be read is a leak.  The spike test measures what the
//  row loop is holding before its autorelease pool drains, which is not a leak but is still
//  what gets the process killed on a large report.
//

#import <XCTest/XCTest.h>

#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <MADSqlite3/MADDataTableFast.h>

#import <mach/mach.h>

#import "sqlite3.h"

/// The columns the fixture writes and the row loop reads.  Five mixed widths, which is
/// what a report of any size is made of: a key, a short dimension to group on, a
/// measure, and a wide text column for the payload.
static NSArray <NSString *> *MADBenchFieldKeys(void) {
	return @[@"id", @"customer", @"amount", @"region", @"note"];
}

/// The resident size of this process, which is what the OS kills you for.  Read through
/// task_info rather than NSProcessInfo because only phys_footprint counts dirty pages and
/// compressed memory the way the jetsam limit does.
static NSUInteger MADBenchFootprint(void) {
	task_vm_info_data_t info;
	mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
	if (task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&info, &count) != KERN_SUCCESS) {
		return 0;
	}
	return (NSUInteger)info.phys_footprint;
}

static NSString *MADBenchMB(NSUInteger bytes) {
	return [NSString stringWithFormat:@"%.1f MB", (double)bytes / (1024.0 * 1024.0)];
}

/// Ingesting 2N rows may not cost materially more than ingesting N.  Generous on purpose:
/// the point is to catch a cache that has to be resident, which at this scale shows up as
/// hundreds of megabytes, not to pin the number to the megabyte.
static const NSUInteger MADBenchMaxScaleGrowthBytes = 48 * 1024 * 1024;

/// And a ceiling on what one row may cost before its pool drains, which catches an
/// order-of-magnitude regression without pretending to know the product's limit.  The
/// measured cost is around 500 bytes per row; this is four times that.
static const NSUInteger MADBenchMaxSpikeBytesPerRow = 2048;

/// Rows to generate, set at build time or in the test-action environment; zero skips the
/// suite.  See the header for the two ways to set it.
#ifndef MAD_BENCH_ROWS
#define MAD_BENCH_ROWS 0
#endif

@interface MADDataTableFastBenchmarkTests : XCTestCase
@property (nonatomic, strong) NSURL *tempDirectory;
@property (nonatomic, strong) NSURL *sourceURL;
/// Rows to generate; zero when the scale was never set, which is what skips the suite.
@property (nonatomic, assign) NSUInteger rowCount;
@end

@implementation MADDataTableFastBenchmarkTests

/// Resolved once per test; NSNotFound before it has been, zero when the scale was never set.
- (NSUInteger)rowCount {
	if (_rowCount == NSNotFound) {
		NSString *value = [[NSProcessInfo processInfo] environment][@"MAD_BENCH_ROWS"];
		NSInteger parsed = value.length > 0 ? value.integerValue : 0;
		_rowCount = parsed > 0 ? (NSUInteger)parsed : (NSUInteger)MAD_BENCH_ROWS;
	}
	return _rowCount;
}

- (void)setUp {
	[super setUp];
	self.rowCount = NSNotFound;

	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	self.tempDirectory = [NSURL fileURLWithPath:path isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:self.tempDirectory
							 withIntermediateDirectories:YES
											  attributes:nil
												   error:nil];
	self.sourceURL = [self.tempDirectory URLByAppendingPathComponent:@"source.sqlite"];
}

- (void)tearDown {
	[[NSFileManager defaultManager] removeItemAtURL:self.tempDirectory error:nil];
	self.tempDirectory = nil;
	self.sourceURL = nil;
	[super tearDown];
}

- (void)requireBenchmarkScale {
	XCTSkipIf(self.rowCount == 0,
			  @"No benchmark scale; build with MAD_BENCH_ROWS=<n> to run the "
			  @"MADDataTableFast benchmark.  See the header of this file.");
}

#pragma mark - Fixture

/// Generates the source rows in sqlite itself rather than by looping in Objective-C, so
/// the fixture costs one statement and no resident memory, and the measurement that
/// follows is entirely the code under test.  A recursive CTE is used because the bundled
/// sqlite3 is 3.49.2 (Compressor/library/sqlite3/sqlite3.h).  Rebuilds from scratch, so
/// the scale test can call it twice with two different counts.
- (void)writeSourceRowsCount:(NSUInteger)rowCount {
	[[NSFileManager defaultManager] removeItemAtURL:self.sourceURL error:nil];

	sqlite3 *db = NULL;
	XCTAssertEqual(sqlite3_open(self.sourceURL.path.UTF8String, &db), SQLITE_OK);
	XCTAssertEqual(sqlite3_exec(db,
		"CREATE TABLE bench (id INTEGER PRIMARY KEY, customer TEXT, amount REAL,"
		" region TEXT, note TEXT);", NULL, NULL, NULL), SQLITE_OK);

	NSString *fill = [NSString stringWithFormat:
		@"WITH RECURSIVE seq(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM seq WHERE i < %lu)"
		" INSERT INTO bench (id, customer, amount, region, note)"
		" SELECT i, 'customer-' || i, i * 1.5, 'region-' || (i %% 7),"
		" 'a note long enough to be a real payload for row ' || i FROM seq;",
		(unsigned long)rowCount];
	XCTAssertEqual(sqlite3_exec(db, fill.UTF8String, NULL, NULL, NULL), SQLITE_OK);
	sqlite3_close(db);
}

/// The app's refresh path, minus the app: a driver row loop handed nothing but a write
/// port.  The whole five-call port is the driver's to send, so nothing is seeded here.
- (MADDataTableFast *)ingestRowsIntoTableId:(NSUInteger)tableId error:(NSError **)error {
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:self.sourceURL];
	MADDatabaseSqlite3 *source = [[MADDatabaseSqlite3 alloc] init];
	source.databaseConnection = connection;
	[source openDatabase];

	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:tableId
													cacheDirectory:self.tempDirectory];

	BOOL success = [source executeSQL:@"SELECT id, customer, amount, region, note FROM bench ORDER BY id"
							fieldKeys:MADBenchFieldKeys()
						 onConnection:nil
					  intoResultTable:table
					   transactionSet:NO
					   returnsResults:YES
					   binaryBindings:nil
							withError:error];
	if (!success) return nil;
	return table;
}

- (MADDataTableFast *)ingestOrFailIntoTableId:(NSUInteger)tableId {
	NSError *error = nil;
	MADDataTableFast *table = [self ingestRowsIntoTableId:tableId error:&error];
	XCTAssertNotNil(table, @"the row loop refused the table: %@", error);
	return table;
}

/// Ingests inside its own autorelease pool, so the pool's debris is gone by the time this
/// returns and the caller measures only what the table kept.  The table comes back through
/// retainedTable and outlives the pool.
- (void)ingestRowsIntoTableId:(NSUInteger)tableId
				retainedTable:(MADDataTableFast * __strong *)retainedTable {
	NSError *error = nil;
	@autoreleasepool {
		*(retainedTable) = [self ingestRowsIntoTableId:tableId error:&error];
	}
	XCTAssertNotNil(*retainedTable, @"the row loop refused the table: %@", error);
}

#pragma mark - Throughput

- (void)testIngestThroughput {
	[self requireBenchmarkScale];
	[self writeSourceRowsCount:self.rowCount];

	// Two passes: enough to average over, few enough that a large MAD_BENCH_ROWS stays
	// a usable round trip.
	XCTMeasureOptions *options = XCTMeasureOptions.defaultOptions;
	options.iterationCount = 2;

	__block NSUInteger ingested = 0;
	[self measureWithMetrics:@[[XCTClockMetric new]]
					 options:options
					   block:^{
		@autoreleasepool {
			MADDataTableFast *table = [self ingestOrFailIntoTableId:1];
			ingested = table.count;
		}
	}];

	XCTAssertEqual(ingested, self.rowCount);
}

/// The report's bulk read: MADocument walks the query cache with
/// -enumeratorForKeyObjectsSorted (MADocument.m:866), which is this cursor.  It is a
/// single stepping statement, not a per-row re-query.
///
/// A loop of -objectAtRow: would measure something no production caller does, and would
/// be quadratic if it did: that accessor is LIMIT 1 OFFSET n
/// (MADDataTableFast.m:1086), so each call rescans to the row.
- (void)testSortedEnumeratorThroughput {
	[self requireBenchmarkScale];
	[self writeSourceRowsCount:self.rowCount];

	MADDataTableFast *table = [self ingestOrFailIntoTableId:2];
	XCTAssertEqual(table.count, self.rowCount);

	__block NSUInteger read = 0;
	[self measureWithMetrics:@[[XCTClockMetric new]]
					 options:XCTMeasureOptions.defaultOptions
					   block:^{
		NSUInteger seen = 0;
		for (NSDictionary *row in [table enumeratorForAllObjectsSorted]) {
			@autoreleasepool {
				if (row != nil) seen++;
			}
		}
		read = seen;
	}];

	XCTAssertEqual(read, self.rowCount);
}

/// The renderer's random access: each page element asks for one row by its cache id
/// (MADocument.m:874 -> MADDataTableFast.m:941), which is a WHERE ROWID = ? lookup with a
/// one-entry cache in front of it.  Sampled across the whole range so the lookup cannot
/// sit on one page of the index, which is the state a report actually renders in.
- (void)testRandomAccessThroughput {
	[self requireBenchmarkScale];
	[self writeSourceRowsCount:self.rowCount];

	MADDataTableFast *table = [self ingestOrFailIntoTableId:5];
	XCTAssertEqual(table.count, self.rowCount);

	__block NSUInteger read = 0;
	[self measureWithMetrics:@[[XCTClockMetric new]]
					 options:XCTMeasureOptions.defaultOptions
					   block:^{
		NSUInteger seen = 0;
		NSUInteger stride = 97;   // coprime with anything; walks the whole rowid range
		for (NSUInteger rowId = 1; rowId <= self.rowCount; rowId += stride) {
			@autoreleasepool {
				if ([table dataForRow:rowId error:NULL] != nil) seen++;
			}
		}
		read = seen;
	}];

	XCTAssertEqual(read, (self.rowCount + 96) / 97);
}

#pragma mark - Footprint

/// RETAINED: what the tables still hold once each ingest's autorelease pool has drained.
/// A number that grows with the row count here is a leak -- the report cache is supposed to
/// live in its .maddb file, not on the heap.  Both tables are alive for the second
/// measurement, so the first is the baseline the second is measured against.
- (void)testRetainedFootprintDoesNotScaleWithRowCount {
	[self requireBenchmarkScale];

	NSUInteger baseline = MADBenchFootprint();

	[self writeSourceRowsCount:self.rowCount];
	MADDataTableFast *small = nil;
	[self ingestRowsIntoTableId:3 retainedTable:&small];
	NSUInteger footprintAtN = MADBenchFootprint();

	[self writeSourceRowsCount:self.rowCount * 2];
	MADDataTableFast *large = nil;
	[self ingestRowsIntoTableId:4 retainedTable:&large];
	NSUInteger footprintAtTwoN = MADBenchFootprint();

	XCTAssertEqual(small.count, self.rowCount);
	XCTAssertEqual(large.count, self.rowCount * 2);

	NSUInteger growth = footprintAtTwoN > footprintAtN ? footprintAtTwoN - footprintAtN : 0;
	NSLog(@"MADDataTableFast retained: start %@; %lu rows -> %@; %lu rows -> %@ "
		  @"(growth %@ for %lu more rows)",
		  MADBenchMB(baseline),
		  (unsigned long)small.count, MADBenchMB(footprintAtN),
		  (unsigned long)large.count, MADBenchMB(footprintAtTwoN),
		  MADBenchMB(growth), (unsigned long)small.count);

	XCTAssertLessThan(growth, MADBenchMaxScaleGrowthBytes,
					  @"Ingesting %lu more rows left %@ still resident; the cache is being held "
					  @"in memory rather than streamed to its file.",
					  (unsigned long)small.count, MADBenchMB(growth));

	XCTAssertEqual(small.count + large.count, self.rowCount * 3);
}

/// SPIKE: the footprint at the moment the row loop returns, before its pool drains.
/// -insertRow: allocates a MADDatabaseDataBinding for every value of every row
/// (MADDataTableFast.m:562), and the row loop's pool is whatever the caller established, so
/// this grows with the rows ingested in one pool.  Nothing is leaked -- the retained test
/// above measures that separately -- but the process can still be jetsam-killed for holding
/// it, which is the crash a large report has to avoid.
- (void)testIngestSpikeStaysBounded {
	[self requireBenchmarkScale];
	[self writeSourceRowsCount:self.rowCount];

	NSUInteger before = MADBenchFootprint();
	MADDataTableFast *table = [self ingestOrFailIntoTableId:6];
	NSUInteger after = MADBenchFootprint();

	XCTAssertEqual(table.count, self.rowCount);

	NSUInteger spike = after > before ? after - before : 0;
	NSUInteger bytesPerRow = self.rowCount > 0 ? spike / self.rowCount : 0;
	NSLog(@"MADDataTableFast ingest spike: %@ for %lu rows (%lu bytes/row before the pool drains)",
		  MADBenchMB(spike), (unsigned long)self.rowCount, (unsigned long)bytesPerRow);

	XCTAssertLessThan(bytesPerRow, MADBenchMaxSpikeBytesPerRow,
					  @"The row loop is holding %lu bytes per row until its pool drains.",
					  (unsigned long)bytesPerRow);
}

@end
