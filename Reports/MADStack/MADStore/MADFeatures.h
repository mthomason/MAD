//
//  MADFeatures.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/21/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADFeatures_h
#define MAD_Designer_MADFeatures_h

#import <Foundation/NSObject.h>

@class  MADFeature;

@interface MADFeatures : NSObject

@property (nonatomic, strong, readonly) NSArray *features;

    - (NSArray *)availableFeatures;
    - (NSArray *)availableFeaturesProductIDs;
    - (MADFeature *)featureForProductID:(NSString *)productID;

@end

#endif
