//
//  MADFeatures.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/21/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADFeatures_h
#define MAD_Designer_MADFeatures_h

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>

@class  MADFeature;

@interface MADFeatures : NSObject

@property (readonly, nonatomic, strong) NSArray <MADFeature *> *features;

- (NSArray <MADFeature *> *)availableFeatures;
- (NSArray <NSString *> *)availableFeaturesProductIDs;
- (MADFeature *)featureForProductID:(NSString *)productID;
- (BOOL)loadFeaturesFromPlist;

@end

#endif
