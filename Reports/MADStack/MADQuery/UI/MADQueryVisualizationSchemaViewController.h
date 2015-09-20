//
//  MTQueryBuilderAdvancedSchemaViewController.h
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderAdvancedSchemaViewController_h
#define Reports_MTQueryBuilderAdvancedSchemaViewController_h

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <QuartzCore/QuartzCore.h>
#import <MAD/MAD.h>
#import "MADViewController.h"
#import "MADocumentProtocol.h"

@protocol MADQueryVisualizationSchemaDelegate
- (void)didMoveFieldRect:(id)sender animated:(BOOL)animated;
@end

@class MTSchemaFieldCell, NSManagedObjectID, MADocument;

@interface MADQueryVisualizationSchemaViewController : MADViewController
    <UIDynamicItem, MADocumentProtocol>

@property (nonatomic, strong) IBOutlet UITableView *schemaTableViewController;
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, weak) id <MADQueryVisualizationSchemaDelegate> delegate;
@property (nonatomic, weak) IBOutlet MTSchemaFieldCell *schemaFieldCell;

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

#endif
