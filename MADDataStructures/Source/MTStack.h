//
//  MTStack.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/11/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_DataStructures_MTStack_h
#define MAD_DataStructures_MTStack_h

#import <MADDataStructures/MTObject.h>
#import <Foundation/NSEnumerator.h>
#import <MADDataStructures/MTProtocolLog.h>

@interface MTStack : NSObject <NSFastEnumeration, MTProtocolLog>

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithObject:(id)object NS_DESIGNATED_INITIALIZER;
- (void)push:(id)object;
- (id)pop;
- (BOOL)isEmpty;

@end

#endif
