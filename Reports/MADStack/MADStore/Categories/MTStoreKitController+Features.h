//
//  MTStoreKitController+Features.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/26/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MTStoreKitController.h"

@interface MTStoreKitController (Features)

@property (readonly, getter=isReportingLimited)             BOOL reportingLimited;
@property (readonly, getter=isReportingEnabledAndDesired)   BOOL reportingEnabledAndDesired;
@property (readonly, getter=isReportingEnabled)             BOOL reportingEnabled;
@property (readonly, getter=isBarcodeDesignerEnabled)       BOOL barcodeDesignerEnabled;

@end
