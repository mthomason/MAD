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
#import "MTVerificationController.h"

extern NSString * const MTStoreKitTransactionReceipt;
extern NSString * const MTStoreKitTransactionDate;
extern NSString * const MTStoreKitTransactionIdentifier;
extern NSString * const MTStoreKitTransactionsIdentifier;

//Keys returned by iTunes Receipt
extern NSString * const MTStoreKitIdentifierReceiptBid;
extern NSString * const MTStoreKitIdentifierReceiptBrvs;
extern NSString * const MTStoreKitIdentifierReceiptQuantity;
extern NSString * const MTStoreKitIdentifierReceiptItemId;
extern NSString * const MTStoreKitIdentifierReceiptOriginalPurchaseDate;
extern NSString * const MTStoreKitIdentifierReceiptOriginalPurchaseDateMs;
extern NSString * const MTStoreKitIdentifierReceiptOriginalPurchaseDatePst;
extern NSString * const MTStoreKitIdentifierReceiptOriginalTransactionId;
extern NSString * const MTStoreKitIdentifierReceiptProductId;
extern NSString * const MTStoreKitIdentifierReceiptPurchaseDate;
extern NSString * const MTStoreKitIdentifierReceiptPurchaseDateMs;
extern NSString * const MTStoreKitIdentifierReceiptPurchaseDatePst;
extern NSString * const MTStoreKitIdentifierReceiptTransactionId;
extern NSString * const MTStoreKitIdentifierReceiptUniqueId;

typedef void (^MTBlockCompletion)(BOOL success, NSError *error);
//typedef void (^MTStoreKitPurchaseProductWithIdentifierCompletion)(BOOL success, NSError *error);
//typedef void (^MTStoreKitInitalizeProductsCompletion)(BOOL success, NSError *error);
//typedef void (^MTStoreKitRestoreProductsCompletion)(BOOL success, NSError *error);

@interface MTStoreKitController : NSObject

+ (MTStoreKitController *)sharedObject;

@property(nonatomic, readonly, retain) NSArray *products;

- (void)initalizeProductsWithIdentifiers:(NSArray *)productIdentifiers
                              completion:(MTBlockCompletion)completion;
- (void)purchaseProductWithIdentifier:(SKProduct *)product
                           completion:(MTBlockCompletion) completion;
- (void)restorePurchases:(MTBlockCompletion)completion;
+ (NSArray *)transactions;

@end
