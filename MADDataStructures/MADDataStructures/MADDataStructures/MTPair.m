//
//  MTPair.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPair.h"
#import "MTObject.h"
#import <Foundation/NSString.h>

@implementation MTPair

- (id)copyWithZone:(nullable NSZone *)zone {
	id copy = [[[self class] alloc] initWithFormer:self.former andLatter:self.latter];
	return copy;
}

- (instancetype)init {
	return [self initWithFormer:nil andLatter:nil];
}

- (instancetype)initWithFormer:(id)former andLatter:(id)latter {
	
	if (self = [super init]) {
		
		id f = former;
		self.former = f;
		
		id l = latter;
		self.latter = l;
		
	}
	
	return self;
}

- (instancetype)initWithLeft:(id)left andRight:(id)right {
	
	if (self = [super init]) {
		
		id f = left;
		self.former = f;
		
		id l = right;
		self.latter = l;
	}
	return self;
}

+ (instancetype)newPairWithFormer:(id)former andLatter:(id)latter {
	id result = [[self alloc] initWithFormer:former andLatter:latter];
	return result;
}

+ (instancetype)newPairWithLeft:(id)left andRight:(id)right   {
	id result = [[self alloc] initWithLeft:left andRight:right];
	return result;
}

- (NSString *)toStringHumanReadable {
	Protocol *protocolLog = @protocol(MTProtocolLog);
	BOOL formerConfirmsToLoggingProtocol = [self.former conformsToProtocol: protocolLog];
	BOOL latterConfirmsToLoggingProtocol = [self.latter conformsToProtocol: protocolLog];
	NSString *formerToString = formerConfirmsToLoggingProtocol ?
							[((id <MTProtocolLog>)self.former) toStringHumanReadable] :
							[NSString stringWithFormat:@"%@", self.former];
	NSString *latterToString = latterConfirmsToLoggingProtocol ?
							[((id <MTProtocolLog>)self.latter) toStringHumanReadable] :
							[NSString stringWithFormat:@"%@", self.latter];
	NSString *result = [[NSString alloc] initWithFormat:@"(%@, %@)", formerToString, latterToString];
	return result;
}

- (NSObject <NSCopying> *)left {
	return self.former;
}

- (NSObject <NSCopying> *)right {
	return self.latter;
}

- (NSString *)toString {
	return [self toStringHumanReadable];
}

- (NSString *)toStringDebug {
	return [self toStringHumanReadable];
}

@end
