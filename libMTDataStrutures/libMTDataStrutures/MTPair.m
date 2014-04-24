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

@interface MTPair ()

@end

@implementation MTPair

- (id)init {
    return [self initWithFormer:nil andLatter:nil];
}

- (id)initWithFormer:(id)former andLatter:(id)latter {
    self = [super init];
    if (self) {
        
        [self setFormer:former];
        [self setLatter:latter];
        
    }
    return self;
}

+ (id)pairWithFormer:(id)former andLatter:(id)latter {
    id result = [[self alloc] initWithFormer:former andLatter:latter];
    return result;
}

- (NSString *)toStringHumanReadable {
    Protocol *protocolLog = @protocol(MTProtocolLog);
    BOOL formerConfirmsToLoggingProtocol = [[self former] conformsToProtocol: protocolLog];
    BOOL latterConfirmsToLoggingProtocol = [[self latter] conformsToProtocol: protocolLog];
    NSString *formerToString = formerConfirmsToLoggingProtocol ? [[self former] toStringHumanReadable] : [NSString stringWithFormat:@"%@", [self former]];
    NSString *latterToString = latterConfirmsToLoggingProtocol ? [[self latter] toStringHumanReadable] : [NSString stringWithFormat:@"%@", [self latter]];
    return [NSString stringWithFormat:@"(%@, %@)", formerToString, latterToString];
}

- (NSString *)toString {
    return [self toStringHumanReadable];
}

- (NSString *)toStringDebug {
    return [self toStringHumanReadable];
}

@end
