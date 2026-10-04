//
//  MADCocoaExtensions.h
//  MADCocoaExtensions
//
//  Created by Michael Thomason on 9/15/15.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import <Foundation/NSObjCRuntime.h>

FOUNDATION_EXPORT double MADCocoaExtensionsVersionNumber;
FOUNDATION_EXPORT const unsigned char MADCocoaExtensionsVersionString[];

#import <MADCocoaExtensions/MADViewHelpers.h>
#import <MADCocoaExtensions/NSNumberFormatter+MADExtensions.h>
#import <MADCocoaExtensions/MTMath.h>
#import <MADCocoaExtensions/MADLabelTitle.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import <MADCocoaExtensions/MADAlertController.h>
#import <MADCocoaExtensions/MADAlertControllerAlertRemovedProtocol.h>
#import <MADCocoaExtensions/MADTextField.h>

#import <MADCocoaExtensions/NSError+Constructors.h>
#import <MADCocoaExtensions/UIApplication+Helpers.h>

#import <MADCocoaExtensions/MAD2dDirection.h>
#import <MADCocoaExtensions/MADAspectRatio.h>
#import <MADCocoaExtensions/MADResizeAspect.h>

#import <MADCocoaExtensions/MADColorSocial.h>
#import <MADCocoaExtensions/MFMailComposeViewController+MADExtensions.h>

#import <MADCocoaExtensions/MADMargin.h>
#import <MADCocoaExtensions/MADPadding.h>
#import <MADCocoaExtensions/MADBorderStyle.h>
#import <MADCocoaExtensions/MADTextStyle.h>

// Remaining public headers, so the module umbrella is complete.
// (-Wincomplete-umbrella; keep in sync with the Public headers phase.)
#import <MADCocoaExtensions/MADColor.h>
#import <MADCocoaExtensions/MADCompassDirection.h>
#import <MADCocoaExtensions/MADLineSegment.h>
#import <MADCocoaExtensions/MADMathAlgebra.h>
