//
//  UITableViewControllerLinkBuilder.m
//  Reports
//
//  Created by Michael Thomason on 1/26/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryLinkBuilderController.h"

#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UILabel.h>

#import <MAD/MADocument.h>

#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>

#import <MAD/RptqQueryTable.h>

#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryField+Extras.h>

#import <MAD/RptqQueryLinks.h>
#import <MAD/RptqQueryLinks+Extras.h>

#import "MADQueryChooseFieldController.h"
#import "MADQueryAddLinkJoinTypeController.h"

@interface MADQueryLinkBuilderController ()

    @property (nonatomic, strong) RptqQueryTable *firstTable;
    @property (nonatomic, strong) RptqQueryTable *secondTable;

    @property (nonatomic, strong) RptqQueryField *firstField;
    @property (nonatomic, strong) RptqQueryField *secondField;

    @property (nonatomic, strong) IBOutlet UILabel *labelRightField;

@end

@implementation MADQueryLinkBuilderController

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
    self.currentlyEditingPart = MADLinkNone;
    [self updateRightLabelState];
    [self updateSaveButtonState];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"showSelectJoinType"]) {

        if ([segue.destinationViewController isKindOfClass:
                                        [MADQueryAddLinkJoinTypeController class]]) {
            [self setupJoinController:segue.destinationViewController];
        }
        
    } else {
        
        if ([segue.identifier isEqualToString:@"showSelectLinkTableFieldOne"]) {
            
            self.currentlyEditingPart = MADLinkLeft;
            [self setupFieldController2:segue.destinationViewController];

        } else if ([segue.identifier isEqualToString:@"showSelectLinkTableFieldTwo"]) {
            
            self.currentlyEditingPart = MADLinkRight;
            [self setupFieldController1:segue.destinationViewController];
            
        }
    }
}

- (void)setupJoinController:(MADQueryAddLinkJoinTypeController *)controller {
    controller.delegate = self;
    controller.document = self.document;
}

- (void)setupFieldController1:(MADQueryChooseFieldController *)controller {
    [self setupFieldController:controller excludeTable:self.firstTable];
}

- (void)setupFieldController2:(MADQueryChooseFieldController *)controller {
    [self setupFieldController:controller excludeTable:self.secondTable];
}

- (void)setupFieldController:(MADQueryChooseFieldController *)controller
                 excludeTable:(RptqQueryTable *)excludeTable {
    if (controller == nil) return;
    id alias = excludeTable.alias.copy;
    NSArray *excludeTables = alias != nil ?
                                [[NSArray alloc] initWithObjects:alias, nil] :
                                [[NSArray alloc] init];
    controller.excludeTables = excludeTables;
    controller.delegate = self;
    controller.document = self.document;
}

#pragma mark - Actions

- (IBAction)save:(id)sender {
    if (self.firstField && self.secondField) {
        MADocument *document = self.document;
        RptqQueryLinks *links;
        links = [RptqQueryLinks newQueryLinksWithLeftField: self.firstField
                                                rightField: self.secondField
                                                  joinType: self.linkType
                                      managedObjectContext: document.managedObjectContext];
        [document.activeDocumentModel addQueryLink:links];
        [document saveContext];
        
        [self.queryLinkDelegate viewController:self addedQueryLink: links];
    } else {
        [self cancel:sender];
    }
}

- (IBAction)cancel:(id)sender {
    [self.queryLinkDelegate viewControllerDidCancel:self];
}

#pragma mark - Delegate callbacks

- (MNSLinkType)initalLinktype {
    return self.linkType;
}

- (void)tableViewControllerChooseFieldDidFinish: (MADQueryChooseFieldController *)controller
                                      withField: (RptqQueryField *)queryField {
    [self.navigationController popToViewController: self animated: YES];
    
    RptqQueryTable *queryTable = queryField.inQueryTable;
    NSString *tableFieldName = [queryField toString];
    switch (self.currentlyEditingPart) {
        case MADLinkLeft: {

            self.tableViewCellTableFieldOne.detailTextLabel.text = tableFieldName.lowercaseString;
            self.firstTable = queryTable;
            self.firstField = queryField;
            
            [self updateRightLabelState];

            NSString *required = NSLocalizedString(@"Required",
                                                   @"Shows that this field is required.");
            required = required.lowercaseString;
            self.tableViewCellTableFieldTwo.detailTextLabel.text = required;
            self.tableViewCellTableFieldTwo.accessoryType =
                                                    UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case MADLinkRight: {
            self.tableViewCellTableFieldTwo.detailTextLabel.text = tableFieldName.lowercaseString;
            self.secondTable = queryTable;
            self.secondField = queryField;
            break;
        }
        default:
            break;
    }
    [self updateSaveButtonState];
}

- (void)viewController:(UIViewController *)viewController addLinkJoinType:(MNSLinkType)result {
    [self setJoinType:result];
    [self.navigationController popToViewController: self animated: YES];
}

#pragma mark - Helper functions

- (void)setJoinType:(MNSLinkType)type {
    NSString *linkName = [RptqQueryLinks newLocalizedNameForLinkType:type];
    NSString *text = linkName.lowercaseString;
    self.tableViewCellJoinType.detailTextLabel.text = text;
    self.linkType = type;
}

- (BOOL)firstFieldSet {
    return self.firstField != nil;
}

- (BOOL)secondFieldSet {
    return self.secondField != nil && [self.firstField isEqual:self.secondField] == NO;
}

- (void)updateRightLabelState {

    BOOL enabled = [self firstFieldSet];
    self.tableViewCellTableFieldTwo.userInteractionEnabled = enabled;
    self.tableViewCellTableFieldTwo.textLabel.enabled = enabled;
    self.tableViewCellTableFieldTwo.detailTextLabel.enabled = enabled;
    self.labelRightField.enabled = enabled;
    
    UIColor *darkTextColor = enabled ? [UIColor blackColor] : [UIColor darkTextColor];
    self.labelRightField.textColor = darkTextColor;
}

- (void)updateSaveButtonState {
    BOOL enabled = [self firstFieldSet] && self.secondField;
    self.navigationItem.rightBarButtonItem.enabled = enabled;
}

@end
