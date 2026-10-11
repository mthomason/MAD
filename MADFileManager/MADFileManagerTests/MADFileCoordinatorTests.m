//
//  MADFileCoordinatorTests.m
//  MADFileManagerTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for the MADFileCoordinator base class: the two factories that choose
//  a concrete coordinator, and the abstract contract every unimplemented method
//  still owes its callers (an NSInternalInconsistencyException naming the
//  selector).  The concrete coordinators are covered in their own suites.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADApplication.h>

#import "MADAppStorageOption.h"
#import "MADFileCoordinator.h"
#import "MADFileCoordinatorDelegate.h"
#import "MADFileCoordinatorProtocol.h"
#import "MADLocalFileCoordinator.h"
#import "MADCloudFileCoordinator.h"

// Declared and implemented on the base class, absent from its header.
@interface MADFileCoordinator (TestAccess)
- (void)createURLWithName:(NSString *)name
				extention:(NSString *)extention
				fileGroup:(NSString *)fileGroup;
- (id)debugQuickLookObject;
@end

#pragma mark - Test delegate

@interface MADTestFileCoordinatorDelegate : NSObject <MADFileCoordinatorDelegate>
@end

@implementation MADTestFileCoordinatorDelegate

- (void)fileCoordinatorDidUpdateContentsWithInsertedURLs:(NSArray *)insertedURLs
											 removedURLs:(NSArray *)removedURLs
											 updatedURLs:(NSArray *)updatedURLs { }

- (void)fileCoordinatorDidUpdateContentsWithInsertedMetaDatum:(NSArray *)insertedMetaDatum
											 removedMetaDatum:(NSArray *)removedMetaDatum
											 updatedMetaDatum:(NSArray *)updatedMetaDatum
												   completion:(void (^)(BOOL success, NSError *error))completion { }

- (void)fileCoordinatorDidFailRemovingFileAtURL:(NSURL *)URL withError:(NSError *)error { }
- (void)fileCoordinatorDidFailDuplicatingFileAtURL:(NSURL *)URL withError:(NSError *)error { }
- (void)fileCoordinatorDidFailRenamingFileAtURL:(NSURL *)URL withError:(NSError *)error { }
- (void)fileCoordinatorDidFailCreatingFileAtURL:(NSURL *)URL withError:(NSError *)error { }

@end

#pragma mark - Tests

@interface MADFileCoordinatorTests : XCTestCase

// Cloud coordinators are held until their documents-directory block has run;
// releasing one first segfaults (see BUGS.md).
@property (nonatomic, strong) NSMutableArray *cloudCoordinators;

@end

@implementation MADFileCoordinatorTests

- (void)setUp {
	[super setUp];
	self.cloudCoordinators = [NSMutableArray array];
}

- (void)tearDown {
	for (MADFileCoordinator *coordinator in self.cloudCoordinators) {
		dispatch_queue_t queue = [coordinator valueForKey:@"documentsDirectoryQueue"];
		if (queue != NULL) dispatch_sync(queue, ^{ });
	}
	[self.cloudCoordinators removeAllObjects];
	self.cloudCoordinators = nil;
	[super tearDown];
}

- (MADFileCoordinator *)keepCloudCoordinator:(MADFileCoordinator *)coordinator {
	if ([coordinator isKindOfClass:[MADCloudFileCoordinator class]]) {
		[self.cloudCoordinators addObject:coordinator];
	}
	return coordinator;
}

#pragma mark - Factories

- (void)testFactoryWithPathExtensionChoosesLocalForEveryNonCloudOption {
	NSString *group = [MADApplication groupIdentifier];
	NSArray <NSNumber *> *localOptions = @[@(MADAppStorageNotSet),
										   @(MADAppStorageLocal),
										   @(MADAppStorageCloudButSignedOut),
										   @(MADAppStorageStateUnknown)];

	for (NSNumber *option in localOptions) {
		MADFileCoordinator *coordinator =
			[MADFileCoordinator newFileCoordinatorWithPathExtension:@"mad"
													  storageOption:(MADAppStorage)option.integerValue
														 identifier:group
												  firstQueryHandler:nil];
		XCTAssertTrue([coordinator isKindOfClass:[MADLocalFileCoordinator class]],
					  @"storage option %@ should build a local coordinator", option);
	}
}

- (void)testFactoryWithPathExtensionChoosesCloudForTheCloudOption {
	MADFileCoordinator *coordinator =
		[self keepCloudCoordinator:
			[MADFileCoordinator newFileCoordinatorWithPathExtension:@"mad"
													   storageOption:MADAppStorageCloud
														  identifier:nil
												   firstQueryHandler:nil]];

	XCTAssertTrue([coordinator isKindOfClass:[MADCloudFileCoordinator class]]);
}

- (void)testFactoryWithLastPathComponentChoosesTheSameClasses {
	MADFileCoordinator *local =
		[MADFileCoordinator newFileCoordinatorWithLastPathComponent:@"Report.mad"
													 storageOption:MADAppStorageLocal
														identifier:[MADApplication groupIdentifier]
												 firstQueryHandler:nil];
	XCTAssertTrue([local isKindOfClass:[MADLocalFileCoordinator class]]);

	MADFileCoordinator *cloud =
		[self keepCloudCoordinator:
			[MADFileCoordinator newFileCoordinatorWithLastPathComponent:@"Report.mad"
														   storageOption:MADAppStorageCloud
															  identifier:nil
													   firstQueryHandler:nil]];
	XCTAssertTrue([cloud isKindOfClass:[MADCloudFileCoordinator class]]);
}

- (void)testFactoryPassesTheFirstQueryHandlerThrough {
	XCTestExpectation *handlerCalled = [self expectationWithDescription:@"first query handler"];

	MADFileCoordinator *coordinator =
		[MADFileCoordinator newFileCoordinatorWithPathExtension:@"mad"
												  storageOption:MADAppStorageLocal
													 identifier:[MADApplication groupIdentifier]
											  firstQueryHandler:^{
			[handlerCalled fulfill];
		}];

	[coordinator refresh];
	[self waitForExpectations:@[handlerCalled] timeout:5.0];
}

#pragma mark - Abstract contract

- (void)testUnimplementedMethodsThrowNamingTheSelector {
	MADFileCoordinator *coordinator = [[MADFileCoordinator alloc] init];
	NSURL *URL = [NSURL fileURLWithPath:@"/tmp/Report.mad"];

	NSArray <NSString *> *selectors = @[@"startQuery", @"stopQuery", @"refresh",
										@"removeFileAtURL:", @"duplicateFileAtURL:",
										@"renameFileAtURL:toName:", @"createURLWithName:extention:fileGroup:",
										@"canCreateFileWithName:extention:fileGroup:"];

	for (NSString *selectorName in selectors) {
		@try {
			if ([selectorName isEqualToString:@"startQuery"]) {
				[coordinator startQuery];
			} else if ([selectorName isEqualToString:@"stopQuery"]) {
				[coordinator stopQuery];
			} else if ([selectorName isEqualToString:@"refresh"]) {
				[coordinator refresh];
			} else if ([selectorName isEqualToString:@"removeFileAtURL:"]) {
				[coordinator removeFileAtURL:URL];
			} else if ([selectorName isEqualToString:@"duplicateFileAtURL:"]) {
				[coordinator duplicateFileAtURL:URL];
			} else if ([selectorName isEqualToString:@"renameFileAtURL:toName:"]) {
				[coordinator renameFileAtURL:URL toName:@"Other"];
			} else if ([selectorName isEqualToString:@"createURLWithName:extention:fileGroup:"]) {
				[coordinator createURLWithName:@"Report" extention:@"mad" fileGroup:nil];
			} else {
				[coordinator canCreateFileWithName:@"Report" extention:@"mad" fileGroup:nil];
			}
			XCTFail(@"%@ did not throw", selectorName);
		} @catch (NSException *exception) {
			XCTAssertEqualObjects(exception.name, NSInternalInconsistencyException, @"%@", selectorName);
			XCTAssertTrue([exception.reason containsString:selectorName],
						  @"reason for %@ was: %@", selectorName, exception.reason);
		}
	}
}

#pragma mark - Declared properties

- (void)testDocumentsDirectoryIsStored {
	MADFileCoordinator *coordinator = [[MADFileCoordinator alloc] init];
	NSURL *directory = [NSURL fileURLWithPath:@"/tmp/Documents" isDirectory:YES];

	XCTAssertNil(coordinator.documentsDirectory);
	coordinator.documentsDirectory = directory;
	XCTAssertEqualObjects(coordinator.documentsDirectory, directory);
}

- (void)testDelegateIsHeldWeakly {
	MADFileCoordinator *coordinator = [[MADFileCoordinator alloc] init];

	@autoreleasepool {
		MADTestFileCoordinatorDelegate *delegate = [[MADTestFileCoordinatorDelegate alloc] init];
		coordinator.delegate = delegate;
		XCTAssertEqual(coordinator.delegate, delegate);
	}

	XCTAssertNil(coordinator.delegate);
}

- (void)testDebugQuickLookObjectNamesTheClass {
	MADFileCoordinator *coordinator = [[MADFileCoordinator alloc] init];

	NSString *debug = [coordinator debugQuickLookObject];
	XCTAssertTrue([debug containsString:[[NSStringFromClass([MADFileCoordinator class]) uppercaseString] copy]]);
}

@end
