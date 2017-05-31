//
//  MADAppStorageOption.h
//  MADFileManager
//
//  Created by Michael Thomason on 5/29/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADAppStorageOption_h
#define MADAppStorageOption_h

#import <sys/types.h>

typedef enum MADAppStorage : NSInteger {
    MADAppStorageNotSet = 0,
    MADAppStorageCloud = 1,
    MADAppStorageLocal = 2,
    MADAppStorageCloudButSignedOut = 3,
    MADAppStorageStateUnknown = 4
} MADAppStorage;

#endif /* MADAppStorageOption_h */
