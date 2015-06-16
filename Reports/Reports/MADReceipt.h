//
//  MADReceipt.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/16/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MADReceipt : NSObject

@property (readonly) NSArray *inAppPurchases;

- (instancetype)initWithPath:(NSString *)path;
- (BOOL)verifyReceiptWithBundleID:(NSString *)bundleID bundleVersion:(NSString *)bundleVersion andDeviceID:(NSUUID *)vendorUUID;

@end
