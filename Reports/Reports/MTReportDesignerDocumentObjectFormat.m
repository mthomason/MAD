//
//  MTReportDesignerDocumentObjectFormat.m
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTReportDesignerDocumentObjectFormat.h"
#import "UIDevice+Hack.h"
#import "AppDelegate.h"
#import "MTApplicationInstance.h"
#import "MAReportDocument.h"
#import <CoreData/CoreData.h>
#import "MTToolboxViewControllerProtocol.h"
#import "RptqDocumentObject+Extras.h"
#import "RptqQueryField.h"
#import "RptqDocumentObjectLabelDataField.h"
#import "RptqDatabaseSchemaField.h"

@interface MTReportDesignerDocumentObjectFormat ()
    <UITableViewDelegate, MTToolboxViewControllerProtocol>

@property (nonatomic, strong) NSSet *userSelectedObjectIds;

@property (nonatomic, strong) IBOutlet UITableViewCell *tableViewCellDecimals;
@property (nonatomic, strong) IBOutlet UITableViewCell *tableViewCellCurrency;
@property (nonatomic, strong) IBOutlet UITableViewCell *tableViewCellCurrencyLocation;

@property (strong, nonatomic) IBOutlet UIStepper *stepperNumberOfDecimals;
@property (strong, nonatomic) IBOutlet UILabel *labelNumberOfDecimals;

@property (nonatomic, strong) IBOutletCollection(UIView) NSArray *viewsToDisableNumeric;
@property (nonatomic, strong) IBOutletCollection(UIControl) NSArray *controlsToDisableNumeric;


@end

@implementation MTReportDesignerDocumentObjectFormat


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Table View Delegate Protocol


#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateDisplay];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if ([UIDevice isPad] == NO) {
        //CGFloat insetOffset = [[[self tabBarController] tabBar] frame].size.height;
        UIEdgeInsets tableInset = UIEdgeInsetsMake(0.0000f, 0.0000f, 50.0000f, 0.0000f);
        [[self tableView] setContentInset:tableInset];
        [[self tableView] setScrollIndicatorInsets:tableInset];
    }
}

- (void)setSelectedDocumentObjects:(NSSet *)objectIds {
    
    BOOL numericTypeInSet = NO;
    NSMutableSet *keepers = [[NSMutableSet alloc] init];
    for (NSManagedObjectID *objectId in objectIds) {

        RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId
                                                                      managedObjectContext: self.document.managedObjectContext];
        MTDataType dataType = [[[[[documentObject isLabelDataField] referencesQueryField] databaseSchemaField] dataType] integerValue];
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
    if ([[self userSelectedObjectIds] count] == 0) {
        [[self tableViewCellCurrency] setSelectionStyle:UITableViewCellSelectionStyleNone];
        [[self tableViewCellCurrency] setAccessoryType:UITableViewCellAccessoryNone];
        [[self labelNumberOfDecimals] setText:NSLocalizedString(@"Decimals", "Decimals")];
    } else {
        [[self tableViewCellCurrency] setSelectionStyle:UITableViewCellSelectionStyleBlue];
        
        
        UITableViewCellAccessoryType accessoryType = UITableViewCellAccessoryNone;
        for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId
                                                                          managedObjectContext: self.document.managedObjectContext];
            BOOL isCurrency = [[documentObject formatNumericCurrency] boolValue];
            if (isCurrency) {
                accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }

        [[self tableViewCellCurrency] setAccessoryType:accessoryType];
        
        if ([[self userSelectedObjectIds] count] == 1) {
            NSManagedObjectID *objectId = [[self userSelectedObjectIds] anyObject];
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId
                                                                          managedObjectContext: self.document.managedObjectContext];
            NSInteger numberOfDec = [[documentObject formatNumericDecimals] integerValue];
            [[self labelNumberOfDecimals] setAttributedText:[self decimalsStringForNumberOfDecimals:numberOfDec]];
            [[self stepperNumberOfDecimals] setValue:numberOfDec];
        } else {
            
            BOOL allTheSame = NO;
            NSInteger lastInteger = 0;
            NSUInteger counter = 0;
            for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
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
                [[self labelNumberOfDecimals] setAttributedText:[self decimalsStringForNumberOfDecimals:lastInteger]];
            } else {
                NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@""];
                [[self labelNumberOfDecimals] setAttributedText:attributedString];
            }
            [[self stepperNumberOfDecimals] setValue:lastInteger];
        }

    }
}
#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)emptySelector:(id)sender {}

- (IBAction)controlValueChanged:(id)sender {
    
    SEL valueChangedAction = @selector(emptySelector:);
    id valueThatChanged = nil;
    
    if ([sender isEqual:[self stepperNumberOfDecimals]]) {
        valueChangedAction = @selector(setFormatNumericDecimals:);
        valueThatChanged = @([[self stepperNumberOfDecimals] value]);
        [[self labelNumberOfDecimals] setAttributedText: [self decimalsStringForNumberOfDecimals:[valueThatChanged floatValue]]];
        
        for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId
                                                                          managedObjectContext: self.document.managedObjectContext];
            [documentObject setFormatNumericDecimals:valueThatChanged];
            [[documentObject managedObjectContext] save:nil];
        }
    }
    
}

- (NSAttributedString *)decimalsStringForNumberOfDecimals:(NSInteger)numberOfDecimals {
    CGFloat pointSize = [[[self labelNumberOfDecimals] font] pointSize];
    UIFont *boldFont = [UIFont boldSystemFontOfSize:pointSize];
    UIFont *systemFont = [UIFont systemFontOfSize:[[[self labelNumberOfDecimals] font] pointSize]];
    NSDictionary *boldAttributes = @{NSFontAttributeName : boldFont};
    NSDictionary *normalAttributes = @{NSFontAttributeName : systemFont};
    
    NSMutableAttributedString *localizedAttributedMessage = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"Decimals", "Decimals")
                                                                                                   attributes:boldAttributes];
    NSString *pointsString;
    if (numberOfDecimals == -1) {
        pointsString = @"-";
    } else {
        pointsString = [@" " stringByAppendingFormat:@"%ld", (long)numberOfDecimals];
    }
    NSAttributedString *messageSuffix = [[NSAttributedString alloc] initWithString:pointsString attributes:normalAttributes];
    [localizedAttributedMessage appendAttributedString:messageSuffix];
    [[self labelNumberOfDecimals] setAttributedText:localizedAttributedMessage];
    return localizedAttributedMessage;
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 1 && indexPath.section == 0) {
        
        for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID:objectId
                                                                          managedObjectContext:self.document.managedObjectContext];
            BOOL isCurrency = [[documentObject formatNumericCurrency] boolValue];
            BOOL isCurrencyNow = !isCurrency;
            [documentObject setFormatNumericCurrency:@(isCurrencyNow)];
            UITableViewCellAccessoryType newAccessory = isCurrencyNow ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            [[self tableViewCellCurrency] setAccessoryType:newAccessory];
            [[documentObject managedObjectContext] save:nil];
        }
    }
}

@end
