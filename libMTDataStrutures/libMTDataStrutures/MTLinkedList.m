//
//  MNLinkedList.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTLinkedList.h"

@interface MTLinkedList()

@property (nonatomic, retain) NSMutableArray *list;
@property (assign) NSInteger location;

@end

@implementation MTLinkedList

- (id)init {
    self = [super init];
    if (self) {
        [self setLocation: 0];
        NSMutableArray *list = [[NSMutableArray alloc] init];
        [self setList:list];
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

- (void)insert:(id)object {
    if (object != nil) {
        [[self list] insertObject:object atIndex:0];
    }
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
        result = [[self list] objectAtIndex:0];
    }
    return result;
}

- (id)getNext {
    id result;
    @synchronized(self) {
        if ([self isNext]) {
            self.location++;
            result = [[self list] objectAtIndex:[self location]];
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
            result = [[self list] objectAtIndex:[self location]];
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

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])stackbuf count:(NSUInteger)len {
    return [[self list] countByEnumeratingWithState:state objects:stackbuf count:len];
}

- (NSString *)toStringHumanReadable {
    NSMutableString *result = [[NSMutableString alloc] initWithString:@"*<->"];
    for (id object in [self list]) {
        if ([object conformsToProtocol:@protocol(MTProtocolLog)]) {
            [result appendFormat:@"%@<->", [object toStringHumanReadable]];
        } else {
            [result appendFormat:@"%@<->", object];
        }
    }
    [result appendString:@"*"];
    return result;
}

- (NSString *)toString {
    return nil;
}

- (NSString *)toStringDebug {
    return [NSString stringWithFormat:@"%@", self];
}

- (void)reverse {
    NSArray *reverse = [[[self list] reverseObjectEnumerator] allObjects];
    NSMutableArray *newList = [[NSMutableArray alloc] initWithArray:reverse];
    [self setList:newList];
}

- (NSArray *)toArray {
    return [self list];
}

@end
