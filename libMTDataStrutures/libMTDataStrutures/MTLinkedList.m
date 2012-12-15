//
//  MNLinkedList.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTLinkedList.h"

@interface MTLinkedList()

@property (nonatomic, retain) NSMutableArray *list;
@property (assign) NSInteger location;

@end

@implementation MTLinkedList

- (void)dealloc {
    [_list release];
	[super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {
        [self setLocation: 0];
        NSMutableArray *list = [[NSMutableArray alloc] init];
        [self setList:list];
        [list release];
    }
    return self;
}

- (NSUInteger)count {
    return [[self list] count];
}

- (bool)isNext {
    return ([self location] + 1 < [self count]);
}

- (bool)isPrevious {
    return ([self location] - 1 < [self count] && [self location] > 0);
}

- (void)add:(id)object {
    if (object != nil) {
        [[self list] addObject:object];
        [self setLocation: [self count] - 1];
    }
}

- (id)head {
    id result;
    @synchronized(self) {
        result = [[[[self list] objectAtIndex:0] retain] autorelease];
    }
    return result;
}

- (id)getNext {
    id result;
    @synchronized(self) {
        if ([self isNext]) {
            self.location++;
            result = [[[[self list] objectAtIndex:[self location]] retain] autorelease];
        } else {
            result = nil;
        }
    }
    return result;
}

- (id)getPrevious {
    id result;
    @synchronized(self) {
        if ([self isPrevious]) {
            self.location--;
            result = [[[[self list] objectAtIndex:[self location]] retain] autorelease];
        } else {
            result = nil;
        }
    }
    return result;
}

- (id)getTop {
    return ([self count] > 0) ? [[self list] lastObject] : nil;
}

- (id)getBottom {
    return ([self count] > 0) ? [[self list] objectAtIndex:0] : nil;
}

- (id)objectAtIndex:(NSUInteger)index {
    return [[self list] objectAtIndex:index];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len {
    BOOL haveAnother = state->state < [[self list] count];
    NSUInteger result = haveAnother ? 1 : 0;
    if (haveAnother) {
        state->itemsPtr[0] = [[self list] objectAtIndex:state->state];
        state->state++;
    }
    return result;
}

- (NSString *)humanReadableObjectIdentifier {
    return nil;
}

- (NSString *)toString {
    return nil;
}

- (NSString *)toStringForDebugging {
    return [NSString stringWithFormat:@"%@", [self destination]];
}

@end