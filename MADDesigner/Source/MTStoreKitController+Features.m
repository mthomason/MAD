//
//  MTStoreKitController+Features.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/26/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MTStoreKitController+Features.h"
#import "MADVerificationController.h"

@implementation MADStoreKitController (Features)

- (BOOL)isReportingLimited {
    return !self.isReportingEnabledAndDesired;
}

- (BOOL)isReportingEnabledAndDesired {
	return [[MADVerificationController sharedInstance] entitledToProduct:@"com.everydayapps.mad.designer.product.viewer"] &&
		[[NSUserDefaults standardUserDefaults] boolForKey:@"defaults.everydayapps.features.viewer.desired"];
}

- (BOOL)isReportingEnabled {
    return [[MADVerificationController sharedInstance] entitledToProduct:@"com.everydayapps.mad.designer.product.viewer"];
}

- (BOOL)isBarcodeDesignerEnabled {
	return [[MADVerificationController sharedInstance] entitledToProduct:@"com.everydayapps.mad.designer.product.element.barcode"];
}

@end
