//
//  MADAlertControllerTests.m
//  MADCocoaExtensionsTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADAlertController: the app's alert factories.  Each is pinned for
//  the pieces a caller can observe without presenting the alert -- title, message,
//  style, and the actions with their styles and order.
//
//  -newAlertControllerSaveCredentials:cancel: and
//  -newAlertControllerPromptForPasswordGivenUsername:... are implemented but declared
//  in no header; they are reached through the test-only bridge below.
//
//  Text-field contents are not asserted: UIAlertController builds its text fields at
//  presentation time, and these alerts are never presented.
//

#import <XCTest/XCTest.h>
#include <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIAlertController.h>

#import <MADCocoaExtensions/MADAlertController.h>

// Undeclared implementation surface; this test-only category is the deliberate bridge.
@interface MADAlertController (TestFactories)
+ (UIAlertController *)newAlertControllerSaveCredentials:(void (^)(UIAlertAction *action))handlerContinue
												  cancel:(void (^)(UIAlertAction *action))handlerCancel;
+ (UIAlertController *)newAlertControllerPromptForPasswordGivenUsername:(NSString *)username
															   password:(void (^)(UITextField *textField))passwordSetup
																 submit:(void (^)(NSString *password))handlerContinue
																 cancel:(void (^)(void))handlerCancel;
@end

@interface MADAlertControllerTests : XCTestCase
@end

@implementation MADAlertControllerTests

#pragma mark - Errors

- (void)testErrorAlertUsesDescriptionAndReason {
	NSError *error = [NSError errorWithDomain:@"com.example.tests" code:1 userInfo:@{
		NSLocalizedDescriptionKey: @"Something went wrong",
		NSLocalizedFailureReasonErrorKey: @"Because testing.",
		NSLocalizedRecoverySuggestionErrorKey: @"Try again.",
	}];

	UIAlertController *alert = [MADAlertController newAlertControllerError:error];

	XCTAssertEqualObjects(alert.title, @"Something went wrong");
	// Reason and recovery suggestion are concatenated.
	XCTAssertEqualObjects(alert.message, @"Because testing.Try again.");
	XCTAssertEqual(alert.preferredStyle, UIAlertControllerStyleAlert);
	XCTAssertEqual(alert.actions.count, (NSUInteger)1);
	XCTAssertEqualObjects(alert.actions.firstObject.title, @"Continue");
}

- (void)testErrorAlertWithoutDetailsUsesTheUnknownErrorFallback {
	NSError *error = [NSError errorWithDomain:@"com.example.tests" code:1 userInfo:nil];

	UIAlertController *alert = [MADAlertController newAlertControllerError:error];

	XCTAssertEqualObjects(alert.message, @"Unknown error.");
}

- (void)testErrorDisplayAlertCarriesTitleMessageAndCompletion {
	UIAlertController *alert = [MADAlertController newAlertControllerErrorDisplayErrorWithTitle:@"Title"
																						message:@"Message"
																				  andCompletion:^(UIAlertAction *action) {}];

	XCTAssertEqualObjects(alert.title, @"Title");
	XCTAssertEqualObjects(alert.message, @"Message");
	XCTAssertEqual(alert.preferredStyle, UIAlertControllerStyleAlert);
	XCTAssertEqual(alert.actions.count, (NSUInteger)1);
	XCTAssertEqual(alert.actions.firstObject.style, UIAlertActionStyleDefault);
}

#pragma mark - Credentials

- (void)testRemoveCredentialsKeepsCancelStyleAndDestructiveRemoval {
	UIAlertController *alert = [MADAlertController removeCredentials:^(UIAlertAction *action) {}
															  cancel:^(UIAlertAction *action) {}];

	XCTAssertEqualObjects(alert.title, @"Remove Saved Password");
	XCTAssertEqual(alert.actions.count, (NSUInteger)2);
	XCTAssertEqualObjects(alert.actions[0].title, @"Keep");
	XCTAssertEqual(alert.actions[0].style, UIAlertActionStyleDefault);
	XCTAssertEqualObjects(alert.actions[1].title, @"Remove");
	XCTAssertEqual(alert.actions[1].style, UIAlertActionStyleDestructive);
}

- (void)testSaveCredentialsAlertContinuesOrCancels {
	UIAlertController *alert = [MADAlertController newAlertControllerSaveCredentials:^(UIAlertAction *action) {}
																			 cancel:^(UIAlertAction *action) {}];

	XCTAssertEqualObjects(alert.title, @"Save Credentials");
	XCTAssertEqual(alert.actions.count, (NSUInteger)2);
	XCTAssertEqualObjects(alert.actions[0].title, @"Continue");
	XCTAssertEqual(alert.actions[0].style, UIAlertActionStyleDefault);
	XCTAssertEqualObjects(alert.actions[1].title, @"Cancel");
	XCTAssertEqual(alert.actions[1].style, UIAlertActionStyleCancel);
}

- (void)testPasswordPromptHasSubmitAndCancel {
	UIAlertController *alert = [MADAlertController newAlertControllerPromptForPasswordGivenUsername:@"alice"
																						   password:^(UITextField *textField) {}
																							 submit:^(NSString *password) {}
																							 cancel:^{}];

	XCTAssertEqualObjects(alert.title, @"Password");
	XCTAssertEqual(alert.actions.count, (NSUInteger)2);
	XCTAssertEqualObjects(alert.actions[0].title, @"Continue");
	XCTAssertEqual(alert.actions[1].style, UIAlertActionStyleCancel);
}

#pragma mark - Destructive confirmation

- (NSString *)spelledNumber:(NSUInteger)count {
	return [NSNumberFormatter localizedStringFromNumber:@(count) numberStyle:NSNumberFormatterSpellOutStyle];
}

- (void)testDeleteItemsUsesPluralWording {
	UIAlertController *alert = [MADAlertController newAlertControllerDeleteItems:4
																		 confirm:^(UIAlertAction *action) {}
																		  cancel:^(UIAlertAction *action) {}];
	NSString *spelled = [self spelledNumber:4];
	NSString *expectedTitle = [NSString stringWithFormat:@"Remove %@ items", spelled];

	XCTAssertEqual(alert.preferredStyle, UIAlertControllerStyleActionSheet);
	XCTAssertEqualObjects(alert.title, @"Confirm");
	XCTAssertTrue([alert.message containsString:spelled]);
	XCTAssertEqual(alert.actions.count, (NSUInteger)2);
	// Cancel is added first, the destructive action second.
	XCTAssertEqual(alert.actions[0].style, UIAlertActionStyleCancel);
	XCTAssertEqual(alert.actions[1].style, UIAlertActionStyleDestructive);
	XCTAssertEqualObjects(alert.actions[1].title, expectedTitle);
}

- (void)testDeleteSingleItemUsesSingularWording {
	UIAlertController *alert = [MADAlertController newAlertControllerDeleteItems:1
																		 confirm:^(UIAlertAction *action) {}
																		  cancel:^(UIAlertAction *action) {}];
	NSString *spelled = [self spelledNumber:1];
	NSString *expectedTitle = [NSString stringWithFormat:@"Remove %@ item", spelled];

	XCTAssertEqualObjects(alert.actions[1].title, expectedTitle);
}

#pragma mark - Completion notice

- (void)testTransactionCompleteAlert {
	UIAlertController *alert = [MADAlertController newAlertControllerNofityTransactionComplete];

	XCTAssertEqualObjects(alert.title, @"Transaction Complete");
	XCTAssertEqualObjects(alert.message, @"Software activated.");
	XCTAssertEqual(alert.actions.count, (NSUInteger)1);
}

@end
#endif
