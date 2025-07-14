//
//  MTStoreKitController+Features.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/26/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTStoreKitController+Features.h"
#import "MADVerificationController.h"

@implementation MADStoreKitController (Features)

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
	return [[MADVerificationController sharedInstance] entitledToProduct:@"com.everydayapps.mad.designer.product.element.barcode"];
}

@end
