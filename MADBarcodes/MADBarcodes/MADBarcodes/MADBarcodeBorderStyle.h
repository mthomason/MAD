//
//  MADBarcodeBorderStyle.h
//  MADBarcodes
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADBarcodeBorderStyle_h
#define MADBarcodeBorderStyle_h

#import <MADBarcodes/zint.h>

typedef NS_ENUM(int16_t, MADBarcodeBorderStyle) {
	MADBarcodeBorderStyleNone	= 0,
	MADBarcodeBorderStyleBind	= BARCODE_BIND,
	MADBarcodeBorderStyleBox	 = BARCODE_BOX
};

#endif /* MADBarcodeBorderStyle_h */
