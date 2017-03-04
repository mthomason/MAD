//
//  MADReceipt.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/16/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADSalesReceipt.h"

#include <openssl/pkcs7.h>
#include <openssl/objects.h>
#include <openssl/sha.h>
#include <openssl/x509.h>
#include <err.h>

#import <Security/Security.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSData.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSString.h>
#import <Foundation/NSUUID.h>
#import <Foundation/NSPathUtilities.h>

#define VRCFRelease(object) if(object) CFRelease(object)

// ASN.1 values for In-App Purchase values
#define INAPP_ATTR_START	1700
#define INAPP_QUANTITY		1701
#define INAPP_PRODID		1702
#define INAPP_TRANSID		1703
#define INAPP_PURCHDATE		1704
#define INAPP_ORIGTRANSID	1705
#define INAPP_ORIGPURCHDATE	1706
#define INAPP_ATTR_END		1707
#define INAPP_SUBEXP_DATE   1708
#define INAPP_WEBORDER      1711
#define INAPP_CANCEL_DATE   1712

// ASN.1 values for the App Store receipt
#define ATTR_START 1
#define BUNDLE_ID 2
#define VERSION 3
#define OPAQUE_VALUE 4
#define HASH 5
#define ATTR_END 6
#define INAPP_PURCHASE 17
#define ORIG_VERSION 19
#define EXPIRE_DATE 21

unsigned int iTS_intermediate_cert_der_len = 1039;

unsigned char iTS_intermediate_cert_der[] = {
    0x30, 0x82, 0x04, 0x0b, 0x30, 0x82, 0x02, 0xf3, 0xa0, 0x03, 0x02, 0x01,
    0x02, 0x02, 0x01, 0x1a, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
    0xf7, 0x0d, 0x01, 0x01, 0x05, 0x05, 0x00, 0x30, 0x62, 0x31, 0x0b, 0x30,
    0x09, 0x06, 0x03, 0x55, 0x04, 0x06, 0x13, 0x02, 0x55, 0x53, 0x31, 0x13,
    0x30, 0x11, 0x06, 0x03, 0x55, 0x04, 0x0a, 0x13, 0x0a, 0x41, 0x70, 0x70,
    0x6c, 0x65, 0x20, 0x49, 0x6e, 0x63, 0x2e, 0x31, 0x26, 0x30, 0x24, 0x06,
    0x03, 0x55, 0x04, 0x0b, 0x13, 0x1d, 0x41, 0x70, 0x70, 0x6c, 0x65, 0x20,
    0x43, 0x65, 0x72, 0x74, 0x69, 0x66, 0x69, 0x63, 0x61, 0x74, 0x69, 0x6f,
    0x6e, 0x20, 0x41, 0x75, 0x74, 0x68, 0x6f, 0x72, 0x69, 0x74, 0x79, 0x31,
    0x16, 0x30, 0x14, 0x06, 0x03, 0x55, 0x04, 0x03, 0x13, 0x0d, 0x41, 0x70,
    0x70, 0x6c, 0x65, 0x20, 0x52, 0x6f, 0x6f, 0x74, 0x20, 0x43, 0x41, 0x30,
    0x1e, 0x17, 0x0d, 0x30, 0x39, 0x30, 0x35, 0x31, 0x39, 0x31, 0x38, 0x33,
    0x31, 0x33, 0x30, 0x5a, 0x17, 0x0d, 0x31, 0x36, 0x30, 0x35, 0x31, 0x38,
    0x31, 0x38, 0x33, 0x31, 0x33, 0x30, 0x5a, 0x30, 0x7f, 0x31, 0x0b, 0x30,
    0x09, 0x06, 0x03, 0x55, 0x04, 0x06, 0x13, 0x02, 0x55, 0x53, 0x31, 0x13,
    0x30, 0x11, 0x06, 0x03, 0x55, 0x04, 0x0a, 0x0c, 0x0a, 0x41, 0x70, 0x70,
    0x6c, 0x65, 0x20, 0x49, 0x6e, 0x63, 0x2e, 0x31, 0x26, 0x30, 0x24, 0x06,
    0x03, 0x55, 0x04, 0x0b, 0x0c, 0x1d, 0x41, 0x70, 0x70, 0x6c, 0x65, 0x20,
    0x43, 0x65, 0x72, 0x74, 0x69, 0x66, 0x69, 0x63, 0x61, 0x74, 0x69, 0x6f,
    0x6e, 0x20, 0x41, 0x75, 0x74, 0x68, 0x6f, 0x72, 0x69, 0x74, 0x79, 0x31,
    0x33, 0x30, 0x31, 0x06, 0x03, 0x55, 0x04, 0x03, 0x0c, 0x2a, 0x41, 0x70,
    0x70, 0x6c, 0x65, 0x20, 0x69, 0x54, 0x75, 0x6e, 0x65, 0x73, 0x20, 0x53,
    0x74, 0x6f, 0x72, 0x65, 0x20, 0x43, 0x65, 0x72, 0x74, 0x69, 0x66, 0x69,
    0x63, 0x61, 0x74, 0x69, 0x6f, 0x6e, 0x20, 0x41, 0x75, 0x74, 0x68, 0x6f,
    0x72, 0x69, 0x74, 0x79, 0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09,
    0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03,
    0x82, 0x01, 0x0f, 0x00, 0x30, 0x82, 0x01, 0x0a, 0x02, 0x82, 0x01, 0x01,
    0x00, 0xa4, 0xbc, 0xaf, 0x32, 0x94, 0x43, 0x3e, 0x0b, 0xbc, 0x37, 0x87,
    0xcd, 0x63, 0x89, 0xf2, 0xcc, 0xd9, 0xbe, 0x20, 0x4d, 0x5a, 0xb4, 0xfe,
    0x87, 0x67, 0xd2, 0x9a, 0xde, 0x1a, 0x54, 0x9d, 0xa2, 0xf3, 0xdf, 0x87,
    0xe4, 0x4c, 0xcb, 0x93, 0x11, 0x78, 0xa0, 0x30, 0x8f, 0x34, 0x41, 0xc1,
    0xd3, 0xbe, 0x66, 0x6d, 0x47, 0x6c, 0x98, 0xb8, 0xec, 0x7a, 0xd5, 0xc9,
    0xdd, 0xa5, 0xe4, 0xea, 0xc6, 0x70, 0xf4, 0x35, 0xd0, 0x91, 0xf7, 0xb3,
    0xd8, 0x0a, 0x11, 0x99, 0xab, 0x3a, 0x62, 0x3a, 0xbd, 0x7b, 0xf4, 0x56,
    0x4f, 0xdb, 0x9f, 0x24, 0x93, 0x51, 0x50, 0x7c, 0x20, 0xd5, 0x66, 0x4d,
    0x66, 0xf3, 0x18, 0xa4, 0x13, 0x96, 0x22, 0x16, 0xfd, 0x31, 0xa7, 0xf4,
    0x39, 0x66, 0x9b, 0xfb, 0x62, 0x69, 0x5c, 0x4b, 0x9f, 0x94, 0xa8, 0x4b,
    0xe8, 0xec, 0x5b, 0x64, 0x5a, 0x18, 0x79, 0x8a, 0x16, 0x75, 0x63, 0x42,
    0xa4, 0x49, 0xd9, 0x8c, 0x33, 0xde, 0xad, 0x7b, 0xd6, 0x39, 0x04, 0xf4,
    0xe2, 0x9d, 0x0a, 0x69, 0x8c, 0xeb, 0x4b, 0x12, 0x28, 0x4b, 0x34, 0x48,
    0x07, 0x9b, 0x0e, 0x59, 0xf9, 0x1f, 0x62, 0xb0, 0x03, 0x9f, 0x36, 0xb8,
    0x4e, 0xa3, 0xd3, 0x75, 0x59, 0xd4, 0xf3, 0x3a, 0x05, 0xca, 0xc5, 0x33,
    0x3b, 0xf8, 0xc0, 0x06, 0x09, 0x08, 0x93, 0xdb, 0xe7, 0x4d, 0xbf, 0x11,
    0xf3, 0x52, 0x2c, 0xa5, 0x16, 0x35, 0x15, 0xf3, 0x41, 0x02, 0xcd, 0x02,
    0xd1, 0xfc, 0xf5, 0xf8, 0xc5, 0x84, 0xbd, 0x63, 0x6a, 0x86, 0xd6, 0xb6,
    0x99, 0xf6, 0x86, 0xae, 0x5f, 0xfd, 0x03, 0xd4, 0x28, 0x8a, 0x5a, 0x5d,
    0xaf, 0xbc, 0x65, 0x74, 0xd1, 0xf7, 0x1a, 0xc3, 0x92, 0x08, 0xf4, 0x1c,
    0xad, 0x69, 0xe8, 0x02, 0x4c, 0x0e, 0x95, 0x15, 0x07, 0xbc, 0xbe, 0x6a,
    0x6f, 0xc1, 0xb3, 0xad, 0xa1, 0x02, 0x03, 0x01, 0x00, 0x01, 0xa3, 0x81,
    0xae, 0x30, 0x81, 0xab, 0x30, 0x0e, 0x06, 0x03, 0x55, 0x1d, 0x0f, 0x01,
    0x01, 0xff, 0x04, 0x04, 0x03, 0x02, 0x01, 0x86, 0x30, 0x0f, 0x06, 0x03,
    0x55, 0x1d, 0x13, 0x01, 0x01, 0xff, 0x04, 0x05, 0x30, 0x03, 0x01, 0x01,
    0xff, 0x30, 0x1d, 0x06, 0x03, 0x55, 0x1d, 0x0e, 0x04, 0x16, 0x04, 0x14,
    0x36, 0x1d, 0xe8, 0xe2, 0x9d, 0x82, 0xd2, 0x01, 0x18, 0xb5, 0x32, 0x6b,
    0x0e, 0xd7, 0x43, 0x0b, 0x91, 0x58, 0x43, 0x3a, 0x30, 0x1f, 0x06, 0x03,
    0x55, 0x1d, 0x23, 0x04, 0x18, 0x30, 0x16, 0x80, 0x14, 0x2b, 0xd0, 0x69,
    0x47, 0x94, 0x76, 0x09, 0xfe, 0xf4, 0x6b, 0x8d, 0x2e, 0x40, 0xa6, 0xf7,
    0x47, 0x4d, 0x7f, 0x08, 0x5e, 0x30, 0x36, 0x06, 0x03, 0x55, 0x1d, 0x1f,
    0x04, 0x2f, 0x30, 0x2d, 0x30, 0x2b, 0xa0, 0x29, 0xa0, 0x27, 0x86, 0x25,
    0x68, 0x74, 0x74, 0x70, 0x3a, 0x2f, 0x2f, 0x77, 0x77, 0x77, 0x2e, 0x61,
    0x70, 0x70, 0x6c, 0x65, 0x2e, 0x63, 0x6f, 0x6d, 0x2f, 0x61, 0x70, 0x70,
    0x6c, 0x65, 0x63, 0x61, 0x2f, 0x72, 0x6f, 0x6f, 0x74, 0x2e, 0x63, 0x72,
    0x6c, 0x30, 0x10, 0x06, 0x0a, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x63, 0x64,
    0x06, 0x02, 0x02, 0x04, 0x02, 0x05, 0x00, 0x30, 0x0d, 0x06, 0x09, 0x2a,
    0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x05, 0x05, 0x00, 0x03, 0x82,
    0x01, 0x01, 0x00, 0x75, 0xa6, 0x90, 0xe6, 0x9a, 0xa7, 0xdb, 0x65, 0x70,
    0xa6, 0x09, 0x93, 0x6f, 0x08, 0xdf, 0x2c, 0xdb, 0xe9, 0x28, 0x8d, 0x40,
    0x1b, 0x57, 0x5e, 0xa0, 0xea, 0xf4, 0xec, 0x13, 0x65, 0x1b, 0x71, 0x4a,
    0x4d, 0xdc, 0x80, 0x48, 0x4f, 0xf2, 0xe5, 0xa9, 0xfb, 0x85, 0x6c, 0xb7,
    0x1e, 0x9d, 0xdb, 0xf4, 0x18, 0x48, 0x10, 0x79, 0x17, 0xea, 0xc3, 0x3d,
    0x87, 0xd8, 0xb4, 0x79, 0x6d, 0x14, 0x50, 0xad, 0xd2, 0xbf, 0x3d, 0x4e,
    0xfc, 0x0d, 0xe2, 0xc5, 0x03, 0x94, 0x75, 0x80, 0x73, 0x4d, 0xa5, 0xa1,
    0x91, 0xfe, 0x1c, 0xde, 0x15, 0x17, 0xac, 0x89, 0x71, 0x2a, 0x6f, 0x0f,
    0x67, 0x0a, 0xd3, 0x9c, 0x30, 0xa1, 0x68, 0xfb, 0xcf, 0x70, 0x17, 0xca,
    0xd9, 0x40, 0xfc, 0xf8, 0x1b, 0xbf, 0xce, 0xb0, 0xc4, 0xae, 0xf4, 0x4a,
    0x2d, 0xa9, 0x99, 0x87, 0x06, 0x42, 0x09, 0x86, 0x22, 0x6a, 0x84, 0x40,
    0x39, 0xf4, 0xbb, 0xac, 0x56, 0x18, 0xf7, 0x9a, 0x1c, 0x01, 0x81, 0x5c,
    0x8c, 0x6e, 0x41, 0xf2, 0x5d, 0x19, 0x2c, 0x17, 0x1c, 0x49, 0x46, 0xd9,
    0x1c, 0x7e, 0x93, 0x12, 0x13, 0xc8, 0x67, 0x99, 0xc2, 0xea, 0x83, 0xe3,
    0xa2, 0x8c, 0x0e, 0xb8, 0x3b, 0x2a, 0xdf, 0x1c, 0xbf, 0x4b, 0x8b, 0x6f,
    0x1a, 0xb8, 0xee, 0x97, 0x67, 0x4a, 0xd8, 0xab, 0xaf, 0x8b, 0xa4, 0xda,
    0x5c, 0x87, 0x1e, 0x20, 0xb8, 0xc5, 0xf3, 0xb1, 0xc4, 0x98, 0xa2, 0x37,
    0xf8, 0x9e, 0xc6, 0x9a, 0x6b, 0xa5, 0xad, 0xf6, 0x78, 0x96, 0x0e, 0x82,
    0x8f, 0x04, 0x46, 0x1c, 0xb2, 0xa5, 0xfd, 0x9a, 0x30, 0x51, 0x28, 0xfd,
    0x52, 0x04, 0x15, 0x03, 0xd5, 0x3c, 0xad, 0xfe, 0xf6, 0x78, 0xe0, 0xea,
    0x35, 0xef, 0x65, 0xb5, 0x21, 0x76, 0xdb, 0xa4, 0xef, 0xcb, 0x72, 0xef,
    0x54, 0x6b, 0x01, 0x0d, 0xc7, 0xdd, 0x1a
};

static NSString * const MTStoreKitTransactionReceipt                           = @"MTStoreKitTransactionReceipt";
static NSString * const MTStoreKitTransactionDate                              = @"MTStoreKitTransactionDate";
static NSString * const MTStoreKitTransactionIdentifier                        = @"MTStoreKitTransactionIdentifier";
static NSString * const MTStoreKitTransactionsIdentifier                       = @"MTStoreKitTransactionsIdentifier";
static NSString * const MTStoreKitIdentifierReceiptVersion                     = @"version";
static NSString * const MTStoreKitIdentifierReceiptOriginalVersion             = @"ogversion";
static NSString * const MTStoreKitIdentifierReceiptOpaqueValue                 = @"opaquevalue";
static NSString * const MTStoreKitIdentifierReceiptBid                         = @"bid";
static NSString * const MTStoreKitIdentifierReceiptBidData                     = @"bid-data";
static NSString * const MTStoreKitIdentifierReceiptBrvs                        = @"brvs";
static NSString * const MTStoreKitIdentifierReceiptQuantity                    = @"quantity";
static NSString * const MTStoreKitIdentifierReceiptItemId                      = @"item-id";
static NSString * const MTStoreKitIdentifierReceiptOriginalPurchaseDate        = @"original-purchase-date";
static NSString * const MTStoreKitIdentifierReceiptOriginalPurchaseDateMs      = @"original-purchase-date-ms";
static NSString * const MTStoreKitIdentifierReceiptOriginalPurchaseDatePst     = @"original-purchase-date-pst";
static NSString * const MTStoreKitIdentifierReceiptOriginalTransactionId       = @"original-transaction-id";
static NSString * const MTStoreKitIdentifierReceiptProductId                   = @"product-id";
static NSString * const MTStoreKitIdentifierReceiptPurchaseDate                = @"purchase-date";
static NSString * const MTStoreKitIdentifierReceiptPurchaseDateMs              = @"purchase-date-ms";
static NSString * const MTStoreKitIdentifierReceiptPurchaseDatePst             = @"purchase-date-pst";
static NSString * const MTStoreKitIdentifierReceiptTransactionId               = @"transaction-id";
static NSString * const MTStoreKitIdentifierReceiptUniqueId                    = @"unique-identifier";
static NSString * const MTStoreKitIdentifierReceiptCancellationDate            = @"cancellation-date";
static NSString * const MTStoreKitIdentifierReceiptWebOrderLineItemID          = @"web-item-id";
static NSString * const MTStoreKitIdentifierReceiptSubscriptionExpirationDate  = @"experaion-date-subscription";
static NSString * const MTStoreKitIdentifierReceiptExpirationDate              = @"experaion-date";
static NSString * const MTStoreKitIdentifierReceiptHash                        = @"hash";
static NSString * const MTStoreKitIdentifierReceiptInApp                       = @"inapppurchases";

@interface MADSalesReceipt ()

@property (nonatomic, assign, readwrite, getter=isValidReceipt) BOOL validReceipt;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSDictionary *data;

+ (NSData *)appleRootCert;

@end

@implementation MADSalesReceipt

- (NSString *)bundleID {
    NSString *bundleID = _data[MTStoreKitIdentifierReceiptBid];
    return bundleID.copy;
}

- (NSString *)purcahseDate {
    NSString *purchaseDate = _data[MTStoreKitIdentifierReceiptPurchaseDate];
    return purchaseDate.copy;
}

- (NSString *)version {
    NSString *version = _data[MTStoreKitIdentifierReceiptVersion];
    return  version.copy;
}

- (NSString *)originalVersion {
    NSString *originalVersion = _data[MTStoreKitIdentifierReceiptOriginalVersion];
    return originalVersion.copy;
}

- (BOOL)charterMembership {
    return [self.originalVersion compare:@"7.0.100" options:NSNumericSearch];
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        self.path = path;
    }
    return self;
}

+ (NSData *)appleRootCert {
    // Obtain the Apple Inc. root certificate from http://www.apple.com/certificateauthority/
    // Download the Apple Inc. Root Certificate
    //  ( http://www.apple.com/appleca/AppleIncRootCertificate.cer )
    // Add the AppleIncRootCertificate.cer to your app's resource bundle.
    NSURL *rootCertificate = [[NSBundle mainBundle] URLForResource:@"AppleIncRootCertificate"
                                                     withExtension:@"cer"];
    NSData *cert = [[NSData alloc] initWithContentsOfURL:rootCertificate.copy];
    return cert;
}

- (BOOL)verifyReceiptWithBundleID:(NSString *)bundleID bundleVersion:(NSString *)bundleVersion
                      andDeviceID:(NSUUID *)vendorUUID {
    BOOL validReceipt = NO;
    
    NSDictionary *receipt = dictionaryWithAppStoreReceipt(self.path);
    self.data = [[NSDictionary alloc] initWithDictionary: receipt];
    
    NSMutableData *hashData, *input, *hashReceiptData;
    
    NSString *bid, *version;
    id data;

    if (receipt == nil) goto END_verifyReceiptWithBundleID;
    
    unsigned char uuidBytes[16];
    [vendorUUID getUUIDBytes:uuidBytes];
    
    input = [[NSMutableData alloc] initWithBytes:uuidBytes length:sizeof(uuidBytes)];
    [input appendBytes:uuidBytes length:sizeof(uuidBytes)];
    
    data = receipt[MTStoreKitIdentifierReceiptOpaqueValue];
    [input appendData:data];

    data = receipt[MTStoreKitIdentifierReceiptBidData];
    [input appendData:data];
    
    hashData = [NSMutableData dataWithLength:SHA_DIGEST_LENGTH];
    
    SHA1(input.bytes, input.length, hashData.mutableBytes);
    
    bid = receipt[MTStoreKitIdentifierReceiptBid],
    version = receipt[MTStoreKitIdentifierReceiptVersion],
    hashReceiptData = receipt[MTStoreKitIdentifierReceiptHash];
    
    if ([bundleID isEqualToString:bid] &&
        [bundleVersion isEqualToString:version] &&
        [hashData isEqualToData:hashReceiptData]) {
        validReceipt = YES;
    } else {
        
        validReceipt = NO;
    }

END_verifyReceiptWithBundleID:;

    self.validReceipt = validReceipt;
    return validReceipt;
    
}

NSArray *parseInAppPurchasesData(NSData *inappData);
NSArray *parseInAppPurchasesData(NSData *inappData) {
    int type = 0;
    int xclass = 0;
    long length = 0;
    
    NSUInteger dataLenght = inappData.length;
    const uint8_t *p = inappData.bytes;
    
    const uint8_t *end = p + dataLenght;
    
    NSMutableArray *resultArray = [NSMutableArray array];
    
    while (p < end) {
        ASN1_get_object(&p, &length, &type, &xclass, end - p);
        
        const uint8_t *set_end = p + length;
        
        if(type != V_ASN1_SET) {
            break;
        }
        
        NSMutableDictionary *item = [[NSMutableDictionary alloc] initWithCapacity:6];
        
        while (p < set_end) {
            ASN1_get_object(&p, &length, &type, &xclass, set_end - p);
            if (type != V_ASN1_SEQUENCE) {
                break;
            }
            
            const uint8_t *seq_end = p + length;
            
            int attr_type = 0;
            int attr_version = 0;
            
            // Attribute type
            ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
            if (type == V_ASN1_INTEGER) {
                if(length == 1) {
                    attr_type = p[0];
                }
                else if(length == 2) {
                    attr_type = p[0] * 0x100 + p[1]
                    ;
                }
            }
            p += length;
            
            // Attribute version
            ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
            if (type == V_ASN1_INTEGER && length == 1) {
                // clang analyser hit (wontfix at the moment, since the code might come in handy later)
                // But if someone has a convincing case throwing that out, I might do so, Roddi
                attr_version = p[0];
            }
            p += length;
            
            // Only parse attributes we're interested in
            if ((attr_type > INAPP_ATTR_START && attr_type < INAPP_ATTR_END) || attr_type == INAPP_SUBEXP_DATE || attr_type == INAPP_WEBORDER || attr_type == INAPP_CANCEL_DATE) {
                NSString *key = nil;
                
                ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
                if (type == V_ASN1_OCTET_STRING) {
                    //NSData *data = [NSData dataWithBytes:p length:(NSUInteger)length];
                    
                    // Integers
                    if (attr_type == INAPP_QUANTITY || attr_type == INAPP_WEBORDER) {
                        int num_type = 0;
                        long num_length = 0;
                        const uint8_t *num_p = p;
                        ASN1_get_object(&num_p, &num_length, &num_type, &xclass, seq_end - num_p);
                        if (num_type == V_ASN1_INTEGER) {
                            NSUInteger quantity = 0;
                            if (num_length) {
                                quantity += num_p[0];
                                if (num_length > 1) {
                                    quantity += num_p[1] * 0x100;
                                    if (num_length > 2) {
                                        quantity += num_p[2] * 0x10000;
                                        if (num_length > 3) {
                                            quantity += num_p[3] * 0x1000000;
                                        }
                                    }
                                }
                            }
                            
                            NSNumber *num = [[NSNumber alloc] initWithUnsignedInteger: quantity];
                            if (attr_type == INAPP_QUANTITY) {
                                item[MTStoreKitIdentifierReceiptQuantity] = num;
                            } else if (attr_type == INAPP_WEBORDER) {
                                item[MTStoreKitIdentifierReceiptWebOrderLineItemID] = num;
                            }
                        }
                    }
                    
                    // Strings
                    if (attr_type == INAPP_PRODID ||
                        attr_type == INAPP_TRANSID ||
                        attr_type == INAPP_ORIGTRANSID ||
                        attr_type == INAPP_PURCHDATE ||
                        attr_type == INAPP_ORIGPURCHDATE ||
                        attr_type == INAPP_SUBEXP_DATE ||
                        attr_type == INAPP_CANCEL_DATE) {
                        
                        int str_type = 0;
                        long str_length = 0;
                        const uint8_t *str_p = p;
                        ASN1_get_object(&str_p, &str_length, &str_type, &xclass, seq_end - str_p);
                        if (str_type == V_ASN1_UTF8STRING) {
                            switch (attr_type) {
                                case INAPP_PRODID:
                                    key = MTStoreKitIdentifierReceiptProductId;
                                    break;
                                case INAPP_TRANSID:
                                    key = MTStoreKitIdentifierReceiptTransactionId;
                                    break;
                                case INAPP_ORIGTRANSID:
                                    key = MTStoreKitIdentifierReceiptOriginalTransactionId;
                                    break;
                            }
                            
                            if (key) {
                                NSString *string = [[NSString alloc] initWithBytes:str_p
                                                                            length:(NSUInteger)str_length
                                                                          encoding:NSUTF8StringEncoding];
                                item[key] = string;
                            }
                        }
                        if (str_type == V_ASN1_IA5STRING) {
                            switch (attr_type) {
                                case INAPP_PURCHDATE:
                                    key = MTStoreKitIdentifierReceiptPurchaseDate;
                                    break;
                                case INAPP_ORIGPURCHDATE:
                                    key = MTStoreKitIdentifierReceiptOriginalPurchaseDate;
                                    break;
                                case INAPP_SUBEXP_DATE:
                                    key = MTStoreKitIdentifierReceiptSubscriptionExpirationDate;
                                    break;
                                case INAPP_CANCEL_DATE:
                                    key = MTStoreKitIdentifierReceiptCancellationDate;
                                    break;
                            }
                            
                            if (key) {
                                NSString *string = [[NSString alloc] initWithBytes:str_p
                                                                            length:(NSUInteger)str_length
                                                                          encoding:NSASCIIStringEncoding];
                                item[key] = string;
                            }
                        }
                    }
                }
                
                p += length;
            }
            
            // Skip any remaining fields in this SEQUENCE
            while (p < seq_end) {
                ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
                p += length;
            }
        }
        
        // Skip any remaining fields in this SET
        while (p < set_end) {
            ASN1_get_object(&p, &length, &type, &xclass, set_end - p);
            p += length;
        }
        
        [resultArray addObject:item];
    }
    
    return resultArray;
}


NSDictionary *dictionaryWithAppStoreReceipt(NSString *receiptPath);
NSDictionary *dictionaryWithAppStoreReceipt(NSString *receiptPath) {
    NSData *rootCertData = [MADSalesReceipt appleRootCert];
    
    ERR_load_PKCS7_strings();
    ERR_load_X509_strings();
    OpenSSL_add_all_digests();
    
    // Expected input is a PKCS7 container with signed data containing
    // an ASN.1 SET of SEQUENCE structures. Each SEQUENCE contains
    // two INTEGERS and an OCTET STRING.
    
    const char *path = receiptPath.stringByStandardizingPath.fileSystemRepresentation;
    FILE *fp = fopen(path, "rb");
    if (fp == NULL) {
        return nil;
    }
    
    PKCS7 *p7 = d2i_PKCS7_fp(fp, NULL);
    fclose(fp);
    
    // Check if the receipt file was invalid (otherwise we go crashing and burning)
    if (p7 == NULL) {
        return nil;
    }
    
    if (!PKCS7_type_is_signed(p7)) {
        PKCS7_free(p7);
        return nil;
    }
    
    if (!PKCS7_type_is_data(p7->d.sign->contents)) {
        PKCS7_free(p7);
        return nil;
    }
    
    int verifyReturnValue = 0;
    X509_STORE *store = X509_STORE_new();
    if (store) {
        const uint8_t *data = (uint8_t *)(rootCertData.bytes);
        X509 *appleCA = d2i_X509(NULL, &data, (long)rootCertData.length);
        if (appleCA) {
            BIO *payload = BIO_new(BIO_s_mem());
            X509_STORE_add_cert(store, appleCA);
            
            if (payload) {
                verifyReturnValue = PKCS7_verify(p7,NULL,store,NULL,payload,0);
                BIO_free(payload);
            }
            
            X509_free(appleCA);
        }
        
        X509_STORE_free(store);
    }
    
    EVP_cleanup();
    
    if (verifyReturnValue != 1) {
        PKCS7_free(p7);
        return nil;
    }
    
    ASN1_OCTET_STRING *octets = p7->d.sign->contents->d.data;
    const uint8_t *p = octets->data;
    const uint8_t *end = p + octets->length;
    
    int type = 0;
    int xclass = 0;
    long length = 0;
    
    ASN1_get_object(&p, &length, &type, &xclass, end - p);
    if (type != V_ASN1_SET) {
        PKCS7_free(p7);
        return nil;
    }
    
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    
    while (p < end) {
        ASN1_get_object(&p, &length, &type, &xclass, end - p);
        if (type != V_ASN1_SEQUENCE) {
            break;
        }
        
        const uint8_t *seq_end = p + length;
        
        int attr_type = 0;
        int attr_version = 0;
        
        // Attribute type
        ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
        if (type == V_ASN1_INTEGER && length == 1) {
            attr_type = p[0];
        }
        p += length;
        
        // Attribute version
        ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
        if (type == V_ASN1_INTEGER && length == 1) {
            attr_version = p[0];
            attr_version = attr_version;
        }
        p += length;
        
        // Only parse attributes we're interested in
        //if ((attr_type > ATTR_START && attr_type < ATTR_END) || attr_type == INAPP_PURCHASE || attr_type == ORIG_VERSION || attr_type == EXPIRE_DATE) {
            NSString *key = nil;
            
            ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
            if (type == V_ASN1_OCTET_STRING) {
                NSData *data = [[NSData alloc] initWithBytes:p length:(NSUInteger)length];
                
                // Bytes
                if (attr_type == BUNDLE_ID || attr_type == OPAQUE_VALUE || attr_type == HASH) {
                    switch (attr_type) {
                        case BUNDLE_ID:
                            // This is included for hash generation
                            key = MTStoreKitIdentifierReceiptBidData;
                            break;
                        case OPAQUE_VALUE:
                            key = MTStoreKitIdentifierReceiptOpaqueValue;
                            break;
                        case HASH:
                            key = MTStoreKitIdentifierReceiptHash;
                            break;
                    }
                    if (key) {
                        info[key] = data;
                    }
                }
                
                // Strings
                if (attr_type == BUNDLE_ID || attr_type == VERSION || attr_type == ORIG_VERSION) {
                    int str_type = 0;
                    long str_length = 0;
                    const uint8_t *str_p = p;
                    ASN1_get_object(&str_p, &str_length, &str_type, &xclass, seq_end - str_p);
                    if (str_type == V_ASN1_UTF8STRING) {
                        switch (attr_type) {
                            case BUNDLE_ID:
                                key = MTStoreKitIdentifierReceiptBid;
                                break;
                            case VERSION:
                                key = MTStoreKitIdentifierReceiptVersion;
                                break;
                            case ORIG_VERSION:
                                key = MTStoreKitIdentifierReceiptOriginalVersion;
                                break;
                        }
                        
                        if (key) {
                            NSString *string = [[NSString alloc] initWithBytes: str_p
                                                                        length: (NSUInteger)str_length
                                                                      encoding: NSUTF8StringEncoding];
                            info[key] = string;
                        }
                    }
                }
                
                // In-App purchases
                if (attr_type == INAPP_PURCHASE) {
                    NSArray *inApp = parseInAppPurchasesData(data);
                    NSArray *current = info[MTStoreKitIdentifierReceiptInApp];
                    if (current) {
                        info[MTStoreKitIdentifierReceiptInApp] = [current arrayByAddingObjectsFromArray:inApp];
                    } else {
                        info[MTStoreKitIdentifierReceiptInApp] = inApp;
                    }
                }
            }
            p += length;
        //}
        
        // Skip any remaining fields in this SEQUENCE
        while (p < seq_end) {
            ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
            p += length;
        }
    }
    
    PKCS7_free(p7);
    
    return info;
}

- (NSArray *)inAppPurchases {
    if (!self.data) {
        return nil;
    }
    NSArray *purchases = self.data[MTStoreKitIdentifierReceiptInApp];
    return (!purchases || ![purchases isKindOfClass:[NSArray class]]) ? nil : purchases;
}

- (id)debugQuickLookObject {
    NSMutableString *result = [[NSMutableString alloc] initWithString:self.description];
    [result appendFormat:@"Displaying receipt at path:\n\t%@\n", self.path];
    [result appendString:@"------R E C E I P T------\n"];
    [result appendFormat:@"Hash:                        %@\n", self.data[MTStoreKitIdentifierReceiptHash]];
    [result appendFormat:@"Bid:                         %@\n", self.data[MTStoreKitIdentifierReceiptBid]];
    [result appendFormat:@"Bid data:                    %@\n", self.data[MTStoreKitIdentifierReceiptBidData]];
    [result appendFormat:@"Version:                     %@\n", self.data[MTStoreKitIdentifierReceiptVersion]];
    [result appendFormat:@"Origional version:           %@\n", self.data[MTStoreKitIdentifierReceiptOriginalVersion]];
    [result appendFormat:@"Origional purchase date:     %@\n", self.data[MTStoreKitIdentifierReceiptOriginalPurchaseDate]];
    [result appendFormat:@"Origional purchase date MS:  %@\n", self.data[MTStoreKitIdentifierReceiptOriginalPurchaseDateMs]];
    [result appendFormat:@"Origional purchase date PST: %@\n", self.data[MTStoreKitIdentifierReceiptOriginalPurchaseDatePst]];
    [result appendFormat:@"Experation date:             %@\n", self.data[MTStoreKitIdentifierReceiptExpirationDate]];
    [result appendFormat:@"In app purchases:            %@\n", self.data[MTStoreKitIdentifierReceiptInApp]];
    /*
    [self.data enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *debuggingString = [NSString stringWithFormat:@"%@\t\t\t%@\n", key, obj];
        [result appendString:debuggingString];
        if ([obj isKindOfClass:[NSDictionary class]]) {
            [obj enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                NSString *debuggingString = [NSString stringWithFormat:@"\t%@\t\t%@\n", key, obj];
                [result appendString:debuggingString];
            }];
        }
    }];*/
    [result appendString:@"----------E N D----------\n"];
    return result;
}

@end
