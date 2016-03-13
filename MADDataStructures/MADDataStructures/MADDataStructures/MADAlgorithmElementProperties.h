//
//  MADAlgorithmElementColor.h
//  MADDataStructures
//
//  Created by Michael Thomason on 3/12/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/NSObject.h>

typedef NS_ENUM(short, MTAlgorithmColor) {
    MTColorBlack,
    MTColorWhite,
    MTColorGray
};

@interface MADAlgorithmElementProperties : NSObject

    @property (atomic, assign) MTAlgorithmColor vertexColor;

@end
