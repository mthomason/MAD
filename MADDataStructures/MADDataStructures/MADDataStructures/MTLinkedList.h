//
//  MNLinkedList.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_DataStructures_MTLinkedList_h
#define MAD_DataStructures_MTLinkedList_h

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

@interface MTLinkedList : NSObject <NSFastEnumeration, MTProtocolLog>

    - (instancetype)init NS_DESIGNATED_INITIALIZER;
    - (NSUInteger)count;
    - (void)insert:(id)object;
    - (void)add:(id)object;
    - (id)head;
    - (id)getNext;
    - (id)getPrevious;
    - (id)getTop;
    - (id)getBottom;
    - (BOOL)isNext;
    - (BOOL)isPrevious;
    - (id)objectAtIndex:(NSUInteger)index;
    - (void)reverse;
    - (NSArray *)toArray;

@end

#endif
