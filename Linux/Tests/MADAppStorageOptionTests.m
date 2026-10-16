//
//  MADAppStorageOptionTests.m
//  Linux/Tests
//
//  Ported from MADFileManagerTests/MADAppStorageOptionTests.m: the raw values
//  of the MADAppStorage enum, which are persisted storage-location state and
//  must not drift.
//

#import "MADTestSupport.h"
#import <MADFileManager/MADAppStorageOption.h>

static void testRawValues(void) {
	MAD_PASS(MADAppStorageNotSet == (MADAppStorage)0, "MADAppStorageNotSet is 0");
	MAD_PASS(MADAppStorageCloud == (MADAppStorage)1, "MADAppStorageCloud is 1");
	MAD_PASS(MADAppStorageLocal == (MADAppStorage)2, "MADAppStorageLocal is 2");
	MAD_PASS(MADAppStorageCloudButSignedOut == (MADAppStorage)3, "MADAppStorageCloudButSignedOut is 3");
	MAD_PASS(MADAppStorageStateUnknown == (MADAppStorage)4, "MADAppStorageStateUnknown is 4");
}

MAD_TEST_MAIN("MADAppStorageOptionTests",
	MAD_TEST(testRawValues));
