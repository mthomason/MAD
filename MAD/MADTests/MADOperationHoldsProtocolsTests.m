//
//  MADOperationHoldsProtocolsTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for the three "holder" protocols an operation adopts when it carries
//  credentials, a password, or a username for a dependent operation to read:
//
//    * MADOperationHoldsCredentialsProtocol
//    * MADOperationHoldsPasswordProtocol
//    * MADOperationHoldsUsernameProtocol
//
//  No class under MAD/Source conforms to them today.  The live adopters are the
//  credentials operations in MADDesigner/Source (MADOperationGetCredentials,
//  MADOperationPromptPassword, ...) and the CLI's MADCLICredentialsOperation,
//  none of which are compiled into this bundle, so a local adopter is used to
//  pin the protocol shapes themselves.  The consumer side that is in this
//  framework -- -[MADOperationCreateDocumentCreateDocument
//  getCredentialsForKey:] -- is covered in
//  MADOperationCreateDocumentCreateDocumentTests.m.
//

#import <XCTest/XCTest.h>

#import "MADOperationHoldsCredentialsProtocol.h"
#import "MADOperationHoldsPasswordProtocol.h"
#import "MADOperationHoldsUsernameProtocol.h"

#import <MADFoundation/MADCredential.h>

// The local adopter: if a required method or property is renamed in one of the
// headers, this no longer compiles.
@interface MADHoldsProtocolsTestOperation : NSObject
	<MADOperationHoldsCredentialsProtocol, MADOperationHoldsPasswordProtocol, MADOperationHoldsUsernameProtocol>

	@property (nonatomic, copy) MADCredential *credentials;
	@property (nonatomic, assign) BOOL gotCredentials;
	@property (nonatomic, assign) BOOL manuallyInputtedCredentials;
	@property (nonatomic, copy) NSString *password;
	@property (nonatomic, assign) BOOL gotPassword;
	@property (nonatomic, copy) NSString *username;
	@property (nonatomic, assign) BOOL gotUsername;

@end

@implementation MADHoldsProtocolsTestOperation
@end

@interface MADOperationHoldsProtocolsTests : XCTestCase
@end

@implementation MADOperationHoldsProtocolsTests

#pragma mark - MADOperationHoldsCredentialsProtocol

- (void)testCredentialsProtocolShape {
	MADHoldsProtocolsTestOperation *holder = [[MADHoldsProtocolsTestOperation alloc] init];

	XCTAssertTrue([holder conformsToProtocol:@protocol(MADOperationHoldsCredentialsProtocol)]);

	MADCredential *credential = [[MADCredential alloc] initWithUsername:@"user" andPassword:@"pass"];
	holder.credentials = credential;
	holder.gotCredentials = YES;
	holder.manuallyInputtedCredentials = YES;

	XCTAssertEqualObjects(holder.credentials.username, @"user");
	XCTAssertEqualObjects(holder.credentials.password, @"pass");
	XCTAssertTrue(holder.gotCredentials);
	XCTAssertTrue(holder.manuallyInputtedCredentials);
}

#pragma mark - MADOperationHoldsPasswordProtocol

- (void)testPasswordProtocolShape {
	MADHoldsProtocolsTestOperation *holder = [[MADHoldsProtocolsTestOperation alloc] init];

	XCTAssertTrue([holder conformsToProtocol:@protocol(MADOperationHoldsPasswordProtocol)]);

	holder.password = @"pass";
	holder.gotPassword = YES;

	XCTAssertEqualObjects(holder.password, @"pass");
	XCTAssertTrue(holder.gotPassword);
}

#pragma mark - MADOperationHoldsUsernameProtocol

- (void)testUsernameProtocolShape {
	MADHoldsProtocolsTestOperation *holder = [[MADHoldsProtocolsTestOperation alloc] init];

	XCTAssertTrue([holder conformsToProtocol:@protocol(MADOperationHoldsUsernameProtocol)]);

	holder.username = @"user";
	holder.gotUsername = YES;

	XCTAssertEqualObjects(holder.username, @"user");
	XCTAssertTrue(holder.gotUsername);
}

@end
