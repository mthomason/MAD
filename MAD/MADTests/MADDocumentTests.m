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
#import <MAD/MADConstants.h>
#import "MADArchiveManager.h"

#import <string.h>

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

#pragma mark - Document format

// The v1 header (MAD_FORMAT.md section 7.1) is written ahead of the bzip2 stream by
// MADArchiveManager -archive: and stripped again by -unarchive.  A directory with one
// file should round-trip, and the archive should begin with the magic and version.
- (void)testArchiveRoundTripWritesAndStripsTheV1Header {

	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *temp = [NSURL fileURLWithPath: NSTemporaryDirectory() isDirectory: YES];

	NSURL *source = [temp URLByAppendingPathComponent: [NSUUID UUID].UUIDString isDirectory: YES];
	NSURL *destination = [temp URLByAppendingPathComponent: [NSUUID UUID].UUIDString isDirectory: YES];
	NSURL *archive = [temp URLByAppendingPathComponent: [[NSUUID UUID].UUIDString stringByAppendingPathExtension: @"mad"]];
	[fileManager createDirectoryAtURL: source withIntermediateDirectories: YES attributes: nil error: NULL];

	NSString *body = @"round-trip";
	[body writeToURL: [source URLByAppendingPathComponent: @"member.txt"]
		  atomically: YES encoding: NSUTF8StringEncoding error: NULL];

	MADArchiveManager *writer = [[MADArchiveManager alloc] initWithFileWrapperURL: source archiveURL: archive];
	XCTAssertTrue([writer archive: YES], @"archive should succeed");

	// The archive must open with the 8 magic bytes, then the two little-endian version
	// words, then four flags bytes (all zero: the store is not checkpointed).
	NSData *head = [NSData dataWithContentsOfURL: archive options: NSDataReadingMappedIfSafe error: NULL];
	XCTAssertGreaterThanOrEqual(head.length, (NSUInteger)MADFileFormatHeaderLength, @"the header is present");
	if (head.length >= MADFileFormatHeaderLength) {
		const uint8_t *bytes = head.bytes;
		XCTAssertEqual(memcmp(bytes, MADFileFormatMagic, 8), 0, @"the magic bytes match");
		uint16_t major = (uint16_t)(bytes[8] | (bytes[9] << 8));
		uint16_t minor = (uint16_t)(bytes[10] | (bytes[11] << 8));
		XCTAssertEqual(major, MADFileFormatMajorVersion, @"the major version is 1");
		XCTAssertEqual(minor, MADFileFormatMinorVersion, @"the minor version is 0");
		XCTAssertTrue(bytes[12] == 0 && bytes[13] == 0 && bytes[14] == 0 && bytes[15] == 0,
					  @"the flags are zero (not checkpointed)");
	}

	// Unarchive into a fresh directory; the member must come back verbatim.
	MADArchiveManager *reader = [[MADArchiveManager alloc] initWithFileWrapperURL: destination archiveURL: archive];
	XCTAssertTrue([reader unarchive], @"unarchive should succeed");

	NSString *extracted = [NSString stringWithContentsOfURL: [destination URLByAppendingPathComponent: @"member.txt"]
												  encoding: NSUTF8StringEncoding error: NULL];
	XCTAssertEqualObjects(extracted, body, @"the member round-trips");

	[fileManager removeItemAtURL: source error: NULL];
	[fileManager removeItemAtURL: destination error: NULL];
	[fileManager removeItemAtURL: archive error: NULL];
}

// The header's flag bit 0 records whether the store was checkpointed before archiving,
// so a reader knows whether to expect a WAL.  The writer sets it from its
// `checkpointed` property.
- (void)testArchiveHeaderRecordsTheCheckpointFlag {

	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *temp = [NSURL fileURLWithPath: NSTemporaryDirectory() isDirectory: YES];
	NSURL *source = [temp URLByAppendingPathComponent: [NSUUID UUID].UUIDString isDirectory: YES];
	NSURL *archive = [temp URLByAppendingPathComponent: [[NSUUID UUID].UUIDString stringByAppendingPathExtension: @"mad"]];
	[fileManager createDirectoryAtURL: source withIntermediateDirectories: YES attributes: nil error: NULL];
	[@"x" writeToURL: [source URLByAppendingPathComponent: @"member.txt"]
		 atomically: YES encoding: NSUTF8StringEncoding error: NULL];

	MADArchiveManager *writer = [[MADArchiveManager alloc] initWithFileWrapperURL: source archiveURL: archive];
	writer.checkpointed = YES;
	XCTAssertTrue([writer archive: YES]);

	NSData *head = [NSData dataWithContentsOfURL: archive options: NSDataReadingMappedIfSafe error: NULL];
	const uint8_t *bytes = head.bytes;
	XCTAssertEqual(bytes[12] & 0x01, 0x01, @"bit 0 records that the store was checkpointed");
	XCTAssertTrue(bytes[13] == 0 && bytes[14] == 0 && bytes[15] == 0, @"the other flag bits are clear");

	[fileManager removeItemAtURL: source error: NULL];
	[fileManager removeItemAtURL: archive error: NULL];
}

@end
