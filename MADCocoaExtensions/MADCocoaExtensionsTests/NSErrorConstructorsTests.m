//
//  NSErrorConstructorsTests.m
//  MADCocoaExtensionsTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for NSError (Constructors) -presentError:onViewController:completion:.
//
//  The nil-error path is fully deterministic (it calls back YES and presents
//  nothing).  The alert path is pinned through the state it leaves on the presenter:
//  the presentation style it sets, and the alert it hands to UIKit -- including the
//  underlying-error substitution, where the wrapped error's description and failure
//  reason win over the outer one's.  The presentation itself is not awaited; a
//  windowless presenter still records the call.
//

#import <XCTest/XCTest.h>

#import <UIKit/UIAlertController.h>
#import <UIKit/UIViewController.h>

#import <MADCocoaExtensions/NSError+Constructors.h>

#pragma mark - Test double

// Captures the alert instead of presenting it.  A windowless presenter's
// -presentedViewController does not reliably describe the alert the method built, so
// the double records the view controller it was handed and lets the assertions read
// the real object.  -modalPresentationStyle is still set by the code under test on
// this same object, so that side effect is pinned too.
@interface MADCapturingPresenter : UIViewController
@property (nonatomic, strong) UIViewController *capturedViewController;
@end

@implementation MADCapturingPresenter
- (void)presentViewController:(UIViewController *)viewControllerToPresent
					 animated:(BOOL)flag
				   completion:(void (^)(void))completion {
	self.capturedViewController = viewControllerToPresent;
}
@end

@interface NSErrorConstructorsTests : XCTestCase
@end

@implementation NSErrorConstructorsTests

#pragma mark - Nil error

- (void)testNilErrorCallsBackYes {
	__block BOOL called = NO;
	__block BOOL success = NO;

	[NSError presentError:nil onViewController:nil completion:^(BOOL s) {
		called = YES;
		success = s;
	}];

	XCTAssertTrue(called);
	XCTAssertTrue(success);
}

- (void)testNilErrorWithNilCompletion {
	XCTAssertNoThrow([NSError presentError:nil onViewController:nil completion:nil]);
}

#pragma mark - Alert path

- (void)testErrorPresentsAnAlertOnTheGivenController {
	NSError *error = [NSError errorWithDomain:@"com.example.tests" code:1 userInfo:@{
		NSLocalizedDescriptionKey: @"Something went wrong",
		NSLocalizedFailureReasonErrorKey: @"Because testing.",
	}];
	MADCapturingPresenter *presenter = [[MADCapturingPresenter alloc] init];

	[NSError presentError:error onViewController:presenter completion:nil];

	XCTAssertEqual(presenter.modalPresentationStyle, UIModalPresentationOverCurrentContext);
	XCTAssertTrue([presenter.capturedViewController isKindOfClass:[UIAlertController class]]);
	UIAlertController *alert = (UIAlertController *)presenter.capturedViewController;
	XCTAssertEqualObjects(alert.title, @"Because testing.");
	XCTAssertEqualObjects(alert.message, @"Something went wrong");
	XCTAssertEqual(alert.actions.count, (NSUInteger)1);
	XCTAssertEqualObjects(alert.actions.firstObject.title, @"Dismiss");
}

- (void)testUnderlyingErrorWinsOverTheOuterError {
	NSError *underlying = [NSError errorWithDomain:@"com.example.tests" code:2 userInfo:@{
		NSLocalizedDescriptionKey: @"Inner description",
		NSLocalizedFailureReasonErrorKey: @"Inner reason.",
	}];
	NSError *outer = [NSError errorWithDomain:@"com.example.tests" code:1 userInfo:@{
		NSLocalizedDescriptionKey: @"Outer description",
		NSLocalizedFailureReasonErrorKey: @"Outer reason.",
		NSUnderlyingErrorKey: underlying,
	}];
	MADCapturingPresenter *presenter = [[MADCapturingPresenter alloc] init];

	[NSError presentError:outer onViewController:presenter completion:nil];

	UIAlertController *alert = (UIAlertController *)presenter.capturedViewController;
	XCTAssertEqualObjects(alert.title, @"Inner reason.");
	XCTAssertEqualObjects(alert.message, @"Inner description");
}

@end
