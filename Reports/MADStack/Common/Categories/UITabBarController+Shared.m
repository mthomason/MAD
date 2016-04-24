//
//  UITabBarController+Shared.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UITabBarController+Shared.h"
#import "MADStoryboard.h"

static NSString * const TabBar = @"MADIdentifierStoryboardMainTabBarController";

@implementation MADTabBarController (Shared)

+ (instancetype)mainTabBarController NS_RETURNS_NOT_RETAINED {
    UIStoryboard *designer = [MADStoryboard newStoryboardDesigner];
    id viewController = [designer instantiateViewControllerWithIdentifier:TabBar];
    return viewController;
}

@end
