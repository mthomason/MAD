//
//  MADCacheManager.h
//  MAD Designer
//
//  Created by Michael Thomason on 4/27/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADCacheManager_h
#define MAD_Designer_MADCacheManager_h

#import <Foundation/NSObject.h>

@class NSOperation;

@interface MADCacheManager : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)sharedManager;
- (void)addOperation:(NSOperation *)operation;

@end

#endif
