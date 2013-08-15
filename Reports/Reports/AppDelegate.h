//
//  AppDelegate.h
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIDevice+Hack.h"
#import "MACloudManager.h"
#import "MTStoreKitController.h"
#import "MTLog.h"
#import "NSURL+Document.h"

extern NSString * const MTBundleIdDesigner;
extern NSString * const MTBundleIdViewer;

@interface AppDelegate : UIResponder
    <UIApplicationDelegate, UIDocumentInteractionControllerDelegate>

@property (nonatomic, strong) UIWindow *window;

+ (NSString *)storyboardName;
+ (NSString *)bundleId;
+ (BOOL)isMadViewer;
+ (BOOL)isMadDesigner;

@end
