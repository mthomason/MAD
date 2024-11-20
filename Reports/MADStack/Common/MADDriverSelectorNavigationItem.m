//
//  MADDriverSelectorNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 2/16/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDriverSelectorNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

@implementation MADDriverSelectorNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        NSString *hint = NSLocalizedString(@"Choose the type of connection to use.", @"Hint");
        NSString *title;
        title = NSLocalizedString(@"New Report",
                                  @"Title of form that allows you to choose "
                                  @"the name of a database field.");
        MADLabelTitle *titleView;
        titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
        titleView.text = title;
        titleView.accessibilityHint = hint;
        titleView.accessibilityTraits = UIAccessibilityTraitHeader;
        
        self.prompt = NSLocalizedString(@"Select database type.",
                                        @"Select database type.");
        self.titleView = titleView;
        self.title = title;
        self.leftItemsSupplementBackButton = YES;
    }
    return self;
}

@end
