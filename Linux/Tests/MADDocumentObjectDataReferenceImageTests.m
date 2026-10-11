//
//  MADDocumentObjectDataReferenceImageTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADDocumentObjectDataReferenceImageTests.m:
//  MADDocumentObjectDataReferenceImage, the handle over an image element -- it
//  simply hands back the element's `image`.
//
//  The file also pins the image's journey through the portable store, and that
//  journey is lossy: the element declares `UIImage *image`
//  (RptqDocumentElementImage.h) and the designer assigns a UIImage, but the
//  store's Blob column only binds NSData (MADStore.m, MADStoreBindColumn) and
//  writes NULL for anything else, while a read hands back NSData.  So the image
//  survives in memory and is gone after save/load.  The last test pins today's
//  behaviour and will need updating when the defect is fixed.
//
//  UIImage does not exist off Apple (no UIGraphics either), so the fixture's
//  one-pixel UIImage is a plain-object stand-in.  Its only relevant property is
//  that it is not NSData, which is exactly what the Blob column asks, so the
//  stand-in makes the same save/load journey the UIImage does; the assertions
//  are the Xcode ones unchanged.
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

static void testImageDoesNotSurviveSaveAndReopen(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"persistence.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");
	MADTestImageStandIn *image = [[MADTestImageStandIn alloc] init];
	RptqDocumentElementImage *element = (RptqDocumentElementImage *)[context insertObjectForEntity:@"RptqDocumentElementImage" identifier:0];
	element.type = MADPrintPageElementTypeImage;
	element.image = (UIImage *)image;
	int64_t elementIdentifier = element.identifier;

	NSError *error = nil;
	MAD_PASS([context save:&error], "the save succeeds");

	RptqStoreContext *reread = openContextAtPath(directory, @"persistence.sqlite");
	MAD_PASS([reread loadAllWithError:&error], "the fresh context loads");
	RptqDocumentElementImage *readElement = (RptqDocumentElementImage *)[reread objectForEntity:@"RptqDocumentElementImage"
																					  identifier:elementIdentifier];

	MAD_PASS(readElement != nil, "the element is read back");
	// The Blob column was written NULL because a UIImage is not NSData.  This is the
	// current, lossy behaviour: an image element's picture is gone after save/load.
	MAD_PASS(readElement.image == nil, "the image does not survive the save and reopen");

	[[NSFileManager defaultManager] removeItemAtURL:directory error:nil];
}

MAD_TEST_MAIN("MADDocumentObjectDataReferenceImageTests",
	MAD_TEST(testFactoryReturnsImageReference),
	MAD_TEST(testImageIsNilWhenTheElementHasNone),
	MAD_TEST(testImageIsTheElementImageWhileInMemory),
	MAD_TEST(testImageDoesNotSurviveSaveAndReopen));
