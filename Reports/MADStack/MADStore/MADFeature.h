//
//  MADFeature.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/21/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADFeature_h
#define MAD_Designer_MADFeature_h

#import <Foundation/NSObject.h>

typedef NS_ENUM(short, MADFeatureType) {
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

#endif
