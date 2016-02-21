//
//  MTStoreKitController+Features.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/26/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MTStoreKitController+Features.h"
#import "MTVerificationController.h"

@implementation MTStoreKitController (Features)

- (BOOL)isReportingLimited {
    return !self.isReportingEnabledAndDesired;
}

- (BOOL)isReportingEnabledAndDesired {
    return YES;
    
    //[[MTVerificationController sharedInstance] entitledToProduct:@"com.everydayapps.mad.designer.product.viewer"] &&
    //        [[NSUserDefaults standardUserDefaults] boolForKey:@"defaults.everydayapps.features.viewer.desired"];
}

- (BOOL)isReportingEnabled {
    return YES;
    //[[MTVerificationController sharedInstance] entitledToProduct:@"com.everydayapps.mad.designer.product.viewer"];
}

- (BOOL)isBarcodeDesignerEnabled {
    return [[MTVerificationController sharedInstance] entitledToProduct:@"com.everydayapps.mad.designer.product.element.barcode"];
}

@end
