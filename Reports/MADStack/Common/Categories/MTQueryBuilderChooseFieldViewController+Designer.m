//
//  MTQueryBuilderChooseFieldViewController+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderChooseFieldViewController+Designer.h"
#import "UIStoryboard+ObjectSelector.h"

static NSString * const MainIdentifier = @"UITableViewControllerChooseFieldDataObject";

@implementation MTQueryBuilderChooseFieldViewController (Designer)

+ (instancetype)main {
    UIStoryboard *storyboard = [UIStoryboard ObjectSelector];
    return [storyboard instantiateViewControllerWithIdentifier: MainIdentifier];
}

@end
