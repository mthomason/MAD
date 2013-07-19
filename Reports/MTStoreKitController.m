//
//  MTStoreKit.m
//  Reports
//
//  Created by Michael Thomason on 7/1/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTStoreKitController.h"
#import "AppDelegate.h"

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
    if ([self restoringPurchases] == NO) {
        [self setRestoringPurchasesCompletion:[completion copy]];
        [self setRestoringPurchases:YES];
        NSUbiquitousKeyValueStore *defaultStore = [NSUbiquitousKeyValueStore defaultStore];
        [self setRestoredTransactionArray:[defaultStore arrayForKey:MTStoreKitTransactionsIdentifier]];
        [defaultStore setArray:@[] forKey:MTStoreKitTransactionsIdentifier];
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    }
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

- (void)processTransaction:(SKPaymentTransaction *)transaction validTransaction:(BOOL)validTransaction error:(NSError *)error  status:(NSInteger)status receiptData:(NSDictionary *)receiptData purchaseDate:(NSDate *)purcahseDate {
    NSMutableDictionary *completeTransactionData = nil;
    if (validTransaction) {
        
        NSDictionary *transactionData = @{MTStoreKitTransactionReceipt      : [transaction transactionReceipt],
                                          MTStoreKitTransactionDate         : [transaction transactionDate],
                                          MTStoreKitTransactionIdentifier   : [transaction transactionIdentifier]};
        
        completeTransactionData = [[NSMutableDictionary alloc] initWithDictionary:transactionData];
        [receiptData enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [completeTransactionData setObject:obj forKey:key];
        }];
        [MTStoreKitController archiveTransactionData:completeTransactionData];
        
        NSString *productId = [completeTransactionData objectForKey:MTStoreKitIdentifierReceiptProductId];
        SKProduct *product = [self productForIdentifier:productId];
        if (product != nil) {
            NSString *messageFormat = NSLocalizedString(@"Succesfully activated \"%@.\"", @"Shows the name of the items purchased and activated.");
            NSString *message = [NSString stringWithFormat:messageFormat, [product localizedDescription]];
            MTAlertView *alertView = [[MTAlertView alloc] initWithTitle: NSLocalizedString(@"Transaction Complete", @"Title for a completed purchase.")
                                                                message: message
                                                      cancelButtonTitle:nil otherButtonTitle:@[NSLocalizedString(@"Continue", @"Continue")] onDismiss:nil onCancel:nil];
            [alertView show];
            [alertView autorelease];
        }
    }
    
    if ([self purchasingProduct] && [self purchaseProductWithIdentifierCompletion] != nil) {
        if ([[[self purchasingProductObject] productIdentifier] isEqualToString:[completeTransactionData objectForKey:MTStoreKitIdentifierReceiptProductId]]) {
            
            [self setPurchasingProductObject:nil];
            [self setPurchasingProduct:NO];
            [self purchaseProductWithIdentifierCompletion](validTransaction, error);
            [self setPurchaseProductWithIdentifierCompletion:nil];
        }
    }
    
    [completeTransactionData release];
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
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

- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray *)downloads {
    
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {

    for (SKPaymentTransaction *transaction in transactions) {
		switch ([transaction transactionState]) {
                
			case SKPaymentTransactionStatePurchasing:
				MTLog(@"SKPaymentTransactionStatePurchasing");
				break;
            
            case SKPaymentTransactionStatePurchased: {

                MTLog(@"SKPaymentTransactionStatePurchased %@", [[transaction payment] productIdentifier]);
                
                [[MTVerificationController sharedInstance] verifyPurchase:transaction onSandboxServer:MTDebugOn completion:^(BOOL validTransaction, NSError *error, NSInteger status, NSDictionary *receiptData, NSDate *purcahseDate) {
                    
                    if (status == 21007) {
                        
                        [[MTVerificationController sharedInstance] verifyPurchase:transaction onSandboxServer:YES completion:^(BOOL validTransaction, NSError *error, NSInteger status, NSDictionary *receiptData, NSDate *purcahseDate) {
                            [self processTransaction:transaction validTransaction:validTransaction error:error status:status receiptData:receiptData purchaseDate:purcahseDate];
                        }];
                        
                    } else {
                        [self processTransaction:transaction validTransaction:validTransaction error:error status:status receiptData:receiptData purchaseDate:purcahseDate];
                    }
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
                
                if ([self purchaseProductWithIdentifierCompletion] != nil) {
                    [self purchaseProductWithIdentifierCompletion](NO, [transaction error]);
                }
                [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
				break;
            }
			default:
				MTLog(@"Transaction State Not Found");
				break;
		}
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    NSUbiquitousKeyValueStore *defaultStore = [NSUbiquitousKeyValueStore defaultStore];
    [defaultStore setArray:[self restoredTransactionArray] forKey:MTStoreKitTransactionsIdentifier];
    [self setRestoredTransactionArray:nil];
    [self setRestoringPurchases:NO];
    [self restoringPurchasesCompletion](NO, error);
    [self setRestoringPurchasesCompletion:nil];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    MTLog(@"Transactions: %@", [queue transactions]);
    NSUbiquitousKeyValueStore *defaultStore = [NSUbiquitousKeyValueStore defaultStore];
    [defaultStore setArray:[queue transactions] forKey:MTStoreKitTransactionsIdentifier];

    [self setRestoringPurchases:NO];
    [self restoringPurchasesCompletion](YES, nil);
    [self setRestoringPurchasesCompletion:nil];
}

@end
