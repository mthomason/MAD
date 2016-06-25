//
//  MADTableViewHeader+QueryViewSectionTypes.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/7/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADViewTableHeader+QueryViewSectionTypes.h"
#import "MADQueryViewDataSource.h"
#import <UIKit/UILabel.h>
#import <UIKit/UIButton.h>
#import <UIKit/UIAccessibility.h>
#import "MADQueryViewControllerLayoutSections.h"

@implementation MADTableViewHeader (QueryViewSectionTypes)

+ (nonnull instancetype)newTableViewHeaderWithType:(nonnull MADQueryViewControllerLayoutSection *)layout andFrame:(CGRect)frame target:(nullable id)target {

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
            view.buttonAdd.accessibilityHint = NSLocalizedString(@"Adds a new table.", @"Adds a new table.");
            break;
            
        case MADIdentifierQueryViewSectionsLinks:
            view.labelTitle.text = layout.name.copy;
            [view.buttonAdd addTarget: target action: layout.selector forControlEvents: UIControlEventTouchUpInside];
            view.buttonAdd.isAccessibilityElement = YES;
            view.buttonAdd.accessibilityLabel = NSLocalizedString(@"Add", @"Add");
            view.buttonAdd.accessibilityHint = NSLocalizedString(@"Adds a new table join.", @"Adds a new table join.");
            break;
            
        case MADIdentifierQueryViewSectionsDocumentGroups:
        case MADIdentifierQueryViewSectionsGroups:
            view.labelTitle.text = layout.name.copy;
            [view.buttonAdd addTarget: target action: layout.selector forControlEvents: UIControlEventTouchUpInside];
            view.buttonAdd.isAccessibilityElement = YES;
            view.buttonAdd.accessibilityLabel = NSLocalizedString(@"Add", @"Add");
            view.buttonAdd.accessibilityHint = NSLocalizedString(@"Adds a new query grouping.", @"Adds a new query grouping.");
            break;
            
        case MADIdentifierQueryViewSectionsPredicate:
            view.labelTitle.text = layout.name.copy;
            [view.buttonAdd addTarget: target action: layout.selector forControlEvents: UIControlEventTouchUpInside];
            [view.labelTitle sizeToFit];
            view.buttonAdd.isAccessibilityElement = YES;
            view.buttonAdd.accessibilityLabel = NSLocalizedString(@"Add", @"Add");
            view.buttonAdd.accessibilityHint = NSLocalizedString(@"Adds a predicate to filter the query results.", @"Adds a predicate to filter the query results.");
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

@end
