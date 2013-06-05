//
//  UITableViewControllerLinkBuilder.m
//  Reports
//
//  Created by Michael Thomason on 1/26/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderLinkBuilderViewController.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"
#import "AppDelegate.h"

@interface MTQueryBuilderLinkBuilderViewController ()

@property (nonatomic, retain) RptqQueryTable *firstTableName;
@property (nonatomic, retain) RptqQueryTable *secondTableName;
@property (nonatomic, retain) RptqQueryField *firstFieldName;
@property (nonatomic, retain) RptqQueryField *secondFieldName;

@end

@implementation MTQueryBuilderLinkBuilderViewController

@synthesize delegate = _delegate;
@synthesize tableViewCellJoinType = _tableViewCellJoinType;
@synthesize tableViewCellTableOne = _tableViewCellTableOne;
@synthesize tableViewCellFieldOne = _tableViewCellFieldOne;
@synthesize tableViewCellTableTwo = _tableViewCellTableTwo;
@synthesize tableViewCellFieldTwo = _tableViewCellFieldTwo;
@synthesize tableViewCellTableFieldOne = _tableViewCellTableFieldOne;
@synthesize tableViewCellTableFieldTwo = _tableViewCellTableFieldTwo;
@synthesize linkType = _linkType;
@synthesize currentlyEditingPart = _currentlyEditingPart;

- (void)dealloc {
    [_firstTableName release];
    [_firstFieldName release];
    [_secondTableName release];
    [_tableViewCellJoinType release];
    [_tableViewCellTableOne release];
    [_tableViewCellFieldOne release];
    [_tableViewCellTableTwo release];
    [_tableViewCellFieldTwo release];
    [_tableViewCellTableFieldOne release];
    [_tableViewCellTableFieldTwo release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setCurrentlyEditingPart: MNSLinkNone];
        [[self tableViewCellTableFieldTwo] setUserInteractionEnabled:NO];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setCurrentlyEditingPart: MNSLinkNone];
        [[self tableViewCellTableFieldTwo] setUserInteractionEnabled:NO];
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showSelectJoinType"]) {

        if ([[segue destinationViewController] isKindOfClass: [MTQueryBuilderAddLinkJoinTypeViewController class]]) {
            MTQueryBuilderAddLinkJoinTypeViewController *vcFf = [segue destinationViewController];
            if (vcFf) {
                [vcFf setDelegate: self];
            }
        }

    } else {
        
        if ([[segue identifier] isEqualToString:@"showSelectTableOne"]) {

            if ([[segue destinationViewController] isKindOfClass: [MTQueryBuilderAddLinkFirstTableViewController class]]) {
                MTQueryBuilderAddLinkFirstTableViewController *tvc = [segue destinationViewController];
                if (tvc) {
                    [tvc setDelegate:self];
                    
                    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
                    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
                    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
                    RptqQuery *query = [[database hasQueries] anyObject];
                    
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryTable class])];
                    request.predicate = [NSPredicate predicateWithFormat:@"inQuery == %@", [query objectID]];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"alias" ascending:YES];
                    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];

                    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                          managedObjectContext: [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext]
                                                                                            sectionNameKeyPath: nil
                                                                                                     cacheName: nil];
                    [tvc setFetchedResultsController: frc];
                    [frc release];
                }
            }

        } else if ([[segue identifier] isEqualToString:@"showSelectFieldOne"]) {

            if ([[segue destinationViewController] isKindOfClass: [MTQueryBuilderAddLinkFirstFieldViewController class]]) {
                MTQueryBuilderAddLinkFirstFieldViewController *vcFf = [segue destinationViewController];
                if (vcFf) {
                    [vcFf setDelegate:self];
                    
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryField class])];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"databaseSchemaField.name" ascending:YES];
                    request.predicate = [NSPredicate predicateWithFormat:@"inQueryTable == %@", [[self firstTableName] objectID]];
                    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                          managedObjectContext: [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext]
                                                                                            sectionNameKeyPath: nil
                                                                                                     cacheName: nil];
                    [vcFf setFetchedResultsController: frc];
                    [frc release];
                }
            }

        } else if ([[segue identifier] isEqualToString:@"showSelectTableTwo"]) {

            
            if ([[segue destinationViewController] isKindOfClass: [MTQueryBuilderAddLinkSecondTableViewController class]]) {
                MTQueryBuilderAddLinkSecondTableViewController *vcFf = [segue destinationViewController];
                if (vcFf) {                
                    [vcFf setDelegate:self];                    

                    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
                    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
                    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
                    RptqQuery *query = [[database hasQueries] anyObject];

                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryTable class])];
                    request.predicate = [NSPredicate predicateWithFormat:@"inQuery == %@", [query objectID]];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"alias" ascending:YES];
                    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name != %@", [[self firstTableName] alias]];
                    [request setPredicate: predicate];
                    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                          managedObjectContext: [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext]
                                                                                            sectionNameKeyPath: nil
                                                                                                     cacheName: nil];
                    [vcFf setFetchedResultsController: frc];
                    [frc release];
                }
            }
        } else if ([[segue identifier] isEqualToString:@"showSelectFieldTwo"]) {

            if ([[segue destinationViewController] isKindOfClass: [MTQueryBuilderAddLinkSecondFieldViewController class]]) {
                MTQueryBuilderAddLinkSecondFieldViewController *vcFf = [segue destinationViewController];
                if (vcFf) {                
                    [vcFf setDelegate:self];
                    
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryField class])];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"databaseSchemaField.name" ascending:YES];
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inQueryTable == %@", [[self secondTableName] objectID]];
                    request.predicate = predicate;
                    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                          managedObjectContext: [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext]
                                                                                            sectionNameKeyPath: nil
                                                                                                     cacheName: nil];
                    [vcFf setFetchedResultsController: frc];
                    [frc release];
                }
            }
        } else if ([[segue identifier] isEqualToString:@"showSelectLinkTableFieldOne"]) {
            
            [self setCurrentlyEditingPart: MNSLinkLeft];
            
            MTQueryBuilderChooseFieldViewController *dvc = [segue destinationViewController];
            if (dvc != nil) {
                [dvc setExcludeTables: ([[self secondTableName] alias] ? [NSArray arrayWithObject:[[self secondTableName] alias]] : [NSArray array])];
                [dvc setDelegate: self];
            }

        } else if ([[segue identifier] isEqualToString:@"showSelectLinkTableFieldTwo"]) {
            
            [self setCurrentlyEditingPart: MNSLinkRight];
            
            MTQueryBuilderChooseFieldViewController *dvc = [segue destinationViewController];
            if (dvc != nil) {
                [dvc setExcludeTables: ([[self firstTableName] alias] ? [NSArray arrayWithObject:[[self firstTableName] alias]] : [NSArray array])];
                [dvc setDelegate: self];
            }

        }
    }
}


#pragma mark - Actions

- (IBAction)done:(id)sender {
    
}

- (IBAction)save:(id)sender {
    RptqQueryLinks *queryLink = [RptqQueryLinks createQueryLinkWithLeftField:[self firstFieldName] rightField:[self secondFieldName] andJoinType:[self linkType]];
    [[self delegate] viewControllerSchemaAddLinkDidAdd:queryLink];
}

- (IBAction)cancel:(id)sender {
    [[self delegate] viewControllerDidCancel:self];
}

#pragma mark - Delegate callbacks

- (void)tableViewControllerChooseFieldDidFinish: (MTQueryBuilderChooseFieldViewController *)controller
                                      withField: (RptqQueryField *)queryField {
    [[self navigationController] popToViewController: self animated: YES];
    
    RptqQueryTable *queryTable = [queryField inQueryTable];
    //RptqDatabaseSchemaTable *tableName = [queryTable databaseSchemaTable];
    //NSString *fieldName = [field name];
    //NSString *tableFieldName = [[NSString stringWithFormat:@"%@.%@", tableName, fieldName] retain];
    NSString *tableFieldName = [[queryField toString] retain];
    switch ([self currentlyEditingPart]) {
        case MNSLinkLeft:
            [[[self tableViewCellTableFieldOne] detailTextLabel] setText: [tableFieldName lowercaseString]];
            [self setFirstTableName:queryTable];
            [self setFirstFieldName:queryField];
//            [self setFirstTableFieldName:tableFieldName];

            [[self tableViewCellTableFieldTwo] setUserInteractionEnabled:YES];
            [[[self tableViewCellTableFieldTwo] textLabel] setEnabled:YES];
            [[[self tableViewCellTableFieldTwo] detailTextLabel] setEnabled:YES];
            
            //[[[self tableViewCellTableFieldTwo] textLabel] setTextColor:[UIColor darkTextColor]];
            NSString *required = [NSLocalizedString(@"Required", @"Shows that this field is required.") lowercaseString];
            [[[self tableViewCellTableFieldTwo] detailTextLabel] setText: required];
            [[self tableViewCellTableFieldTwo] setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            break;
        case MNSLinkRight:
            [[[self tableViewCellTableFieldTwo] detailTextLabel] setText: [tableFieldName lowercaseString]];
            [self setSecondTableName:queryTable];
            [self setSecondFieldName:queryField];
//            [self setSecondTableFieldName:tableFieldName];
            break;
        default:
            break;
    }
    //NSLog(@"%@", NSStringFromCGRect([[self tableViewCellTableFieldOne] detailTextLabel].frame));
    //[[[self tableViewCellFieldOne] detailTextLabel] setNeedsLayout];
    [tableFieldName release];
}

- (void)viewControllerDidFinishWithTable:(RptqQueryTable *)result {
    [[self navigationController] popToViewController: self animated: YES];
    [[[self tableViewCellTableOne] detailTextLabel] setText: [[result alias] lowercaseString]];
    [self setFirstTableName: result];
}

- (void)viewControllerSchemaAddLinkFirstFieldDidFinishWith:(RptqQueryField *)result {
    [[self navigationController] popToViewController: self animated: YES];
    [[[self tableViewCellFieldOne] detailTextLabel] setText: [[[result databaseSchemaField] name] lowercaseString]];
    [self setFirstFieldName: result];
}

- (void)viewControllerDidFinishWithSecondTable:(RptqQueryTable *)result {
    [[self navigationController] popToViewController: self animated: YES];
    [[[self tableViewCellTableTwo] detailTextLabel] setText: [[result alias] lowercaseString]];
    [self setSecondTableName: result];
}

- (void)viewControllerSchemaAddLinkDidSecondFieldFinishWith:(RptqQueryField *)result {
    [[self navigationController] popToViewController: self animated: YES];
    [[[self tableViewCellFieldTwo] detailTextLabel] setText: [[[result databaseSchemaField] name] lowercaseString]];
    [self setSecondFieldName: result];
}

- (void)viewControllerSchemaAddLinkJoinTypeDidFinishWith:(MNSLinkType)result from:(MTReportDocument *)document {
    switch (result) {
        case MNSLinkTypeEquiJoin:
            [[[self tableViewCellJoinType] detailTextLabel] setText:[[MNSLinkTypeNames objectAtIndex:MNSLinkTypeEquiJoin] lowercaseString]];
            break;
        case MNSLinkTypeCrossJoin:
            [[[self tableViewCellJoinType] detailTextLabel] setText:[[MNSLinkTypeNames objectAtIndex:MNSLinkTypeCrossJoin] lowercaseString]];
            break;
        case MNSLinkTypeFullOuterJoin:
            [[[self tableViewCellJoinType] detailTextLabel] setText:[[MNSLinkTypeNames objectAtIndex:MNSLinkTypeFullOuterJoin] lowercaseString]];
            break;
        case MNSLinkTypeInnerJoin:
            [[[self tableViewCellJoinType] detailTextLabel] setText:[[MNSLinkTypeNames objectAtIndex:MNSLinkTypeInnerJoin] lowercaseString]];
            break;
        case MNSLinkTypeLeftOuterJoin:
            [[[self tableViewCellJoinType] detailTextLabel] setText:[[MNSLinkTypeNames objectAtIndex:MNSLinkTypeLeftOuterJoin] lowercaseString]];
            break;
        case MNSLinkTypeNaturalJoin:
            [[[self tableViewCellJoinType] detailTextLabel] setText:[[MNSLinkTypeNames objectAtIndex:MNSLinkTypeNaturalJoin] lowercaseString]];
            break;
        case MNSLinkTypeRightOuterJoin:
            [[[self tableViewCellJoinType] detailTextLabel] setText:[[MNSLinkTypeNames objectAtIndex:MNSLinkTypeRightOuterJoin] lowercaseString]];
            break;
        default:
            break;
    }
    [[self navigationController] popToViewController: self animated: YES];
    [self setLinkType: result];
}

@end