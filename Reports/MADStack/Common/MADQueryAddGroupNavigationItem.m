//
//  MADQueryAddGroupNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 3/6/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryAddGroupNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import "MADLabelTitle.h"

@interface MADQueryAddGroupNavigationItem ()



@end

@implementation MADQueryAddGroupNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        NSString *hint = NSLocalizedString(@"Define a grouping the query and report.", @"Hint");
        NSString *title;
        title = NSLocalizedString(@"Add Group",
                                  @"Title for the add group screen. ");
        MADLabelTitle *titleView;
        titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
        titleView.text = title;
        titleView.accessibilityHint = hint;
        titleView.accessibilityTraits = UIAccessibilityTraitHeader;
        
        self.leftBarButtonItem.tintColor = [MADColorEverydayApps newColorWhite];
        self.rightBarButtonItem.tintColor = [MADColorEverydayApps newColorWhite];
        self.backBarButtonItem.tintColor = [MADColorEverydayApps newColorWhite];
        
        self.titleView = titleView;
        self.title = title;
        self.leftItemsSupplementBackButton = YES;
    }
    return self;
}

@end
