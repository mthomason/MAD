//
//  MTStoreKitController+Features.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/26/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MTStoreKitController_Features_h
#define MAD_Designer_MTStoreKitController_Features_h

#import "MADStoreKitController.h"

@interface MADStoreKitController (Features)

@property (readonly, getter=isReportingLimited)             BOOL reportingLimited;
@property (readonly, getter=isReportingEnabled)             BOOL reportingEnabled;
@property (readonly, getter=isBarcodeDesignerEnabled)       BOOL barcodeDesignerEnabled;

@end

#endif
