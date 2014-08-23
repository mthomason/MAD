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
#import "RptqQueryLinks+Extras.h"

@interface MTQueryBuilderLinkBuilderViewController ()

@property (nonatomic, strong) RptqQueryTable *firstTable;
@property (nonatomic, strong) RptqQueryTable *secondTable;

@property (nonatomic, strong) RptqQueryField *firstField;
@property (nonatomic, strong) RptqQueryField *secondField;

@property (nonatomic, strong) IBOutlet UILabel *labelRightField;

//- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;
//- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_DESIGNATED_INITIALIZER;

@end

@implementation MTQueryBuilderLinkBuilderViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    return self = [super initWithCoder:aDecoder];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setJoinType:MNSLinkTypeLeftOuterJoin];
    [self setCurrentlyEditingPart: MNSLinkNone];
    [self updateRightLabelState];
    [self updateSaveButtonState];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showSelectJoinType"]) {

        if ([segue.destinationViewController isKindOfClass: [MTQueryBuilderAddLinkJoinTypeViewController class]]) {
            MTQueryBuilderAddLinkJoinTypeViewController *vcFf = segue.destinationViewController;
            vcFf.delegate = self;
            vcFf.document = self.document;
        }
    } else {
        
        if ([[segue identifier] isEqualToString:@"showSelectLinkTableFieldOne"]) {
            
            [self setCurrentlyEditingPart: MNSLinkLeft];
            
            MTQueryBuilderChooseFieldViewController *dvc = segue.destinationViewController;
            
            if (dvc != nil) {
                [dvc setExcludeTables: ([[self secondTable] alias] ? @[[[self secondTable] alias]] : @[])];
                dvc.delegate = self;
                dvc.document = self.document;
            }

        } else if ([[segue identifier] isEqualToString:@"showSelectLinkTableFieldTwo"]) {
            
            [self setCurrentlyEditingPart: MNSLinkRight];
            
            MTQueryBuilderChooseFieldViewController *dvc = segue.destinationViewController;
            if (dvc != nil) {
                [dvc setExcludeTables: ([[self firstTable] alias] ? @[[[self firstTable] alias]] : @[])];
                dvc.delegate = self;
                dvc.document = self.document;
            }
        }
    }
}


#pragma mark - Actions

- (IBAction)save:(id)sender {
    if ([self firstField] && [self secondField]) {
        RptqQueryLinks *queryLink = [RptqQueryLinks queryLinkFactoryWithLeftField:[self firstField] rightField:[self secondField] joinType:[self linkType]];
        [self.delegate viewControllerSchemaAddLinkDidAdd:queryLink];
    } else {
        [self cancel:sender];
    }
}

- (IBAction)cancel:(id)sender {
    [self.delegate viewControllerDidCancel:self];
}

#pragma mark - Delegate callbacks

- (MNSLinkType)initalLinktype {
    return [self linkType];
}

- (void)tableViewControllerChooseFieldDidFinish: (MTQueryBuilderChooseFieldViewController *)controller
                                      withField: (RptqQueryField *)queryField {
    [[self navigationController] popToViewController: self animated: YES];
    
    RptqQueryTable *queryTable = [queryField inQueryTable];
    NSString *tableFieldName = [queryField toString];
    switch ([self currentlyEditingPart]) {
        case MNSLinkLeft: {
            [[[self tableViewCellTableFieldOne] detailTextLabel] setText: [tableFieldName lowercaseString]];
            [self setFirstTable:queryTable];
            [self setFirstField:queryField];
            
            [self updateRightLabelState];

            
            NSString *required = [NSLocalizedString(@"Required", @"Shows that this field is required.") lowercaseString];
            [[[self tableViewCellTableFieldTwo] detailTextLabel] setText: required];
            [[self tableViewCellTableFieldTwo] setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            break;
        }
        case MNSLinkRight: {
            [[[self tableViewCellTableFieldTwo] detailTextLabel] setText: [tableFieldName lowercaseString]];
            [self setSecondTable:queryTable];
            [self setSecondField:queryField];
            break;
        }
        default:
            break;
    }
    [self updateSaveButtonState];
}

- (void)viewControllerSchemaAddLinkJoinTypeDidFinishWith:(MNSLinkType)result from:(MAReportDocument *)document {
    [self setJoinType:result];
    [[self navigationController] popToViewController: self animated: YES];
}

#pragma mark - Helper functions

- (void)setJoinType:(MNSLinkType)type {
    NSString *text = [[RptqQueryLinks LocalizedNamesForLinkType:type] lowercaseString];
    [[[self tableViewCellJoinType] detailTextLabel] setText:text];
    [self setLinkType: type];
}

- (BOOL)firstFieldSet {
    return [self firstField] != nil;
}

- (BOOL)secondFieldSet {
    return [self secondField] != nil && [[self firstField] isEqual:[self secondField]] == NO;
}

- (void)updateRightLabelState {
    BOOL enabled = [self firstFieldSet];
    [[self tableViewCellTableFieldTwo] setUserInteractionEnabled:enabled];
    [[[self tableViewCellTableFieldTwo] textLabel] setEnabled:enabled];
    [[[self tableViewCellTableFieldTwo] detailTextLabel] setEnabled:enabled];
    [[self labelRightField] setEnabled:enabled];
    UIColor *darkTextColor = enabled ? [UIColor blackColor] : [UIColor darkTextColor];
    [[self labelRightField] setTextColor:darkTextColor];
}

- (void)updateSaveButtonState {
    BOOL enabled = [self firstFieldSet] && [self secondField];
    [[[self navigationItem] rightBarButtonItem] setEnabled:enabled];
}

@end
