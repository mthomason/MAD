//
//  MADBarcodeSizingMode.h
//  MADBarcodes
//
//  Created by Michael Thomason on 6/14/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADBarcodeSizingMode_h
#define MADBarcodeSizingMode_h

typedef NS_ENUM(unsigned char, MTBarcodeSizingMode) {
    MTBarcodeSizingModeAutomaticResizing     = 1,
    MTBarcodeSizingModeSpecificSize          = 2,
    MTBarcodeSizingModeSpecificErrorLevel    = 3
};

#endif /* MADBarcodeSizingMode_h */
