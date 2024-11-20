//
//  MADPredicateAddNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 3/7/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADPredicateAddNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

@implementation MADPredicateAddNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        NSString *hint = NSLocalizedString(@"Add a condition to your report.", @"Hint");
        NSString *title;
        title = NSLocalizedString(@"Add Predicate",
                                  @"Title for the add predicate screen. ");
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
