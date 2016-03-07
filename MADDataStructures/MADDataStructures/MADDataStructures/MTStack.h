//
//  MTStack.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/11/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_DataStructures_MTStack_h
#define MAD_DataStructures_MTStack_h

#import "MTObject.h"
#import <Foundation/NSEnumerator.h>
#import "MTProtocolLog.h"

@interface MTStack : MTObject  <NSFastEnumeration,  MTProtocolLog>

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithObject:(id)object NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCapacity:(NSUInteger)capacity NS_DESIGNATED_INITIALIZER;
- (void)push:(id)object;
- (id)pop;
- (BOOL)isEmpty;

@end

#endif
