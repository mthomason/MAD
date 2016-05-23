//
//  MADBarcodeBorderStyle.h
//  MADBarcodes
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADBarcodeBorderStyle_h
#define MADBarcodeBorderStyle_h

#import "zint.h"

typedef NS_ENUM(unsigned char, MTBarcodeBorderStyle) {
    MTBarcodeBorderStyleNone    = 0,
    MTBarcodeBorderStyleBind    = BARCODE_BIND,
    MTBarcodeBorderStyleBox     = BARCODE_BOX
};

#endif /* MADBarcodeBorderStyle_h */
