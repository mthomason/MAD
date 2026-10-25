//
//  MADBarcodeSizingMode.h
//  MADBarcodes
//
//  Created by Michael Thomason on 6/14/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADBarcodeSizingMode_h
#define MADBarcodeSizingMode_h

typedef NS_ENUM(unsigned char, MADBarcodeSizingMode) {
	MADBarcodeSizingModeAutomaticResizing	= 1,
	MADBarcodeSizingModeSpecificSize			= 2,
	MADBarcodeSizingModeSpecificErrorLevel	= 3
};

#endif /* MADBarcodeSizingMode_h */
