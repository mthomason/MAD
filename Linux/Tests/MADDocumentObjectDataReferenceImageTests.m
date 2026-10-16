//
//  MADDocumentObjectDataReferenceImageTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADDocumentObjectDataReferenceImageTests.m:
//  MADDocumentObjectDataReferenceImage, the handle over an image element -- it
//  simply hands back the element's `image`.
//
//  The file also pins the image's journey through the portable store.  The
//  element declares `UIImage *image` (RptqDocumentElementImage.h) and the
//  store's Blob column holds image bytes (MADStore.m's binder and reader; the
//  legacy converter writes PNG).  The UIImage half of the transform is Apple
//  only -- RptqDocumentElementImage (Extras) codes and decodes it there,
//  because UIImage is UIKit's -- so what this port pins is the wire format:
//  image bytes stored under the attribute survive a save and reopen.
//
//  UIImage does not exist off Apple (no UIGraphics either), so the fixture's
//  one-pixel UIImage is a plain-object stand-in and the persistence test
//  carries the bytes themselves; the assertions are the Xcode ones where the
//  two platforms agree.
//

#import "MADTestSupport.h"

#import <MAD/MADDocumentObjectDataReference.h>
#import <MAD/MADStore.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDocumentElementImage.h>
#import <MAD/RptqDocumentElement+Extras.h>

// Stands in for the Xcode fixture's one-pixel UIImage (see the header comment).
@interface MADTestImageStandIn : NSObject
@end

@implementation MADTestImageStandIn
@end

#pragma mark - Fixture

static NSURL *makeTempDirectory(void) {
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	NSURL *directory = [NSURL fileURLWithPath:path isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:directory
							 withIntermediateDirectories:YES
											  attributes:nil
												   error:nil];
	return directory;
}

static RptqStoreContext *openContextAtPath(NSURL *directory, NSString *name) {
	NSURL *url = [directory URLByAppendingPathComponent:name];
	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	MAD_PASS([store openWithError:&error], "the store opens");
	return [RptqStoreContext contextWithStore:store];
}

static MADDocumentObjectDataReferenceImage *referenceForElement(RptqDocumentElementImage *element) {
	return (MADDocumentObjectDataReferenceImage *)[MADDocumentObjectDataReference newDocumentObjectDataReference:nil
																										 delegate:nil
																											 page:1
																											 item:element
																										   itemID:3];
}

#pragma mark - Tests

static void testFactoryReturnsImageReference(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"factory.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");
	RptqDocumentElementImage *element = (RptqDocumentElementImage *)[context insertObjectForEntity:@"RptqDocumentElementImage" identifier:0];
	element.type = MADPrintPageElementTypeImage;

	MADDocumentObjectDataReferenceImage *reference = referenceForElement(element);

	MAD_PASS_EQUAL(NSStringFromClass([reference class]), @"MADDocumentObjectDataReferenceImage",
				   "the factory returns the image reference");
	MAD_PASS(reference.type == MADPrintPageElementTypeImage, "the reference reads the element's type");

	[[NSFileManager defaultManager] removeItemAtURL:directory error:nil];
}

static void testImageIsNilWhenTheElementHasNone(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"unset.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");
	RptqDocumentElementImage *element = (RptqDocumentElementImage *)[context insertObjectForEntity:@"RptqDocumentElementImage" identifier:0];
	element.type = MADPrintPageElementTypeImage;

	MADDocumentObjectDataReferenceImage *reference = referenceForElement(element);

	MAD_PASS(reference.image == nil, "an element without an image reads nil");

	[[NSFileManager defaultManager] removeItemAtURL:directory error:nil];
}

static void testImageIsTheElementImageWhileInMemory(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"memory.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");
	MADTestImageStandIn *image = [[MADTestImageStandIn alloc] init];
	RptqDocumentElementImage *element = (RptqDocumentElementImage *)[context insertObjectForEntity:@"RptqDocumentElementImage" identifier:0];
	element.type = MADPrintPageElementTypeImage;
	element.image = (UIImage *)image;

	MADDocumentObjectDataReferenceImage *reference = referenceForElement(element);

	MAD_PASS_EQUAL(reference.image, image, "the reference hands back the element's image");

	[[NSFileManager defaultManager] removeItemAtURL:directory error:nil];
}

static void testImageDataSurvivesSaveAndReopen(void) {
	// The wire format is the image bytes; off Apple there is no UIImage to transform,
	// so the bytes themselves are what the element carries and what must come back.
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"persistence.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");
	NSData *data = [@"PNG-ish bytes" dataUsingEncoding:NSUTF8StringEncoding];
	RptqDocumentElementImage *element = (RptqDocumentElementImage *)[context insertObjectForEntity:@"RptqDocumentElementImage" identifier:0];
	element.type = MADPrintPageElementTypeImage;
	element.image = (UIImage *)data;
	int64_t elementIdentifier = element.identifier;

	NSError *error = nil;
	MAD_PASS([context save:&error], "the save succeeds");

	RptqStoreContext *reread = openContextAtPath(directory, @"persistence.sqlite");
	MAD_PASS([reread loadAllWithError:&error], "the fresh context loads");
	RptqDocumentElementImage *readElement = (RptqDocumentElementImage *)[reread objectForEntity:@"RptqDocumentElementImage"
																					  identifier:elementIdentifier];

	MAD_PASS(readElement != nil, "the element is read back");
	MAD_PASS_EQUAL(readElement.image, data, "the image bytes survive the save and reopen");

	[[NSFileManager defaultManager] removeItemAtURL:directory error:nil];
}

MAD_TEST_MAIN("MADDocumentObjectDataReferenceImageTests",
	MAD_TEST(testFactoryReturnsImageReference),
	MAD_TEST(testImageIsNilWhenTheElementHasNone),
	MAD_TEST(testImageIsTheElementImageWhileInMemory),
	MAD_TEST(testImageDataSurvivesSaveAndReopen));
