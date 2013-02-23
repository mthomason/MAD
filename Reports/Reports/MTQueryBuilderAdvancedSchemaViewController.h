//
//  MTQueryBuilderAdvancedSchemaViewController.h
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <QuartzCore/QuartzCore.h>
#import "RptqTable+Extras.h"
#import "AppDelegate.h"
#import "MTSchemaFieldCell.h"
#import "UIView+NSObjectIdTag.h"
#import "MTConnectorView.h"
#import "MTTitleView.h"

@protocol MTQueryBuilderAdvancedSchemaViewControllerDelegate
- (void)didMoveFieldRect:(id)sender;
@end

@interface MTQueryBuilderAdvancedSchemaViewController : UIViewController
    <MTSchemaFieldCellDelegate>

@property (nonatomic, retain, readonly) IBOutlet UITableView *schemaTableViewController;
@property (nonatomic, assign) id <MTQueryBuilderAdvancedSchemaViewControllerDelegate> delegate;
@property (nonatomic, assign) IBOutlet MTSchemaFieldCell *schemaFieldCell;

- (NSManagedObjectID *)tableObjectId;
- (void)setTableObjectId:(NSManagedObjectID *)tableObjectId;
- (MTSchemaFieldCell *)cellForFieldWithObjectId:(NSManagedObjectID *)managedObjectID;
- (CGRect)rectForFieldWithObjectId:(NSManagedObjectID *)managedObjectID;
- (CGRect)rectForFieldWithObjectId:(NSManagedObjectID *)managedObjectID inView:(UIView *)containerView;

@end
