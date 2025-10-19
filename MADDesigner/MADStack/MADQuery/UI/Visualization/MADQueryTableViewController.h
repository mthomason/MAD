//
//  MADQueryBuilderAdvancedSchemaViewController.h
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTQueryBuilderAdvancedSchemaViewController_h
#define Reports_MTQueryBuilderAdvancedSchemaViewController_h

#import <UIKit/UIViewController.h>
#import "MADViewControllerDocumentProtocol.h"
#import "MADManagedObjectViewProtocol.h"
#import "MADHierarchicalGroupingNodeProtocol.h"

@protocol MADQueryVisualizationSchemaDelegate;

@class UITableView, MADocument, MTSchemaFieldCell, NSManagedObjectID, UITableView;

extern const CGFloat MADSchemaViewDefaultWidth;
extern const CGFloat MADSchemaViewDefaultHeight;

@interface MADQueryTableViewController : UIViewController <MADViewControllerDocumentProtocol, MADManagedObjectViewProtocol, MADHierarchicalGroupingNodeProtocol>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) id <MADQueryVisualizationSchemaDelegate> delegate;
@property (nonatomic, weak) IBOutlet MTSchemaFieldCell *schemaFieldCell;

+ (instancetype)newQueryTableViewController:(int64_t)identifier root:(BOOL)root
								   delegate:(id <MADQueryVisualizationSchemaDelegate>)delegate
								   document:(MADocument *)document;


@end

#endif
