//
//  UISplitViewController+MADQuery.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/27/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "UINavigationController+MADQuery.h"
#import "UIStoryboard+Designer.h"

static NSString * const QueryNavigationController = @"MADIdentifierStoryboardQueryNavigationController";

@implementation UINavigationController (MADQuery)

+ (instancetype)QuerySplitViewController NS_RETURNS_RETAINED {
    UIStoryboard *storyboard = [UIStoryboard Designer];
    UINavigationController *queryNavigationController= [storyboard instantiateViewControllerWithIdentifier: QueryNavigationController];
    return queryNavigationController;
}

@end
