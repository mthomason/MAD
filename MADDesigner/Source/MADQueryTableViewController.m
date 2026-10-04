//
//  MADQueryBuilderAdvancedSchemaViewController.m
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryTableViewController.h"

#import <QuartzCore/CALayer.h>


#import <UIKit/UIView.h>
#import <UIKit/UIStoryboard.h>
#import <UIKit/UIManagedDocument.h>
#import <UIKit/UITableView.h>
#import <UIKit/UIToolbar.h>
#import <UIKit/UINibLoading.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIViewControllerTransitionCoordinator.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UICollectionView.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import <MAD/MADocument.h>

#import <MAD/MADModel.h>
#import <MAD/MADModelDocument.h>
#import <MAD/MADModelDatabase.h>
#import <MAD/MADModelTable.h>
#import <MAD/MADModelField.h>
#import <MAD/MADModelQuery.h>
#import <MAD/MADModelQueryTable.h>
#import <MAD/MADModelQueryField.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import "MTTitleView.h"
#import "MTSchemaFieldCell.h"
#import "MADConnectorView.h"
#import "NSLayoutConstraint+QueryVisualization.h"

#import "MADManagedObjectViewProtocol.h"

#import "MADQueryVisualizationSchemaView.h"
#import "MADQueryVisualizationSchemaDelegate.h"
#import "MADSchemaFieldCellProtocol.h"

@interface MADQueryTableViewController () <UITableViewDataSource, UITableViewDelegate, MADSchemaFieldCellProtocol>

	@property (nonatomic, weak) IBOutlet MADTitleViewQueryTable *titleView;
	@property (nonatomic, weak) IBOutlet UIView *containerView;
	@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;

@end

@implementation MADQueryTableViewController {
	int64_t _identifierQueryTable;
	int64_t _identifierSchemaTable;
}

@synthesize document = _document;
@synthesize identifier = _identifier;
@synthesize root = _root;

const CGFloat MADSchemaViewDefaultWidth = 120.0;
const CGFloat MADSchemaViewDefaultHeight = 140.0;
static NSString * const MADIdentifierQueryTableViewController = @"MADIdentifierQueryTableViewController";

+ (instancetype)newQueryTableViewController:(int64_t)identifier
									   root:(BOOL)root
								   delegate:(id <MADQueryVisualizationSchemaDelegate>)delegate
								   document:(MADocument *)document {
	id controller = [[UIStoryboard storyboardWithName: @"MADDesigner" bundle: NULL] instantiateViewControllerWithIdentifier: MADIdentifierQueryTableViewController];
	((MADQueryTableViewController *)controller).document = document;
	((MADQueryTableViewController *)controller).delegate = delegate;
	((MADQueryTableViewController *)controller).identifier = identifier;
	((MADQueryTableViewController *)controller).root = root;
	return controller;
}

+ (void)initialize {
	[super initialize];
	if (self == [MADQueryTableViewController self]) {
		@autoreleasepool {
			NSArray <Class <UIAppearanceContainer>> *classes = [[NSArray alloc] initWithObjects: [MTTitleView class], nil];
			UILabel <UIAppearance> *appearanceProxy = [UILabel appearanceWhenContainedInInstancesOfClasses:classes];
			appearanceProxy.textColor = [UIColor whiteColor];
			appearanceProxy.font = [[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline] fontWithSize:12.0];
		}
	}
}

- (CGSize)preferredContentSize {
	return CGSizeMake(MADSchemaViewDefaultWidth, MADSchemaViewDefaultHeight);
}

- (void)dealloc { }

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) { }
	return self;
}

/*- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	[self.titleView setNeedsLayout];
	[self.containerView setNeedsLayout];
	[self.tableView setNeedsLayout];
}*/

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	self.tableView.dataSource = self;
	self.tableView.delegate = self;
	self.containerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	self.containerView.layer.cornerRadius =  3.0;
	self.containerView.clipsToBounds = YES;
	self.toolbar.backgroundColor = [UIColor darkGrayColor];

	// Card styling
	self.view.layer.cornerRadius = 12.0;
	self.view.layer.masksToBounds = NO; // Important for shadow to appear
	
	// Shadow
	self.view.layer.shadowColor = [UIColor blackColor].CGColor;
	self.view.layer.shadowOffset = CGSizeMake(0, 4);
	self.view.layer.shadowOpacity = 0.77f;
	self.view.layer.shadowRadius = 10.0;
	
	// Subtle Border
	self.view.layer.borderColor = [UIColor separatorColor].CGColor;
	self.view.layer.borderWidth = 0.5;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark MADManagedObjectViewProtocol

- (void)setIdentifier:(int64_t)identifier {

	if (_identifier != identifier) {
		NSAssert(self.document != nil, @"We expect a document.");
		((MADQueryVisualizationSchemaView *)self.view).identifier = identifier;
		_identifierQueryTable = identifier;
		
		MADModelQueryTable *queryTable;
		MADocument *doc = self.document;
		NSNumber *identifierObjectID = @(identifier);
		queryTable = [doc.documentModel.firstQuery.tables objectForKey: identifierObjectID];
		_identifierSchemaTable = queryTable.schemaTable;

		self.titleView.label.text = [queryTable alias].copy;
		
		_identifier = identifier;
	}
}

#pragma mark -
#pragma mark MADHierarchicalGroupingNodeProtocol

- (void)setRoot:(BOOL)root {
	self.titleView.style = root ? MADTitleViewQueryTableRoot : MADTitleViewQueryTableChild;
	self.toolbar.barTintColor = root ? [MADColorEverydayApps newColorBlue] : [UIColor labelColor];
}

- (CGRect)frame {
	return self.tableView.frame;
}

- (CGRect)rectForFieldID:(int64_t)fieldID
				  inView:(UIView *)containerView {
	MADModelTable *table = [_document.documentModel.firstDatabase.tableDictionary objectForKey: @(_identifierSchemaTable)];
	NSUInteger row = [table.fieldIDs indexOfObject: @(fieldID)];
	CGRect rectForRow;
	if (row == NSNotFound) {
		rectForRow = CGRectZero;
	} else {
		rectForRow = [self.tableView rectForRowAtIndexPath: [NSIndexPath indexPathForItem: (NSInteger)row inSection: 0]];
	}
	return [self.tableView convertRect: rectForRow toView: containerView];
}

#pragma mark -
#pragma mark UIPresentationController

- (BOOL)shouldPresentInFullscreen { return YES; }

#pragma mark -
#pragma mark UIContentContainer

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
			  withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
	
	[super willTransitionToTraitCollection: newCollection withTransitionCoordinator: coordinator];
	if (!self.isViewLoaded) return;
	__weak UIView *titleView = self.navigationItem.titleView;;
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> __unused context) {
		[titleView sizeToFit];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext> __unused context) {
		[titleView sizeToFit];
	}];
	
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { }

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 16.0;
}

#pragma mark -
#pragma mark Table view datasource

- (UITableViewCell *)tableView:(UITableView *)tableView
		 cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	static NSString *MyIdentifierMTSchemaFieldCell = @"MTSchemaFieldCellIdentifier";
	
	MADModelDocument *doc = _document.documentModel;
	NSNumber *key = @(_identifierSchemaTable);
	MADModelTable *table = [doc.firstDatabase.tableDictionary objectForKey: key];
	NSNumber *schemaFieldID = [table.fieldIDs objectAtIndex:(NSUInteger)indexPath.row];
	MADModelField *field = [table.fields objectForKey:schemaFieldID];
	
	MTSchemaFieldCell *cell = [tableView dequeueReusableCellWithIdentifier: MyIdentifierMTSchemaFieldCell];
	cell.detailLabel.text = field.name.copy;
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	MADModelDocument *doc = _document.documentModel;
	NSNumber *key = @(_identifierSchemaTable);
	MADModelTable *table = [doc.firstDatabase.tableDictionary objectForKey: key];
	return (NSInteger)table.fieldIDs.count;
}

#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self.delegate didMoveFieldRect:self animated:NO];
}

#pragma mark -
#pragma mark Helper

- (id <NSCopying>)key {
	return @(self.identifier);
}

@end
