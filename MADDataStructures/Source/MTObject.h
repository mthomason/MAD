//
//  MTObject.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/11/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_DataStructures_MTObject_h
#define MAD_DataStructures_MTObject_h

#import <Foundation/NSObject.h>
#import <MADDataStructures/MTProtocolLog.h>
#import <MADDataStructures/MTProtocolCompare.h>

#ifndef NS_DESIGNATED_INITIALIZER
  #if __has_attribute(objc_designated_initializer)
    #define NS_DESIGNATED_INITIALIZER __attribute((objc_designated_initializer))
  #else
    #define NS_DESIGNATED_INITIALIZER
  #endif
#endif

@interface MTObject : NSObject <NSCopying, MTProtocolCompare, MTProtocolLog>

	@property (readonly, nonatomic, strong) __kindof NSObject <NSCopying> *object;

	+ (instancetype)newObject:(NSObject <NSCopying> *)object;
	- (instancetype)init;
	- (instancetype)initWithObject:(NSObject <NSCopying> *)object;

@end

#endif
