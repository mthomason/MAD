//
//  MADVectorBool.h
//  MADDataStructures
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_DataStructures_MADVectorBool_h
#define MAD_DataStructures_MADVectorBool_h

#import <Foundation/NSObject.h>

@interface MADVectorBool : NSObject

	- (void)push:(BOOL)value;
	- (void)addTrue;
	- (void)addFalse;
	- (unsigned long)count;
	- (void)enumerateBools:(void (^)(NSUInteger idx, BOOL valid, BOOL *stop))valueHandler;

@end

#endif
