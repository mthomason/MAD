//
//  MADStoreNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 2/16/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADStoreNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

@implementation MADStoreNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        NSString *hint = NSLocalizedString(@"Choose a feature to purchase.", @"Hint");
        NSString *title;
        title = NSLocalizedString(@"MAD Features",
                                  @"Title for the store... list program features. ");
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
