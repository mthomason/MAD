//
//  MADBarcodeView.h
//  Barcodes
//
//  Created by Michael Thomason on 11/3/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Barcodes_MADBarcodeView_h
#define Barcodes_MADBarcodeView_h

#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIView.h>
typedef UIView MADBarcodeSuperView;
#elif TARGET_OS_OSX
#import <AppKit/NSView.h>
typedef NSView MADBarcodeSuperView;
#endif

@class MADBarcode;

@interface MADBarcodeView : MADBarcodeSuperView

	@property (nonatomic, retain) MADBarcode *barcode;

@end

#endif
