//
//  MTObject.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/11/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_DataStructures_MTObject_h
#define MAD_DataStructures_MTObject_h

#import <Foundation/NSObject.h>
#import "MTProtocolLog.h"
#import "MTProtocolCompare.h"

#ifndef NS_DESIGNATED_INITIALIZER
  #if __has_attribute(objc_designated_initializer)
    #define NS_DESIGNATED_INITIALIZER __attribute((objc_designated_initializer))
  #else
    #define NS_DESIGNATED_INITIALIZER
  #endif
#endif

@interface MTObject : NSObject
    <NSCopying, MTProtocolCompare, MTProtocolLog>

    + (instancetype)newObject:(id <NSCopying>)object;
    - (instancetype)init;
    - (instancetype)initWithObject:(id <NSCopying>)object;

    @property (readonly, nonatomic, strong) id object;

@end

#endif
