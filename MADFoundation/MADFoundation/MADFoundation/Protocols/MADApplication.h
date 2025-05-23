//
//  MADApplication.h
//  MADFoundation
//
//  Created by Michael Thomason on 9/23/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADFoundation_MADApplication_h
#define MAD_MADFoundation_MADApplication_h

#import <Foundation/NSObject.h>
#import <UIKit/UIApplication.h>

@protocol MADApplicationProtocol;

@interface MADApplication : NSObject

+ (id <UIApplicationDelegate, MADApplicationProtocol>)AppDelegate;

+ (NSString *)groupIdentifier;
+ (NSString *)ubiquityIdentifier;

+ (BOOL)isMADDesigner;
+ (BOOL)isMADViewer;

@end

#endif
