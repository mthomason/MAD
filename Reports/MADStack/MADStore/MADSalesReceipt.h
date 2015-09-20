//
//  MADReceipt.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/16/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MADSalesReceipt : NSObject

- (instancetype)initWithPath:(NSString *)path;
- (BOOL)verifyReceiptWithBundleID:(NSString *)bundleID
                    bundleVersion:(NSString *)bundleVersion
                      andDeviceID:(NSUUID *)vendorUUID;

@property (nonatomic, assign, readonly, getter=isValidReceipt) BOOL validReceipt;
@property (readonly) NSString *bundleID;
@property (readonly) NSString *purcahseDate;
@property (readonly) NSArray *inAppPurchases;
@property (readonly) NSString *originalVersion;
@property (readonly) NSString *version;
@property (readonly) BOOL charterMembership;

@end
