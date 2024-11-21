//
//  MTTableController.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTTableController.h"

#import <CoreData/NSManagedObjectID.h>

#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UITableView.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIActivityIndicatorView.h>
#import <UIKit/NSStringDrawing.h>

#import <MADFoundation/MADDataTableType.h>
#import <MADFoundation/MADDataTable.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/NSError+Constructors.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>

#import <MAD/RptqQuery.h>
#import <MADAPI/MADQuery.h>
#import <MAD/MADDataFormatter.h>
#import <MADFoundation/MADKeyChain.h>
#import <MAD/MADDataTable+Constructor.h>

#import "MADTableLayout.h"
#import "MTTableCell.h"
#import "MTTableCellHeader.h"

@interface MADTableController ()
	<UICollectionViewDataSource, MADTableLayoutDelegate, MADDatabaseResultsProtocol>

	@property (nonatomic, strong) MADDatabase *database;
	@property (nonatomic, strong) MADQuery <MADQueryDatabaseProtocol> *query;
	@property (nonatomic, strong) MADDataTable *datatable;
	@property (nonatomic, strong, readwrite) MADDataFormatter *tableFormatter;
	@property (nonatomic, strong, readwrite) NSArray *fieldKeys;
	@property (nonatomic, strong, readwrite) NSArray *fieldSizes;

@end

@implementation MADTableController {
	BOOL _firstTimeViewDidAppear;
}

- (void)dealloc {
	((MADQuery <MADQueryDataTableProtocol >*)self.query).dataTable = nil;
}

- (MADDataTable *)dataTableForQuery:(MADQuery *)query {
	return self.datatable;
}

- (instancetype)initWithQuery:(MADQuery <MADQueryDatabaseProtocol> *)query
					 database:(MADDatabase *)database
					  tableID:(NSManagedObjectID *)tableID {
	
	NSUInteger rowCount = 0;
	NSUInteger columnCount = 0;
	MADTableLayout *tableLayout = [[MADTableLayout alloc] initWithColumnCount: columnCount
																  andRowCount: rowCount];
	
	if (self = [super initWithCollectionViewLayout:tableLayout]) {
		_firstTimeViewDidAppear = YES;
		query.database.delegate = self;
		
		MADDataTable *datatable;
		
		datatable = [MADTableController dataTableWithObjectId: tableID];
		self.datatable = datatable;
		
		tableLayout.delegate = self;
		MADDataFormatter *tableFormatter = [[MADDataFormatter alloc] initWithQuery:query];
		self.tableFormatter = tableFormatter;
		self.database = database;
		self.query = query;
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	[self initialize];
	self.collectionView.backgroundColor = [MADColorEverydayApps newColorBlue];
	self.collectionView.alwaysBounceHorizontal = YES;
	self.collectionView.alwaysBounceVertical = YES;
	
	//self.navigationItem.rightBarButtonItem.tintColor = [MADColorEverydayApps newColorWhite];
	[self setAutomaticallyAdjustsScrollViewInsets:YES];
	
	//self.toolbarItems = nil;
	//self.navigationController.toolbarHidden = YES;
	//self.navigationController embe
	//self.providesPresentationContextTransitionStyle = NO;
	//self.definesPresentationContext = NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

+ (MADDataTable *)dataTableWithObjectId:(NSManagedObjectID *)objectID {
	NSNumber *typeKey = @(MADDataTableParametersType);
	NSNumber *type = @(MADDataTableTypeVirtual);
	NSNumber *objectIdKey = @(MADDataTableParametersIdentifier);
	NSNumber *objectIdV =  @(objectID.URIRepresentation.absoluteString.hash);
	NSDictionary *parameters = @{typeKey : type, objectIdKey : objectIdV};
	return [MADDataTable newDataTableWithDefinition:parameters];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	//[self.navigationController setNavigationBarHidden:NO animated:animated];
	//[self.view setNeedsLayout];
	//[self.view layoutIfNeeded];
	
	UIActivityIndicatorView *activityIndicator;
	activityIndicator = [[UIActivityIndicatorView alloc]
						 initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[activityIndicator startAnimating];
	activityIndicator.hidden = NO;
	activityIndicator.hidesWhenStopped = YES;
	
	UIBarButtonItem *barButtonItemActive;
	barButtonItemActive = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
	
	[self.navigationItem setRightBarButtonItem: barButtonItemActive animated: NO];
	
	MADTableController * __weak weakSelf = self;

	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, ^{
		
		MADTableController *strongself = weakSelf;
		
		MADQuery *queryTableFormatter = strongself.tableFormatter.query;
		if ([queryTableFormatter conformsToProtocol:@protocol(MADQueryDataTableProtocol)]) {
			((MADQuery <MADQueryDataTableProtocol> *)queryTableFormatter).dataTable = strongself.datatable;
		}
		
		NSError * __autoreleasing errorPerformQuery = NULL;
		BOOL success = [strongself.database executeQuery:queryTableFormatter
											   withError:&errorPerformQuery];
		//MADTableController *strongself2 = weakSelf2;
		UIBarButtonItem *rightBarButtonItem = strongself.navigationItem.rightBarButtonItem;
		SEL selector = @selector(setRightBarButtonItem:);
		[strongself.navigationItem performSelectorOnMainThread: selector
													withObject: rightBarButtonItem
												waitUntilDone: NO];
		
		selector = @selector(stopAnimating);
		[activityIndicator performSelectorOnMainThread: selector
											withObject: nil
										 waitUntilDone: NO];
		
		if (!success && errorPerformQuery) {
			
			NSString *key = strongself.query.database.databaseConnection.connectionString.copy;
			void (^deleteKey)(BOOL);
			deleteKey = ^(BOOL displayErrorSuccess) {
				[MADKeyChain deleteKey:key];
			};
			
			NSError *serror = [errorPerformQuery copyWithZone:nil];
			MADTableController * __weak weakself4 = strongself;
			dispatch_block_t showError = ^{
				MADTableController *sself = weakself4;
				[NSError presentError: serror
					 onViewController: sself
						   completion: deleteKey];
			};
			
			[NSThread isMainThread] ? showError() :
									  dispatch_sync(dispatch_get_main_queue(), showError);
			
		}
		[strongself performSelectorOnMainThread: @selector(invalidateLayout)
									 withObject: strongself
								  waitUntilDone: NO];
		
		
	});
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self.collectionView flashScrollIndicators];
	if (_firstTimeViewDidAppear) {
		_firstTimeViewDidAppear = NO;
		[self.collectionView scrollRectToVisible: MADRectOfSize(CGSizeMake(
															 self.collectionView.frame.size.width,
															 1.0000f))
										animated: NO];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

/*- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	
	UIViewController *parentViewController = self.navigationController.parentViewController;
	self.navigationController.navigationBar.frame = CGRectMake(self.navigationController.navigationBar.frame.origin.x,
															   (parentViewController.navigationController.navigationBar.frame.origin.y +
																parentViewController.navigationController.navigationBar.frame.size.height),
															   self.navigationController.navigationBar.frame.size.width,
															   self.navigationController.navigationBar.frame.size.height);
	
	self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width,
																 self.navigationController.bottomLayoutGuide.length, CGSizeZero.width);
	
	self.collectionView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width,
														self.navigationController.bottomLayoutGuide.length, CGSizeZero.width);
	[self.navigationItem.titleView setNeedsLayout];
}*/

/*- (void)viewDidLayoutSubviews {
	self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width,
																 self.navigationController.bottomLayoutGuide.length, CGSizeZero.width);
	
	self.collectionView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width,
														self.navigationController.bottomLayoutGuide.length, CGSizeZero.width);
	[super viewDidLayoutSubviews];
}*/


#pragma mark - Helpers

- (void)invalidateLayout {
	UICollectionView *collectionView = self.collectionView;
	[collectionView reloadData];
	[(MADTableLayout *)self.collectionViewLayout setColumnCount:self.columnCount
													  andRowCount:self.rowCount];
	
	for (NSUInteger i=0; i<self.columnCount; i++) {

		NSString *reuseId = [self reuseIdForColumn:(NSInteger)i];
		[self.collectionView registerClass: [MADTableCell class]
				forCellWithReuseIdentifier: reuseId];
		
		NSString *reuseIdHeader = [self newReuseIdSupplementForColumn:(NSInteger)i];
		[self.collectionView registerClass: [MADTableCellHeader class]
				forSupplementaryViewOfKind: @"MADTableCellHeader"
					   withReuseIdentifier: reuseIdHeader];

	}

}

- (void)initialize {
	self.collectionView.delegate = self;
	self.collectionView.dataSource = self;
}

#pragma mark - Methods

+ (NSString *)reuseId {
	static NSString * reuseId;
	if (reuseId == nil) {
		reuseId = NSStringFromClass([self class]);
	}
	return reuseId;
}

- (NSString *)reuseIdForColumn:(NSInteger)column {
	id result = [[NSString alloc] initWithFormat:@"%@%ld", [MADTableController reuseId], (long)column];
	return result;
}

- (NSString *)newReuseIdSupplementForColumn:(NSInteger)column {
	id reuseId = [[NSString alloc] initWithFormat:@"%@%ld", [MADTableController reuseIdSupplement], (long)column];
	return reuseId;
}

+ (NSString *)reuseIdSupplement {
	static NSString * reuseIdSupplement;
	if (reuseIdSupplement == nil) {
		reuseIdSupplement = [NSStringFromClass([self class]) stringByAppendingString:@"Sup"];
	}
	return reuseIdSupplement;
}

- (NSUInteger)rowCount {
	return [self.datatable numberOfRows];
}

- (NSUInteger)columnCount {
	return [self.datatable numberOfColumns];

}
#pragma mark - Delegates

#pragma mark - Collection View Datasource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
	 numberOfItemsInSection:(NSInteger)section {
	return (NSInteger)([self rowCount] * [self columnCount]);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
				  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	NSUInteger column, row;
	column =[(MADTableLayout *)collectionView.collectionViewLayout columnForIndexPath:indexPath];
	row = [(MADTableLayout *)collectionView.collectionViewLayout rowForIndexPath:indexPath];
	
	NSString *reuseId = [self reuseIdForColumn:(NSInteger)column];
	
	MADTableCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseId
																   forIndexPath:indexPath];
	
	NSDictionary *rowData = [self.datatable objectAtRow:row];
	NSString *fieldKey = [self.query fieldKeyForIndex:column];

	id fieldValue = rowData[fieldKey];
	NSString *text = [[NSString alloc] initWithFormat:@"%@", fieldValue];
	cell.label.text = text;

	return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
		   viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	
	NSUInteger column =[(MADTableLayout *)collectionView.collectionViewLayout columnForIndexPath:indexPath];
	NSString *reuseId = [self newReuseIdSupplementForColumn:(NSInteger)column];
	NSString *fieldKey = [self.query fieldKeyForIndex:(NSUInteger)indexPath.row];
	NSArray <NSString *>  *components = [fieldKey componentsSeparatedByString:@"."];
	NSString *fieldName = [components.lastObject stringByReplacingOccurrencesOfString:@"\""
																		   withString:@""];
	static NSString *tableKind = @"MADTableCellHeader";
	MADTableCellHeader *view = [collectionView dequeueReusableSupplementaryViewOfKind:tableKind
																  withReuseIdentifier:reuseId
																		 forIndexPath:indexPath];
	view.label.text = fieldName;
	return view;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
						layout:(UICollectionViewLayout*)collectionViewLayout
		insetForSectionAtIndex:(NSInteger)section{
	return UIEdgeInsetsMake(CGSizeZero.height + 22.0000f, CGSizeZero.width,
							CGSizeZero.height, CGSizeZero.width);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
				   layout:(UICollectionViewLayout*)collectionViewLayout
	  widthRequiredColumn:(NSInteger)section {
	
	NSUInteger column = (NSUInteger)section;
	NSString *fieldKey = [self.query fieldKeyForIndex:column];
	MADDatabaseField *field = ((MADQuery <MADQueryFieldKeysProtocol> *)self.query).fields[fieldKey];
	NSUInteger maxNumberOfCharacters = field.calculatedWidth;
	if (maxNumberOfCharacters <= 0) {
		maxNumberOfCharacters = 4;
	}

	UIFontDescriptor *fontDescriptorBody = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
	CGFloat sizeBody = [fontDescriptorBody.fontAttributes[UIFontDescriptorSizeAttribute] floatValue];
	UIFont *bodyFont = [UIFont fontWithDescriptor:fontDescriptorBody size:sizeBody];
	
	NSDictionary *attributes;
	attributes = [[NSDictionary alloc] initWithObjectsAndKeys: bodyFont, NSFontAttributeName, nil];
	NSString *s = [@"" stringByPaddingToLength:maxNumberOfCharacters
									withString:@"X" startingAtIndex:0];
	CGSize size = [s sizeWithAttributes:attributes];
	return size.width < 75.0000f ? 75.0000f : (size.width > 280.0000f) ? 280.0000f : size.width;
}

@end
