//
//  MADVectorBool.h
//  MADDataStructures
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MADVectorBool : NSObject

    - (void)addTrue;
    - (void)addFalse;
    - (unsigned long)count;
    - (void)enumerateBools:(void (^)(NSUInteger idx, BOOL valid, BOOL *stop))valueHandler;

@end
