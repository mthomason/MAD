//
//  MADToolboxFormatViewController.m
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADToolboxFormatViewController.h"

#import <CoreData/NSManagedObject.h>
#import <CoreData/NSManagedObjectContext.h>

#import <UIKit/UIStepper.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UIFont.h>
#import <UIKit/UILabel.h>
#import <UIKit/NSAttributedString.h>

#import <MADFoundation/MADDataType.h>

#import <MAD/RptqAlignment.h>

#import <MAD/RptqNumericFormat.h>

#import <MAD/MADocument.h>
#import <MAD/MTDatabase.h>
#import <MAD/MADDatabaseField.h>
#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqDocumentElement+Extras.h>
#import <MAD/RptqDocumentElementLabelDataField.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqNumericFormat.h>

#import "MADToolboxControllerProtocol.h"

@interface MADToolboxFormatViewController ()
    <UITableViewDelegate, MADToolboxControllerProtocol>

@property (nonatomic, strong) NSSet <NSNumber *> *userSelectedObjectIDs;

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

- (void)setSelectedDocumentObjects:(NSSet <NSNumber *> *)objectIDs {
    
    BOOL numericTypeInSet = NO;
    NSMutableSet <NSNumber *> *keepers = [[NSMutableSet alloc] init];
    
    NSNumber *objectID;
    RptqDocumentElementLabelDataField *documentObject;
    for (objectID in objectIDs) {

        documentObject = [RptqDocumentElementLabelDataField newDocumentElementWithIdentifier: objectID.longLongValue
                                                                           fromObjectContext: _document.managedObjectContext];
        MADDataType dataType = documentObject.referencesQueryField.databaseSchemaField.dataType;
        BOOL isNumeric = [MADDatabaseField isNumeric:dataType];
        if (isNumeric) {
            numericTypeInSet = YES;
            [keepers addObject:objectID];
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
        NSNumber *identifier;
        NSSet <NSNumber *> *userSelectedObjectIDs;
        RptqDocumentElement *element;
        
        userSelectedObjectIDs = self.userSelectedObjectIDs;
        for (identifier in userSelectedObjectIDs) {
        
            element = [RptqDocumentElement newDocumentElementWithIdentifier: identifier.longLongValue
                                                          fromObjectContext: document.managedObjectContext];
            if (element.numericFormat.enabled) {
                accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }

        (self.tableViewCellCurrency).accessoryType = accessoryType;
        
        if ((self.userSelectedObjectIDs).count == 1) {
            identifier = userSelectedObjectIDs.anyObject;
            element = [RptqDocumentElement newDocumentElementWithIdentifier: identifier.longLongValue
                                                          fromObjectContext: document.managedObjectContext];
            (self.labelNumberOfDecimals).attributedText = [self decimalsStringForNumberOfDecimals:element.numericFormat.decimalCount];
            (self.stepperNumberOfDecimals).value = element.numericFormat.decimalCount;

        } else {
            
            BOOL allTheSame = NO;
            NSInteger lastInteger = 0;
            NSUInteger counter = 0;
            for (identifier in self.userSelectedObjectIDs) {
                element = [RptqDocumentElement newDocumentElementWithIdentifier: identifier.longLongValue
                                                              fromObjectContext: document.managedObjectContext];
                if (counter > 0) {
#warning Don't think BOOL allTheSame ever becomes "YES"
                    if (lastInteger == element.numericFormat.decimalCount && allTheSame) {  /// WTF: How does this work?  Don't think it ever gets in here!
                        allTheSame = YES;
                    } else {
                        allTheSame = NO;
                    }
                    
                    lastInteger = element.numericFormat.decimalCount;
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
        valueThatChanged = [[NSNumber alloc] initWithDouble:(self.stepperNumberOfDecimals).value];
        (self.labelNumberOfDecimals).attributedText =
            [self decimalsStringForNumberOfDecimals:(NSInteger)[valueThatChanged floatValue]];
        
        RptqDocumentElement *documentObject;
        NSNumber *identifier;
        NSManagedObjectContext *context = self.document.managedObjectContext;
        for (identifier in self.userSelectedObjectIDs) {
            documentObject = [RptqDocumentElement newDocumentElementWithIdentifier: identifier.longLongValue
                                                                 fromObjectContext: context];
            documentObject.numericFormat.decimalCount = [valueThatChanged integerValue];
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
    NSMutableAttributedString *localizedAttributedMessage;
    localizedAttributedMessage = [[NSMutableAttributedString alloc] initWithString: decimals
                                                                        attributes: boldAttributes];
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath { }

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 1 && indexPath.section == 0) {
        
        NSNumber *identifier;
        UITableViewCellAccessoryType newAccessory;
        RptqDocumentElement *documentObject;
        NSManagedObjectContext *context = self.document.managedObjectContext;
        for (identifier in self.userSelectedObjectIDs) {
            documentObject = [RptqDocumentElement newDocumentElementWithIdentifier: identifier.longLongValue
                                                                 fromObjectContext: context];
            documentObject.numericFormat.enabled = !documentObject.numericFormat.enabled;
            newAccessory = documentObject.numericFormat.enabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            (self.tableViewCellCurrency).accessoryType = newAccessory;
            [documentObject.managedObjectContext save:nil];
        }
    }
}

@end
