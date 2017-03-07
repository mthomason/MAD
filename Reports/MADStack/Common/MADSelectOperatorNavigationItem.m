//
//  MADSelectOperatorNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 3/7/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADSelectOperatorNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import "MADLabelTitle.h"

@implementation MADSelectOperatorNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        NSString *hint = NSLocalizedString(@"Add a condition to your report.", @"Hint");
        NSString *title;
        title = NSLocalizedString(@"Select Operator",
                                  @"Title for the select operator screen. This is to "
                                  @"select a mathmatical operator... like equal or greater "
                                  @"than.");
        MADLabelTitle *titleView;
        titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
        titleView.text = title;
        titleView.accessibilityHint = hint;
        titleView.accessibilityTraits = UIAccessibilityTraitHeader;
        
        self.titleView = titleView;
        self.title = title;
        self.leftItemsSupplementBackButton = YES;
        
    }
    return self;
}

@end
