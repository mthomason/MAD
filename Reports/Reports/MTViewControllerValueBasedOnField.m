//
//  MTViewControllerValueBasedOnField.m
//  Reports
//
//  Created by Michael Thomason on 5/16/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTViewControllerValueBasedOnField.h"

@interface MTViewControllerValueBasedOnField ()

@property (nonatomic, retain) IBOutlet UITableView *tableViewMain;
@property (nonatomic, retain) IBOutlet UIView *pickerViewBackground;

@property (nonatomic, retain) IBOutlet NSLayoutConstraint *tableViewHeightConstraint;

@property (nonatomic, retain) UITextField *textField;
@property (nonatomic, retain) UIPickerView *pickerView;

@property (nonatomic, retain) NSArray *pickerData;

@property (nonatomic, retain) NSDateFormatter *longStyleDateFormatter;

@end

@implementation MTViewControllerValueBasedOnField

- (void)dealloc {
    [_pickerData release];
    [_textField release];
    [_pickerView release];
    [_pickerViewBackground release];
    [_tableViewMain release];
    [_tableViewHeightConstraint release];
    [_longStyleDateFormatter release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        NSDateFormatter *longStyleDateFormatter = [[NSDateFormatter alloc] init];
        [longStyleDateFormatter setDateStyle:NSDateFormatterFullStyle];
        [longStyleDateFormatter setTimeStyle:NSDateFormatterLongStyle];
        [longStyleDateFormatter setLocale:[NSLocale currentLocale]];
        [self setLongStyleDateFormatter:longStyleDateFormatter];
        [longStyleDateFormatter release];
        
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [[self enterStringDelegate] enterStringDidFinishWithString:[[self textField] text]];
}

- (void)keyboardDidHide:(id)sender {
    [self done:sender];
}

- (void)textFieldDidEndOnExit:(id)sender {
    [self done:sender];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    static NSString *MTTableViewCellTextFieldIdentifier = @"MTTableViewCellTextFieldIdentifier";

    [[self tableViewMain] registerClass:[UITableViewCell class] forCellReuseIdentifier:MTTableViewCellTextFieldIdentifier];
    
    NSLayoutConstraint *layoutConstraintTableViewHeight = [NSLayoutConstraint constraintWithItem: [self tableViewMain] attribute: NSLayoutAttributeBottom relatedBy: NSLayoutRelationEqual toItem: [self pickerView] attribute: NSLayoutAttributeTop multiplier: 0.0000f constant: 0.0000f];
    [[self tableViewMain] addConstraint:layoutConstraintTableViewHeight];
    
    UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:[[self pickerViewBackground] frame]];
    [pickerView setDelegate:self];
    [pickerView setDataSource:self];
    [pickerView setShowsSelectionIndicator:YES];
    [[self pickerView] setFrame:[[self pickerViewBackground] bounds]];
    [[self pickerViewBackground] addSubview:pickerView];
    [self setPickerView:pickerView];
    [pickerView release];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    dispatch_async(queuePriorityBackground, ^{
        
        NSManagedObjectContext *objectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
        RptqDatabaseSchemaField *field = [RptqDatabaseSchemaField getFieldForObjectID: [self schemaFieldObjectId]
                                                                    fromObjectContext: objectContext];
        
        RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: objectContext];
        RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
        MTDatabase *mnsDatabase = [MTDatabase databaseForRptqDatabase: database];
        [mnsDatabase sampleDataForSchemaField:field completion:^(BOOL success, NSError *error, NSArray *resultStrings) {
            
            if (success) {
                [resultStrings retain];
                [self setPickerData:resultStrings];
                [resultStrings release];
                [[self pickerView] reloadAllComponents];
            } else {
                [error presentErrorToUser];
            }
            
        }];
        
    });

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    CGSize backgroundSize = [[self pickerViewBackground] bounds].size;
    [[self pickerView] setFrame:CGRectMake(CGPointZero.x, CGPointZero.y, backgroundSize.width, backgroundSize.height)];
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];

    [[self textField] setText:[self pickerView: [self pickerView]
                                   titleForRow: 0
                                  forComponent: 0]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
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

//- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component {

//}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString *result = nil;
    NSDictionary *pickerData = [[self pickerData] objectAtIndex:row];
    id resultObject = [[pickerData allValues] lastObject];
    if ([resultObject isKindOfClass:[NSDateComponents class]]) {
        NSDateComponents *resultDate = resultObject;
        NSCalendar *localCalendar = [NSCalendar autoupdatingCurrentCalendar];
        NSDate *newDate = [localCalendar dateFromComponents:resultDate];
        result = [[self longStyleDateFormatter] stringFromDate:newDate];        
    } else if ([resultObject isKindOfClass:[NSString class]]) {
        result = [[resultObject retain] autorelease];
    } else if ([resultObject isKindOfClass:[NSNumber class]]) {
        result = [[[(NSNumber *)resultObject stringValue] retain] autorelease];
    } else if (resultObject == nil) {
        result = @"NULL";
    } else {
        result = @"";
    }
    return result;
}


- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    [[self textField] setText:[self pickerView:pickerView titleForRow:row forComponent:component]];
}

//- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    
//}

//- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    
//}

//- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    
//}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *MTTableViewCellTextFieldIdentifier = @"MTTableViewCellTextFieldIdentifier";
    UITableViewCell *result = [tableView dequeueReusableCellWithIdentifier: MTTableViewCellTextFieldIdentifier];
    
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(20.0000f, 6.0000f, 280.0000f, 31.0000f)];
    [textField addTarget:self action:@selector(textFieldDidEndOnExit:) forControlEvents:UIControlEventEditingDidEndOnExit];
    [textField setBorderStyle:UITextBorderStyleBezel];
    [[result contentView] addSubview:textField];
    [self setTextField:textField];
    [textField release];
    return result;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
