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

#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSManagedObjectID.h>

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

#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import <MADFileManager/NSURL+CommonURLs.h>

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

#import "MUIViewControllerDelegate.h"

#import "MADManagedObjectView.h"
#import "MADViewControllerSQL.h"
#import "MADConnectorView.h"

#import "MADQueryVisualizationSchemaViewController.h"
#import "MADQueryVisualizationSchemaViewController+Designer.h"

#import "CGAffineTransform+Common.h"

#import "UIViewController+Designer.h"
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
        MTViewControllerProtocol>

    @property (nonatomic, strong) NSMutableDictionary <__kindof NSManagedObjectID *, __kindof MADQueryVisualizationSchemaViewController *> *controllersByObjectID;
    @property (nonatomic, strong) NSMutableDictionary <__kindof NSManagedObjectID *, __kindof MADConnectorView *> *connectionViewsByObjectID;

    @property (nonatomic, strong) NSMutableSet <__kindof NSManagedObjectID *> *rootTables;

    @property (nonatomic, weak) IBOutlet UIView *backgroundContainer;

    @property (nonatomic, strong) MADQueryVisualizationCacheData *cacheData;
    @property (nonatomic, strong) MADQueryVisualizationScrollView *scrollView;

@end

@implementation MADQueryVisualizationViewController

@synthesize document = _document;

- (void)dealloc { }

#pragma mark - UIContainerViewControllerCallbacks

- (BOOL)shouldAutomaticallyForwardAppearanceMethods { return NO; }

- (void)willMoveToParentViewController:(nullable UIViewController *)parent {
    [super willMoveToParentViewController:parent];
}

- (void)didMoveToParentViewController:(nullable UIViewController *)parent {
    [super didMoveToParentViewController:parent];
}

#pragma mark - UIContentContainer

- (CGSize)sizeForChildContentContainer:(id <UIContentContainer>)container withParentContainerSize:(CGSize)parentSize {
    return CGSizeMake(MADSchemaViewDefaultWidth, MADSchemaViewDefaultHeight);
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
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

#pragma mark - NSObject

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    
    NSMutableDictionary <__kindof NSManagedObjectID *, __kindof MADQueryVisualizationSchemaViewController *> *controllersByObjectID = [[NSMutableDictionary alloc] init];
    self.controllersByObjectID = controllersByObjectID;

    NSMutableDictionary <__kindof NSManagedObjectID *, __kindof MADConnectorView *> *connectionViewsByObjectID = [[NSMutableDictionary alloc] init];
    self.connectionViewsByObjectID = connectionViewsByObjectID;
    
    NSMutableSet <__kindof NSManagedObjectID *> *rootTables = [[NSMutableSet alloc] init];
    self.rootTables = rootTables;

}

- (void)setDocument:(MADocument *)document {
    if (_document != document) {
        _document = document;
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSAssert(self.document != nil, @"%s: Need a document", __PRETTY_FUNCTION__);
    
    self.definesPresentationContext = NO;
    
    self.backgroundContainer.layer.borderWidth = [MADocument isRetnaDisplay] ? 0.5000f : 1.0000f;
    
    self.backgroundContainer.backgroundColor = [UIColor clearColor];
    self.backgroundContainer.opaque = NO;
    self.view.opaque = YES;
    
    MADQueryVisualizationScrollView *scrollView = [[MADQueryVisualizationScrollView alloc] initWithFrame:self.backgroundContainer.bounds];
    scrollView.delegate = self;
    scrollView.backgroundColor = [[UIColor groupTableViewBackgroundColor] colorWithAlphaComponent:.02f];
    scrollView.opaque = NO;

    [self.backgroundContainer addSubview:scrollView];
    
    NSDictionary *viewDictionary = @{@"sv" : scrollView, @"bg" : self.backgroundContainer};
    
    NSMutableArray *constraints = [NSMutableArray new];
    NSArray *constraints5 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bg]|" options:0 metrics:0 views:viewDictionary];
    NSArray *constraints6 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[bg]|" options:0 metrics:0 views:viewDictionary];
    [constraints addObjectsFromArray:constraints5];
    [constraints addObjectsFromArray:constraints6];
    [self.view addConstraints:constraints];
    [constraints removeAllObjects];
    
    NSArray *constraints1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[sv]|" options:0 metrics:0 views:viewDictionary];
    NSArray *constraints2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[sv]|" options:0 metrics:0 views:viewDictionary];
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

    MADocument *doc = self.document;
    [self reloadDocument:doc animated:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(managedObjectContextWillSave:)
                                                 name: NSManagedObjectContextWillSaveNotification
                                               object: doc.activeDocumentModel.managedObjectContext];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(managedObjectContextDidSave:)
                                                 name: NSManagedObjectContextDidSaveNotification
                                               object: doc.activeDocumentModel.managedObjectContext];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (animated) [self.scrollView flashScrollIndicators];
}

- (void)cleanup {
    [self archiveCache];
    [self clearScreen];
    
    MADocument *doc = self.document;
    id managedObjectContext = doc.activeDocumentModel.managedObjectContext;
    
    NSString * __unsafe_unretained willSave = NSManagedObjectContextWillSaveNotification;
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: willSave
                                                  object: managedObjectContext];
    
    NSString * __unsafe_unretained didSave = NSManagedObjectContextDidSaveNotification;
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
    for (RptqQueryLinks *queryLink in self.document.activeDocumentModel.defaultDatabase.defaultQuery.hasQueryLinks) {
        [self layoutQueryLinkViewController:queryLink];
    }
}

#pragma mark - UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController { }

#pragma mark - NSManagedObjectContext Observer

- (void)managedObjectContextWillSave:(NSNotification *)notification { }

- (void)managedObjectContextDidSave:(NSNotification *)notification {

    NSArray *insertedObjects = notification.userInfo[NSInsertedObjectsKey];
    NSArray *updatedObjects = notification.userInfo[NSUpdatedObjectsKey];
    NSArray *deletedObjects = notification.userInfo[NSDeletedObjectsKey];
    
    RptqQuery *updatedQuery = nil;
    bool needsLayout = false;
    
#pragma mark Handle inserted objects
    
    CGFloat height;
    NSUInteger rootTableCount;
    for (id insertedObject in insertedObjects) {
        
        if ([insertedObject isKindOfClass:[RptqQueryLinks class]]) {
            
            //User adding a link starting point...
            RptqQueryLinks *insertedQueryLinks = insertedObject;
            [self insertQueryLink:insertedQueryLinks];
            
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
            [self.view layoutIfNeeded];
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
                                [self.view layoutIfNeeded];
                            }
                        }
                        needsLayout = true;
                        
                    }
                }
            }
        }
    }
    
#pragma mark Handle deleted objects
    
    for (id deletedObject in deletedObjects) {
        if ([deletedObject isKindOfClass:[RptqQueryTable class]]) {
            [self deleteQueryTable:deletedObject];
        } else if ([deletedObject isKindOfClass:[RptqQueryLinks class]]) {
            [self deleteQueryLink:deletedObject];
        }
    }

    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

#pragma mark - MTViewControllerProtocol

- (void)viewControllerDidFinish:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{ }];
}

#pragma mark - Cache Operations

- (void)updateCache {
    MADocument *doc = self.document;
    if (doc != nil) {
        
        RptqQuery *query = doc.activeDocumentModel.defaultDatabase.defaultQuery;
        MADQueryVisualizationDefination *queryDef = [[MADQueryVisualizationDefination alloc] initWithQuery:query];
        MTLinkedList *topologicallySortedTables = queryDef.topologicallySortedTables;

        MADQueryVisualizationCacheData *cacheData = [[MADQueryVisualizationCacheData alloc] initWithNumberOfTables:[topologicallySortedTables count]];
        cacheData.scrollViewContentOffset = self.scrollView.contentOffset;
        cacheData.scrollViewZoomScale = self.scrollView.zoomScale;
        
        for (MTPair *pair in queryDef.topologicallySortedTables) {
            MTVertex *tableIdVertext = pair.former;
            if (tableIdVertext.object != nil) {
                
                MADQueryVisualizationSchemaViewController *viewController = self.controllersByObjectID[(NSManagedObjectID *)tableIdVertext.object];
                
                MADQueryVisualizationTableDefination *tableDef = [[MADQueryVisualizationTableDefination alloc] init];
                tableDef.center = viewController.view.center;
                
                NSArray <NSURL *> * __unsafe_unretained startingPoints = queryDef.startingPoints;
                tableDef.root = [startingPoints containsObject: ((NSManagedObjectID *)tableIdVertext.object).URIRepresentation];
                [cacheData addTableDefination:tableDef forObjectID:tableIdVertext.object];
            }
        }
        self.cacheData = cacheData;
    }
}

- (void)archiveCache {
    [self updateCache];
    MADOperationArchiveData *operation = [[MADOperationArchiveData alloc] initWithURL:self.localCacheFileUrl
                                                                            andObject:self.cacheData];
    [[MADCacheManager sharedManager] addOperation:operation];
}

- (MADQueryVisualizationCacheData *)loadCache {
    MADQueryVisualizationCacheData *result;
    NSError * _Nullable __autoreleasing * _Nullable error = nil;
    NSData *data = [[NSData alloc] initWithContentsOfURL:self.localCacheFileUrl options:NSDataReadingUncached error:error];
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
    NSString *groupIdentifier = MADIdentifierGroup;
    
    NSURL *cachedFilesDirectories;
    cachedFilesDirectories = [NSURL newURLForLocalCacheDirectoryForGroupIdentifier:groupIdentifier];
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

- (void)insertQueryLink:(RptqQueryLinks *)insertedQueryLinks {
    MADQueryVisualizationSchemaViewController * __weak leftTableViewController = self.controllersByObjectID[insertedQueryLinks.hasLeftField.inQueryTable.objectID];
    MADQueryVisualizationSchemaViewController * __weak rightTableViewController = self.controllersByObjectID[insertedQueryLinks.hasRightField.inQueryTable.objectID];
    
    [self.rootTables removeObject:insertedQueryLinks.hasLeftField.inQueryTable.objectID];
    if ([leftTableViewController isEqual:rightTableViewController] == NO) {
        [self addLinkViewControllerForQueryLink: insertedQueryLinks animated:YES];
    }
}

#pragma mark Reload document view controllers

- (void)redraw {
    [self reloadDocument:self.document animated:NO];
}

- (void)reloadDocument:(MADocument *)documentReport animated:(BOOL)animated {
    if (documentReport) {
        [self clearScreen];
        [self.rootTables removeAllObjects];
        [self.controllersByObjectID removeAllObjects];
        [self.connectionViewsByObjectID removeAllObjects];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.localCacheFileUrl.path]) {
            MADQueryVisualizationCacheData *schemaLocations = [self loadCache];
            self.cacheData = schemaLocations;
            [self displayQuery:documentReport.activeDocumentModel.defaultDatabase.defaultQuery withSchemaHints:schemaLocations animated:animated];
        } else {
            [self displayQuery:documentReport.activeDocumentModel.defaultDatabase.defaultQuery animated:animated];
        }
    }
}

- (void)displayQuery:(RptqQuery *)query withSchemaHints:(MADQueryVisualizationCacheData *)cacheData animated:(BOOL)animated {

    if (cacheData != nil) {

        self.scrollView.contentOffset = cacheData.scrollViewContentOffset;
        self.scrollView.zoomScale = cacheData.scrollViewZoomScale;
        

        MADQueryVisualizationDefination *queryDef = [[MADQueryVisualizationDefination alloc] initWithQuery:query];
        MTLinkedList *topologicallySortedTables = queryDef.topologicallySortedTables;
        for (MTPair *pair in topologicallySortedTables) {
            MTVertex *tableIdVertext = pair.former;
            if (tableIdVertext.object != nil) {
                
                RptqQueryTable *table = (RptqQueryTable *)[self.document.managedObjectContext objectWithID:tableIdVertext.object];
                
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
        
        for (RptqQueryLinks *queryLink in query.hasQueryLinks) {
            [self addLinkViewControllerForQueryLink:queryLink animated:YES];
        }
        
    } else {
        [self displayQuery:query animated:animated];
    }
}

// FIXME: Display query with a layout... this method is called when there is NO CACHE...
//          Right now, views end up in the center...

- (void)displayQuery:(RptqQuery *)query animated:(BOOL)animated {

    MADQueryVisualizationDefination *queryDef = [[MADQueryVisualizationDefination alloc] initWithQuery:query];
    NSInteger tableCounter = 0;

    NSManagedObjectID *tableID;
    for (MTPair *pair in queryDef.topologicallySortedTables) {
        MTVertex *tableIdVertext = pair.former;
        if (tableIdVertext.object != nil) {
            RptqQueryTable *table = (RptqQueryTable *)[self.document.managedObjectContext objectWithID:tableIdVertext.object];
            BOOL topLevel = [queryDef.startingPoints containsObject: table.objectID.URIRepresentation];

            tableID = table.objectID.copy;
            [self addSchemaViewControllerForTableID:tableID
                                             center:self.scrollView.contentView.center
                                               root:topLevel animated:animated];
            if (topLevel) {
                NSManagedObjectID *objectID = table.objectID.copy;
                [self.rootTables addObject: objectID];
            }
            tableCounter++;
        }
    }
    
    for (RptqQueryLinks *queryLink in query.hasQueryLinks) {
        [self addLinkViewControllerForQueryLink:queryLink animated:animated];
    }
}

- (void)deleteQueryTable:(RptqQueryTable *)deletedQueryTable {
    if (deletedQueryTable.inQuery != nil) {
        MADQueryVisualizationSchemaViewController *viewController = self.controllersByObjectID[deletedQueryTable.objectID];
        if (viewController != nil) {
            [viewController willMoveToParentViewController:nil];
            [viewController.view removeFromSuperview];
            [viewController removeFromParentViewController];
            [viewController didMoveToParentViewController:nil];
            [self.controllersByObjectID removeObjectForKey:deletedQueryTable.objectID];
        }
    }
}

- (void)deleteQueryLink:(RptqQueryLinks *)deletedQueryLinks {
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
    
    MADConnectorView * __unsafe_unretained connectorView = self.connectionViewsByObjectID[deletedLink.objectID];
    [connectorView removeFromSuperview];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    [self.connectionViewsByObjectID removeObjectForKey:deletedLink.objectID];
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

- (void)addSchemaViewControllerForTableID:(NSManagedObjectID *)tableID center:(CGPoint)center
                                     root:(BOOL)root animated:(BOOL)animated {
    
    MADQueryVisualizationSchemaViewController *viewController = [MADQueryVisualizationSchemaViewController newAdvancedSchemaViewController];
    viewController.document = self.document;
    viewController.delegate = self;
    NSManagedObjectID *tableIDCopy = tableID.copy;
    viewController.tableObjectId = tableIDCopy;
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

- (void)addLinkViewControllerForQueryLink:(RptqQueryLinks *)link animated:(BOOL)animated {

    MADConnectorView *connectorView = [[MADConnectorView alloc] initWithFrame:CGRectZero];
    connectorView.userInteractionEnabled = NO;
    connectorView.objectIdTag = link.objectID;
    
    self.connectionViewsByObjectID[link.objectID] = connectorView;
    
    if (animated == NO) {
        [self layoutQueryLinkViewController:link];
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
        [self layoutQueryLinkViewController:link];
    }
}

#pragma mark - Layout

- (void)didMoveFieldRect:(id)sender animated:(BOOL)animated {
    if ([sender isKindOfClass:[MADQueryVisualizationSchemaViewController class]]) {
        MADQueryVisualizationSchemaViewController *controller = (MADQueryVisualizationSchemaViewController *)sender;
        
        RptqQueryTable *queryTable = [RptqQueryTable queryTableWithObjectID:controller.tableObjectId
                                                       managedObjectContext:self.document.managedObjectContext];
        for (RptqQueryLinks *queryLink in queryTable.inQuery.hasQueryLinks) {
            if ([queryLink.hasLeftField.inQueryTable isEqualTo:queryTable] ||
                [queryLink.hasRightField.inQueryTable isEqualTo:queryTable]) {
                [self layoutQueryLinkViewController:queryLink];
            }
        }
    }
}

- (void)layoutQueryLinkViewController:(RptqQueryLinks *)queryLink {

    MADConnectorView *connectorView = self.connectionViewsByObjectID[queryLink.objectID];
    const CGFloat paddingLeft = 44.0000f;
    
    MADQueryVisualizationSchemaViewController *leftTableViewController = self.controllersByObjectID[queryLink.hasLeftField.inQueryTable.objectID];
    CGRect leftCellFrameInTable = [leftTableViewController rectForFieldWithObjectId:queryLink.hasLeftField.objectID inView:leftTableViewController.view];
    CGFloat leftTableBottomY = leftTableViewController.schemaTableViewController.frame.origin.y + leftTableViewController.schemaTableViewController.frame.size.height;
    
    if (leftCellFrameInTable.origin.y + leftCellFrameInTable.size.height > leftTableBottomY) {
        leftCellFrameInTable = CGRectMake(leftCellFrameInTable.origin.x, leftTableBottomY - leftCellFrameInTable.size.height, leftCellFrameInTable.size.width, leftCellFrameInTable.size.height);
    } else if (leftCellFrameInTable.origin.y < leftTableViewController.schemaTableViewController.frame.origin.y) {
        leftCellFrameInTable = CGRectMake(leftCellFrameInTable.origin.x, leftTableViewController.schemaTableViewController.frame.origin.y, leftCellFrameInTable.size.width, leftCellFrameInTable.size.height);
    }
    CGRect leftCellFrameInView = [self.scrollView.contentView convertRect:leftCellFrameInTable fromView:leftTableViewController.view];
    CGPoint leftCellAnchorPoint = CGCenterOfRect(leftCellFrameInView);
    leftCellAnchorPoint.x += paddingLeft;
    leftCellAnchorPoint.y += 0.0000f;
    
    MADQueryVisualizationSchemaViewController *rightTableViewController = self.controllersByObjectID[queryLink.hasRightField.inQueryTable.objectID];
    CGRect rightCellFrameInTable = [rightTableViewController rectForFieldWithObjectId:queryLink.hasRightField.objectID
                                                                               inView:rightTableViewController.view];
    CGFloat rightTableBottomY = rightTableViewController.schemaTableViewController.frame.origin.y + rightTableViewController.schemaTableViewController.frame.size.height;
    
    if (rightCellFrameInTable.origin.y + rightCellFrameInTable.size.height > rightTableBottomY) {
        rightCellFrameInTable = CGRectMake(rightCellFrameInTable.origin.x, rightTableBottomY - rightCellFrameInTable.size.height, rightCellFrameInTable.size.width, rightCellFrameInTable.size.height);
    } else if (rightCellFrameInTable.origin.y < rightTableViewController.schemaTableViewController.frame.origin.y) {
        rightCellFrameInTable = CGRectMake(rightCellFrameInTable.origin.x, rightTableViewController.schemaTableViewController.frame.origin.y, rightCellFrameInTable.size.width, rightCellFrameInTable.size.height);
    }
    
    CGRect rightCellFrameInView = [self.scrollView.contentView convertRect:rightCellFrameInTable fromView:rightTableViewController.view];
    CGPoint rightCellAnchorPoint = CGCenterOfRect(rightCellFrameInView);
    rightCellAnchorPoint.x -= paddingLeft;
    rightCellAnchorPoint.y += -2.0000f;
    
    bool topLeftToBottomRight;
    CGFloat extraInset = 0.0000f;
    if (leftCellAnchorPoint.x < rightCellAnchorPoint.x) {
        if (leftCellAnchorPoint.y < rightCellAnchorPoint.y) {
            topLeftToBottomRight = true;
        } else {
            topLeftToBottomRight = false;
            leftCellAnchorPoint.y += leftCellFrameInTable.size.height;
            rightCellAnchorPoint.y -= rightCellFrameInTable.size.height;
        }
        connectorView.leftViewIsInital = true;
    } else {
        extraInset = -20.0000f;
        if (leftCellAnchorPoint.y < rightCellAnchorPoint.y) {
            topLeftToBottomRight = false;
        } else {
            topLeftToBottomRight = true;
            leftCellAnchorPoint.y += leftCellFrameInTable.size.height;
            rightCellAnchorPoint.y -= rightCellFrameInTable.size.height;
        }
        connectorView.leftViewIsInital = false;
    }
    connectorView.topLeftToBottomRight = topLeftToBottomRight;
    
    connectorView.frame = CGRectMake(leftCellAnchorPoint.x - 10.0000f - extraInset, leftCellAnchorPoint.y - 10.0000f,
                                     rightCellAnchorPoint.x - leftCellAnchorPoint.x + 20.0000f + (extraInset * 2.0000f),
                                     rightCellAnchorPoint.y - leftCellAnchorPoint.y + 20.0000f);;

    [connectorView setNeedsDisplay];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView { }

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self updateCache];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView { }

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale { }

- (void)scrollViewDidScroll:(UIScrollView *)scrollView { }

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView { }

- (void)scrollViewDidZoom:(UIScrollView *)scrollView { }

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView { return NO; }

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView { }

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView { }

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view { }

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset { }

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView { return self.scrollView.contentView; }

@end
