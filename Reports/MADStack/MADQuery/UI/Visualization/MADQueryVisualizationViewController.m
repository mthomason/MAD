//
//  MADQueryBuilderAdvancedViewController.m
//  Reports
//
//  Created by Michael Thomason on 2/14/13.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryVisualizationViewController.h"

#import <Foundation/NSSet.h>

#import <CoreData/NSManagedObjectContext.h>

#import <UIKit/UIWindow.h>
#import <UIKit/UIView.h>
#import <UIKit/UITableView.h>
#import <UIKit/UIToolbar.h>

#import <UIKit/UIManagedDocument.h>
#import <UIKit/UIStoryboard.h>
#import <UIKit/UIPopoverController.h>
#import <UIKit/UIPanGestureRecognizer.h>

#import <QuartzCore/CALayer.h>

#import <MADDataStructures/MTPair.h>
#import <MADDataStructures/MTVertex.h>
#import <MADDataStructures/MTLinkedList.h>

#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADApplicationProtocol.h>
#import <MADFoundation/MADURLFactory.h>

#import <MADFoundation/MADApplicationProtocol.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import <MAD/MADocument.h>

#import <MAD/RptqDocument.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqQueryLinks.h>
#import <MAD/RptqQueryLinks+Extras.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryTable.h>

#import <MAD/MADModel.h>
#import <MAD/MADModelDocument.h>
#import <MAD/MADModelDatabase.h>
#import <MAD/MADModelQuery.h>
#import <MAD/MADModelQueryTable.h>
#import <MAD/MADModelQueryLink.h>
#import <MAD/MADModelTable.h>
#import <MAD/MADModelField.h>
#import <MAD/MADModelQueryField.h>

#import <MAD/MADTableFieldIdentifier.h>

#import <MADAPI/MADViewControllerStandardProtocol.h>

#import "MADConnectorView.h"

#import "MADQueryTableViewController.h"

#import "MADAffineTransformSwing.h"

#import "NSLayoutConstraint+QueryVisualization.h"
#import "MADHierarchicalChildViewDefination.h"

#import "MADGestureRecognizerAnchorPoint.h"

#import "MADQueryVisualizationSchemaPresentationController.h"

#import "MADQueryVisualizationContentView.h"
#import "MADQueryVisualizationScrollView.h"

#import "MADQueryVisualizationSchemaView.h"
#import "MADQueryVisualizationSchemaDelegate.h"

#import "MADQueryVisualizationCacheManager.h"

#import "MADQueryVisualizationModel.h"
#import "MADHierarchicalDisplayModel.h"

#import "MADViewController.h"

#import "NSLayoutConstraint+Designer.h"
#import "AppDelegate.h"

typedef void(^MTBlockResultVoid)(void);

typedef UIViewController <MADManagedObjectViewProtocol, MADHierarchicalGroupingNodeProtocol> MADHierarchicalChildController;
typedef NSMutableDictionary <NSNumber *,
							 MADHierarchicalChildController *> MADMutableMapHierarchicalChildControllers;

@interface MADQueryVisualizationViewController ()
	<UIGestureRecognizerDelegate,
		UIPopoverControllerDelegate,
		MADQueryVisualizationSchemaPresentationDelegate,
		MADQueryVisualizationSchemaDelegate,
		MADViewControllerStandardProtocol>

	@property (nonatomic, strong) MADQueryVisualizationCacheManager *cacheManager;
	@property (nonatomic, strong) MADMutableMapHierarchicalChildControllers *controllersByObjectID;
	@property (nonatomic, strong) NSMutableDictionary <NSNumber *, MADConnectorView *> *connectionViewsByObjectID;
	@property (nonatomic, strong) NSMutableDictionary <NSNumber *, NSDictionary <NSString *, NSLayoutConstraint *> *> *constraints;
	@property (nonatomic, strong) NSMutableSet <NSNumber *> *rootTables;

	@property (nonatomic, weak) IBOutlet UIView *backgroundContainer;
	@property (nonatomic, strong) MADQueryVisualizationScrollView *scrollView;

	@property (nonatomic, copy) NSURL *localCacheFileURL;

	@property (nonatomic, readonly) MADQueryVisualizationContentView *contentView;

@end

static NSString *keyCenterX = @"x";
static NSString *keyCenterY = @"y";
static NSString *keyWidth   = @"w";
static NSString *keyHeight  = @"h";

static inline CGPoint MADPointInsertTable(CGFloat, NSUInteger);
static inline CGPoint MADPointInsertTable(CGFloat viewHeight, NSUInteger tableCount) {
	return CGPointMake(CGPointZero.x + 300, viewHeight / (tableCount + 2) * (tableCount + 1));
}

@implementation MADQueryVisualizationViewController

@synthesize document = _document;

#pragma mark -
#pragma mark Static functions and keys

+ (instancetype)newQueryVisualizationViewController:(MADocument *)document {
	id controller = [MADViewController newViewControllerQueryVisulization];
	[controller setDocument: document];
	return controller;
}

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
	[_controllersByObjectID removeAllObjects];
	[_connectionViewsByObjectID removeAllObjects];
	[_rootTables removeAllObjects];
	[_constraints removeAllObjects];
	
	MADModelQuery *firstQuery = _document.documentModel.firstQuery;
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: MADNotificationQueryLinkDelete
												  object: firstQuery];
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: MADNotificationQueryTableDelete
												  object: firstQuery];
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: MADNotificationQueryLinkInsert
												  object: firstQuery];
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: MADNotificationQueryTableInsert
												  object: firstQuery];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		
		MADMutableMapHierarchicalChildControllers *controllersByObjectID;
		controllersByObjectID = [[NSMutableDictionary alloc] init];
		self.controllersByObjectID = controllersByObjectID;
		
		NSMutableDictionary <NSNumber *, MADConnectorView *> *connectionViewsByObjectID;
		connectionViewsByObjectID = [[NSMutableDictionary alloc] init];
		self.connectionViewsByObjectID = connectionViewsByObjectID;
		
		NSMutableSet <NSNumber *> *rootTables = [[NSMutableSet alloc] init];
		self.rootTables = rootTables;
		
		NSMutableDictionary <NSNumber *, NSDictionary <NSString *, NSLayoutConstraint *> *> *constraints;
		constraints = [[NSMutableDictionary alloc] init];
		self.constraints = constraints;
		
	}
	return self;
}

#pragma mark -
#pragma mark UIContainerViewController Callbacks

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
	return NO;
}

- (void)willMoveToParentViewController:(nullable UIViewController *)parent {
	[super willMoveToParentViewController:parent];
}

- (void)didMoveToParentViewController:(nullable UIViewController *)parent {
	[super didMoveToParentViewController:parent];
}

#pragma mark -
#pragma mark UIContentContainer

- (CGSize)sizeForChildContentContainer:(id <UIContentContainer>)container
			   withParentContainerSize:(CGSize)parentSize {
	return CGSizeMake(MADSchemaViewDefaultWidth, MADSchemaViewDefaultHeight);
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection
			  withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
}

- (void)viewWillTransitionToSize:(CGSize)size
	   withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

	if (CGSizeEqualToSize(size, self.view.bounds.size)) return;
	
	for (UIViewController *subviewController in self.childViewControllers) {
		[self didMoveFieldRect: subviewController animated: YES];
	}
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self.view setNeedsDisplay];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) { }];
	
}

#pragma mark -
#pragma mark Overrides

- (MADQueryVisualizationContentView *)contentView {
	return self.scrollView.contentView;
}

#pragma mark -
#pragma mark MADQueryVisualizationSchemaPresentationDelegate

- (CGRect)frameOfItemWithObjectID:(int64_t)objectID {
	MADHierarchicalChildViewDefination *tableDefination;
	tableDefination = [self.cacheManager.cacheData tableDefinationForObjectID:objectID];
	CGRect result = CGRectMake(tableDefination.center.x - MADSchemaViewDefaultWidth / 2,
							   tableDefination.center.y - MADSchemaViewDefaultHeight / 2,
							   MADSchemaViewDefaultWidth,
							   MADSchemaViewDefaultHeight);
	return result;
}

- (void)setDocument:(MADocument *)document {
	if (document != nil && _document != document) {
		_document = document;
	}
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.definesPresentationContext = YES;
	
	BOOL isRetnaDisplay = YES;
	self.backgroundContainer.layer.borderWidth = isRetnaDisplay ? 0.5 : 1.0;
	self.backgroundContainer.backgroundColor = [UIColor clearColor];
	self.backgroundContainer.opaque = NO;
	self.backgroundContainer.autoresizesSubviews = NO;
	self.view.opaque = YES;
	
	MADQueryVisualizationScrollView *scrollView;
	scrollView = [[MADQueryVisualizationScrollView alloc] initWithFrame:self.backgroundContainer.bounds];
	[self.backgroundContainer addSubview:scrollView];
	
	NSDictionary <NSString *, __kindof UIView *> *viewDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:scrollView, @"sv", _backgroundContainer, @"bg", nil];

	NSMutableArray <NSLayoutConstraint *> *constraints = [[NSMutableArray alloc] init];
	[constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bg]|" options:0 metrics:0 views:viewDictionary]];
	[constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[bg]|" options:0 metrics:0 views:viewDictionary]];
	[self.view addConstraints:constraints];

	NSMutableArray <NSLayoutConstraint *> *constraints2 = [[NSMutableArray alloc] init];
	[constraints2 addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[sv]|" options:0 metrics:0 views:viewDictionary]];
	[constraints2 addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[sv]|" options:0 metrics:0 views:viewDictionary]];
	[self.backgroundContainer addConstraints:constraints2];
	
	self.scrollView = scrollView;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	MADocument *document = self.document;
	NSManagedObjectContext *managedObjectContext;
	managedObjectContext = document.documentModel.managedObjectContext;
	id firstQuery = document.documentModel.firstQuery;
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(deleteQueryLink:)
												 name: MADNotificationQueryLinkDelete
											   object: firstQuery];

	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(deleteQueryTable:)
												 name: MADNotificationQueryTableDelete
											   object: firstQuery];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(handleInsertQueryLink:)
												 name: MADNotificationQueryLinkInsert
											   object: firstQuery];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(insertQueryTable:)
												 name: MADNotificationQueryTableInsert
											   object: firstQuery];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(managedObjectContextWillSave:)
												 name: NSManagedObjectContextWillSaveNotification
											   object: managedObjectContext];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(managedObjectContextDidSave:)
												 name: NSManagedObjectContextDidSaveNotification
											   object: managedObjectContext];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self redraw: animated];
	if (animated) [self.scrollView flashScrollIndicators];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	//[self archiveCache];
	[self clearScreen];
	
	MADocument *document = self.document;
	NSManagedObjectContext *managedObjectContext;
	managedObjectContext = document.documentModel.managedObjectContext;

	
	NSString *willSave = NSManagedObjectContextWillSaveNotification;
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: willSave
												  object: managedObjectContext];
	
	NSString *didSave = NSManagedObjectContextDidSaveNotification;
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: didSave
												  object: managedObjectContext];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];

	[self.connectionViewsByObjectID removeAllObjects];
	[self.controllersByObjectID removeAllObjects];
	[self.rootTables removeAllObjects];
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	//self.scrollView.scrollIndicatorInsets =
	//    UIEdgeInsetsMake(self.view.safeAreaLayoutGuide.length, CGSizeZero.width,
	//                     self.bottomLayoutGuide.length, CGSizeZero.height);
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	[self archiveCache];
	[self clearScreen];
}

- (void)layoutQueryTables {
	UIViewController *childContoller;
	NSArray *childControllers = self.childViewControllers;
	for (childContoller in childControllers) {
		if ([childContoller isKindOfClass:[MADQueryTableViewController class]]) {

			MADHierarchicalChildViewDefination *tableDefination;
			tableDefination = [self.cacheManager.cacheData tableDefinationForObjectID:((MADHierarchicalChildController *)childContoller).identifier];
			if (tableDefination == nil) {
				tableDefination = [MADHierarchicalChildViewDefination newTableDefination];
				
				tableDefination.center = CGCenterRect(self.scrollView.bounds);

				[self.cacheManager.cacheData addTableDefination: tableDefination
									   forObjectID: ((MADHierarchicalChildController *)childContoller).identifier];
			}
			
			if (tableDefination.root) {
				NSNumber *objectID;
				objectID = @(((MADHierarchicalChildController *)childContoller).identifier);
				[self.rootTables addObject: objectID];
			}

			childContoller.view.frame = CGRectMake(tableDefination.center.x - childContoller.view.frame.size.width / 2,
												   tableDefination.center.y - childContoller.view.frame.size.height / 2,
												   childContoller.view.frame.size.width,
												   childContoller.view.frame.size.height);
			childContoller.view.center = tableDefination.center;
		}
	}
}

- (void)layoutQueryLinks {
	NSEnumerator <MADModelQueryLink *> *queryLinkEnumerator = self.document.documentModel.firstQuery.links.objectEnumerator;
	for (MADModelQueryLink *link in queryLinkEnumerator) {
		[self layoutQueryLinkViewControllerWithModelObject:link];
	}
	[self.view setNeedsLayout];
}

#pragma mark -
#pragma mark NSManagedObjectContext Observer

- (void)managedObjectContextWillSave:(NSNotification *)notification {
/*
	NSArray *insertedObjects = notification.userInfo[NSInsertedObjectsKey];
	NSArray *updatedObjects = notification.userInfo[NSUpdatedObjectsKey];
	NSArray *deletedObjects = notification.userInfo[NSDeletedObjectsKey];
*/
}

- (void)managedObjectContextDidSave:(NSNotification *)notification {
	/*
	NSArray *insertedObjects = notification.userInfo[NSInsertedObjectsKey];
	NSArray *updatedObjects = notification.userInfo[NSUpdatedObjectsKey];
	NSArray *deletedObjects = notification.userInfo[NSDeletedObjectsKey];
	
	RptqQuery *updatedQuery = nil;
	BOOL needsLayout = NO;
	
#pragma mark Handle inserted objects
	
	for (id insertedObject in insertedObjects) {
		
		if ([insertedObject isKindOfClass:[RptqQueryLinks class]]) {
			
			//User adding a link starting point...
			RptqQueryLinks *insertedQueryLinks = insertedObject;
			//[self insertQueryLink:insertedQueryLinks];
			
		} else if ([insertedObject isKindOfClass:[RptqQueryTable class]]) {
			
			//User adding a table starting point...
			RptqQueryTable *insertedQueryTable = insertedObject;
			//[self insertQueryTable:insertedQueryTable];
		}
	}
	
#pragma mark Handle updated objects

	CGFloat height;
	NSUInteger rootTableCount;

	if (updatedObjects.count) {

		NSMutableArray *updatedTables;
		updatedTables = [[NSMutableArray alloc] initWithCapacity:updatedObjects.count];

		for (const id updatedObject in updatedObjects) {
			
			if ([updatedObject isKindOfClass:[RptqQueryTable class]]) {
				[updatedTables addObject:updatedObject];
		
			} else if ([updatedObject isKindOfClass:[RptqQuery class]]) {
				updatedQuery = updatedObject;
			}
		}

		if (updatedQuery && updatedTables.count > 0) {
			
			MADHierarchicalChildController *updatedItem;
			
			NSNumber *updatedTableID = nil, *effectedLinkID = nil;
			for (RptqQueryTable *updatedTable in updatedTables) {
				if (![updatedTable.inQuery.objectID isEqual:updatedQuery.objectID]) {

					updatedTableID = @(updatedTable.identifier);
					//Table was remvoed from query... so remove it from screen.
					updatedItem = self.controllersByObjectID[updatedTableID];
					
					if (updatedItem != nil) {
						
						[self.rootTables removeObject:updatedTableID];
						[self.cacheManager.cacheData removeTableDefinationForObjectID:updatedTable.identifier];
						[self removeViewController:updatedItem];
						
						for (RptqQueryLinks *link in updatedQuery.hasQueryLinks) {
							if ([link isConnectedToTable:updatedTable]) {
								effectedLinkID = @(link.identifier);
								MADConnectorView *connectorView = self.connectionViewsByObjectID[effectedLinkID];
								[connectorView removeFromSuperview];
								
								[self.view setNeedsLayout];
							}
						}
						needsLayout = YES;
					}
				}
			}
		}
	}

#pragma mark Handle deleted objects

	if (deletedObjects.count > 0) {
		NSNumber *effectedLinkID = nil;
		for (RptqQueryLinks *link in deletedObjects) {
			effectedLinkID = @(link.identifier);
			MADConnectorView *connectorView = self.connectionViewsByObjectID[effectedLinkID];
			[connectorView removeFromSuperview];
			
			[self.view setNeedsLayout];
		}
		needsLayout = YES;
	}
	
#pragma mark Handle deleted objects
	
	//for (id deletedObject in deletedObjects) {
	//    if ([deletedObject isKindOfClass:[RptqQueryTable class]]) {
	//        [self deleteQueryTable:deletedObject];
	//        [self.view setNeedsLayout];
	//    }
	//}

	//[self.view layoutIfNeeded];
	 
	 */
}

#pragma mark -
#pragma mark MADViewControllerStandardProtocol

- (void)viewControllerDidFinish:(id)sender {
	[self dismissViewControllerAnimated:YES completion:^{ }];
}

#pragma mark -
#pragma mark Cache Operations

- (MADQueryVisualizationCacheManager *)cacheManager {
	if (_cacheManager == nil) {
		MADQueryVisualizationCacheManager *cacheManager;
		cacheManager = [[MADQueryVisualizationCacheManager alloc] initWithURL:self.localCacheFileURL];
		_cacheManager = cacheManager;
	}
	return _cacheManager;
}

- (void)updateCache {
	MADocument *doc = self.document;
	[self.cacheManager updateCacheWithQuery:doc.documentModel.firstQuery
							  contentOffset:self.scrollView.contentOffset
								  zoomScale:self.scrollView.zoomScale
									 center:^CGPoint(NSNumber *tableID) {
		MADHierarchicalChildController *schemaController = self.controllersByObjectID[tableID];
		return schemaController.view.center;
	}];
}

- (void)archiveCache {
	[self updateCache];
	[self.cacheManager archiveCache];
}

- (NSString *)cacheFileName {
	return [MADQueryVisualizationViewController cacheFileNameForDocument:self.document];
}

- (NSURL *)localCacheFileURL {
	if (_localCacheFileURL == nil) {
		NSString *cacheFileName = [self cacheFileName];
		NSString *groupID = [AppDelegate groupIdentifier];
		NSURL *url = [MADURLFactory newURLForLocalCacheDirectoryForGroupIdentifier:groupID];
		url = [url URLByAppendingPathComponent: cacheFileName
								   isDirectory: NO];
		_localCacheFileURL = url.copy;
	}
	return _localCacheFileURL;
}

+ (NSString *)cacheFileNameForDocument:(MADocument *)document {
	NSString *filename = document.fileURL.lastPathComponent.stringByDeletingPathExtension;
	return [MADHierarchicalDisplayModel cacheFileNameForFileName:filename];
}

#pragma mark -
#pragma mark Gesture recognizer actions

- (void)handlePanPiece:(UIPanGestureRecognizer *)gestureRecognizer {
	int64_t tableID;
	tableID = ((MADQueryVisualizationSchemaView *)gestureRecognizer.view).identifier;
	NSAssert(tableID > 0, @"We expect an ID");
	if (!tableID) return;
	
	[MADGestureRecognizerAnchorPoint adjustAnchorPointForGestureRecognizer:gestureRecognizer];
	
	UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
	CGPoint pointInView = [window convertPoint: [gestureRecognizer locationInView:window]
										toView: self.contentView];
	NSNumber *tableIdentifier = @(tableID);
	NSDictionary <NSString *, NSLayoutConstraint *> *constraints;
	constraints = [self.constraints objectForKey: tableIdentifier];
	constraints[keyCenterX].constant = pointInView.x;
	constraints[keyCenterY].constant = pointInView.y;

	MADHierarchicalChildController *movingController = self.controllersByObjectID[tableIdentifier];
	[self didMoveFieldRect: movingController
				  animated: NO];
	
	if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
		
		if (self.cacheManager.cacheData) {
			MADHierarchicalChildViewDefination *tableDefination;
			tableDefination = [self.cacheManager.cacheData tableDefinationForObjectID:tableID];
			tableDefination.center = pointInView;
		}
		[self archiveCache];
		
	} else if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
 
		UIView *gestureView = gestureRecognizer.view;
		if (gestureView != nil) {
			[self.contentView bringSubviewToFront:gestureView];
			NSEnumerator <MADConnectorView *> *views;
			MADConnectorView *view;
			NSSet <NSNumber /*MADModelQueryLink*/ *> *queryLinks;
			queryLinks = [self.document.documentModel.firstQuery linksForQueryTable:tableID];
			views = self.connectionViewsByObjectID.objectEnumerator;
			for (view in views) {
				if ([queryLinks containsObject:view.key]) {
					[self.contentView bringSubviewToFront:view];
				}
			}
		}
	}
}

#pragma mark -
#pragma mark Change UI on IR Diagram

- (void)clearScreen {
	for (UIViewController *viewController in self.childViewControllers) {
		[self removeViewController:viewController];
	}
	for (UIView *subview in self.contentView.subviews) {
		[subview removeFromSuperview];
	}
}

- (void)redraw:(BOOL)animated {
	[self clearScreen];
	[self.rootTables removeAllObjects];
	[self.controllersByObjectID removeAllObjects];
	[self.connectionViewsByObjectID removeAllObjects];
	
	MADModelDocument *document = _document.documentModel;
	MADModelQuery *query = document.firstQuery;
	
	MADQueryVisualizationModel *queryVisualizationModel = [[MADQueryVisualizationModel alloc] initWithQuery:query];
	MTLinkedList *topologicallySortedTables = queryVisualizationModel.topologicallySortedTables;
	
	NSManagedObjectContext *managedObjectContext = document.managedObjectContext;
	
	NSEnumerator <MADModelQueryLink *> *queryLinkEnumerator = query.links.objectEnumerator;
	
	MTVertex *vertexTableID;
	NSNumber *objectID;
	
	typeof(self) __weak wself = self;
	
	NSMutableArray <MADQueryTableViewController *> *viewControllers;
	viewControllers = [[NSMutableArray alloc] init];
	for (MTPair *pair in topologicallySortedTables) {

		vertexTableID = pair.former;

		if (vertexTableID.object != nil) {
			
			objectID = ((NSNumber *)vertexTableID.object).copy;
			int64_t tableID = objectID.longLongValue;
			
			BOOL topLevel = [queryVisualizationModel isTopLevel:objectID];
			if (topLevel) {
				[self.rootTables addObject: objectID];
			}
			MADQueryTableViewController *viewController = [MADQueryTableViewController newQueryTableViewController:tableID
																											  root:topLevel
																										  delegate:self
																										  document:self.document];
			viewController.view.translatesAutoresizingMaskIntoConstraints = NO;
			[viewControllers addObject:viewController];
		}
	}

	
	MADHierarchicalDisplayModel *cacheData;
	NSString *path = self.localCacheFileURL.filePathURL.path.copy;
	if (path != nil && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
		cacheData = [self.cacheManager loadCache];
	}
	
	if (cacheData != nil) {
		self.scrollView.contentOffset = cacheData.scrollViewContentOffset;
		self.scrollView.zoomScale = cacheData.scrollViewZoomScale;
	}
	
	void(^completion)(void) = ^() {
		typeof(self) sself = wself;
		MADModelDocument *modelDocument = sself.document.documentModel;
		MADModelQuery *modelQuery = modelDocument.firstQuery;
		NSEnumerator <MADModelQueryLink *> *queryLinks = modelQuery.links.objectEnumerator;
		
		for (MADModelQueryLink *link in queryLinks) {
			[sself addLinkViewControllerForQueryLinkModel:link animated:animated];
		}
		
		NSEnumerator <MADConnectorView *> *views = sself.connectionViewsByObjectID.objectEnumerator;
		for (UIView *view in views) {
			[sself.contentView bringSubviewToFront:view];
		}
	};
	
	[self addViewControllers: viewControllers
				   cacheData: cacheData
	 queryVisualizationModel: queryVisualizationModel
					animated: animated
				  completion: completion];
}

- (void)addViewControllers:(NSArray <MADQueryTableViewController *> *)viewControllers
				 cacheData:(MADHierarchicalDisplayModel *)cacheData
   queryVisualizationModel:(MADQueryVisualizationModel *)queryVisualizationModel
				  animated:(BOOL)animated
				completion:(void(^)(void))completion {
	for (MADQueryTableViewController *viewController in viewControllers) {
		
		int64_t tableID = viewController.identifier;
		
		MADHierarchicalChildViewDefination *tableDef;
		tableDef = cacheData != nil ? [cacheData tableDefinationForObjectID:tableID] : nil;
		
		CGPoint center = cacheData != nil ? tableDef.center : self.contentView.center;
		NSDictionary <NSString *, NSLayoutConstraint *> *constraints;
		constraints = [self constraints:viewController center:center];
		
		NSNumber *identifier = @(viewController.identifier);
		[self.constraints setObject:constraints forKey:identifier];
		viewController.root = [queryVisualizationModel isTopLevel:identifier];
		
		self.controllersByObjectID[identifier] = viewController;;
		
		UIPanGestureRecognizer *panGesture;
		panGesture = [MADQueryVisualizationViewController newGestureRecognizerPanPiece:self];
		
		[self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:panGesture];
		
		[viewController.view addGestureRecognizer:panGesture];
		[viewController willMoveToParentViewController:self];
		
		[self addChildViewController:viewController];
		
		[viewController beginAppearanceTransition:YES animated:YES];
		
		viewController.view.bounds = CGRectMake(CGPointZero.x, CGPointZero.y,
												viewController.preferredContentSize.width,
												viewController.preferredContentSize.height);
		viewController.view.center = center;
		viewController.view.alpha = animated ? 0.0 : 1.0;
		[self.contentView addSubview: viewController.view];
		[self.contentView addConstraints: constraints.allValues];

		if (!animated) {
			[viewController endAppearanceTransition];
			[viewController didMoveToParentViewController:self];
		}
	}

	if (!animated) return completion();
	
	typeof(self) __weak weakself = self;
	[UIView animateWithDuration:0.5 animations: ^{
		for (MADQueryTableViewController *viewController in viewControllers) {
			[viewController.view setAlpha:1.0];
		}
	} completion:^(BOOL finished) {
		for (MADQueryTableViewController *viewController in viewControllers) {
			[viewController endAppearanceTransition];
			[viewController didMoveToParentViewController:weakself];
		}
		completion();
	}];

}

- (void)addViewController:(MADHierarchicalChildController *)viewController
				   center:(CGPoint)center
					 root:(BOOL)root
				 animated:(BOOL)animated
			   completion:(void(^)(void))completion {
	
	NSDictionary <NSString *, NSLayoutConstraint *> *constraints;
	constraints = [self constraints:viewController center:center];
	
	NSNumber *identifier = @(viewController.identifier);
	[self.constraints setObject:constraints forKey:identifier];
	viewController.root = root;
	
	self.controllersByObjectID[identifier] = viewController;;
	
	UIPanGestureRecognizer *panGesture;
	panGesture = [MADQueryVisualizationViewController newGestureRecognizerPanPiece:self];
	
	[self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:panGesture];
	
	[viewController.view addGestureRecognizer:panGesture];
	[viewController willMoveToParentViewController:self];
	
	[self addChildViewController:viewController];
	
	[viewController beginAppearanceTransition:YES animated:YES];
	
	viewController.view.center = center;
	viewController.view.alpha = animated ? 0.0 : 1.0;
	[self.contentView addSubview: viewController.view];
	[self.contentView addConstraints: constraints.allValues];
	
	if (animated) {
		[UIView animateWithDuration:0.5 animations: ^{
			[viewController.view setAlpha:1.0];
		} completion:^(BOOL finished) {
			[viewController endAppearanceTransition];
			[viewController didMoveToParentViewController:self];
			completion();
		}];
	} else {
		[viewController endAppearanceTransition];
		[viewController didMoveToParentViewController:self];
		completion();
	}
}

#pragma mark Add Query Visualization Items

- (void)insertQueryTable:(NSNotification *)note {
	if (![note.name isEqualToString:MADNotificationQueryTableInsert]) return;

	MADModelQueryTable *insertedTable;
	NSEnumerator *insertedTables = note.userInfo.objectEnumerator;

	CGFloat contentViewHeight = self.contentView.bounds.size.height;
	for (insertedTable in insertedTables) {
		[self.rootTables addObject: insertedTable.objectID];
		
		MADQueryTableViewController *viewController;
		viewController = [MADQueryTableViewController newQueryTableViewController:insertedTable.identifier
																			 root:YES
																		 delegate:self
																		 document:self.document];
		viewController.view.translatesAutoresizingMaskIntoConstraints = NO;
		
		[self addViewController: viewController
						 center: MADPointInsertTable(contentViewHeight / 2, self.rootTables.count)
						   root: YES
					   animated: YES
					 completion: ^{ }];

	}
}

- (void)handleInsertQueryLink:(NSNotification *)note {
	if (![note.name isEqualToString:MADNotificationQueryLinkInsert]) return;

	MADHierarchicalChildController *leftTVC, *rightTVC;

	MADModelQueryLink *insertedLink;
	NSEnumerator <MADModelQueryLink *> *insertedLinks;
	insertedLinks = note.userInfo.objectEnumerator;
	NSNumber *leftFieldID, *rightFieldID;
	for (insertedLink in insertedLinks) {
		
		leftFieldID = @(insertedLink.leftFieldIdentifier.tableID);
		leftTVC = self.controllersByObjectID[leftFieldID];
		
		rightFieldID = @(insertedLink.rightFieldIdentifier.tableID);
		rightTVC = self.controllersByObjectID[rightFieldID];
		
		[self.rootTables removeObject: leftFieldID];
		
		if ([leftTVC isEqual:rightTVC] == NO) {
			[self addLinkViewControllerForQueryLinkModel: insertedLink
												animated: YES];
		}
	}
}

#pragma mark Remove Query Visualization Items

- (void)deleteQueryTable:(NSNotification *)note {
	if (![note.name isEqualToString:MADNotificationQueryTableDelete]) return;
	
	MADModelQueryTable *deletedTable;
	MADHierarchicalChildController *viewController;
	
	NSEnumerator *deletedTables = note.userInfo.objectEnumerator;
	for (deletedTable in deletedTables) {
		if ((viewController = self.controllersByObjectID[deletedTable.objectID])) {
			[viewController willMoveToParentViewController:nil];
			[viewController.view removeFromSuperview];
			[viewController removeFromParentViewController];
			[viewController didMoveToParentViewController:nil];
			[self.controllersByObjectID removeObjectForKey:deletedTable.objectID];
			//[self.view setNeedsLayout];
		}
	}
	//[self.view layoutIfNeeded];
}

- (void)deleteQueryLink:(NSNotification *)note {
	if (![note.name isEqualToString:MADNotificationQueryLinkDelete]) return;
	
	MADModelQuery *query = note.object;
	MADModelQueryLink *deletedLink;
	
	NSExpression *expressionMinusSet;
	NSExpression *evaluatedObject = [NSExpression expressionForEvaluatedObject];
	NSExpression *evaluatedJoinedTables;
	NSSet <NSNumber *> *orphaned;
	
	NSEnumerator *deletedLinks = note.userInfo.objectEnumerator;
	
	for (deletedLink in deletedLinks) {
		orphaned = [query orphanedQueryTables];
		
		evaluatedJoinedTables = [NSExpression expressionForConstantValue:orphaned];
		expressionMinusSet = [NSExpression expressionForMinusSet: evaluatedObject
															with: evaluatedJoinedTables];
		NSNumber *objectID;
		for (NSNumber *orphanedTableIDs in orphaned) {
			
			@autoreleasepool {
				objectID = orphanedTableIDs.copy;
				MADHierarchicalChildViewDefination *tableDefination;
				tableDefination = [self.cacheManager.cacheData tableDefinationForObjectID:orphanedTableIDs.longLongValue];
				tableDefination.root = YES;
				NSNumber *controllerID = @(orphanedTableIDs.longLongValue);
				MADHierarchicalChildController *tableController;
				tableController = self.controllersByObjectID[controllerID];
				tableController.root = YES;
				[self.rootTables addObject: objectID];
				objectID = nil;
			}
		}
		
		MADConnectorView *connectorView;
		connectorView = self.connectionViewsByObjectID[deletedLink.objectID];
		[self.connectionViewsByObjectID removeObjectForKey:deletedLink.objectID];
		[connectorView removeFromSuperview];
		//[self.view setNeedsLayout];
		//[self.view layoutIfNeeded];
//UILayoutConstraintAxisVertical
		//[self.view setNeedsLayout];
	}
	
	//[self.view layoutIfNeeded];
}

#pragma mark - Layout

- (void)didMoveFieldRect:(id)sender animated:(BOOL)animated {
	if ([sender isKindOfClass:[MADQueryTableViewController class]]) {
		
		MADQueryTableViewController *controller;
		
		NSEnumerator <MADModelQueryLink *> *links; MADModelQueryLink *link;
		controller = (MADQueryTableViewController *)sender;
		
		links = self.document.documentModel.firstQuery.links.objectEnumerator;
		
		for (link in links) {
			if (link.leftFieldIdentifier.tableID == controller.identifier ||
				link.rightFieldIdentifier.tableID == controller.identifier) {
				[self layoutQueryLinkViewControllerWithModelObject: link];
			}
		}
	}
}

- (void)layoutQueryLinkViewControllerWithModelObject:(MADModelQueryLink *)link {
 
	MADConnectorView *connectorView;

	connectorView = self.connectionViewsByObjectID[link.objectID];
	
	static const CGFloat padding = 44.0;

	CGFloat(^bottomLeftY)(CGRect) = ^CGFloat(CGRect rect) {
		return rect.origin.y + rect.size.height;
	};
	
	void(^translatePoint)(CGPoint *, CGFloat, CGFloat) = ^void(CGPoint *p, CGFloat translateHorizontal, CGFloat translateVertical) {
		(*p).x += translateHorizontal;
		(*p).y += translateVertical;
	};
	
	void(^repositionRect)(CGRect *, CGRect *, CGFloat) = ^void(CGRect *rectParent, CGRect *rectChild, CGFloat rectParentBottomY) {
		if ((*rectParent).origin.y + (*rectParent).size.height > rectParentBottomY) {
			(*rectParent) = CGRectMake((*rectParent).origin.x,
									   rectParentBottomY - (*rectParent).size.height,
									   (*rectParent).size.width,
									   (*rectParent).size.height);
		} else if ((*rectParent).origin.y < (*rectChild).origin.y) {
			(*rectParent) = CGRectMake((*rectParent).origin.x,
									   (*rectChild).origin.y,
									   (*rectParent).size.width,
									   (*rectParent).size.height);
		}
	};
	
	CGRect(^mainFrame)(CGPoint, CGPoint, CGFloat, CGFloat, CGFloat) =
	^ CGRect(CGPoint acl, CGPoint acr, CGFloat insete, CGFloat insets, CGFloat insetsY) {
		return CGRectMake(acl.x - insets - insete,
						  acl.y - insets - insetsY,
						  acr.x - acl.x + (insets * 2.0) + (insete * 2.0),
						  acr.y - acl.y + (insets * 2.0) + insetsY * 2.0);
	};
	
	BOOL(^updateAnchorPoints)(CGPoint *, CGFloat, CGPoint *, CGFloat, CGFloat *extraInset) =
	^ BOOL(CGPoint *leftPoint, CGFloat leftHeight, CGPoint *rightPoint,
		   CGFloat rightHeight, CGFloat *extraInset) {
		
		BOOL topLeftToBottomRight;
		if ((*leftPoint).x < (*rightPoint).x) {
			*extraInset = 0.0;
			if ((*leftPoint).y < (*rightPoint).y) {
				topLeftToBottomRight = YES;
			} else {
				topLeftToBottomRight = NO;
				(*leftPoint).y += leftHeight;
				(*rightPoint).y -= rightHeight;
			}
		} else {
			*extraInset = -20.0;
			if ((*leftPoint).y < (*rightPoint).y) {
				topLeftToBottomRight = NO;
			} else {
				topLeftToBottomRight = YES;
				(*leftPoint).y += leftHeight;
				(*rightPoint).y -= rightHeight;
			}
		}
		return topLeftToBottomRight;
	};
	
	CGRect leftCellFrameInTable, rightCellFrameInTable;
	CGFloat leftTableBottomY, rightTableBottomY;
	CGPoint leftCellAnchorPoint, rightCellAnchorPoint;
	
	MADHierarchicalChildController *leftTableViewController, *rightTableViewController;
	
	MADocument *document = self.document;
	MADModelDatabase *firstDatabase = document.documentModel.firstDatabase;
	MADModelQuery *firstQuery = firstDatabase.firstQuery;
	MADModelTable *rightTable, *leftTable;
	MADModelField *rightField, *leftField;
	MADModelQueryTable *rightQueryTable, *leftQueryTable;
	MADModelQueryField *rightQueryField, *leftQueryField;
	
	rightQueryTable = firstQuery.tables[link.rightTableObjectID];
	rightTable = firstDatabase.tableDictionary[rightQueryTable.schemaTableID];
	rightQueryField = rightQueryTable.queryFields[link.rightFieldObjectID];
	rightField = rightTable.fields[rightQueryField.schemaFieldID];
	rightTableViewController = self.controllersByObjectID[link.rightTableObjectID];
	rightCellFrameInTable = [rightTableViewController rectForFieldID: rightField.identifier
															  inView: rightTableViewController.view];

	leftQueryTable = firstQuery.tables[link.leftTableObjectID];
	leftTable = firstDatabase.tableDictionary[leftQueryTable.schemaTableID];
	leftQueryField = leftQueryTable.queryFields[link.leftFieldObjectID];
	leftField = leftTable.fields[leftQueryField.schemaFieldID];
	leftTableViewController = self.controllersByObjectID[link.leftTableObjectID];
	leftCellFrameInTable = [leftTableViewController rectForFieldID: leftField.identifier
															inView: leftTableViewController.view];
	
	leftTableBottomY = bottomLeftY(leftTableViewController.frame);
	
	CGRect leftTableViewControllerFrame = leftTableViewController.frame;
	repositionRect(&leftCellFrameInTable, &(leftTableViewControllerFrame), leftTableBottomY);
	CGRect convertedRect = [self.contentView convertRect: leftCellFrameInTable
												fromView: leftTableViewController.view];
	leftCellAnchorPoint = CGCenterOfRect(convertedRect);
	translatePoint(&leftCellAnchorPoint, padding, 0.0);
	rightTableBottomY = bottomLeftY(rightTableViewController.frame);

	CGRect rightTableViewControllerFrame = rightTableViewController.frame;
	repositionRect(&rightCellFrameInTable, &(rightTableViewControllerFrame), rightTableBottomY);
	
	convertedRect = [self.contentView convertRect: rightCellFrameInTable
										 fromView: rightTableViewController.view];
	rightCellAnchorPoint = CGCenterOfRect(convertedRect);
	translatePoint(&rightCellAnchorPoint, -padding, 0.0);
	
	connectorView.leftViewIsInital = directionHorizontal(leftCellAnchorPoint, rightCellAnchorPoint) == MADDirectionLeft;

	CGFloat extraInset = 0.0;
	connectorView.topLeftToBottomRight = updateAnchorPoints(&leftCellAnchorPoint,
															leftCellFrameInTable.size.height,
															&rightCellAnchorPoint,
															rightCellFrameInTable.size.height,
															&extraInset);
	connectorView.frame = mainFrame(leftCellAnchorPoint,
									rightCellAnchorPoint,
									extraInset, 0.0, 10.0);
	[connectorView setNeedsDisplay];
}

MADDirection directionHorizontal(CGPoint, CGPoint);
MADDirection directionHorizontal(CGPoint l, CGPoint r) {
	return l.x < r.x ? MADDirectionLeft : MADDirectionRight;
}

#pragma mark -
#pragma mark View Controller Container

- (void)removeViewController:(UIViewController *)viewController {
	[viewController willMoveToParentViewController:nil];
	[viewController.view removeFromSuperview];
	[viewController removeFromParentViewController];
	[viewController didMoveToParentViewController:nil];
	[self.view setNeedsLayout];
	[self.view layoutIfNeeded];
}

- (NSDictionary <NSString *, NSLayoutConstraint *> *)constraints:(MADHierarchicalChildController *)viewController
														  center:(CGPoint)center {
	NSLayoutConstraint *width, *height, *centerX, *centerY;
	width = [MADLayoutConstraint newLayoutConstraint: viewController.view
											   width: viewController.preferredContentSize.width];
	height = [MADLayoutConstraint newLayoutConstraint: viewController.view
											   height: viewController.preferredContentSize.height];
	centerX = [MADLayoutConstraint newLayoutConstraint: viewController.view
												toView: self.contentView
											   centerX: center.x];
	
	centerY = [MADLayoutConstraint newLayoutConstraint: viewController.view
												toView: self.contentView
											   centerY: center.y];
	
	NSDictionary <NSString *, NSLayoutConstraint *> *constraints;
	constraints = [[NSDictionary alloc] initWithObjectsAndKeys:
				   centerX, keyCenterX, centerY, keyCenterY,
				   width, keyWidth, height, keyHeight, nil];
	return constraints;
}

+ (UIPanGestureRecognizer *)newGestureRecognizerPanPiece:(id <UIGestureRecognizerDelegate>)delegate {
	UIPanGestureRecognizer *panGesture;
	panGesture = [[UIPanGestureRecognizer alloc] initWithTarget: delegate
														 action: @selector(handlePanPiece:)];
	panGesture.delegate = delegate;
	return panGesture;
}

#pragma mark -
#pragma mark Adding Child View Controllers

- (void)addLinkViewControllerForQueryLinkModel:(MADModelQueryLink *)link
									  animated:(BOOL)animated {
	MADConnectorView *connectorView = [[MADConnectorView alloc] initWithFrame:CGRectZero];
	connectorView.userInteractionEnabled = NO;
	connectorView.identifier = link.identifier;
	connectorView.autoresizesSubviews = NO;
	connectorView.translatesAutoresizingMaskIntoConstraints = NO;

	CGRect desiredFrame = connectorView.frame;
	CGPoint desiredCenter = connectorView.center;
	CGAffineTransform desiredTransform = connectorView.transform;
	
	connectorView.bounds = CGRectZero;
	connectorView.center = desiredCenter;
	if (animated) {
		connectorView.transform = animated ? CGAffineTransformIdentity : MADAffineTransformSwing();
	}
	
	self.connectionViewsByObjectID[link.objectID] = connectorView;
	
	if (!animated) {
		[self layoutQueryLinkViewControllerWithModelObject:link];
	}
	
	[self.contentView addSubview:connectorView];
	
	MTBlockResultVoid animateTwo = ^() {
		connectorView.frame = desiredFrame;
		connectorView.transform = desiredTransform;
	};
	
	if (animated) {
		
		CGFloat animationDuration = 0.3;
		[UIView animateWithDuration: animationDuration
							  delay: 0.0
							options: UIViewAnimationOptionCurveEaseInOut
						 animations: animateTwo
						 completion: ^(BOOL finished) { }];
	}
	
	if (animated) {
		[self layoutQueryLinkViewControllerWithModelObject:link];
	}
}

@end
