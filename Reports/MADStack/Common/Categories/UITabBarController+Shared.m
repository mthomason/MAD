//
//  UITabBarController+Shared.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UITabBarController+Shared.h"
#import "UIStoryboard+Designer.h"

static NSString * const TabBar = @"MADIdentifierStoryboardMainTabBarController";

@implementation UITabBarController (Shared)

+ (instancetype)mainTabBarController {
    UIStoryboard *designer = [UIStoryboard Designer];
    return [designer instantiateViewControllerWithIdentifier:TabBar];
}

@end
