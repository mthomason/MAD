//
//  MADViewTableHeader.m
//  Reports
//
//  Created by Michael Thomason on 1/27/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADTableViewHeader.h"
#import <Foundation/NSBundle.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIButton.h>
#import <UIKit/UINibLoading.h>
#import <UIKit/UIAccessibility.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import "MADQueryViewSectionDelegate.h"

@interface MADTableViewHeader ()
    @property (nonatomic, weak) UIView *nibView;
@end

@implementation MADTableViewHeader

+ (nonnull instancetype)newTableViewHeaderWithType: (nonnull MADQueryViewSectionDelegate *)layout
                                          andFrame: (CGRect)frame
                                            target: (nullable id <MADQueryViewControllerLayoutSectionSelectorProtocol>)target {

    MADTableViewHeader *view = [[self alloc] initWithFrame:frame];
    switch (layout.querySection) {

        case MADIdentifierQueryViewSectionsDatasource:
            view.labelTitle.text = layout.name.copy;
            view.labelTitle.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
            view.buttonAdd.hidden = YES;
            view.buttonAdd.isAccessibilityElement = NO;
            break;

        case MADIdentifierQueryViewSectionsTables:
            view.labelTitle.text = layout.name.copy;
            [view.buttonAdd addTarget: target action: layout.selector forControlEvents: UIControlEventTouchUpInside];
            view.buttonAdd.isAccessibilityElement = YES;
            view.buttonAdd.accessibilityLabel = NSLocalizedString(@"Add", @"Add");
            view.buttonAdd.accessibilityHint = NSLocalizedString(@"Adds a new table.",
                                                                 @"Adds a new table.");
            break;
            
        case MADIdentifierQueryViewSectionsLinks:
            view.labelTitle.text = layout.name.copy;
            [view.buttonAdd addTarget: target action: layout.selector forControlEvents: UIControlEventTouchUpInside];
            view.buttonAdd.isAccessibilityElement = YES;
            view.buttonAdd.accessibilityLabel = NSLocalizedString(@"Add", @"Add");
            view.buttonAdd.accessibilityHint = NSLocalizedString(@"Adds a new table join.",
                                                                 @"Adds a new table join.");
            break;
            
        case MADIdentifierQueryViewSectionsDocumentGroups:
        case MADIdentifierQueryViewSectionsGroups:
            view.labelTitle.text = layout.name.copy;
            [view.buttonAdd addTarget: target action: layout.selector forControlEvents: UIControlEventTouchUpInside];
            view.buttonAdd.isAccessibilityElement = YES;
            view.buttonAdd.accessibilityLabel = NSLocalizedString(@"Add", @"Add");
            view.buttonAdd.accessibilityHint = NSLocalizedString(@"Adds a new query grouping.",
                                                                 @"Adds a new query grouping.");
            break;
            
        case MADIdentifierQueryViewSectionsPredicate:
            view.labelTitle.text = layout.name.copy;
            [view.buttonAdd addTarget: target action: layout.selector forControlEvents: UIControlEventTouchUpInside];
            [view.labelTitle sizeToFit];
            view.buttonAdd.isAccessibilityElement = YES;
            view.buttonAdd.accessibilityLabel = NSLocalizedString(@"Add", @"Add");
            view.buttonAdd.accessibilityHint = NSLocalizedString(@"Adds a predicate to filter the "
                                                                 @"query results.",
                                                                 @"Hint for query predicate.");
            break;
            
        case MADIdentifierQueryViewSectionsNumberOfQueryResults:
            view.labelTitle.text = layout.name.copy;
            view.buttonAdd.enabled = NO;
            view.buttonAdd.hidden = YES;
            [view.labelTitle sizeToFit];
            view.buttonAdd.isAccessibilityElement = NO;
            break;
            
        case MADIdentifierQueryViewSectionsSql:
        default:
            break;
    }
    return view;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        NSArray *nibContents =  [[NSBundle mainBundle] loadNibNamed: @"MADTableViewHeader"
                                                              owner: self options: nil];
        
        UIView *view = nibContents.firstObject;
        view.frame = self.frame;
        
        self.labelTitle.textColor = [MADColorEverydayApps newColorRed];
        self.buttonAdd.tintColor = [MADColorEverydayApps newColorBlue];

        [self addSubview:view];
        self.nibView = view;
        
        self.labelTitle.numberOfLines = 0;
        self.labelTitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        self.backgroundColor = [MADColorEverydayApps newColorHeaderColor];
        
    }
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];
	if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
		if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
			self.backgroundColor = [UIColor secondarySystemBackgroundColor];
		} else {
			self.backgroundColor = [MADColorEverydayApps newColorHeaderColor];
		}
	}
}

@end
