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
#import <MAD/MADStore.h>
#import <MAD/MADStoreGraph.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/MTPaper.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqDocumentElement+Extras.h>
#import <MAD/RptqTextStyle.h>
#import <MAD/MADDesignerLayout.h>
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
- (RptqStoreContext *)newTestContext {
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

// The caller keeps the context alive.  A store-backed object holds its context
// weakly, so one built and dropped inside this helper leaves the document with no
// context at all.
- (RptqDocument *)newDocumentModelOfType:(MTPaperType)paperType
							   inContext:(RptqStoreContext *)context {
	RptqDocument *document = [context insertObjectForEntity:@"RptqDocument" identifier:0];
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
	RptqStoreContext *context = [self newTestContext];
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

	RptqStoreContext *context = [self newTestContext];
	RptqDocumentElement *element =
		[context insertObjectForEntity:@"RptqDocumentElement" identifier:0];

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

#pragma mark - The document path: convert on open, save, reopen

- (NSURL *)newTestDirectory {
	NSURL *directory = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
						URLByAppendingPathComponent:NSUUID.UUID.UUIDString isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	return directory;
}

// A real user's document must convert on open and survive a save/reopen with nothing
// lost: open the shipping London sample through MADDocument's own readFromURL:, save
// it through writeContents: (write the portable store, archive a new .mad), reopen
// that saved .mad, and compare the completed graphs.
- (void)testLegacyLondonConvertsSavesAndReopensUnchanged {
	NSURL *directory = [self newTestDirectory];
	NSURL *sampleURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"London" withExtension:@"mad"];
	XCTAssertNotNil(sampleURL, @"London.mad was not copied into the test bundle.");
	NSURL *documentURL = [directory URLByAppendingPathComponent:@"London.mad"];

	NSError *error = nil;
	MADocument *document = [[MADocument alloc] initWithFileURL:documentURL];
	XCTAssertTrue([document readFromURL:sampleURL error:&error],
				  @"opening the legacy document failed: %@", error);

	MADStoreGraph *converted = [[document.storeContext.store allObjectsWithError:&error] graphByCompletingInverses];
	XCTAssertNotNil(converted, @"reading the converted store failed: %@", error);
	XCTAssertTrue(converted.count > 0, @"the converted document is empty");

	// Save: the portable store is written and a new .mad is archived.
	XCTAssertTrue([document writeContents:nil
							andAttributes:nil
							  safelyToURL:documentURL
						 forSaveOperation:UIDocumentSaveForOverwriting
									error:&error],
				  @"saving the converted document failed: %@", error);

	// Reopen the saved document from its own archive, as the next launch would.
	MADocument *reopened = [[MADocument alloc] initWithFileURL:documentURL];
	XCTAssertTrue([reopened readFromURL:documentURL error:&error],
				  @"reopening the saved document failed: %@", error);
	MADStoreGraph *reread = [[reopened.storeContext.store allObjectsWithError:&error] graphByCompletingInverses];
	XCTAssertNotNil(reread, @"reading the reopened store failed: %@", error);

	XCTAssertTrue([reread isEqualToGraph:converted],
				  @"the document changed across a save and reopen");

	[[NSFileManager defaultManager] removeItemAtURL:directory error:NULL];
}

#pragma mark - Undo

// document.undoManager must be live, and a designer edit (updateElements:setBold: and
// its inverse) must undo and redo against a real store-backed document.
- (void)testDesignerBoldUndoesAndRedoesThroughTheDocument {
	NSURL *documentURL = [[self newTestDirectory] URLByAppendingPathComponent:@"undo.mad"];
	MADocument *document = [[MADocument alloc] initWithFileURL:documentURL];

	// The context is normally opened by readFromURL:; KVC it in the way the other
	// store-less tests inject the model.
	RptqStoreContext *context = [self newTestContext];
	[document setValue:context forKey:@"storeContext"];

	NSUndoManager *undoManager = document.undoManager;
	XCTAssertNotNil(undoManager, @"document.undoManager is not live");
	XCTAssertTrue(document.designerLayout.delegate == document,
				  @"the designer layout's undo target is the document");

	RptqDocumentElement *element = [context insertObjectForEntity:NSStringFromClass([RptqDocumentElement class]) identifier:0];
	XCTAssertNotNil(element.textStyle, @"awakeFromInsert must create the satellites");
	XCTAssertTrue([context save:NULL]);

	[document.designerLayout updateElements:[NSSet setWithObject:@(element.identifier)] setBold:YES];
	XCTAssertTrue(element.textStyle.bold, @"the edit applied");

	[undoManager undo];
	XCTAssertFalse(element.textStyle.bold, @"undo must clear the bold");

	[undoManager redo];
	XCTAssertTrue(element.textStyle.bold, @"redo must restore the bold");
}

@end
