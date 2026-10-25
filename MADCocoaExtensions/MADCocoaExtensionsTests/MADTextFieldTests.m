//
//  MADTextFieldTests.m
//  MADCocoaExtensionsTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADTextField: the credential-entry preconfigured text-field pair.
//  The class is a pair of configuration blocks; each is applied to a caller-supplied
//  UITextField and pins the label, secure-entry flag, and the input affordances.
//

#import <XCTest/XCTest.h>

#import <UIKit/UITextField.h>
#import <UIKit/UILabel.h>

#import <MADCocoaExtensions/MADTextField.h>

@interface MADTextFieldTests : XCTestCase
@end

@implementation MADTextFieldTests

- (void)testInitProvidesBothHandlers {
	MADTextField *configure = [[MADTextField alloc] init];

	XCTAssertNotNil(configure.handleConfigureUsername);
	XCTAssertNotNil(configure.handleConfigurePassword);
}

- (void)testUsernameConfiguration {
	MADTextField *configure = [[MADTextField alloc] init];
	UITextField *textField = [[UITextField alloc] init];

	configure.handleConfigureUsername(textField);

	XCTAssertTrue([textField.leftView isKindOfClass:[UILabel class]]);
	XCTAssertEqualObjects(((UILabel *)textField.leftView).text, @"Username: ");
	XCTAssertFalse(textField.isSecureTextEntry);
	XCTAssertEqual(textField.leftViewMode, UITextFieldViewModeAlways);
	XCTAssertEqualObjects(textField.text, @"");
	XCTAssertEqual(textField.autocapitalizationType, UITextAutocapitalizationTypeNone);
	XCTAssertEqual(textField.clearButtonMode, UITextFieldViewModeAlways);
}

- (void)testPasswordConfiguration {
	MADTextField *configure = [[MADTextField alloc] init];
	UITextField *textField = [[UITextField alloc] init];

	configure.handleConfigurePassword(textField);

	XCTAssertTrue([textField.leftView isKindOfClass:[UILabel class]]);
	XCTAssertEqualObjects(((UILabel *)textField.leftView).text, @"Password: ");
	// The one field the password configuration must differ on.
	XCTAssertTrue(textField.isSecureTextEntry);
	XCTAssertEqual(textField.leftViewMode, UITextFieldViewModeAlways);
	XCTAssertEqualObjects(textField.text, @"");
	XCTAssertEqual(textField.autocapitalizationType, UITextAutocapitalizationTypeNone);
	XCTAssertEqual(textField.clearButtonMode, UITextFieldViewModeAlways);
}

@end
