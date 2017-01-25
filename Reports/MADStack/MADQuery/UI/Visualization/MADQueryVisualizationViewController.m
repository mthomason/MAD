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

#import <QuartzCore/CALayer.h>

#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADAppDelegate.h>
#import <MADFoundation/MADApplicationProtocol.h>

#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSManagedObjectID.h>

#import <UIKit/UIStoryboard.h>
#import <UIKit/UIPopoverController.h>
#import <UIKit/UIPanGestureRecognizer.h>
#import <UIKit/UITableView.h>
#import <UIKit/UIWindow.h>
#import <UIKit/UIToolbar.h>
#import <UIKit/UIManagedDocument.h>

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

#import "MUIViewControllerDelegate.h"

#import "MADManagedObjectView.h"
#import "MADViewControllerSQL.h"
#import "MADConnectorView.h"

#import "MADQueryVisualizationSchemaViewController.h"

#import "CGAffineTransform+Common.h"

#import "NSLayoutConstraint+QueryVisualization.h"
#import "MADQueryVisualizationTableDefination.h"

#import "MADQueryVisualizationDefination.h"
#import "MADQueryVisualizationCacheData.h"

#import "MADOperationArchiveData.h"

#import "UIGestureRecognizer+AnchorPoint.h"

#import "MADQueryVisualizationSchemaPresentationController.h"

#import "MADQueryVisualizationSchemaAnimatedTransitioning.h"
#import "MADQueryVisualizationContentView.h"
#import "MADQueryVisualizationScrollView.h"

#import "MADOperationQueue.h"

#import "MADCacheManager.h"

typedef void(^MTBlockResultVoid)(void);

static NSString * const QueryVisualization = @"MADQueryVisualization";
static NSString * const StoryboardDesigner = @"MADDesigner";
static NSString * const MADQueryVisualizationViewControllerIdentifer = @"MADStoryboardIDQueryVisulization";

static inline CGPoint PointInsertTable(CGFloat *viewHeight, NSUInteger *tableCount);
static inline CGPoint PointInsertTable(CGFloat *viewHeight, NSUInteger *tableCount) {
    return CGPointMake(CGPointZero.x + 500, *viewHeight / (*tableCount + 2) * (*tableCount + 1));
}

@interface MADQueryVisualizationViewController ()
    <UIGestureRecognizerDelegate,
        UIScrollViewDelegate,
        UIPopoverControllerDelegate,
        MADQueryVisualizationSchemaPresentationDelegate,
        MADQueryVisualizationSchemaDelegate,
        MADViewControllerStandardProtocol>

    @property (nonatomic, strong) NSMutableDictionary <NSManagedObjectID *, MADQueryVisualizationSchemaViewController *> *controllersByObjectID;
    @property (nonatomic, strong) NSMutableDictionary <NSManagedObjectID *, MADConnectorView *> *connectionViewsByObjectID;

    @property (nonatomic, strong) NSMutableSet <NSManagedObjectID *> *rootTables;

    @property (nonatomic, weak) IBOutlet UIView *backgroundContainer;

    @property (nonatomic, strong) MADQueryVisualizationCacheData *cacheData;
    @property (nonatomic, strong) MADQueryVisualizationScrollView *scrollView;


@end

@implementation MADQueryVisualizationViewController

@synthesize document = _document;

+ (instancetype)newQueryVisualizationViewController:(MADocument *)document {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName: QueryVisualization bundle: [NSBundle mainBundle]];
    id controller = [storyboard instantiateViewControllerWithIdentifier:MADQueryVisualizationViewControllerIdentifer];
    [((typeof(self))controller) setDocument: document];
    return controller;
}

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MADNotificationDeleteQueryLink
                                                  object:_document.documentObjectIDStore.firstQuery];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
        NSMutableDictionary <NSManagedObjectID *, __kindof MADQueryVisualizationSchemaViewController *> *controllersByObjectID = [[NSMutableDictionary alloc] init];
        _controllersByObjectID = controllersByObjectID;
        
        NSMutableDictionary <NSManagedObjectID *, __kindof MADConnectorView *> *connectionViewsByObjectID = [[NSMutableDictionary alloc] init];
        _connectionViewsByObjectID = connectionViewsByObjectID;
        
        NSMutableSet <NSManagedObjectID *> *rootTables = [[NSMutableSet alloc] init];
        _rootTables = rootTables;
        
    }
    return self;
}

#pragma mark - UIContainerViewController Callbacks

- (BOOL)shouldAutomaticallyForwardAppearanceMethods { return YES; }

- (void)willMoveToParentViewController:(nullable UIViewController *)parent {
    [super willMoveToParentViewController:parent];
}

- (void)didMoveToParentViewController:(nullable UIViewController *)parent {
    [super didMoveToParentViewController:parent];
}

#pragma mark - UIContentContainer

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

#pragma mark - MADQueryVisualizationSchemaPresentationDelegate

- (MADQueryVisualizationTableDefination *)copyTableDefinationForObjectID:(NSManagedObjectID *)objectID {
    return [self.cacheData copyTableDefinationForObjectID:objectID];
}

- (CGRect)frameOfItemWithObjectID:(NSManagedObjectID *)objectID {
    MADQueryVisualizationTableDefination *tableDefination = [self.cacheData tableDefinationForObjectID:objectID];
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

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.definesPresentationContext = NO;
    
    self.backgroundContainer.layer.borderWidth = [UIScreen mainScreen].isRetnaDisplay ? 0.5000f : 1.0000f;
    
    self.backgroundContainer.backgroundColor = [UIColor clearColor];
    self.backgroundContainer.opaque = NO;
    self.view.opaque = YES;
    
    MADQueryVisualizationScrollView *scrollView;
    scrollView = [[MADQueryVisualizationScrollView alloc] initWithFrame:self.backgroundContainer.bounds];
    scrollView.delegate = self;
    scrollView.backgroundColor = [[UIColor groupTableViewBackgroundColor] colorWithAlphaComponent:.02f];
    scrollView.opaque = NO;

    [self.backgroundContainer addSubview:scrollView];
    
    id viewDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:scrollView, @"sv", _backgroundContainer, @"bg", nil];
    
    NSMutableArray *constraints = [NSMutableArray new];
    NSArray *constraints5 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bg]|"
                                                                    options:0 metrics:0
                                                                      views:viewDictionary];
    NSArray *constraints6 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[bg]|"
                                                                    options:0 metrics:0
                                                                      views:viewDictionary];
    [constraints addObjectsFromArray:constraints5];
    [constraints addObjectsFromArray:constraints6];
    [self.view addConstraints:constraints];
    [constraints removeAllObjects];
    
    NSArray *constraints1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[sv]|"
                                                                    options:0 metrics:0
                                                                      views:viewDictionary];
    NSArray *constraints2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[sv]|"
                                                                    options:0 metrics:0
                                                                      views:viewDictionary];
    [constraints addObjectsFromArray:constraints1];
    [constraints addObjectsFromArray:constraints2];
    [self.backgroundContainer addConstraints:constraints];
    [constraints removeAllObjects];
    
    [scrollView addConstraints:constraints];
    [constraints removeAllObjects];
    
    self.scrollView = scrollView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self reloadDocument: YES];
    
    MADocument *document = self.document;
    NSManagedObjectContext *managedObjectContext;
    managedObjectContext = document.documentObjectIDStore.managedObjectContext;
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(deleteQueryLink:)
                                                 name: MADNotificationDeleteQueryLink
                                               object: document.documentObjectIDStore.firstQuery];
    
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
    if (animated) [self.scrollView flashScrollIndicators];
}

- (void)cleanup {
    [self archiveCache];
    [self clearScreen];
    
    MADocument *document = self.document;

    NSManagedObjectContext *managedObjectContext;
    managedObjectContext = document.documentObjectIDStore.managedObjectContext;

    
    NSString *willSave = NSManagedObjectContextWillSaveNotification;
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: willSave
                                                  object: managedObjectContext];
    
    NSString *didSave = NSManagedObjectContextDidSaveNotification;
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: didSave
                                                  object: managedObjectContext];

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self cleanup];
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
    [self layoutQueryTables];
    [self layoutQueryLinks];
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
    for (UIViewController *childContoller in self.childViewControllers) {
        if ([childContoller isKindOfClass:[MADQueryVisualizationSchemaViewController class]]) {
            MADQueryVisualizationTableDefination *tableDefination = [self.cacheData tableDefinationForObjectID:((MADQueryVisualizationSchemaViewController *)childContoller).tableObjectId];
            if (tableDefination == nil) {
                tableDefination = [MADQueryVisualizationTableDefination newTableDefination];
                tableDefination.center = CGCenterRect(self.scrollView.bounds);
                [self.cacheData addTableDefination:tableDefination forObjectID:((MADQueryVisualizationSchemaViewController *)childContoller).tableObjectId];
            }
            if (tableDefination.root) {
                NSManagedObjectID *objectID = ((MADQueryVisualizationSchemaViewController *)childContoller).tableObjectId.copy;
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
    NSEnumerator <MADModelQueryLink *> *queryLinkEnumerator;
    queryLinkEnumerator = self.document.documentObjectIDStore.firstQuery.links.objectEnumerator;
    for (MADModelQueryLink *link in queryLinkEnumerator) {
        [self layoutQueryLinkViewControllerWithModelObject:link];
    }
}

#pragma mark - NSManagedObjectContext Observer

- (void)managedObjectContextWillSave:(NSNotification *)notification { }

- (void)managedObjectContextDidSave:(NSNotification *)notification {

    NSArray *insertedObjects = notification.userInfo[NSInsertedObjectsKey];
    NSArray *updatedObjects = notification.userInfo[NSUpdatedObjectsKey];
    NSArray *deletedObjects = notification.userInfo[NSDeletedObjectsKey];
    
    RptqQuery *updatedQuery = nil;
    BOOL needsLayout = NO;
    
#pragma mark Handle inserted objects
    
    CGFloat height;
    NSUInteger rootTableCount;
    for (id insertedObject in insertedObjects) {
        
        if ([insertedObject isKindOfClass:[RptqQueryLinks class]]) {
            
            //User adding a link starting point...
            //RptqQueryLinks *(insertedObject)insertedQueryLinks = insertedObject;
            
            MADQueryVisualizationSchemaViewController *leftTVC;
            leftTVC = self.controllersByObjectID[((RptqQueryLinks *)insertedObject).hasLeftField.inQueryTable.objectID];
            MADQueryVisualizationSchemaViewController *rightTVC;
            rightTVC = self.controllersByObjectID[((RptqQueryLinks *)insertedObject).hasRightField.inQueryTable.objectID];
            
            [self.rootTables removeObject:((RptqQueryLinks *)insertedObject).hasLeftField.inQueryTable.objectID];
            
            if ([leftTVC isEqual:rightTVC] == NO) {
                [self addLinkViewControllerForQueryLinkObject: ((RptqQueryLinks *)insertedObject)
                                                     animated: YES];
            }
            
        } else if ([insertedObject isKindOfClass:[RptqQueryTable class]]) {
            
            //Going to assume that it's a top level table.
            NSManagedObjectID *objectID = ((RptqQueryTable *)insertedObject).objectID.copy;
            [self.rootTables addObject: objectID];

            height = self.scrollView.contentView.bounds.size.height;
            rootTableCount = self.rootTables.count;
            [self addSchemaViewControllerForTableID: objectID
                                             center: PointInsertTable(&height, &rootTableCount)
                                               root: YES
                                           animated: YES];
            [self.view setNeedsLayout];
        }
    }
    
    if (updatedObjects.count) {

        //Evaluate the updated objects.
        NSMutableArray *updatedTables = [[NSMutableArray alloc] initWithCapacity:updatedObjects.count];
        for (const id updatedObject in updatedObjects) {
            if ([updatedObject isKindOfClass:[RptqQueryTable class]]) {
                [updatedTables addObject:updatedObject];
            } else if ([updatedObject isKindOfClass:[RptqQuery class]]) {
                updatedQuery = updatedObject;
            }
        }

        if (updatedQuery && updatedTables.count > 0) {
            for (RptqQueryTable *updatedTable in updatedTables) {
                if (![updatedTable.inQuery.objectID isEqual:updatedQuery.objectID]) {

                    //Table was remvoed from query... so remove it from screen.
                    MADQueryVisualizationSchemaViewController *updatedItem = self.controllersByObjectID[updatedTable.objectID];
                    
                    if (updatedItem != nil) {
                        
                        [self.rootTables removeObject:updatedTable.objectID];
                        [self.cacheData removeTableDefinationForObjectID:updatedTable.objectID];
                        [self removeViewController:updatedItem];
                        
                        for (RptqQueryLinks *link in updatedQuery.hasQueryLinks) {
                            if ([link.hasLeftField.inQueryTable.objectID isEqual: updatedTable.objectID] ||
                                [link.hasRightField.inQueryTable.objectID isEqual: updatedTable.objectID]) {
                                
                                MADConnectorView * __weak connectorView = self.connectionViewsByObjectID[link.objectID];
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
    
    for (id deletedObject in deletedObjects) {
        if ([deletedObject isKindOfClass:[RptqQueryTable class]]) {
            [self deleteQueryTable:deletedObject];
            [self.view setNeedsLayout];
        }// else if ([deletedObject isKindOfClass:[RptqQueryLinks class]]) {
         //   [self deleteQueryLinkOld:deletedObject];
         //   [self.view setNeedsLayout];
        //}
    }

    [self.view layoutIfNeeded];
}

#pragma mark - MADViewControllerStandardProtocol

- (void)viewControllerDidFinish:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{ }];
}

#pragma mark - Cache Operations

- (void)updateCache {
    MADocument *doc = self.document;
    if (doc != nil) {
        
        MADQueryVisualizationDefination *queryDef;
        queryDef= [[MADQueryVisualizationDefination alloc] initWithQuery:doc.documentObjectIDStore.firstQuery];
        MTLinkedList *topologicallySortedTables = queryDef.topologicallySortedTables;

        MADQueryVisualizationCacheData *cacheData;
        cacheData = [[MADQueryVisualizationCacheData alloc] initWithNumberOfTables:[topologicallySortedTables count]];
        cacheData.scrollViewContentOffset = self.scrollView.contentOffset;
        cacheData.scrollViewZoomScale = self.scrollView.zoomScale;
        
        for (MTPair *pair in queryDef.topologicallySortedTables) {
            MTVertex *tableIdVertext = pair.former;
            if (tableIdVertext.object != nil) {
                
                MADQueryVisualizationSchemaViewController *viewController = self.controllersByObjectID[(NSManagedObjectID *)tableIdVertext.object];
                
                MADQueryVisualizationTableDefination *tableDef = [[MADQueryVisualizationTableDefination alloc] init];
                tableDef.center = viewController.view.center;
                
                NSArray <NSURL *> *startingPoints = queryDef.startingPoints;
                tableDef.root = [startingPoints containsObject: ((NSManagedObjectID *)tableIdVertext.object).URIRepresentation];
                [cacheData addTableDefination:tableDef forObjectID:tableIdVertext.object];
            }
        }
        self.cacheData = cacheData;
    }
}

- (void)archiveCache {
    [self updateCache];
    MADOperationArchiveData *operation;
    operation = [[MADOperationArchiveData alloc] initWithURL: self.localCacheFileUrl
                                                   andObject: self.cacheData];
    [[MADCacheManager sharedManager] addOperation:operation];
}

- (MADQueryVisualizationCacheData *)loadCache {
    
    MADQueryVisualizationCacheData *result;
    NSError * _Nullable __autoreleasing * _Nullable error = nil;
    NSData *data;
    data = [[NSData alloc] initWithContentsOfURL: self.localCacheFileUrl
                                         options: NSDataReadingUncached error:error];
    if (error != nil) {
        [[NSFileManager defaultManager] removeItemAtURL:self.localCacheFileUrl error:error];
        result = nil;
    } else {
        id resultFromTryBlock = nil;
        @try {
            resultFromTryBlock = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
        @catch (NSException *exception) {
            NSError *cleanup = nil;
            [[NSFileManager defaultManager] removeItemAtURL:self.localCacheFileUrl error:&cleanup];
        }
        @finally {
            if ([resultFromTryBlock isKindOfClass:[MADQueryVisualizationCacheData class]]) {
                result = resultFromTryBlock;
            } else {
                [[NSFileManager defaultManager] removeItemAtURL:self.localCacheFileUrl error:error];
                result = nil;
            }
        }
    }
    return result;
}

- (NSString *)cacheFileName {
    return [MADQueryVisualizationViewController cacheFileNameForDocument:self.document];
}

- (NSURL *)localCacheFileUrl {
    
    MADAppDelegate delegate = [MADApplication AppDelegate];
    NSString *groupIdentifier = [delegate groupIdentifier].copy;
    
    NSURL *cachedFilesDirectories;
    cachedFilesDirectories = [MADURL newURLForLocalCacheDirectoryForGroupIdentifier:groupIdentifier];
    NSString *cacheFileName = [self cacheFileName];
    return [cachedFilesDirectories URLByAppendingPathComponent:cacheFileName isDirectory:NO];
}

+ (NSString *)cacheFileNameForDocument:(MADocument *)document {
    return [MADQueryVisualizationCacheData cacheFileNameForFileName:document.fileURL.lastPathComponent.stringByDeletingPathExtension];
}

#pragma mark - Gesture recognizer actions

- (void)panPiece:(UIPanGestureRecognizer *)gestureRecognizer {
    [UIGestureRecognizer adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    
    UIWindow *window = [UIApplication sharedApplication].windows[0];
    gestureRecognizer.view.center = [window convertPoint: [gestureRecognizer locationInView:window]
                                                  toView: self.scrollView.contentView];
    [self didMoveFieldRect:self.controllersByObjectID[((MADManagedObjectView *)gestureRecognizer.view).objectIdTag]
                  animated:NO];
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self updateCache];
    }
}

#pragma mark - Change UI on IR Diagram

- (void)clearScreen {
    for (UIViewController *viewController in self.childViewControllers) {
        [self removeViewController:viewController];
    }
    for (UIView *subview in self.scrollView.contentView.subviews) {
        [subview removeFromSuperview];
    }
}

#pragma mark Reload document view controllers

- (void)redraw {
    [self reloadDocument: NO];
}

- (void)reloadDocument:(BOOL)animated {
    MADocument *documentReport = self.document;
    if (documentReport) {
        [self clearScreen];
        [self.rootTables removeAllObjects];
        [self.controllersByObjectID removeAllObjects];
        [self.connectionViewsByObjectID removeAllObjects];
        
        NSString *path = self.localCacheFileUrl.path.copy;
        
        MADModelQuery *query;
        query = _document.documentObjectIDStore.databases.firstObject.queries.firstObject;

        if (path != nil && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
            MADQueryVisualizationCacheData *schemaLocations = [self loadCache];
            self.cacheData = schemaLocations;
            [self displayQuery: query
               withSchemaHints: schemaLocations
                      animated: animated];
        } else {
            [self displayQuery: query
                      animated: animated];
        }
    }
}

- (void)displayQuery:(MADModelQuery *)queryID
     withSchemaHints:(MADQueryVisualizationCacheData *)cacheData
            animated:(BOOL)animated {

    if (cacheData != nil) {

        self.scrollView.contentOffset = cacheData.scrollViewContentOffset;
        self.scrollView.zoomScale = cacheData.scrollViewZoomScale;
        

        MADQueryVisualizationDefination *queryDef = [[MADQueryVisualizationDefination alloc] initWithQuery:queryID];
        MTLinkedList *topologicallySortedTables = queryDef.topologicallySortedTables;
        
        NSManagedObjectContext *managedObjectContext = self.document.managedObjectContext;
        for (MTPair *pair in topologicallySortedTables) {
            MTVertex *tableIdVertext = pair.former;
            if (tableIdVertext.object != nil) {
                
                RptqQueryTable *table = (RptqQueryTable *)[managedObjectContext objectWithID:tableIdVertext.object];
                
                NSManagedObjectID *objectID = table.objectID.copy;
                NSURL *uriRepresentation = [objectID URIRepresentation];
                BOOL topLevel = [queryDef.startingPoints containsObject: uriRepresentation];
                if (topLevel) {
                    [self.rootTables addObject: objectID];
                }

                MADQueryVisualizationTableDefination *tableDef = [cacheData tableDefinationForObjectID:objectID];
                [self addSchemaViewControllerForTableID:objectID center:tableDef.center
                                                   root:topLevel animated:animated];

            }
        }
        NSEnumerator <MADModelQueryLink *> *queryLinkEnumerator = queryID.links.objectEnumerator;
        for (MADModelQueryLink *link in queryLinkEnumerator) {
            [self addLinkViewControllerForQueryLinkModel:link animated:YES];
        }
        
    } else {
        [self displayQuery:queryID animated:animated];
    }
}

// FIXME: Display query with a layout... this method is called when there is NO CACHE...
//          Right now, views end up in the center...

- (void)displayQuery:(MADModelQuery *)query animated:(BOOL)animated {

    MADQueryVisualizationDefination *queryDef;
    queryDef = [[MADQueryVisualizationDefination alloc] initWithQuery:query];
    NSInteger tableCounter = 0;

    NSManagedObjectID *tableObjectID;
    for (MTPair *pair in queryDef.topologicallySortedTables) {
        MTVertex *tableIdVertext = pair.former;
        if (tableIdVertext.object != nil) {

            tableObjectID = [tableIdVertext.object copy];
            
            BOOL topLevel = [queryDef.startingPoints containsObject: tableObjectID.URIRepresentation];

            [self addSchemaViewControllerForTableID: tableObjectID
                                             center: self.scrollView.contentView.center
                                               root: topLevel
                                           animated: animated];
            if (topLevel) {
                NSManagedObjectID *objectID = tableObjectID.copy;
                [self.rootTables addObject: objectID];
            }
            tableCounter++;
        }
    }
    NSEnumerator <MADModelQueryLink *> *queryLinkEnumerator = query.links.objectEnumerator;
    for (MADModelQueryLink *link in queryLinkEnumerator) {
        [self addLinkViewControllerForQueryLinkModel:link animated:animated];
    }
}

- (void)deleteQueryTable:(RptqQueryTable *)deletedQueryTable {
    if (deletedQueryTable.inQuery != nil) {
        MADQueryVisualizationSchemaViewController *viewController;
        viewController = self.controllersByObjectID[deletedQueryTable.objectID];
        if (viewController != nil) {
            [viewController willMoveToParentViewController:nil];
            [viewController.view removeFromSuperview];
            [viewController removeFromParentViewController];
            [viewController didMoveToParentViewController:nil];
            [self.controllersByObjectID removeObjectForKey:deletedQueryTable.objectID];
        }
    }
}

- (void)deleteQueryLinkOld:(RptqQueryLinks *)deletedQueryLinks {
    NSMutableSet *orphanedQueryTables = [[NSMutableSet alloc] init];
    MADocument *doc = self.document;
    RptqDatabase *database = doc.activeDocumentModel.hasDatabaseSchemas.anyObject;
    RptqQuery *query = database.hasQueries.anyObject;
    for (RptqQueryTable *table in query.hasQueryTables) {
        BOOL orphaned = YES;
        for (RptqQueryLinks *link in query.hasQueryLinks) {
            if ([table.objectID isEqual:link.hasRightField.inQueryTable.objectID]) {
                orphaned = NO;
                break;
            }
        }
        if (orphaned) {
            [orphanedQueryTables addObject:table];
        }
    }
    
    [orphanedQueryTables minusSet:self.rootTables];  // Should only be one newly orphaned table.
    
    RptqQueryLinks *deletedLink = (RptqQueryLinks *)[doc.managedObjectContext objectWithID:deletedQueryLinks.objectID];
    MADQueryVisualizationTableDefination *tableDefination;
    NSManagedObjectID *objectID;
    for (RptqQueryTable *table in orphanedQueryTables) {
        
        @autoreleasepool {
            objectID = table.objectID.copy;
            tableDefination = [self.cacheData tableDefinationForObjectID:objectID];
            tableDefination.root = YES;
            [self.rootTables addObject: objectID];
            objectID = nil;
        }
        
    }
    
    MADConnectorView *connectorView = self.connectionViewsByObjectID[deletedLink.objectID];
    [connectorView removeFromSuperview];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    [self.connectionViewsByObjectID removeObjectForKey:deletedLink.objectID];
}

- (void)deleteQueryLink:(NSNotification *)note {
    if ([note.name isEqualToString:MADNotificationDeleteQueryLink]) {
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
            NSLog(@"%@", orphaned);
            
            for (NSManagedObjectID *orphanedTableIDs in orphaned) {
                
                @autoreleasepool {
                    NSManagedObjectID *objectID = orphanedTableIDs.copy;
                    MADQueryVisualizationTableDefination *tableDefination;
                    tableDefination = [self.cacheData tableDefinationForObjectID:objectID];
                    tableDefination.root = YES;
                    [self.rootTables addObject: objectID];
                    objectID = nil;
                }
            }
            
            MADConnectorView *connectorView = self.connectionViewsByObjectID[deletedLink.objectID];
            [connectorView removeFromSuperview];
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
            [self.connectionViewsByObjectID removeObjectForKey:deletedLink.objectID];
        }
    }
}

- (void)removeFromParentViewController {
    [super removeFromParentViewController];
}

#pragma mark - View Controller Container Data

- (void)removeViewController:(UIViewController *)viewController {
    [viewController willMoveToParentViewController:nil];
    [viewController.view removeFromSuperview];
    [viewController removeFromParentViewController];
    [viewController didMoveToParentViewController:nil];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (void)addSchemaViewControllerForTableID:(NSManagedObjectID *)tableID
                                   center:(CGPoint)center
                                     root:(BOOL)root animated:(BOOL)animated {
    
    MADQueryVisualizationSchemaViewController *viewController;
    viewController = [MADQueryVisualizationSchemaViewController newQueryVisualizationSchemaViewController];
    viewController.document = self.document;
    viewController.delegate = self;
    viewController.tableObjectId = tableID.copy;
    viewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    if (root) viewController.toolbar.backgroundColor = [UIColor blueColor];
    self.controllersByObjectID[tableID] = viewController;

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panPiece:)];
    panGesture.delegate = self;
    [self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:panGesture];
    [viewController.view addGestureRecognizer:panGesture];
    
    [viewController willMoveToParentViewController:self];
    [self addChildViewController:viewController];
    viewController.view.center = center;
    [self.scrollView.contentView addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
}

- (void)addLinkViewControllerForQueryLinkModel:(MADModelQueryLink *)link animated:(BOOL)animated {
    __weak typeof(self) weakself = self;
    [self addLinkViewControllerForQueryLinkID:link.objectID animated:animated layoutHandler:^{
        [weakself layoutQueryLinkViewControllerWithModelObject:link];
    }];
}

- (void)addLinkViewControllerForQueryLinkObject:(RptqQueryLinks *)link animated:(BOOL)animated {
    __weak typeof(self) weakself = self;
    [self addLinkViewControllerForQueryLinkID:link.objectID animated:animated layoutHandler:^{
        [weakself layoutQueryLinkViewControllerWithManagedObject:link];
    }];
}
- (void)addLinkViewControllerForQueryLinkID:(NSManagedObjectID *)linkID animated:(BOOL)animated layoutHandler:(void(^)(void))layoutHandler {

    MADConnectorView *connectorView = [[MADConnectorView alloc] initWithFrame:CGRectZero];
    connectorView.userInteractionEnabled = NO;
    connectorView.objectIdTag = linkID.copy;
    
    self.connectionViewsByObjectID[linkID] = connectorView;
    
    if (animated == NO) {
        layoutHandler();
    }
    
    CGRect desiredFrame = connectorView.frame;
    CGPoint desiredCenter = connectorView.center;
    CGAffineTransform desiredTransform = connectorView.transform;
    
    connectorView.bounds = CGRectZero;
    connectorView.center = desiredCenter;
    if (animated) {
        connectorView.transform = animated ? CGAffineTransformIdentity : CGAffineTransformSwing();
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
                         completion:^(BOOL finished) { }];
    } else {
        animateTwo();
    }
    
    if (animated) {
        layoutHandler();
    }
}

#pragma mark - Layout

- (void)didMoveFieldRect:(id)sender animated:(BOOL)animated {
    
    if ([sender isKindOfClass:[MADQueryVisualizationSchemaViewController class]]) {
        MADQueryVisualizationSchemaViewController *controller;
        controller = (MADQueryVisualizationSchemaViewController *)sender;
        NSManagedObjectID *tableID = controller.tableObjectId;
        
        NSEnumerator <MADModelQueryLink *> *links; MADModelQueryLink *link;
        links = self.document.documentObjectIDStore.firstQuery.links.objectEnumerator;
        for (link in links) {
            if ([link.leftFieldReference.tableID isEqual: tableID] ||
                [link.rightFieldReference.tableID isEqual: tableID]) {
                [self layoutQueryLinkViewControllerWithModelObject: link];
            }
        }
    }
}

- (void)layoutQueryLinkViewControllerWithManagedObject:(RptqQueryLinks *)queryLink {
    
}
- (void)layoutQueryLinkViewControllerWithModelObject:(MADModelQueryLink *)link {
    [self layoutQueryLinkViewControllerWithQueryLinkID: link.objectID
                                           leftFieldID: link.leftFieldReference.fieldID
                                           leftTableID: link.leftFieldReference.tableID
                                          rightFieldID: link.rightFieldReference.fieldID
                                          rightTableID: link.rightFieldReference.tableID];
}

- (void)layoutQueryLinkViewControllerWithQueryLinkID:(NSManagedObjectID *)queryLinkID
                                         leftFieldID:(NSManagedObjectID *)leftFieldID
                                         leftTableID:(NSManagedObjectID *)leftTableID
                                        rightFieldID:(NSManagedObjectID *)rightFieldID
                                        rightTableID:(NSManagedObjectID *)rightTableID {
    
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
    
    MADConnectorView *connectorView;
    MADQueryVisualizationSchemaViewController *leftTVC, *rightTVC;
    
    connectorView = self.connectionViewsByObjectID[queryLinkID];
    rightTVC = self.controllersByObjectID[rightTableID];
    leftTVC = self.controllersByObjectID[leftTableID];
    
    leftCellFrameInTable = [leftTVC rectForFieldWithObjectId:leftFieldID inView:leftTVC.view];
    rightCellFrameInTable = [rightTVC rectForFieldWithObjectId:rightFieldID inView:rightTVC.view];

    leftTableBottomY = bottomLeftY(leftTVC.schemaTableViewController.frame);
    
    CGRect leftTVCFrame = leftTVC.schemaTableViewController.frame;
    repositionRect(&leftCellFrameInTable, &(leftTVCFrame), leftTableBottomY);
    
    leftCellAnchorPoint = CGCenterOfRect([self.scrollView.contentView convertRect: leftCellFrameInTable
                                                                         fromView: leftTVC.view]);
    translatePoint(&leftCellAnchorPoint, paddingLeft, 0.0000f);
    
    rightTableBottomY = bottomLeftY(rightTVC.schemaTableViewController.frame);

    CGRect rightTVCFrame = rightTVC.schemaTableViewController.frame;
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
    if (direction == MADDirectionLeft) {
        connectorView.leftViewIsInital = YES;
    } else {
        connectorView.leftViewIsInital = NO;
    }
    connectorView.frame = mainFrame(leftCellAnchorPoint, rightCellAnchorPoint, extraInset, 10.0000f);
    [connectorView setNeedsDisplay];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView { }

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self updateCache];
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

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView { return self.scrollView.contentView; }

@end
