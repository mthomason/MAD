//
//  MTStoreKitController+NonRenewableLicensing.h
//  Reports
//
//  Created by Michael Thomason on 7/15/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTStoreKitController.h"
#import "AppDelegate.h"

@interface MTStoreKitController (NonRenewableLicensing)

+ (BOOL)licensedUser;

@end
