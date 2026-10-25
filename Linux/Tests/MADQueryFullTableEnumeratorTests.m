//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADQueryFullTableEnumeratorTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADQueryFullTableEnumeratorTests.m:
//  characterization coverage for MADQueryFullTableEnumerator.  The class
//  subclasses NSEnumerator but overrides no nextObject (or any other enumeration
//  point), so all it really holds is the document's identifier and store context,
//  captured at init.  The last test pins that the class still uses NSEnumerator's
//  implementation, which is the standing defect.  The Xcode suite's in-memory
//  Core Data context is a real SQLite store under a per-test temp directory here.
//

#import "MADTestSupport.h"

#import <MAD/MADQueryFullTableEnumerator.h>
#import <MAD/MADStore.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>

// -managedObjectContext and -documentObjectIdentifier are implemented but declared only
// in the class extension; this test-only category is the deliberate bridge.
@interface MADQueryFullTableEnumerator (TestSurface)
- (RptqStoreContext *)managedObjectContext;
- (int64_t)documentObjectIdentifier;
@end

#pragma mark - Fixture

static RptqStoreContext *inMemoryContext(void) {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"test.sqlite"]];
	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	MAD_PASS([store openWithError:&error], "the store opens");
	RptqStoreContext *context = [RptqStoreContext contextWithStore:store];
	MAD_PASS([context loadAllWithError:&error], "the context loads");
	return context;
}

#pragma mark - Tests

static void testInitCapturesTheDocumentIdentifierAndContext(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];

	MADQueryFullTableEnumerator *enumerator = [[MADQueryFullTableEnumerator alloc] initWithDocument:document];

	MAD_PASS([enumerator documentObjectIdentifier] == document.identifier, "the document identifier is captured");
	MAD_PASS([enumerator managedObjectContext] == context, "the store context is captured");

	[enumerator release];
}

static void testInitWithNilDocumentStoresNothing(void) {
	MADQueryFullTableEnumerator *enumerator = [[MADQueryFullTableEnumerator alloc] initWithDocument:nil];

	MAD_PASS([enumerator documentObjectIdentifier] == (int64_t)0, "a nil document gives identifier 0");
	MAD_PASS([enumerator managedObjectContext] == nil, "a nil document gives no context");

	[enumerator release];
}

static void testNextObjectIsStillNSEnumeratorsAbstractImplementation(void) {
	// NSEnumerator's -nextObject raises; this class never replaces it.  Comparing the
	// IMPs pins that without invoking the raising method.
	IMP inherited = [NSEnumerator instanceMethodForSelector:@selector(nextObject)];
	IMP actual = [MADQueryFullTableEnumerator instanceMethodForSelector:@selector(nextObject)];

	MAD_PASS(actual == inherited, "nextObject is still NSEnumerator's implementation");
}

MAD_TEST_MAIN("MADQueryFullTableEnumeratorTests",
	MAD_TEST(testInitCapturesTheDocumentIdentifierAndContext),
	MAD_TEST(testInitWithNilDocumentStoresNothing),
	MAD_TEST(testNextObjectIsStillNSEnumeratorsAbstractImplementation));
