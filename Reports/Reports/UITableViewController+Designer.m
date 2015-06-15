//
//  UITableViewController+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewController+Designer.h"
#import "UIStoryboard+Designer.h"

static NSString * const About = @"MADIdentifierAboutViewController";

@implementation UITableViewController (Designer)

+ (instancetype)About {
    UIStoryboard *storyboard = [UIStoryboard About];
    UITableViewController *about = [storyboard instantiateViewControllerWithIdentifier:About];
    about.modalPresentationStyle = UIModalPresentationPopover;
    return about;
}

@end
