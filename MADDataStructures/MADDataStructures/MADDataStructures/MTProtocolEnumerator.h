//
//  MTProtocolEnumerator.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 2/3/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_DataStructures_MTProtocolEnumerator_h
#define MAD_DataStructures_MTProtocolEnumerator_h

#import <Foundation/NSObject.h>

@protocol MTProtocolEnumerator <NSObject>

- (id)next;
- (id)previous;

@optional

- (id)first;
- (id)last;

@end

#endif
