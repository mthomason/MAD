//
//  MADFeature.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/21/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/NSObject.h>

typedef NS_ENUM(NSUInteger, MADFeatureType) {
    MADFeatureTypeNonConsumable                     = 1,
    MADFeatureTypeSubscription                      = 2
};

@interface MADFeature : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (readonly) NSString *productID;
@property (readonly) NSString *appleID;
@property (readonly) NSString *defaultTitle;
@property (readonly) NSString *defaultDescription;
@property (readonly) MADFeatureType type;
@property (readonly) BOOL available;

@end
