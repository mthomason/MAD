//
//  MTApplicaitonInstance.m
//  MAD
//
//  Created by Michael Thomason on 2/16/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADAppConfiguration.h"

#import <MADFoundation/UIApplication+MADAppDelegate.h>

#if MAD_DESIGNER
    #import "UIViewController+Designer.h"
#elif MAD_VIEWER
    #import "UIViewController+Viewer.h"
#endif

#ifndef MADWATCHKIT
    #import "MADToolboxNavigationController.h"
    #import "MADNavigationController.h"
    #import "MADTransparentPresentationController.h"
    #import "MADNavigationBarFixedSize.h"
#endif




@interface MADAppConfiguration ()

@property (nonatomic, strong) dispatch_queue_t appInstaceQueue;

@end

@implementation MADAppConfiguration



@end
