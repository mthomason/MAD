//
//  MADHorizontalAlignmentType.h
//  MAD
//
//  Created by Michael on 2/16/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADHorizontalAlignmentType_h
#define MADHorizontalAlignmentType_h

#import <sys/types.h>

typedef enum MADHorizontalAlignment : int16_t {
    MADHorizontalAlignmentUnknown = -1,
    MADHorizontalAlignmentLeft = 0,
    MADHorizontalAlignmentCenter = 1,
    MADHorizontalAlignmentRight = 2,
    MADHorizontalAlignmentJustified = 3,
    MADHorizontalAlignmentNatrual = 4,
    
} MADHorizontalAlignment;

#endif /* MADHorizontalAlignmentType_h */
