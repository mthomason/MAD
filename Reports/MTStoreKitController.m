//
//  MTStoreKit.m
//  Reports
//
//  Created by Michael Thomason on 7/1/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTStoreKitController.h"
#import "AppDelegate.h"

NSString * const MTStoreKitTransactionReceipt                           = @"MTStoreKitTransactionReceipt";
NSString * const MTStoreKitTransactionDate                              = @"MTStoreKitTransactionDate";
NSString * const MTStoreKitTransactionIdentifier                        = @"MTStoreKitTransactionIdentifier";
NSString * const MTStoreKitTransactionsIdentifier                       = @"MTStoreKitTransactionsIdentifier";
NSString * const MTStoreKitIdentifierReceiptVersion                     = @"version";
NSString * const MTStoreKitIdentifierReceiptOriginalVersion             = @"ogversion";
NSString * const MTStoreKitIdentifierReceiptOpaqueValue                 = @"opaquevalue";
NSString * const MTStoreKitIdentifierReceiptBid                         = @"bid";
NSString * const MTStoreKitIdentifierReceiptBidData                     = @"bid-data";
NSString * const MTStoreKitIdentifierReceiptBrvs                        = @"brvs";
NSString * const MTStoreKitIdentifierReceiptQuantity                    = @"quantity";
NSString * const MTStoreKitIdentifierReceiptItemId                      = @"item-id";
NSString * const MTStoreKitIdentifierReceiptOriginalPurchaseDate        = @"original-purchase-date";
NSString * const MTStoreKitIdentifierReceiptOriginalPurchaseDateMs      = @"original-purchase-date-ms";
NSString * const MTStoreKitIdentifierReceiptOriginalPurchaseDatePst     = @"original-purchase-date-pst";
NSString * const MTStoreKitIdentifierReceiptOriginalTransactionId       = @"original-transaction-id";
NSString * const MTStoreKitIdentifierReceiptProductId                   = @"product-id";
NSString * const MTStoreKitIdentifierReceiptPurchaseDate                = @"purchase-date";
NSString * const MTStoreKitIdentifierReceiptPurchaseDateMs              = @"purchase-date-ms";
NSString * const MTStoreKitIdentifierReceiptPurchaseDatePst             = @"purchase-date-pst";
NSString * const MTStoreKitIdentifierReceiptTransactionId               = @"transaction-id";
NSString * const MTStoreKitIdentifierReceiptUniqueId                    = @"unique-identifier";
NSString * const MTStoreKitIdentifierReceiptCancellationDate            = @"cancellation-date";
NSString * const MTStoreKitIdentifierReceiptWebOrderLineItemID          = @"web-item-id";
NSString * const MTStoreKitIdentifierReceiptSubscriptionExpirationDate  = @"experaion-date-subscription";
NSString * const MTStoreKitIdentifierReceiptExpirationDate              = @"experaion-date";
NSString * const MTStoreKitIdentifierReceiptHash                        = @"hash";
NSString * const MTStoreKitIdentifierReceiptInApp                       = @"inapppurchases";


@interface MTStoreKitController ()
    <SKPaymentTransactionObserver, SKProductsRequestDelegate>

@property(nonatomic, retain) NSArray *productIdentifiers;
@property(nonatomic, readwrite, retain) NSArray *products;

@property(atomic, assign) BOOL purchasingProduct;

@property(copy) MTBlockCompletion    purchaseProductWithIdentifierCompletion;
@property(copy) MTBlockCompletion    initalizeProductsCompletion;
@property(copy) MTBlockCompletion    restoringPurchasesCompletion;

@property(nonatomic, strong) SKProduct *purchasingProductObject;
@property(nonatomic, strong) NSArray *restoredTransactionArray;

@property(atomic, assign) BOOL restoringPurchases;

@end

@implementation MTStoreKitController

static MTStoreKitController *sharedSingleton = nil;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSingleton = [[super allocWithZone:NULL] init];
        [[SKPaymentQueue defaultQueue] addTransactionObserver: sharedSingleton];
        [sharedSingleton setProductIdentifiers:nil];
        [sharedSingleton setProducts:nil];
        [sharedSingleton setInitalizeProductsCompletion:nil];
        [sharedSingleton setPurchaseProductWithIdentifierCompletion:nil];
    });
}

+ (MTStoreKitController *)sharedObject {
    return sharedSingleton;
}

+ (id)allocWithZone:(NSZone *)zone {
    //Do not release... this is a singleton yo.
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
                              completion:(MTBlockCompletion)completion {
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
                           completion:(MTBlockCompletion) completion {
    [self setPurchasingProduct: YES];
    [self setPurchasingProductObject:product];
    [self setPurchaseProductWithIdentifierCompletion:[completion copy]];
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}


- (void)restorePurchases:(MTBlockCompletion)completion {
    completion(NO, nil);
}

+ (NSArray *)transactions {
    return [[[[NSUbiquitousKeyValueStore defaultStore] arrayForKey:MTStoreKitTransactionsIdentifier] retain] autorelease];
}

+ (void)archiveTransactionData:(NSDictionary *)transactionData {
    
    NSUbiquitousKeyValueStore *defaultStore = [NSUbiquitousKeyValueStore defaultStore];
    NSArray *transactionDatum = [[defaultStore arrayForKey:MTStoreKitTransactionsIdentifier] copy];
    
    NSMutableArray *updatedTransactionData = [[NSMutableArray alloc] initWithArray:transactionDatum];
    [updatedTransactionData addObject:transactionData];
    [defaultStore setArray:updatedTransactionData forKey:MTStoreKitTransactionsIdentifier];
    [defaultStore synchronize];
    [transactionDatum release];
    [updatedTransactionData release];
    
}

#pragma mark - Private

- (SKProduct *)productForIdentifier:(NSString *)productIdentifier {
    SKProduct *result = nil;
    for (SKProduct *product in [self products]) {
        if ([[product productIdentifier] isEqualToString:productIdentifier]) {
            result = [product retain];
            break;
        }
    }
    return result;
}

#pragma mark - SKRequestDelegate Protocol

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    if ([self initalizeProductsCompletion]) {
        [self initalizeProductsCompletion](NO, error);
    }
}

- (void)requestDidFinish:(SKRequest *)request {
    if ([self initalizeProductsCompletion]) {
        [self initalizeProductsCompletion](YES, nil);
    }
}

#pragma mark - SKProductsRequestDelegate Protocol

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    [self setProducts: [response products]];
}

#pragma mark - SKPaymentTransactionObserver Protocol

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {

    for (SKPaymentTransaction *transaction in transactions) {
		switch ([transaction transactionState]) {
                
			case SKPaymentTransactionStatePurchasing:
				//MTLog(@"SKPaymentTransactionStatePurchasing");
				break;
            
            case SKPaymentTransactionStatePurchased: {

                //MTLog(@"SKPaymentTransactionStatePurchased %@", [[transaction payment] productIdentifier]);
                
                MTVerificationController *verificationController = [MTVerificationController sharedInstance];
                [verificationController iOS7VerifyReceipt];
                
                MTAlertView *alertView = [[MTAlertView alloc] initWithTitle: NSLocalizedString(@"Transaction Complete", @"Title for a completed purchase.")
                                                                    message: NSLocalizedString(@"Software activated.", @"Software activated.")
                                                          cancelButtonTitle:nil otherButtonTitle:@[NSLocalizedString(@"Continue", @"Continue")] onDismiss:nil onCancel:nil];
                [alertView show];
                [alertView autorelease];
                
                
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                
                [self purchaseProductWithIdentifierCompletion](YES, nil);
                
				break;
            }

			case SKPaymentTransactionStateRestored: {
                //Since the non-renewable subscription is consumable, don't restore... hope it's saved to iCloud.
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                
                break;
                
            }

			case SKPaymentTransactionStateFailed: {
                
                if ([self purchaseProductWithIdentifierCompletion] != nil) {
                    [self purchaseProductWithIdentifierCompletion](NO, [transaction error]);
                }
                [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
				break;
            }
			default:
				//MTLog(@"Transaction State Not Found");
				break;
		}
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions { }

- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray *)downloads { }

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error { }

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue { }

@end
