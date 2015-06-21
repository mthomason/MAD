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

@property (nonatomic, strong) NSString *bundleID;
@property (nonatomic, strong) NSString *purcahseDate;
@property (nonatomic, strong) NSArray *inAppPurchases;

@end
