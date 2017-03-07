//
//  MADSortOrderNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 3/6/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADSortOrderNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import "MADLabelTitle.h"

@implementation MADSortOrderNavigationItem

/*+ (void)initialize {
    [super initialize];
    
    if (self == [MADSortOrderNavigationItem self]) {
        @autoreleasepool {
            NSArray<Class <UIAppearanceContainer>> * classes;
            UIBarButtonItem *barButtonItem;
            classes = [[NSArray alloc] initWithObjects: [UINavigationBar class], nil];
            barButtonItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:classes];
            barButtonItem.tintColor = [MADColorEverydayApps newColorWhite];
        }
    }
}*/

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        NSString *hint = NSLocalizedString(@"Select a sort order.", @"Hint");
        NSString *title;
        title = NSLocalizedString(@"Sort Order",
                                  @"Title for the sort order screen. ");
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
        self.hidesBackButton = NO;
    }
    return self;
}

@end
