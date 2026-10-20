//
//  MADBarcodeSizingMode.h
//  MADBarcodes
//
//  Created by Michael Thomason on 6/14/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADBarcodeSizingMode_h
#define MADBarcodeSizingMode_h

typedef NS_ENUM(unsigned char, MADBarcodeSizingMode) {
	MADBarcodeSizingModeAutomaticResizing	= 1,
	MADBarcodeSizingModeSpecificSize			= 2,
	MADBarcodeSizingModeSpecificErrorLevel	= 3
};

#endif /* MADBarcodeSizingMode_h */
