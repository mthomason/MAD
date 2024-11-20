//
//  MADPreference.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/17/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADPreference.h"
#import <Foundation/NSString.h>

@interface MADPreference ()

    @property (nonatomic, strong) NSString *key;
    @property (nonatomic, assign) BOOL allowCloud;
    @property (nonatomic, assign) BOOL encrypt;

@end

@implementation MADPreference

- (instancetype)initWithKey:(NSString *)key {
    MADPreference *p = [[MADPreference alloc] initWithKey:key allowCloud:YES encrypt:NO];
    return p;
}

- (instancetype)initWithKey:(NSString *)key allowCloud:(BOOL)allowCloud encrypt:(BOOL)encrypt {
    if (self = [super init]) {
        
        _key = key.copy;
        _allowCloud = allowCloud;
        _encrypt = encrypt;
        
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:[MADPreference class]] ?
        [self.key compare:((MADPreference *)object).key] : NO;
}

- (NSUInteger)hash {
    return self.key.hash;
}

@end
