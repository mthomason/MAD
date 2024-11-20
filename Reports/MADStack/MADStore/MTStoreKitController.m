//
//  MTStoreKit.m
//  Reports
//
//  Created by Michael Thomason on 7/1/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTStoreKitController.h"
#import "MTVerificationController.h"

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

    @property(nonatomic, assign) BOOL purchasingProduct;
    @property(nonatomic, assign) BOOL restoringPurchases;

    @property(nonatomic, retain) NSArray *productIdentifiers;
    @property(nonatomic, readwrite, retain) NSArray *products;

    @property(nonatomic, copy) MTBlockCompletion    purchaseProductWithIdentifierCompletion;
    @property(nonatomic, copy) MTBlockCompletion    initializeProductsCompletion;
    @property(nonatomic, copy) MTBlockCompletion    restoringPurchasesCompletion;

    @property(nonatomic, strong) SKProduct *purchasingProductObject;
    @property(nonatomic, strong) NSArray *restoredTransactionArray;

@end

@implementation MTStoreKitController

- (void)dealloc {
    NSAssert(NO, @"Don't dealloc the singleton.");
}

- (id)debugQuickLookObject {
    NSMutableString *string = [[NSMutableString alloc] init];
    [string appendString:@"Products: \n"];
    for (SKProduct *product in self.products) {
        [string appendString:@"-------P R O D U C T-------\n"];
        [string appendFormat:@"Title:           %@ (%@)\n", product.localizedDescription, product.productIdentifier];
        [string appendFormat:@"Description:     %@\n", product.localizedDescription];
        [string appendFormat:@"Price:           %@ (%@)\n", product.price, [product.priceLocale objectForKey:NSLocaleCountryCode]];
        [string appendFormat:@"Downloadable:    %@\n", product.isDownloadable ? @"YES" : @"NO"];
        [string appendString:@"---------------------------\n"];
    }
    
    return string;
}

+ (MTStoreKitController *)sharedObject {
    static id sharedSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSingleton = [[self alloc] init];
    });
    return sharedSingleton;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return self;
}

#pragma mark - Methods

- (instancetype)init {
    if (self = [super init]) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver: self];
    }
    return self;
}

- (void)initializeProductsWithIdentifiers:(NSArray *)productIdentifiers
                               completion:(MTBlockCompletion)completion {
    if (self.initializeProductsCompletion == nil && self.products.count == 0) {
        
        self.initializeProductsCompletion = [completion copy];
        self.productIdentifiers = productIdentifiers;
        
        NSSet *productIdSet = [NSSet setWithArray:self.productIdentifiers];
        SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdSet];
        request.delegate = self;
        [request start];
        
    } else if (self.products.count == 0) {
        NSDictionary *errorInfo = @{NSLocalizedDescriptionKey :         @"Product Load Failed",
                                    NSLocalizedFailureReasonErrorKey :  @"Try again later."};
        completion(NO, [NSError errorWithDomain:@"MTStoreKitController" code:5 userInfo:errorInfo]);
    } else {
        completion(YES, nil);
    }
}

- (void)purchaseProduct:(SKProduct *)product completion:(MTBlockCompletion) completion {
    
    self.purchasingProduct = YES;
    self.purchasingProductObject = product;
    self.purchaseProductWithIdentifierCompletion = [completion copy];

    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)restorePurchases:(MTBlockCompletion)completion {
    completion(NO, nil);
}

/*
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
}*/

#pragma mark - Private

- (SKProduct *)productForIdentifier:(NSString *)productIdentifier {
    SKProduct *result = nil;
    for (SKProduct *product in self.products) {
        if ([product.productIdentifier isEqualToString:productIdentifier]) {
            result = product;
            break;
        }
    }
    return result;
}

#pragma mark - SKRequestDelegate Protocol

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    if (self.initializeProductsCompletion) {
        self.initializeProductsCompletion(NO, error);
    }
}

- (void)requestDidFinish:(SKRequest *)request {
    if (self.initializeProductsCompletion) {
        self.initializeProductsCompletion(YES, nil);
    }
}

#pragma mark - SKProductsRequestDelegate Protocol

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSArray *products = [NSArray arrayWithArray:response.products];
    self.products = products;
}

#pragma mark - SKPaymentTransactionObserver Protocol

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {

    for (SKPaymentTransaction *transaction in transactions) {
		switch (transaction.transactionState) {
                
			case SKPaymentTransactionStatePurchasing:
				break;
            
            case SKPaymentTransactionStatePurchased: {
                
                MTVerificationController *verificationController = [MTVerificationController sharedInstance];
                [verificationController iOS7VerifyReceipt];
                
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                
                self.purchaseProductWithIdentifierCompletion(YES, nil);
                
				break;
            }

			case SKPaymentTransactionStateRestored: {
                //Since the non-renewable subscription is consumable, don't restore... hope it's saved to iCloud.
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                
                break;
                
            }

			case SKPaymentTransactionStateFailed: {
                
                if (self.purchaseProductWithIdentifierCompletion != nil) {
                    self.purchaseProductWithIdentifierCompletion(NO, transaction.error);
                }
                [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
				break;
            }
			default:
				break;
		}
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions { }

- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray *)downloads { }

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error { }

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue { }

@end
