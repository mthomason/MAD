//
//  MADFeatures.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/21/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADFeatures_h
#define Reports_MADFeatures_h

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>

@class  MADFeature;

@interface MADFeatures : NSObject

    @property (nonatomic, strong, readonly) NSArray <__kindof MADFeature *> *features;

    - (NSArray *)availableFeatures;
    - (NSArray *)availableFeaturesProductIDs;
    - (MADFeature *)featureForProductID:(NSString *)productID;

@end

#endif
