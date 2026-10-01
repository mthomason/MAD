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

@interface MADDocumentTests : XCTestCase
@end

@implementation MADDocumentTests

#pragma mark - Helpers

// The model is loaded from the test bundle the way MADCoreDataModelTests does it:
// MADMock's own helper looks for Reports.momd in the framework bundle, where it is
// not compiled.
- (RptqDocument *)newDocumentModelOfType:(MTPaperType)paperType {

	NSURL *momdURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"MAD"
															 withExtension:@"momd"];
	XCTAssertNotNil(momdURL, @"MAD.momd was not compiled into the test bundle.");

	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:momdURL];
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	[coordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL];

	NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	context.persistentStoreCoordinator = coordinator;

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
	[document setValue: [self newDocumentModelOfType: MTPaperTypeLetter]
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

@end
