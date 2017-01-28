//
//  MTQueryBuilderAdvancedSchemaViewController.h
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderAdvancedSchemaViewController_h
#define Reports_MTQueryBuilderAdvancedSchemaViewController_h

#import <UIKit/UIViewController.h>
#import "MADViewControllerDocumentProtocol.h"
#import "MADManagedObjectViewProtocol.h"

@class UITableView;

@protocol MADQueryVisualizationSchemaDelegate
    - (void)didMoveFieldRect:(id)sender animated:(BOOL)animated;
@end

@protocol MADHierarchicalGroupingNodeProtocol <NSObject>
    @property (nonatomic, assign) BOOL root;
    - (CGRect)rectForFieldWithObjectId:(NSManagedObjectID *)managedObjectID
                                inView:(UIView *)containerView;
    - (CGRect)frame;
@end

@class MADocument, MTSchemaFieldCell, NSManagedObjectID;

@interface MADQueryVisualizationSchemaViewController : UIViewController
    <MADViewControllerDocumentProtocol,
        MADManagedObjectViewProtocol,
        MADHierarchicalGroupingNodeProtocol>

    + (instancetype)newQueryVisualizationSchemaViewController;

    @property (nonatomic, weak) IBOutlet UITableView *tableView;
    @property (nonatomic, weak) id <MADQueryVisualizationSchemaDelegate> delegate;
    @property (nonatomic, weak) IBOutlet MTSchemaFieldCell *schemaFieldCell;

    - (CGRect)rectForFieldWithObjectId:(NSManagedObjectID *)managedObjectID;

@end

#endif
