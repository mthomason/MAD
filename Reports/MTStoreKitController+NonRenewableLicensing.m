//
//  MTStoreKitController+NonRenewableLicensing.m
//  Reports
//
//  Created by Michael Thomason on 7/15/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTStoreKitController+NonRenewableLicensing.h"

const NSTimeInterval MTTimeIntervalHour = 60 /*secs*/ * 60 /*minutes*/;
const NSTimeInterval MTTimeIntervalDay = MTTimeIntervalHour * 24 /*hours*/;
const NSTimeInterval MTTimeIntervalMonth = MTTimeIntervalDay * 30.4368 /*days*/;
const NSTimeInterval MTTimeIntervalYear = MTTimeIntervalDay * 365.242 /*days*/;

@implementation MTStoreKitController (NonRenewableLicensing)

+ (void)licensedUser:(MTStoreKitNonRenewableLicensedUser)completion {
    NSDate *experationDate = [MTStoreKitController experationDate];
    
    BOOL isLicensedUser = NO;
    if (experationDate != nil) {
        NSDate *now = [NSDate date];
        NSComparisonResult dateComparesonResult = [now compare:experationDate];
        switch (dateComparesonResult) {
            case NSOrderedAscending:
                isLicensedUser = YES;   //Only path to redemption
                break;
            case NSOrderedSame:
                break;
            case NSOrderedDescending:
                break;
            default:
                break;
        }
    }
    completion(isLicensedUser, experationDate);
}

+ (NSDate *)experationDate {
    
    NSDate *experationDate = nil;
    
    NSMutableArray *transactions = [[NSMutableArray alloc] initWithArray:[MTStoreKitController transactions]];
    
    
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
        
        NSArray *productIds;
        NSString *bundleId = [AppDelegate bundleId];
        if ([AppDelegate isMadDesigner]) {
            productIds = @[MTStoreKitProductIdentifierDesignerSubscriptionYear1];
        } else if ([AppDelegate isMadViewer]) {
            productIds = @[MTStoreKitProductIdentifierViewerSubscriptionMonth1, MTStoreKitProductIdentifierViewerSubscriptionYear1];
        }
        
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
