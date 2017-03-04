//
//  MADFeature.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/21/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADFeature.h"
#import <Foundation/NSDictionary.h>
#import <Foundation/NSValue.h>

static NSString * const ProductID       = @"product-id";
static NSString * const AppleID         = @"apple-id";
static NSString * const Title           = @"title";
static NSString * const Description     = @"description";
static NSString * const Type            = @"type";
static NSString * const Available       = @"available";

@interface MADFeature ()

@property (nonatomic, strong) NSDictionary *feature;

@end

@implementation MADFeature

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        NSDictionary *feature = [NSDictionary dictionaryWithDictionary:dictionary];
        self.feature = feature;
    }
    return self;
}

- (NSString *)productID {
    return self.feature[ProductID];
}

- (NSString *)appleID {
    return self.feature[AppleID];
}

- (NSString *)defaultTitle {
    return self.feature[Title];
}

- (NSString *)defaultDescription {
    return self.feature[Description];
}

- (MADFeatureType)type {
    return ((NSNumber *)self.feature[Type]).shortValue;
}

- (BOOL)available {
    return ((NSNumber *)self.feature[Available]).boolValue;
}

@end
