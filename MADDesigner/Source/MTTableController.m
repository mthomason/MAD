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
#import "MADTableLayout.h"
#import "MTTableCellHeader.h"
#import "MTTableCell.h"
#import "madlog.h"

#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADAPI/MADQuery.h>

#import <MADFoundation/MADDataTableType.h>
#import <MADFoundation/MADDataTable.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/NSError+Constructors.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import <MADFoundation/MADKeyChain.h>

#import <MAD/RptqQuery.h>
#import <MAD/MADDataFormatter.h>
#import <MAD/MADDataTable+Constructor.h>

#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UITableView.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIActivityIndicatorView.h>
#import <UIKit/NSStringDrawing.h>

#import <CoreData/NSManagedObjectID.h>

@interface MADTableController () <UICollectionViewDataSource, MADTableLayoutDelegate, MADDatabaseResultsProtocol>

@property (nonatomic, strong) MADDatabase *database;
@property (nonatomic, strong) MADQuery <MADQueryDatabaseProtocol, MADQueryDatabaseRangeProtocol> *query;
@property (nonatomic, strong) MADDataTable *datatable;
@property (nonatomic, strong, readwrite) MADDataFormatter *tableFormatter;
@property (nonatomic, strong, readwrite) NSArray *fieldKeys;
@property (nonatomic, strong, readwrite) NSArray *fieldSizes;
@property (nonatomic, assign) NSInteger minKnownRow;
@property (nonatomic, assign) NSInteger maxKnownRow;
@property (nonatomic, assign) NSUInteger nextOffset;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL hasMoreData;


@end

@implementation MADTableController {
	BOOL _firstTimeViewDidAppear;
}

- (void)dealloc {
	self.tableFormatter.query = nil;
	((MADQuery <MADQueryDataTableProtocol >*)self.query).dataTable = nil;
}

- (MADDataTable *)dataTableForQuery:(MADQuery *)query {
	return self.datatable;
}

- (instancetype)initWithQuery:(MADQuery <MADQueryDatabaseProtocol, MADQueryDatabaseRangeProtocol> *)query
					 database:(MADDatabase *)database
					  tableID:(NSManagedObjectID *)tableID {
	
	NSUInteger rowCount = 0;
	NSUInteger columnCount = 0;
	MADTableLayout *tableLayout = [[MADTableLayout alloc] initWithColumnCount: columnCount
																  andRowCount: rowCount];
	
	if (self = [super initWithCollectionViewLayout:tableLayout]) {
		_firstTimeViewDidAppear = YES;
		query.database.delegate = self;
		
		MADDataTable *datatable = [MADDataTable newDataTableWithDefinition:@{
			@(MADDataTableParametersType) : @(MADDataTableTypeVirtual),
			@(MADDataTableParametersIdentifier) : @(tableID.URIRepresentation.absoluteString.hash)
		}];
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
	self.collectionView.alwaysBounceHorizontal = YES;
	self.collectionView.alwaysBounceVertical = YES;
	self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
	self.collectionView.delegate = self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// Create and show activity indicator
	UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
	[activityIndicator startAnimating];
	activityIndicator.hidesWhenStopped = YES;
	
	// Set activity indicator as right bar button
	UIBarButtonItem *barButtonItemActive = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
	[self.navigationItem setRightBarButtonItem:barButtonItemActive animated:NO];
	
	self.minKnownRow = NSIntegerMax;
	self.maxKnownRow = NSIntegerMin;
	self.nextOffset = 0;
	self.hasMoreData = YES;
	self.isLoading = NO;
	[self fetchMoreRows];

	/*
	__weak typeof(self) weakSelf = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		__strong typeof(self) strongSelf = weakSelf;
		if (!strongSelf) return;
		
		MADQuery *queryTableFormatter = strongSelf.tableFormatter.query;
		if ([queryTableFormatter conformsToProtocol:@protocol(MADQueryDataTableProtocol)]) {
			((MADQuery <MADQueryDataTableProtocol> *)queryTableFormatter).dataTable = strongSelf.datatable;
		}
		
		NSError *errorPerformQuery = nil;
		BOOL success = [strongSelf.database executeQuery:queryTableFormatter withError:&errorPerformQuery];
		
		// Update UI on main thread
		dispatch_async(dispatch_get_main_queue(), ^{
			// Stop activity indicator
			[activityIndicator stopAnimating];
			
			// Handle query result
			if (!success && errorPerformQuery) {
				NSString *key = [strongSelf.query.database.databaseConnection.connectionString copy];
				[NSError presentError:errorPerformQuery
					  onViewController:strongSelf
							completion:^(BOOL s){
								[MADKeyChain deleteKey:key];
							}];
			}
			
			// Refresh table view
			[strongSelf invalidateLayout];
		});
	});
	*/
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self.collectionView flashScrollIndicators];
	if (_firstTimeViewDidAppear) {
		_firstTimeViewDidAppear = NO;
		[self.collectionView scrollRectToVisible: MADRectOfSize(CGSizeMake(self.collectionView.frame.size.width, 1.0))
										animated: NO];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark - Helpers

- (void)invalidateLayout {
	UICollectionView *collectionView = self.collectionView;
	NSInteger totalRows = (self.maxKnownRow >= self.minKnownRow) ? (self.maxKnownRow - self.minKnownRow + 1) : 0;
	[(MADTableLayout *)self.collectionViewLayout setColumnCount:self.columnCount
													andRowCount:(NSUInteger)totalRows /*self.rowCount*/];

	for (NSUInteger i=0; i<self.columnCount; i++) {

		NSString *reuseId = [self reuseIdForColumn:(NSInteger)i];
		[self.collectionView registerClass: [MADTableCell class]
				forCellWithReuseIdentifier: reuseId];
		
		NSString *reuseIdHeader = [self newReuseIdSupplementForColumn:(NSInteger)i];
		[self.collectionView registerClass: [MADTableCellHeader class]
				forSupplementaryViewOfKind: @"MADTableCellHeader"
					   withReuseIdentifier: reuseIdHeader];

	}
	[collectionView reloadData];

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
	return [[NSString alloc] initWithFormat:@"%@%ld", [MADTableController reuseId], (long)column];
}

- (NSString *)newReuseIdSupplementForColumn:(NSInteger)column {
	return [[NSString alloc] initWithFormat:@"%@%ld", [MADTableController reuseIdSupplement], (long)column];
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

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	NSInteger totalRows = (self.maxKnownRow >= self.minKnownRow) ? (self.maxKnownRow - self.minKnownRow + 1) : 0;
	return totalRows * (NSInteger)[self columnCount];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
				  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	NSUInteger column =[(MADTableLayout *)collectionView.collectionViewLayout columnForIndexPath:indexPath];
	NSUInteger row = [(MADTableLayout *)collectionView.collectionViewLayout rowForIndexPath:indexPath];
	//NSUInteger actualRowIndex = (NSUInteger)self.minKnownRow + row;
	NSString *reuseId = [self reuseIdForColumn:(NSInteger)column];
	
	MADTableCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseId
																   forIndexPath:indexPath];
	
	NSUInteger dataIndex = row - _query.offset;
	NSDictionary *rowData = [self.datatable objectAtRow:dataIndex];
	if (!rowData && !self.isLoading) {
		[self fetchRowAtIndex:row];
		rowData = [self.datatable objectAtRow:dataIndex];
		// You can also show a loading placeholder here
	}
	
	NSString *fieldKey = [self.query fieldKeyForIndex:column];

	id fieldValue = rowData[fieldKey];
	cell.label.text = [NSString stringWithFormat:@"%@", fieldValue];

	return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
		   viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	
	NSUInteger column = [(MADTableLayout *)collectionView.collectionViewLayout columnForIndexPath:indexPath];
	NSString *reuseId = [self newReuseIdSupplementForColumn:(NSInteger)column];
	NSString *fieldKey = [self.query fieldKeyForIndex:(NSUInteger)indexPath.row];
	NSArray <NSString *> *components = [fieldKey componentsSeparatedByString:@"."];
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
	return UIEdgeInsetsMake(CGSizeZero.height + 22.0, CGSizeZero.width, CGSizeZero.height, CGSizeZero.width);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
				   layout:(UICollectionViewLayout*)collectionViewLayout
	  widthRequiredColumn:(NSInteger)section {
	
	NSString *fieldKey = [self.query fieldKeyForIndex:(NSUInteger)section];
	MADDatabaseField *field = ((MADQuery <MADQueryFieldKeysProtocol> *)self.query).fields[fieldKey];
	NSUInteger maxNumberOfCharacters = field.calculatedWidth;
	if (maxNumberOfCharacters <= 0) {
		maxNumberOfCharacters = 4;
	}

	UIFontDescriptor *fontDescriptorBody = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
	CGFloat sizeBody = [fontDescriptorBody.fontAttributes[UIFontDescriptorSizeAttribute] floatValue];
	UIFont *bodyFont = [UIFont fontWithDescriptor:fontDescriptorBody size:sizeBody];
	
	CGSize size = [[@"" stringByPaddingToLength: maxNumberOfCharacters
									 withString: @"X"
								startingAtIndex: 0] sizeWithAttributes:@{
		NSFontAttributeName: bodyFont,
	}];
	return size.width < 75.0 ? 75.0 : (size.width > 280.0) ? 280.0 : size.width;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	return;
	// Below is commented code that I'm keeping.  It's the begining of ∞ scrolling.
	/*
	CGFloat offsetY = scrollView.contentOffset.y;
	CGFloat contentHeight = scrollView.contentSize.height;
	CGFloat viewHeight = scrollView.bounds.size.height;
	
	if (offsetY + viewHeight > contentHeight * 0.8 && self.hasMoreData && !self.isLoading) {
		[self fetchMoreRows];
	}
	
	// Prefetch upward if near top
	if (offsetY < contentHeight * 0.2 && self.minKnownRow > 0 && !self.isLoading) {
		NSUInteger candidateRow = (NSUInteger)self.minKnownRow - 255;
		[self fetchRowAtIndex:candidateRow];
	}
	*/
}

#pragma mark - Data Fetching

- (void)fetchMoreRows {
	if (self.isLoading || !self.hasMoreData) return;
	self.isLoading = YES;
	
	NSUInteger limit = 255;
	NSUInteger offset = (self.maxKnownRow == NSIntegerMin) ? 0 : (NSUInteger)self.maxKnownRow + 1;
	
	[self fetchFromAPIWithOffset:offset limit:limit completion:^(BOOL hasMore) {
		NSUInteger lower = offset;
		NSUInteger upper = offset + self.datatable.count - 1;
		self.minKnownRow = MIN(self.minKnownRow, (NSInteger)lower);
		self.maxKnownRow = MAX(self.maxKnownRow, (NSInteger)upper);
		self.hasMoreData = hasMore;
		self.isLoading = NO;
		[self invalidateLayout];
		[self.collectionView reloadData];
		[self.navigationItem setRightBarButtonItem:nil animated:NO];
	}];
}

- (void)fetchRowAtIndex:(NSUInteger)rowIndex {
	NSUInteger pageSize = 255;
	NSUInteger alignedOffset = (rowIndex / pageSize) * pageSize;
	if (rowIndex < 0 || self.isLoading || [self.datatable objectAtRow:rowIndex]) return;
	
	self.isLoading = YES;
	
	[self fetchFromAPIWithOffset:alignedOffset limit:pageSize completion:^(BOOL hasMore) {
		NSUInteger lower = alignedOffset;
		NSUInteger upper = alignedOffset + self.datatable.count - 1;
		self.minKnownRow = MIN(self.minKnownRow, (NSInteger)lower);
		self.maxKnownRow = MAX(self.maxKnownRow, (NSInteger)upper);
		self.hasMoreData = hasMore;
		self.isLoading = NO;
		[self invalidateLayout];
		//[self.collectionView reloadData];
	}];
}

- (void)fetchFromAPIWithOffset:(NSUInteger)offset
						 limit:(NSUInteger)limit
					completion:(void (^)(BOOL hasMore))completion {
	
	__weak MADTableController *weakSelf = self;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		__strong MADTableController *strongSelf = weakSelf;
		if (!strongSelf) return;
		
		MADQuery *queryTableFormatter = strongSelf.tableFormatter.query;
		if ([queryTableFormatter conformsToProtocol:@protocol(MADQueryDataTableProtocol)]) {
			((MADQuery <MADQueryDataTableProtocol> *)queryTableFormatter).dataTable = strongSelf.datatable;
		}
		if ([queryTableFormatter conformsToProtocol:@protocol(MADQueryDatabaseRangeProtocol)]) {
			((MADQuery <MADQueryDatabaseRangeProtocol> *)queryTableFormatter).offset = offset;
			((MADQuery <MADQueryDatabaseRangeProtocol> *)queryTableFormatter).limit = limit;
		} else {
			os_log_error(GetDesignerLog(), "Expected MADQueryDatabaseRangeProtocol to be implemented.");
		}

		NSError *errorPerformQuery = nil;
		BOOL success = [strongSelf.database executeQuery:queryTableFormatter withError:&errorPerformQuery];
		
		// Update UI on main thread
		if (!success && errorPerformQuery) {
			dispatch_async(dispatch_get_main_queue(), ^{
				// Handle query result
				if (!success && errorPerformQuery) {
					NSString *key = [strongSelf.query.database.databaseConnection.connectionString copy];
					[NSError presentError:errorPerformQuery
						 onViewController:strongSelf
							   completion:^(BOOL s){
						[MADKeyChain deleteKey:key];
					}];
				}
				BOOL hasMore = (strongSelf.datatable.count == limit);
				completion(hasMore);
			});
		} else {
			dispatch_async(dispatch_get_main_queue(), ^{
				BOOL hasMore = (strongSelf.datatable.count == limit);
				completion(hasMore);
			});
		}
	});
}

@end
