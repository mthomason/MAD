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

@interface MTObject : NSObject <NSCopying, MTProtocolCompare, MTProtocolLog>

@property (atomic, strong) id object;

- (instancetype)init;
- (instancetype)initWithObject:(id <NSCopying>)object;
+ (instancetype)objectWithObject:(id <NSCopying>)object;

@end

#endif
