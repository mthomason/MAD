//
//  MADSortOrderNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 3/6/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADSortOrderNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

@implementation MADSortOrderNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
        titleView.text = NSLocalizedString(@"Sort Order", "Sort Order");
        titleView.accessibilityHint = NSLocalizedString(@"Select a sort order.", @"Select a sort order.");
        titleView.accessibilityTraits = UIAccessibilityTraitHeader;
        
        self.leftBarButtonItem.tintColor = [MADColorEverydayApps newColorWhite];
        self.rightBarButtonItem.tintColor = [MADColorEverydayApps newColorWhite];
        self.backBarButtonItem.tintColor = [MADColorEverydayApps newColorWhite];

        self.titleView = titleView;
        self.title = NSLocalizedString(@"Sort Order", "Sort Order");
        self.leftItemsSupplementBackButton = YES;
        self.hidesBackButton = NO;
    }
    return self;
}

@end
