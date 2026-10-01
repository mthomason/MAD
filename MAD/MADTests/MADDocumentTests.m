//
//  MADDocumentTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for the accessors MADocument builds lazily.  A MADocument is a
//  UIManagedDocument, so these exercise only the state that does not need a
//  database connection or a store on disk.
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>

#import <MAD/MADocument.h>
#import <MAD/MTPaper.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqDocumentElement+Extras.h>

@interface MADDocumentTests : XCTestCase
@end

@implementation MADDocumentTests

#pragma mark - Helpers

// The model is loaded from the test bundle the way MADCoreDataModelTests does it:
// MADMock's own helper looks for Reports.momd in the framework bundle, where it is
// not compiled.
- (NSManagedObjectContext *)newTestContext {

	NSURL *momdURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"MAD"
															 withExtension:@"momd"];
	XCTAssertNotNil(momdURL, @"MAD.momd was not compiled into the test bundle.");

	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:momdURL];
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	[coordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL];

	NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	context.persistentStoreCoordinator = coordinator;
	return context;
}

// The caller keeps the context alive.  A managed object does not retain the context
// it is inserted into, so one built and dropped inside this helper leaves the
// document with no context at all.
- (RptqDocument *)newDocumentModelOfType:(MTPaperType)paperType
							   inContext:(NSManagedObjectContext *)context {

	NSEntityDescription *entity = [NSEntityDescription entityForName:@"RptqDocument"
											 inManagedObjectContext:context];
	RptqDocument *document = (RptqDocument *)[[NSManagedObject alloc] initWithEntity:entity
													 insertIntoManagedObjectContext:context];
	document.papersize = paperType;
	return document;
}

#pragma mark - -paperSize

// -paperSize used to read the _paper ivar, which stays nil until the lazy -paper
// accessor builds it from activeDocumentModel.paperType.  Whoever asked first
// therefore got {0, 0}; a zero layout size makes PrintableHeightForPage
// negative, so the formatter starts a new page on every row -- 3503 rows
// produced 11602 pages for the CLI, the only caller that asked before something
// else had touched -paper.  See BUGS.md.
- (void)testPaperSizeBuildsThePaperItself {

	NSURL *url = [NSURL fileURLWithPath:
				  [NSTemporaryDirectory() stringByAppendingPathComponent: @"MADDocumentTests.mad"]];
	MADocument *document = [[MADocument alloc] initWithFileURL: url];

	// -activeDocumentModel is readonly from outside the class, and its getter reads
	// the ivar this accessor had wrongly consulted, so the model goes in by KVC.
	NSManagedObjectContext *context = [self newTestContext];
	[document setValue: [self newDocumentModelOfType: MTPaperTypeLetter
										   inContext: context]
				forKey: @"activeDocumentModel"];

	CGSize paperSize = document.paperSize;
	CGSize expected = document.paper.paperSize;
	CGSize letter = [MTPaper sizeLetter];

	XCTAssertFalse(CGSizeEqualToSize(paperSize, CGSizeZero),
				   @"-paperSize answered {0, 0}; it did not build the paper");
	XCTAssertTrue(CGSizeEqualToSize(paperSize, expected),
				  @"-paperSize disagrees with -paper");
	XCTAssertTrue(CGSizeEqualToSize(paperSize, letter),
				  @"-paperSize is not the letter paper the model asks for");
	XCTAssertEqual(document.paper.paperType, MTPaperTypeLetter);
}

#pragma mark - RptqDocumentElement -formattedString:forValue:

// A NULL read from a source database reaches the formatter as NSNull, which is not
// nil.  It used to fall through to the branches below, whose text paths write NSNull
// as "<null>" -- so that is what a NULL printed as -- and whose date branches read it
// as the interval 0, so a NULL date printed as the epoch.  The four callers tried to
// catch the text case by comparing against MTNullIdentifier, which is "(null)" with
// parentheses: a different string, so the guard never fired.
- (void)testFormattedStringRendersNullAsEmpty {

	NSManagedObjectContext *context = [self newTestContext];
	RptqDocumentElement *element =
		[NSEntityDescription insertNewObjectForEntityForName: @"RptqDocumentElement"
									  inManagedObjectContext: context];

	XCTAssertEqualObjects([element formattedString: MADDataTypeString forValue: [NSNull null]], @"");
	XCTAssertEqualObjects([element formattedString: MADDataTypeInteger forValue: [NSNull null]], @"");
	XCTAssertEqualObjects([element formattedString: MADDataTypeDate forValue: [NSNull null]], @"");
	XCTAssertEqualObjects([element formattedString: MADDataTypeDateTime forValue: [NSNull null]], @"");

	// nil was already empty, and stays that way.
	XCTAssertEqualObjects([element formattedString: MADDataTypeString forValue: nil], @"");

	// A value that is there still formats.
	XCTAssertEqualObjects([element formattedString: MADDataTypeString forValue: @"Group A"], @"Group A");
}

@end
