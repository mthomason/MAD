//
//  AppDelegate.h
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTApplicaitonInstance.h"


@interface AppDelegate : UIResponder
    <UIApplicationDelegate,
        UIDocumentInteractionControllerDelegate,
        UIAlertViewDelegate>

+ (MTApplicaitonInstance *)applicationInstance;

@property (nonatomic, strong) UIWindow *window;

- (UIFont *)mainFont;
- (UIFont *)detailFont;

@end
