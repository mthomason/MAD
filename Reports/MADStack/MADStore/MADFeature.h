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
	MADFeatureTypeNonConsumable = 1,
	MADFeatureTypeSubscription = 2
};

@interface MADFeature : NSObject <NSSecureCoding, NSCopying>

@property (readonly, nonatomic, copy) NSString *productID;
@property (readonly, nonatomic, copy) NSString *appleID;
@property (readonly, nonatomic, copy) NSString *defaultTitle;
@property (readonly, nonatomic, copy) NSString *defaultDescription;
@property (readonly, nonatomic) MADFeatureType type;
@property (readonly, nonatomic) BOOL available;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary __deprecated_msg("Use initWithProductID:appleID:title:description:type:available: instead.");
- (instancetype)initWithProductID:(NSString *)productID appleID:(NSString *)appleID title:(NSString *)title description:(NSString *)description type:(MADFeatureType)type available:(BOOL)available;

@end

#endif
