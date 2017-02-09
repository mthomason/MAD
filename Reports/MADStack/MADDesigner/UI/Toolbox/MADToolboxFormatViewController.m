//
//  MTReportDesignerDocumentObjectFormat.m
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADToolboxFormatViewController.h"
#import <UIKit/UIStepper.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UIFont.h>
#import <UIKit/UILabel.h>
#import <UIKit/NSAttributedString.h>

#import <CoreData/NSManagedObject.h>
#import <CoreData/NSManagedObjectContext.h>

#import <MADFoundation/MADDataType.h>

#import <MAD/MADCurrencyFormatter.h>

#import <MAD/MADocument.h>
#import <MAD/MTDatabase.h>
#import <MAD/MADDatabaseField.h>
#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqDocumentElement+Extras.h>
#import <MAD/RptqDocumentElementLabelDataField.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqQueryField.h>

#import "MTToolboxViewControllerProtocol.h"

@interface MADToolboxFormatViewController ()
    <UITableViewDelegate, MTToolboxViewControllerProtocol>

@property (nonatomic, strong) NSSet *userSelectedObjectIDs;

@property (nonatomic, strong) IBOutlet UITableViewCell *tableViewCellDecimals;
@property (nonatomic, strong) IBOutlet UITableViewCell *tableViewCellCurrency;
@property (nonatomic, strong) IBOutlet UITableViewCell *tableViewCellCurrencyLocation;

@property (strong, nonatomic) IBOutlet UIStepper *stepperNumberOfDecimals;
@property (strong, nonatomic) IBOutlet UILabel *labelNumberOfDecimals;

@property (nonatomic, strong) IBOutletCollection(UIView) NSArray *viewsToDisableNumeric;
@property (nonatomic, strong) IBOutletCollection(UIControl) NSArray *controlsToDisableNumeric;

@property (nonatomic, assign) BOOL completedInitalLayout;

@end

@implementation MADToolboxFormatViewController

#pragma mark -
#pragma mark Table View Delegate Protocol


#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.completedInitalLayout = NO;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length,
                                                   CGSizeZero.width,
                                                   self.bottomLayoutGuide.length,
                                                   CGSizeZero.width);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(self.topLayoutGuide.length,
                                                            CGSizeZero.width,
                                                            self.bottomLayoutGuide.length,
                                                            CGSizeZero.width);
    if (self.completedInitalLayout == NO) {
        [self.tableView setContentOffset:CGPointMake(CGPointZero.x, -self.topLayoutGuide.length) animated:NO];
        self.completedInitalLayout = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden: NO animated: animated];
    [self updateDisplay];
    if (self.clearsBackground) {
        self.tableView.backgroundView = nil;
    }
}

- (void)setSelectedDocumentObjects:(NSSet *)objectIds {
    
    BOOL numericTypeInSet = NO;
    NSMutableSet *keepers = [[NSMutableSet alloc] init];
    
    for (NSManagedObjectID *objectId in objectIds) {

        RptqDocumentElementLabelDataField *documentObject = [self.document.managedObjectContext objectWithID:objectId];
        MADDataType dataType = documentObject.referencesQueryField.databaseSchemaField.dataType;
        BOOL isNumeric = [MADDatabaseField isNumeric:dataType];
        if (isNumeric) {
            numericTypeInSet = YES;
            [keepers addObject:objectId];
            break;
        }
    }
    
    self.userSelectedObjectIDs = keepers;
    
    for (UIView *view in self.viewsToDisableNumeric) {
        view.userInteractionEnabled = numericTypeInSet;
        if ([view isKindOfClass:[UIControl class]]) {
            ((UIControl *)view).enabled = numericTypeInSet;
        }
    }
    
    [self updateDisplay];
}


- (void)updateDisplay {
    
    if (self.userSelectedObjectIDs.count == 0) {

        self.tableViewCellCurrency.selectionStyle = UITableViewCellSelectionStyleNone;
        self.tableViewCellCurrency.accessoryType = UITableViewCellAccessoryNone;
        self.labelNumberOfDecimals.text = NSLocalizedString(@"Decimals", "Decimals");

    } else {
    
        (self.tableViewCellCurrency).selectionStyle = UITableViewCellSelectionStyleBlue;
        
        UITableViewCellAccessoryType accessoryType = UITableViewCellAccessoryNone;

        MADocument *document = _document;
        for (NSManagedObjectID *objectId in self.userSelectedObjectIDs) {
        
            RptqDocumentElement *documentObject = [document.managedObjectContext objectWithID:objectId];
            MADCurrencyFormatter *currencyFormatter = (MADCurrencyFormatter *)documentObject.numericFormat;
            if (currencyFormatter.enabled) {
                accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }

        (self.tableViewCellCurrency).accessoryType = accessoryType;
        
        if ((self.userSelectedObjectIDs).count == 1) {

            NSManagedObjectID *objectId = [self.userSelectedObjectIDs anyObject];
            RptqDocumentElement *documentObject = [document.managedObjectContext objectWithID:objectId];
            MADCurrencyFormatter *currencyFormatter = (MADCurrencyFormatter *)documentObject.numericFormat;
            (self.labelNumberOfDecimals).attributedText = [self decimalsStringForNumberOfDecimals:currencyFormatter.decimalCount];
            (self.stepperNumberOfDecimals).value = currencyFormatter.decimalCount;

        } else {
            
            BOOL allTheSame = NO;
            NSInteger lastInteger = 0;
            NSUInteger counter = 0;
            for (NSManagedObjectID *objectId in self.userSelectedObjectIDs) {
                RptqDocumentElement *documentObject = [document.managedObjectContext objectWithID:objectId];
                MADCurrencyFormatter *currencyFormatter = (MADCurrencyFormatter *)documentObject.numericFormat;
                if (counter > 0) {
                    if (lastInteger == currencyFormatter.decimalCount && allTheSame) {
                        allTheSame = YES;
                    } else {
                        allTheSame = NO;
                    }
                    
                    lastInteger = currencyFormatter.decimalCount;
                }
                counter++;
            }
            if (allTheSame) {
                self.labelNumberOfDecimals.attributedText = [self decimalsStringForNumberOfDecimals:lastInteger];
            } else {
                NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@""];
                self.labelNumberOfDecimals.attributedText = attributedString;
            }
            self.stepperNumberOfDecimals.value = lastInteger;
        }

    }
}
#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)emptySelector:(id)sender {}

- (IBAction)controlValueChanged:(id)sender {
    id valueThatChanged = nil;
    
    if ([sender isEqual:self.stepperNumberOfDecimals]) {
        valueThatChanged = @((self.stepperNumberOfDecimals).value);
        (self.labelNumberOfDecimals).attributedText =
            [self decimalsStringForNumberOfDecimals:(NSInteger)[valueThatChanged floatValue]];
        
        MADCurrencyFormatter *currencyFormatter;
        RptqDocumentElement *documentObject;
        NSManagedObjectID *objectID;
        for (objectID in self.userSelectedObjectIDs) {
            documentObject = [self.document.managedObjectContext objectWithID:objectID];
            currencyFormatter = (MADCurrencyFormatter *)documentObject.numericFormat;
            currencyFormatter.decimalCount = [valueThatChanged integerValue];
            documentObject.numericFormat = currencyFormatter;
            [documentObject.managedObjectContext save:nil];
        }
    }
    
}

- (NSAttributedString *)decimalsStringForNumberOfDecimals:(NSInteger)numberOfDecimals {

    UIFont *boldFont = [UIFont boldSystemFontOfSize:self.labelNumberOfDecimals.font.pointSize];
    UIFont *systemFont = [UIFont systemFontOfSize:self.labelNumberOfDecimals.font.pointSize];
    NSDictionary *boldAttributes = @{NSFontAttributeName : boldFont};
    NSDictionary *normalAttributes = @{NSFontAttributeName : systemFont};
    
    NSString *decimals = NSLocalizedString(@"Decimals", "Decimals");
    NSMutableAttributedString *localizedAttributedMessage = [[NSMutableAttributedString alloc] initWithString: decimals attributes: boldAttributes];
    NSString *pointsString;
    if (numberOfDecimals == -1) {
        pointsString = @"-";
    } else {
        pointsString = [@" " stringByAppendingFormat:@"%ld", (long)numberOfDecimals];
    }
    NSAttributedString *messageSuffix = [[NSAttributedString alloc] initWithString:pointsString attributes:normalAttributes];
    [localizedAttributedMessage appendAttributedString:messageSuffix];
    (self.labelNumberOfDecimals).attributedText = localizedAttributedMessage;
    return localizedAttributedMessage;
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath { }

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 1 && indexPath.section == 0) {
        
        MADCurrencyFormatter *currencyFormatter;
        NSManagedObjectID *objectID;
        UITableViewCellAccessoryType newAccessory;
        for (objectID in self.userSelectedObjectIDs) {
            RptqDocumentElement *documentObject = [self.document.managedObjectContext objectWithID:objectID];
            currencyFormatter = (MADCurrencyFormatter *)documentObject.numericFormat;
            currencyFormatter.enabled = !currencyFormatter.enabled;
            documentObject.numericFormat = currencyFormatter;
            newAccessory = currencyFormatter.enabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            (self.tableViewCellCurrency).accessoryType = newAccessory;
            [documentObject.managedObjectContext save:nil];
        }
    }
}

@end
