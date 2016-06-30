//
//  UITabBarController+Shared.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UITabBarController+Shared.h"
#import "MADStoryboard.h"
#import "MADTabBarController.h"
#import <UIKit/UITabBarController.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>

static NSString * const TabBar = @"MADIdentifierStoryboardMainTabBarController";

@implementation MADTabBarController (Shared)

+ (instancetype)newTabBarControllerMain:(NSString *)title {
    UIStoryboard *designer = [MADStoryboard newStoryboardDesigner];
    MADTabBarController *viewController = [designer instantiateViewControllerWithIdentifier:TabBar];
    viewController.navigationItem.prompt = title.copy;
    viewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    viewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    return viewController;
}

@end
