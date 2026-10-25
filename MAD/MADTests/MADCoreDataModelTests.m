//
//  MADCoreDataModelTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Tier 4 (Core Data domain model) coverage for the MAD framework.  These tests
//  load the compiled MAD.xcdatamodeld (MAD.momd) from the test bundle and exercise
//  the Rptq* managed-object subclasses against an in-memory store, independent of
//  any on-disk document or database connection.
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>

#import <MAD/RptqDocument.h>
#import <MAD/MADStore.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/MADocumentSectionType.h>

@interface MADCoreDataModelTests : XCTestCase
@end

@implementation MADCoreDataModelTests

#pragma mark - Helpers

- (NSManagedObjectModel *)modelFromTestBundle {
	NSURL *momdURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"MAD"
															 withExtension:@"momd"];
	XCTAssertNotNil(momdURL, @"MAD.momd was not compiled into the test bundle.");
	return [[NSManagedObjectModel alloc] initWithContentsOfURL:momdURL];
}

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

#pragma mark - Model loading

- (void)testManagedObjectModelLoadsFromTestBundle {
	NSManagedObjectModel *model = [self modelFromTestBundle];
	XCTAssertNotNil(model);
	XCTAssertEqual(model.entities.count, (NSUInteger)33);

	NSSet *names = [NSSet setWithArray:[model.entities valueForKey:@"name"]];
	XCTAssertTrue([names containsObject:@"RptqDocument"]);
	XCTAssertTrue([names containsObject:@"RptqDocumentSection"]);
	XCTAssertTrue([names containsObject:@"RptqDocumentSectionRows"]);
	XCTAssertTrue([names containsObject:@"RptqDatabase"]);
	XCTAssertTrue([names containsObject:@"RptqQuery"]);
}

- (void)testModelEntityResolvesToManagedObjectSubclass {
	NSManagedObjectModel *model = [self modelFromTestBundle];
	NSEntityDescription *entity = model.entitiesByName[@"RptqDocument"];
	XCTAssertNotNil(entity);
	// representedClassName points at the manual RptqDocument subclass.
	XCTAssertEqualObjects(entity.managedObjectClassName, @"RptqDocument");
	XCTAssertEqual(NSClassFromString(entity.managedObjectClassName), [RptqDocument class]);
}

#pragma mark - Entity insertion

- (void)testInsertRptqDocumentFromEntityName {
	RptqStoreContext *context = [self inMemoryContext];

	RptqDocument *document = [context insertObjectForEntity:@"RptqDocument" identifier:0];
	XCTAssertNotNil(document);
	XCTAssertTrue([document isKindOfClass:[RptqDocument class]]);
	// The store mints identifier = 1 for the first document.
	XCTAssertEqual(document.identifier, (int64_t)1);
}

#pragma mark - Document factory

- (void)testNewDocumentFactoryBuildsSections {
	RptqStoreContext *context = [self inMemoryContext];

	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	XCTAssertNotNil(document);
	XCTAssertEqual(document.identifier, (int64_t)1);

	XCTAssertNotNil(document.hasReportHeaderSection);
	XCTAssertNotNil(document.hasReportFooterSection);
	XCTAssertNotNil(document.hasPageHeaderSection);
	XCTAssertNotNil(document.hasPageFooterSection);
	XCTAssertNotNil(document.hasDetailSection);

	XCTAssertEqual(document.hasReportHeaderSection.type, (int16_t)MADDocumentSectionTypeReportHeader);
	XCTAssertEqual(document.hasReportFooterSection.type, (int16_t)MADDocumentSectionTypeReportFooter);
	XCTAssertEqual(document.hasPageHeaderSection.type, (int16_t)MADDocumentSectionTypePageHeader);
	XCTAssertEqual(document.hasPageFooterSection.type, (int16_t)MADDocumentSectionTypePageFooter);
	XCTAssertEqual(document.hasDetailSection.type, (int16_t)MADDocumentSectionTypeBody);
}

- (void)testNewDocumentFactorySectionIdentifiersAndRows {
	RptqStoreContext *context = [self inMemoryContext];

	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];

	XCTAssertEqual(document.hasReportHeaderSection.identifier, (int64_t)1);
	XCTAssertEqual(document.hasReportFooterSection.identifier, (int64_t)2);
	XCTAssertEqual(document.hasPageHeaderSection.identifier, (int64_t)3);
	XCTAssertEqual(document.hasPageFooterSection.identifier, (int64_t)4);
	XCTAssertEqual(document.hasDetailSection.identifier, (int64_t)5);

	XCTAssertEqual(document.hasReportHeaderSection.hasRows.count, (NSUInteger)1);
	XCTAssertEqual(document.hasReportFooterSection.hasRows.count, (NSUInteger)1);
	XCTAssertEqual(document.hasPageHeaderSection.hasRows.count, (NSUInteger)1);
	XCTAssertEqual(document.hasPageFooterSection.hasRows.count, (NSUInteger)1);
	XCTAssertEqual(document.hasDetailSection.hasRows.count, (NSUInteger)1);

	// setInterfaceHeight: stores the raw value on `layoutHeight`; the persisted
	// `height` attribute is derived as (interface height + 44).
	XCTAssertEqual(document.hasReportHeaderSection.layoutHeight, 44.0);
	XCTAssertEqual(document.hasReportHeaderSection.height, 88.0);
	XCTAssertEqual(document.hasDetailSection.layoutHeight, 88.0);
	XCTAssertEqual(document.hasDetailSection.height, 132.0);
}

@end
