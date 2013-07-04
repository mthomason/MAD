//
//  MTStoreKit.h
//  Reports
//
//  Created by Michael Thomason on 7/1/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "MTLog.h"
#import "NSError+UserInterface.h"
#import "VerificationController.h"

typedef void (^MTStoreKitPurchaseProductWithIdentifierCompletion)(BOOL success, NSError *error);
typedef void (^MTStoreKitInitalizeProductsCompletion)(BOOL success, NSError *error);

@interface MTStoreKitController : NSObject

+ (MTStoreKitController *)sharedObject;

@property(nonatomic, readonly, retain) NSArray *products;

- (void)initalizeProductsWithIdentifiers:(NSArray *)productIdentifiers
                              completion:(MTStoreKitInitalizeProductsCompletion)completion;
- (void)purchaseProductWithIdentifier:(SKProduct *)product
                           completion:(MTStoreKitPurchaseProductWithIdentifierCompletion) completion;

@end
