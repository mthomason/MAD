//
//  MADQueryFullTableEnumeratorTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization coverage for MADQueryFullTableEnumerator.  The class subclasses
//  NSEnumerator but overrides no nextObject (or any other enumeration point), so all it
//  really holds is the document's identifier and store context, captured at init.  It is
//  exercised through those, not by enumerating: the inherited nextObject raises
//  NSInvalidArgumentException, so no test calls it.  The last test pins that the class
//  still uses NSEnumerator's implementation, which is the standing defect.
//
//  This class looks like the durable half of an abandoned table enumerator; see the
//  report.
//

#import <XCTest/XCTest.h>

#import "MADQueryFullTableEnumerator.h"
#import "MADStore.h"
#import "RptqStoreContext.h"
#import "RptqDocument.h"
#import "RptqDocument+Extras.h"

// -managedObjectContext and -documentObjectIdentifier are implemented but declared only
// in the class extension; this test-only category is the deliberate bridge.
@interface MADQueryFullTableEnumerator (TestSurface)
- (RptqStoreContext *)managedObjectContext;
- (int64_t)documentObjectIdentifier;
@end

@interface MADQueryFullTableEnumeratorTests : XCTestCase
@end

@implementation MADQueryFullTableEnumeratorTests

#pragma mark - Fixture

- (RptqStoreContext *)inMemoryContext {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"test.sqlite"]];
	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	XCTAssertTrue([store openWithError:&error], @"open failed: %@", error);
	RptqStoreContext *context = [RptqStoreContext contextWithStore:store];
	XCTAssertTrue([context loadAllWithError:&error], @"load failed: %@", error);
	return context;
}

#pragma mark - Tests

- (void)testInitCapturesTheDocumentIdentifierAndContext {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];

	MADQueryFullTableEnumerator *enumerator = [[MADQueryFullTableEnumerator alloc] initWithDocument:document];

	XCTAssertEqual([enumerator documentObjectIdentifier], document.identifier);
	XCTAssertEqual([enumerator managedObjectContext], context);
}

- (void)testInitWithNilDocumentStoresNothing {
	MADQueryFullTableEnumerator *enumerator = [[MADQueryFullTableEnumerator alloc] initWithDocument:nil];

	XCTAssertEqual([enumerator documentObjectIdentifier], (int64_t)0);
	XCTAssertNil([enumerator managedObjectContext]);
}

- (void)testNextObjectIsStillNSEnumeratorsAbstractImplementation {
	// NSEnumerator's -nextObject raises; this class never replaces it.  Comparing the
	// IMPs pins that without invoking the raising method.
	IMP inherited = [NSEnumerator instanceMethodForSelector:@selector(nextObject)];
	IMP actual = [MADQueryFullTableEnumerator instanceMethodForSelector:@selector(nextObject)];

	XCTAssertTrue(actual == inherited);
}

@end
