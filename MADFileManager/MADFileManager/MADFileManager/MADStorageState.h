//
//  MADStorageState.h
//  MADFileManager
//
//  Created by Michael Thomason on 9/12/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(short, MADAppStorage) {
    MADAppStorageNotSet = 0,
    MADAppStorageCloud = 1,
    MADAppStorageLocal = 2
};

@interface MADStorageState : NSObject

@property (nonatomic, assign) MADAppStorage storageOption;
@property (nonatomic, assign) BOOL accountDidChange;
@property (nonatomic, assign) BOOL cloudAvailable;

@end
