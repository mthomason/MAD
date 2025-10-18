//
//  MTProtocolEnumerator.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 2/3/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
