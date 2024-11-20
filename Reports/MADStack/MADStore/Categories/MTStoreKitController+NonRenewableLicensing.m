//
//  MTStoreKitController+NonRenewableLicensing.m
//  Reports
//
//  Created by Michael Thomason on 7/15/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTStoreKitController+NonRenewableLicensing.h"
#import "MTVerificationController.h"
#import "MADSalesReceipt.h"

//On future versions of the software, we will enable subscription based purchase.  For now, it's free once
//  they get a download.

#define SUBSCRIPTION FALSE

const NSTimeInterval MTTimeIntervalHour = 60 /*secs*/ * 60 /*minutes*/;
const NSTimeInterval MTTimeIntervalDay = MTTimeIntervalHour * 24 /*hours*/;
const NSTimeInterval MTTimeIntervalMonth = MTTimeIntervalDay * 30.4368 /*days*/;
const NSTimeInterval MTTimeIntervalYear = MTTimeIntervalDay * 365.242 /*days*/;

NSString * const MTStoreKitProductIdentifierDesignerSubscriptionYear1       = @"com.everydayapps.mad.designer.subscription.year";
NSString * const MTStoreKitProductIdentifierDesignerSubscriptionMonth1      = @"com.everydayapps.mad.designer.subscription.month";
NSString * const MTStoreKitProductIdentifierViewerSubscriptionMonth1        = @"com.everydayapps.mad.viewer.subscription.month";
NSString * const MTStoreKitProductIdentifierViewerSubscriptionYear1         = @"com.everydayapps.mad.viewer.subscription.year";

@implementation MTStoreKitController (NonRenewableLicensing)

- (void)licensedUser:(MTStoreKitNonRenewableLicensedUser)completion {
//#if SUBSCRIPTION == TRUE
//    if (YES) {    //#warning Set to NO to test as unlicensed.  Don't ship as NO.  SHIP AS YES!

        MTVerificationController *verificationController = [MTVerificationController sharedInstance];
        NSDate *experationDate = verificationController.modernReceiptProcessExperationDate;
        BOOL licensedUser = experationDate != nil &&
                            verificationController.modernReceiptIsValid &&
                            verificationController.modernReceiptProcessLicensed &&
                            [experationDate compare:[NSDate date]] == NSOrderedDescending;
        completion(licensedUser, experationDate);

//    } else {
//        completion(NO, nil);
//    }
//#else
//    NSDate *now = [NSDate date];
//    NSDate *experationDate = [now dateByAddingTimeInterval:MTTimeIntervalYear*10];//Expires ten years from now
//    completion(YES, experationDate);
//#endif
    
}

+ (BOOL)licensedUser {
    
    BOOL result = NO;
//#if SUBSCRIPTION == TRUE
//    if (YES) {
        
        MTVerificationController *verificationController = [MTVerificationController sharedInstance];
        NSDate *experationDate = verificationController.modernReceiptProcessExperationDate;
        BOOL licensedUser = experationDate != nil &&
            verificationController.modernReceiptIsValid &&
            verificationController.modernReceiptProcessLicensed &&
            [experationDate compare:[NSDate date]] == NSOrderedDescending;
        result = licensedUser;
        
//    }
//#else
//    result = YES;
//#endif
    return result;

}

+ (void)licensedUser:(MTStoreKitNonRenewableLicensedUser)completion {
//#if SUBSCRIPTION == TRUE

//    if (YES) {  //#warning Set to NO to test as unlicensed.  Don't ship as NO.  SHIP AS YES!
        
        MTVerificationController *verificationController = [MTVerificationController sharedInstance];
        NSDate *experationDate = verificationController.modernReceiptProcessExperationDate;
        BOOL licensedUser = experationDate != nil &&
                            verificationController.modernReceiptIsValid &&
                            verificationController.modernReceiptProcessLicensed &&
                            [experationDate compare:[NSDate date]] == NSOrderedDescending;
        completion(licensedUser, experationDate);
        
//    } else {
//        completion(NO, nil);
//    }
//#else
//    NSDate *now = [NSDate date];
//    NSDate *experationDate = [now dateByAddingTimeInterval:MTTimeIntervalYear*10];//Expires ten years from now
//    completion(YES, experationDate);
//#endif

}

- (NSDate *)experationDateIOS7 {
    
    NSDate *experationDate = nil;
    
//#if SUBSCRIPTION == TRUE
    
    if ([MTVerificationController sharedInstance].modernReceiptIsValid) {

        NSArray *inAppPurchasesReadOnly = [MTVerificationController sharedInstance].receipt.inAppPurchases;
        NSMutableArray *inAppPurchases = [NSMutableArray arrayWithArray: inAppPurchasesReadOnly];
        
        NSPredicate *canceledReceipts = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            NSDictionary *transactionData = evaluatedObject;
            return ([transactionData[MTStoreKitIdentifierReceiptCancellationDate] length] > 0);
        }];
        NSArray *refundedPurchases = [inAppPurchases filteredArrayUsingPredicate:canceledReceipts];
        
        NSPredicate *nonRefundedReceipts = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            
            BOOL refunded = NO;
            NSDictionary *transactionData = evaluatedObject;
            
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            dateFormat.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";

            //Only goes though this if a refunded transaction exist.
            for (NSDictionary *refundTransaction in refundedPurchases) {
                
                // FIXME: Verify the below loop... haven't tested since iOS7 update
                NSString *refundTransactionOrigionalTransactionId = refundTransaction[MTStoreKitIdentifierReceiptOriginalTransactionId];
                if (refundTransactionOrigionalTransactionId) {
                    NSString *origionalTransactionId = transactionData[MTStoreKitIdentifierReceiptTransactionId];
                    if ([origionalTransactionId isEqualToString:refundTransactionOrigionalTransactionId]) {
                        NSString *refundTransactionCancelDate = refundTransaction[MTStoreKitIdentifierReceiptCancellationDate];
                        NSDate *refundDate = nil;
                        if (refundTransactionCancelDate.length > 0) {
                            refundDate = [dateFormat dateFromString: refundTransactionCancelDate];
                            if ([refundDate compare:[NSDate date]] == NSOrderedAscending) {
                                refunded = YES;
                            }
                        }
                    }
                }
            }
            
            if ([transactionData[MTStoreKitIdentifierReceiptCancellationDate] length] > 0) {
                refunded = YES;
            }
            
            [dateFormat release];
            
            return !refunded;
        }];
        [inAppPurchases filterUsingPredicate:nonRefundedReceipts];

        if (inAppPurchases.count > 0) {
            
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            dateFormat.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
            
            [inAppPurchases sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *transactionA, NSDictionary *transactionB) {
                NSString *purchaseDateStringA = transactionA[MTStoreKitIdentifierReceiptOriginalPurchaseDate];
                NSString *purchaseDateStringB = transactionB[MTStoreKitIdentifierReceiptOriginalPurchaseDate];
                NSDate *purchaseDateA = [dateFormat dateFromString:purchaseDateStringA];
                NSDate *purchaseDateB = [dateFormat dateFromString:purchaseDateStringB];
                return [purchaseDateA compare:purchaseDateB];
            }];
            
            //NSString *bundleId = [AppDelegate bundleId];
            
            for (NSDictionary *transactionData in inAppPurchases) {
                //NSString *receiptBundleIdentifier = [transactionData objectForKey:MTStoreKitIdentifierReceiptBid];
                NSString *receiptBundlePurchaseDate = transactionData[MTStoreKitIdentifierReceiptOriginalPurchaseDate];
                NSString *receiptBundleProductIdentifier = transactionData[MTStoreKitIdentifierReceiptProductId];
                
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
            //[dateFormat release];
        }
        //[inAppPurchases release];
    }
//#else
//    NSDate *now = [NSDate date];
//    experationDate = [now dateByAddingTimeInterval:MTTimeIntervalYear*10];//Expires ten years from now
//#endif
    return experationDate;
}

+ (NSDate *)experationDate {
    
    NSDate *experationDate = nil;
    
//#if SUBSCRIPTION == TRUE
/*
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
        //[dateFormat release];
    }
    
    //[transactions release];
    
//#else
//    NSDate *now = [NSDate date];
//    experationDate = [now dateByAddingTimeInterval:MTTimeIntervalYear*10];//Expires ten years from now
//#endif
    */
    return experationDate;
    
}

@end
