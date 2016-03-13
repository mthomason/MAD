//
//  MTPair.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPair.h"
#import "MTObject.h"
#import <Foundation/NSString.h>

@implementation MTPair

- (id)copyWithZone:(nullable NSZone *)zone {
    id <NSCopying> former = [self.former copyWithZone:zone];
    id <NSCopying> latter = [self.latter copyWithZone:zone];
    id copy = [[[self class] allocWithZone:zone] initWithFormer:former andLatter:latter];
    return copy;
}

- (instancetype)init {
    return [self initWithFormer:nil andLatter:nil];
}

- (instancetype)initWithFormer:(id <NSCopying>)former andLatter:(id <NSCopying>)latter {

    if (self = [super init]) {

        id f = [former copyWithZone:NULL];
        self.former = f;
        
        id l = [latter copyWithZone:NULL];
        self.latter = l;
        
    }

    return self;
}

- (instancetype)initWithLeft:(id <NSCopying>)left andRight:(id <NSCopying>)right {
    return [self initWithFormer:left andLatter:right];
}

+ (instancetype)newPairWithFormer:(id <NSCopying>)former andLatter:(id <NSCopying>)latter {
    id result = [[self alloc] initWithFormer:former andLatter:latter];
    return result;
}

+ (instancetype)newPairWithLeft:(id <NSCopying>)left andRight:(id <NSCopying>)right   {
    id result = [[self alloc] initWithLeft:left andRight:right];
    return result;
}

- (NSString *)toStringHumanReadable {
    Protocol *protocolLog = @protocol(MTProtocolLog);
    BOOL formerConfirmsToLoggingProtocol = [self.former conformsToProtocol: protocolLog];
    BOOL latterConfirmsToLoggingProtocol = [self.latter conformsToProtocol: protocolLog];
    NSString *formerToString = formerConfirmsToLoggingProtocol ? [self.former toStringHumanReadable] : [NSString stringWithFormat:@"%@", self.former];
    NSString *latterToString = latterConfirmsToLoggingProtocol ? [self.latter toStringHumanReadable] : [NSString stringWithFormat:@"%@", self.latter];
    return [NSString stringWithFormat:@"(%@, %@)", formerToString, latterToString];
}

- (id)left {
    return self.former;
}

- (id)right {
    return self.latter;
}

- (NSString *)toString {
    return [self toStringHumanReadable];
}

- (NSString *)toStringDebug {
    return [self toStringHumanReadable];
}

@end
