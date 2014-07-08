//
//  MTViewControllerValueBasedOnField.m
//  Reports
//
//  Created by Michael Thomason on 5/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTViewControllerValueBasedOnField.h"
#import "MTCellEnterText.h"
#import "AppDelegate.h"
#import "MTApplicationInstance.h"
#import <CoreData/CoreData.h>
#import "RptqDatabaseSchemaField.h"
#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "MTQuery.h"
#import "NSError+UserInterface.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "MTDataTable.h"

@interface MTViewControllerValueBasedOnField ()
    <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableViewMain;
@property (nonatomic, weak) IBOutlet UIView *pickerViewBackground;
@property (nonatomic, weak) IBOutlet UIPickerView *pickerView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) MTCellEnterText *tableViewCellEnterText;
@property (nonatomic, strong) NSArray *pickerData;
@property (nonatomic, strong) NSDateFormatter *longStyleDateFormatter;
@property (nonatomic, strong) MTDataTable *dataTable;

@end

@implementation MTViewControllerValueBasedOnField

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        NSDateFormatter *longStyleDateFormatter = [[NSDateFormatter alloc] init];
        [longStyleDateFormatter setDateStyle:NSDateFormatterFullStyle];
        [longStyleDateFormatter setTimeStyle:NSDateFormatterLongStyle];
        [longStyleDateFormatter setLocale:[NSLocale currentLocale]];
        [self setLongStyleDateFormatter:longStyleDateFormatter];
        
    }
    return self;
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [[self enterStringDelegate] enterStringDidFinishWithString:[[self textField] text]];
}

- (void)keyboardDidHide:(id)sender {
    [self done:sender];
}

#pragma mark - View lifecycle

- (void)loadPickerView {
    //__weak MTViewControllerValueBasedOnField *weakself = self;
    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    NSManagedObjectContext *objectContext = [[reportDocument activeDocument] managedObjectContext];
    RptqDatabaseSchemaField *field = [RptqDatabaseSchemaField getFieldForObjectID: [self schemaFieldObjectId]
                                                                fromObjectContext: objectContext];
    
    MTQuery *querySampleDataField = [[MTQuery alloc] initWithQueryType:MTQueryTypeSampleDataField object:field];
    
    MTDataTable *dataTable = [MTDataTable newDataTableForIdentifier:[[[field objectID] URIRepresentation] absoluteString]];
    [self setDataTable:dataTable];
    
    __weak MTViewControllerValueBasedOnField *weakself2 = self;
    [querySampleDataField performQuery:^(BOOL success, NSError *error) {
        if (success) {
            
            //__weak MTViewControllerValueBasedOnField *weakself3 = weakself2;
            
            [weakself2 setPickerData:[weakself2 dataTable]];
            [[weakself2 pickerView] reloadAllComponents];
            
            [[weakself2 pickerView] setNeedsDisplay];
            [[weakself2 pickerView] selectRow:0 inComponent:0 animated:NO];
            
            
        } else {
            [error presentErrorToUser];
        }
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    [[self textField] setText:[self pickerView: [self pickerView]
                                   titleForRow: 0
                                  forComponent: 0]];
    
    [self loadPickerView];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (CGSize)preferredContentSize {
    return CGSizeMake(320.0000f, 420.0000f);
}

#pragma mark - Picker View Data Source
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    NSUInteger result = 0;
    if ([self pickerData] != nil) {
        result = [[self pickerData] count];
    }
    return result;
}

#pragma mark - Picker View Delegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString *result = nil;
    if (row < [[self pickerData] count]) {
        NSDictionary *pickerData = [[self pickerData] objectAtIndex:row];
        id resultObject = [[pickerData allValues] lastObject];
        if ([resultObject isKindOfClass:[NSDateComponents class]]) {
            NSDateComponents *resultDate = resultObject;
            NSCalendar *localCalendar = [NSCalendar autoupdatingCurrentCalendar];
            NSDate *newDate = [localCalendar dateFromComponents:resultDate];
            result = [[self longStyleDateFormatter] stringFromDate:newDate];
        } else if ([resultObject isKindOfClass:[NSString class]]) {
            result = [NSString stringWithString: resultObject];
        } else if ([resultObject isKindOfClass:[NSNumber class]]) {
            result = [(NSNumber *)resultObject stringValue];
        } else if (resultObject == nil) {
            result = @"NULL";
        } else {
            result = @"";
        }
    } else {
        result = @"";
    }
    return result;
}


- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    [[self textField] setText:[self pickerView:pickerView titleForRow:row forComponent:component]];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *MTTableViewCellTextFieldIdentifier = @"MTTableViewCellPredicateEnterValueString";
    
    MTCellEnterText *result = [tableView dequeueReusableCellWithIdentifier: MTTableViewCellTextFieldIdentifier];
    
    [[result textField] setReturnKeyType:UIReturnKeyDone];
    //[[result textField] addTarget:self action:@selector(didEndEditing:) forControlEvents:UIControlEventEditingDidEnd];
    [[result textField] setDelegate:self];
    
    [self setTextField:[result textField]];
    return result;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
