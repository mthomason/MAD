//
//  MNLinkedList.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTLinkedList : NSObject

- (NSUInteger)count;
- (void)add:(id)object;
- (id)getNext;
- (id)getPrevious;
- (id)getTop;
- (id)getBottom;
- (bool)isNext;
- (bool)isPrevious;
- (id)objectAtIndex:(NSUInteger)index;

@end