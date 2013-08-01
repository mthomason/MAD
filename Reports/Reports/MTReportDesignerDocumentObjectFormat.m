//
//  MTReportDesignerDocumentObjectFormat.m
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTReportDesignerDocumentObjectFormat.h"

@interface MTReportDesignerDocumentObjectFormat ()

@property (nonatomic, retain) NSSet *userSelectedObjectIds;

@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellDecimals;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellCurrency;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellCurrencyLocation;

@property (retain, nonatomic) IBOutlet UIStepper *stepperNumberOfDecimals;
@property (retain, nonatomic) IBOutlet UILabel *labelNumberOfDecimals;

@property (nonatomic, retain) IBOutletCollection(UIView) NSArray *viewsToDisableNumeric;
@property (nonatomic, retain) IBOutletCollection(UIControl) NSArray *controlsToDisableNumeric;


@end

@implementation MTReportDesignerDocumentObjectFormat

- (void)dealloc {
    [_userSelectedObjectIds release];
    [_tableViewCellDecimals release];
    [_tableViewCellCurrency release];
    [_tableViewCellCurrencyLocation release];
    [_viewsToDisableNumeric release];
    [_stepperNumberOfDecimals release];
    [_labelNumberOfDecimals release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
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

- (void)setSelectedDocumentObjects:(NSSet *)objectIds {
    
    BOOL numericTypeInSet = NO;
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];

    NSMutableSet *keepers = [[NSMutableSet alloc] init];
    for (NSManagedObjectID *objectId in objectIds) {

        RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];
        MTDataType dataType = [[[[[documentObject isLabelDataField] referencesQueryField] databaseSchemaField] dataType] integerValue];
        BOOL isNumeric = [MTDatabaseField isNumeric:dataType];
        if (isNumeric) {
            numericTypeInSet = YES;
            [keepers addObject:objectId];
            break;
        }
    }
    [self setUserSelectedObjectIds:keepers];
    [keepers release];
    
    for (UIView *view in [self viewsToDisableNumeric]) {
        [view setUserInteractionEnabled:numericTypeInSet];
        if ([view isKindOfClass:[UIControl class]]) {
            [(UIControl *)view setEnabled:numericTypeInSet];
        }
    }
}


- (void)updateDisplay {
    if ([[self userSelectedObjectIds] count] == 0) {
        
    } else {
        
    }
}
#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)emptySelector:(id)sender {}

- (IBAction)controlValueChanged:(id)sender {
    MTReportDocument *activeDocument = [[MTActiveDocument sharedDocument] activeDocument];

    SEL valueChangedAction = @selector(emptySelector:);
    id valueThatChanged = nil;
    
    if ([sender isEqual:[self stepperNumberOfDecimals]]) {
        valueChangedAction = @selector(setFormatNumericDecimals:);
        valueThatChanged = @([[self stepperNumberOfDecimals] value]);
        [[self labelNumberOfDecimals] setAttributedText: [self decimalsStringForNumberOfDecimals:[valueThatChanged floatValue]]];
        
    }
    
    for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
        RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:[activeDocument managedObjectContext]];
        [documentObject performSelector:valueChangedAction withObject:valueThatChanged];
        [[documentObject managedObjectContext] save:nil];
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
    NSString *pointsString = [@" " stringByAppendingFormat:@"%d", numberOfDecimals];
    NSAttributedString *messageSuffix = [[NSAttributedString alloc] initWithString:pointsString attributes:normalAttributes];
    [localizedAttributedMessage appendAttributedString:messageSuffix];
    [messageSuffix release];
    [[self labelNumberOfDecimals] setAttributedText:localizedAttributedMessage];
    return [localizedAttributedMessage autorelease];
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
}

@end
