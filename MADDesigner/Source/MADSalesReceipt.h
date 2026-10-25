//
//  MADReceipt.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/16/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADSalesReceipt_h
#define MAD_Designer_MADSalesReceipt_h

#import <Foundation/NSObject.h>

@class NSUUID;

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

#endif
