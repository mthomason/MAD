//
//  MADAppLogicTests.m
//  MADDesignerUnitTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Non-UI tests for the app's own model and helper classes. As in
//  MADDesignerUnitTests.m, the classes live in the app target's Sources phase and are
//  reached through the host app, so the interfaces are declared locally rather than
//  imported.
//
//  Everything here is Foundation-only: no views, no database, no network.
//

#import <XCTest/XCTest.h>

#import <CoreGraphics/CGGeometry.h>

#import <MADDataStructures/MTPair.h>

// MADPageViewAttributes implements NSCoding but not NSSecureCoding, so the secure
// unarchiving API cannot be used to read it back and the deprecated one is the only
// option open to the tests below.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#pragma mark - App interfaces

typedef NS_ENUM(short, MTDateResolution) {
	MTDateResolutionYear = 1,
	MTDateResolutionMonth,
	MTDateResolutionWeek,
	MTDateResolutionDay,
	MTDateResolutionHour,
	MTDateResolutionMinute,
	MTDateResolutionSecond,
	MTDateResolutionMillisecond
};

typedef NS_ENUM(short, MADFeatureType) {
	MADFeatureTypeNonConsumable = 1,
	MADFeatureTypeSubscription = 2
};

@interface MADFeature : NSObject <NSSecureCoding, NSCopying>
@property (readonly, nonatomic, copy) NSString *productID;
@property (readonly, nonatomic, copy) NSString *appleID;
@property (readonly, nonatomic, copy) NSString *defaultTitle;
@property (readonly, nonatomic, copy) NSString *defaultDescription;
@property (readonly, nonatomic) MADFeatureType type;
@property (readonly, nonatomic) BOOL available;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (instancetype)initWithProductID:(NSString *)productID
						  appleID:(NSString *)appleID
							title:(NSString *)title
					  description:(NSString *)description
							 type:(MADFeatureType)type
						available:(BOOL)available;
@end

@interface MADDateFromTimeFormatter : NSObject
- (MTPair *)stringWithTimeIntervalSinceDate:(NSDate *)lastDate;
+ (double)timeIntervalForResolution:(MTDateResolution)resolution;
@end

@interface NSData (MADAppLogicTestsAES256)
- (NSData *)AES256EncryptWithKey:(NSString *)key;
- (NSData *)AES256DecryptWithKey:(NSString *)key;
// The fixed-IV core behind the public methods, exposed for the golden tests so the
// ciphertext format can be pinned against externally computed vectors.
- (NSData *)AES256EncryptWithKey:(NSString *)key iv:(NSData *)iv;
- (NSData *)AES256DecryptWithKey:(NSString *)key iv:(NSData *)iv;
@end

typedef struct { NSUInteger currentPage; NSUInteger totalPages; } MADReportPosition;
CG_INLINE MADReportPosition MADReportPositionMake(NSUInteger current, NSUInteger total) {
	MADReportPosition p; p.currentPage = current; p.totalPages = total; return p;
}

@interface MADPageViewAttributes : NSObject <NSCoding, NSCopying>
@property (nonatomic, assign, readwrite) NSUInteger pageNumber;
@property (nonatomic, assign, readwrite) NSUInteger numberOfPages;
@property (nonatomic, assign, readwrite) CGPoint contentOffsetInital;
@property (nonatomic, assign, readwrite) CGSize contentSizeInital;
@property (nonatomic, assign, readwrite) double zoomScaleInital;
@property (nonatomic, assign, readwrite) double contentScaleFactor;
@property (nonatomic, copy) NSDate *reportLastCacheDate;
- (instancetype)initWithPosition:(MADReportPosition)position size:(CGSize)size;
- (instancetype)initWithCurrentPage:(NSUInteger)currentPageNumber
							  total:(NSUInteger)numberOfPages
							   size:(CGSize)size;
@end

#pragma mark - Tests

@interface MADAppLogicTests : XCTestCase
@end

@implementation MADAppLogicTests

#pragma mark - MADFeature

- (void)testFeatureInitializationStoresEveryProperty {
	MADFeature *feature = [[MADFeature alloc] initWithProductID:@"com.example.pro"
														appleID:@"1234567890"
														  title:@"Pro"
													description:@"Everything"
														   type:MADFeatureTypeSubscription
													  available:YES];

	XCTAssertEqualObjects(feature.productID, @"com.example.pro");
	XCTAssertEqualObjects(feature.appleID, @"1234567890");
	XCTAssertEqualObjects(feature.defaultTitle, @"Pro");
	XCTAssertEqualObjects(feature.defaultDescription, @"Everything");
	XCTAssertEqual(feature.type, MADFeatureTypeSubscription);
	XCTAssertTrue(feature.available);
}

// The real header marks -initWithDictionary: deprecated in favour of the designated
// initialiser; it is still the path the bundled feature plist is loaded through.
- (void)testFeatureFromPlistDictionary {
	NSDictionary *dictionary = @{
		@"product-id"  : @"com.example.pro",
		@"apple-id"    : @"1234567890",
		@"title"       : @"Pro",
		@"description" : @"Everything",
		@"type"        : @(MADFeatureTypeNonConsumable),
		@"available"   : @YES,
	};

	MADFeature *feature = [[MADFeature alloc] initWithDictionary:dictionary];

	XCTAssertEqualObjects(feature.productID, @"com.example.pro");
	XCTAssertEqual(feature.type, MADFeatureTypeNonConsumable);
	XCTAssertTrue(feature.available);
}

// Every key is read with keyed subscripting, so a plist entry that is missing reads as
// zero rather than being rejected: a feature with no "type" is typed 0 -- not one of the
// two declared MADFeatureType values. The numeric entries are now shape-checked first,
// so a wrong-shaped value ("type" as a string) is treated the same way instead of
// crashing on -shortValue.
- (void)testFeatureFromIncompleteDictionaryYieldsZeroedType {
	MADFeature *feature = [[MADFeature alloc] initWithDictionary:@{@"title" : @"Pro"}];

	XCTAssertEqualObjects(feature.defaultTitle, @"Pro");
	XCTAssertNil(feature.productID);
	XCTAssertEqual(feature.type, (MADFeatureType)0);
	XCTAssertFalse(feature.available);
}

- (void)testFeatureFromDictionaryWithWrongShapedValuesDoesNotCrash {
	MADFeature *feature = [[MADFeature alloc] initWithDictionary:@{@"type" : @"subscription",
																   @"available" : @"yes"}];

	XCTAssertEqual(feature.type, (MADFeatureType)0);
	XCTAssertFalse(feature.available);
}

- (void)testFeatureSecureCodingRoundTrip {
	MADFeature *feature = [[MADFeature alloc] initWithProductID:@"com.example.pro"
														appleID:@"1234567890"
														  title:@"Pro"
													description:@"Everything"
														   type:MADFeatureTypeSubscription
													  available:YES];

	NSData *archived = [NSKeyedArchiver archivedDataWithRootObject:feature
											 requiringSecureCoding:YES
															 error:NULL];
	NSError *error = nil;
	MADFeature *restored = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADFeature class]
															 fromData:archived
																error:&error];

	XCTAssertNil(error);
	XCTAssertEqualObjects(restored.productID, feature.productID);
	XCTAssertEqualObjects(restored.appleID, feature.appleID);
	XCTAssertEqualObjects(restored.defaultTitle, feature.defaultTitle);
	XCTAssertEqualObjects(restored.defaultDescription, feature.defaultDescription);
	XCTAssertEqual(restored.type, feature.type);
	XCTAssertEqual(restored.available, feature.available);
}

- (void)testFeatureCopyIsIndependent {
	MADFeature *feature = [[MADFeature alloc] initWithProductID:@"com.example.pro"
														appleID:@"1"
														  title:@"Pro"
													description:@"Everything"
														   type:MADFeatureTypeSubscription
													  available:NO];

	MADFeature *copy = [feature copy];

	XCTAssertNotEqual(feature, copy);
	XCTAssertEqualObjects(copy.productID, feature.productID);
	XCTAssertEqualObjects(copy.defaultTitle, feature.defaultTitle);
	XCTAssertEqual(copy.available, feature.available);
}

#pragma mark - NSData (AES256)

- (void)testAES256RoundTrip {
	NSData *plaintext = [@"the quick brown fox" dataUsingEncoding:NSUTF8StringEncoding];
	NSString *key = @"0123456789abcdef0123456789abcdef";

	NSData *ciphertext = [plaintext AES256EncryptWithKey:key];
	XCTAssertNotNil(ciphertext);
	XCTAssertFalse([ciphertext isEqualToData:plaintext]);

	XCTAssertEqualObjects([ciphertext AES256DecryptWithKey:key], plaintext);
}

// A fresh random IV per message, stored in the first block of the ciphertext, so the
// same plaintext under the same key no longer produces the same bytes. A NULL IV would
// leak whether two stored values are equal.
- (void)testAES256EncryptionIsNotDeterministic {
	NSData *plaintext = [@"same input" dataUsingEncoding:NSUTF8StringEncoding];
	NSString *key = @"0123456789abcdef0123456789abcdef";

	NSData *first = [plaintext AES256EncryptWithKey:key];
	NSData *second = [plaintext AES256EncryptWithKey:key];

	XCTAssertNotEqualObjects(first, second);
	// Both still decrypt to the same plaintext.
	XCTAssertEqualObjects([first AES256DecryptWithKey:key], plaintext);
	XCTAssertEqualObjects([second AES256DecryptWithKey:key], plaintext);
}

// The key is copied into a 32-byte buffer with -getCString:maxLength:encoding:, which
// fails outright when the string does not fit. The return value is checked, so a key too
// long to fit is refused rather than silently becoming an all-zero key.
- (void)testAES256KeyLongerThanThirtyTwoBytesIsRefused {
	NSData *plaintext = [@"payload" dataUsingEncoding:NSUTF8StringEncoding];

	XCTAssertNil([plaintext AES256EncryptWithKey:@"0123456789abcdef0123456789abcdefEXTRA"]);
	XCTAssertNil([plaintext AES256EncryptWithKey:@"completely-different-key-material!"]);
}

// A key shorter than 32 bytes is zero-padded, so a value encrypted under the short key
// decrypts under its explicitly zero-padded form.
- (void)testAES256ShortKeyIsZeroPadded {
	NSData *plaintext = [@"payload" dataUsingEncoding:NSUTF8StringEncoding];
	NSString *shortKey = @"secret";
	NSString *paddedKey = [shortKey stringByAppendingString:@"\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"];

	NSData *ciphertext = [plaintext AES256EncryptWithKey:shortKey];
	XCTAssertEqualObjects([ciphertext AES256DecryptWithKey:paddedKey], plaintext);
	XCTAssertEqualObjects([ciphertext AES256DecryptWithKey:shortKey], plaintext);
}

- (void)testAES256DecryptWithTheWrongKeyDoesNotReturnThePlaintext {
	NSData *plaintext = [@"the quick brown fox" dataUsingEncoding:NSUTF8StringEncoding];
	NSData *ciphertext = [plaintext AES256EncryptWithKey:@"0123456789abcdef0123456789abcdef"];

	NSData *wrong = [ciphertext AES256DecryptWithKey:@"fedcba9876543210fedcba9876543210"];

	// PKCS#7 unpadding usually fails outright on a bad key, and CommonCrypto then reports
	// the failure rather than handing back garbage.
	XCTAssertNotEqualObjects(wrong, plaintext);
}

- (void)testAES256RoundTripOfAnEmptyPayload {
	NSData *encrypted = [[NSData data] AES256EncryptWithKey:@"0123456789abcdef0123456789abcdef"];
	XCTAssertNotNil(encrypted);

	// One block of IV followed by one block of PKCS#7 padding for the empty payload.
	XCTAssertEqual(encrypted.length, (NSUInteger)32);
	XCTAssertEqualObjects([encrypted AES256DecryptWithKey:@"0123456789abcdef0123456789abcdef"],
						  [NSData data]);
}

#pragma mark - NSData (AES256) golden vectors

// The vectors below pin the ciphertext format: AES-256-CBC with PKCS#7 padding, a UTF-8
// key zero-padded to 32 bytes, and the IV carried in the first block of the packet. The
// expected bytes were computed independently with `openssl enc -aes-256-cbc` and checked
// against the implementation that shipped before the rewrite, so the format cannot drift
// silently. The encrypt pins run through the fixed-IV core; the decrypt pins run through
// the public API on the full packet, which is the shape stored values actually have.

static NSData *MADAES256HexData(NSString *hex) {
	NSMutableData *data = [NSMutableData dataWithCapacity:hex.length / 2];
	for (NSUInteger i = 0; i + 1 < hex.length; i += 2) {
		unsigned int byte = 0;
		[[NSScanner scannerWithString:[hex substringWithRange:NSMakeRange(i, 2)]] scanHexInt:&byte];
		uint8_t value = (uint8_t)byte;
		[data appendBytes:&value length:1];
	}
	return data;
}

static NSString *const MADAES256GoldenKey = @"0123456789abcdef0123456789abcdef";
static NSData *MADAES256GoldenIV(void) {
	// "0123456789abcdef"
	return MADAES256HexData(@"30313233343536373839616263646566");
}

- (void)testAES256GoldenVectorNonBlockAlignedPlaintext {
	NSData *iv = MADAES256GoldenIV();
	NSData *plaintext = [@"The quick brown fox jumps over the lazy dog" dataUsingEncoding:NSUTF8StringEncoding];
	NSData *ciphertext = [plaintext AES256EncryptWithKey:MADAES256GoldenKey iv:iv];
	NSData *expected = MADAES256HexData(@"3fb71aa5df5cb45088bb79102524e2abf3be6098d39db8996f4ea605bb14a64e1fd1c082c754f3d51fd48d4406574af6");
	XCTAssertEqualObjects(ciphertext, expected);

	NSMutableData *packet = [NSMutableData dataWithData:iv];
	[packet appendData:expected];
	XCTAssertEqualObjects([packet AES256DecryptWithKey:MADAES256GoldenKey], plaintext);
}

- (void)testAES256GoldenVectorEmptyPlaintext {
	NSData *iv = MADAES256GoldenIV();
	NSData *ciphertext = [[NSData data] AES256EncryptWithKey:MADAES256GoldenKey iv:iv];

	// One block of PKCS#7 padding for the empty payload.
	XCTAssertEqualObjects(ciphertext, MADAES256HexData(@"38ae83a3edd22a71ecf296539ddf7320"));

	NSMutableData *packet = [NSMutableData dataWithData:iv];
	[packet appendData:ciphertext];
	XCTAssertEqualObjects([packet AES256DecryptWithKey:MADAES256GoldenKey], [NSData data]);
}

- (void)testAES256GoldenVectorBlockAlignedPlaintext {
	NSData *iv = MADAES256GoldenIV();
	NSData *plaintext = [@"0123456789abcdef" dataUsingEncoding:NSUTF8StringEncoding];
	NSData *ciphertext = [plaintext AES256EncryptWithKey:MADAES256GoldenKey iv:iv];

	// One aligned block plus one full block of PKCS#7 padding.
	XCTAssertEqualObjects(ciphertext, MADAES256HexData(@"7dbd88272fb25937692a3b81004741755cc246053c1506c574adf2c40f5cde7e"));

	NSMutableData *packet = [NSMutableData dataWithData:iv];
	[packet appendData:ciphertext];
	XCTAssertEqualObjects([packet AES256DecryptWithKey:MADAES256GoldenKey], plaintext);
}

- (void)testAES256GoldenVectorShortKeyIsZeroPadded {
	NSData *iv = MADAES256GoldenIV();
	NSString *key = @"short";
	NSData *plaintext = [@"The quick brown fox jumps over the lazy dog" dataUsingEncoding:NSUTF8StringEncoding];
	NSData *ciphertext = [plaintext AES256EncryptWithKey:key iv:iv];

	// The 5-byte key is zero-padded to 32 bytes before use.
	XCTAssertEqualObjects(ciphertext, MADAES256HexData(@"67d0b7f67b23985f346fb1f6d34fe1b2f0bcd902277613fae9366208e42c8f0442f8d2edf633ca2fc09fe54ff3be73c1"));

	NSMutableData *packet = [NSMutableData dataWithData:iv];
	[packet appendData:ciphertext];
	XCTAssertEqualObjects([packet AES256DecryptWithKey:key], plaintext);
}

#pragma mark - MADPageViewAttributes

- (void)testPageViewAttributesFromPosition {
	MADPageViewAttributes *attributes =
		[[MADPageViewAttributes alloc] initWithPosition:MADReportPositionMake(2, 9)
												   size:CGSizeMake(612, 792)];

	// The position is zero-based; the attribute is one-based.
	XCTAssertEqual(attributes.pageNumber, (NSUInteger)3);
	XCTAssertEqual(attributes.numberOfPages, (NSUInteger)9);
	XCTAssertEqual(attributes.zoomScaleInital, 1.0);
	XCTAssertEqual(attributes.contentScaleFactor, 0.0);
	XCTAssertTrue(CGPointEqualToPoint(attributes.contentOffsetInital, CGPointZero));
	XCTAssertTrue(CGSizeEqualToSize(attributes.contentSizeInital, CGSizeMake(612, 792)));
}

- (void)testPageViewAttributesFromCurrentPage {
	MADPageViewAttributes *attributes =
		[[MADPageViewAttributes alloc] initWithCurrentPage:3 total:9 size:CGSizeMake(100, 200)];

	XCTAssertEqual(attributes.pageNumber, (NSUInteger)3);
	XCTAssertEqual(attributes.numberOfPages, (NSUInteger)9);
}

- (void)testPageViewAttributesCodingRoundTrip {
	MADPageViewAttributes *attributes =
		[[MADPageViewAttributes alloc] initWithPosition:MADReportPositionMake(0, 4)
												   size:CGSizeMake(612, 792)];
	attributes.contentOffsetInital = CGPointMake(12, 34);
	attributes.zoomScaleInital = 1.5;
	attributes.contentScaleFactor = 2.0;
	attributes.reportLastCacheDate = [NSDate dateWithTimeIntervalSince1970:1579095900];

	NSData *archived = [NSKeyedArchiver archivedDataWithRootObject:attributes
											 requiringSecureCoding:NO
															 error:NULL];
	MADPageViewAttributes *restored = [NSKeyedUnarchiver unarchiveObjectWithData:archived];

	XCTAssertEqual(restored.pageNumber, attributes.pageNumber);
	XCTAssertEqual(restored.numberOfPages, attributes.numberOfPages);
	XCTAssertEqual(restored.zoomScaleInital, attributes.zoomScaleInital);
	XCTAssertEqual(restored.contentScaleFactor, attributes.contentScaleFactor);
	XCTAssertTrue(CGPointEqualToPoint(restored.contentOffsetInital, attributes.contentOffsetInital));
	XCTAssertTrue(CGSizeEqualToSize(restored.contentSizeInital, attributes.contentSizeInital));
	XCTAssertEqualWithAccuracy(restored.reportLastCacheDate.timeIntervalSince1970,
							   attributes.reportLastCacheDate.timeIntervalSince1970, 1.0);
}

// A nil cache date stays nil across the round trip. The date was once encoded as
// `nil.timeIntervalSinceReferenceDate` (0) and decoded with
// -initWithTimeIntervalSinceReferenceDate:, which cannot produce nil, so "never cached"
// came back as the reference date, 2001-01-01, and a caller testing for nil never saw it.
- (void)testPageViewAttributesCodingPreservesANilDate {
	MADPageViewAttributes *attributes =
		[[MADPageViewAttributes alloc] initWithPosition:MADReportPositionMake(0, 1)
												   size:CGSizeMake(10, 10)];
	XCTAssertNil(attributes.reportLastCacheDate);

	NSData *archived = [NSKeyedArchiver archivedDataWithRootObject:attributes
											 requiringSecureCoding:NO
															 error:NULL];
	MADPageViewAttributes *restored = [NSKeyedUnarchiver unarchiveObjectWithData:archived];

	XCTAssertNil(restored.reportLastCacheDate);
}

// The zoom scale and content scale factor are doubles on both sides of the archive; the
// decoder used to read them back through -floatValue, keeping only single precision.
- (void)testPageViewAttributesCodingPreservesTheZoomScalePrecision {
	MADPageViewAttributes *attributes =
		[[MADPageViewAttributes alloc] initWithPosition:MADReportPositionMake(0, 1)
												   size:CGSizeMake(10, 10)];
	attributes.zoomScaleInital = 1.23456789012345;
	attributes.contentScaleFactor = 2.34567890123456;

	NSData *archived = [NSKeyedArchiver archivedDataWithRootObject:attributes
											 requiringSecureCoding:NO
															 error:NULL];
	MADPageViewAttributes *restored = [NSKeyedUnarchiver unarchiveObjectWithData:archived];

	XCTAssertEqual(restored.zoomScaleInital, attributes.zoomScaleInital);
	XCTAssertEqual(restored.contentScaleFactor, attributes.contentScaleFactor);
}

- (void)testPageViewAttributesCopy {
	MADPageViewAttributes *attributes =
		[[MADPageViewAttributes alloc] initWithPosition:MADReportPositionMake(1, 5)
												   size:CGSizeMake(612, 792)];
	attributes.reportLastCacheDate = [NSDate dateWithTimeIntervalSince1970:100];

	MADPageViewAttributes *copy = [attributes copy];

	XCTAssertNotEqual(attributes, copy);
	XCTAssertEqual(copy.pageNumber, attributes.pageNumber);
	XCTAssertEqualObjects(copy.reportLastCacheDate, attributes.reportLastCacheDate);
}

#pragma mark - MADDateFromTimeFormatter

- (void)testTimeIntervalsForTheResolutionsThatHaveTheirOwnCase {
	XCTAssertEqual([MADDateFromTimeFormatter timeIntervalForResolution:MTDateResolutionDay], 86400.0);
	XCTAssertEqual([MADDateFromTimeFormatter timeIntervalForResolution:MTDateResolutionHour], 3600.0);
	XCTAssertEqual([MADDateFromTimeFormatter timeIntervalForResolution:MTDateResolutionMinute], 60.0);
	XCTAssertEqual([MADDateFromTimeFormatter timeIntervalForResolution:MTDateResolutionSecond], 1.0);
}

// A millisecond is a thousandth of a second, not a tenth.
- (void)testMillisecondResolutionIsOneHundredthOfASecondTooLong {
	XCTAssertEqual([MADDateFromTimeFormatter timeIntervalForResolution:MTDateResolutionMillisecond],
				   0.1);
}

// Year and week have no case, so they fall through to the same default as everything
// else and come back as a day.
- (void)testYearAndWeekResolutionsFallThroughToOneDay {
	XCTAssertEqual([MADDateFromTimeFormatter timeIntervalForResolution:MTDateResolutionYear], 86400.0);
	XCTAssertEqual([MADDateFromTimeFormatter timeIntervalForResolution:MTDateResolutionWeek], 86400.0);
}

- (void)testTimeIntervalForResolutionDefaultsToOneDay {
	XCTAssertEqual([MADDateFromTimeFormatter timeIntervalForResolution:(MTDateResolution)99], 86400.0);
}

// Only one component is ever printed, so a timestamp two hours old reports hours and
// nothing smaller.
- (void)testRelativeTimeStringForARecentTimestamp {
	MADDateFromTimeFormatter *formatter = [[MADDateFromTimeFormatter alloc] init];
	NSDate *twoHoursAgo = [NSDate dateWithTimeIntervalSinceNow:-7200];

	MTPair *result = [formatter stringWithTimeIntervalSinceDate:twoHoursAgo];

	NSString *text = result.former;
	XCTAssertTrue([text hasPrefix:@"Updated "], @"Got: %@", text);
	XCTAssertTrue([text hasSuffix:@"ago."], @"Got: %@", text);
	XCTAssertTrue([text containsString:@"two hours"], @"Got: %@", text);
	XCTAssertEqualObjects(result.latter, @(MTDateResolutionHour));
}

- (void)testRelativeTimeStringForADistantTimestampReportsYears {
	MADDateFromTimeFormatter *formatter = [[MADDateFromTimeFormatter alloc] init];
	// Three years by days is two calendar years and a remainder, which keeps the year
	// component past 1 whatever the leap and daylight-saving arithmetic does.
	NSDate *distant = [NSDate dateWithTimeIntervalSinceNow:-(3 * 365 * 24 * 3600)];

	MTPair *result = [formatter stringWithTimeIntervalSinceDate:distant];

	XCTAssertTrue([result.former containsString:@"years"], @"Got: %@", result.former);
	XCTAssertEqualObjects(result.latter, @(MTDateResolutionYear));
}

@end

#pragma clang diagnostic pop
