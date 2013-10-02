//
//  MTStoreKitController+NonRenewableLicensing.h
//  Reports
//
//  Created by Michael Thomason on 7/15/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTStoreKitController.h"
#import "AppDelegate.h"

typedef void (^MTStoreKitNonRenewableLicensedUser)(BOOL isLicensedUser, NSDate *experationDate);
extern const NSTimeInterval MTTimeIntervalHour;
extern const NSTimeInterval MTTimeIntervalDay;
extern const NSTimeInterval MTTimeIntervalMonth;
extern const NSTimeInterval MTTimeIntervalYear;

@interface MTStoreKitController (NonRenewableLicensing)

+ (void)licensedUser:(MTStoreKitNonRenewableLicensedUser)completion;
- (void)licensedUser:(MTStoreKitNonRenewableLicensedUser)completion;
- (NSDate *)experationDateIOS7;
+ (NSDate *)experationDate;

@end
