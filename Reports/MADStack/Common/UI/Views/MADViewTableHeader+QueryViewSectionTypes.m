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
#import "MADQueryViewSectionDelegate.h"

static NSString * const MADTextButtonAdd                = @"Add";
static NSString * const MADTextButtonAddHintTables      = @"Adds a new table.";
static NSString * const MADTextButtonAddHintLinks       = @"Adds a new table join.";
static NSString * const MADTextButtonAddHintGroups      = @"Adds a new query grouping.";
static NSString * const MADTextButtonAddHintPredicate   = @"Adds a predicate to filter the "
                                                            @"query results.";

@implementation MADTableViewHeader (QueryViewSectionTypes)

+ (nonnull instancetype)newTableViewHeaderWithType: (nonnull MADQueryViewSectionDelegate *)layout
                                          andFrame: (CGRect)frame
                                            target: (nullable id)target {

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
            view.buttonAdd.accessibilityLabel = NSLocalizedString(MADTextButtonAdd, MADTextButtonAdd);
            view.buttonAdd.accessibilityHint = NSLocalizedString(MADTextButtonAddHintTables, MADTextButtonAddHintTables);
            break;
            
        case MADIdentifierQueryViewSectionsLinks:
            view.labelTitle.text = layout.name.copy;
            [view.buttonAdd addTarget: target action: layout.selector forControlEvents: UIControlEventTouchUpInside];
            view.buttonAdd.isAccessibilityElement = YES;
            view.buttonAdd.accessibilityLabel = NSLocalizedString(MADTextButtonAdd, MADTextButtonAdd);
            view.buttonAdd.accessibilityHint = NSLocalizedString(MADTextButtonAddHintLinks, MADTextButtonAddHintLinks);
            break;
            
        case MADIdentifierQueryViewSectionsDocumentGroups:
        case MADIdentifierQueryViewSectionsGroups:
            view.labelTitle.text = layout.name.copy;
            [view.buttonAdd addTarget: target action: layout.selector forControlEvents: UIControlEventTouchUpInside];
            view.buttonAdd.isAccessibilityElement = YES;
            view.buttonAdd.accessibilityLabel = NSLocalizedString(MADTextButtonAdd, MADTextButtonAdd);
            view.buttonAdd.accessibilityHint = NSLocalizedString(MADTextButtonAddHintGroups, MADTextButtonAddHintGroups);
            break;
            
        case MADIdentifierQueryViewSectionsPredicate:
            view.labelTitle.text = layout.name.copy;
            [view.buttonAdd addTarget: target action: layout.selector forControlEvents: UIControlEventTouchUpInside];
            [view.labelTitle sizeToFit];
            view.buttonAdd.isAccessibilityElement = YES;
            view.buttonAdd.accessibilityLabel = NSLocalizedString(MADTextButtonAdd, MADTextButtonAdd);
            view.buttonAdd.accessibilityHint = NSLocalizedString(MADTextButtonAddHintPredicate, MADTextButtonAddHintPredicate);
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
