//
//  MADAppStorageOption.h
//  MADFileManager
//
//  Created by Michael Thomason on 5/29/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADAppStorageOption_h
#define MADAppStorageOption_h

typedef NS_ENUM(short, MADAppStorage) {
    MADAppStorageNotSet = 0,
    MADAppStorageCloud = 1,
    MADAppStorageLocal = 2,
    MADAppStorageCloudButSignedOut = 3,
    MADAppStorageStateUnknown = 4
};

#endif /* MADAppStorageOption_h */
