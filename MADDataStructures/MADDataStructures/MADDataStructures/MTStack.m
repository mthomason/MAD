//
//  MTStack.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/11/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTStack.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>

@interface MTStack ()

@property (nonatomic, strong) NSMutableArray *stack;
@property (nonatomic, assign) NSUInteger counter;

@end

@implementation MTStack

- (instancetype)init {
	if (self = [super init]) {
		NSMutableArray *stack = [[NSMutableArray alloc] init];
		self.stack = stack;
	}
	return self;
}

- (instancetype)initWithObject:(id)object {
	if (self = [super initWithObject:object]) {
		NSMutableArray *stack = [[NSMutableArray alloc] init];
		self.stack = stack;
	}
	return self;
}

- (instancetype)initWithCapacity:(NSUInteger)capacity {
	if (self = [super init]) {
		NSMutableArray *stack = [[NSMutableArray alloc] initWithCapacity:capacity];
		self.stack = stack;
	}
	return self;
}

- (void)push:(id)object {
	[self.stack addObject:object];
	self.counter++;
}

- (id)pop {
	NSAssert(self.counter > 0, @"Underflow error.  Nothing to pop.");
	id result = self.stack.lastObject;
	[self.stack removeLastObject];
	self.counter--;
	return result;
}

- (BOOL)isEmpty {
	return self.counter <= 0;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
								  objects:(id __unsafe_unretained [])stackbuf
									count:(NSUInteger)len {
	return [self.stack countByEnumeratingWithState:state objects:stackbuf count:len];
}

- (NSString *)toStringHumanReadable {
	return nil;
}

- (NSString *)toString {
	return nil;
}

- (NSString *)toStringDebug {
	return [NSString stringWithFormat:@"%@", self];
}

@end
