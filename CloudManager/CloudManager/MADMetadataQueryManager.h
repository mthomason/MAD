//
//  MADFileLocationManager.h
//  MAD
//
//  Created by Michael Thomason on 9/25/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADFileLocationManager_h
#define Reports_MADFileLocationManager_h

#import <Foundation/Foundation.h>

extern NSString * const MADUtiType;
extern NSString * const MADKeyMetadataShort;

@protocol MADFileLocationManagerDelegate <NSObject>

@end

@interface MADMetadataQueryManager : NSObject

+ (NSString *)keyResults;

@end

#endif
