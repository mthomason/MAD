//
//  MADAssert.h
//  MADFoundation
//
//  Created by Michael Thomason on 5/31/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADAssert_h
#define MADAssert_h

    #ifndef DEBUG
        #import <Foundation/NSException.h>
        #define MADAssert NSAssert(condition, desc, ...)
    #else
        #import <Foundation/NSException.h>
        #define MADAssert NSAssert(condition, desc, ...)
    #endif

#endif /* MADAssert_h */
