//
//  MTViewControllerBarcodePreviewDelegate.h
//  MAD
//
//  Created by Michael Thomason on 9/28/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTViewControllerBarcodePreviewDelegate_h
#define MAD_MTViewControllerBarcodePreviewDelegate_h

#import <MADBarcodes/MADBarcodes.h>

@protocol MTViewControllerBarcodePreviewDelegate
- (void)didChangeBarcodeType:(MTBarcodeType)type;
@end

#endif
