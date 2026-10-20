//
//  MTViewControllerBarcodePreviewDelegate.h
//  MAD
//
//  Created by Michael Thomason on 9/28/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MTViewControllerBarcodePreviewDelegate_h
#define MAD_MTViewControllerBarcodePreviewDelegate_h

#import <MADBarcodes/MADBarcodeType.h>

@protocol MTViewControllerBarcodePreviewDelegate
	- (void)didChangeBarcodeType:(MADBarcodeType)type;
@end

#endif
