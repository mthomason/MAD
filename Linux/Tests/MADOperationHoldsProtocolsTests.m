//
//  MADOperationHoldsProtocolsTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADOperationHoldsProtocolsTests.m: the three
//  "holder" protocols an operation adopts when it carries credentials, a
//  password, or a username for a dependent operation to read.  The live adopters
//  are app-side, so a local adopter pins the protocol shapes: if a required
//  method or property is renamed in one of the headers, this no longer compiles.
//

#import "MADTestSupport.h"

#import <MAD/MADOperationHoldsCredentialsProtocol.h>
#import <MAD/MADOperationHoldsPasswordProtocol.h>
#import <MAD/MADOperationHoldsUsernameProtocol.h>

#import <MADFoundation/MADCredential.h>

// The local adopter.
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

#pragma mark - MADOperationHoldsCredentialsProtocol

static void testCredentialsProtocolShape(void) {
	MADHoldsProtocolsTestOperation *holder = [[MADHoldsProtocolsTestOperation alloc] init];

	MAD_PASS([holder conformsToProtocol:@protocol(MADOperationHoldsCredentialsProtocol)], "the adopter conforms");

	MADCredential *credential = [[MADCredential alloc] initWithUsername:@"user" andPassword:@"pass"];
	holder.credentials = credential;
	holder.gotCredentials = YES;
	holder.manuallyInputtedCredentials = YES;

	MAD_PASS_EQUAL(holder.credentials.username, @"user", "the credentials carry the username");
	MAD_PASS_EQUAL(holder.credentials.password, @"pass", "the credentials carry the password");
	MAD_PASS(holder.gotCredentials, "the got-credentials flag round-trips");
	MAD_PASS(holder.manuallyInputtedCredentials, "the manually-inputted flag round-trips");

	[credential release];
	[holder release];
}

#pragma mark - MADOperationHoldsPasswordProtocol

static void testPasswordProtocolShape(void) {
	MADHoldsProtocolsTestOperation *holder = [[MADHoldsProtocolsTestOperation alloc] init];

	MAD_PASS([holder conformsToProtocol:@protocol(MADOperationHoldsPasswordProtocol)], "the adopter conforms");

	holder.password = @"pass";
	holder.gotPassword = YES;

	MAD_PASS_EQUAL(holder.password, @"pass", "the password round-trips");
	MAD_PASS(holder.gotPassword, "the got-password flag round-trips");

	[holder release];
}

#pragma mark - MADOperationHoldsUsernameProtocol

static void testUsernameProtocolShape(void) {
	MADHoldsProtocolsTestOperation *holder = [[MADHoldsProtocolsTestOperation alloc] init];

	MAD_PASS([holder conformsToProtocol:@protocol(MADOperationHoldsUsernameProtocol)], "the adopter conforms");

	holder.username = @"user";
	holder.gotUsername = YES;

	MAD_PASS_EQUAL(holder.username, @"user", "the username round-trips");
	MAD_PASS(holder.gotUsername, "the got-username flag round-trips");

	[holder release];
}

MAD_TEST_MAIN("MADOperationHoldsProtocolsTests",
	MAD_TEST(testCredentialsProtocolShape),
	MAD_TEST(testPasswordProtocolShape),
	MAD_TEST(testUsernameProtocolShape));
