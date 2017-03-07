//
//  MADPredicateFormatNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 3/7/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADPredicateFormatNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import "MADLabelTitle.h"

@implementation MADPredicateFormatNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        NSString *hint = NSLocalizedString(@"What type of predicate would you like to use?",
                                           @"Hint");
        NSString *title;
        title = NSLocalizedString(@"Predicate Format",
                                  @"Title for the predicate format screen. ");
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
