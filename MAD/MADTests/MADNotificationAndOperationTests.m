//
//  MADNotificationAndOperationTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Tier 1 coverage for two small notifications and one operation:
//
//    * MADNotificationDidFormatPage -- the singleton that paces page-format progress
//      notifications.  Page 0 always posts (0 % interval == 0) and resets the pacing,
//      so it is the one page that can be asserted regardless of what ran before.
//    * MADNotificationFileUpdate -- carries a document URL to observers via -notify.
//    * MADOperationUniqueUrlForFilename -- resolves a non-colliding file URL in a
//      directory, and finishes with an error when it cannot.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADOperation.h>

#import "MADNotificationDidFormatPage.h"
#import "MADNotificationFileUpdate.h"
#import "MADNotificationProtocol.h"
#import "MADOperationUniqueUrlForFilename.h"

@interface MADNotificationAndOperationTests : XCTestCase
@end

@implementation MADNotificationAndOperationTests

#pragma mark - MADNotificationDidFormatPage

- (void)testFormatPageSingletonIdentity {
	MADNotificationDidFormatPage *a = [MADNotificationDidFormatPage sharedObject];
	MADNotificationDidFormatPage *b = [MADNotificationDidFormatPage sharedObject];

	XCTAssertNotNil(a);
	XCTAssertEqual(a, b);
	XCTAssertEqual([a copy], a);
}

- (void)testFormatPageZeroPostsNotification {
	MADNotificationDidFormatPage *notifier = [MADNotificationDidFormatPage sharedObject];
	id formatter = [[NSObject alloc] init];

	__block NSNotification *captured = nil;
	id observer = [[NSNotificationCenter defaultCenter] addObserverForName:MADNotificationDidFormatPagesName
																	object:nil
																	 queue:nil
																usingBlock:^(NSNotification *note) {
		captured = note;
	}];

	[notifier reportFormatter:formatter formattedPage:0];
	[[NSNotificationCenter defaultCenter] removeObserver:observer];

	XCTAssertNotNil(captured);
	XCTAssertEqual(captured.object, formatter);
	XCTAssertEqualObjects(captured.userInfo[MTDatabaseNumberOfPagesFormattedKey], @0);
}

#pragma mark - MADNotificationFileUpdate

- (void)testFileUpdateNotifyPostsURL {
	NSURL *url = [NSURL fileURLWithPath:@"/tmp/Report.mad"];
	MADNotificationFileUpdate *update = [[MADNotificationFileUpdate alloc] initWithURL:url];

	__block NSNotification *captured = nil;
	__block NSUInteger count = 0;
	id observer = [[NSNotificationCenter defaultCenter] addObserverForName:MADNotificationIdentifierFileUpdate
																	object:nil
																	 queue:nil
																usingBlock:^(NSNotification *note) {
		captured = note;
		count++;
	}];

	[update notify];
	[[NSNotificationCenter defaultCenter] removeObserver:observer];

	XCTAssertEqual(count, (NSUInteger)1);
	XCTAssertEqualObjects(captured.object, url);
}

#pragma mark - MADOperationUniqueUrlForFilename

- (NSURL *)temporaryDirectory {
	NSURL *directory = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString]
								  isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	return directory;
}

- (void)testUniqueUrlForFreeFilename {
	NSURL *directory = [self temporaryDirectory];
	MADOperationUniqueUrlForFilename *operation;
	operation = [[MADOperationUniqueUrlForFilename alloc] initWithDesiredFilename:@"Report"
																	pathExtension:@"mad"
															 andDocumentsDirectory:directory];

	XCTAssertTrue(operation.isAsynchronous);

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertNotNil(operation.uniqueUrl);
	XCTAssertEqualObjects(operation.uniqueUrl.lastPathComponent, @"Report.mad");
	XCTAssertEqualObjects(operation.uniqueUrl.URLByDeletingLastPathComponent.path, directory.path);
}

- (void)testUniqueUrlSkipsExistingFile {
	NSURL *directory = [self temporaryDirectory];
	NSURL *existing = [directory URLByAppendingPathComponent:@"Report.mad"];
	[[NSFileManager defaultManager] createFileAtPath:existing.path contents:[NSData data] attributes:nil];

	MADOperationUniqueUrlForFilename *operation;
	operation = [[MADOperationUniqueUrlForFilename alloc] initWithDesiredFilename:@"Report"
																	pathExtension:@"mad"
															 andDocumentsDirectory:directory];
	[operation execute];

	XCTAssertEqualObjects(operation.uniqueUrl.lastPathComponent, @"Report 0.mad");
}

- (void)testUniqueUrlWithoutExtension {
	NSURL *directory = [self temporaryDirectory];
	MADOperationUniqueUrlForFilename *operation;
	operation = [[MADOperationUniqueUrlForFilename alloc] initWithDesiredFilename:@"Report"
																	pathExtension:@""
															 andDocumentsDirectory:directory];
	[operation execute];

	XCTAssertEqualObjects(operation.uniqueUrl.lastPathComponent, @"Report");
}

@end
