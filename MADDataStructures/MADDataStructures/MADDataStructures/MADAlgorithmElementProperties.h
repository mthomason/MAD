//
//  MADAlgorithmElementColor.h
//  MADDataStructures
//
//  Created by Michael Thomason on 3/12/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_DataStructures_MADAlgorithmElementProperties_h
#define MAD_DataStructures_MADAlgorithmElementProperties_h

#import <Foundation/NSObject.h>
#import <MADDataStructures/MADAlgorithmColor.h>

@interface MADAlgorithmElementProperties : NSObject
    <NSCopying>

    - (instancetype)initWithColor:(MADAlgorithmColor)algorithmColor NS_DESIGNATED_INITIALIZER;
    @property (nonatomic, assign) MADAlgorithmColor algorithmColor;

@end

#endif
