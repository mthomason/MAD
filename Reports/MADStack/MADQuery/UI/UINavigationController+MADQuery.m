//
//  UISplitViewController+MADQuery.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/27/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "UINavigationController+MADQuery.h"
#import "MADStoryboard.h"

static NSString * const QueryNavigationController       = @"MADIdentifierStoryboardQueryNavigationController";
static NSString * const DesignerNavigationController    = @"MADIdentifierStoryboardDesignerNavigationController";
static NSString * const ViewerNavigationController      = @"MADIdentifierStoryboardViewerNavigationController";

@implementation UINavigationController (MADQuery)

+ (instancetype)QuerySplitViewController {
    UIStoryboard *storyboard = [MADStoryboard storyboardDesigner];
    UINavigationController *queryNavigationController= [storyboard instantiateViewControllerWithIdentifier: QueryNavigationController];
    return queryNavigationController;
}

+ (instancetype)DesignerController {
    UIStoryboard *storyboard = [MADStoryboard storyboardDesigner];
    UINavigationController *queryNavigationController= [storyboard instantiateViewControllerWithIdentifier: DesignerNavigationController];
    return queryNavigationController;
}

+ (instancetype)ViewerController {
    UIStoryboard *storyboard = [MADStoryboard storyboardDesigner];
    UINavigationController *queryNavigationController= [storyboard instantiateViewControllerWithIdentifier: ViewerNavigationController];
    return queryNavigationController;
}

@end
