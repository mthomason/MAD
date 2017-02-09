//
//  MADQueryViewControllerLayout.h
//  MAD Designer
//
//  Created by Michael Thomason on 4/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADQueryViewControllerLayoutSection_h
#define MAD_Designer_MADQueryViewControllerLayoutSection_h

#import <UIKit/UITableView.h>
#import "MADIdentifierQueryViewSections.h"

@class NSArray <__covariant ObjectType>, NSSet <__covariant ObjectType>,
       NSNumber, NSFetchedResultsController, NSIndexPath, NSIndexSet, NSManagedObjectID,
       NSManagedObjectContext, UITableViewCell, MADocument, MADQueryViewSectionDelegate;

typedef void (^MADQueryViewCellConfigureHandler)(UITableViewCell *,
                                                 MADIdentifierQueryViewSections,
                                                 NSInteger /* row */);

@protocol MADQueryViewControllerDatasourceProtocol;

@interface MADQueryViewDataSource : NSObject
    <UITableViewDataSource>

    - (instancetype)initWithQueryID: (NSNumber *)queryID
               managedObjectContext: (NSManagedObjectContext *)managedObjectContext
                   reportingEnabled: (BOOL)reportingEnabled
                handleConfigureCell: (MADQueryViewCellConfigureHandler)handleConfigureCel;

    - (instancetype)initWithNumberOfTables:(NSUInteger)numberOfTables
                          reportingEnabled:(BOOL)reportingEnabled
                       handleConfigureCell:(MADQueryViewCellConfigureHandler)handleConfigureCell;

    @property (nonatomic, weak) id <MADQueryViewControllerDatasourceProtocol> datasoruce;

    @property (nonatomic, strong) NSFetchedResultsController *queryTablesController;
    @property (nonatomic, strong) NSFetchedResultsController *queryLinksController;
    @property (nonatomic, strong) NSFetchedResultsController *queryGroupsController;
    @property (nonatomic, strong) NSFetchedResultsController *queryPredicatesController;

    @property (nonatomic, readonly, assign) short count;
    @property (nonatomic, readonly, strong) NSArray <__kindof MADQueryViewSectionDelegate *> *sections;

    - (void)numberOfTablesChanged:(NSUInteger)numberOfTables;

    - (NSSet <NSNumber *> *)sectionTypes;
    - (NSIndexSet *)sectionTypesIndexs;
    - (MADIdentifierQueryViewSections)sectionAtIndex:(short)index;
    - (MADQueryViewSectionDelegate *)layoutAtIndex:(short)index;

    - (NSInteger)numberOfRowsInSectionAtIndex:(short)index;
    - (BOOL)canEditSectionAtIndex:(short)index;

    - (void)performFetchAll;
    - (void)performFetchTables;
    - (void)performFetchLinks;
    - (void)performFetchGroups;
    - (void)performFetchPredicate;

@end

#endif
