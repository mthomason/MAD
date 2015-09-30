//
//  MADFeatures.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/21/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/NSObject.h>

@class  MADFeature;

@interface MADFeatures : NSObject

@property (nonatomic, strong, readonly) NSArray *features;

- (NSArray *)availableFeatures;
- (NSArray *)availableFeaturesProductIDs;
- (MADFeature *)featureForProductID:(NSString *)productID;

@end
