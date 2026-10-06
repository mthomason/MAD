//
//  MADQueryViewControllerLayout.h
//  MAD Designer
//
//  Created by Michael Thomason on 4/6/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADQueryViewControllerLayoutSection_h
#define MAD_Designer_MADQueryViewControllerLayoutSection_h

#import "MADIdentifierQueryViewSections.h"
#import <MAD/RptqStoreContext.h>
#import <UIKit/UITableView.h>

@class NSArray <__covariant ObjectType>, NSSet <__covariant ObjectType>,
	   NSNumber, UITableViewCell, MADocument, MADQueryViewSectionDelegate;

typedef void (^MADQueryViewCellConfigureHandler)(UITableViewCell *,
												 MADIdentifierQueryViewSections,
												 NSInteger /* row */);

@protocol MADQueryViewControllerDatasourceProtocol;

@interface MADQueryViewDataSource : NSObject <UITableViewDataSource>

@property (nonatomic, weak) id <MADQueryViewControllerDatasourceProtocol> datasoruce;

@property (readonly, nonatomic, weak) RptqStoreContext *managedObjectContext;
@property (readonly, nonatomic, strong) NSArray *queryTablesController;
@property (readonly, nonatomic, strong) NSArray *queryLinksController;
@property (readonly, nonatomic, strong) NSArray *queryGroupsController;
@property (readonly, nonatomic, strong) NSArray *queryPredicatesController;

@property (nonatomic, readonly, assign) short count;
@property (nonatomic, readonly, strong) NSArray <__kindof MADQueryViewSectionDelegate *> *sections;

- (instancetype)initWithQueryID: (NSNumber *)queryID
		   managedObjectContext: (RptqStoreContext *)managedObjectContext
			   reportingEnabled: (BOOL)reportingEnabled
			handleConfigureCell: (MADQueryViewCellConfigureHandler)handleConfigureCel;

- (instancetype)initWithNumberOfTables:(NSUInteger)numberOfTables
					  reportingEnabled:(BOOL)reportingEnabled
				   handleConfigureCell:(MADQueryViewCellConfigureHandler)handleConfigureCell;

- (void)numberOfTablesChanged:(NSUInteger)numberOfTables;

- (NSSet <NSNumber *> *)sectionTypes;
- (NSIndexSet *)sectionTypesIndexs;
- (MADIdentifierQueryViewSections)sectionAtIndex:(short)index;
- (MADQueryViewSectionDelegate *)layoutAtIndex:(short)index;

- (BOOL)canEditSectionAtIndex:(short)index;

- (void)performFetchAll;
- (void)performFetchTables;
- (void)performFetchLinks;
- (void)performFetchGroups;
- (void)performFetchPredicate;

@end

#endif
