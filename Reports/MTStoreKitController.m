//
//  MTStoreKit.m
//  Reports
//
//  Created by Michael Thomason on 7/1/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTStoreKitController.h"

NSString * const MTStoreKitTransactionReceipt       = @"MTStoreKitTransactionReceipt";
NSString * const MTStoreKitTransactionDate          = @"MTStoreKitTransactionDate";
NSString * const MTStoreKitTransactionIdentifier    = @"MTStoreKitTransactionIdentifier";
NSString * const MTStoreKitTransactionsIdentifier   = @"MTStoreKitTransactionsIdentifier";

//Keys returned by iTunes
NSString * const MTStoreKitIdentifierReceiptBid                     = @"bid";
NSString * const MTStoreKitIdentifierReceiptBrvs                    = @"brvs";
NSString * const MTStoreKitIdentifierReceiptQuantity                = @"quantity";
NSString * const MTStoreKitIdentifierReceiptItemId                  = @"item-id";
NSString * const MTStoreKitIdentifierReceiptOriginalPurchaseDate    = @"original-purchase-date";
NSString * const MTStoreKitIdentifierReceiptOriginalPurchaseDateMs  = @"original-purchase-date-ms";
NSString * const MTStoreKitIdentifierReceiptOriginalPurchaseDatePst = @"original-purchase-date-pst";
NSString * const MTStoreKitIdentifierReceiptOriginalTransactionId   = @"original-transaction-id";
NSString * const MTStoreKitIdentifierReceiptProductId               = @"product-id";
NSString * const MTStoreKitIdentifierReceiptPurchaseDate            = @"purchase-date";
NSString * const MTStoreKitIdentifierReceiptPurchaseDateMs          = @"purchase-date-ms";
NSString * const MTStoreKitIdentifierReceiptPurchaseDatePst         = @"purchase-date-pst";
NSString * const MTStoreKitIdentifierReceiptTransactionId           = @"transaction-id";
NSString * const MTStoreKitIdentifierReceiptUniqueId                = @"unique-identifier";

@interface MTStoreKitController ()
    <SKPaymentTransactionObserver, SKProductsRequestDelegate>

@property(nonatomic, retain) NSArray *productIdentifiers;
@property(nonatomic, readwrite, retain) NSArray *products;

@property(copy) MTStoreKitPurchaseProductWithIdentifierCompletion    purchaseProductWithIdentifierCompletion;
@property(copy) MTStoreKitInitalizeProductsCompletion                initalizeProductsCompletion;

@end

@implementation MTStoreKitController

static MTStoreKitController *sharedSingleton = nil;

+ (void)initialize {
    static BOOL initialized = NO;
    if (initialized == NO) {
        initialized = YES;
        if (sharedSingleton == nil) {
            sharedSingleton = [[super allocWithZone:NULL] init];

            [[SKPaymentQueue defaultQueue] addTransactionObserver: sharedSingleton];
            [sharedSingleton setProductIdentifiers:nil];
            [sharedSingleton setProducts:nil];
            [sharedSingleton setInitalizeProductsCompletion:nil];
            [sharedSingleton setPurchaseProductWithIdentifierCompletion:nil];

        }
    }
}

+ (MTStoreKitController *)sharedObject {
    return sharedSingleton;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [[self sharedObject] retain];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;
}

- (oneway void)release { }

- (id)autorelease {
    return self;
}

#pragma mark - Methods

- (void)initalizeProductsWithIdentifiers:(NSArray *)productIdentifiers
                              completion:(MTStoreKitInitalizeProductsCompletion)completion {
    if ([self initalizeProductsCompletion] == nil && [[self products] count] == 0) {
        [self setInitalizeProductsCompletion:   [completion copy]];
        [self setProductIdentifiers:            productIdentifiers];
        NSSet *productIdSet = [NSSet setWithArray:[self productIdentifiers]];
        SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdSet];
        [request setDelegate:self];
        [request start];
    } else if ([[self products] count] == 0) {
        NSDictionary *errorInfo = @{NSLocalizedDescriptionKey :         @"Product Load Failed",
                                    NSLocalizedFailureReasonErrorKey :  @"Try again later."};
        completion(NO, [NSError errorWithDomain:@"MTStoreKitController" code:5 userInfo:errorInfo]);
    } else {
        completion(YES, nil);
    }
}

- (void)purchaseProductWithIdentifier:(SKProduct *)product
                           completion:(MTStoreKitPurchaseProductWithIdentifierCompletion) completion {
    [self setPurchaseProductWithIdentifierCompletion:[completion copy]];
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)restorePurchases {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

+ (NSArray *)transactions {
    NSUbiquitousKeyValueStore *defaultStore = [NSUbiquitousKeyValueStore defaultStore];
    return [[[defaultStore arrayForKey:MTStoreKitTransactionsIdentifier] retain] autorelease];
}

+ (void)archiveTransactionData:(NSDictionary *)transactionData {
    
    NSUbiquitousKeyValueStore *defaultStore = [NSUbiquitousKeyValueStore defaultStore];
    NSArray *transactionDatum = [defaultStore arrayForKey:MTStoreKitTransactionsIdentifier];
    
    NSMutableArray *updatedTransactionData = [[NSMutableArray alloc] initWithArray:transactionDatum];
    [updatedTransactionData addObject:transactionData];
    [defaultStore setArray:updatedTransactionData forKey:MTStoreKitTransactionsIdentifier];
    [updatedTransactionData release];
    
}

#pragma mark - SKRequestDelegate Protocol

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    if ([self initalizeProductsCompletion]) {
        [self initalizeProductsCompletion](NO, error);
        //[[self initalizeProductsCompletion] release];
        //[self setInitalizeProductsCompletion:nil];
    }
}

- (void)requestDidFinish:(SKRequest *)request {
    [self initalizeProductsCompletion](YES, nil);
}

#pragma mark - SKProductsRequestDelegate Protocol

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    [self setProducts: [response products]];
}

#pragma mark - SKPaymentTransactionObserver Protocol

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions {
    
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray *)downloads {
    
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {

    for (SKPaymentTransaction *transaction in transactions) {
		switch (transaction.transactionState) {
                
			case SKPaymentTransactionStatePurchasing:
				MTLog(@"SKPaymentTransactionStatePurchasing");
				break;
            
            case SKPaymentTransactionStatePurchased: {

				MTLog(@"SKPaymentTransactionStatePurchased %@", [[transaction payment] productIdentifier]);
                
                [[MTVerificationController sharedInstance] verifyPurchase:transaction completion:^(BOOL validTransaction, NSError *error, NSDictionary *receiptData, NSDate *purcahseDate) {
                    
                    if (validTransaction) {
                        NSDictionary *transactionData = @{MTStoreKitTransactionReceipt      : [transaction transactionReceipt],
                                                          MTStoreKitTransactionDate         : [transaction transactionDate],
                                                          MTStoreKitTransactionIdentifier   : [transaction transactionIdentifier]};
                        
                        NSMutableDictionary *completeTransactionData = [[NSMutableDictionary alloc] initWithDictionary:transactionData];
                        [receiptData enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                            [completeTransactionData setObject:obj forKey:key];
                        }];
                        [MTStoreKitController archiveTransactionData:completeTransactionData];
                        [completeTransactionData release];
                    }
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                    [self purchaseProductWithIdentifierCompletion](validTransaction, error);

                }];
				break;
            }

			case SKPaymentTransactionStateRestored: {
				MTLog(@"SKPaymentTransactionStateRestored %@", transaction);
				MTLog(@"SKPaymentTransactionStateRestored %@", transaction.payment);

                SKPaymentTransaction *origionalTransaction = [transaction originalTransaction];
                
                //Only finalize payment if able to save transaction data to iCloud
                NSUbiquitousKeyValueStore *defaultStore = [NSUbiquitousKeyValueStore defaultStore];
                NSDictionary *transactionData = @{MTStoreKitTransactionReceipt      : [origionalTransaction transactionReceipt],
                                                  MTStoreKitTransactionDate         : [origionalTransaction transactionDate],
                                                  MTStoreKitTransactionIdentifier   : [origionalTransaction transactionIdentifier]};
                NSArray *transactionDatum = [defaultStore arrayForKey:MTStoreKitTransactionsIdentifier];
                NSMutableArray *updatedTransactionData = [[NSMutableArray alloc] initWithArray:transactionDatum];
                [updatedTransactionData addObject:transactionData];
                [defaultStore setArray:updatedTransactionData forKey:MTStoreKitTransactionsIdentifier];
                [updatedTransactionData release];
                
                
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                
                for (id product in [self products]) {
                    MTLog(@"Product: %@", product);
                    if ([[[transaction payment] productIdentifier] isEqualToString:@"com.everydayapps.quotationary.export.email.csv"]) {
                        UIAlertView *av = [[UIAlertView alloc] initWithTitle: @"Item Enabled"
                                                                     message:@"Item Export to CSV is enabled."
                                                                    delegate:nil
                                                           cancelButtonTitle:nil
                                                           otherButtonTitles:@"Continue", nil];
                        [av show];
                        [av release];
                    }
                }
                
				break;
                
            }

			case SKPaymentTransactionStateFailed: {
                
                NSError *error = [transaction error];
                
                if (error != nil) {
                    if (error.code != SKErrorPaymentCancelled) {
                        MTLog(@"ERROR:\n%d\t\t%@\n\t\t\t%@\n\t\t\t%@", [error code], [error localizedDescription], [error localizedFailureReason], [error localizedRecoverySuggestion]);
                        if ([error code] != NSUserCancelledError) {
                            UIAlertView *av = [[UIAlertView alloc] initWithTitle: @"Error Occured"
                                                                         message:[error localizedDescription]
                                                                        delegate:nil
                                                               cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
                            [av show];
                            [av release];
                        }
                    }
                    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
                }
				break;
            }
			default:
				MTLog(@"Transaction State Not Found");
				break;
		}
	}
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    
}

@end
