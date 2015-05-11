//
//  MTStoreKit.h
//  Reports
//
//  Created by Michael Thomason on 7/1/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTStoreKitController_h
#define Reports_MTStoreKitController_h

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

extern NSString * const MTStoreKitTransactionReceipt;
extern NSString * const MTStoreKitTransactionDate;
extern NSString * const MTStoreKitTransactionIdentifier;
extern NSString * const MTStoreKitTransactionsIdentifier;

//Keys returned by iTunes Receipt
extern NSString * const MTStoreKitIdentifierReceiptBid;
extern NSString * const MTStoreKitIdentifierReceiptBidData;
extern NSString * const MTStoreKitIdentifierReceiptVersion;

extern NSString * const MTStoreKitIdentifierReceiptOpaqueValue;

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
extern NSString * const MTStoreKitIdentifierReceiptCancellationDate;
extern NSString * const MTStoreKitIdentifierReceiptWebOrderLineItemID;
extern NSString * const MTStoreKitIdentifierReceiptSubscriptionExpirationDate;
extern NSString * const MTStoreKitIdentifierReceiptHash;
extern NSString * const MTStoreKitIdentifierReceiptInApp;
extern NSString * const MTStoreKitIdentifierReceiptOriginalVersion;
extern NSString * const MTStoreKitIdentifierReceiptExpirationDate;

typedef void (^MTBlockCompletion)(BOOL success, NSError *error);

@interface MTStoreKitController : NSObject

+ (MTStoreKitController *)sharedObject;

@property(nonatomic, readonly, retain) NSArray *products;

- (void)initalizeProductsWithIdentifiers:(NSArray *)productIdentifiers completion:(MTBlockCompletion)completion;
- (void)purchaseProductWithIdentifier:(SKProduct *)product completion:(MTBlockCompletion) completion;
- (void)restorePurchases:(MTBlockCompletion)completion;
+ (NSArray *)transactions;


@property (nonatomic, retain) NSDateFormatter *receiptDateFormatter;

//@property (nonatomic, assign) BOOL verifiedUser;
@property (nonatomic, retain) NSDate *verifiedExperationDate;

@end

#endif
