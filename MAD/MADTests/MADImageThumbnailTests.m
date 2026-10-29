//
//  MADImageThumbnailTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization tests for MADImageThumbnail, the UIImage subclass the document
//  browser shows for a .mad file.
//
//  Pinned behaviours:
//
//    * +newImageThumbnailWithRenderer: lays the thumbnail out for Letter paper
//      (612 x 792) and squares it, so the result is 792 x 792 whatever the device
//      scale -- the crop takes a point-sized rectangle out of a pixel-sized image,
//      which is why the crop is scale-independent but also why it never covers more
//      than the top-left 612 x 792 pixels.
//    * It asks the renderer for page index 0 -- the report's first page -- so a
//      single-page document has a cover and not a blank canvas.  The recording
//      renderer below asserts the index; the paged renderer proves a one-page
//      document's thumbnail carries the drawing.
//    * +newImageThumbnailWithRect:...: ignores the `size` argument unless zoomEffect
//      is set; the non-zoom crop is the rect itself.
//
//  +newImageThumbnailWithDocument: is implemented but declared nowhere, and would
//  need an open MADocument; it is not covered here.  The two helpers it shares with
//  the renderer path are covered directly.
//

#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <XCTest/XCTest.h>

#import <UIKit/UIKit.h>

#import "MADImageThumbnail.h"
#import "MADPrintPageRenderer.h"
#import "MADPrintPageRendererDataSource.h"

// Both constructors are implemented but declared nowhere public; this test-only
// category is the deliberate bridge.  -newImageMadeSquare: carries its ownership
// attribute through, so ARC balances it the way the implementation does.
@interface MADImageThumbnail (TestConstructors)
+ (instancetype)newImageThumbnailWithRect:(CGRect)rect
									 size:(CGFloat)size
							   zoomEffect:(BOOL)zoomEffect
							 squareEffect:(BOOL)squareEffect
							   cornerSize:(CGFloat)cornerSize
									scale:(CGFloat)scale
					 andPrintPageRenderer:(MADPrintPageRenderer *)printPageRenderer;
+ (instancetype)newImageMadeSquare:(UIImage *)source NS_RETURNS_NOT_RETAINED;
@end

#pragma mark - Test doubles

// Everything MADPrintPageRendererDataSourceProtocol requires.  Every answer stays
// nil: the drawing path checked here returns before it reads any of them.
@interface MADThumbnailTestSource : NSObject <MADPrintPageRendererDataSourceProtocol>

@property (nonatomic, strong) MADDatabase *database;
@property (nonatomic, strong) MADDataTableFast *dataTable;
@property (nonatomic, strong) MADReportFormatter *reportFormatter;

@end

@implementation MADThumbnailTestSource

- (NSArray <MADResult *> *)groupLevelKeys:(int64_t)rowID { return @[]; }
- (NSArray <MADResult *> *)groupKeys:(int64_t)rowID groupNumber:(int64_t)groupNumber { return @[]; }
- (NSArray <NSString *> *)groupLevelKeyNames { return @[]; }
- (NSDictionary <NSString *, MADResult *> *)dataForRow:(NSUInteger)rowID error:(NSError * __autoreleasing *)error { return nil; }
- (NSDictionary *)dataForRowReportFirst { return nil; }
- (NSDictionary *)dataForRowReportLast { return nil; }
- (NSDictionary *)dataForRowPageFirst:(NSUInteger)pageIndex { return nil; }
- (NSDictionary *)dataForRowPageLast:(NSUInteger)pageIndex { return nil; }
- (NSDictionary <NSString *, MADResult *> *)dataForRow:(NSUInteger)rowID column:(NSString *)columnKey error:(NSError * __autoreleasing *)error { return nil; }
- (NSArray <__kindof NSDictionary *> *)dataForGroups:(NSArray *)groupKeys groupID:(int64_t)groupID { return @[]; }
- (__kindof NSObject <NSCopying> *)dataForRows:(NSArray *)rowIDs column:(NSString *)columnKey groups:(NSArray *)groupKeys function:(MTAggregateFunctionType)function groupBy:(MTAggregateGroupByType)groupBy { return nil; }
- (NSUInteger)rowIDFirstOfReport { return 1; }
- (NSUInteger)rowIDLastOfReport { return 1; }
- (NSUInteger)rowIDFirstOfPage:(NSUInteger)page { return 1; }
- (NSUInteger)rowIDLastOfPage:(NSUInteger)page { return 1; }
- (NSArray <NSNumber *> *)rowIDsForPage:(NSUInteger)pageIndex { return @[]; }
- (void)updatePrintingReportFormatter { }

@end

// A renderer that records the page it was asked to draw and renders nothing.  The
// thumbnail only needs a backing image to crop, so leaving the canvas as it began is
// enough to exercise the constructor.
@interface MADThumbnailTestRenderer : MADPrintPageRenderer

@property (nonatomic, assign) BOOL didDrawPage;
@property (nonatomic, assign) NSUInteger lastDrawnPageIndex;
@property (nonatomic, assign) CGRect lastDrawnRect;

@end

@implementation MADThumbnailTestRenderer

- (void)drawPageAtIndex:(NSUInteger)index
				 inRect:(CGRect)pageRect
	withTransparentBackground:(BOOL)transparentBackground {
	self.didDrawPage = YES;
	self.lastDrawnPageIndex = index;
	self.lastDrawnRect = pageRect;
}

@end

// A renderer that draws the way the real one bounds-checks: a valid page fills with
// colour, a page at or past the count draws nothing.
@interface MADThumbnailPagedRenderer : MADPrintPageRenderer

@property (nonatomic, assign) NSUInteger pageCount;

@end

@implementation MADThumbnailPagedRenderer

- (void)drawPageAtIndex:(NSUInteger)index
					 inRect:(CGRect)pageRect
	withTransparentBackground:(BOOL)transparentBackground {
	if (index >= self.pageCount) return;
	[[UIColor blueColor] setFill];
	UIRectFill(pageRect);
}

@end

#pragma mark - Tests

@interface MADImageThumbnailTests : XCTestCase
@end

@implementation MADImageThumbnailTests

- (MADThumbnailTestRenderer *)renderer {
	return [[MADThumbnailTestRenderer alloc] initWithDataSource:[[MADThumbnailTestSource alloc] init]];
}

- (UIImage *)solidImageWithSize:(CGSize)size {
	UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
	[[UIColor blueColor] setFill];
	UIRectFill(CGRectMake(0.0, 0.0, size.width, size.height));
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

// The centre pixel of the image, colour-tested: the squared thumbnail puts the page's
// middle at its middle, so a page that drew reaches the centre and a blank cover does
// not.
- (BOOL)imageIsBlueAtItsCenter:(UIImage *)image {
	CGImageRef cgImage = image.CGImage;
	if (!cgImage) return NO;
	size_t x = CGImageGetWidth(cgImage) / 2, y = CGImageGetHeight(cgImage) / 2;
	CGImageRef onePixel = CGImageCreateWithImageInRect(cgImage, CGRectMake(x, y, 1, 1));
	if (!onePixel) return NO;
	unsigned char bytes[4] = { 0, 0, 0, 0 };
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	CGContextRef ctx = CGBitmapContextCreate(bytes, 1, 1, 8, 4, space, kCGImageAlphaPremultipliedLast);
	CGColorSpaceRelease(space);
	if (!ctx) {
		CGImageRelease(onePixel);
		return NO;
	}
	CGContextDrawImage(ctx, CGRectMake(0.0, 0.0, 1.0, 1.0), onePixel);
	CGContextRelease(ctx);
	CGImageRelease(onePixel);
	return bytes[2] > 200 && bytes[0] < 50;
}

#pragma mark - newImageThumbnailWithRenderer:

- (void)testRendererThumbnailIsASquareLetterPageAndDrawsPageOne {
	MADThumbnailTestRenderer *renderer = [self renderer];

	MADImageThumbnail *thumbnail = [MADImageThumbnail newImageThumbnailWithRenderer:renderer];

	XCTAssertNotNil(thumbnail);
	// Quirk: the factory is declared on MADImageThumbnail (a UIImage subclass) and
	// returns instancetype, but the object it builds is a plain UIImage.
	XCTAssertTrue([thumbnail isKindOfClass:[UIImage class]]);
	// Letter paper (612 x 792) squared on its larger dimension.
	XCTAssertTrue(CGSizeEqualToSize(thumbnail.size, CGSizeMake(792.0, 792.0)));

	// The renderer was asked for the Letter page rect ...
	XCTAssertTrue(renderer.didDrawPage);
	XCTAssertTrue(CGRectEqualToRect(renderer.lastDrawnRect, CGRectMake(0.0, 0.0, 612.0, 792.0)));
	// ... and for page index 0: the report's first page.
	XCTAssertEqual(renderer.lastDrawnPageIndex, (NSUInteger)0);
}

- (void)testAOnePageDocumentsThumbnailIsNotBlank {
	MADThumbnailPagedRenderer *renderer = [[MADThumbnailPagedRenderer alloc] initWithDataSource:[[MADThumbnailTestSource alloc] init]];
	renderer.pageCount = 1;

	MADImageThumbnail *thumbnail = [MADImageThumbnail newImageThumbnailWithRenderer:renderer];

	// The one page the renderer has is the page the thumbnail asked for, so the
	// drawing reaches the cover; asking for index 1 left it blank.
	XCTAssertNotNil(thumbnail);
	XCTAssertTrue([self imageIsBlueAtItsCenter:thumbnail]);
}

- (void)testAMultiPageDocumentsThumbnailShowsTheFirstPage {
	MADThumbnailPagedRenderer *renderer = [[MADThumbnailPagedRenderer alloc] initWithDataSource:[[MADThumbnailTestSource alloc] init]];
	renderer.pageCount = 5;

	MADImageThumbnail *thumbnail = [MADImageThumbnail newImageThumbnailWithRenderer:renderer];

	XCTAssertNotNil(thumbnail);
	XCTAssertTrue([self imageIsBlueAtItsCenter:thumbnail]);
}

- (void)testRendererThumbnailWithARealRendererIsStillAValidImage {
	// The production renderer with a data source whose reportFormatter is nil: the
	// page-index check answers 0 pages, so the draw returns after the white canvas.
	MADThumbnailTestSource *source = [[MADThumbnailTestSource alloc] init];
	MADPrintPageRenderer *renderer = [[MADPrintPageRenderer alloc] initWithDataSource:source];

	MADImageThumbnail *thumbnail = [MADImageThumbnail newImageThumbnailWithRenderer:renderer];

	XCTAssertNotNil(thumbnail);
	XCTAssertTrue(CGSizeEqualToSize(thumbnail.size, CGSizeMake(792.0, 792.0)));
}

#pragma mark - newImageThumbnailWithRect:...:

- (void)testNonZoomCropUsesTheRectAndIgnoresTheSizeArgument {
	MADThumbnailTestRenderer *renderer = [self renderer];
	CGRect rect = CGRectMake(0.0, 0.0, 100.0, 50.0);

	// `size` is huge on purpose: without zoomEffect it must make no difference.
	MADImageThumbnail *thumbnail;
	thumbnail = [MADImageThumbnail newImageThumbnailWithRect:rect
														size:1024.0
												  zoomEffect:NO
												squareEffect:NO
												  cornerSize:0.0
													   scale:1.0
										andPrintPageRenderer:renderer];

	XCTAssertNotNil(thumbnail);
	XCTAssertTrue(CGSizeEqualToSize(thumbnail.size, CGSizeMake(100.0, 50.0)));
}

- (void)testZoomCropDerivesItsWidthFromTheAspectRatio {
	MADThumbnailTestRenderer *renderer = [self renderer];
	CGRect rect = CGRectMake(0.0, 0.0, 100.0, 50.0);

	// zoomRect is (0, 0, size * width / height, size) = (0, 0, 40, 20).
	MADImageThumbnail *thumbnail;
	thumbnail = [MADImageThumbnail newImageThumbnailWithRect:rect
														size:20.0
												  zoomEffect:YES
												squareEffect:NO
												  cornerSize:5.0
													   scale:1.0
										andPrintPageRenderer:renderer];

	XCTAssertNotNil(thumbnail);
	XCTAssertTrue(CGSizeEqualToSize(thumbnail.size, CGSizeMake(40.0, 20.0)));
}

- (void)testScaleMultipliesTheZoomCropSize {
	MADThumbnailTestRenderer *renderer = [self renderer];
	CGRect rect = CGRectMake(0.0, 0.0, 100.0, 50.0);

	// size becomes 40, so the crop is (0, 0, 80, 40).
	MADImageThumbnail *thumbnail;
	thumbnail = [MADImageThumbnail newImageThumbnailWithRect:rect
														size:20.0
												  zoomEffect:YES
												squareEffect:NO
												  cornerSize:5.0
													   scale:2.0
										andPrintPageRenderer:renderer];

	XCTAssertNotNil(thumbnail);
	XCTAssertTrue(CGSizeEqualToSize(thumbnail.size, CGSizeMake(80.0, 40.0)));
}

- (void)testSquareEffectSquaresTheZoomCrop {
	MADThumbnailTestRenderer *renderer = [self renderer];
	CGRect rect = CGRectMake(0.0, 0.0, 100.0, 50.0);

	MADImageThumbnail *thumbnail;
	thumbnail = [MADImageThumbnail newImageThumbnailWithRect:rect
														size:20.0
												  zoomEffect:YES
												squareEffect:YES
												  cornerSize:5.0
													   scale:1.0
										andPrintPageRenderer:renderer];

	XCTAssertNotNil(thumbnail);
	XCTAssertTrue(CGSizeEqualToSize(thumbnail.size, CGSizeMake(40.0, 40.0)));
}

#pragma mark - newImageMadeSquare:

- (void)testImageMadeSquareSquaresTheLargerDimensionForALandscapeImage {
	UIImage *source = [self solidImageWithSize:CGSizeMake(30.0, 10.0)];

	UIImage *square = [MADImageThumbnail newImageMadeSquare:source];

	XCTAssertNotNil(square);
	XCTAssertTrue(CGSizeEqualToSize(square.size, CGSizeMake(30.0, 30.0)));
}

- (void)testImageMadeSquareSquaresTheLargerDimensionForAPortraitImage {
	UIImage *source = [self solidImageWithSize:CGSizeMake(10.0, 30.0)];

	UIImage *square = [MADImageThumbnail newImageMadeSquare:source];

	XCTAssertNotNil(square);
	XCTAssertTrue(CGSizeEqualToSize(square.size, CGSizeMake(30.0, 30.0)));
}

- (void)testImageMadeSquareOfASquareIsUnchanged {
	UIImage *source = [self solidImageWithSize:CGSizeMake(25.0, 25.0)];

	UIImage *square = [MADImageThumbnail newImageMadeSquare:source];

	XCTAssertNotNil(square);
	XCTAssertTrue(CGSizeEqualToSize(square.size, CGSizeMake(25.0, 25.0)));
}

@end
#endif
