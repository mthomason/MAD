//
//  MADPrintPageRendererTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Characterization tests for MADPrintPageRenderer, the UIPrintPageRenderer subclass
//  the app draws pages and thumbnails with.
//
//  The page-drawing loop itself is not covered end to end: a page with content needs
//  a live MADReportFormatter (a layout enumerator, per-section heights, a document
//  model), and none of that can be stood up without a full MADocument.  What is
//  covered is everything around the loop:
//
//    * -numberOfPages forwards to the data source's reportFormatter.
//    * the white canvas, sampled through a 1 x 1 bitmap context.
//    * the out-of-range early return: an index at or past -numberOfPages draws only
//      the canvas.
//    * the section-type colour map, both the class method and the fill helper.
//    * +textRepresentation is cached, and -debugQuickLookObject is that same object.
//
//  One defect is pinned here: -drawPageAtIndex:inRect:withTransparentBackground:
//  ignores its transparentBackground argument -- the white canvas is always drawn.
//  The header's contract (and MADImageThumbnail, which passes YES) expects otherwise.
//

#import <XCTest/XCTest.h>

#import <UIKit/UIKit.h>

#import "MADPrintPageRenderer.h"
#import "MADPrintPageRendererDataSource.h"
#import "MADReportFormatter.h"
#import "MADocumentSectionType.h"
#import "MADStore.h"
#import "RptqStoreContext.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"

// The canvas and colour helpers are implemented but declared nowhere public; this
// test-only category is the deliberate bridge.  -debugQuickLookObject is bridged too.
@interface MADPrintPageRenderer (TestHelpers)
+ (void)drawWhiteCanvas:(CGContextRef)ctx pageRect:(CGRect)pageRect;
+ (UIColor *)backgroundColorForDocumentSectionType:(MADDocumentSectionType)type;
- (void)setBackgroundColorForDocumentSection:(RptqDocumentSection *)documentSection
									  inRect:(CGRect)rect;
- (id)debugQuickLookObject;
@end

typedef struct {
	unsigned char red;
	unsigned char green;
	unsigned char blue;
	unsigned char alpha;
} MADRendererTestPixel;

#pragma mark - Test doubles

// Everything MADPrintPageRendererDataSourceProtocol requires.  The renderer paths
// under test read no answer except reportFormatter.
@interface MADRendererTestSource : NSObject <MADPrintPageRendererDataSourceProtocol>

@property (nonatomic, strong) MADDatabase *database;
@property (nonatomic, strong) MADDataTableFast *dataTable;
@property (nonatomic, strong) MADReportFormatter *reportFormatter;

@end

@implementation MADRendererTestSource

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

// Only -numberOfPages is read by the paths under test; everything else stays as the
// base class leaves it (an uninitialised formatter, which is never asked anything but
// the page count).
@interface MADRendererTestFormatter : MADReportFormatter

@property (nonatomic, assign) NSUInteger testNumberOfPages;

@end

@implementation MADRendererTestFormatter

- (NSUInteger)numberOfPages { return self.testNumberOfPages; }

@end

#pragma mark - Tests

@interface MADPrintPageRendererTests : XCTestCase

@property (nonatomic, strong) RptqStoreContext *context;

@end

@implementation MADPrintPageRendererTests

#pragma mark - Fixtures

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

// Draws into a one-pixel bitmap context and answers the pixel that came out.  A
// one-pixel context removes any question of row order or flipping.
- (MADRendererTestPixel)pixelAfterDrawing:(void (^)(void))draw {
	unsigned char bytes[4] = { 0, 0, 0, 0 };
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	CGContextRef ctx = CGBitmapContextCreate(bytes, 1, 1, 8, 4, space,
											 (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
	CGColorSpaceRelease(space);
	XCTAssertNotEqual(ctx, NULL);
	UIGraphicsPushContext(ctx);
	draw();
	UIGraphicsPopContext();
	CGContextRelease(ctx);

	MADRendererTestPixel pixel = { bytes[0], bytes[1], bytes[2], bytes[3] };
	return pixel;
}

- (void)assertPixelIsWhite:(MADRendererTestPixel)pixel {
	XCTAssertEqual(pixel.red, 255);
	XCTAssertEqual(pixel.green, 255);
	XCTAssertEqual(pixel.blue, 255);
	XCTAssertEqual(pixel.alpha, 255);
}

- (void)assertPixelLooksLikeRed:(MADRendererTestPixel)pixel {
	XCTAssertGreaterThanOrEqual(pixel.red, 250);
	XCTAssertLessThanOrEqual(pixel.green, 2);
	XCTAssertLessThanOrEqual(pixel.blue, 2);
	XCTAssertEqual(pixel.alpha, 255);
}

#pragma mark - Lifecycle

- (void)setUp {
	[super setUp];
	self.context = [self inMemoryContext];
}

#pragma mark - Data source passthrough

- (void)testInitWithDataSourceKeepsTheSource {
	MADRendererTestSource *source = [[MADRendererTestSource alloc] init];

	MADPrintPageRenderer *renderer = [[MADPrintPageRenderer alloc] initWithDataSource:source];

	// The property is internal; the renderer keeps the source it was handed.
	XCTAssertTrue([renderer valueForKey:@"datasource"] == source);
}

- (void)testNumberOfPagesFollowsTheReportFormatter {
	MADRendererTestSource *source = [[MADRendererTestSource alloc] init];
	MADPrintPageRenderer *renderer = [[MADPrintPageRenderer alloc] initWithDataSource:source];

	// No formatter: no pages.
	XCTAssertEqual(renderer.numberOfPages, (NSInteger)0);

	MADRendererTestFormatter *formatter = [[MADRendererTestFormatter alloc] init];
	formatter.testNumberOfPages = 3;
	source.reportFormatter = formatter;

	XCTAssertEqual(renderer.numberOfPages, (NSInteger)3);
}

- (void)testTextRepresentationIsBuiltOnceAndReused {
	MADRendererTestSource *source = [[MADRendererTestSource alloc] init];
	MADPrintPageRenderer *renderer = [[MADPrintPageRenderer alloc] initWithDataSource:source];

	MADReportTextRepresentation *first = renderer.textRepresentation;
	MADReportTextRepresentation *second = renderer.textRepresentation;

	XCTAssertNotNil(first);
	XCTAssertTrue(first == second);
	// debugQuickLookObject answers exactly that object.
	XCTAssertTrue([renderer debugQuickLookObject] == first);
}

#pragma mark - Section background colours

- (void)testBackgroundColorForDocumentSectionTypeMapsEveryType {
	XCTAssertEqualObjects([MADPrintPageRenderer backgroundColorForDocumentSectionType:MADDocumentSectionTypeBody],
						  [UIColor redColor]);
	XCTAssertEqualObjects([MADPrintPageRenderer backgroundColorForDocumentSectionType:MADDocumentSectionTypeGroupFooter],
						  [UIColor purpleColor]);
	XCTAssertEqualObjects([MADPrintPageRenderer backgroundColorForDocumentSectionType:MADDocumentSectionTypeGroupHeader],
						  [UIColor yellowColor]);
	XCTAssertEqualObjects([MADPrintPageRenderer backgroundColorForDocumentSectionType:MADDocumentSectionTypePageFooter],
						  [UIColor grayColor]);
	XCTAssertEqualObjects([MADPrintPageRenderer backgroundColorForDocumentSectionType:MADDocumentSectionTypePageHeader],
						  [UIColor greenColor]);
	XCTAssertEqualObjects([MADPrintPageRenderer backgroundColorForDocumentSectionType:MADDocumentSectionTypeReportFooter],
						  [UIColor brownColor]);
	XCTAssertEqualObjects([MADPrintPageRenderer backgroundColorForDocumentSectionType:MADDocumentSectionTypeReportHeader],
						  [UIColor blueColor]);
	// Unknown, and anything outside the enum, is the magenta catch-all.
	XCTAssertEqualObjects([MADPrintPageRenderer backgroundColorForDocumentSectionType:MADDocumentSectionTypeUnknown],
						  [UIColor magentaColor]);
	XCTAssertEqualObjects([MADPrintPageRenderer backgroundColorForDocumentSectionType:(MADDocumentSectionType)99],
						  [UIColor magentaColor]);
}

- (void)testSetBackgroundColorForDocumentSectionFillsWithTheSectionColour {
	RptqDocumentSection *body;
	body = [RptqDocumentSection newDocumentSectionOfType:MADDocumentSectionTypeBody
								  forManagedObjectContext:self.context];
	MADPrintPageRenderer *renderer = [[MADPrintPageRenderer alloc] initWithDataSource:nil];

	MADRendererTestPixel red = [self pixelAfterDrawing:^ {
		[renderer setBackgroundColorForDocumentSection:body inRect:CGRectMake(0.0, 0.0, 1.0, 1.0)];
	}];
	[self assertPixelLooksLikeRed:red];

	RptqDocumentSection *header;
	header = [RptqDocumentSection newDocumentSectionOfType:MADDocumentSectionTypeReportHeader
									forManagedObjectContext:self.context];
	MADRendererTestPixel blue = [self pixelAfterDrawing:^ {
		[renderer setBackgroundColorForDocumentSection:header inRect:CGRectMake(0.0, 0.0, 1.0, 1.0)];
	}];
	XCTAssertLessThanOrEqual(blue.red, 2);
	XCTAssertLessThanOrEqual(blue.green, 2);
	XCTAssertGreaterThanOrEqual(blue.blue, 250);
	XCTAssertEqual(blue.alpha, 255);
}

#pragma mark - Drawing

- (void)testDrawWhiteCanvasFillsThePageRectWithOpaqueWhite {
	MADRendererTestPixel pixel = [self pixelAfterDrawing:^ {
		[MADPrintPageRenderer drawWhiteCanvas:UIGraphicsGetCurrentContext()
									 pageRect:CGRectMake(0.0, 0.0, 1.0, 1.0)];
	}];

	[self assertPixelIsWhite:pixel];
}

- (void)testDrawPageDrawsTheWhiteCanvasEvenWithTransparentBackground {
	MADRendererTestSource *source = [[MADRendererTestSource alloc] init];
	MADPrintPageRenderer *renderer = [[MADPrintPageRenderer alloc] initWithDataSource:source];

	// Characterization of the defect: the transparentBackground argument is not read,
	// so the canvas is opaque white even though YES was asked for.
	MADRendererTestPixel pixel = [self pixelAfterDrawing:^ {
		[renderer drawPageAtIndex:0
						   inRect:CGRectMake(0.0, 0.0, 1.0, 1.0)
		 withTransparentBackground:YES];
	}];

	[self assertPixelIsWhite:pixel];
}

- (void)testDrawPagePastTheEndDrawsOnlyTheCanvas {
	MADRendererTestSource *source = [[MADRendererTestSource alloc] init];
	MADRendererTestFormatter *formatter = [[MADRendererTestFormatter alloc] init];
	formatter.testNumberOfPages = 3;
	source.reportFormatter = formatter;
	MADPrintPageRenderer *renderer = [[MADPrintPageRenderer alloc] initWithDataSource:source];

	// Page 5 of a 3-page report: the page-bound check returns before any section work,
	// leaving the white canvas.
	MADRendererTestPixel pixel = [self pixelAfterDrawing:^ {
		[renderer drawPageAtIndex:5
						   inRect:CGRectMake(0.0, 0.0, 1.0, 1.0)
		 withTransparentBackground:NO];
	}];

	[self assertPixelIsWhite:pixel];
}

@end
