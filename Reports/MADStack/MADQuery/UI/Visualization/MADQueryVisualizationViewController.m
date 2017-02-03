//
//  MTQueryBuilderAdvancedViewController.m
//  Reports
//
//  Created by Michael Thomason on 2/14/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryVisualizationViewController.h"

#import <UIKit/UIWindow.h>
#import <UIKit/UIView.h>
#import <UIKit/UITableView.h>
#import <UIKit/UIToolbar.h>

#import <UIKit/UIManagedDocument.h>
#import <UIKit/UIStoryboard.h>
#import <UIKit/UIPopoverController.h>
#import <UIKit/UIPanGestureRecognizer.h>

#import <QuartzCore/CALayer.h>

#import <Foundation/NSSet.h>

#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSManagedObjectID.h>

#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADAppDelegate.h>
#import <MADFoundation/MADApplicationProtocol.h>

#import <MADDataStructures/MTPair.h>
#import <MADDataStructures/MTVertex.h>
#import <MADDataStructures/MTLinkedList.h>

#import <MADFoundation/MADApplicationProtocol.h>
#import <MADFoundation/UIScreen+Properties.h>

#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import <MADFoundation/MADURL.h>

#import <MAD/MADConstants.h>

#import <MAD/MADocument.h>

#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>

#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabase+Extras.h>

#import <MAD/RptqQuery.h>
#import <MAD/RptqQuery+Extras.h>

#import <MAD/RptqQueryLinks.h>
#import <MAD/RptqQueryLinks+Extras.h>

#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryField+Extras.h>

#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryTable+Extras.h>

#import <MAD/MADModel.h>
#import <MAD/MADModelDocument.h>
#import <MAD/MADModelDatabase.h>

#import "MUIViewControllerDelegate.h"

#import "MADViewControllerSQL.h"
#import "MADConnectorView.h"

#import "MADQueryVisualizationSchemaViewController.h"

#import "CGAffineTransform+Common.h"

#import "NSLayoutConstraint+QueryVisualization.h"
#import "MADHierarchicalChildViewDefination.h"

#import "MADQueryVisualizationDefination.h"
#import "MADHierarchicalDisplayModel.h"

#import "MADOperationArchiveData.h"

#import "UIGestureRecognizer+AnchorPoint.h"

#import "MADQueryVisualizationSchemaPresentationController.h"

#import "MADQueryVisualizationSchemaAnimatedTransitioning.h"
#import "MADQueryVisualizationContentView.h"
#import "MADQueryVisualizationScrollView.h"

#import "MADOperationQueue.h"

#import "MADCacheManager.h"
#import "MADQueryVisualizationSchemaView.h"

typedef void(^MTBlockResultVoid)(void);

typedef UIViewController <MADManagedObjectViewProtocol, MADHierarchicalGroupingNodeProtocol> MADHierarchicalChildController;
typedef NSMutableDictionary <NSManagedObjectID *,
                             MADHierarchicalChildController *> MADMutableMapHierarchicalChildControllers;

@interface MADQueryVisualizationViewController ()
    <UIGestureRecognizerDelegate,
        UIScrollViewDelegate,
        UIPopoverControllerDelegate,
        MADQueryVisualizationSchemaPresentationDelegate,
        MADQueryVisualizationSchemaDelegate,
        MADViewControllerStandardProtocol>

    @property (nonatomic, strong) MADMutableMapHierarchicalChildControllers *controllersByObjectID;
    @property (nonatomic, strong) NSMutableDictionary <NSManagedObjectID *, MADConnectorView *> *connectionViewsByObjectID;
    @property (nonatomic, strong) NSMutableDictionary <NSManagedObjectID *, NSDictionary <NSString *, NSLayoutConstraint *> *> *constraints;
    @property (nonatomic, strong) NSMutableSet <NSManagedObjectID *> *rootTables;

    @property (nonatomic, weak) IBOutlet UIView *backgroundContainer;

    @property (nonatomic, strong) MADHierarchicalDisplayModel *cacheData;
    @property (nonatomic, strong) MADQueryVisualizationScrollView *scrollView;

    @property (nonatomic, copy) NSURL *localCacheFileURL;

@end

@implementation MADQueryVisualizationViewController

@synthesize document = _document;

#pragma mark -
#pragma mark Static functions and keys

static const CGFloat MADSchemaViewDefaultWidth = 120.0000f;
static const CGFloat MADSchemaViewDefaultHeight = 140.0000f;

static NSString *keyCenterX = @"x";
static NSString *keyCenterY = @"y";
static NSString *keyWidth   = @"w";
static NSString *keyHeight  = @"h";

static inline CGPoint MADPointInsertTable(CGFloat, NSUInteger);
static inline CGPoint MADPointInsertTable(CGFloat viewHeight, NSUInteger tableCount) {
    return CGPointMake(CGPointZero.x + 500, viewHeight / (tableCount + 2) * (tableCount + 1));
}

+ (instancetype)newQueryVisualizationViewController:(MADocument *)document {
    UIStoryboard *storyboard;
    id controller;
    storyboard = [UIStoryboard storyboardWithName: [self identifierStoryboard]
                                           bundle: [NSBundle mainBundle]];
    controller = [storyboard instantiateViewControllerWithIdentifier: [self identifierController]];
    [controller setDocument: document];
    return controller;
}

+ (NSString *)identifierStoryboard {
    return @"MADQuery";
}

+ (NSString *)identifierController {
    return @"MADStoryboardIDQueryVisulization";
}

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
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
        _controllersByObjectID = controllersByObjectID;
        
        NSMutableDictionary <NSManagedObjectID *, __kindof MADConnectorView *> *connectionViewsByObjectID;
        connectionViewsByObjectID = [[NSMutableDictionary alloc] init];
        _connectionViewsByObjectID = connectionViewsByObjectID;
        
        NSMutableSet <NSManagedObjectID *> *rootTables = [[NSMutableSet alloc] init];
        _rootTables = rootTables;
        
        NSMutableDictionary <NSManagedObjectID *, NSDictionary <NSString *, NSLayoutConstraint *> *> *constraints;
        constraints = [[NSMutableDictionary alloc] init];
        _constraints = constraints;
        
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

    if (!CGSizeEqualToSize(size, self.view.bounds.size)) {
        
        for (UIViewController *subviewController in self.childViewControllers) {
        
            [self didMoveFieldRect: subviewController animated: YES];
            
        }
        
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        
            [self.view setNeedsDisplay];
            
        } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) { }];
        
    }
}

#pragma mark -
#pragma mark MADQueryVisualizationSchemaPresentationDelegate

- (CGRect)frameOfItemWithObjectID:(NSManagedObjectID *)objectID {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    MADHierarchicalChildViewDefination *tableDefination = [self.cacheData tableDefinationForObjectID:objectID];
    CGRect result = CGRectMake(tableDefination.center.x - MADSchemaViewDefaultWidth / 2,
                               tableDefination.center.y - MADSchemaViewDefaultHeight / 2,
                               MADSchemaViewDefaultWidth,
                               MADSchemaViewDefaultHeight);
    return result;
}

- (void)setDocument:(MADocument *)document {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (document != nil && _document != document) {
        _document = document;
    }
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.definesPresentationContext = YES;
    
    self.backgroundContainer.layer.borderWidth = [UIScreen mainScreen].isRetnaDisplay ? 0.5000f : 1.0000f;
    self.backgroundContainer.backgroundColor = [UIColor clearColor];
    self.backgroundContainer.opaque = NO;
    self.backgroundContainer.autoresizesSubviews = NO;
    self.view.opaque = YES;
    
    MADQueryVisualizationScrollView *scrollView;
    scrollView = [[MADQueryVisualizationScrollView alloc] initWithFrame:self.backgroundContainer.bounds];
    scrollView.delegate = self;
    scrollView.backgroundColor = [[UIColor groupTableViewBackgroundColor] colorWithAlphaComponent:.02f];
    scrollView.opaque = NO;
    scrollView.autoresizesSubviews = NO;
    [self.backgroundContainer addSubview:scrollView];
    
    NSDictionary <NSString *, __kindof UIView *> *viewDictionary;
    viewDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:scrollView, @"sv",
                                                                  _backgroundContainer, @"bg", nil];
    
    NSMutableArray <__kindof NSLayoutConstraint *> *constraints;
    constraints = [[NSMutableArray alloc] init];

    NSArray <__kindof NSLayoutConstraint *> * constraintGroup;
    constraintGroup = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bg]|"
                                                              options:0
                                                              metrics:0
                                                                views:viewDictionary];
    [constraints addObjectsFromArray:constraintGroup];
    
    constraintGroup = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[bg]|"
                                                              options:0
                                                              metrics:0
                                                                views:viewDictionary];
    [constraints addObjectsFromArray:constraintGroup];
    
    [self.view addConstraints:constraints];

    [constraints removeAllObjects];
    
    constraintGroup = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[sv]|"
                                                              options:0
                                                              metrics:0
                                                                views:viewDictionary];
    [constraints addObjectsFromArray:constraintGroup];

    constraintGroup = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[sv]|"
                                                              options:0
                                                              metrics:0
                                                                views:viewDictionary];
    [constraints addObjectsFromArray:constraintGroup];

    [self.backgroundContainer addConstraints:constraints];
    
    [constraints removeAllObjects];
    
    
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
                                             selector: @selector(insertQueryLink:)
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
    
    [self archiveCache];
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
    self.scrollView.scrollIndicatorInsets =
        UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width,
                         self.bottomLayoutGuide.length, CGSizeZero.height);
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
        if ([childContoller isKindOfClass:[MADQueryVisualizationSchemaViewController class]]) {

            MADHierarchicalChildViewDefination *tableDefination;
            tableDefination = [self.cacheData tableDefinationForObjectID:((MADHierarchicalChildController *)childContoller).objectIdTag];
            if (tableDefination == nil) {
                tableDefination = [MADHierarchicalChildViewDefination newTableDefination];
                
                tableDefination.center = CGCenterRect(self.scrollView.bounds);

                [self.cacheData addTableDefination: tableDefination
                                       forObjectID: ((MADHierarchicalChildController *)childContoller).objectIdTag];
            }
            
            if (tableDefination.root) {
                NSManagedObjectID *objectID;
                objectID = ((MADHierarchicalChildController *)childContoller).objectIdTag.copy;
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
    NSLog(@"%s", __PRETTY_FUNCTION__);

    NSEnumerator <MADModelQueryLink *> *queryLinkEnumerator;
    queryLinkEnumerator = self.document.documentModel.firstQuery.links.objectEnumerator;
    for (MADModelQueryLink *link in queryLinkEnumerator) {
        [self layoutQueryLinkViewControllerWithModelObject:link];
    }
    [self.view setNeedsLayout];
}

#pragma mark -
#pragma mark NSManagedObjectContext Observer

- (void)managedObjectContextWillSave:(NSNotification *)notification { }

- (void)managedObjectContextDidSave:(NSNotification *)notification {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    NSArray *insertedObjects = notification.userInfo[NSInsertedObjectsKey];
    NSArray *updatedObjects = notification.userInfo[NSUpdatedObjectsKey];
    NSArray *deletedObjects = notification.userInfo[NSDeletedObjectsKey];
    
    RptqQuery *updatedQuery = nil;
    BOOL needsLayout = NO;
    
#pragma mark Handle inserted objects
    
    CGFloat height;
    NSUInteger rootTableCount;

    if (updatedObjects.count) {

        NSMutableArray *updatedTables;
        updatedTables = [[NSMutableArray alloc] initWithCapacity:updatedObjects.count];

        /*for (const id updatedObject in updatedObjects) {
            
            if ([updatedObject isKindOfClass:[RptqQueryTable class]]) {
                [updatedTables addObject:updatedObject];
        
            } else if ([updatedObject isKindOfClass:[RptqQuery class]]) {
                updatedQuery = updatedObject;
            }
        }

        if (updatedQuery && updatedTables.count > 0) {
            
            MADQueryVisualizationSchemaViewController *updatedItem;

            for (RptqQueryTable *updatedTable in updatedTables) {
                if (![updatedTable.inQuery.objectID isEqual:updatedQuery.objectID]) {

                    //Table was remvoed from query... so remove it from screen.
                    updatedItem = self.controllersByObjectID[updatedTable.objectID];
                    
                    if (updatedItem != nil) {
                        
                        [self.rootTables removeObject:updatedTable.objectID];
                        [self.cacheData removeTableDefinationForObjectID:updatedTable.objectID];
                        [self removeViewController:updatedItem];
                        
                        for (RptqQueryLinks *link in updatedQuery.hasQueryLinks) {
                            if ([link.hasLeftField.inQueryTable.objectID isEqual: updatedTable.objectID] ||
                                [link.hasRightField.inQueryTable.objectID isEqual: updatedTable.objectID]) {
                                
                                MADConnectorView *connectorView = self.connectionViewsByObjectID[link.objectID];
                                [connectorView removeFromSuperview];
                                
                                [self.view setNeedsLayout];
                            }
                        }
                        needsLayout = YES;
                        
                    }
                }
            }
        }*/
    }
    
#pragma mark Handle deleted objects
    
    //for (id deletedObject in deletedObjects) {
    //    if ([deletedObject isKindOfClass:[RptqQueryTable class]]) {
    //        [self deleteQueryTable:deletedObject];
    //        [self.view setNeedsLayout];
    //    }
    //}

    //[self.view layoutIfNeeded];
}

#pragma mark -
#pragma mark MADViewControllerStandardProtocol

- (void)viewControllerDidFinish:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self dismissViewControllerAnimated:YES completion:^{ }];
}

#pragma mark -
#pragma mark Cache Operations

- (void)updateCache {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    MADocument *doc = self.document;
    if (doc != nil) {
        
        MADQueryVisualizationDefination *queryDef;
        MTLinkedList *topologicallySortedTables;
        MADHierarchicalDisplayModel *cacheData;
        
        NSManagedObjectID *tableID;
        MADHierarchicalChildController *schemaController;
        MADHierarchicalChildViewDefination *tableModel;
        NSArray <NSURL *> *startingPoints;

        MTVertex *tableIDVertext;
        
        queryDef= [[MADQueryVisualizationDefination alloc] initWithQuery:doc.documentModel.firstQuery];
        topologicallySortedTables = queryDef.topologicallySortedTables;

        cacheData = [[MADHierarchicalDisplayModel alloc] initWithNumberOfTables:[topologicallySortedTables count]];
        cacheData.scrollViewContentOffset = self.scrollView.contentOffset;
        cacheData.scrollViewZoomScale = self.scrollView.zoomScale;
        
        for (MTPair *pair in queryDef.topologicallySortedTables) {

            tableIDVertext = (MTVertex *)pair.former;
            if (tableIDVertext.object != nil) {
                
                tableID = (NSManagedObjectID *)tableIDVertext.object;
                schemaController = self.controllersByObjectID[tableID];
                
                tableModel = [[MADHierarchicalChildViewDefination alloc] init];
                tableModel.center = schemaController.view.center;
                
                startingPoints = queryDef.startingPoints;
                tableModel.root = [startingPoints containsObject: tableID.URIRepresentation];
                [cacheData addTableDefination:tableModel forObjectID:tableID];
            }
        }
        self.cacheData = cacheData;
    }
}

- (void)archiveCache {
    [self updateCache];
    MADOperationArchiveData *operation;
    operation = [[MADOperationArchiveData alloc] initWithURL: self.localCacheFileURL
                                                   andObject: self.cacheData];
    [[MADCacheManager sharedManager] addOperation:operation];
}

- (MADHierarchicalDisplayModel *)loadCache {
    
    MADHierarchicalDisplayModel *result;
    NSError * _Nullable __autoreleasing * _Nullable error = nil;
    NSData *data;
    data = [[NSData alloc] initWithContentsOfURL: self.localCacheFileURL
                                         options: NSDataReadingUncached error:error];
    if (error != nil) {
    
        [[NSFileManager defaultManager] removeItemAtURL:self.localCacheFileURL error:error];
        result = nil;

    } else {
        
        id resultFromTryBlock = nil;
        @try {
        
            resultFromTryBlock = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        } @catch (NSException *exception) {

            NSError *cleanup = nil;
            [[NSFileManager defaultManager] removeItemAtURL:self.localCacheFileURL error:&cleanup];
        
        } @finally {
            
            if ([resultFromTryBlock isKindOfClass:[MADHierarchicalDisplayModel class]]) {
                result = resultFromTryBlock;
            } else {
                [[NSFileManager defaultManager] removeItemAtURL:self.localCacheFileURL error:error];
                result = nil;
            }
            
        }
    }
    return result;
}

- (NSString *)cacheFileName {
    return [MADQueryVisualizationViewController cacheFileNameForDocument:self.document];
}

- (NSURL *)localCacheFileURL {
    if (_localCacheFileURL == nil) {
        MADAppDelegate delegate = [MADApplication AppDelegate];
        NSString *groupIdentifier = [delegate groupIdentifier].copy;
        NSURL *url;
        NSString *cacheFileName = [self cacheFileName];
        url = [MADURL newURLForLocalCacheDirectoryForGroupIdentifier:groupIdentifier];
        url = [url URLByAppendingPathComponent: cacheFileName
                                   isDirectory: NO];
        _localCacheFileURL = url.copy;
    }
    return _localCacheFileURL;
}

+ (NSString *)cacheFileNameForDocument:(MADocument *)document {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    return [MADHierarchicalDisplayModel cacheFileNameForFileName:document.fileURL.lastPathComponent.stringByDeletingPathExtension];
}

#pragma mark -
#pragma mark Gesture recognizer actions

- (void)handlePanPiece:(UIPanGestureRecognizer *)gestureRecognizer {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSManagedObjectID *tableID;
    tableID = ((MADQueryVisualizationSchemaView *)gestureRecognizer.view).objectIdTag;
    NSAssert(tableID != nil, @"We expect an ID");
    if (!tableID) return;
    
    [UIGestureRecognizer adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    
    UIWindow *window = [UIApplication sharedApplication].windows[0];
    NSDictionary <NSString *, NSLayoutConstraint *> *constraints;
    constraints = [_constraints objectForKey: tableID];
    CGPoint pointInView = [window convertPoint: [gestureRecognizer locationInView:window]
                                        toView: self.scrollView.contentView];
    constraints[keyCenterX].constant = pointInView.x;
    constraints[keyCenterY].constant = pointInView.y;

    [self didMoveFieldRect: self.controllersByObjectID[tableID]
                  animated: NO];
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        
        if (!_cacheData) {
            [self updateCache];
        } else {
            MADHierarchicalChildViewDefination *tableDefination;
            tableDefination = [_cacheData tableDefinationForObjectID:tableID];
            tableDefination.center = pointInView;
        }
    }
}

#pragma mark -
#pragma mark Change UI on IR Diagram

- (void)clearScreen {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    for (UIViewController *viewController in self.childViewControllers) {
        [self removeViewController:viewController];
    }
    for (UIView *subview in self.scrollView.contentView.subviews) {
        [subview removeFromSuperview];
    }
}

#pragma mark -
#pragma mark Reload document view controllers

- (void)redraw:(BOOL)animated {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    [self clearScreen];
    [self.rootTables removeAllObjects];
    [self.controllersByObjectID removeAllObjects];
    [self.connectionViewsByObjectID removeAllObjects];
    
    MADModelQuery *query;
    MADModelDocument *document;
    MADHierarchicalDisplayModel *cacheData;
    
    MADQueryVisualizationDefination *queryDef;
    MTLinkedList *topologicallySortedTables;
    NSManagedObjectContext *managedObjectContext;
    NSEnumerator <MADModelQueryLink *> *queryLinkEnumerator;
    NSString *path;

    document = _document.documentModel;
    query = document.databases.firstObject.queries.firstObject;
    
    path = self.localCacheFileURL.filePathURL.path;
    if (path != nil && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
        cacheData = [self loadCache];
    }
    
    if (cacheData) {
        self.scrollView.contentOffset = cacheData.scrollViewContentOffset;
        self.scrollView.zoomScale = cacheData.scrollViewZoomScale;
    }
    
    queryDef = [[MADQueryVisualizationDefination alloc] initWithQuery:query];
    topologicallySortedTables = queryDef.topologicallySortedTables;
    managedObjectContext = document.managedObjectContext;
    
    queryLinkEnumerator = query.links.objectEnumerator;
    for (MADModelQueryLink *link in queryLinkEnumerator) {
        [self addLinkViewControllerForQueryLinkModel:link animated:YES];
    }
    
    BOOL topLevel;
    MTVertex *tableIdVertext;
    RptqQueryTable *table;
    NSManagedObjectID *objectID;
    MADHierarchicalChildViewDefination *tableDef;
    
    typeof(self) __weak wself = self;
    
    for (MTPair *pair in topologicallySortedTables) {

        tableIdVertext = pair.former;

        if (tableIdVertext.object != nil) {
            
            table = (RptqQueryTable *)[managedObjectContext objectWithID:tableIdVertext.object];
            objectID = table.objectID.copy;

            topLevel = [queryDef.startingPoints containsObject: objectID.URIRepresentation];
            
            if (topLevel) [self.rootTables addObject: objectID];
            
            tableDef = cacheData != nil ? [cacheData tableDefinationForObjectID:objectID] : nil;
            
            [self addSchemaViewControllerForTableID: objectID
                                             center: tableDef ? tableDef.center : self.scrollView.contentView.center
                                               root: topLevel
                                           animated: animated
                                         completion: ^{
                                             
                                             //Layout Query View if Related to Table
                                             typeof(self) sself = wself;
                                             NSEnumerator <MADModelQueryLink *> *queryLinks = query.links.objectEnumerator;
                                             for (MADModelQueryLink *link in queryLinks) {
                                                 if (link.leftFieldReference.tableID == objectID ||
                                                     link.rightFieldReference.tableID == objectID) {
                                                     [sself layoutQueryLinkViewControllerWithModelObject:link];
                                                 }
                                             }
                                             
                                             NSEnumerator <MADConnectorView *> *views = sself.connectionViewsByObjectID.objectEnumerator;
                                             for (UIView *view in views) {
                                                 [sself.scrollView.contentView bringSubviewToFront:view];
                                             }
                                         }];
        }
    }
}

#pragma mark -
#pragma mark MADModel Notification Handlers

- (void)insertQueryTable:(NSNotification *)note {
    
    NSLog(@"%s", __PRETTY_FUNCTION__);

    if (![note.name isEqualToString:MADNotificationQueryTableInsert]) return;

    MADModelQueryTable *insertedTable;
    NSEnumerator *insertedTables = note.userInfo.objectEnumerator;

    for (insertedTable in insertedTables) {
        NSManagedObjectID *objectID = insertedTable.objectID.copy;
        [self.rootTables addObject: objectID];
        [self addSchemaViewControllerForTableID: objectID
                                         center: MADPointInsertTable(self.scrollView.contentView.bounds.size.height,
                                                                     self.rootTables.count)
                                           root: YES
                                       animated: YES completion:^{
                                           
                                       }];
    }
    
}

- (void)insertQueryLink:(NSNotification *)note {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    if (![note.name isEqualToString:MADNotificationQueryLinkInsert]) return;

    MADHierarchicalChildController *leftTVC, *rightTVC;

    MADModelQueryLink *insertedLink;
    NSEnumerator <MADModelQueryLink *> *insertedLinks;
    insertedLinks = note.userInfo.objectEnumerator;
    for (insertedLink in insertedLinks) {

        leftTVC = self.controllersByObjectID[insertedLink.leftFieldReference.tableID];
        rightTVC = self.controllersByObjectID[insertedLink.rightFieldReference.tableID];
        
        [self.rootTables removeObject: insertedLink.leftFieldReference.tableID];
        
        if ([leftTVC isEqual:rightTVC] == NO) {
            [self addLinkViewControllerForQueryLinkModel: insertedLink
                                                animated: YES];
        }

    }
}

- (void)deleteQueryTable:(NSNotification *)note {

    NSLog(@"%s", __PRETTY_FUNCTION__);

    if (![note.name isEqualToString:MADNotificationQueryLinkDelete]) return;
    
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

    NSLog(@"%s", __PRETTY_FUNCTION__);

    if (![note.name isEqualToString:MADNotificationQueryLinkDelete]) return;
    
    MADModelQuery *query = note.object;
    MADModelQueryLink *deletedLink;
    
    NSExpression *expressionMinusSet;
    NSExpression *evaluatedObject = [NSExpression expressionForEvaluatedObject];
    NSExpression *evaluatedJoinedTables;
    NSSet <NSManagedObjectID *> *orphaned;
    
    NSEnumerator *deletedLinks = note.userInfo.objectEnumerator;
    
    for (deletedLink in deletedLinks) {
        orphaned = [query orphanedQueryTables];
        
        evaluatedJoinedTables = [NSExpression expressionForConstantValue:orphaned];
        expressionMinusSet = [NSExpression expressionForMinusSet: evaluatedObject
                                                            with: evaluatedJoinedTables];
        //NSLog(@"%@", orphaned);
        NSManagedObjectID *objectID;
        for (NSManagedObjectID *orphanedTableIDs in orphaned) {
            
            @autoreleasepool {
                objectID = orphanedTableIDs.copy;
                MADHierarchicalChildViewDefination *tableDefination;
                tableDefination = [self.cacheData tableDefinationForObjectID:objectID];
                if (tableDefination == nil) {
                    NSLog(@"Break\n\n");
                }
                tableDefination.root = YES;
                [self.rootTables addObject: objectID];
                objectID = nil;
            }
        }
        
        MADConnectorView *connectorView;
        connectorView = self.connectionViewsByObjectID[deletedLink.objectID];
        [self.connectionViewsByObjectID removeObjectForKey:deletedLink.objectID];
        [connectorView removeFromSuperview];
        NSLog(@"Deleted %@", deletedLink.objectID);
        //[self.view setNeedsLayout];
        //[self.view layoutIfNeeded];
//UILayoutConstraintAxisVertical
        //[self.view setNeedsLayout];
    }
    
    //[self.view layoutIfNeeded];
}

#pragma mark -
#pragma mark View Controller Container Data

- (void)removeViewController:(UIViewController *)viewController {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [viewController willMoveToParentViewController:nil];
    [viewController.view removeFromSuperview];
    [viewController removeFromParentViewController];
    [viewController didMoveToParentViewController:nil];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (void)addViewController:(MADHierarchicalChildController *)viewController
                   center:(CGPoint)center
                     root:(BOOL)root
                 animated:(BOOL)animated
               completion:(void(^)(void))completion {

    NSLayoutConstraint *width, *height;
    width = [NSLayoutConstraint newLayoutConstraintWidthForView: viewController.view
                                                       andWidth: MADSchemaViewDefaultWidth];
    height = [NSLayoutConstraint newLayoutConstraintHeightForView: viewController.view
                                                        andHeight: MADSchemaViewDefaultHeight];
    
    NSLayoutConstraint *centerX, *centerY;
    centerX = [NSLayoutConstraint constraintWithItem: viewController.view
                                           attribute: NSLayoutAttributeCenterX
                                           relatedBy: NSLayoutRelationEqual
                                              toItem: self.scrollView.contentView
                                           attribute: NSLayoutAttributeLeftMargin
                                          multiplier: 1.0000f
                                            constant: center.x];
    
    centerY = [NSLayoutConstraint constraintWithItem: viewController.view
                                           attribute: NSLayoutAttributeCenterY
                                           relatedBy: NSLayoutRelationEqual
                                              toItem: self.scrollView.contentView
                                           attribute: NSLayoutAttributeTopMargin
                                          multiplier: 1.0000f
                                            constant: center.y];
    
    NSDictionary <NSString *, NSLayoutConstraint *> *constraints;
    constraints = [[NSDictionary alloc] initWithObjectsAndKeys:
                   centerX, keyCenterX, centerY, keyCenterY,
                   width, keyWidth, height, keyHeight, nil];
    
    [_constraints setObject:constraints forKey:viewController.objectIdTag];
    viewController.root = root;

    self.controllersByObjectID[viewController.objectIdTag] = viewController;;

    UIPanGestureRecognizer *panGesture;
    panGesture = [[UIPanGestureRecognizer alloc] initWithTarget: self
                                                         action: @selector(handlePanPiece:)];
    panGesture.delegate = self;
    [self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:panGesture];
    [viewController.view addGestureRecognizer:panGesture];
    
    [viewController willMoveToParentViewController:self];
    [self addChildViewController:viewController];

    [viewController beginAppearanceTransition:YES animated:YES];
    
    viewController.view.center = center;
    viewController.view.alpha = 0.00000f;
    [self.scrollView.contentView addSubview: viewController.view];
    [self.scrollView.contentView addConstraints: constraints.allValues];

    [UIView animateWithDuration:.5 animations: ^{
        [viewController.view setAlpha:1.0];
    } completion:^(BOOL finished) {
        if (finished) {
            [viewController endAppearanceTransition];
            [viewController didMoveToParentViewController:self];
            completion();
        }
    }];
    [viewController didMoveToParentViewController:self];
}

- (void)addSchemaViewControllerForTableID:(NSManagedObjectID *)tableID
                                   center:(CGPoint)center
                                     root:(BOOL)root
                                 animated:(BOOL)animated
                               completion:(void(^)(void))completion {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    MADQueryVisualizationSchemaViewController *viewController;
    viewController = [MADQueryVisualizationSchemaViewController newQueryVisualizationSchemaViewController];
    viewController.document = self.document;
    viewController.delegate = self;
    viewController.objectIdTag = tableID.copy;
    viewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addViewController: viewController
                     center: center
                       root: root
                   animated: animated
                 completion: completion];

}

- (void)addLinkViewControllerForQueryLinkModel:(MADModelQueryLink *)link
                                      animated:(BOOL)animated {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    MADConnectorView *connectorView = [[MADConnectorView alloc] initWithFrame:CGRectZero];
    connectorView.userInteractionEnabled = NO;
    connectorView.objectIdTag = link.objectID.copy;
    connectorView.autoresizesSubviews = NO;
    connectorView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.connectionViewsByObjectID[link.objectID] = connectorView;
    
    if (animated == NO) {
        [self layoutQueryLinkViewControllerWithModelObject:link];
    }
    
    CGRect desiredFrame = connectorView.frame;
    CGPoint desiredCenter = connectorView.center;
    CGAffineTransform desiredTransform = connectorView.transform;
    
    connectorView.bounds = CGRectZero;
    connectorView.center = desiredCenter;
    if (animated) {
        connectorView.transform = animated ? CGAffineTransformIdentity : MADAffineTransformSwing();
    }
    
    [self.scrollView.contentView addSubview:connectorView];
    
    MTBlockResultVoid animateTwo = ^() {
        connectorView.frame = desiredFrame;
        connectorView.transform = desiredTransform;
    };
    
    if (animated) {
        
        CGFloat animationDuration = 0.3000f;
        [UIView animateWithDuration: animationDuration
                              delay: 0.0000f
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations: animateTwo
                         completion: ^(BOOL finished) {
                         
                         }];
    } else {
        animateTwo();
    }
    
    if (animated) {
        [self layoutQueryLinkViewControllerWithModelObject:link];
    }
}

#pragma mark - Layout

- (void)didMoveFieldRect:(id)sender animated:(BOOL)animated {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    if ([sender isKindOfClass:[MADQueryVisualizationSchemaViewController class]]) {
        
        MADQueryVisualizationSchemaViewController *controller;
        
        NSEnumerator <MADModelQueryLink *> *links; MADModelQueryLink *link;
        controller = (MADQueryVisualizationSchemaViewController *)sender;
        
        links = self.document.documentModel.firstQuery.links.objectEnumerator;
        
        for (link in links) {
            if ([link.leftFieldReference.tableID isEqual: controller.objectIdTag] ||
                [link.rightFieldReference.tableID isEqual: controller.objectIdTag]) {
                [self layoutQueryLinkViewControllerWithModelObject: link];
            }
        }
    }
}

- (void)layoutQueryLinkViewControllerWithModelObject:(MADModelQueryLink *)link {
 
    MADConnectorView *connectorView;
    //if (!(connectorView = self.connectionViewsByObjectID[queryLinkID])) return;
    connectorView = self.connectionViewsByObjectID[link.objectID];
    
    const CGFloat paddingLeft = 44.0000f;

    CGFloat(^bottomLeftY)(CGRect) = ^CGFloat(CGRect rect) {
        return rect.origin.y + rect.size.height;
    };
    
    void(^translatePoint)(CGPoint *, CGFloat, CGFloat) = ^void(CGPoint *p, CGFloat translateHorizontal, CGFloat translateVertical) {
        (*p).x += translateHorizontal;
        (*p).y += translateVertical;
    };
    
    void(^repositionRect)(CGRect *, CGRect *, CGFloat) = ^void(CGRect *rectParent, CGRect *rectChild, CGFloat rectParentBottomY) {
        if ((*rectParent).origin.y + (*rectParent).size.height > rectParentBottomY) {
            (*rectParent) = CGRectMake((*rectParent).origin.x, rectParentBottomY - (*rectParent).size.height, (*rectParent).size.width, (*rectParent).size.height);
        } else if ((*rectParent).origin.y < (*rectChild).origin.y) {
            (*rectParent) = CGRectMake((*rectParent).origin.x, (*rectChild).origin.y, (*rectParent).size.width, (*rectParent).size.height);
        }
    };
    
    CGRect(^mainFrame)(CGPoint, CGPoint, CGFloat, CGFloat) =
    ^ CGRect(CGPoint acl, CGPoint acr, CGFloat insete, CGFloat insets) {
        return CGRectMake(acl.x - insets - insete,
                          acl.y - insets,
                          acr.x - acl.x + (insets*2) + (insete * 2.0000f),
                          acr.y - acl.y + (insets*2));
    };
    
    BOOL(^updateAnchorPoints)(CGPoint *, CGFloat, CGPoint *, CGFloat, CGFloat *extraInset) =
    ^ BOOL(CGPoint *leftPoint, CGFloat leftHeight, CGPoint *rightPoint, CGFloat rightHeight, CGFloat *extraInset) {
        
        BOOL topLeftToBottomRight;
        if ((*leftPoint).x < (*rightPoint).x) {
            *extraInset = 0.0000f;
            if ((*leftPoint).y < (*rightPoint).y) {
                topLeftToBottomRight = YES;
            } else {
                topLeftToBottomRight = NO;
                (*leftPoint).y += leftHeight;
                (*rightPoint).y -= rightHeight;
            }
        } else {
            *extraInset = -20.0000f;
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
    
    MADHierarchicalChildController *leftTVC, *rightTVC;
    
    rightTVC = self.controllersByObjectID[link.rightFieldReference.tableID];
    leftTVC = self.controllersByObjectID[link.leftFieldReference.tableID];
    
    leftCellFrameInTable = [leftTVC rectForFieldWithObjectId: link.leftFieldReference.fieldID
                                                      inView: leftTVC.view];
    rightCellFrameInTable = [rightTVC rectForFieldWithObjectId: link.rightFieldReference.fieldID
                                                        inView: rightTVC.view];

    leftTableBottomY = bottomLeftY(leftTVC.frame);
    
    CGRect leftTVCFrame = leftTVC.frame;
    repositionRect(&leftCellFrameInTable, &(leftTVCFrame), leftTableBottomY);
    
    leftCellAnchorPoint = CGCenterOfRect([self.scrollView.contentView convertRect: leftCellFrameInTable
                                                                         fromView: leftTVC.view]);
    translatePoint(&leftCellAnchorPoint, paddingLeft, 0.0000f);
    
    rightTableBottomY = bottomLeftY(rightTVC.frame);

    CGRect rightTVCFrame = rightTVC.frame;
    repositionRect(&rightCellFrameInTable, &(rightTVCFrame), rightTableBottomY);
    
    rightCellAnchorPoint = CGCenterOfRect([self.scrollView.contentView convertRect: rightCellFrameInTable
                                                                          fromView: rightTVC.view]);
    translatePoint(&rightCellAnchorPoint, -paddingLeft, -2.0000f);

    MADDirection direction;
    direction = leftCellAnchorPoint.x < rightCellAnchorPoint.x ? MADDirectionLeft : MADDirectionRight;
    
    CGFloat extraInset = 0.0000f;
    connectorView.topLeftToBottomRight = updateAnchorPoints(&leftCellAnchorPoint,
                                                            leftCellFrameInTable.size.height,
                                                            &rightCellAnchorPoint,
                                                            rightCellFrameInTable.size.height,
                                                            &extraInset);
    connectorView.leftViewIsInital = direction == MADDirectionLeft;
    connectorView.frame = mainFrame(leftCellAnchorPoint,
                                    rightCellAnchorPoint,
                                    extraInset, 10.0000f);
    [connectorView setNeedsDisplay];
}

#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView { }

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    //[self updateCache];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView { }

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view
                        atScale:(CGFloat)scale { }

- (void)scrollViewDidScroll:(UIScrollView *)scrollView { }

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView { }

- (void)scrollViewDidZoom:(UIScrollView *)scrollView { }

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView { return NO; }

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView { }

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView { }

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view { }

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset { }

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.scrollView.contentView;
}

@end
