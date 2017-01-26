//
//  MADQueryViewControllerLayout.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryViewDataSource.h"

#import <Foundation/NSIndexPath.h>
#import <UIKit/UITableView.h>
#import <UIKit/UILabel.h>
#import <CoreData/NSExpressionDescription.h>
#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSFetchedResultsController.h>
#import <CoreData/NSManagedObjectID.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSOrderedSet.h>

#import "MADTableViewCellQueryTableName.h"
#import "MADTableViewCellQueryLink.h"
#import "MADTableViewCellQueryPredicate.h"
#import "MADTableViewCellQueryGroup.h"

#import "NSAttributedString+QueryViewController.h"

#import "MADQueryViewSectionDelegate.h"

#import <MAD/MADocument.h>

#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqQuery+Extras.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqQueryGroup+Extras.h>
#import <MAD/RptqQueryLinks+Extras.h>
#import <MAD/RptqQueryPredicate+Extras.h>
#import <MAD/RptqUserCredentals+Extras.h>

@interface MADQueryViewDataSource ()
    <NSFetchedResultsControllerDelegate>

    @property (nonatomic, readwrite, assign) short count;

    @property (nonatomic, readwrite, strong) NSArray <__kindof MADQueryViewSectionDelegate *> *sections;

    @property (nonatomic, readwrite, weak) MADQueryViewCellConfigureHandler handleConfigureCell;

@end

@implementation MADQueryViewDataSource {
    BOOL _reportingEnabled;
    NSUInteger _numberOfTables;
}

- (void)dealloc {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    //_sections = nil;
    _handleConfigureCell = nil;
    _datasoruce = nil;
    if (_queryLinksController) {
        _queryLinksController.delegate = nil;
//        _queryLinksController = nil;
    }
    if (_queryTablesController) {
        _queryTablesController.delegate = nil;
//        _queryTablesController = nil;
    }
    if (_queryGroupsController) {
        _queryGroupsController.delegate = nil;
//        _queryGroupsController = nil;
    }
    if (_queryPredicatesController) {
        _queryPredicatesController.delegate = nil;
//        _queryPredicatesController = nil;
    }
}

short numberOfSectionsForQueryTableCount(NSUInteger, BOOL);
short numberOfSectionsForQueryTableCount(NSUInteger queryTableCount, BOOL reportingEnabled) {
    switch (queryTableCount) {
        case 0:
            return reportingEnabled ? 3 : 2;
            break;
        case 1:
            return reportingEnabled ? 5 : 4;
            break;
        default:
            return reportingEnabled ? 6 : 5;
            break;
    }
}

- (instancetype)initWithQueryID: (NSManagedObjectID *)queryID
           managedObjectContext: (NSManagedObjectContext *)managedObjectContext
               reportingEnabled: (BOOL)reportingEnabled
            handleConfigureCell: (MADQueryViewCellConfigureHandler)handleConfigureCell {
    if (self = [super init]) {
    
        NSString *keyHasQueryTables = @"madQTC";
        
        id result;
        NSError * __autoreleasing *error = NULL;
        NSFetchRequest *request;
        NSComparisonPredicate *predicate;
        NSExpression *expression[2];
        NSExpressionDescription *expressionDescriptionQueryTableCount;
        NSExpressionDescription *expressionDescriptionQueryObjectID;
        NSExpression *keyPathHasQueryTables;
        
        expressionDescriptionQueryObjectID = [[NSExpressionDescription alloc] init];
        expressionDescriptionQueryObjectID.name = NSStringFromSelector(@selector(objectID));
        expressionDescriptionQueryObjectID.expression = [NSExpression expressionForEvaluatedObject];
        expressionDescriptionQueryObjectID.expressionResultType = NSObjectIDAttributeType;
        
        NSArray *keyPathQueryTables;
        
        expressionDescriptionQueryTableCount = [[NSExpressionDescription alloc] init];
        expressionDescriptionQueryTableCount.name = keyHasQueryTables.copy;
        expressionDescriptionQueryTableCount.expressionResultType = NSInteger32AttributeType;
        
        keyPathHasQueryTables = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(hasQueryTables))];
        keyPathQueryTables = [[NSArray alloc] initWithObjects:keyPathHasQueryTables, nil];
        
        expressionDescriptionQueryTableCount.expression = [NSExpression expressionForFunction: @"count:"
                                                                                    arguments: keyPathQueryTables];
        
        expression[0] = [NSExpression expressionForEvaluatedObject];
        expression[1] = [NSExpression expressionForConstantValue: queryID];
        predicate= [NSComparisonPredicate predicateWithLeftExpression: expression[0]
                                                      rightExpression: expression[1]
                                                             modifier: NSDirectPredicateModifier
                                                                 type: NSEqualToPredicateOperatorType
                                                              options: 0];
        
        NSEntityDescription *entityDescription;
        NSArray *propertiesToFetch;

        entityDescription = [NSEntityDescription entityForName: NSStringFromClass([RptqQuery class])
                                        inManagedObjectContext: managedObjectContext];
        request = [[NSFetchRequest alloc] init];

        propertiesToFetch = [[NSArray alloc] initWithObjects:expressionDescriptionQueryTableCount,
                                                             expressionDescriptionQueryObjectID, nil];
        request.propertiesToFetch = propertiesToFetch;
        request.entity = entityDescription;
        request.fetchLimit = 1;
        request.predicate = predicate;
        request.resultType = NSDictionaryResultType;
        request.includesSubentities = NO;

        NSUInteger numberOfTables = 0;

        result = [managedObjectContext executeFetchRequest:request error:error];
        if (result == nil) {
            if (error) NSLog(@"Fetch error: %@", *error);
            numberOfTables = 0;
            
        } else {
            if (((NSArray *)result).count > 0) {
                id tableCount = result[0][keyHasQueryTables];
                numberOfTables = (NSUInteger)[tableCount integerValue];
                tableCount = nil;
            }
        }
        
        _count = numberOfSectionsForQueryTableCount(numberOfTables, reportingEnabled);
        _reportingEnabled = reportingEnabled;
        _numberOfTables = (unsigned long)numberOfTables;
        _handleConfigureCell = handleConfigureCell;
        
    }
    return self;
}

- (instancetype)initWithNumberOfTables:(NSUInteger)numberOfTables
                      reportingEnabled:(BOOL)reportingEnabled
                   handleConfigureCell:(MADQueryViewCellConfigureHandler)handleConfigureCell {

    if (self = [super init]) {
        
        _count = numberOfSectionsForQueryTableCount(numberOfTables, reportingEnabled);
        _reportingEnabled = reportingEnabled;
        _numberOfTables = numberOfTables;
        _handleConfigureCell = handleConfigureCell;
        
    }
    return self;
}

- (void)numberOfTablesChanged:(NSUInteger)numberOfTables {
    _count = numberOfSectionsForQueryTableCount(numberOfTables, _reportingEnabled);
    _numberOfTables = numberOfTables;
    _sections = nil;
}

- (MADIdentifierQueryViewSections)sectionAtIndex:(short)index {
    MADQueryViewSectionDelegate *layout;
    layout = [[MADQueryViewSectionDelegate alloc] initWithNumberOfTables:_numberOfTables position:index];
    return layout.querySection;
}

- (NSIndexSet *)sectionTypesIndexs {
    NSMutableIndexSet *sectionTypes = [[NSMutableIndexSet alloc] init];
    NSArray <__kindof MADQueryViewSectionDelegate *> *sections = self.sections;
    for (MADQueryViewSectionDelegate *section in sections) {
        [sectionTypes addIndex:section.querySection];
    }
    return sectionTypes;
}

- (NSSet <__kindof NSNumber *> *)sectionTypes {
    NSMutableSet <__kindof NSNumber *> *sectionTypes = [[NSMutableSet alloc] initWithCapacity:(NSUInteger)_count];
    for (MADQueryViewSectionDelegate *section in self.sections) {
        NSNumber *sectionType = [[NSNumber alloc] initWithShort:section.querySection];
        [sectionTypes addObject:sectionType];
    }
    return sectionTypes;
}

- (MADQueryViewSectionDelegate *)layoutAtIndex:(short)index {
    return self.sections[(NSUInteger)index];
}

- (NSArray <__kindof MADQueryViewSectionDelegate *> *)sections {
    if (_sections != nil) {
        return _sections;
    } else {
    
        NSMutableArray <__kindof MADQueryViewSectionDelegate *> *sections;
        sections = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)_count];
        for (short i = 0; i < _count; i++) {
            MADQueryViewSectionDelegate *section;
            section = [[MADQueryViewSectionDelegate alloc] initWithNumberOfTables: _numberOfTables
                                                                         position: i];
            [sections addObject:section];
        }
        _sections = sections;
        return _sections;
    }
}

- (NSInteger)numberOfRowsInSectionAtIndex:(short)index {
    MADQueryViewSectionDelegate *layoutSection = [self layoutAtIndex:(short)index];
    NSInteger numberOfSections = layoutSection.numberOfRows == NSNotFound ?
                                    [self numberOfRowsInSection:layoutSection.querySection] : 1;
    return numberOfSections;
}

- (NSInteger)numberOfRowsInSection:(MADIdentifierQueryViewSections)section {
    switch (section) {

        case MADIdentifierQueryViewSectionsTables:
            return (NSInteger)_queryTablesController.sections[0].numberOfObjects;
            break;

        case MADIdentifierQueryViewSectionsLinks:
            return (NSInteger)_queryLinksController.sections[0].numberOfObjects;
            break;

        case MADIdentifierQueryViewSectionsPredicate:
            return (NSInteger)_queryPredicatesController.sections[0].numberOfObjects;
            break;

        case MADIdentifierQueryViewSectionsGroups:
            return (NSInteger)_queryGroupsController.sections[0].numberOfObjects;
            break;

        default:
            return 0;
            break;
    }
}

- (BOOL)canEditSectionAtIndex:(short)index {
    MADIdentifierQueryViewSections sectionType = [self sectionAtIndex:index];
    return (sectionType == MADIdentifierQueryViewSectionsTables ||
            sectionType == MADIdentifierQueryViewSectionsGroups ||
            sectionType == MADIdentifierQueryViewSectionsPredicate ||
            sectionType == MADIdentifierQueryViewSectionsLinks);
}

#pragma mark -
#pragma mark Fetching

- (void)performFetchWithController:(NSFetchedResultsController *)controller {
    if (controller) {
        NSError * __autoreleasing error = NULL;
        [controller performFetch:&error];
        NSAssert(error == NULL, @"Error: %@", error);
    }
    [self.datasoruce reloadQueryViewData];
}

- (void)performFetchAll {
    [self performFetchTables];
    [self performFetchLinks];
    [self performFetchGroups];
    [self performFetchPredicate];
}

- (void)performFetchTables {
    [self performFetchWithController:self.queryTablesController];
}

- (void)performFetchLinks {
    [self performFetchWithController:self.queryLinksController];
}

- (void)performFetchGroups {
    [self performFetchWithController:self.queryGroupsController];
}

- (void)performFetchPredicate {
    [self performFetchWithController:self.queryPredicatesController];
}

#pragma mark -
#pragma mark Table View Data Source Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)_count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self numberOfRowsInSectionAtIndex:(short)section];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self canEditSectionAtIndex:(short)indexPath.section];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return ([self sectionAtIndex:(short)indexPath.section] == MADIdentifierQueryViewSectionsGroups);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style
                                            forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //NSLog(@"Commit editing style for index path: (%ld, %ld)", (long)indexPath.section, indexPath.row);
    switch (style) {
            
        case UITableViewCellEditingStyleDelete:
            [self.datasoruce deleteItemFromQuerySection: [self sectionAtIndex:(short)indexPath.section]
                                          fromTableView: tableView
                                            atIndexPath: indexPath];
            break;
            
        case UITableViewCellEditingStyleInsert:
            break;
            
        case UITableViewCellEditingStyleNone:
            break;
            
        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
      toIndexPath:(NSIndexPath *)toIndexPath {

    //NSLog(@"Move row at (%ld, %ld) to (%ld, %ld).", fromIndexPath.section, fromIndexPath.row, toIndexPath.section, toIndexPath.row);

    switch ([self sectionAtIndex:(short)toIndexPath.section]) {
        case MADIdentifierQueryViewSectionsGroups: {
            
            NSIndexPath *fromIndex =    [NSIndexPath indexPathForRow: fromIndexPath.row
                                                           inSection: 0],
                        *toIndex =      [NSIndexPath indexPathForRow: toIndexPath.row
                                                           inSection: 0];
            
            RptqQueryGroup *fromGroup = [_queryGroupsController objectAtIndexPath: fromIndex],
                           *toGroup =   [_queryGroupsController objectAtIndexPath: toIndex];
            
            id fromWeight   = [[NSNumber alloc] initWithInteger: toGroup.weight.integerValue],
               toWeight     = [[NSNumber alloc] initWithInteger: fromGroup.weight.integerValue];
            
            fromGroup.weight = fromWeight;
            toGroup.weight = toWeight;
            
            NSError *error = nil;
            [(self.queryGroupsController).managedObjectContext save:&error];

            //[self.document.managedObjectContext save:&error];
            [self performFetchGroups];
            break;
        }
        default:
            break;
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView { return nil; }

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //NSLog(@"Cell for row at index path: (%ld, %ld)", indexPath.section, indexPath.row);

    UITableViewCell *cell = nil;
    
    NSInteger row = indexPath.row;
    MADIdentifierQueryViewSections section = [self sectionAtIndex:(short)indexPath.section];
    
    switch (section) {
            
            // MARK: Display and identify the data source and data sources
        case MADIdentifierQueryViewSectionsDatasource: {
            
            static NSString *MADIdentifierTableViewCellDataSource = @"MADIdentifierTableViewCellDataSource";
            cell = [tableView dequeueReusableCellWithIdentifier: MADIdentifierTableViewCellDataSource];
            
            NSManagedObjectContext *managedObjectContext;
            managedObjectContext = self.datasoruce.document.managedObjectContext;
            RptqDocument *document;
            document = [self.datasoruce.document activeDocumentModel];
            RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
            if (database.ownedByUser) {
                
                id databaseType = database.ownedByUser.database_driver_type.copy;
                id schemaName = [database.ownedByUser copyDatabaseSchemaName];
                
                
                NSString *TextFormatConnection = @"You are connecting to %1$@"
                                                 @" datasource named %2$@.";
                id localizedMessageFormat = NSLocalizedString(TextFormatConnection, TextFormatConnection);
                id localizedMessage = [NSString stringWithFormat:localizedMessageFormat, databaseType, schemaName];
                id message = [NSAttributedString newAttributedStringQuerySectionDatasourceForMessage: localizedMessage
                                                                                        databaseType: databaseType
                                                                                          schemaName: schemaName];
                UILabel *textLabel = cell.textLabel;
                textLabel.attributedText = message;
                textLabel.text = localizedMessage;
            }
            
            break;
        }
            
            // MARK: Display the table names that are used in the query
        case MADIdentifierQueryViewSectionsTables: {
            
            static NSString *MyIdentifierUITableViewCellTableName = @"MADTableCellSchemaName";
            cell = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellTableName];
            
            NSIndexPath *path = [NSIndexPath indexPathForRow: row inSection: 0];
            RptqQueryTable *tablea = [self.queryTablesController objectAtIndexPath: path];
            cell.textLabel.text = tablea.alias.copy;

            break;

        }
            
            // MARK: Display the table links or joins that are used in the query.
        case MADIdentifierQueryViewSectionsLinks: {
            
            static NSString *MADIDCellInstruction = @"UITableViewCellQueryLink";
            cell = [tableView dequeueReusableCellWithIdentifier: MADIDCellInstruction];
            
            NSIndexPath *indexPathLinks = [NSIndexPath indexPathForRow: row inSection: 0];
            RptqQueryLinks *links = [self.queryLinksController objectAtIndexPath: indexPathLinks];
            
            NSString *leftString = [NSString newStringFieldDisplayWithTable: links.tableleft
                                                                   andField: links.fieldleft];
            
            NSString *rightString = [NSString newStringFieldDisplayWithTable: links.tableright
                                                                    andField: links.fieldright];
            
            NSString *linksDescription = [links copyLinkDescription];
            NSAttributedString *message;
            message = [NSAttributedString newAttributedStringQuerySectionLinks: leftString
                                                                   rightString: rightString
                                                              linksDescription: linksDescription];
            ((MADTableViewCellQueryLink *)cell).tableID = links.objectID.copy;
            cell.textLabel.attributedText = message;

            break;
        }
            
            // MARK: Display the groupings used in the query.
        case MADIdentifierQueryViewSectionsGroups: {
            
            static NSString *MADIDCellInstruction = @"UITableViewCellQueryGroup";
            cell = [tableView dequeueReusableCellWithIdentifier: MADIDCellInstruction];
            
            
            NSIndexPath *path = [NSIndexPath indexPathForRow: row inSection: 0];
            RptqQueryGroup *group = [self.queryGroupsController objectAtIndexPath: path];
            cell.backgroundView.backgroundColor = [UIColor whiteColor];
            
            NSString *field = [group fieldNameNice].copy,
            *sort  = [group sortDisplayNice].copy;
            NSAttributedString *message;
            message = [NSAttributedString newAttributedStringQuerySectionGroupWithField: field
                                                                                andSort: sort];
            cell.textLabel.attributedText = message;
            ((MADTableViewCellQueryGroup *)cell).tableID = group.objectID.copy;

            break;
        }
            
            // MARK: Display the predicates or conditions on the query.
        case MADIdentifierQueryViewSectionsPredicate: {
            static NSString *MADIDCellPredicate = @"UITableViewCellQueryPredicate";
            cell = [tableView dequeueReusableCellWithIdentifier: MADIDCellPredicate];
            NSIndexPath *indexPathPredicates = [NSIndexPath indexPathForRow: row inSection: 0];
            RptqQueryPredicate *predicate = [self.queryPredicatesController objectAtIndexPath: indexPathPredicates];

            NSString *leftFieldDisplay, *rightFieldDisplay, *symbol = [predicate symbolForDisplay];
            if (predicate.fieldleftpred != nil) {
                leftFieldDisplay = predicate.fieldleftpred;
            } else {
                leftFieldDisplay = [predicate.hasLeftField toString];
            }
            
            if (predicate.fieldrightpred != nil) {
                rightFieldDisplay = predicate.fieldrightpred;
            } else {
                rightFieldDisplay = [predicate.hasRightField toString];
            }
            NSAttributedString *message;
            message = [NSAttributedString newAttributedStringQueryPredicate: leftFieldDisplay
                                                                     symbol: symbol
                                                                  rightText: rightFieldDisplay];
            ((MADTableViewCellQueryPredicate *)cell).tableID = predicate.objectID.copy;
            cell.textLabel.attributedText = message;
            break;
        }
            
        case MADIdentifierQueryViewSectionsSql: {
            switch (row) {
                case 0: {
                    static NSString *MADIDCellOverride = @"UITableViewCellOverride";
                    cell = [tableView dequeueReusableCellWithIdentifier: MADIDCellOverride];
                    break;
                }
                default: {
                    static NSString *MADIDCellQueryInput = @"UITableViewCellQueryInput";
                    cell = [tableView dequeueReusableCellWithIdentifier: MADIDCellQueryInput];
                    break;
                }
            }
            break;
        }
            
        case MADIdentifierQueryViewSectionsNumberOfQueryResults: {
            
            static NSString *idNumberOfQueryResults = @"UITableViewCellNumberOfQueryResultsIdentifier";
            cell = [tableView dequeueReusableCellWithIdentifier: idNumberOfQueryResults];
            break;
        }
            
        default: {
            break;
        }
            
    }
    
    if (cell) {
        self.handleConfigureCell(cell, section, indexPath.row);
    } else {
        static NSString *idDefaultCell = @"DefaultCellShouldNotGetHere";
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault
                                      reuseIdentifier: idDefaultCell];
    }
    
    return cell;
}

@end
