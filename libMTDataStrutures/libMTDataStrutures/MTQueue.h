//
//  MTQueue.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/11/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTQueue : NSObject  <NSFastEnumeration>

- (void)enqueue:(id)object;
- (id)dequeue;
- (NSUInteger)count;

@end