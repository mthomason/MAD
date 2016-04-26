//
//  MADTableViewHeader+QueryViewSectionTypes.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/7/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADViewTableHeader+QueryViewSectionTypes.h"
#import "MADQueryViewControllerLayout.h"

@implementation MADTableViewHeader (QueryViewSectionTypes)

g
    MADTableViewHeader *view = [[self alloc] initWithFrame:frame];
    switch (layout.querySection) {

        case MTQuerySectionsDatasource:
            view.labelTitle.text = layout.name.copy;
            view.labelTitle.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
            view.buttonAdd.hidden = YES;
            view.buttonAdd.isAccessibilityElement = NO;
            break;

        case MTQuerySectionsTables:
            view.labelTitle.text = layout.name.copy;
            [view.buttonAdd addTarget: target action: layout.selector forControlEvents: UIControlEventTouchUpInside];
            view.buttonAdd.isAccessibilityElement = YES;
            view.buttonAdd.accessibilityLabel = NSLocalizedString(@"Add", @"Add");
            view.buttonAdd.accessibilityHint = NSLocalizedString(@"Adds a new table.", @"Adds a new table.");
            break;
            
        case MTQuerySectionsLinks:
            view.labelTitle.text = layout.name.copy;
            [view.buttonAdd addTarget: target action: layout.selector forControlEvents: UIControlEventTouchUpInside];
            view.buttonAdd.isAccessibilityElement = YES;
            view.buttonAdd.accessibilityLabel = NSLocalizedString(@"Add", @"Add");
            view.buttonAdd.accessibilityHint = NSLocalizedString(@"Adds a new table join.", @"Adds a new table join.");
            break;
            
        case MTQuerySectionsDocumentGroups:
        case MTQuerySectionsGroups:
            view.labelTitle.text = layout.name.copy;
            [view.buttonAdd addTarget: target action: layout.selector forControlEvents: UIControlEventTouchUpInside];
            view.buttonAdd.isAccessibilityElement = YES;
            view.buttonAdd.accessibilityLabel = NSLocalizedString(@"Add", @"Add");
            view.buttonAdd.accessibilityHint = NSLocalizedString(@"Adds a new query grouping.", @"Adds a new query grouping.");
            break;
            
        case MTQuerySectionsPredicate:
            view.labelTitle.text = layout.name.copy;
            [view.buttonAdd addTarget: target action: layout.selector forControlEvents: UIControlEventTouchUpInside];
            [view.labelTitle sizeToFit];
            view.buttonAdd.isAccessibilityElement = YES;
            view.buttonAdd.accessibilityLabel = NSLocalizedString(@"Add", @"Add");
            view.buttonAdd.accessibilityHint = NSLocalizedString(@"Adds a predicate to filter the query results.", @"Adds a predicate to filter the query results.");
            break;
            
        case MTQuerySectionsNumberOfQueryResults:
            view.labelTitle.text = layout.name.copy;
            view.buttonAdd.enabled = NO;
            view.buttonAdd.hidden = YES;
            [view.labelTitle sizeToFit];
            view.buttonAdd.isAccessibilityElement = NO;
            break;
            
        case MTQuerySectionsSql:
        default:
            break;
    }
    return view;
}

@end
