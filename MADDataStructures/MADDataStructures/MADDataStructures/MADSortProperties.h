//
//  MADSortProperties.h
//  MADDataStructures
//
//  Created by Michael Thomason on 3/12/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_DataStructures_MADSortProperties_h
#define MAD_DataStructures_MADSortProperties_h

#import <Foundation/NSObject.h>
#import "MADAlgorithmColor.h"

@interface MADSortProperties : NSObject
    <NSCopying>

    @property (atomic, assign) MADAlgorithmColor algorithmColor;

@end

#endif
