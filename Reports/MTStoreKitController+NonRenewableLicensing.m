//
//  MTStoreKitController+NonRenewableLicensing.m
//  Reports
//
//  Created by Michael Thomason on 7/15/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTStoreKitController+NonRenewableLicensing.h"

@implementation MTStoreKitController (NonRenewableLicensing)

+ (BOOL)licensedUser {

    BOOL isLicensedUser = NO;
    NSArray *transactions = [MTStoreKitController transactions];

    if ([transactions count] > 0) {
        const NSTimeInterval oneHour = 60 /*secs*/ * 60 /*minutes*/;
        const NSTimeInterval oneDay = oneHour * 24 /*hours*/;
        const NSTimeInterval oneMonth = oneDay * 30.4368 /*days*/;
        const NSTimeInterval oneYear = oneDay * 365.242 /*days*/;
        
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss z"];
        
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
            
            NSDate *expiresDate = nil;
            
            NSDate *purchaseDate = [dateFormat dateFromString:[receiptBundlePurchaseDate stringByReplacingOccurrencesOfString:@"Etc/" withString:@""]];
            
            if ([receiptBundleIdentifier isEqualToString:bundleId]) {                                       //Make sure receipt is for current app running
                if ([receiptBundleIdentifier isEqualToString:MTBundleIdMadDesigner]) {
                    if ([receiptBundleProductIdentifier isEqualToString:MTStoreKitProductIdentifierDesignerSubscriptionYear1]) {
                        expiresDate = [purchaseDate dateByAddingTimeInterval: oneYear];
                    }
                } else if ([receiptBundleIdentifier isEqualToString:MTBundleIdMadViewer]) {
                    if ([receiptBundleProductIdentifier isEqualToString:MTStoreKitProductIdentifierViewerSubscriptionMonth1]) {
                        expiresDate = [purchaseDate dateByAddingTimeInterval: oneMonth];
                    } else if ([receiptBundleProductIdentifier isEqualToString:MTStoreKitProductIdentifierViewerSubscriptionYear1]) {
                        expiresDate = [purchaseDate dateByAddingTimeInterval: oneYear];
                    }
                }
            }
            
            if (expiresDate != nil) {
                NSDate *now = [NSDate date];
                NSComparisonResult dateComparesonResult = [now compare:expiresDate];
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
            if (isLicensedUser) {
                break;
            }
        }
        [dateFormat release];
    }

    return isLicensedUser;

}

@end
