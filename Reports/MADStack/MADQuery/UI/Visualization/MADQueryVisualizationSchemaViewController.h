//
//  MTQueryBuilderAdvancedSchemaViewController.h
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderAdvancedSchemaViewController_h
#define Reports_MTQueryBuilderAdvancedSchemaViewController_h

#import <UIKit/UIViewController.h>
#import "MADViewControllerDocumentProtocol.h"
#import "MADManagedObjectViewProtocol.h"
#import "MADHierarchicalGroupingNodeProtocol.h"

@protocol MADQueryVisualizationSchemaDelegate;

@class UITableView, MADocument, MTSchemaFieldCell, NSManagedObjectID, UITableView;

@interface MADQueryVisualizationSchemaViewController : UIViewController
    <MADViewControllerDocumentProtocol,
        MADManagedObjectViewProtocol,
        MADHierarchicalGroupingNodeProtocol>

    + (instancetype)newQueryVisualizationSchemaViewController;

    @property (nonatomic, weak) IBOutlet UITableView *tableView;
    @property (nonatomic, weak) id <MADQueryVisualizationSchemaDelegate> delegate;
    @property (nonatomic, weak) IBOutlet MTSchemaFieldCell *schemaFieldCell;

    - (CGRect)rectForFieldWithObjectIdentifier:(int64_t)managedObjectID;

@end

#endif
