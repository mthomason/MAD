//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADStorageStateTests.m
//  Linux/Tests
//
//  Ported from MADFileManagerTests/MADStorageStateTests.m: MADStorageState, a
//  plain value object carrying the storage location plus two iCloud flags.
//

#import "MADTestSupport.h"
#import <MADFileManager/MADStorageState.h>

static void testDefaults(void) {
	MADStorageState *state = [[MADStorageState alloc] init];
	MAD_PASS(state.storageOption == MADAppStorageNotSet, "storage option defaults to NotSet");
	MAD_PASS(!state.accountDidChange, "accountDidChange defaults to NO");
	MAD_PASS(!state.cloudAvailable, "cloudAvailable defaults to NO");
}

static void testSetters(void) {
	MADStorageState *state = [[MADStorageState alloc] init];
	state.storageOption = MADAppStorageCloud;
	state.accountDidChange = YES;
	state.cloudAvailable = YES;

	MAD_PASS(state.storageOption == MADAppStorageCloud, "storage option round trips");
	MAD_PASS(state.accountDidChange, "accountDidChange round trips");
	MAD_PASS(state.cloudAvailable, "cloudAvailable round trips");
}

MAD_TEST_MAIN("MADStorageStateTests",
	MAD_TEST(testDefaults),
	MAD_TEST(testSetters));
