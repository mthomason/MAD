//
//  MADSelectFieldNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 3/6/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADSelectFieldNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import "MADLabelTitle.h"

@implementation MADSelectFieldNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        NSString *hint = NSLocalizedString(@"Select a field.", @"Hint");
        NSString *title;
        title = NSLocalizedString(@"Select Field",
                                  @"Title for the select field screen. ");
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
