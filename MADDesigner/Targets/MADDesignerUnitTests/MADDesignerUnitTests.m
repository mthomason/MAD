//
//  MADDesignerUnitTests.m
//  MADDesignerUnitTests
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Non-UI tests for the app. This bundle is hosted by `MAD Designer.app`
//  (TEST_HOST/BUNDLE_LOADER are set), so it can reach two things the framework test
//  bundles cannot: the app's own source, and the MAD frameworks exactly as the app
//  links them.
//
//  The first group covers app-source helper categories. Those live in the app
//  target's Sources phase, so they are reached through the host rather than imported:
//  the categories are declared locally here to describe the interface, and the
//  symbols resolve against the running app at load time.
//
//  The second group covers framework consumption -- the same construction and SQL
//  generation the app does when it opens a connection, which is the part of the
//  integration that is worth pinning independently of any live server.
//
//  The original contents of this file were the Xcode template stubs plus a
//  `testExample` that opened a live RDS instance in us-east-1 with hardcoded
//  credentials. That host no longer resolves and the APIs it used no longer exist, so
//  it had not compiled in some time. It is replaced below by tests that need no server;
//  the live path is covered by the framework suites (MADMySQLTests, MADTdsClientTests).
//

#import <XCTest/XCTest.h>

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseType.h>
#import <MADAPI/MADQuery.h>

#import <MAD/MADQueryTest.h>
#import <MADMySQL/MADDatabaseMySQL.h>
#import <MADMySQL/MADDatabaseConnectionMySql.h>
#import <MADPostgres/MADPostgres.h>
#import <MADAPI/MADConnectionViewController.h>

#import <MAD/MADocument.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/MADStore.h>
#import <MAD/MADStoreGraph.h>
#import <MAD/MADStoreObject.h>
#import <MAD/RptqObject.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabaseCredentals.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDocumentElementLabelDataField.h>
#import <MAD/RptqQueryField.h>
#import <MAD/MADDatabaseConnection+Constructor.h>
#import <MAD/MADOperationCreateDocumentCreateDocument.h>
#import <MAD/MADOperationCreateDocumentFirstTimeSetup.h>
#import <MAD/MADOperationCreateDocumentAddConnection.h>
#import <MAD/MADOperationCreateDocumentImportSchema.h>
#import <MAD/MADOperationDocumentCloseDocument.h>
#import <MAD/MADOperationUniqueUrlForFilename.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADURLFactory.h>
#import <UIKit/NSDataAsset.h>
#import <objc/runtime.h>

// A fixed-URL stand-in for MADOperationUniqueUrlForFilename, so the chain can be
// driven against a temp directory without the file explorer's URL machinery.
@interface MADFixedURLOperation : NSOperation <MADOperationUniqueUrlForFilenameProtocol>
@property (nonatomic, copy, readonly) NSURL *uniqueUrl;
- (instancetype)initWithURL:(NSURL *)url;
@end

@implementation MADFixedURLOperation
- (instancetype)initWithURL:(NSURL *)url {
	if (self = [super init]) {
		_uniqueUrl = url.copy;
	}
	return self;
}
@end

// The initializer exists on the class but is not in its header; the app reaches it
// through the group operation.  Declared locally so the test can build the chain the
// same way.
@interface MADOperationCreateDocumentFirstTimeSetup (MADDesignerUnitTestsChain)
- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)databaseConnection;
@end

// App-source categories. Declared rather than imported because the app's Source
// directory is not on this bundle's header search path; the implementations are in
// the host app.
@interface NSData (MADDesignerUnitTestsBase64)
+ (NSData *)dataFromBase64String:(NSString *)aString;
- (NSString *)base64EncodedString;
@end

@interface NSDateFormatter (MADDesignerUnitTestsRFC3339)
+ (instancetype)RFC_3339;
@end

@interface MADDriverSelectorController : UITableViewController
@property (nonatomic, weak, readonly) __kindof MADConnectionViewController *connectionViewController;
- (void)showViewControllerConnection:(NSInteger)type;
@end

@interface MADQueryAddLinkJoinTypeController : UITableViewController
@property (nonatomic, strong) MADocument *document;
@end

@interface MADDesignerSectionView : UICollectionView
@property (nonatomic, assign) int64_t identifier;
@end

@interface MADDesignerScrollView : UIScrollView
@property (nonatomic, strong) UIView *container;
@end

@interface MADDesignerView : UIView
@property (nonatomic, weak) MADDesignerScrollView *scroller;
@end

@interface MADLabelStatus : UILabel
- (void)updateStatusWithTime:(NSString *)message;
- (void)updateRecordsReadStatusWithNumberOfRecordsRead:(NSNumber *)numberOfRecs;
- (void)updateStatusWithPageNumber:(NSString *)message;
@end

@interface MADTabBarController : UITabBarController
@property (nonatomic, strong) MADocument *document;
+ (instancetype)newTabBarController:(MADocument *)document prompt:(NSString *)prompt;
@end

@interface MADThemeManager : NSObject
+ (void)applyAppearanceToTabBarController:(UITabBarController *)tabBarController traitCollection:(UITraitCollection *)traitCollection;
@end

@interface MADTableViewCellBase : UITableViewCell
@property (nonatomic, strong) UILabel *label;
@end

@interface MADAboutTableViewController : UITableViewController
+ (instancetype)newAboutTableViewController;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface MADGettingStartedTableViewController : UITableViewController
@end

@interface MADAcknowledgementsViewController : UIViewController
+ (NSAttributedString *)acknowledgementsAttributedText;
@end

@interface MADExplorerController : UICollectionViewController
@property (nonatomic, weak) UIBarButtonItem *barButtonItemAbout;
@property (nonatomic, weak) UIBarButtonItem *barButtonItemAddNewDocument;
- (IBAction)actionAbout:(id)sender;
- (IBAction)actionCancel:(id)sender;
- (IBAction)actionDone:(id)sender;
- (void)done:(id)sender;
@end

@interface MADExplorerNavigationItem : UINavigationItem
@end

@interface UINavigationController (MADDesignerUnitTestsConstructors)
@property (nonatomic, strong) MADocument *document;
+ (UINavigationController *)documentNavigationControllerWithType:(short)type
														document:(MADocument *)document;
@end

@interface MADViewerController : UIPageViewController
@property (nonatomic, weak) UIBarButtonItem *barButtonItemRefresh;
@property (nonatomic, strong) UIBarButtonItem *barButtonItemPaperSize;
@property (nonatomic, assign) MTPaperType selectedPaperType;
@property (nonatomic, assign, readonly) MTPaperType renderedPaperType;
+ (instancetype)newViewerController:(MADocument *)document;
- (void)selectPaperType:(MTPaperType)paperType;
- (void)setDisplayActive;
- (void)setDisplayInactive;
@end

@interface MADPageViewAttributes : NSObject
- (instancetype)initWithCurrentPage:(NSUInteger)currentPageNumber
							  total:(NSUInteger)numberOfPages
							   size:(CGSize)size;
@end

@interface MADDocumentPageController : UIViewController
@property (readonly, nonatomic, weak) UIView *documentView;
@property (readonly, nonatomic, weak) UIScrollView *documentScroller;
+ (instancetype)newDocumentPageController:(MADocument *)document
						   pageAttributes:(MADPageViewAttributes *)pageAttributes;
@end

@interface MADOperationInstallSampleDocument : MADOperation
@property (nonatomic, assign) bool sampleDocumentInstalled;
- (instancetype)initWithFilename:(NSString *)filename
				   fileExtension:(NSString *)fileExtension
				 groupIdentifier:(NSString *)groupIdentifier
					 installFlag:(NSString *)installFlag;
@end

static BOOL MADUnitTestForceMADViewerMode = NO;
static BOOL (*MADOriginalIsMADViewerIMP)(id, SEL) = NULL;
static BOOL MADSwizzledIsMADViewer(id self, SEL _cmd) {
	if (MADUnitTestForceMADViewerMode) {
		return YES;
	}
	return MADOriginalIsMADViewerIMP ? MADOriginalIsMADViewerIMP(self, _cmd) : NO;
}


@interface MADDesignerViewController : UIViewController
@property (nonatomic, weak) MADocument *document;
@property (nonatomic, assign) NSInteger lastSelectedSectionControlPanel;
@property (nonatomic, copy) NSNumber *objectIdEditDynamicLabel;
- (RptqDocumentSection *)sectionForLabelTag:(NSInteger)tag;
- (MADDesignerSectionView *)documentSectionViewWithIdentifier:(NSInteger)identifier;
- (void)tableViewControllerChooseFieldDidFinish:(id)controller withFieldID:(int64_t)fieldID;
@end

@interface MADDesignerUnitTests : XCTestCase
@end

@implementation MADDesignerUnitTests

#pragma mark - App source: NSData (Base64)

- (void)testBase64DecodeOfKnownString {
	NSData *decoded = [NSData dataFromBase64String:@"aGVsbG8="];
	XCTAssertEqualObjects([[NSString alloc] initWithData:decoded encoding:NSUTF8StringEncoding], @"hello");
}

- (void)testBase64EncodeOfKnownString {
	NSData *data = [@"hello" dataUsingEncoding:NSUTF8StringEncoding];
	XCTAssertEqualObjects([data base64EncodedString], @"aGVsbG8=");
}

- (void)testBase64RoundTrip {
	NSData *original = [@"The quick brown fox jumps over the lazy dog" dataUsingEncoding:NSUTF8StringEncoding];
	NSData *decoded = [NSData dataFromBase64String:[original base64EncodedString]];
	XCTAssertEqualObjects(decoded, original);
}

- (void)testBase64EncodeOfEmptyData {
	XCTAssertEqualObjects([NSData data].base64EncodedString, @"");
}

- (void)testBase64DecodeOfEmptyString {
	XCTAssertEqual([NSData dataFromBase64String:@""].length, (NSUInteger)0);
}

// An encoded length that is not a multiple of 4 still decodes, and no longer writes past
// the output buffer. The decoder used to size that buffer as `(length / 4) * 3` while
// the store loop always wrote 3 bytes per group, so a five-character input got a 3-byte
// buffer and the trailing character wrote at offsets 3, 4 and 5. The overrun landed in
// malloc's slack -- the returned NSData is built from the separately tracked length, so
// the decoded value was already correct -- which is why it needed inspection rather than
// a test to find. The assertions below pin the value; the buffer sizing is checked by
// reading NewBase64Decode.
- (void)testBase64DecodeOfTruncatedInput {
	NSData *decoded = [NSData dataFromBase64String:@"YWJjY"];

	XCTAssertEqual(decoded.length, (NSUInteger)3);
	XCTAssertEqualObjects([[NSString alloc] initWithData:decoded encoding:NSUTF8StringEncoding], @"abc");
}

#pragma mark - App source: NSDateFormatter (RFC_3339)

- (void)testRFC3339FormatterFormat {
	NSDate *epoch = [NSDate dateWithTimeIntervalSince1970:0];
	XCTAssertEqualObjects([[NSDateFormatter RFC_3339] stringFromDate:epoch], @"1970-01-01T00:00:00Z");
}

- (void)testRFC3339FormatterParsesAndRoundTrips {
	NSDateFormatter *formatter = [NSDateFormatter RFC_3339];
	NSDate *parsed = [formatter dateFromString:@"2020-01-15T13:45:00Z"];

	XCTAssertNotNil(parsed);
	XCTAssertEqualWithAccuracy(parsed.timeIntervalSince1970, 1579095900.0, 0.5);
	XCTAssertEqualObjects([formatter stringFromDate:parsed], @"2020-01-15T13:45:00Z");
}

// RFC 3339 permits both the `Z` spelling of UTC and a numeric offset. The format string
// used to end in a literal 'Z', so only the former was accepted and a server timestamp
// carrying an offset was silently dropped.
- (void)testRFC3339FormatterAcceptsAnExplicitNumericOffset {
	NSDateFormatter *formatter = [NSDateFormatter RFC_3339];

	XCTAssertNotNil([formatter dateFromString:@"2020-01-15T13:45:00Z"]);

	NSDate *offset = [formatter dateFromString:@"2020-01-15T13:45:00+02:00"];
	XCTAssertNotNil(offset);
	// 13:45 at +02:00 is 11:45 UTC.
	XCTAssertEqualWithAccuracy(offset.timeIntervalSince1970, 1579088700.0, 0.5);
}

#pragma mark - Framework consumption: connections

- (void)testMySQLConnectionProperties {
	MADDatabaseConnectionMySql *connection = [[MADDatabaseConnectionMySql alloc] initWithHost:@"localhost"
																					database:@"employees"
																					 andPort:3306];

	XCTAssertEqual(connection.databaseType, MADDatabaseTypeMySQL);
	XCTAssertTrue(connection.requiresCredentials);
	XCTAssertNotNil(connection.connectionString);
	XCTAssertNotNil(connection.identifier);
}

- (void)testPostgresConnectionProperties {
	MADDatabaseConnectionPostgres *connection = [[MADDatabaseConnectionPostgres alloc] initWithHost:@"localhost"
																						  database:@"chinook"
																						   andPort:5432];

	XCTAssertEqual(connection.databaseType, MADDatabaseTypePostgres);
	XCTAssertTrue(connection.requiresCredentials);
	XCTAssertNotNil(connection.connectionString);
	XCTAssertNotNil(connection.identifier);
}

#pragma mark - Framework consumption: SQL generation

// MADQueryTest is the connection-test query the app runs before it will accept a new
// connection. It builds its statement from the MADDatabase it is handed, so this pins
// the SQL text without touching a server.
- (void)testQueryTestGeneratesMySQLStatement {
	MADDatabaseMySQL *database = [[MADDatabaseMySQL alloc] init];
	database.databaseConnection = [[MADDatabaseConnectionMySql alloc] initWithHost:@"localhost"
																		 database:@"employees"
																		  andPort:3306];

	MADQueryTest *query = [[MADQueryTest alloc] initWithObject:database];
	query.database = database;

	NSError *error = nil;
	NSString *sql = [query getSql:&error];

	XCTAssertNil(error);
	XCTAssertNotNil(sql);
	XCTAssertTrue([sql containsString:@"SELECT"], @"Got: %@", sql);
	XCTAssertTrue([sql containsString:@"255"], @"Got: %@", sql);
	XCTAssertTrue([sql containsString:@"`f1`"], @"Got: %@", sql);
}

- (void)testQueryTestGeneratesPostgresStatement {
	MADDatabasePostgres *database = [[MADDatabasePostgres alloc] init];
	database.databaseConnection = [[MADDatabaseConnectionPostgres alloc] initWithHost:@"localhost"
																			database:@"chinook"
																			 andPort:5432];

	MADQueryTest *query = [[MADQueryTest alloc] initWithObject:database];
	query.database = database;

	NSError *error = nil;
	NSString *sql = [query getSql:&error];

	XCTAssertNil(error);
	XCTAssertNotNil(sql);
	XCTAssertTrue([sql containsString:@"SELECT"], @"Got: %@", sql);
	XCTAssertTrue([sql containsString:@"255"], @"Got: %@", sql);
	XCTAssertTrue([sql containsString:@"\"f1\""], @"Got: %@", sql);
}

#pragma mark - App source: PostgreSQL driver wiring

- (void)testDriverSelectorControllerIncludesPostgres {
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MADCreateDocument" bundle:[NSBundle mainBundle]];
	UINavigationController *nav = [storyboard instantiateViewControllerWithIdentifier:@"MADIdentifierNavControllerCreateDoc"];
	MADDriverSelectorController *selector = (MADDriverSelectorController *)nav.topViewController;
	[selector loadViewIfNeeded];

	XCTAssertEqual([selector tableView:selector.tableView numberOfRowsInSection:0], (NSInteger)3);
	UITableViewCell *cell = [selector tableView:selector.tableView
						  cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
	XCTAssertEqualObjects(cell.textLabel.text, @"PostgreSQL Native Driver");
	XCTAssertNotNil(cell.imageView.image);

	[selector showViewControllerConnection:2];
	XCTAssertTrue([selector.connectionViewController isKindOfClass:NSClassFromString(@"MADPostgresConnectionViewController")]);
	XCTAssertEqual(selector.connectionViewController.databaseType, MADDatabaseTypePostgres);
}

- (void)testQueryAddLinkJoinTypeControllerEnablesAllJoinsForPostgres {
	NSURL *directory = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
						URLByAppendingPathComponent:NSUUID.UUID.UUIDString isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *documentURL = [directory URLByAppendingPathComponent:@"pg.mad"];
	MADocument *document = [[MADocument alloc] initWithFileURL:documentURL];
	RptqDatabase *database = (RptqDatabase *)[document.storeContext insertObjectForEntity:@"RptqDatabase" identifier:1];
	RptqDatabaseCredentals *creds = (RptqDatabaseCredentals *)[document.storeContext insertObjectForEntity:@"RptqDatabaseCredentals" identifier:2];
	creds.driverID = [MADDatabaseConnection Identifier:MADDatabaseTypePostgres];
	creds.inDatabase = database;
	database.ownedByUser = creds;

	MADQueryAddLinkJoinTypeController *joinController = [[MADQueryAddLinkJoinTypeController alloc] initWithStyle:UITableViewStyleGrouped];
	joinController.document = document;
	UITableViewCell *equiCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MNSJoinTypeEquiJoin"];
	UITableViewCell *naturalCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MNSJoinTypeNaturalJoin"];
	UITableViewCell *fullOuterCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MNSJoinTypeFullOuterJoin"];
	equiCell.userInteractionEnabled = NO;
	equiCell.textLabel.enabled = NO;
	naturalCell.userInteractionEnabled = NO;
	naturalCell.textLabel.enabled = NO;
	fullOuterCell.userInteractionEnabled = NO;
	fullOuterCell.textLabel.enabled = NO;
	[joinController setValue:equiCell forKey:@"tableViewCellEquiJoin"];
	[joinController setValue:naturalCell forKey:@"tableViewCellNaturalJoin"];
	[joinController setValue:fullOuterCell forKey:@"tableViewCellFullOuterJoin"];

	[joinController loadViewIfNeeded];

	XCTAssertTrue(equiCell.userInteractionEnabled);
	XCTAssertTrue(equiCell.textLabel.enabled);
	XCTAssertTrue(naturalCell.userInteractionEnabled);
	XCTAssertTrue(naturalCell.textLabel.enabled);
	XCTAssertTrue(fullOuterCell.userInteractionEnabled);
	XCTAssertTrue(fullOuterCell.textLabel.enabled);

	[[NSFileManager defaultManager] removeItemAtURL:directory error:NULL];
}

// -initWithObject: deliberately ignores its argument -- the database has to be assigned
// afterwards. Without it the statement is built from a nil database and comes out as
// literal "(null)" text rather than failing loudly.
- (void)testQueryTestWithoutADatabaseProducesGarbageSQL {
	MADQueryTest *query = [[MADQueryTest alloc] initWithObject:[[MADDatabaseMySQL alloc] init]];

	NSError *error = nil;
	NSString *sql = [query getSql:&error];

	XCTAssertNil(query.database);
	XCTAssertNotNil(sql);
	XCTAssertTrue([sql containsString:@"(null)"], @"Got: %@", sql);
}

#pragma mark - The create-document chain, against the store

// The chain the app runs when the user picks New Document: create the document from a
// Sqlite3 connection (no server), import the schema, save, reopen, and assert the
// schema is there.  Chinook is the sample database the app itself ships.
- (void)testCreateDocumentChainImportsAChinookSchema {
	NSDataAsset *chinookAsset = [[NSDataAsset alloc] initWithName:@"chinook"];
	XCTAssertNotNil(chinookAsset, @"chinook.sqlite3 is not in the host app's assets");

	NSURL *directory = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
						URLByAppendingPathComponent:NSUUID.UUID.UUIDString isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *databaseURL = [directory URLByAppendingPathComponent:@"chinook.sqlite3"];
	NSURL *documentURL = [directory URLByAppendingPathComponent:
						  [[NSUUID UUID].UUIDString stringByAppendingPathExtension:@"mad"]];
	XCTAssertTrue([chinookAsset.data writeToURL:databaseURL options:NSDataWritingAtomic error:NULL]);

	MADDatabaseConnection *connection = [MADDatabaseConnection newDatabaseConnectionForUrl:databaseURL];

	MADFixedURLOperation *urlOperation = [[MADFixedURLOperation alloc] initWithURL:documentURL];
	MADOperationCreateDocumentCreateDocument *createDocument = [[MADOperationCreateDocumentCreateDocument alloc] initWithDatabaseConnection:connection];
	MADOperationCreateDocumentFirstTimeSetup *firstTimeSetup = [[MADOperationCreateDocumentFirstTimeSetup alloc] initWithDatabaseConnection:connection];
	MADOperationCreateDocumentAddConnection *addConnection = [[MADOperationCreateDocumentAddConnection alloc] initWithDatabaseConnection:connection];
	MADOperationCreateDocumentImportSchema *importSchema = [[MADOperationCreateDocumentImportSchema alloc] initWithDatabaseConnection:connection];
	MADOperationDocumentCloseDocument *closeDocument = [[MADOperationDocumentCloseDocument alloc] init];

	[createDocument addDependency:urlOperation];
	[firstTimeSetup addDependency:createDocument];
	[addConnection addDependency:firstTimeSetup];
	// The import finds the document through a direct dependency, as in the app's
	// group operation, and waits for the connection step.
	[importSchema addDependency:createDocument];
	[importSchema addDependency:addConnection];
	[closeDocument addDependency:createDocument];
	[closeDocument addDependency:importSchema];
	// The ops are asynchronous and their save machinery hops through the main queue;
	// blocking the main thread in waitUntilFinished: would deadlock, so wait on an
	// expectation instead.
	XCTestExpectation *finished = [self expectationWithDescription:@"create-document chain"];
	closeDocument.completionBlock = ^{
		[finished fulfill];
	};

	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;
	[queue addOperation:urlOperation];
	[queue addOperation:createDocument];
	[queue addOperation:firstTimeSetup];
	[queue addOperation:addConnection];
	[queue addOperation:importSchema];
	[queue addOperation:closeDocument];
	[self waitForExpectations:@[ finished ] timeout:120];

	MADocument *document = ((id <MADOperationCreateDocumentProtocol>)createDocument).document;
	XCTAssertNotNil(document, @"the chain did not create the document");
	XCTAssertEqual(createDocument.errors.count, (NSUInteger)0, @"create failed: %@", createDocument.errors.firstObject);
	XCTAssertEqual(firstTimeSetup.errors.count, (NSUInteger)0, @"setup failed: %@", firstTimeSetup.errors.firstObject);
	XCTAssertEqual(addConnection.errors.count, (NSUInteger)0, @"add-connection failed: %@", addConnection.errors.firstObject);
	XCTAssertEqual(importSchema.errors.count, (NSUInteger)0, @"import failed: %@", importSchema.errors.firstObject);
	XCTAssertEqual(closeDocument.errors.count, (NSUInteger)0, @"save-and-close failed: %@", closeDocument.errors.firstObject);
	XCTAssertTrue(importSchema.success, @"the schema import did not report success");

	// Reopen the document the chain saved and closed.
	MADocument *reopened = [[MADocument alloc] initWithFileURL:documentURL];
	NSError *error = nil;
	XCTAssertTrue([reopened readFromURL:documentURL error:&error], @"reopening failed: %@", error);

	NSArray *tables = [reopened.storeContext objectsForEntity:NSStringFromClass([RptqDatabaseSchemaTable class])];
	XCTAssertEqual(tables.count, (NSUInteger)11, @"chinook's eleven tables must be in the imported schema: %@", tables);

	NSArray *names = [tables valueForKey:@"name"];
	XCTAssertTrue([names containsObject:@"Track"], @"the Track table is missing: %@", names);
	XCTAssertTrue([names containsObject:@"PlaylistTrack"], @"the PlaylistTrack table is missing: %@", names);

	[[NSFileManager defaultManager] removeItemAtURL:directory error:NULL];
}

#pragma mark - App source: MADDesignerViewController regressions

- (void)testSectionForLabelTagUsesPassedTagNotLastSelectedSectionControlPanel {
	NSURL *tempURL = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
					  URLByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingPathExtension:@"mad"]];
	MADocument *document = [[MADocument alloc] initWithFileURL:tempURL];
	RptqDocument *rptqDoc = (RptqDocument *)[document.storeContext insertObjectForEntity:NSStringFromClass([RptqDocument class]) identifier:1];
	RptqDocumentSection *headerSection = (RptqDocumentSection *)[document.storeContext insertObjectForEntity:NSStringFromClass([RptqDocumentSection class]) identifier:101];
	RptqDocumentSection *pageHeaderSection = (RptqDocumentSection *)[document.storeContext insertObjectForEntity:NSStringFromClass([RptqDocumentSection class]) identifier:202];
	rptqDoc.hasReportHeaderSection = headerSection;
	rptqDoc.hasPageHeaderSection = pageHeaderSection;

	MADDesignerViewController *designerVC = [[MADDesignerViewController alloc] init];
	designerVC.document = document;
	designerVC.lastSelectedSectionControlPanel = 0;

	RptqDocumentSection *resolved = [designerVC sectionForLabelTag:1];
	XCTAssertEqual(resolved.identifier, (int64_t)202);
}

- (void)testDocumentSectionViewWithIdentifierMatchesIdentifierPropertyNotViewTag {
	MADDesignerViewController *designerVC = [[MADDesignerViewController alloc] init];
	MADDesignerView *designerView = [[MADDesignerView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
	MADDesignerScrollView *scroller = [[MADDesignerScrollView alloc] initWithFrame:designerView.bounds];
	UIView *container = [[UIView alloc] initWithFrame:scroller.bounds];
	scroller.container = container;
	[designerView addSubview:scroller];
	designerView.scroller = scroller;
	designerVC.view = designerView;

	UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
	MADDesignerSectionView *sectionView = [[MADDesignerSectionView alloc] initWithFrame:CGRectMake(0, 0, 100, 40)
																   collectionViewLayout:layout];
	sectionView.identifier = 4242;
	sectionView.tag = 0;
	[designerView.scroller.container addSubview:sectionView];

	MADDesignerSectionView *found = [designerVC documentSectionViewWithIdentifier:4242];
	XCTAssertEqual(found, sectionView);
}

- (void)testChooseFieldDidFinishUpdatesEditedDynamicLabelFieldReference {
	NSURL *tempURL = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
					  URLByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingPathExtension:@"mad"]];
	MADocument *document = [[MADocument alloc] initWithFileURL:tempURL];
	[document.storeContext insertObjectForEntity:@"RptqDocument" identifier:1];
	RptqDocumentElementLabelDataField *label = (RptqDocumentElementLabelDataField *)[document.storeContext insertObjectForEntity:NSStringFromClass([RptqDocumentElementLabelDataField class]) identifier:5001];
	RptqQueryField *field = (RptqQueryField *)[document.storeContext insertObjectForEntity:NSStringFromClass([RptqQueryField class]) identifier:6002];
	XCTAssertNotNil(label);
	XCTAssertNotNil(field);

	MADDesignerViewController *designerVC = [[MADDesignerViewController alloc] init];
	designerVC.document = document;
	designerVC.objectIdEditDynamicLabel = @(5001);

	[designerVC tableViewControllerChooseFieldDidFinish:nil withFieldID:6002];

	XCTAssertEqual(label.referencesQueryField.identifier, (int64_t)6002);
	XCTAssertNil(designerVC.objectIdEditDynamicLabel);
}

- (void)testTabBarAndViewerToolbarLayout {
	NSURL *tempURL = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
					  URLByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingPathExtension:@"mad"]];
	MADocument *document = [[MADocument alloc] initWithFileURL:tempURL];
	[document.storeContext insertObjectForEntity:@"RptqDocument" identifier:1];

	UIWindowScene *scene = (UIWindowScene *)UIApplication.sharedApplication.connectedScenes.anyObject;
	UIWindow *window = scene ? [[UIWindow alloc] initWithWindowScene:scene] : [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 402, 874)];
	window.frame = CGRectMake(0, 0, 402, 874);
	UINavigationController *rootNav = [[UINavigationController alloc] init];
	window.rootViewController = rootNav;
	[window makeKeyAndVisible];

	MADTabBarController *tabBarVC = [MADTabBarController newTabBarController:document prompt:@"Test.mad"];
	tabBarVC.document = document;
	[rootNav pushViewController:tabBarVC animated:NO];
	[window layoutIfNeeded];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];

	XCTAssertEqual(tabBarVC.tabBar.items.count, (NSUInteger)3);
	for (UITabBarItem *item in tabBarVC.tabBar.items) {
		XCTAssertNotNil(item.image);
		XCTAssertEqual(item.image.renderingMode, UIImageRenderingModeAlwaysTemplate);
		XCTAssertEqual(item.selectedImage.renderingMode, UIImageRenderingModeAlwaysTemplate);
	}
	XCTAssertEqualObjects(tabBarVC.tabBar.unselectedItemTintColor, [UIColor labelColor]);

	UINavigationController *viewerNav = (UINavigationController *)tabBarVC.viewControllers[2];
	UIViewController *dummyVC = [[UIViewController alloc] init];
	dummyVC.edgesForExtendedLayout = UIRectEdgeNone;

	MADLabelStatus *statusView = [[MADLabelStatus alloc] initWithFrame:CGRectMake(0, 0, 230, 44)];
	[statusView updateStatusWithTime:@"Updated just now"];
	[statusView updateRecordsReadStatusWithNumberOfRecordsRead:@(42)];
	[statusView updateStatusWithPageNumber:@"\nPage 1 of 2 pages."];
	UIBarButtonItem *statusItem = [[UIBarButtonItem alloc] initWithCustomView:statusView];
	UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	UIBarButtonItem *actionItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:nil action:nil];
	dummyVC.toolbarItems = @[statusItem, flexItem, actionItem];
	[viewerNav setViewControllers:@[dummyVC] animated:NO];

	tabBarVC.selectedIndex = 2;
	if ([tabBarVC.delegate respondsToSelector:@selector(tabBarController:didSelectViewController:)]) {
		[tabBarVC.delegate tabBarController:tabBarVC didSelectViewController:viewerNav];
	}
	[viewerNav setToolbarHidden:NO animated:NO];

	window.frame = CGRectMake(0, 0, 402, 875);
	[window layoutIfNeeded];
	window.frame = CGRectMake(0, 0, 402, 874);
	[window layoutIfNeeded];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];

	CGRect statusWin = [statusView convertRect:statusView.bounds toView:window];
	CGRect tabBarWin = [tabBarVC.tabBar convertRect:tabBarVC.tabBar.bounds toView:window];
	XCTAssertGreaterThanOrEqual(statusWin.size.width, 200.0);
	XCTAssertGreaterThanOrEqual(statusWin.size.height, 40.0);
	XCTAssertLessThanOrEqual(CGRectGetMaxY(statusWin), CGRectGetMinY(tabBarWin) + 1.0);
	XCTAssertGreaterThanOrEqual(CGRectGetMinY(statusWin), CGRectGetMaxY(dummyVC.view.frame) - 1.0);
}

- (void)testAboutAndAcknowledgementsViewControllers {
	MADAboutTableViewController *aboutVC = [MADAboutTableViewController newAboutTableViewController];
	XCTAssertNotNil(aboutVC);
	[aboutVC loadViewIfNeeded];
	aboutVC.view.frame = CGRectMake(0, 0, 320, 320);
	[aboutVC.view layoutIfNeeded];

	NSInteger rowCount = [aboutVC tableView:aboutVC.tableView numberOfRowsInSection:0];
	XCTAssertEqual(rowCount, 6);

	NSMutableArray<NSString *> *rowTexts = [NSMutableArray arrayWithCapacity:(NSUInteger)rowCount];
	for (NSInteger r = 0; r < rowCount; r++) {
		NSIndexPath *ip = [NSIndexPath indexPathForRow:r inSection:0];
		MADTableViewCellBase *cell = (MADTableViewCellBase *)[aboutVC tableView:aboutVC.tableView cellForRowAtIndexPath:ip];
		[cell layoutIfNeeded];
		NSString *text = cell.label.text ?: cell.label.attributedText.string ?: @"";
		[rowTexts addObject:text];

		XCTAssertFalse([text localizedCaseInsensitiveContainsString:@"Everyday Apps"], @"Row %ld should not mention Everyday Apps: %@", (long)r, text);
		XCTAssertFalse([text localizedCaseInsensitiveContainsString:@"Cincinnati"], @"Row %ld should not mention Cincinnati: %@", (long)r, text);
		XCTAssertFalse([text containsString:@"®"], @"Row %ld should not claim a registered trademark: %@", (long)r, text);
	}

	XCTAssertEqualObjects(rowTexts[0], @"MAD Designer");
	XCTAssertTrue([rowTexts[2] containsString:@"Copyright © 2012–2026 Michael Thomason"]);
	XCTAssertTrue([rowTexts[3] containsString:@"Licensed under the MIT License"]);
	XCTAssertTrue([rowTexts[3] containsString:@"not licensed under the MIT License"]);
	XCTAssertEqualObjects(rowTexts[4], @"Overview");
	XCTAssertEqualObjects(rowTexts[5], @"Acknowledgements");

	NSAttributedString *ackText = [MADAcknowledgementsViewController acknowledgementsAttributedText];
	XCTAssertNotNil(ackText);
	NSString *ackString = ackText.string;
	XCTAssertTrue([ackString containsString:@"MariaDB Connector/C"]);
	XCTAssertTrue([ackString containsString:@"FreeTDS"]);
	XCTAssertTrue([ackString containsString:@"PostgreSQL libpq"]);
	XCTAssertTrue([ackString containsString:@"OpenSSL"]);
	XCTAssertTrue([ackString containsString:@"libarchive"]);
	XCTAssertTrue([ackString containsString:@"zint"]);
	XCTAssertTrue([ackString containsString:@"Font Awesome"]);
	XCTAssertTrue([ackString containsString:@"GNU LESSER GENERAL PUBLIC LICENSE"]);
	XCTAssertTrue([ackString containsString:@"Apache License"]);

	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:aboutVC];
	[navController loadViewIfNeeded];
	[aboutVC beginAppearanceTransition:YES animated:NO];
	[aboutVC endAppearanceTransition];
	XCTAssertTrue(navController.isNavigationBarHidden);

	[aboutVC tableView:aboutVC.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	XCTAssertEqual(navController.viewControllers.count, (NSUInteger)2);
	XCTAssertTrue([navController.topViewController isKindOfClass:[MADGettingStartedTableViewController class]]);
	MADGettingStartedTableViewController *overviewVC = (MADGettingStartedTableViewController *)navController.topViewController;
	[overviewVC loadViewIfNeeded];
	[overviewVC beginAppearanceTransition:YES animated:NO];
	[overviewVC endAppearanceTransition];
	XCTAssertFalse(navController.isNavigationBarHidden);
	XCTAssertEqual([overviewVC tableView:overviewVC.tableView numberOfRowsInSection:0], 12);
	MADTableViewCellBase *overviewCell0 = (MADTableViewCellBase *)[overviewVC tableView:overviewVC.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	XCTAssertEqualObjects(overviewCell0.label.text, @"Mobile Analytics Document");

	[navController popToRootViewControllerAnimated:NO];
	[aboutVC beginAppearanceTransition:YES animated:NO];
	[aboutVC endAppearanceTransition];
	XCTAssertTrue(navController.isNavigationBarHidden);

	[aboutVC tableView:aboutVC.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:0]];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	XCTAssertEqual(navController.viewControllers.count, (NSUInteger)2);
	XCTAssertTrue([navController.topViewController isKindOfClass:[MADAcknowledgementsViewController class]]);
	[navController.topViewController loadViewIfNeeded];
	[navController.topViewController beginAppearanceTransition:YES animated:NO];
	[navController.topViewController endAppearanceTransition];
	XCTAssertFalse(navController.isNavigationBarHidden);
}

#pragma mark - App source: MAD Viewer regressions

- (void)testNavigationControllerViewerFactoryAndNavigationBar {
	NSURL *tempURL = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
					  URLByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingPathExtension:@"mad"]];
	MADocument *document = [[MADocument alloc] initWithFileURL:tempURL];
	// MADNavigationControllerTypeViewer == 8
	UINavigationController *viewerNav = [UINavigationController documentNavigationControllerWithType:8 document:document];
	XCTAssertNotNil(viewerNav);
	XCTAssertTrue([viewerNav isKindOfClass:NSClassFromString(@"MADNavigationControllerViewer")]);
	XCTAssertTrue([viewerNav.navigationBar isKindOfClass:NSClassFromString(@"MADViewerNavigationBar")]);
	XCTAssertEqual(viewerNav.document, document);
}

- (void)testViewerControllerNavigationItemsSetOnOwnNavigationItem {
	NSURL *tempURL = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
					  URLByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingPathExtension:@"mad"]];
	MADocument *document = [[MADocument alloc] initWithFileURL:tempURL];
	MADViewerController *viewerVC = [MADViewerController newViewerController:document];
	XCTAssertNotNil(viewerVC);
	[viewerVC loadViewIfNeeded];

	[viewerVC setDisplayInactive];
	UIBarButtonItem *inactiveRightItem = viewerVC.navigationItem.rightBarButtonItem;
	XCTAssertNotNil(inactiveRightItem);
	XCTAssertTrue([inactiveRightItem.customView isKindOfClass:[UIActivityIndicatorView class]]);
	UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)inactiveRightItem.customView;
	XCTAssertTrue(spinner.isAnimating);

	[viewerVC setDisplayActive];
	UIBarButtonItem *activeRightItem = viewerVC.navigationItem.rightBarButtonItem;
	XCTAssertNotNil(activeRightItem);
	XCTAssertNil(activeRightItem.customView);
	XCTAssertEqual(activeRightItem, viewerVC.barButtonItemRefresh);
	XCTAssertTrue(viewerVC.barButtonItemRefresh.isEnabled);
	XCTAssertNotNil(viewerVC.barButtonItemPaperSize);
	XCTAssertNotNil(viewerVC.barButtonItemPaperSize.menu);
}

- (void)testViewerPageSizeSelectionAndOrientationInvariance {
	NSURL *tempURL = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
					  URLByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingPathExtension:@"mad"]];
	MADocument *document = [[MADocument alloc] initWithFileURL:tempURL];
	[document.storeContext insertObjectForEntity:@"RptqDocument" identifier:1];
	MADViewerController *viewerVC = [MADViewerController newViewerController:document];
	[viewerVC loadViewIfNeeded];

	// Default paper type is US Letter across apps
	XCTAssertEqual(viewerVC.selectedPaperType, MTPaperTypeLetter);
	XCTAssertEqual(viewerVC.renderedPaperType, MTPaperTypeLetter);
	XCTAssertEqualWithAccuracy(document.paperSize.width, 612.0, 0.5);
	XCTAssertEqualWithAccuracy(document.paperSize.height, 792.0, 0.5);

	// Selecting A4 updates selectedPaperType and button title, but does not change renderedPaperType until refresh
	[viewerVC selectPaperType:MTPaperTypeA4];
	XCTAssertEqual(viewerVC.selectedPaperType, MTPaperTypeA4);
	XCTAssertEqual(viewerVC.renderedPaperType, MTPaperTypeLetter);
	XCTAssertEqualObjects(viewerVC.barButtonItemPaperSize.title, @"A4");

	// Apply A4 on document as refresh does, then verify framed page view is rotation-invariant
	[document setPaperType:MTPaperTypeA4];
	XCTAssertEqualWithAccuracy(document.paperSize.width, 595.0, 1.0);
	XCTAssertEqualWithAccuracy(document.paperSize.height, 842.0, 1.0);

	MADPageViewAttributes *attrs = [[MADPageViewAttributes alloc] initWithCurrentPage:1
																				total:1
																				 size:document.paperSize];
	MADDocumentPageController *pageVC = [MADDocumentPageController newDocumentPageController:document
																			  pageAttributes:attrs];
	// Start in Portrait (390 x 844)
	pageVC.view.frame = CGRectMake(0.0, 0.0, 390.0, 844.0);
	[pageVC loadViewIfNeeded];
	[pageVC.view setNeedsLayout];
	[pageVC.view layoutIfNeeded];

	XCTAssertEqual(pageVC.documentView.autoresizingMask, UIViewAutoresizingNone);
	XCTAssertFalse(pageVC.documentScroller.autoresizesSubviews);
	XCTAssertGreaterThan(pageVC.documentView.layer.borderWidth, 0.0);
	XCTAssertGreaterThan(pageVC.documentView.layer.shadowOpacity, 0.0f);
	XCTAssertEqualWithAccuracy(pageVC.documentView.bounds.size.width, document.paperSize.width, 0.5);
	XCTAssertEqualWithAccuracy(pageVC.documentView.bounds.size.height, document.paperSize.height, 0.5);
	CGFloat portraitZoom = pageVC.documentScroller.zoomScale;
	XCTAssertEqualWithAccuracy(portraitZoom, 1.0, 0.01);

	// Rotate to Landscape (844 x 390) -> page size and zoomScale must not change or distort
	pageVC.view.frame = CGRectMake(0.0, 0.0, 844.0, 390.0);
	[pageVC.view setNeedsLayout];
	[pageVC.view layoutIfNeeded];
	XCTAssertEqualWithAccuracy(pageVC.documentView.bounds.size.width, document.paperSize.width, 0.5);
	XCTAssertEqualWithAccuracy(pageVC.documentView.bounds.size.height, document.paperSize.height, 0.5);
	XCTAssertEqualWithAccuracy(pageVC.documentScroller.zoomScale, portraitZoom, 0.01);

	// Rotate back to Portrait (390 x 844) -> still unchanged
	pageVC.view.frame = CGRectMake(0.0, 0.0, 390.0, 844.0);
	[pageVC.view setNeedsLayout];
	[pageVC.view layoutIfNeeded];
	XCTAssertEqualWithAccuracy(pageVC.documentView.bounds.size.width, document.paperSize.width, 0.5);
	XCTAssertEqualWithAccuracy(pageVC.documentView.bounds.size.height, document.paperSize.height, 0.5);
	XCTAssertEqualWithAccuracy(pageVC.documentScroller.zoomScale, portraitZoom, 0.01);
}

- (void)testInstallSampleDocumentDoesNotOverwriteExistingFileWithExtension {
	NSString *flagKey = [NSString stringWithFormat:@"MADUnitTestInstallSampleFlag_%@", NSUUID.UUID.UUIDString];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:flagKey];

	NSString *groupID = @"group.everydayapps.mad.local";
	NSURL *docsDir = [MADURLFactory newURLLocalDocumentsDirectoryForGroupIdentifier:groupID];
	XCTAssertNotNil(docsDir);
	[[NSFileManager defaultManager] createDirectoryAtURL:docsDir withIntermediateDirectories:YES attributes:nil error:NULL];

	NSURL *londonURL = [[docsDir URLByAppendingPathComponent:@"London" isDirectory:NO] URLByAppendingPathExtension:@"mad"];
	NSData *originalBackup = [[NSData alloc] initWithContentsOfURL:londonURL];

	NSData *sentinelData = [@"sentinel-london-content" dataUsingEncoding:NSUTF8StringEncoding];
	XCTAssertTrue([sentinelData writeToURL:londonURL options:NSDataWritingAtomic error:NULL]);

	MADOperationInstallSampleDocument *op = [[MADOperationInstallSampleDocument alloc] initWithFilename:@"London"
																						  fileExtension:@"mad"
																						groupIdentifier:groupID
																							installFlag:flagKey];
	XCTestExpectation *exp = [self expectationWithDescription:@"install sample document checks .mad extension"];
	op.completionBlock = ^{
		[exp fulfill];
	};
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	[queue addOperation:op];
	[self waitForExpectations:@[exp] timeout:10.0];

	NSData *afterData = [[NSData alloc] initWithContentsOfURL:londonURL];
	XCTAssertEqualObjects(afterData, sentinelData, @"Existing London.mad should not be overwritten");
	XCTAssertTrue([[NSUserDefaults standardUserDefaults] boolForKey:flagKey]);

	[[NSUserDefaults standardUserDefaults] removeObjectForKey:flagKey];
	if (originalBackup != nil) {
		[originalBackup writeToURL:londonURL options:NSDataWritingAtomic error:NULL];
	} else {
		[[NSFileManager defaultManager] removeItemAtURL:londonURL error:NULL];
	}
}

- (void)testMADViewerModeHidesTabBarOmitsDesignerTabsAndHidesAddDocumentButton {
	Method m = class_getClassMethod([MADApplication class], @selector(isMADViewer));
	XCTAssertTrue(m != NULL);
	if (MADOriginalIsMADViewerIMP == NULL) {
		MADOriginalIsMADViewerIMP = (BOOL (*)(id, SEL))method_setImplementation(m, (IMP)MADSwizzledIsMADViewer);
	}
	MADUnitTestForceMADViewerMode = YES;
	@try {
		XCTAssertTrue([MADApplication isMADViewer]);

		NSURL *tempURL = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
						  URLByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingPathExtension:@"mad"]];
		MADocument *document = [[MADocument alloc] initWithFileURL:tempURL];
		[document.storeContext insertObjectForEntity:@"RptqDocument" identifier:1];

		MADTabBarController *tabBarVC = [MADTabBarController newTabBarController:document prompt:@"ViewerTest.mad"];
		tabBarVC.document = document;
		[tabBarVC loadViewIfNeeded];
		[tabBarVC beginAppearanceTransition:YES animated:NO];
		[tabBarVC endAppearanceTransition];

		XCTAssertTrue(tabBarVC.tabBar.isHidden);
		XCTAssertEqual(tabBarVC.edgesForExtendedLayout, UIRectEdgeBottom);
		XCTAssertEqual(tabBarVC.viewControllers.count, (NSUInteger)1);
		XCTAssertTrue([tabBarVC.viewControllers.firstObject isKindOfClass:NSClassFromString(@"MADNavigationControllerViewer")]);

		UIStoryboard *explorerStoryboard = [UIStoryboard storyboardWithName:@"MADExplorer" bundle:[NSBundle mainBundle]];
		UINavigationController *explorerNav = [explorerStoryboard instantiateInitialViewController];
		MADExplorerController *explorerVC = (MADExplorerController *)explorerNav.topViewController;
		[explorerVC loadViewIfNeeded];

		XCTAssertEqualObjects(explorerVC.navigationItem.title, @"MAD Viewer");
		XCTAssertNotNil(explorerVC.navigationItem.titleView);
		XCTAssertEqualObjects([explorerVC.navigationItem.titleView valueForKey:@"text"], @"MAD Viewer");
		XCTAssertNil(explorerVC.navigationItem.leftBarButtonItem);
		XCTAssertFalse(explorerVC.barButtonItemAddNewDocument.isEnabled);

		[explorerVC actionCancel:nil];
		XCTAssertNil(explorerVC.navigationItem.leftBarButtonItem);
		XCTAssertFalse(explorerVC.barButtonItemAddNewDocument.isEnabled);

		[explorerVC actionDone:nil];
		XCTAssertNil(explorerVC.navigationItem.leftBarButtonItem);
		XCTAssertFalse(explorerVC.barButtonItemAddNewDocument.isEnabled);
	} @finally {
		MADUnitTestForceMADViewerMode = NO;
	}
}

@end
