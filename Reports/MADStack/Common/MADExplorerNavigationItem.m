//
//  MADExplorerNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 2/16/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADExplorerNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

@implementation MADExplorerNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        NSString *MADHintAppTitle = @"MAD Designer is the mobile analytics document designer.";
        NSString *title = @"MAD Designer";
        MADLabelTitle *titleView;
        titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
        titleView.text = title;
        titleView.accessibilityHint = NSLocalizedString(MADHintAppTitle, MADHintAppTitle);
        titleView.accessibilityTraits = UIAccessibilityTraitHeader;

        self.titleView = titleView;
        self.title = title;
        self.hidesBackButton = YES;
    }
    return self;
}

@end
