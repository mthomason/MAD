//
//  MTStoreKitController+NonRenewableLicensing.h
//  Reports
//
//  Created by Michael Thomason on 7/15/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTStoreKitController_NonRenewableLicensing_h
#define Reports_MTStoreKitController_NonRenewableLicensing_h

#import "MADStoreKitController.h"
#import <Foundation/NSObject.h>
#import <Foundation/NSDate.h>

extern const NSTimeInterval MTTimeIntervalHour;
extern const NSTimeInterval MTTimeIntervalDay;
extern const NSTimeInterval MTTimeIntervalMonth;
extern const NSTimeInterval MTTimeIntervalYear;

extern NSString * const MTStoreKitProductIdentifierDesignerSubscriptionYear1;
extern NSString * const MTStoreKitProductIdentifierDesignerSubscriptionMonth1;
extern NSString * const MTStoreKitProductIdentifierViewerSubscriptionMonth1;
extern NSString * const MTStoreKitProductIdentifierViewerSubscriptionYear1;

typedef void (^MTStoreKitNonRenewableLicensedUser)(BOOL isLicensedUser, NSDate *experationDate);

@interface MADStoreKitController (NonRenewableLicensing)

+ (void)licensedUser:(MTStoreKitNonRenewableLicensedUser)completion;
- (void)licensedUser:(MTStoreKitNonRenewableLicensedUser)completion;
+ (BOOL)licensedUser;

@end

#endif
