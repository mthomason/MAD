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

#if __APPLE__
#import <UIKit/UIApplication.h>
#else
// No UIKit off Apple; the protocol qualifier is what the signatures below
// need, and MADApplicationProtocol supplies the methods actually messaged.
@protocol UIApplicationDelegate;
#endif

@protocol MADApplicationProtocol;

@interface MADApplication : NSObject

+ (id <UIApplicationDelegate, MADApplicationProtocol>)AppDelegate;

+ (NSString *)groupIdentifier;
+ (NSString *)ubiquityIdentifier;

+ (BOOL)isMADDesigner;
+ (BOOL)isMADViewer;

@end

#endif
