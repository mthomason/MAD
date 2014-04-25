//
//  UITableViewControllerLinkBuilder.m
//  Reports
//
//  Created by Michael Thomason on 1/26/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryBuilderLinkBuilderViewController.h"
#import "AppDelegate.h"
#import "RptqQuery.h"
#import "RptqQueryTable.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "RptqDatabaseSchemaField.h"

@interface MTQueryBuilderLinkBuilderViewController ()

@property (nonatomic, strong) RptqQueryTable *firstTableName;
@property (nonatomic, strong) RptqQueryTable *secondTableName;
@property (nonatomic, strong) RptqQueryField *firstFieldName;
@property (nonatomic, strong) RptqQueryField *secondFieldName;
@property (nonatomic, strong) IBOutlet UILabel *labelRightField;

@end

@implementation MTQueryBuilderLinkBuilderViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setCurrentlyEditingPart: MNSLinkNone];
        [[self tableViewCellTableFieldTwo] setUserInteractionEnabled:NO];
        [[self labelRightField] setEnabled:NO];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setCurrentlyEditingPart: MNSLinkNone];
        [[self tableViewCellTableFieldTwo] setUserInteractionEnabled:NO];
        [[self labelRightField] setEnabled:NO];
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
        
        RptqQuery *query = [AppDelegate activeRptqQuery];
        NSManagedObjectContext *managedObjectContext = [query managedObjectContext];
        
        if ([[segue identifier] isEqualToString:@"showSelectTableOne"]) {

            if ([[segue destinationViewController] isKindOfClass: [MTQueryBuilderAddLinkFirstTableViewController class]]) {
                MTQueryBuilderAddLinkFirstTableViewController *tvc = [segue destinationViewController];
                if (tvc) {
                    [tvc setDelegate:self];
                    
                    
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryTable class])];
                    request.predicate = [NSPredicate predicateWithFormat:@"inQuery == %@", [query objectID]];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"alias" ascending:YES];
                    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];

                    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                          managedObjectContext: managedObjectContext
                                                                                            sectionNameKeyPath: nil
                                                                                                     cacheName: nil];
                    [tvc setFetchedResultsController: frc];
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
                                                                                          managedObjectContext: managedObjectContext
                                                                                            sectionNameKeyPath: nil
                                                                                                     cacheName: nil];
                    [vcFf setFetchedResultsController: frc];
                }
            }

        } else if ([[segue identifier] isEqualToString:@"showSelectTableTwo"]) {

            
            if ([[segue destinationViewController] isKindOfClass: [MTQueryBuilderAddLinkSecondTableViewController class]]) {
                MTQueryBuilderAddLinkSecondTableViewController *vcFf = [segue destinationViewController];
                if (vcFf) {                
                    [vcFf setDelegate:self];                    


                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryTable class])];
                    request.predicate = [NSPredicate predicateWithFormat:@"inQuery == %@", [query objectID]];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"alias" ascending:YES];
                    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name != %@", [[self firstTableName] alias]];
                    [request setPredicate: predicate];
                    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                          managedObjectContext: managedObjectContext
                                                                                            sectionNameKeyPath: nil
                                                                                                     cacheName: nil];
                    [vcFf setFetchedResultsController: frc];
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
                                                                                          managedObjectContext: managedObjectContext
                                                                                            sectionNameKeyPath: nil
                                                                                                     cacheName: nil];
                    [vcFf setFetchedResultsController: frc];
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
    NSString *tableFieldName = [queryField toString];
    switch ([self currentlyEditingPart]) {
        case MNSLinkLeft: {
            [[[self tableViewCellTableFieldOne] detailTextLabel] setText: [tableFieldName lowercaseString]];
            [self setFirstTableName:queryTable];
            [self setFirstFieldName:queryField];

            [[self tableViewCellTableFieldTwo] setUserInteractionEnabled:YES];
            [[[self tableViewCellTableFieldTwo] textLabel] setEnabled:YES];
            [[[self tableViewCellTableFieldTwo] detailTextLabel] setEnabled:YES];
            [[self labelRightField] setEnabled:YES];
            [[self labelRightField] setTextColor:[UIColor darkTextColor]];
            
            NSString *required = [NSLocalizedString(@"Required", @"Shows that this field is required.") lowercaseString];
            [[[self tableViewCellTableFieldTwo] detailTextLabel] setText: required];
            [[self tableViewCellTableFieldTwo] setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            break;
        }
        case MNSLinkRight: {
            [[[self tableViewCellTableFieldTwo] detailTextLabel] setText: [tableFieldName lowercaseString]];
            [self setSecondTableName:queryTable];
            [self setSecondFieldName:queryField];
            break;
        }
        default:
            break;
    }
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

- (void)viewControllerSchemaAddLinkJoinTypeDidFinishWith:(MNSLinkType)result from:(MAReportDocument *)document {
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
