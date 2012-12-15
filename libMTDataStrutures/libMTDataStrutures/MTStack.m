//
//  MTStack.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/11/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTStack.h"

@interface MTStack ()

@property (retain) NSMutableArray *stack;
@property (assign) NSUInteger counter;

@end

@implementation MTStack

- (void)dealloc {
    [_stack release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {
        NSMutableArray *stack = [[NSMutableArray alloc] init];
        [self setStack:stack];
        [stack release];
    }
    return self;
}

- (id)initWithCapacity:(NSUInteger)capacity {
    self = [super init];
    if (self) {
        NSMutableArray *stack = [[NSMutableArray alloc] initWithCapacity:capacity];
        [self setStack:stack];
        [stack release];
    }
    return self;
}

- (void)push:(id)object {
    [[self stack] addObject:object];
    self.counter++;
}

- (id)pop {
    if ([self counter] <= 0) {
        @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                       reason: @"Underflow error."
                                     userInfo: nil];
    }
    id result = [[[self stack] lastObject] retain];
    [[self stack] removeLastObject];
    self.counter--;
    return [result autorelease];
}

- (BOOL)isEmpty {
    return [self counter] <= 0;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len {
    BOOL haveAnother = state->state < [[self stack] count];
    NSUInteger result = haveAnother ? 1 : 0;
    if (haveAnother) {
        state->itemsPtr[0] = [[self stack] objectAtIndex:state->state];
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
    return [NSString stringWithFormat:@"%@", self];
}

@end