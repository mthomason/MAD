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
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>

@interface MTLinkedList()

    @property (nonatomic, strong) NSMutableArray *list;

@end

@implementation MTLinkedList {
    NSUInteger _location;
}

- (instancetype)init {
    if (self = [super init]) {
        _location = 0;
        _list = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSUInteger)count { return _list.count; }

- (BOOL)isNext { return (_location + 1 < self.count); }

- (BOOL)isPrevious { return (_location - 1 < self.count && _location > 0); }

- (void)insert:(id)object {
    if (object != nil) {
        [_list insertObject:object atIndex:0];
    }
}

- (void)add:(id)object {
    if (object != nil) {
        [_list addObject:object];
        _location = self.count - 1;
    }
}

- (id)head {
    id result;
    @synchronized(self) {
        result = (_list)[0];
    }
    return result;
}

- (id)getNext {
    id result;
    @synchronized(self) {
        if ([self isNext]) {
            _location++;
            result = (_list)[_location];
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
            _location--;
            result = (_list)[_location];
        } else {
            result = nil;
        }
    }
    return result;
}

- (id)getTop {
    return (self.count > 0) ? (_list).lastObject : nil;
}

- (id)getBottom {
    return (self.count > 0) ? (_list)[0] : nil;
}

- (id)objectAtIndex:(NSUInteger)index {
    return (_list)[index];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])stackbuf
                                    count:(NSUInteger)len {
    return [_list countByEnumeratingWithState:state objects:stackbuf count:len];
}

- (NSString *)toStringHumanReadable {
    NSMutableString *result = [[NSMutableString alloc] initWithString:@"*<->"];
    for (id object in _list) {
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
    NSMutableArray *reverse = _list.reverseObjectEnumerator.allObjects.mutableCopy;
    _list = reverse;
}

- (NSArray *)toArray {
    return _list;
}

@end
