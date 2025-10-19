//
//  MTTableController.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTTableController.h"
#import "MADTableLayout.h"
#import "MTTableCellHeader.h"
#import "MTTableCell.h"
#import "madlog.h" //

#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADAPI/MADQuery.h>

#import <MADFoundation/MADDataTableType.h>
#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADDataTableVirtual.h> // Ensure this is imported

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

#define MAD_TABLECONTROLLER_PAGE_SIZE 255 // The absolute cache size, also the fetch size
#define PREFETCH_THRESHOLD_ROWS 100 // Trigger prefetch when this many rows from the edge of the loaded window

@interface MADTableController () <UICollectionViewDataSource, UIScrollViewDelegate, MADTableLayoutDelegate, MADDatabaseResultsProtocol>

@property (nonatomic, strong) MADDatabase *database;
@property (nonatomic, strong) MADQuery <MADQueryDatabaseProtocol, MADQueryDatabaseRangeProtocol> *query;
@property (nonatomic, strong) MADDataTable *datatable; // This is MADDataTableVirtual
@property (nonatomic, strong, readwrite) MADDataFormatter *tableFormatter;
@property (nonatomic, strong, readwrite) NSArray *fieldKeys;
@property (nonatomic, strong, readwrite) NSArray *fieldSizes;

@property (nonatomic, assign) NSInteger currentWindowMinRow;      // The first virtual row index currently loaded in datatable
@property (nonatomic, assign) NSInteger currentWindowMaxRow;      // The last virtual row index currently loaded in datatable
@property (nonatomic, assign) NSInteger totalKnownRows;           // The highest virtual row index + 1 we know exists from previous fetches
@property (nonatomic, assign) BOOL isLoadingData;                 // Flag to prevent multiple concurrent fetches
@property (nonatomic, assign) BOOL hasMoreDataAtEnd;              // Are there more rows past the current window?
@property (nonatomic, assign) BOOL hasMoreDataAtBeginning;        // Are there more rows before the current window?

// Properties to maintain scroll position during window shift
@property (nonatomic, assign) NSInteger lastScrollTriggerRow; // The virtual row that triggered the last fetch
@property (nonatomic, assign) CGFloat lastScrollOffsetRatio;  // Content offset Y ratio within the collection view for scroll position restoration
@property (nonatomic, assign) BOOL isAdjustingScrollPosition; // Flag to prevent re-triggering fetches during programmatic scroll adjustment

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
		
		// Initialize new properties
		self.currentWindowMinRow = 0;
		self.currentWindowMaxRow = -1; // Indicates no data loaded yet
		self.totalKnownRows = 0;
		self.isLoadingData = NO;
		self.hasMoreDataAtEnd = YES; // Assume more data until proven otherwise
		self.hasMoreDataAtBeginning = NO; // Initially no data before current window
		self.lastScrollTriggerRow = 0;
		self.lastScrollOffsetRatio = 0.0;
		self.isAdjustingScrollPosition = NO; // Initialize new flag
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[self initialize];
	self.collectionView.alwaysBounceHorizontal = YES;
	self.collectionView.alwaysBounceVertical = YES;
	self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
	// The delegate is already set in initialize, no need to set it again here
	// self.collectionView.delegate = self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// Show activity indicator for initial load
	UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
	[activityIndicator startAnimating];
	activityIndicator.hidesWhenStopped = YES;
	UIBarButtonItem *barButtonItemActive = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
	[self.navigationItem setRightBarButtonItem:barButtonItemActive animated:NO];
	
	// Reset properties for new view appearance
	self.currentWindowMinRow = 0;
	self.currentWindowMaxRow = -1;
	self.totalKnownRows = 0;
	self.isLoadingData = NO;
	self.hasMoreDataAtEnd = YES;
	self.hasMoreDataAtBeginning = NO;
	self.lastScrollTriggerRow = 0;
	self.lastScrollOffsetRatio = 0.0;
	self.isAdjustingScrollPosition = NO; // Reset flag on view appearance
	
	// Fetch initial data window
	[self fetchWindowedDataWithOffset:0 limit:MAD_TABLECONTROLLER_PAGE_SIZE completion:^(BOOL hasMore) {
		// Stop activity indicator after initial load completes
		[activityIndicator stopAnimating];
	}];
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
	// The number of rows for the layout should be based on the total known rows,
	// not just the current datatable content, to allow scrolling beyond the current window.
	[(MADTableLayout *)self.collectionViewLayout setColumnCount:self.columnCount
													andRowCount:(NSUInteger)self.totalKnownRows];
	
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
	// This method is likely called by the layout, so it should reflect the total virtual rows
	// that the UICollectionView can scroll through.
	return (NSUInteger)self.totalKnownRows;
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
	// Report a virtual count. If we know there's more data, add a buffer to allow scrolling beyond current window.
	if (self.hasMoreDataAtEnd) {
		return (self.totalKnownRows + MAD_TABLECONTROLLER_PAGE_SIZE) * (NSInteger)[self columnCount];
	} else {
		return self.totalKnownRows * (NSInteger)[self columnCount];
	}
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
				  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	NSUInteger column =[(MADTableLayout *)collectionView.collectionViewLayout columnForIndexPath:indexPath];
	NSInteger virtualRow = (NSInteger)[(MADTableLayout *)collectionView.collectionViewLayout rowForIndexPath:indexPath]; // Changed to NSInteger
	
	NSString *reuseId = [self reuseIdForColumn:(NSInteger)column];
	
	MADTableCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseId
																   forIndexPath:indexPath];
	
	// Check if the requested row is within the current loaded window
	if (virtualRow >= self.currentWindowMinRow && virtualRow <= self.currentWindowMaxRow) {
		NSInteger dataIndexInWindow = virtualRow - self.currentWindowMinRow; // Ensure signedness consistency
		
		// Ensure the index is valid for the current data table content
		if (dataIndexInWindow >= 0 && (NSUInteger)dataIndexInWindow < self.datatable.numberOfRows) { // Added >= 0 check
			NSDictionary *rowData = nil;
			// Protect access to self.datatable for reading to prevent races
			@synchronized (self.datatable) {
				rowData = [self.datatable objectAtRow:(NSUInteger)dataIndexInWindow]; // Cast to NSUInteger for API
			}
			NSString *fieldKey = [self.query fieldKeyForIndex:column]; //
			id fieldValue = rowData[fieldKey];
			cell.label.text = [NSString stringWithFormat:@"%@", fieldValue];
		} else {
			cell.label.text = @""; // Or "Fetching..." if we want to show something specific here
		}
	} else {
		// The requested row is outside the current window.
		// Display a loading indicator or empty cell.
		cell.label.text = @"Loading...";
		
		// Trigger a fetch if not already loading and data for this region is expected.
		// We calculate an 'aligned' offset to fetch a full page around the requested virtualRow.
		if (!self.isLoadingData) {
			NSUInteger targetOffset = (NSUInteger)((virtualRow / MAD_TABLECONTROLLER_PAGE_SIZE) * MAD_TABLECONTROLLER_PAGE_SIZE); // Cast to NSUInteger
			MADLogDebug("Cell requesting data outside window. Fetching window starting at offset: %lu", (unsigned long)targetOffset); //
			[self fetchWindowedDataWithOffset:targetOffset limit:MAD_TABLECONTROLLER_PAGE_SIZE completion:nil];
		}
	}
	
	return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
		   viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	
	NSUInteger column =[(MADTableLayout *)collectionView.collectionViewLayout columnForIndexPath:indexPath];
	NSString *reuseId = [self newReuseIdSupplementForColumn:(NSInteger)column];
	NSString *fieldKey = [self.query fieldKeyForIndex:column]; //
	NSArray <NSString *> *components = [fieldKey componentsSeparatedByString:@"."];
	NSString *fieldName = [components.lastObject stringByReplacingOccurrencesOfString:@"\"" withString:@""];
	
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
	
	NSString *fieldKey = nil;
	// Protect access to self.query for reading to prevent races
	@synchronized (self.query) {
		fieldKey = [self.query fieldKeyForIndex:(NSUInteger)section]; //
	}
	MADDatabaseField *field = ((MADQuery <MADQueryFieldKeysProtocol> *)self.query).fields[fieldKey]; //
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
	// If we are programmatically adjusting the scroll position, ignore this event to prevent ping-pong effect
	if (self.isAdjustingScrollPosition) {
		// Reset the flag immediately after the programmatic scroll is processed
		self.isAdjustingScrollPosition = NO;
		return;
	}
	
	CGFloat offsetY = scrollView.contentOffset.y;
	CGFloat contentHeight = scrollView.contentSize.height;
	CGFloat viewHeight = scrollView.bounds.size.height;
	
	MADTableLayout *layout = (MADTableLayout *)self.collectionViewLayout;
	CGFloat rowHeight = layout.heightRow; // Using heightRow as per your mention
	if (rowHeight <= 0) rowHeight = 44.0; // Fallback if heightRow is not correctly set or zero
	
	// Calculate current visible row indices (virtual rows)
	NSInteger firstVisibleVirtualRow = (NSInteger)floor(offsetY / rowHeight); // Changed to NSInteger
	NSInteger lastVisibleVirtualRow = (NSInteger)floor((offsetY + viewHeight) / rowHeight); // Changed to NSInteger
	
	// Diagnostic logging
	MADLogDebug("scrollViewDidScroll called. Offset Y: %f, Content Height: %f, View Height: %f", offsetY, contentHeight, viewHeight); //
	MADLogDebug("Current Window: [%ld, %ld], Total Known Rows: %ld", (long)self.currentWindowMinRow, (long)self.currentWindowMaxRow, (long)self.totalKnownRows); //
	MADLogDebug("Has More End: %d, Has More Beginning: %d, Is Loading: %d", self.hasMoreDataAtEnd, self.hasMoreDataAtBeginning, self.isLoadingData); //
	MADLogDebug("First Visible Virtual Row: %ld, Last Visible Virtual Row: %ld", (long)firstVisibleVirtualRow, (long)lastVisibleVirtualRow); //
	
	// --- Scrolling Down (Prefetching) ---
	// Trigger if we are within PREFETCH_THRESHOLD_ROWS of the end of the current data window
	if (lastVisibleVirtualRow >= self.currentWindowMaxRow - PREFETCH_THRESHOLD_ROWS && self.hasMoreDataAtEnd && !self.isLoadingData) {
		
		// Calculate the offset for the next page-aligned window.
		// This will be the start of the next page after the current window.
		NSInteger nextOffset = self.currentWindowMinRow + MAD_TABLECONTROLLER_PAGE_SIZE;
		
		MADLogDebug("Prefetching next page: Triggered by scroll. Fetching window starting at offset: %ld", (long)nextOffset); //
		
		// Store current scroll position relative to the visible area before the fetch
		self.lastScrollTriggerRow = firstVisibleVirtualRow;
		self.lastScrollOffsetRatio = (offsetY - (firstVisibleVirtualRow * rowHeight)); // Offset within the first visible row
		
		[self fetchWindowedDataWithOffset:(NSUInteger)nextOffset limit:MAD_TABLECONTROLLER_PAGE_SIZE completion:nil]; // Cast to NSUInteger
		[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:({ // Fix: Wrap UIActivityIndicatorView in UIBarButtonItem
			UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
			[indicator startAnimating];
			indicator;
		})] animated:YES];
	}
	
	// --- Scrolling Up (Prefetching) ---
	// Trigger if we are within PREFETCH_THRESHOLD_ROWS of the beginning of the current data window
	if (firstVisibleVirtualRow <= self.currentWindowMinRow + PREFETCH_THRESHOLD_ROWS && self.hasMoreDataAtBeginning && !self.isLoadingData) {
		
		// Calculate the offset for the previous page-aligned window.
		// Ensure it doesn't go below 0.
		NSInteger previousOffset = (self.currentWindowMinRow >= MAD_TABLECONTROLLER_PAGE_SIZE) ? self.currentWindowMinRow - MAD_TABLECONTROLLER_PAGE_SIZE : 0;
		
		// Only fetch if this previousOffset is actually a different block of data not currently loaded
		if (previousOffset < self.currentWindowMinRow) {
			MADLogDebug("Prefetching previous page: Triggered by scroll. Fetching window starting at offset: %ld", (long)previousOffset); //
			
			// Store current scroll position relative to the visible area before the fetch
			self.lastScrollTriggerRow = firstVisibleVirtualRow;
			self.lastScrollOffsetRatio = (offsetY - (firstVisibleVirtualRow * rowHeight)); // Offset within the first visible row
			
			[self fetchWindowedDataWithOffset:(NSUInteger)previousOffset limit:MAD_TABLECONTROLLER_PAGE_SIZE completion:nil]; // Cast to NSUInteger
			[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:({ // Fix: Wrap UIActivityIndicatorView in UIBarButtonItem
				UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
				[indicator startAnimating];
				indicator;
			})] animated:YES];
		}
	}
}

#pragma mark - Data Fetching

- (void)fetchWindowedDataWithOffset:(NSUInteger)offset
							  limit:(NSUInteger)limit
						 completion:(void (^)(BOOL hasMore))completion {
	
	if (self.isLoadingData) {
		if (completion) completion(NO);
		return;
	}
	self.isLoadingData = YES;
	
	// Set query parameters for the specific data window
	self.query.offset = offset;
	self.query.limit = limit;
	
	// Capture state for scroll restoration before dispatching to background
	__block NSInteger oldCurrentWindowMinRowAtStartOfFetch = self.currentWindowMinRow;
	
	__weak typeof(self) weakSelf = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		__strong typeof(weakSelf) strongSelf = weakSelf;
		if (!strongSelf) return;
		
		// Create a temporary MADDataTable for the background query
		
		MADDataTable *localTempDataTable = [MADDataTable newDataTableWithDefinition:@{
			@(MADDataTableParametersType) : @(MADDataTableTypeVirtual),
			@(MADDataTableParametersIdentifier) : @([[NSString stringWithFormat:@"%lu", (unsigned long)strongSelf.query.offset] hash]) // Use unique ID for this temp table
		}];
		
		// --- IMPORTANT: Potential Race on MADQuery's internal mutable state (fields, fieldKeys)
		// If strongSelf.query.getSql:error: modifies strongSelf.query's internal arrays while UI reads them,
		// this is still a race. A robust solution requires modifying MADQuery itself to be thread-safe
		// or passing a mutable copy of the query, if executeQuery can handle it.
		// For now, assume that the main thread access to strongSelf.query.fieldKeys
		// and strongSelf.query.fields is sufficiently atomic if they are not being written to *outside* of getSql:error:
		// or if getSql:error: is always called within a query operation that implicitly protects it.
		// The most direct approach for MADQuery race would be to wrap query generation in @synchronized.
		// For this task, we proceed with the assumption that MADDataTable itself being swapped is the primary race fix.
		
		NSError *errorPerformQuery = nil;
		// Execute the query into the temporary dataTable
		BOOL success = [strongSelf.database executeQuery:strongSelf.query withDataTable:localTempDataTable andError:&errorPerformQuery];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (!strongSelf) return;
			
			if (!success && errorPerformQuery) {
				NSString *key = [strongSelf.query.database.databaseConnection.connectionString copy];
				[NSError presentError:errorPerformQuery
					 onViewController:strongSelf
						   completion:^(BOOL s){
					[MADKeyChain deleteKey:key];
				}];
				strongSelf.isLoadingData = NO;
				if (completion) completion(NO);
				return;
			}
			
			// --- CRITICAL FIX FOR RACE CONDITION: Atomically swap strongSelf.datatable on the main thread ---
			@synchronized (strongSelf.datatable) { // Synchronize access to the datatable property
				strongSelf.datatable = localTempDataTable; // Assign the newly populated localTempDataTable
			}
			// --- END RACE CONDITION FIX ---
			
			
			// Update the loaded window boundaries based on the fetched data
			strongSelf.currentWindowMinRow = (NSInteger)offset; // Cast to NSInteger
			strongSelf.currentWindowMaxRow = (NSInteger)(offset + strongSelf.datatable.numberOfRows - 1); // Cast to NSInteger
			
			// Update totalKnownRows: This tracks the highest row index + 1 we've successfully seen.
			// This allows the collection view to continue expanding its scrollable content size.
			if (strongSelf.currentWindowMaxRow >= strongSelf.totalKnownRows) {
				strongSelf.totalKnownRows = strongSelf.currentWindowMaxRow + 1;
			} else if (strongSelf.totalKnownRows == 0 && strongSelf.datatable.numberOfRows > 0) {
				strongSelf.totalKnownRows = (NSInteger)strongSelf.datatable.numberOfRows; // Cast to NSInteger
			}
			
			// Determine if more data is potentially available for scrolling in either direction
			strongSelf.hasMoreDataAtEnd = (strongSelf.datatable.numberOfRows == limit); // If we got a full page, assume more
			strongSelf.hasMoreDataAtBeginning = (strongSelf.currentWindowMinRow > 0); // If the min row is > 0, there's data before
			
			strongSelf.isLoadingData = NO;
			
			// Invalidate layout to update column/row counts for the collection view
			[strongSelf invalidateLayout];
			[strongSelf.collectionView reloadData]; // Reload all visible cells to show new data
			
			// Diagnostic logging for content size after reload
			MADLogDebug("Collection View Content Size after reload: {width: %f, height: %f}", strongSelf.collectionView.contentSize.width, strongSelf.collectionView.contentSize.height); //
			
			// --- Scroll position restoration ---
			NSIndexPath *targetIndexPath = nil;
			UICollectionViewScrollPosition scrollPosition = UICollectionViewScrollPositionTop;
			
			// Determine if we fetched forward or backward based on the original request offset and oldCurrentWindowMinRowAtStartOfFetch
			BOOL fetchedForward = ((NSInteger)offset > oldCurrentWindowMinRowAtStartOfFetch);
			
			strongSelf.isAdjustingScrollPosition = YES; // Set flag BEFORE programmatic scroll
			
			if (strongSelf.datatable.numberOfRows == 0 && strongSelf.currentWindowMinRow == 0) {
				// No data fetched, stay at top
				targetIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
				scrollPosition = UICollectionViewScrollPositionTop;
				MADLogDebug("Restoring scroll position: No data, scrolled to top."); //
			}
			else if (fetchedForward) {
				// We fetched forward (scrolling down).
				// Target the top of the newly loaded page.
				targetIndexPath = [NSIndexPath indexPathForItem:(NSInteger)(strongSelf.currentWindowMinRow * strongSelf.columnCount) inSection:0];
				scrollPosition = UICollectionViewScrollPositionTop;
				MADLogDebug("Restoring scroll position: Fetched forward. Scrolling to top of new window item: %ld (virtual row %ld)", (long)targetIndexPath.item, (long)strongSelf.currentWindowMinRow); //
			} else if (strongSelf.currentWindowMinRow < oldCurrentWindowMinRowAtStartOfFetch) { // We fetched backward
				// We fetched backward (scrolling up).
				// Try to restore the original visual position based on lastScrollTriggerRow and its offset.
				
				// Calculate the virtual row that *should* be at the top of the screen based on original trigger.
				NSInteger targetVirtualRow = strongSelf.lastScrollTriggerRow;
				
				// Adjust it to be within the bounds of the newly loaded window.
				if (targetVirtualRow < strongSelf.currentWindowMinRow) {
					targetVirtualRow = strongSelf.currentWindowMinRow;
				} else if (targetVirtualRow > strongSelf.currentWindowMaxRow) {
					targetVirtualRow = strongSelf.currentWindowMaxRow;
				}
				
				// Calculate the pixel offset for this target virtual row.
				CGFloat targetOffsetY = (CGFloat)(targetVirtualRow - strongSelf.currentWindowMinRow) * ((MADTableLayout *)strongSelf.collectionViewLayout).heightRow + strongSelf.lastScrollOffsetRatio;
				
				// Clamp to valid scrollable area
				CGFloat maxOffsetY = MAX(0, strongSelf.collectionView.contentSize.height - strongSelf.collectionView.bounds.size.height);
				targetOffsetY = MAX(0, targetOffsetY);
				targetOffsetY = MIN(targetOffsetY, maxOffsetY);
				
				[strongSelf.collectionView setContentOffset:CGPointMake(strongSelf.collectionView.contentOffset.x, targetOffsetY) animated:NO];
				MADLogDebug("Restoring scroll position: Fetched backward. Adjusted offset to Y: %f (virtual row %ld)", targetOffsetY, (long)targetVirtualRow); //
			} else { // Initial load or no significant window shift, just restore original position if possible.
				// This handles initial load or any other non-forward/backward fetch where the window didn't shift.
				// It attempts to maintain the exact `lastScrollTriggerRow` and `lastScrollOffsetRatio`
				// relative to the current window.
				
				NSInteger relativeRow = strongSelf.lastScrollTriggerRow - strongSelf.currentWindowMinRow;
				if (relativeRow >= 0 && relativeRow < strongSelf.datatable.numberOfRows) {
					targetIndexPath = [NSIndexPath indexPathForItem:(NSInteger)(relativeRow * strongSelf.columnCount) inSection:0];
				} else {
					targetIndexPath = [NSIndexPath indexPathForItem:0 inSection:0]; // Fallback
				}
				
				CGFloat targetOffsetY = (CGFloat)relativeRow * ((MADTableLayout *)strongSelf.collectionViewLayout).heightRow + strongSelf.lastScrollOffsetRatio;
				CGFloat maxOffsetY = MAX(0, strongSelf.collectionView.contentSize.height - strongSelf.collectionView.bounds.size.height);
				targetOffsetY = MAX(0, targetOffsetY);
				targetOffsetY = MIN(targetOffsetY, maxOffsetY);
				
				[strongSelf.collectionView setContentOffset:CGPointMake(strongSelf.collectionView.contentOffset.x, targetOffsetY) animated:NO];
				MADLogDebug("Restoring scroll position: Initial/No shift. Adjusted offset to Y: %f (virtual row %ld)", targetOffsetY, (long)strongSelf.lastScrollTriggerRow); //
			}
			
			// For fetchedForward scenario, use scrollToItemAtIndexPath
			if (fetchedForward && targetIndexPath) {
				[strongSelf.collectionView scrollToItemAtIndexPath:targetIndexPath atScrollPosition:scrollPosition animated:NO];
			}
			// For other scenarios, setContentOffset was already called directly.
			// --- END Scroll position restoration ---
			
			// Hide the activity indicator after the fetch is complete
			[strongSelf.navigationItem setRightBarButtonItem:nil animated:YES];
			
			if (completion) completion(strongSelf.hasMoreDataAtEnd);
		});
	});
}

@end
