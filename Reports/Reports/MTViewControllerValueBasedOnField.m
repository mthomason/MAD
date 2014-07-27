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
#import "UIDevice+Hack.h"

@interface MTViewControllerValueBasedOnField ()
    <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableViewMain;
@property (nonatomic, weak) IBOutlet UIView *pickerViewBackground;
@property (nonatomic, weak) IBOutlet UIPickerView *pickerView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) MTCellEnterText *tableViewCellEnterText;
@property (nonatomic, strong) NSArray *pickerData;
@property (nonatomic, strong) NSDateFormatter *longStyleDateFormatter;

@property (nonatomic, strong) MTQuery *querySampleDataField;
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver: self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    [defaultCenter addObserver: self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    
    [self loadPickerView];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [[self enterStringDelegate] enterStringDidFinishWithString:[[self textField] text]];
}

- (void)keyboardDidHide:(id)sender {
    if ([UIDevice isPad]) {
        [self done:sender];
    }
}

- (void)keyboardDidShow:(NSNotification *)sender {
    if ([UIDevice isPad] == NO) {

        NSDictionary *userInfo = [sender userInfo];
        //NSValue *keyboardFrameBeginUserInfoKey = userInfo[UIKeyboardFrameBeginUserInfoKey];
        NSValue *keyboardFrameEndUserInfoKey = userInfo[UIKeyboardFrameEndUserInfoKey];
        NSNumber *keyboardAnimationDurationUserInfoKey = userInfo[UIKeyboardAnimationDurationUserInfoKey];
        NSTimeInterval duration = [keyboardAnimationDurationUserInfoKey longLongValue];
        NSNumber *keyboardAnimationCurveUserInfoKey = userInfo[UIKeyboardAnimationCurveUserInfoKey];
        //CGRect keyboardFrameBegin = [keyboardFrameBeginUserInfoKey CGRectValue];
        CGRect keyboardFrameEnd = [keyboardFrameEndUserInfoKey CGRectValue];
        CGFloat pickerViewFrameY = keyboardFrameEnd.origin.y - self.pickerView.frame.size.height;
        CGRect pickerViewFrameEnd = CGRectMake(keyboardFrameEnd.origin.x, pickerViewFrameY, self.pickerView.frame.size.width, self.pickerView.frame.size.height);
        __weak MTViewControllerValueBasedOnField *weakself = self;
        UIViewAnimationOptions options;
        switch ([keyboardAnimationCurveUserInfoKey integerValue]) {
            case UIViewAnimationCurveEaseInOut:
                options = UIViewAnimationOptionCurveEaseInOut;
                break;
            case UIViewAnimationCurveEaseIn:
                options = UIViewAnimationOptionCurveEaseIn;
                break;
            case UIViewAnimationCurveEaseOut:
                options = UIViewAnimationOptionCurveEaseOut;
                break;
            case UIViewAnimationCurveLinear:
                options = UIViewAnimationOptionCurveLinear;
                break;
            default:
                options = UIViewAnimationOptionCurveLinear;
                break;
        }
        [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
            [[weakself pickerView] setFrame:pickerViewFrameEnd];
        } completion:^(BOOL finished) {
            
        }];

        
    }
}

#pragma mark - View lifecycle

- (void)loadPickerView {

    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    NSManagedObjectContext *objectContext = [[reportDocument activeDocument] managedObjectContext];
    RptqDatabaseSchemaField *field = [RptqDatabaseSchemaField managedObjectForObjectID: [self schemaFieldObjectId]
                                                               andManagedObjectContext: objectContext];
    
    MTQuery *querySampleDataField = [[MTQuery alloc] initWithQueryType:MTQueryTypeSampleDataField object:field];

    [self setQuerySampleDataField:querySampleDataField];
    
    __weak MTViewControllerValueBasedOnField *weakself2 = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [querySampleDataField performQuery:^(BOOL success, NSError *error) {
            if (success) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    MTDataTable *dt = [[[querySampleDataField database] delegate] dataTableForQuery:querySampleDataField];
                    [weakself2 setDataTable:dt];
                    NSArray *allObjects = [[weakself2 dataTable] allObjects];
                    [weakself2 setPickerData:allObjects];
                    [[weakself2 pickerView] reloadAllComponents];
                    
                    [[weakself2 pickerView] setNeedsDisplay];
                    
                    [[weakself2 pickerView] selectRow:0 inComponent:0 animated:NO];
                    [weakself2 pickerView:[weakself2 pickerView] didSelectRow:0 inComponent:0];
                });
                
                
            } else {
                [error presentErrorToUser];
            }
        }];
    });
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
