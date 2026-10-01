//
//  MADAppLogicTests.m
//  MADDesignerUnitTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
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

// Every key is read with keyed subscripting and cast to NSNumber. A plist entry that is
// missing or the wrong shape therefore reads as zero rather than being rejected, so a
// feature with no "type" is typed 0 -- not one of the two declared MADFeatureType values.
- (void)testFeatureFromIncompleteDictionaryYieldsZeroedType {
	MADFeature *feature = [[MADFeature alloc] initWithDictionary:@{@"title" : @"Pro"}];

	XCTAssertEqualObjects(feature.defaultTitle, @"Pro");
	XCTAssertNil(feature.productID);
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

// The IV argument to CCCrypt is NULL, which CommonCrypto treats as an all-zero IV, so
// the same plaintext under the same key always produces the same ciphertext. The
// encryption leaks whether two stored values are equal.
- (void)testAES256EncryptionIsDeterministic {
	NSData *plaintext = [@"same input" dataUsingEncoding:NSUTF8StringEncoding];
	NSString *key = @"0123456789abcdef0123456789abcdef";

	XCTAssertEqualObjects([plaintext AES256EncryptWithKey:key],
						  [plaintext AES256EncryptWithKey:key]);
}

// The key is copied into a 32-byte zeroed buffer with -getCString:maxLength:encoding:,
// which fails outright when the string does not fit. Nothing checks the return value, so
// the buffer keeps the zeros it was filled with and the cipher runs on an all-zero key:
// a key too long to fit is silently no key at all, and two unrelated long keys encrypt
// identically.
- (void)testAES256KeyLongerThanThirtyTwoBytesCollapsesToAnAllZeroKey {
	NSData *plaintext = [@"payload" dataUsingEncoding:NSUTF8StringEncoding];

	NSData *fromOneLongKey = [plaintext AES256EncryptWithKey:@"0123456789abcdef0123456789abcdefEXTRA"];
	NSData *fromAnotherLongKey = [plaintext AES256EncryptWithKey:@"completely-different-key-material!"];
	NSData *fromTheZeroKey = [plaintext AES256EncryptWithKey:[@"" stringByPaddingToLength:32
																			   withString:@"\0"
																		  startingAtIndex:0]];

	XCTAssertEqualObjects(fromOneLongKey, fromAnotherLongKey);
	XCTAssertEqualObjects(fromOneLongKey, fromTheZeroKey);
}

// A key shorter than 32 bytes is zero-padded, so the short key and its explicitly
// zero-padded form agree too.
- (void)testAES256ShortKeyIsZeroPadded {
	NSData *plaintext = [@"payload" dataUsingEncoding:NSUTF8StringEncoding];
	NSString *shortKey = @"secret";
	NSString *paddedKey = [shortKey stringByAppendingString:@"\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"];

	XCTAssertEqualObjects([plaintext AES256EncryptWithKey:shortKey],
						  [plaintext AES256EncryptWithKey:paddedKey]);
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

	// PKCS#7 always adds a full block of padding, so empty input encrypts to one block.
	XCTAssertEqual(encrypted.length, (NSUInteger)16);
	XCTAssertEqualObjects([encrypted AES256DecryptWithKey:@"0123456789abcdef0123456789abcdef"],
						  [NSData data]);
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

// A nil cache date is encoded as `nil.timeIntervalSinceReferenceDate`, which is 0, and
// decoded with -initWithTimeIntervalSinceReferenceDate:, which cannot produce nil. The
// date therefore comes back as the reference date -- 2001-01-01 -- rather than as "never
// cached", and a caller that tests for nil will not see it.
- (void)testPageViewAttributesCodingTurnsANilDateIntoTheReferenceDate {
	MADPageViewAttributes *attributes =
		[[MADPageViewAttributes alloc] initWithPosition:MADReportPositionMake(0, 1)
												   size:CGSizeMake(10, 10)];
	XCTAssertNil(attributes.reportLastCacheDate);

	NSData *archived = [NSKeyedArchiver archivedDataWithRootObject:attributes
											 requiringSecureCoding:NO
															 error:NULL];
	MADPageViewAttributes *restored = [NSKeyedUnarchiver unarchiveObjectWithData:archived];

	XCTAssertNotNil(restored.reportLastCacheDate);
	XCTAssertEqualWithAccuracy(restored.reportLastCacheDate.timeIntervalSinceReferenceDate, 0.0, 0.001);
}

// The zoom scale is written as a double but read back through -floatValue, so it only
// survives to single precision.
- (void)testPageViewAttributesCodingNarrowsTheZoomScaleToFloat {
	MADPageViewAttributes *attributes =
		[[MADPageViewAttributes alloc] initWithPosition:MADReportPositionMake(0, 1)
												   size:CGSizeMake(10, 10)];
	attributes.zoomScaleInital = 1.23456789012345;

	NSData *archived = [NSKeyedArchiver archivedDataWithRootObject:attributes
											 requiringSecureCoding:NO
															 error:NULL];
	MADPageViewAttributes *restored = [NSKeyedUnarchiver unarchiveObjectWithData:archived];

	XCTAssertNotEqual(restored.zoomScaleInital, attributes.zoomScaleInital);
	XCTAssertEqualWithAccuracy(restored.zoomScaleInital, attributes.zoomScaleInital, 0.000001);
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
