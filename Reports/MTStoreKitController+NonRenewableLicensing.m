//
//  MTStoreKitController+NonRenewableLicensing.m
//  Reports
//
//  Created by Michael Thomason on 7/15/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTStoreKitController+NonRenewableLicensing.h"
#import "VerifyStoreReceipt.h"

const NSTimeInterval MTTimeIntervalHour = 60 /*secs*/ * 60 /*minutes*/;
const NSTimeInterval MTTimeIntervalDay = MTTimeIntervalHour * 24 /*hours*/;
const NSTimeInterval MTTimeIntervalMonth = MTTimeIntervalDay * 30.4368 /*days*/;
const NSTimeInterval MTTimeIntervalYear = MTTimeIntervalDay * 365.242 /*days*/;


@implementation MTStoreKitController (NonRenewableLicensing)

- (void)licensedUser:(MTStoreKitNonRenewableLicensedUser)completion {
    //#warning Set to NO to test as unlicensed.  Don't ship as NO.  SHIP AS YES!
    if (YES) {

        MTVerificationController *verificationController = [MTVerificationController sharedInstance];
        NSDate *experationDate = [verificationController modernReceiptProcessExperationDate];
        BOOL licensedUser = experationDate != nil &&
                            [verificationController modernReceiptIsValid] &&
                            [verificationController modernReceiptProcessLicensed] &&
                            [experationDate compare:[NSDate date]] == NSOrderedDescending;
        completion(licensedUser, experationDate);

    } else {
        completion(NO, nil);
    }

}

+ (void)licensedUser:(MTStoreKitNonRenewableLicensedUser)completion {
    
    //#warning Set to NO to test as unlicensed.  Don't ship as NO.  SHIP AS YES!
    if (YES) {
        
        MTVerificationController *verificationController = [MTVerificationController sharedInstance];
        NSDate *experationDate = [verificationController modernReceiptProcessExperationDate];
        BOOL licensedUser = experationDate != nil &&
                            [verificationController modernReceiptIsValid] &&
                            [verificationController modernReceiptProcessLicensed] &&
                            [experationDate compare:[NSDate date]] == NSOrderedDescending;
        completion(licensedUser, experationDate);
        
    } else {
        completion(NO, nil);
    }

}

+ (NSDate *)dateFromReceiptString:(NSString *)dateString {
    static NSDateFormatter *receiptDateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        receiptDateFormatter = dateFormat;
    });
    return [receiptDateFormatter dateFromString:dateString];
}

- (NSDate *)experationDateIOS7 {
    
    NSDate *experationDate = nil;
    
    if ([[MTVerificationController sharedInstance] modernReceiptIsValid]) {
        NSURL *receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];
        NSArray *inAppPurchasesReadOnly = obtainInAppPurchases([receiptUrl path]);
        NSMutableArray *inAppPurchases = [[NSMutableArray alloc] initWithArray: inAppPurchasesReadOnly];
        
        NSPredicate *canceledReceipts = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            NSDictionary *transactionData = evaluatedObject;
            return ([[transactionData objectForKey:MTStoreKitIdentifierReceiptCancellationDate] length] > 0);
        }];
        NSArray *refundedPurchases = [inAppPurchases filteredArrayUsingPredicate:canceledReceipts];
        
        NSPredicate *nonRefundedReceipts = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            
            BOOL refunded = NO;
            NSDictionary *transactionData = evaluatedObject;
            
            //Only goes though this if a refunded transaction exist.
            for (NSDictionary *refundTransaction in refundedPurchases) {
                
                // FIXME: Verify the below loop... haven't tested since iOS7 update
                NSString *refundTransactionOrigionalTransactionId = [refundTransaction objectForKey:MTStoreKitIdentifierReceiptOriginalTransactionId];
                if (refundTransactionOrigionalTransactionId) {
                    NSString *origionalTransactionId = [transactionData objectForKey:MTStoreKitIdentifierReceiptTransactionId];
                    if ([origionalTransactionId isEqualToString:refundTransactionOrigionalTransactionId]) {
                        NSString *refundTransactionCancelDate = [refundTransaction objectForKey:MTStoreKitIdentifierReceiptCancellationDate];
                        NSDate *refundDate = nil;
                        if ([refundTransactionCancelDate length] > 0) {
                            refundDate = [MTStoreKitController dateFromReceiptString:refundTransactionCancelDate];
                            if ([refundDate compare:[NSDate date]] == NSOrderedAscending) {
                                refunded = YES;
                            }
                        }
                    }
                }
            }
            
            if ([[transactionData objectForKey:MTStoreKitIdentifierReceiptCancellationDate] length] > 0) {
                refunded = YES;
            }
            
            return !refunded;
        }];
        [inAppPurchases filterUsingPredicate:nonRefundedReceipts];

        if ([inAppPurchases count] > 0) {
            
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
            
            [inAppPurchases sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *transactionA, NSDictionary *transactionB) {
                NSString *purchaseDateStringA = [transactionA objectForKey:MTStoreKitIdentifierReceiptOriginalPurchaseDate];
                NSString *purchaseDateStringB = [transactionB objectForKey:MTStoreKitIdentifierReceiptOriginalPurchaseDate];
                NSDate *purchaseDateA = [dateFormat dateFromString:purchaseDateStringA];
                NSDate *purchaseDateB = [dateFormat dateFromString:purchaseDateStringB];
                return [purchaseDateA compare:purchaseDateB];
            }];
            
            //NSString *bundleId = [AppDelegate bundleId];
            
            for (NSDictionary *transactionData in inAppPurchases) {
                //NSString *receiptBundleIdentifier = [transactionData objectForKey:MTStoreKitIdentifierReceiptBid];
                NSString *receiptBundlePurchaseDate = [transactionData objectForKey:MTStoreKitIdentifierReceiptOriginalPurchaseDate];
                NSString *receiptBundleProductIdentifier = [transactionData objectForKey:MTStoreKitIdentifierReceiptProductId];
                
                NSDate *purchaseDate = [dateFormat dateFromString:receiptBundlePurchaseDate];
                
                NSTimeInterval licenseInterval = 0;
                if ([receiptBundleProductIdentifier isEqualToString:MTStoreKitProductIdentifierDesignerSubscriptionYear1]) {
                    licenseInterval = MTTimeIntervalYear;
                } else if ([receiptBundleProductIdentifier isEqualToString:MTStoreKitProductIdentifierDesignerSubscriptionMonth1]) {
                    licenseInterval = MTTimeIntervalMonth;
                } else if ([receiptBundleProductIdentifier isEqualToString:MTStoreKitProductIdentifierViewerSubscriptionMonth1]) {
                    licenseInterval = MTTimeIntervalMonth;
                } else if ([receiptBundleProductIdentifier isEqualToString:MTStoreKitProductIdentifierViewerSubscriptionYear1]) {
                    licenseInterval = MTTimeIntervalYear;
                }
                
                if (licenseInterval > 0) {
                    if (experationDate == nil) {    //First license
                        experationDate = [purchaseDate dateByAddingTimeInterval: licenseInterval];
                    } else {
                        
                        //If there's a gap between the licenses, add to the purchse date...
                        //  If there's no gap, add to the experation date to calculate a new
                        //  experation date.
                        NSComparisonResult dateCompareson = [experationDate compare:purchaseDate];
                        switch (dateCompareson) {
                            case NSOrderedAscending:
                                experationDate = [purchaseDate dateByAddingTimeInterval: licenseInterval];
                                break;
                            case NSOrderedDescending:
                                experationDate = [experationDate dateByAddingTimeInterval: licenseInterval];
                                break;
                            case NSOrderedSame:
                                experationDate = [purchaseDate dateByAddingTimeInterval: licenseInterval];
                                break;
                            default:
                                break;
                        }
                    }
                }
            }
            [dateFormat release];
        }
    }
    return experationDate;
}

+ (NSDate *)experationDate {
    
    NSDate *experationDate = nil;
    
    NSMutableArray *transactions = [[NSMutableArray alloc] initWithArray:[MTStoreKitController transactions]];
    NSPredicate *canceledReceipts = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        NSDictionary *transactionData = evaluatedObject;
        return ([transactionData objectForKey:MTStoreKitIdentifierReceiptCancellationDate] != nil);
    }];
    
    NSArray *refundTransactions = [transactions filteredArrayUsingPredicate:canceledReceipts];
    
    NSPredicate *nonRefundedReceipts = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {

        BOOL refunded = NO;
        NSDictionary *transactionData = evaluatedObject;
        
        //Only goes though this if a refunded transaction exist.
        for (NSDictionary *refundTransaction in refundTransactions) {
            NSString *refundTransactionOrigionalTransactionId = [refundTransaction objectForKey:MTStoreKitIdentifierReceiptOriginalTransactionId];
            if (refundTransactionOrigionalTransactionId) {
                NSString *origionalTransactionId = [transactionData objectForKey:MTStoreKitIdentifierReceiptTransactionId];
                if ([origionalTransactionId isEqualToString:refundTransactionOrigionalTransactionId]) {
                    NSString *refundTransactionCancelDate = [refundTransaction objectForKey:MTStoreKitIdentifierReceiptCancellationDate];
                    NSDate *refundDate = nil;
                    if (refundTransactionCancelDate != nil) {
                        refundDate = [MTStoreKitController dateFromReceiptString:refundTransactionCancelDate];
                        if ([refundDate compare:[NSDate date]] == NSOrderedAscending) {
                            refunded = YES;
                        }
                    }
                }
            }
        }
        
        if ([transactionData objectForKey:MTStoreKitIdentifierReceiptCancellationDate] != nil) {
            refunded = YES;
        }
        
        return !refunded;
    }];
    [transactions filterUsingPredicate:nonRefundedReceipts];
    
    if ([transactions count] > 0) {
        
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss z"];
        
        [transactions sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *transactionA, NSDictionary *transactionB) {
            NSString *purchaseDateStringA = [transactionA objectForKey:MTStoreKitIdentifierReceiptPurchaseDate];
            NSString *purchaseDateStringB = [transactionB objectForKey:MTStoreKitIdentifierReceiptPurchaseDate];
            NSDate *purchaseDateA = [dateFormat dateFromString:[purchaseDateStringA stringByReplacingOccurrencesOfString:@"Etc/" withString:@""]];
            NSDate *purchaseDateB = [dateFormat dateFromString:[purchaseDateStringB stringByReplacingOccurrencesOfString:@"Etc/" withString:@""]];
            return [purchaseDateA compare:purchaseDateB];
        }];
        
        NSString *bundleId = [AppDelegate bundleId];
        
        for (NSDictionary *transactionData in transactions) {
            NSString *receiptBundleIdentifier = [transactionData objectForKey:MTStoreKitIdentifierReceiptBid];
            NSString *receiptBundlePurchaseDate = [transactionData objectForKey:MTStoreKitIdentifierReceiptPurchaseDate];
            NSString *receiptBundleProductIdentifier = [transactionData objectForKey:MTStoreKitIdentifierReceiptProductId];
            
            NSDate *purchaseDate = [dateFormat dateFromString:[receiptBundlePurchaseDate stringByReplacingOccurrencesOfString:@"Etc/" withString:@""]];
            
            NSTimeInterval licenseInterval = 0;
            if ([receiptBundleIdentifier isEqualToString:bundleId]) {                                       //Make sure receipt is for current app running
                if ([receiptBundleIdentifier isEqualToString:MTBundleIdMadDesigner]) {
                    if ([receiptBundleProductIdentifier isEqualToString:MTStoreKitProductIdentifierDesignerSubscriptionYear1]) {
                        licenseInterval = MTTimeIntervalYear;
                    } else if ([receiptBundleProductIdentifier isEqualToString:MTStoreKitProductIdentifierDesignerSubscriptionMonth1]) {
                        licenseInterval = MTTimeIntervalMonth;
                    }
                } else if ([receiptBundleIdentifier isEqualToString:MTBundleIdMadViewer]) {
                    if ([receiptBundleProductIdentifier isEqualToString:MTStoreKitProductIdentifierViewerSubscriptionMonth1]) {
                        licenseInterval = MTTimeIntervalMonth;
                    } else if ([receiptBundleProductIdentifier isEqualToString:MTStoreKitProductIdentifierViewerSubscriptionYear1]) {
                        licenseInterval = MTTimeIntervalYear;
                    }
                }
            }

            if (licenseInterval > 0) {
                if (experationDate == nil) {
                    experationDate = [purchaseDate dateByAddingTimeInterval: licenseInterval];
                } else {
                    NSComparisonResult dateCompareson = [experationDate compare:purchaseDate];
                    switch (dateCompareson) {
                        case NSOrderedAscending:
                            experationDate = [purchaseDate dateByAddingTimeInterval: licenseInterval];
                            break;
                        case NSOrderedDescending:
                            experationDate = [experationDate dateByAddingTimeInterval: licenseInterval];
                            break;
                        case NSOrderedSame:
                            experationDate = [purchaseDate dateByAddingTimeInterval: licenseInterval];
                            break;
                        default:
                            break;
                    }
                }
            }
        }
        [dateFormat release];
    }
    
    [transactions release];
    
    return experationDate;
    
}

@end
