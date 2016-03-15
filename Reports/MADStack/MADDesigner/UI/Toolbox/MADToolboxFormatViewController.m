//
//  MTReportDesignerDocumentObjectFormat.m
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADToolboxFormatViewController.h"

#import "MTToolboxViewControllerProtocol.h"

@interface MADToolboxFormatViewController ()
    <UITableViewDelegate, MTToolboxViewControllerProtocol>

@property (nonatomic, strong) NSSet *userSelectedObjectIds;

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
    self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width, self.bottomLayoutGuide.length, CGSizeZero.width);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width, self.bottomLayoutGuide.length, CGSizeZero.width);
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

        RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId managedObjectContext: self.document.managedObjectContext];
        MTDataType dataType = documentObject.isLabelDataField.referencesQueryField.databaseSchemaField.dataType.integerValue;
        BOOL isNumeric = [MTDatabaseField isNumeric:dataType];
        if (isNumeric) {
            numericTypeInSet = YES;
            [keepers addObject:objectId];
            break;
        }
    }
    
    [self setUserSelectedObjectIds:keepers];
    
    for (UIView *view in [self viewsToDisableNumeric]) {
        [view setUserInteractionEnabled:numericTypeInSet];
        if ([view isKindOfClass:[UIControl class]]) {
            [(UIControl *)view setEnabled:numericTypeInSet];
        }
    }
    
    [self updateDisplay];
}


- (void)updateDisplay {
    
    if (self.userSelectedObjectIds.count == 0) {

        self.tableViewCellCurrency.selectionStyle = UITableViewCellSelectionStyleNone;
        self.tableViewCellCurrency.accessoryType = UITableViewCellAccessoryNone;
        self.labelNumberOfDecimals.text = NSLocalizedString(@"Decimals", "Decimals");

    } else {
    
        [self.tableViewCellCurrency setSelectionStyle:UITableViewCellSelectionStyleBlue];
        
        UITableViewCellAccessoryType accessoryType = UITableViewCellAccessoryNone;

        for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId
                                                                          managedObjectContext: self.document.managedObjectContext];
            
            if (documentObject.formatNumericCurrency.boolValue) {
                accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }

        [self.tableViewCellCurrency setAccessoryType:accessoryType];
        
        if ([self.userSelectedObjectIds count] == 1) {

            NSManagedObjectID *objectId = [self.userSelectedObjectIds anyObject];
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId
                                                                          managedObjectContext: self.document.managedObjectContext];
            NSInteger numberOfDec = [[documentObject formatNumericDecimals] integerValue];
            [self.labelNumberOfDecimals setAttributedText:[self decimalsStringForNumberOfDecimals:numberOfDec]];
            [self.stepperNumberOfDecimals setValue:numberOfDec];

        } else {
            
            BOOL allTheSame = NO;
            NSInteger lastInteger = 0;
            NSUInteger counter = 0;
            for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
                RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId
                                                                              managedObjectContext: self.document.managedObjectContext];
                NSInteger currentInteger = [[documentObject formatNumericDecimals] integerValue];
                if (counter > 0) {
                    if (lastInteger == currentInteger && allTheSame) {
                        allTheSame = YES;
                    } else {
                        allTheSame = NO;
                    }
                    
                    lastInteger = currentInteger;
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
    
    SEL valueChangedAction = @selector(emptySelector:);
    id valueThatChanged = nil;
    
    if ([sender isEqual:self.stepperNumberOfDecimals]) {
        valueChangedAction = @selector(setFormatNumericDecimals:);
        valueThatChanged = @([self.stepperNumberOfDecimals value]);
        [self.labelNumberOfDecimals setAttributedText: [self decimalsStringForNumberOfDecimals:(NSInteger)[valueThatChanged floatValue]]];
        
        for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId managedObjectContext: self.document.managedObjectContext];
            [documentObject setFormatNumericDecimals:valueThatChanged];
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
    [self.labelNumberOfDecimals setAttributedText:localizedAttributedMessage];
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
        
        for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID:objectId
                                                                          managedObjectContext:self.document.managedObjectContext];
            BOOL isCurrency = [documentObject.formatNumericCurrency boolValue];
            BOOL isCurrencyNow = !isCurrency;
            [documentObject setFormatNumericCurrency:@(isCurrencyNow)];
            UITableViewCellAccessoryType newAccessory = isCurrencyNow ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            [self.tableViewCellCurrency setAccessoryType:newAccessory];
            [documentObject.managedObjectContext save:nil];
        }
    }
}

@end
