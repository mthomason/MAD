//
//  MADQueryValueFromFieldController.m
//  Reports
//
//  Created by Michael Thomason on 5/16/13.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryValueFromFieldController.h"
#import "MADQueryValueFromFieldControllerDelegate.h"

#import <CoreData/NSManagedObjectContext.h>

#import <UIKit/UIWindow.h>
#import <UIKit/UITableView.h>
#import <UIKit/UIPickerView.h>

#import <MADFoundation/MADDataTable.h>

#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADDatabaseConnection.h>

#import <MADCocoaExtensions/NSError+Constructors.h>
#import <MADCocoaExtensions/MADAlertController.h>

#import <MADAPI/MADQuery.h>
#import <MAD/MADQuery+Extras.h>
#import <MADFoundation/MADKeyChain.h>
#import <MAD/MADDatabase+Constructor.h>

#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqDatabaseSchemaField+Extras.h>
#import <MAD/RptqDatabaseCredentals+Extras.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDatabase.h>

#import <MAD/MADocument.h>

#import <MADAPI/MADDatabase.h>

#import "MADCellTextInput.h"

@interface MADQueryValueFromFieldController ()
	<UITextFieldDelegate,
		UITableViewDataSource,
		UITableViewDelegate,
		UIPickerViewDataSource,
		UIPickerViewDelegate>

	@property (nonatomic, weak) IBOutlet UITableView *tableViewMain;
	@property (nonatomic, weak) IBOutlet UIView *pickerViewBackground;
	@property (nonatomic, weak) IBOutlet UIPickerView *pickerView;

	@property (nonatomic, weak) IBOutlet UITextField *textField;
	@property (nonatomic, strong) MADCellTextInput *tableViewCellEnterText;
	@property (nonatomic, strong) NSArray *pickerData;
	@property (nonatomic, strong) NSDateFormatter *longStyleDateFormatter;

	@property (nonatomic, strong) MADQuery *querySampleDataField;
	@property (nonatomic, strong) MADDataTable *dataTable;

@end

@implementation MADQueryValueFromFieldController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		
		NSDateFormatter *longStyleDateFormatter = [[NSDateFormatter alloc] init];
		longStyleDateFormatter.dateStyle = NSDateFormatterFullStyle;
		longStyleDateFormatter.timeStyle = NSDateFormatterLongStyle;
		longStyleDateFormatter.locale = [NSLocale currentLocale];
		self.longStyleDateFormatter = longStyleDateFormatter;
		
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
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(keyboardDidHide:)
												 name: UIKeyboardDidHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(keyboardDidShow:)
												 name: UIKeyboardDidShowNotification object:nil];
	
	[self loadPickerView];
	
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
	[self.enterStringDelegate enterStringDidFinishWithString: self.textField.text];
}

- (void)keyboardDidHide:(id)sender {
	if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		[self done:sender];
	}
}

- (void)keyboardDidShow:(NSNotification *)sender {
	if (self.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPad) {

		NSDictionary *userInfo = sender.userInfo;
		//NSValue *keyboardFrameBeginUserInfoKey = userInfo[UIKeyboardFrameBeginUserInfoKey];
		NSValue *keyboardFrameEndUserInfoKey = userInfo[UIKeyboardFrameEndUserInfoKey];
		NSNumber *keyboardAnimationDurationUserInfoKey = userInfo[UIKeyboardAnimationDurationUserInfoKey];
		NSTimeInterval duration = keyboardAnimationDurationUserInfoKey.longLongValue;
		NSNumber *keyboardAnimationCurveUserInfoKey = userInfo[UIKeyboardAnimationCurveUserInfoKey];
		//CGRect keyboardFrameBegin = [keyboardFrameBeginUserInfoKey CGRectValue];
		CGRect keyboardFrameEnd = [keyboardFrameEndUserInfoKey CGRectValue];
		CGFloat pickerViewFrameY = keyboardFrameEnd.origin.y - self.pickerView.frame.size.height;
		CGRect pickerViewFrameEnd = CGRectMake(keyboardFrameEnd.origin.x, pickerViewFrameY, self.pickerView.frame.size.width, self.pickerView.frame.size.height);
		MADQueryValueFromFieldController * __weak weakself = self;
		UIViewAnimationOptions options;
		switch (keyboardAnimationCurveUserInfoKey.integerValue) {
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
			weakself.pickerView.frame = pickerViewFrameEnd;
		} completion:^(BOOL finished) {
			
		}];

		
	}
}

#pragma mark - View lifecycle

- (void)loadPickerView {

	RptqDatabaseSchemaField *schemaField;
	schemaField = [_document.managedObjectContext objectWithID: _schemaFieldObjectId];

	MADQuery <MADQueryDatabaseProtocol> *querySampleDataField;
	querySampleDataField = (MADQuery <MADQueryDatabaseProtocol> *)[[MADQuery alloc] initWithQueryType: MADQueryTypeSampleDataField
																							 object: schemaField];

	self.querySampleDataField = querySampleDataField;
	
	MADQueryValueFromFieldController * __weak weakself2 = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		__strong MADQueryValueFromFieldController *strongself2 = weakself2;
		RptqDatabaseSchemaField *field;
		field = [strongself2.document.managedObjectContext objectWithID: strongself2.schemaFieldObjectId];
		RptqDatabaseCredentals *userCredentals;
		userCredentals = field.inTable.inDatabase.ownedByUser;
		
		MADDatabaseConnection *databaseConnection;
		databaseConnection = [MADDatabaseConnection newDatabaseConnection:userCredentals];
		
		MADDatabase *database;
		database = [MADDatabase newDatabaseWithConnection:databaseConnection];
		if ([strongself2.querySampleDataField conformsToProtocol:@protocol(MADDatabaseResultsProtocol)]) {
			database.delegate = ((NSObject <MADDatabaseResultsProtocol> *)strongself2.querySampleDataField);
		}

		NSError * __autoreleasing error = NULL;
		BOOL success = [database executeQuery:querySampleDataField withError:&error];

		if (success) {
			MADQueryValueFromFieldController * __weak weakself3 = strongself2;
			dispatch_sync(dispatch_get_main_queue(), ^{
				MADQueryValueFromFieldController *strongself5 = weakself3;
				MADDataTable *dt = [(querySampleDataField.database).delegate dataTableForQuery:querySampleDataField];
				strongself5.dataTable = dt;
				
				NSArray *allObjects = [strongself5.dataTable allObjects];
				strongself5.pickerData = allObjects;
				[strongself5.pickerView reloadAllComponents];
				
				[strongself5.pickerView setNeedsDisplay];
				
				[strongself5.pickerView selectRow: 0 inComponent: 0 animated: NO];
				[strongself5 pickerView: strongself5.pickerView didSelectRow: 0 inComponent: 0];
			});
			
			
		} else {
			
			NSString *key = [NSString stringWithString:querySampleDataField.database.databaseConnection.connectionString];
			// FIXME: Comeon with the fucking blocks.
		
			if ([NSThread isMainThread]) {
				UIViewController * __weak weak1 = strongself2;
				
				[NSError presentError:error onViewController:weak1 completion:^(BOOL presentErrorSuccess) {
					   UIAlertController *alertController = [MADAlertController removeCredentials:^(UIAlertAction *action) {
								   [MADKeyChain deleteKey:key];
					   } cancel:nil];
					   [weak1 presentViewController:alertController animated:YES
										 completion:nil];
					   
				
					
				}];
				
			} else {
				NSError *serror = error;
				UIViewController * __weak weak1 = strongself2;
				dispatch_sync(dispatch_get_main_queue(), ^{
				
					[NSError presentError: serror
						 onViewController: weak1
							   completion:^(BOOL presentErrorSuccess) {
							   
								   UIAlertController *alertController = [MADAlertController removeCredentials:^(UIAlertAction *action) {
									   [MADKeyChain deleteKey:key];
								   } cancel:nil];
								   [weak1 presentViewController:alertController animated:YES
													 completion:nil];
							   }];
				});
			}
		}
	});
}

- (CGSize)preferredContentSize {
	return CGSizeMake(320.0, 420.0);
}

#pragma mark - Picker View Data Source
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
	NSUInteger result = 0;
	if (self.pickerData != nil) {
		result = self.pickerData.count;
	}
	return (NSInteger)result;
}

#pragma mark - Picker View Delegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row
			forComponent:(NSInteger)component {
	NSString *result = nil;
	if ((NSUInteger)row < _pickerData.count) {
		NSDictionary *pickerData = _pickerData[(NSUInteger)row];
		id resultObject = pickerData.allValues.lastObject;

		if ([resultObject isKindOfClass:[NSDateComponents class]]) {
			NSDateComponents *resultDate = resultObject;
			NSCalendar *localCalendar = [NSCalendar autoupdatingCurrentCalendar];
			NSDate *newDate = [localCalendar dateFromComponents:resultDate];
			result = [_longStyleDateFormatter stringFromDate:newDate];
			
		} else if ([resultObject isKindOfClass:[NSString class]]) {
			result = [NSString stringWithString: resultObject];
			
		} else if ([resultObject isKindOfClass:[NSNumber class]]) {
			result = ((NSNumber *)resultObject).stringValue;
			
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
	self.textField.text = [self pickerView:pickerView titleForRow:row forComponent:component];
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
	
	MADCellTextInput *result = [tableView dequeueReusableCellWithIdentifier: MTTableViewCellTextFieldIdentifier];
	
	(result.textField).returnKeyType = UIReturnKeyDone;
	result.textField.delegate = self;
	
	self.textField = result.textField;
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
