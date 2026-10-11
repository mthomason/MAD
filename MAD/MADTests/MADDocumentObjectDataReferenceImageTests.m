//
//  MADDocumentObjectDataReferenceImageTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Characterization coverage for MADDocumentObjectDataReferenceImage: the handle over an
//  image element.  It simply hands back the element's `image`.
//
//  This file also pins the image's journey through the portable store, and that journey
//  is lossy: the element declares `UIImage *image` (RptqDocumentElementImage.h) and the
//  designer assigns a UIImage (RptqDocument+Extras.m, addDocumentObject:...), but the
//  store's Blob column only binds NSData (MADStore.m, MADStoreBindColumn) and writes NULL
//  for anything else, while a read hands back NSData.  So the image survives in memory
//  and is gone after save/load.  Reported in the test report, not fixed; the last test
//  below pins today's behaviour and will need updating when the defect is fixed.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIGraphics.h>
#import <UIKit/UIColor.h>

#import "MADDocumentObjectDataReference.h"
#import "MADStore.h"
#import "RptqStoreContext.h"
#import "RptqDocumentElementImage.h"
#import "RptqDocumentElement+Extras.h"

@interface MADDocumentObjectDataReferenceImageTests : XCTestCase
@property (nonatomic, strong) NSURL *directory;
@end

@implementation MADDocumentObjectDataReferenceImageTests

- (void)setUp {
	[super setUp];
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory
							 withIntermediateDirectories:YES
											  attributes:nil
												   error:NULL];
	self.directory = [NSURL fileURLWithPath:directory isDirectory:YES];
}

- (void)tearDown {
	[[NSFileManager defaultManager] removeItemAtURL:self.directory error:NULL];
	[super tearDown];
}

#pragma mark - Fixture

- (RptqStoreContext *)openContextAtPath:(NSString *)name {
	NSURL *url = [self.directory URLByAppendingPathComponent:name];
	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	XCTAssertTrue([store openWithError:&error], @"open failed: %@", error);
	return [RptqStoreContext contextWithStore:store];
}

- (UIImage *)onePixelImage {
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), NO, 1);
	[[UIColor redColor] setFill];
	UIRectFill(CGRectMake(0, 0, 1, 1));
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

- (MADDocumentObjectDataReferenceImage *)referenceForElement:(RptqDocumentElementImage *)element {
	return (MADDocumentObjectDataReferenceImage *)[MADDocumentObjectDataReference newDocumentObjectDataReference:nil
																										 delegate:nil
																											 page:1
																											 item:element
																										   itemID:3];
}

#pragma mark - Tests

- (void)testFactoryReturnsImageReference {
	RptqStoreContext *context = [self openContextAtPath:@"factory.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);
	RptqDocumentElementImage *element = (RptqDocumentElementImage *)[context insertObjectForEntity:@"RptqDocumentElementImage" identifier:0];
	element.type = MADPrintPageElementTypeImage;

	MADDocumentObjectDataReferenceImage *reference = [self referenceForElement:element];

	XCTAssertEqualObjects(NSStringFromClass([reference class]), @"MADDocumentObjectDataReferenceImage");
	XCTAssertEqual(reference.type, MADPrintPageElementTypeImage);
}

- (void)testImageIsNilWhenTheElementHasNone {
	RptqStoreContext *context = [self openContextAtPath:@"unset.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);
	RptqDocumentElementImage *element = (RptqDocumentElementImage *)[context insertObjectForEntity:@"RptqDocumentElementImage" identifier:0];
	element.type = MADPrintPageElementTypeImage;

	MADDocumentObjectDataReferenceImage *reference = [self referenceForElement:element];

	XCTAssertNil(reference.image);
}

- (void)testImageIsTheElementImageWhileInMemory {
	RptqStoreContext *context = [self openContextAtPath:@"memory.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);
	UIImage *image = [self onePixelImage];
	RptqDocumentElementImage *element = (RptqDocumentElementImage *)[context insertObjectForEntity:@"RptqDocumentElementImage" identifier:0];
	element.type = MADPrintPageElementTypeImage;
	element.image = image;

	MADDocumentObjectDataReferenceImage *reference = [self referenceForElement:element];

	XCTAssertEqualObjects(reference.image, image);
}

- (void)testImageDoesNotSurviveSaveAndReopen {
	RptqStoreContext *context = [self openContextAtPath:@"persistence.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);
	UIImage *image = [self onePixelImage];
	RptqDocumentElementImage *element = (RptqDocumentElementImage *)[context insertObjectForEntity:@"RptqDocumentElementImage" identifier:0];
	element.type = MADPrintPageElementTypeImage;
	element.image = image;
	int64_t elementIdentifier = element.identifier;

	NSError *error = nil;
	XCTAssertTrue([context save:&error], @"save failed: %@", error);

	RptqStoreContext *reread = [self openContextAtPath:@"persistence.sqlite"];
	XCTAssertTrue([reread loadAllWithError:&error], @"load failed: %@", error);
	RptqDocumentElementImage *readElement = (RptqDocumentElementImage *)[reread objectForEntity:@"RptqDocumentElementImage"
																					  identifier:elementIdentifier];

	XCTAssertNotNil(readElement);
	// The Blob column was written NULL because a UIImage is not NSData.  This is the
	// current, lossy behaviour: an image element's picture is gone after save/load.
	XCTAssertNil(readElement.image);
}

@end
