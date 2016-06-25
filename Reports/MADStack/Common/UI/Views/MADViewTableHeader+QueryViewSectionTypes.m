//
//  MADTableViewHeader+QueryViewSectionTypes.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/7/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADViewTableHeader+QueryViewSectionTypes.h"
#import "MADQueryViewControllerLayout.h"
#import <UIKit/UILabel.h>
#import <UIKit/UIButton.h>
#import <UIKit/UIAccessibility.h>
#import "MADQueryViewControllerLayoutSections.h"

@implementation MADTableViewHeader (QueryViewSectionTypes)

+ (nonnull instancetype)newTableViewHeaderWithType:(nonnull MADQueryViewControllerLayoutSection *)layout andFrame:(CGRect)frame target:(nullable id)target {

    MADTableViewHeader *view = [[self alloc] initWithFrame:frame];
    switch (layout.querySection) {

        case MADQueryViewControllerSectionsDatasource:
            view.labelTitle.text = layout.name.copy;
            view.labelTitle.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
            view.buttonAdd.hidden = YES;
            view.buttonAdd.isAccessibilityElement = NO;
            break;

        case MADQueryViewControllerSectionsTables:
            view.labelTitle.text = layout.name.copy;
            [view.buttonAdd addTarget: target action: layout.selector forControlEvents: UIControlEventTouchUpInside];
            view.buttonAdd.isAccessibilityElement = YES;
            view.buttonAdd.accessibilityLabel = NSLocalizedString(@"Add", @"Add");
            view.buttonAdd.accessibilityHint = NSLocalizedString(@"Adds a new table.", @"Adds a new table.");
            break;
            
        case MADQueryViewControllerSectionsLinks:
            view.labelTitle.text = layout.name.copy;
            [view.buttonAdd addTarget: target action: layout.selector forControlEvents: UIControlEventTouchUpInside];
            view.buttonAdd.isAccessibilityElement = YES;
            view.buttonAdd.accessibilityLabel = NSLocalizedString(@"Add", @"Add");
            view.buttonAdd.accessibilityHint = NSLocalizedString(@"Adds a new table join.", @"Adds a new table join.");
            break;
            
        case MADQueryViewControllerSectionsDocumentGroups:
        case MADQueryViewControllerSectionsGroups:
            view.labelTitle.text = layout.name.copy;
            [view.buttonAdd addTarget: target action: layout.selector forControlEvents: UIControlEventTouchUpInside];
            view.buttonAdd.isAccessibilityElement = YES;
            view.buttonAdd.accessibilityLabel = NSLocalizedString(@"Add", @"Add");
            view.buttonAdd.accessibilityHint = NSLocalizedString(@"Adds a new query grouping.", @"Adds a new query grouping.");
            break;
            
        case MADQueryViewControllerSectionsPredicate:
            view.labelTitle.text = layout.name.copy;
            [view.buttonAdd addTarget: target action: layout.selector forControlEvents: UIControlEventTouchUpInside];
            [view.labelTitle sizeToFit];
            view.buttonAdd.isAccessibilityElement = YES;
            view.buttonAdd.accessibilityLabel = NSLocalizedString(@"Add", @"Add");
            view.buttonAdd.accessibilityHint = NSLocalizedString(@"Adds a predicate to filter the query results.", @"Adds a predicate to filter the query results.");
            break;
            
        case MADQueryViewControllerSectionsNumberOfQueryResults:
            view.labelTitle.text = layout.name.copy;
            view.buttonAdd.enabled = NO;
            view.buttonAdd.hidden = YES;
            [view.labelTitle sizeToFit];
            view.buttonAdd.isAccessibilityElement = NO;
            break;
            
        case MADQueryViewControllerSectionsSql:
        default:
            break;
    }
    return view;
}

@end
