//
//  MNLinkedList.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTProtocolLog.h"

// MARK: Just a wrapper around NSArray.

@interface MTLinkedList : NSObject <NSFastEnumeration, MTProtocolLog>

- (NSUInteger)count;
- (void)add:(id)object;
- (id)head;
- (id)getNext;
- (id)getPrevious;
- (id)getTop;
- (id)getBottom;
- (bool)isNext;
- (bool)isPrevious;
- (id)objectAtIndex:(NSUInteger)index;

@end