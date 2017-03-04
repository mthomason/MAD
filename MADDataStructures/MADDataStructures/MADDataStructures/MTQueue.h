//
//  MTQueue.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/11/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_DataStructures_MTQueue_h
#define MAD_DataStructures_MTQueue_h

#import <Foundation/NSObject.h>
#import <Foundation/NSEnumerator.h>
#import "MTProtocolLog.h"

#ifndef NS_DESIGNATED_INITIALIZER
  #if __has_attribute(objc_designated_initializer)
    #define NS_DESIGNATED_INITIALIZER __attribute((objc_designated_initializer))
  #else
    #define NS_DESIGNATED_INITIALIZER
  #endif
#endif

@interface MTQueue : NSObject
    <NSFastEnumeration,  MTProtocolLog>

    - (instancetype)init NS_DESIGNATED_INITIALIZER;
    - (instancetype)initWithCapacity:(NSUInteger)capacity NS_DESIGNATED_INITIALIZER;
    - (void)enqueue:(id)object;
    - (id)dequeue;
    - (NSUInteger)count;

@end

#endif
