//
//  MADModelType.h
//  MAD
//
//  Created by Michael on 3/31/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The kinds a MADModel can be.  Declared early; nothing in the tree reads it
//  (MADModel_Layer.md §6).
//

#ifndef MADModelType_h
#define MADModelType_h

typedef NS_ENUM(short, MADModelType) {
	MADModelTypeUnknown = 0,
	MADModelTypeDocument,
	MADModelTypeDatabase,
	MADModelTypeQueries,
};

#endif /* MADModelType_h */
