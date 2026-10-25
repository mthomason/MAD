//
//  MTStoreKitController+NonRenewableLicensing.m
//  Reports
//
//  Created by Michael Thomason on 7/15/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MTStoreKitController+NonRenewableLicensing.h"
#import "MADVerificationController.h"
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

@implementation MADStoreKitController (NonRenewableLicensing)

- (void)licensedUser:(MTStoreKitNonRenewableLicensedUser)completion {
//#if SUBSCRIPTION == TRUE
//    if (YES) {    //#warning Set to NO to test as unlicensed.  Don't ship as NO.  SHIP AS YES!

        MADVerificationController *verificationController = [MADVerificationController sharedInstance];
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
        
        MADVerificationController *verificationController = [MADVerificationController sharedInstance];
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
        
        MADVerificationController *verificationController = [MADVerificationController sharedInstance];
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

@end
