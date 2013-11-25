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
#import "RptqDatabaseSchemaTable+Extras.h"
#import "AppDelegate.h"
#import "MTSchemaFieldCell.h"
#import "UIView+NSObjectIdTag.h"
#import "MTConnectorView.h"
#import "MTTitleView.h"

@protocol MTQueryBuilderAdvancedSchemaDelegate
- (void)didMoveFieldRect:(id)sender animated:(BOOL)animated;
@end

@interface MTQueryBuilderAdvancedSchemaViewController : UIViewController
    <MTSchemaFieldCellDelegate, UIDynamicItem>

@property (nonatomic, retain) IBOutlet UITableView *schemaTableViewController;
@property (nonatomic, assign) id <MTQueryBuilderAdvancedSchemaDelegate> delegate;
@property (nonatomic, assign) IBOutlet MTSchemaFieldCell *schemaFieldCell;

//@property (nonatomic, retain) NSLayoutConstraint *layoutConstraintX;
//@property (nonatomic, retain) NSLayoutConstraint *layoutConstraintY;

//@property (nonatomic, readwrite) CGRect bounds;
//@property (nonatomic, readwrite) CGPoint center;
//@property (nonatomic, readwrite) CGAffineTransform transform;

- (void)setCenter:(CGPoint)center;
- (void)setBounds:(CGRect)bounds;
- (void)setTransform:(CGAffineTransform)transform;
- (CGPoint)center;
- (CGRect)bounds;
- (CGAffineTransform)transform;

- (NSManagedObjectID *)tableObjectId;
- (void)setTableObjectId:(NSManagedObjectID *)tableObjectId;
- (MTSchemaFieldCell *)cellForFieldWithObjectId:(NSManagedObjectID *)managedObjectID;
- (CGRect)rectForFieldWithObjectId:(NSManagedObjectID *)managedObjectID;
- (CGRect)rectForFieldWithObjectId:(NSManagedObjectID *)managedObjectID inView:(UIView *)containerView;

@end
