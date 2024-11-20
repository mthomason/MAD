//
//  MADBarcodeBorderStyle.h
//  MADBarcodes
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADBarcodeBorderStyle_h
#define MADBarcodeBorderStyle_h

#import "zint.h"

typedef NS_ENUM(int16_t, MTBarcodeBorderStyle) {
    MTBarcodeBorderStyleNone    = 0,
    MTBarcodeBorderStyleBind    = BARCODE_BIND,
    MTBarcodeBorderStyleBox     = BARCODE_BOX
};

#endif /* MADBarcodeBorderStyle_h */
