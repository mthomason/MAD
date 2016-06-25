//
//  MADQueryViewControllerLayout.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryViewDataSource.h"

#import "MADTableViewCellQueryTableName.h"
#import "MADTableViewCellQueryLink.h"
#import "MADTableViewCellQueryPredicate.h"

#import "MADQueryViewControllerLayoutSections.h"

#import <CoreData/NSFetchedResultsController.h>

#import <MAD/MADocument.h>

#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqQuery+Extras.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryGroup+Extras.h>
#import <MAD/RptqQueryLinks+Extras.h>
#import <MAD/RptqQueryPredicate+Extras.h>
#import <MAD/RptqUserCredentals+Extras.h>

#import <Foundation/NSIndexPath.h>
#import <UIKit/UITableView.h>

@interface MADQueryViewDataSource ()
    <NSFetchedResultsControllerDelegate>

    @property (nonatomic, weak) MADocument *document;

    @property (nonatomic, strong) NSFetchedResultsController *queryTablesController;
    @property (nonatomic, strong) NSFetchedResultsController *queryLinksController;
    @property (nonatomic, strong) NSFetchedResultsController *queryGroupsController;
    @property (nonatomic, strong) NSFetchedResultsController *queryPredicatesController;

    @property (nonatomic, readwrite, assign) short count;
    @property (nonatomic, readwrite, assign) NSUInteger numberOfTables;
    @property (nonatomic, readwrite, strong) NSArray <__kindof MADQueryViewControllerLayoutSection *> *sections;

@end

@implementation MADQueryViewDataSource

- (instancetype)initWithNumberOfTables:(NSUInteger)numberOfTables reportingEnabled:(BOOL)reportingEnabled {

    if (self = [super init]) {
        
        short count;
        switch (numberOfTables) {
            case 0:
                count = reportingEnabled ? 3 : 2;
                break;
            case 1:
                count = reportingEnabled ? 5 : 4;
                break;
            default:
                count = reportingEnabled ? 6 : 5;
                break;
        }
        
        _numberOfTables = numberOfTables;
        _count = count;
        
    }
    return self;
}
#pragma mark -
#pragma mark - Helpers 

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

- (void)performFetchWithController:(NSFetchedResultsController *)controller {
    if (controller) {
        [controller performFetch:nil];
    }
// FIXME: Call reload data
    //[self.tableView reloadData];
}

- (void)reloadDocument:(MADocument *)document animated:(BOOL)animated {
    self.document = document;

    NSAssert(document != nil, @"%s: Need a document", __PRETTY_FUNCTION__);
    if (document) {
        
        NSManagedObjectContext *managedObjectContext = document.managedObjectContext;
        
        NSFetchedResultsController * (^newFetchedResultsController)(NSString *, NSPredicate *, NSSortDescriptor *, id <NSFetchedResultsControllerDelegate>);
        newFetchedResultsController = ^NSFetchedResultsController *(NSString *entityName,
                                                                    NSPredicate *predicate,
                                                                    NSSortDescriptor *sortDescriptor,
                                                                    id <NSFetchedResultsControllerDelegate> delegate) {
            
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: entityName];
            request.predicate = predicate;
            NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
            request.sortDescriptors = sortDescriptors;
            
            NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                  managedObjectContext: managedObjectContext
                                                                                    sectionNameKeyPath: nil
                                                                                             cacheName: nil];
            frc.delegate = delegate;
            return frc;
        };
        
        {
            RptqDatabase *database = document.activeDocumentModel.hasDatabaseSchemas.anyObject;
            RptqQuery *query = database.hasQueries.anyObject;
            
            NSString *entityName = NSStringFromClass([RptqQueryTable class]);
            id predicate = [NSPredicate predicateWithFormat:@"inQuery == %@", query.objectID];
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"alias"
                                                                           ascending: YES];
            NSFetchedResultsController *frc;
            frc = newFetchedResultsController(entityName, predicate, sortDescriptor, self);
            
            self.queryTablesController = frc;
            [self performFetchTables];
            frc = nil;
        }
        
        {
            NSString *entityName = NSStringFromClass([RptqQueryLinks class]);
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"tableleft"
                                                                           ascending: YES];
            
            NSFetchedResultsController *frc;
            frc = newFetchedResultsController(entityName, nil, sortDescriptor, self);
            self.queryLinksController = frc;
            [self performFetchLinks];
            frc = nil;
        }
        
        {
            NSString *entityName = NSStringFromClass([RptqQueryGroup class]);
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"weight"
                                                                           ascending: YES];
            
            NSFetchedResultsController *frc;
            frc = newFetchedResultsController(entityName, nil, sortDescriptor, self);
            self.queryGroupsController = frc;
            [self performFetchGroups];
            frc = nil;
            
        }
        
        {
            NSString *entityName = NSStringFromClass([RptqQueryPredicate class]);
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"fieldleftpred"
                                                                           ascending: YES];
            NSFetchedResultsController *frc;
            frc = newFetchedResultsController(entityName, nil, sortDescriptor, self);
            self.queryPredicatesController = frc;
            [self performFetchPredicate];
            frc = nil;
        }

//FIXME: Reload data
//        [self.tableView reloadData];
    }
}

- (MADIdentifierQueryViewSections)sectionAtIndex:(short)index {
    MADQueryViewControllerLayoutSection *layout = [[MADQueryViewControllerLayoutSection alloc] initWithNumberOfTables:_numberOfTables position:index];
    return layout.querySection;
}

- (NSIndexSet *)sectionTypesIndexs {
    NSMutableIndexSet *sectionTypes = [[NSMutableIndexSet alloc] init];
    NSArray <__kindof MADQueryViewControllerLayoutSection *> *sections = self.sections;
    for (MADQueryViewControllerLayoutSection *section in sections) {
        [sectionTypes addIndex:section.querySection];
    }
    return sectionTypes;
}

- (NSSet <__kindof NSNumber *> *)sectionTypes {
    NSMutableSet <__kindof NSNumber *> *sectionTypes = [[NSMutableSet alloc] initWithCapacity:(NSUInteger)_count];
    for (MADQueryViewControllerLayoutSection *section in self.sections) {
        @autoreleasepool {
            NSNumber *sectionType = [[NSNumber alloc] initWithShort:section.querySection];
            [sectionTypes addObject:sectionType];
        }
    }
    return sectionTypes;
}

- (MADQueryViewControllerLayoutSection *)layoutAtIndex:(short)index {
    return self.sections[(NSUInteger)index];
}

- (NSArray <__kindof MADQueryViewControllerLayoutSection *> *)sections {
    if (_sections != nil) {
        return _sections;
    } else {
        NSMutableArray <__kindof MADQueryViewControllerLayoutSection *> *sections = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)_count];
        for (short i = 0; i < _count; i++) {
            @autoreleasepool {
                MADQueryViewControllerLayoutSection *section = [[MADQueryViewControllerLayoutSection alloc] initWithNumberOfTables:_numberOfTables position:i];
                [sections addObject:section];
            }
        }
        _sections = sections;
        return _sections;
    }
}

#pragma mark -
#pragma mark Table View Data Source Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)self.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    
    MADQueryViewControllerLayoutSection *layoutSection = [self layoutAtIndex:(short)section];
    
    NSInteger numberOfRows = 1;
    if (layoutSection.numberOfRows == NSNotFound) {
        id <NSFetchedResultsSectionInfo> sectionData;
        switch (layoutSection.querySection) {
            case MADIdentifierQueryViewSectionsTables: {
                sectionData = self.queryTablesController.sections[0];
                numberOfRows = (NSInteger)sectionData.numberOfObjects;
                break;
            }
            case MADIdentifierQueryViewSectionsLinks: {
                sectionData = self.queryLinksController.sections[0];
                numberOfRows = (NSInteger)sectionData.numberOfObjects;
                break;
            }
            case MADIdentifierQueryViewSectionsPredicate: {
                sectionData = self.queryPredicatesController.sections[0];
                numberOfRows = (NSInteger)sectionData.numberOfObjects;
                break;
            }
            case MADIdentifierQueryViewSectionsGroups: {
                sectionData = self.queryGroupsController.sections[0];
                numberOfRows = (NSInteger)sectionData.numberOfObjects;
                break;
            }
            default:
                numberOfRows = 0;
                break;
        }
    }
	return numberOfRows;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    MADIdentifierQueryViewSections sectionType = [self sectionAtIndex:(short)indexPath.section];
	return (sectionType == MADIdentifierQueryViewSectionsTables ||
            sectionType == MADIdentifierQueryViewSectionsGroups ||
            sectionType == MADIdentifierQueryViewSectionsPredicate ||
            sectionType == MADIdentifierQueryViewSectionsLinks);
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return ([self sectionAtIndex:(short)indexPath.section] == MADIdentifierQueryViewSectionsGroups);
}

- (void)tableView:(UITableView *)tableView
                                commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
                                 forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MADIdentifierQueryViewSections querySection = [self sectionAtIndex:(short)indexPath.section];

    switch (editingStyle) {

        case UITableViewCellEditingStyleDelete:
            [self.datasoruce deleteItemFromQuerySection: querySection
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
    
    MADIdentifierQueryViewSections ts = [self sectionAtIndex:(short)toIndexPath.section];
    switch (ts) {
        case MADIdentifierQueryViewSectionsGroups: {

            NSIndexPath *fromIndex = [NSIndexPath indexPathForRow: fromIndexPath.row inSection: 0],
                        *toIndex = [NSIndexPath indexPathForRow: toIndexPath.row inSection: 0];
            RptqQueryGroup *fromGroup = [self.queryGroupsController objectAtIndexPath: fromIndex],
                           *toGroup = [self.queryGroupsController objectAtIndexPath: toIndex];
            
            id fromWeight = [[NSNumber alloc] initWithInteger: toGroup.weight.integerValue],
               toWeight = [[NSNumber alloc] initWithInteger: fromGroup.weight.integerValue];

            fromGroup.weight = fromWeight;
            toGroup.weight = toWeight;

            NSError *error = nil;
            [(self.queryGroupsController).managedObjectContext save:&error];
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
    
    UITableViewCell *result = nil;

    NSInteger row = indexPath.row;
    MADIdentifierQueryViewSections section = [self sectionAtIndex:(short)indexPath.section];
    
// FIXME: init table cell
    /*
    switch (section) {

        // MARK: Display and identify the data source and data sources
        case MADIdentifierQueryViewSectionsDatasource: {
        
            static NSString *MADIdentifierTableViewCellDataSource = @"MADIdentifierTableViewCellDataSource";
            result = [tableView dequeueReusableCellWithIdentifier: MADIdentifierTableViewCellDataSource];

            RptqDatabase *database = self.document.activeDocumentModel.hasDatabaseSchemas.anyObject;
            if (database.ownedByUser) {

                id databaseType = database.ownedByUser.database_driver_type.copy;
                id schemaName = [database.ownedByUser copyDatabaseSchemaName];
                id localizedMessage = NSLocalizedString(TextFormatConnection, TextFormatConnection);
                id message = [NSAttributedString newAttributedStringQuerySectionDatasourceForMessage: localizedMessage
                                                                                        databaseType: databaseType
                                                                                          schemaName: schemaName];
                
                result.textLabel.attributedText = message;
                result.detailTextLabel.text = @"";
                result.tintColor = [MADColorEverydayApps newColorBlackTwentyFivePercent];

            }
            result.textLabel.numberOfLines = 0;
            break;
        }

        // MARK: Display the table names that are used in the query
        case MADIdentifierQueryViewSectionsTables: {
        
            static NSString *MyIdentifierUITableViewCellTableName = @"UITableViewCellTableName";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellTableName];
            NSIndexPath *path = [NSIndexPath indexPathForRow: row inSection: 0];
            RptqQueryTable *tablea = [self.queryTablesController objectAtIndexPath: path];
            NSString *alias = tablea.alias.copy;
            UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            result.textLabel.text = alias;
            result.textLabel.font = font;
            result.textLabel.backgroundColor = [UIColor whiteColor];
            result.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            result.indentationLevel = 1;
            result.tintColor = [MADColorEverydayApps newColorBlue];
            result.backgroundColor = [UIColor whiteColor];
            break;
        }
        
        // MARK: Display the table links or joins that are used in the query.
        case MADIdentifierQueryViewSectionsLinks: {

            static NSString *MADIDCellInstruction = @"UITableViewCellQueryLink";
            result = [tableView dequeueReusableCellWithIdentifier: MADIDCellInstruction];
            NSIndexPath *indexPathLinks = [NSIndexPath indexPathForRow: row inSection: 0];
            RptqQueryLinks *links = [self.queryLinksController objectAtIndexPath: indexPathLinks];
            
            NSString *leftString = [NSString newStringFieldDisplayWithTable:links.tableleft
                                                                   andField:links.fieldleft];

            NSString *rightString = [NSString newStringFieldDisplayWithTable:links.tableright
                                                                    andField:links.fieldright];

            NSString *linksDescription = [links copyLinkDescription];
            NSAttributedString *message;
            message = [NSAttributedString newAttributedStringQuerySectionLinks:leftString
                                                                   rightString:rightString
                                                              linksDescription: linksDescription];
            ((MADTableViewCellQueryLink *)result).tableID = links.objectID.copy;
            result.textLabel.numberOfLines = 0;
            result.textLabel.attributedText = message;

            break;
        }

        // MARK: Display the groupings used in the query.
        case MADIdentifierQueryViewSectionsGroups: {
            static NSString *MADIDCellInstruction = @"UITableViewCellQueryGroup";
            result = [tableView dequeueReusableCellWithIdentifier: MADIDCellInstruction];
            NSIndexPath *path = [NSIndexPath indexPathForRow: row inSection: 0];
            RptqQueryGroup *group = [self.queryGroupsController objectAtIndexPath: path];
            result.backgroundView.backgroundColor = [UIColor whiteColor];
            
            NSString *field = [group fieldNameNice].copy,
                     *sort  = [group sortDisplayNice].copy;
            NSAttributedString *message;
            message = [NSAttributedString newAttributedStringQuerySectionGroupWithField: field
                                                                                andSort: sort];
            result.textLabel.attributedText = message;
            result.textLabel.numberOfLines = 0;
            ((MADTableViewCellQueryGroup *)result).tableID = group.objectID.copy;
            break;
        }
        
        // MARK: Display the predicates or conditions on the query.
        case MADIdentifierQueryViewSectionsPredicate: {
            static NSString *MADIDCellPredicate = @"UITableViewCellQueryPredicate";
            result = [tableView dequeueReusableCellWithIdentifier: MADIDCellPredicate];
            
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
            result.textLabel.numberOfLines = 0;
            result.textLabel.attributedText = message;
            ((MADTableViewCellQueryPredicate *)result).tableID = predicate.objectID.copy;
            
            break;
        }
        
        case MADIdentifierQueryViewSectionsSql: {
            switch (row) {
                case 0: {
                    static NSString *MADIDCellOverride = @"UITableViewCellOverride";
                    result = [tableView dequeueReusableCellWithIdentifier: MADIDCellOverride];
                    break;
                }
                default: {
                    static NSString *MADIDCellQueryInput = @"UITableViewCellQueryInput";
                    result = [tableView dequeueReusableCellWithIdentifier: MADIDCellQueryInput];
                    break;
                }
            }
            break;
        }
            
        case MADIdentifierQueryViewSectionsNumberOfQueryResults: {
        
            static NSString *idNumberOfQueryResults = @"UITableViewCellNumberOfQueryResultsIdentifier";
            result = [tableView dequeueReusableCellWithIdentifier: idNumberOfQueryResults];
            UISwitch *s = [[UISwitch alloc] initWithFrame:CGRectZero];
            s.on = [[NSUserDefaults standardUserDefaults] boolForKey:MADIdentifierDefaultsViewerDesired];
            [s addTarget:self action:@selector(handleToggleReportingMode:) forControlEvents:UIControlEventValueChanged];
            result.accessoryView = s;
            result.textLabel.text = [[NSUserDefaults standardUserDefaults] boolForKey:MADIdentifierDefaultsViewerDesired] ?
                                                    @"Reporting Mode" : @"Designer Mode (limited)";
            break;
        }
        
        default: {
            break;
        }

    }

    if (!result) {
        result = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCellShouldNotGetHere"];
        (result.textLabel).text = @"Err";
    }
     */

    return result;
}


@end
