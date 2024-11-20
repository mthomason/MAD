//
//  MADFeatures.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/21/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADFeatures.h"
#import "MADFeature.h"
#import <Foundation/NSPredicate.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>

static NSString * const Features = @"MADFeatures";
static NSString * const Plist = @"plist";

@interface MADFeatures ()

@property (nonatomic, strong, readwrite) NSArray *features;
@property (nonatomic, strong) NSPredicate *availablePredicate;

@end

@implementation MADFeatures

- (instancetype)init {
    if (self = [super init]) {
        NSPredicate *available = [NSPredicate predicateWithBlock:^BOOL(MADFeature *feature, NSDictionary *bindings) {
            return feature.available;
        }];
        self.availablePredicate = available;
        NSString *path = [[NSBundle mainBundle] pathForResource:Features ofType:Plist];
        NSArray *features = [NSArray arrayWithContentsOfFile:path];
        NSAssert(features.count > 0, @"No features found! FML!!! Maybe clean and recompile.");
        NSMutableArray *fa = [[NSMutableArray alloc] initWithCapacity:features.count];
        for (NSDictionary *feature in features) {
            MADFeature *f = [[MADFeature alloc] initWithDictionary:feature];
            [fa addObject:f];
        }
        self.features = [NSArray arrayWithArray:fa];
    }
    return self;
}

- (NSArray *)availableFeatures {
    return [self.features filteredArrayUsingPredicate:self.availablePredicate];
}

- (NSArray *)availableFeaturesProductIDs {
    NSArray *availableFeatures = [self availableFeatures];
    NSMutableArray *featureIDs = [[NSMutableArray alloc] initWithCapacity:self.availableFeatures.count];
    for (MADFeature *feature in availableFeatures) {
        [featureIDs addObject:feature.productID];
    }
    return featureIDs;
}

- (MADFeature *)featureForProductID:(NSString *)productID {
    NSPredicate *product = [NSPredicate predicateWithBlock:^BOOL(MADFeature *feature, NSDictionary *bindings) {
        return [feature.productID isEqualToString:productID];
    }];
    return [self.features filteredArrayUsingPredicate:product].firstObject;
}

@end
