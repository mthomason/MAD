//
//  MADUserDefault.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/16/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADUserDefault.h"

@interface MADUserDefault()
    @property (nonatomic, strong) NSString *identifier;
    @property (nonatomic, assign) BOOL shared;
@end

@implementation MADUserDefault

- (instancetype)initWithIdentifier:(NSString *)identifier {
    if (self = [super init]) {
        NSString *i = [NSString stringWithString:identifier];
        self.identifier = i;
        self.shared = NO;
    }
    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier shared:(BOOL)shared {
    if (self = [super init]) {
        NSString *i = [NSString stringWithString:identifier];
        self.identifier = i;
        self.shared = shared;
    }
    return self;
}

@end
