//
//  MADDataTableFastBenchmarkTests.m
//  Linux/Tests
//
//  Ported from MADSqlite3Tests/MADDataTableFastBenchmarkTests.m: throughput
//  and footprint baseline for the one row path the app actually pays for on a
//  report refresh:
//
//      sqlite source -> driver row loop -> <MADDataTableWriting> -> the on-disk
//      .maddb cache -> read back out
//
//  MAD Designer is a data processing app and its reports are meant to hold hundreds of
//  thousands of rows, so the two things these tests exist to catch are a path that got
//  slower and a path that started holding memory it used to stream.  Nothing else in
//  this repository measures either.
//
//  They are skipped at scale zero, which is the default, because the scale is the point
//  and no ordinary green run should pay for it.  Set the scale with MAD_BENCH_ROWS, as a
//  compile-time define or in the environment of the run (the code reads both).
//
//  The two footprint tests are the important ones, and they measure different failures.
//  The retained test ingests N rows and then 2N and asserts the table held neither set --
//  a cache that has to be resident to be read is a leak.  The spike test measures what the
//  row loop is holding before its autorelease pool drains, which is not a leak but is still
//  what gets the process killed on a large report.
//
//  XCTest's performance blocks do not exist on this runner, so the work each measure
//  block performed runs once as a plain test and the result is asserted; nothing is timed.
//

#import "MADTestSupport.h"

#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <MADSqlite3/MADDataTableFast.h>

#if __APPLE__
#import <mach/mach.h>
#else
#import <stdio.h>
#import <unistd.h>
#endif

#import <MADSqlite3/sqlite3.h>

/// The columns the fixture writes and the row loop reads.  Five mixed widths, which is
/// what a report of any size is made of: a key, a short dimension to group on, a
/// measure, and a wide text column for the payload.
static NSArray <NSString *> *MADBenchFieldKeys(void) {
	return @[@"id", @"customer", @"amount", @"region", @"note"];
}

/// The resident size of this process, which is what the OS kills you for.  Apple reads
/// phys_footprint through task_info, because only that counts dirty pages and compressed
/// memory the way the jetsam limit does.  Linux has no equivalent, so the port reads the
/// resident-page count from /proc/self/statm -- the closest analogue the container offers
/// -- and scales it by the page size.
static NSUInteger MADBenchFootprint(void) {
#if __APPLE__
	task_vm_info_data_t info;
	mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
	if (task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&info, &count) != KERN_SUCCESS) {
		return 0;
	}
	return (NSUInteger)info.phys_footprint;
#else
	FILE *statm = fopen("/proc/self/statm", "r");
	if (statm == NULL) {
		return 0;
	}
	unsigned long total = 0;
	unsigned long resident = 0;
	int scanned = fscanf(statm, "%lu %lu", &total, &resident);
	(void)total;
	fclose(statm);
	if (scanned != 2) {
		return 0;
	}
	return (NSUInteger)resident * (NSUInteger)sysconf(_SC_PAGESIZE);
#endif
}

static NSString *MADBenchMB(NSUInteger bytes) {
	return [[NSString alloc] initWithFormat:@"%.1f MB", (double)bytes / (1024.0 * 1024.0)];
}

/// Ingesting 2N rows may not cost materially more than ingesting N.  Generous on purpose:
/// the point is to catch a cache that has to be resident, which at this scale shows up as
/// hundreds of megabytes, not to pin the number to the megabyte.
static const NSUInteger MADBenchMaxScaleGrowthBytes = 48 * 1024 * 1024;

/// And a ceiling on what one row may cost before its pool drains, which catches an
/// order-of-magnitude regression without pretending to know the product's limit.  The
/// measured cost is around 500 bytes per row; this is four times that.
static const NSUInteger MADBenchMaxSpikeBytesPerRow = 2048;

/// Rows to generate, set at build time or in the environment; zero skips the suite.
#ifndef MAD_BENCH_ROWS
#define MAD_BENCH_ROWS 0
#endif

/// The Xcode suite's -rowCount property, resolved once per test: NSNotFound before it
/// has been, zero when the scale was never set.
static NSUInteger gBenchRowCount = NSNotFound;

static NSUInteger benchRowCount(void) {
	if (gBenchRowCount == NSNotFound) {
		NSString *value = [[NSProcessInfo processInfo] environment][@"MAD_BENCH_ROWS"];
		NSInteger parsed = value.length > 0 ? value.integerValue : 0;
		gBenchRowCount = parsed > 0 ? (NSUInteger)parsed : (NSUInteger)MAD_BENCH_ROWS;
	}
	return gBenchRowCount;
}

/// The Xcode suite's -setUp: a fresh temp directory per test, removed by the test that
/// made it.  The scale is reset here too, as the property was.
static NSURL *benchMakeTempDirectory(void) {
	gBenchRowCount = NSNotFound;
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	NSURL *directory = [NSURL fileURLWithPath:path isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:directory
							 withIntermediateDirectories:YES
											  attributes:nil
												   error:nil];
	return directory;
}

static void benchRemoveTempDirectory(NSURL *tempDirectory) {
	[[NSFileManager defaultManager] removeItemAtURL:tempDirectory error:nil];
}

/// Generates the source rows in sqlite itself rather than by looping in Objective-C, so
/// the fixture costs one statement and no resident memory, and the measurement that
/// follows is entirely the code under test.  A recursive CTE is used because the bundled
/// sqlite3 is 3.49.2 (Compressor/library/sqlite3/sqlite3.h).  Rebuilds from scratch, so
/// the scale test can call it twice with two different counts.
static void benchWriteSourceRows(NSURL *sourceURL, NSUInteger rowCount) {
	[[NSFileManager defaultManager] removeItemAtURL:sourceURL error:nil];

	sqlite3 *db = NULL;
	MAD_PASS(sqlite3_open(sourceURL.path.UTF8String, &db) == SQLITE_OK, "the source database opens");
	MAD_PASS(sqlite3_exec(db,
		"CREATE TABLE bench (id INTEGER PRIMARY KEY, customer TEXT, amount REAL,"
		" region TEXT, note TEXT);", NULL, NULL, NULL) == SQLITE_OK, "the fixture table is created");

	NSString *fill = [[NSString alloc] initWithFormat:
		@"WITH RECURSIVE seq(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM seq WHERE i < %lu)"
		" INSERT INTO bench (id, customer, amount, region, note)"
		" SELECT i, 'customer-' || i, i * 1.5, 'region-' || (i %% 7),"
		" 'a note long enough to be a real payload for row ' || i FROM seq;",
		(unsigned long)rowCount];
	MAD_PASS(sqlite3_exec(db, fill.UTF8String, NULL, NULL, NULL) == SQLITE_OK, "the fixture rows generate");
	sqlite3_close(db);
}

/// The app's refresh path, minus the app: a driver row loop handed nothing but a write
/// port.  The whole five-call port is the driver's to send, so nothing is seeded here.
static MADDataTableFast *benchIngestRows(NSURL *sourceURL, NSURL *tempDirectory, NSUInteger tableId, NSError * __autoreleasing *error) {
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:sourceURL];
	MADDatabaseSqlite3 *source = [[MADDatabaseSqlite3 alloc] init];
	source.databaseConnection = connection;
	[source openDatabase];

	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId:tableId
													cacheDirectory:tempDirectory];

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

static MADDataTableFast *benchIngestOrFail(NSURL *sourceURL, NSURL *tempDirectory, NSUInteger tableId) {
	NSError *error = nil;
	MADDataTableFast *table = benchIngestRows(sourceURL, tempDirectory, tableId, &error);
	MAD_PASS(table != nil, "the row loop refused the table: %s", [[error description] UTF8String]);
	return table;
}

/// Ingests inside its own autorelease pool, so the pool's debris is gone by the time this
/// returns and the caller measures only what the table kept.  The table comes back through
/// retainedTable and outlives the pool.  The refusal check runs inside the pool because the
/// NSError handed back is an autoreleased object: after the drain it would dangle.
static void benchIngestRowsRetained(NSURL *sourceURL, NSURL *tempDirectory, NSUInteger tableId,
									MADDataTableFast * __strong *retainedTable) {
	NSError *error = nil;
	@autoreleasepool {
		*(retainedTable) = benchIngestRows(sourceURL, tempDirectory, tableId, &error);
		MAD_PASS(*retainedTable != nil, "the row loop refused the table: %s", [[error description] UTF8String]);
	}
}

#pragma mark - Throughput

static void testIngestThroughput(void) {
	MAD_SKIP(benchRowCount() == 0,
			 @"No benchmark scale; build with MAD_BENCH_ROWS=<n> to run the "
			 @"MADDataTableFast benchmark.  See the header of this file.");
	NSURL *tempDirectory = benchMakeTempDirectory();
	NSURL *sourceURL = [tempDirectory URLByAppendingPathComponent:@"source.sqlite"];
	benchWriteSourceRows(sourceURL, benchRowCount());

	// The Xcode block ran twice and XCTest took the timing; there is no timing here, so
	// the block's work runs once, in its own pool as it did there.
	NSUInteger ingested = 0;
	@autoreleasepool {
		MADDataTableFast *table = benchIngestOrFail(sourceURL, tempDirectory, 1);
		ingested = table.count;
	}

	MAD_PASS(ingested == benchRowCount(), "the whole source table is ingested");
	benchRemoveTempDirectory(tempDirectory);
}

/// The report's bulk read: MADocument walks the query cache with
/// -enumeratorForKeyObjectsSorted (MADocument.m:866), which is this cursor.  It is a
/// single stepping statement, not a per-row re-query.
///
/// A loop of -objectAtRow: would measure something no production caller does, and would
/// be quadratic if it did: that accessor is LIMIT 1 OFFSET n
/// (MADDataTableFast.m:1086), so each call rescans to the row.
static void testSortedEnumeratorThroughput(void) {
	MAD_SKIP(benchRowCount() == 0,
			 @"No benchmark scale; build with MAD_BENCH_ROWS=<n> to run the "
			 @"MADDataTableFast benchmark.  See the header of this file.");
	NSURL *tempDirectory = benchMakeTempDirectory();
	NSURL *sourceURL = [tempDirectory URLByAppendingPathComponent:@"source.sqlite"];
	benchWriteSourceRows(sourceURL, benchRowCount());

	MADDataTableFast *table = benchIngestOrFail(sourceURL, tempDirectory, 2);
	MAD_PASS(table.count == benchRowCount(), "the whole source table is ingested");

	NSUInteger read = 0;
	NSUInteger seen = 0;
	for (NSDictionary *row in [table enumeratorForAllObjectsSorted]) {
		@autoreleasepool {
			if (row != nil) seen++;
		}
	}
	read = seen;

	MAD_PASS(read == benchRowCount(), "the sorted cursor yields every row once");
	benchRemoveTempDirectory(tempDirectory);
}

/// The renderer's random access: each page element asks for one row by its cache id
/// (MADocument.m:874 -> MADDataTableFast.m:941), which is a WHERE ROWID = ? lookup with a
/// one-entry cache in front of it.  Sampled across the whole range so the lookup cannot
/// sit on one page of the index, which is the state a report actually renders in.
static void testRandomAccessThroughput(void) {
	MAD_SKIP(benchRowCount() == 0,
			 @"No benchmark scale; build with MAD_BENCH_ROWS=<n> to run the "
			 @"MADDataTableFast benchmark.  See the header of this file.");
	NSURL *tempDirectory = benchMakeTempDirectory();
	NSURL *sourceURL = [tempDirectory URLByAppendingPathComponent:@"source.sqlite"];
	benchWriteSourceRows(sourceURL, benchRowCount());

	MADDataTableFast *table = benchIngestOrFail(sourceURL, tempDirectory, 5);
	MAD_PASS(table.count == benchRowCount(), "the whole source table is ingested");

	NSUInteger read = 0;
	NSUInteger seen = 0;
	NSUInteger stride = 97;   // coprime with anything; walks the whole rowid range
	for (NSUInteger rowId = 1; rowId <= benchRowCount(); rowId += stride) {
		@autoreleasepool {
			if ([table dataForRow:rowId error:NULL] != nil) seen++;
		}
	}
	read = seen;

	MAD_PASS(read == (benchRowCount() + 96) / 97, "every sampled rowid returns a row");
	benchRemoveTempDirectory(tempDirectory);
}

#pragma mark - Footprint

/// RETAINED: what the tables still hold once each ingest's autorelease pool has drained.
/// A number that grows with the row count here is a leak -- the report cache is supposed to
/// live in its .maddb file, not on the heap.  Both tables are alive for the second
/// measurement, so the first is the baseline the second is measured against.
static void testRetainedFootprintDoesNotScaleWithRowCount(void) {
	MAD_SKIP(benchRowCount() == 0,
			 @"No benchmark scale; build with MAD_BENCH_ROWS=<n> to run the "
			 @"MADDataTableFast benchmark.  See the header of this file.");
	NSURL *tempDirectory = benchMakeTempDirectory();
	NSURL *sourceURL = [tempDirectory URLByAppendingPathComponent:@"source.sqlite"];

	NSUInteger baseline = MADBenchFootprint();

	benchWriteSourceRows(sourceURL, benchRowCount());
	MADDataTableFast *small = nil;
	benchIngestRowsRetained(sourceURL, tempDirectory, 3, &small);
	NSUInteger footprintAtN = MADBenchFootprint();

	benchWriteSourceRows(sourceURL, benchRowCount() * 2);
	MADDataTableFast *large = nil;
	benchIngestRowsRetained(sourceURL, tempDirectory, 4, &large);
	NSUInteger footprintAtTwoN = MADBenchFootprint();

	MAD_PASS(small.count == benchRowCount(), "the first ingest holds N rows");
	MAD_PASS(large.count == benchRowCount() * 2, "the second ingest holds 2N rows");

	NSUInteger growth = footprintAtTwoN > footprintAtN ? footprintAtTwoN - footprintAtN : 0;
	NSLog(@"MADDataTableFast retained: start %@; %lu rows -> %@; %lu rows -> %@ "
		  @"(growth %@ for %lu more rows)",
		  MADBenchMB(baseline),
		  (unsigned long)small.count, MADBenchMB(footprintAtN),
		  (unsigned long)large.count, MADBenchMB(footprintAtTwoN),
		  MADBenchMB(growth), (unsigned long)small.count);

	MAD_PASS(growth < MADBenchMaxScaleGrowthBytes,
			 "Ingesting %lu more rows left %s still resident; the cache is being held "
			 "in memory rather than streamed to its file.",
			 (unsigned long)small.count, MADBenchMB(growth).UTF8String);

	MAD_PASS(small.count + large.count == benchRowCount() * 3, "both tables still hold every row");
	benchRemoveTempDirectory(tempDirectory);
}

/// SPIKE: the footprint at the moment the row loop returns, before its pool drains.
/// -insertRow: allocates a MADDatabaseDataBinding for every value of every row
/// (MADDataTableFast.m:562), and the row loop's pool is whatever the caller established, so
/// this grows with the rows ingested in one pool.  Nothing is leaked -- the retained test
/// above measures that separately -- but the process can still be jetsam-killed for holding
/// it, which is the crash a large report has to avoid.
static void testIngestSpikeStaysBounded(void) {
	MAD_SKIP(benchRowCount() == 0,
			 @"No benchmark scale; build with MAD_BENCH_ROWS=<n> to run the "
			 @"MADDataTableFast benchmark.  See the header of this file.");
	NSURL *tempDirectory = benchMakeTempDirectory();
	NSURL *sourceURL = [tempDirectory URLByAppendingPathComponent:@"source.sqlite"];
	benchWriteSourceRows(sourceURL, benchRowCount());

	NSUInteger before = MADBenchFootprint();
	MADDataTableFast *table = benchIngestOrFail(sourceURL, tempDirectory, 6);
	NSUInteger after = MADBenchFootprint();

	MAD_PASS(table.count == benchRowCount(), "the whole source table is ingested");

	NSUInteger spike = after > before ? after - before : 0;
	NSUInteger bytesPerRow = benchRowCount() > 0 ? spike / benchRowCount() : 0;
	NSLog(@"MADDataTableFast ingest spike: %@ for %lu rows (%lu bytes/row before the pool drains)",
		  MADBenchMB(spike), (unsigned long)benchRowCount(), (unsigned long)bytesPerRow);

	MAD_PASS(bytesPerRow < MADBenchMaxSpikeBytesPerRow,
			 "The row loop is holding %lu bytes per row until its pool drains.",
			 (unsigned long)bytesPerRow);
	benchRemoveTempDirectory(tempDirectory);
}

MAD_TEST_MAIN("MADDataTableFastBenchmarkTests",
	MAD_TEST(testIngestThroughput),
	MAD_TEST(testSortedEnumeratorThroughput),
	MAD_TEST(testRandomAccessThroughput),
	MAD_TEST(testRetainedFootprintDoesNotScaleWithRowCount),
	MAD_TEST(testIngestSpikeStaysBounded));
