//
//  MADConnectionViewControllerTests.m
//  MADAPITests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Tier 3 coverage for the two connection view controllers.  The screens themselves
//  are storyboard-driven and their flows present alerts, so what is pinned here is the
//  deterministic contract both classes share: -databaseConnection is an override point
//  that throws on the abstract class, the transition-animator role they play for their
//  presenting controller, and the nil tolerance of the IB action helpers.  Properties
//  backing the storyboard (textFieldPort, textFields) are nil in a bare instance, which
//  is exactly the state the helpers must survive.
//

#import <XCTest/XCTest.h>
#include <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <MADAPI/MADConnectionViewController.h>
#import <MADAPI/MADConnectionSQLGenericViewController.h>

// The exit-handler actions are wired in the storyboard and declared only in the
// implementation file; this test-only category is the deliberate bridge (same pattern
// as MADFileUtilitiesTests).
@interface MADConnectionSQLGenericViewController (TestActions)
- (IBAction)hostDidEndOnExit:(id)sender;
- (IBAction)portDidEndOnExit:(id)sender;
@end

@interface MADConnectionViewControllerTests : XCTestCase
@end

@implementation MADConnectionViewControllerTests

#pragma mark - Abstract override point

// Both classes implement the override point as an abstract method that throws a real
// NSException named NSInternalInconsistencyException, matching MADDatabase's
// "subclass me" methods.  docs/project/BUGS.md used to record the name constant itself being
// thrown; this test is what pins the corrected shape.

- (void)testDatabaseConnectionThrowsOnBaseClass {
	MADConnectionViewController *controller = [[MADConnectionViewController alloc] initWithNibName:nil bundle:nil];
	@try {
		[controller databaseConnection];
		XCTFail(@"Expected -databaseConnection to throw");
	} @catch (NSException *exception) {
		XCTAssertEqualObjects(exception.name, NSInternalInconsistencyException);
		XCTAssertTrue([exception.reason containsString:@"MADConnectionViewController"]);
	}
}

- (void)testDatabaseConnectionThrowsOnSQLGenericClass {
	MADConnectionSQLGenericViewController *controller = [[MADConnectionSQLGenericViewController alloc] initWithNibName:nil bundle:nil];
	@try {
		[controller databaseConnection];
		XCTFail(@"Expected -databaseConnection to throw");
	} @catch (NSException *exception) {
		XCTAssertEqualObjects(exception.name, NSInternalInconsistencyException);
		XCTAssertTrue([exception.reason containsString:@"MADConnectionSQLGenericViewController"]);
	}
}

#pragma mark - Transition animator

// Both classes play the animator role for the controller they present, declared via
// private extensions; the public protocols are the visible half of that contract.

- (void)testTransitionDuration {
	MADConnectionViewController *base = [[MADConnectionViewController alloc] initWithNibName:nil bundle:nil];
	id <UIViewControllerAnimatedTransitioning> baseAnimator = (id <UIViewControllerAnimatedTransitioning>)base;
	XCTAssertEqual([baseAnimator transitionDuration:(id <UIViewControllerContextTransitioning>)base], 0.4);

	MADConnectionSQLGenericViewController *sql = [[MADConnectionSQLGenericViewController alloc] initWithNibName:nil bundle:nil];
	id <UIViewControllerAnimatedTransitioning> sqlAnimator = (id <UIViewControllerAnimatedTransitioning>)sql;
	XCTAssertEqual([sqlAnimator transitionDuration:(id <UIViewControllerContextTransitioning>)sql], 0.4);
}

- (void)testPresentedControllerAnimatorIsSelf {
	MADConnectionViewController *base = [[MADConnectionViewController alloc] initWithNibName:nil bundle:nil];
	id <UIViewControllerTransitioningDelegate> baseDelegate = (id <UIViewControllerTransitioningDelegate>)base;
	// The delegate ignores these arguments; real controllers keep the nonnull contract.
	id baseAnimator = [baseDelegate animationControllerForPresentedController:base
														 presentingController:base
															 sourceController:base];
	XCTAssertEqual(baseAnimator, base);

	MADConnectionSQLGenericViewController *sql = [[MADConnectionSQLGenericViewController alloc] initWithNibName:nil bundle:nil];
	id <UIViewControllerTransitioningDelegate> sqlDelegate = (id <UIViewControllerTransitioningDelegate>)sql;
	id sqlAnimator = [sqlDelegate animationControllerForPresentedController:sql
														presentingController:sql
															sourceController:sql];
	XCTAssertEqual(sqlAnimator, sql);
}

- (void)testDismissedControllerAnimatorIsNil {
	MADConnectionViewController *base = [[MADConnectionViewController alloc] initWithNibName:nil bundle:nil];
	id <UIViewControllerTransitioningDelegate> baseDelegate = (id <UIViewControllerTransitioningDelegate>)base;
	XCTAssertNil([baseDelegate animationControllerForDismissedController:base]);

	MADConnectionSQLGenericViewController *sql = [[MADConnectionSQLGenericViewController alloc] initWithNibName:nil bundle:nil];
	id <UIViewControllerTransitioningDelegate> sqlDelegate = (id <UIViewControllerTransitioningDelegate>)sql;
	XCTAssertNil([sqlDelegate animationControllerForDismissedController:sql]);
}

- (void)testInteractiveTransitionControllersAreNil {
	MADConnectionViewController *base = [[MADConnectionViewController alloc] initWithNibName:nil bundle:nil];
	id <UIViewControllerTransitioningDelegate> baseDelegate = (id <UIViewControllerTransitioningDelegate>)base;
	id <UIViewControllerAnimatedTransitioning> baseAnimator = (id <UIViewControllerAnimatedTransitioning>)base;
	XCTAssertNil([baseDelegate interactionControllerForDismissal:baseAnimator]);
	XCTAssertNil([baseDelegate interactionControllerForPresentation:baseAnimator]);

	MADConnectionSQLGenericViewController *sql = [[MADConnectionSQLGenericViewController alloc] initWithNibName:nil bundle:nil];
	id <UIViewControllerTransitioningDelegate> sqlDelegate = (id <UIViewControllerTransitioningDelegate>)sql;
	id <UIViewControllerAnimatedTransitioning> sqlAnimator = (id <UIViewControllerAnimatedTransitioning>)sql;
	XCTAssertNil([sqlDelegate interactionControllerForDismissal:sqlAnimator]);
	XCTAssertNil([sqlDelegate interactionControllerForPresentation:sqlAnimator]);
}

#pragma mark - IB action helpers tolerate an unloaded storyboard

- (void)testHostDidEndOnExitWithNilPortDoesNotThrow {
	// textFieldPort is a storyboard outlet; with it nil the focus hand-off is skipped.
	MADConnectionSQLGenericViewController *controller = [[MADConnectionSQLGenericViewController alloc] initWithNibName:nil bundle:nil];
	XCTAssertNoThrow([controller hostDidEndOnExit:nil]);
}

- (void)testPortDidEndOnExitWithNilPortDoesNotThrow {
	MADConnectionSQLGenericViewController *controller = [[MADConnectionSQLGenericViewController alloc] initWithNibName:nil bundle:nil];
	XCTAssertNoThrow([controller portDidEndOnExit:nil]);
}

- (void)testEnableAndDisableTextFieldsWithoutOutletsDoesNotThrow {
	MADConnectionViewController *base = [[MADConnectionViewController alloc] initWithNibName:nil bundle:nil];
	XCTAssertNoThrow([base disableTextFields]);
	XCTAssertNoThrow([base enableTextFields]);

	MADConnectionSQLGenericViewController *sql = [[MADConnectionSQLGenericViewController alloc] initWithNibName:nil bundle:nil];
	XCTAssertNoThrow([sql disableTextFields]);
	XCTAssertNoThrow([sql enableTextFields]);
}

@end
#endif
