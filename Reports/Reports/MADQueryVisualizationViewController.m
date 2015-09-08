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
#import "MADocument.h"
#import "MADConstants.h"
#import "MTApplicationInstance.h"
#import "MADViewControllerSQL.h"

#import "RptqDocument.h"
#import "RptqDatabase.h"

#import "RptqQueryLinks.h"
#import "RptqQueryTable.h"
#import "RptqQueryField.h"
#import "RptqDatabaseSchemaTable.h"

#import "MTConnectionViewController.h"
#import "MTConnectorView.h"

#import "MADQueryVisualizationSchemaViewController.h"
#import "MADWatermarkView.h"

#import "RptqQuery+Extras.h"
#import "RptqQueryTable+Extras.h"

#import "CGGeometry+Extras.h"
#import "CGAffineTransform+Common.h"
#import "UIDevice+Hack.h"

#import "UIView+NSObjectIdTag.h"

#import "MTLinkedList.h"
#import "MTGraph.h"

#import "RptqDocument+Extras.h"

#import "MTQueryTest.h"
#import "NSError+Constructors.h"
#import "UIViewController+Designer.h"
#import "MADQueryVisualizationSchemaViewController+Designer.h"
#import "NSLayoutConstraint+QueryVisulization.h"
#import "MADQueryVisulizationTableDefination.h"

#import "MADQueryVisulizationDefination.h"
#import "NSFileManager+Common.h"
#import "MADQueryVisualizationCacheData.h"

NSString * const MTKeyIsTopLevel = @"MTKeyIsTopLevel";

NSString * const MTIdentifierCollisionBoundryTop = @"MTIdentifierCollisionBoundryLandscapeTop";
NSString * const MTIdentifierCollisionBoundryRight = @"MTIdentifierCollisionBoundryLandscapeRight";
NSString * const MTIdentifierCollisionBoundryBottom = @"MTIdentifierCollisionBoundryLandscapeBottom";
NSString * const MTIdentifierCollisionBoundryLeft = @"MTIdentifierCollisionBoundryLandscapeLeft";

static const CGFloat contentViewWidth = 1024.0000f;
static const CGFloat contentViewHeight = 1024.0000f;
static const CGFloat schemaViewWidth = 120.0000f;
static const CGFloat schemaViewHeight = 140.0000f;

static NSString * const CacheExt = @"qvvc";

typedef void(^MTBlockResultVoid)(void);

@interface MADQueryVisualizationViewController ()
<UIGestureRecognizerDelegate,
    UIScrollViewDelegate,
    UIPopoverControllerDelegate,
    UICollisionBehaviorDelegate,
    UIDynamicAnimatorDelegate,
    MADQueryVisualizationSchemaDelegate,
    MTViewControllerProtocol>

@property (nonatomic, strong) IBOutlet UIToolbar *toolbarBottom;
@property (nonatomic, strong) IBOutlet UIView *backgroundContainer;

@property (nonatomic, strong) MADWatermarkScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) NSMutableArray *rootTables;

@property (nonatomic, strong) NSMutableArray *viewControllersTables;
@property (nonatomic, strong) NSMutableArray *viewControllersLinks;
@property (nonatomic, strong) NSMutableSet *tableIds;

@property (nonatomic, strong) NSMutableDictionary *controllersForObjectIds;     //Tables and links
@property (nonatomic, strong) NSMutableDictionary *controllersForObjectIdsLink; //Only query links

@property (nonatomic, strong) UIDynamicAnimator *dynamicAnimator;
@property (nonatomic, strong) UICollisionBehavior *collisionBehavior;
@property (nonatomic, strong) UIDynamicItemBehavior *dynamicItemBehavior;
@property (nonatomic, strong) NSMutableDictionary *attachmentBehaviorsTables;
@property (nonatomic, strong) NSMutableDictionary *attachmentBehaviorsLinks;

@property (nonatomic, strong) NSURL *localCacheFileUrl;

@property (nonatomic, strong) MADQueryVisualizationCacheData *cacheData;

@end

@implementation MADQueryVisualizationViewController

- (void)dealloc {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    return self;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [self.dynamicAnimator removeAllBehaviors];
    [self.viewControllersTables removeAllObjects];
    [self.viewControllersLinks removeAllObjects];
    [self.tableIds removeAllObjects];
    [self.controllersForObjectIds removeAllObjects];
    [self.controllersForObjectIdsLink removeAllObjects];
    [self.attachmentBehaviorsTables removeAllObjects];
    [self.attachmentBehaviorsLinks removeAllObjects];
    [self.rootTables removeAllObjects];
}

- (void)commonInit {
    NSMutableArray *viewControllersTables = [[NSMutableArray alloc] init];
    self.viewControllersTables = viewControllersTables;

    NSMutableArray *viewControllersLinks = [[NSMutableArray alloc] init];
    self.viewControllersLinks = viewControllersLinks;
    
    NSMutableSet *tableObjectIds = [[NSMutableSet alloc] init];
    self.tableIds = tableObjectIds;
    
    NSMutableDictionary *controllersForObjectIds = [[NSMutableDictionary alloc] init];
    self.controllersForObjectIds = controllersForObjectIds;
    
    NSMutableDictionary *controllersForObjectIdsLink = [[NSMutableDictionary alloc] init];
    self.controllersForObjectIdsLink = controllersForObjectIdsLink;
    
    NSMutableDictionary *attachmentBehaviorsTables = [[NSMutableDictionary alloc] init];
    self.attachmentBehaviorsTables = attachmentBehaviorsTables;
    
    NSMutableDictionary *attachmentBehaviorsLinks = [[NSMutableDictionary alloc] init];
    self.attachmentBehaviorsLinks = attachmentBehaviorsLinks;
    
    NSMutableArray *rootTables = [[NSMutableArray alloc] init];
    self.rootTables = rootTables;
    
    NSArray *dynamicItems = @[];
    UIDynamicItemBehavior *dynamicItemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:dynamicItems];
    dynamicItemBehavior.allowsRotation = NO;
    dynamicItemBehavior.resistance = 0.0000f;
    self.dynamicItemBehavior = dynamicItemBehavior;
    
    NSArray *collisionItems = @[];
    UICollisionBehavior *collisionBehavior = [[UICollisionBehavior alloc] initWithItems:collisionItems];
    collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    collisionBehavior.collisionMode = UICollisionBehaviorModeItems;
    collisionBehavior.collisionDelegate = self;
    self.collisionBehavior = collisionBehavior;
    
}

- (NSString *)cacheFileName {
    return [MADQueryVisualizationViewController cacheFileNameForDocument:self.document];
}

+ (NSString *)cacheFileNameForDocument:(MADocument *)document {
    return [self cacheFileNameForFileName:document.fileURL.lastPathComponent.stringByDeletingPathExtension];
}

+ (NSString *)cacheFileNameForFileName:(NSString *)filename {
    NSString *fileName = [NSString stringWithFormat:@"%lu", (unsigned long)filename.hash];
    return [fileName stringByAppendingPathExtension:CacheExt];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.document = [MTApplicationInstance mainInstance].openDocument;

    NSURL *cachedFilesDirectories = [[NSFileManager defaultManager] localCacheDirectoryForGroupIdentifier:MADIdentifierGroup];
    NSString *cacheFileName = [self cacheFileName];
    NSURL *cacheFileUrl = [cachedFilesDirectories URLByAppendingPathComponent:cacheFileName isDirectory:NO];
    self.localCacheFileUrl = cacheFileUrl;
    
    CGFloat borderWidth = [UIDevice isRetnaDisplay] ? 0.5000f : 1.0000f;
    UIColor *borderColor = [UIColor lightGrayColor];
    self.backgroundContainer.layer.borderWidth = borderWidth;
    self.backgroundContainer.layer.borderColor = borderColor.CGColor;
    
    UIView *containerView = [[UIView alloc] initWithFrame:self.backgroundContainer.bounds];
    containerView.contentMode = UIViewContentModeScaleAspectFit;
    containerView.autoresizesSubviews = NO;
    containerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    containerView.backgroundColor = [UIColor greenColor];
    self.backgroundContainer.backgroundColor = [UIColor redColor];
    
    MADWatermarkScrollView *scrollView = [[MADWatermarkScrollView alloc] initWithFrame:self.backgroundContainer.bounds];
    scrollView.delegate = self;
    [scrollView addSubview:containerView];
    
    [self.backgroundContainer addSubview:scrollView];
    
    NSLayoutConstraint *layoutConstraintSizeHeight = [NSLayoutConstraint heightForView:containerView andHeight:contentViewHeight];
    NSLayoutConstraint *layoutConstraintSizeWidth = [NSLayoutConstraint widthForView:containerView andWidth:contentViewWidth];
    
    NSArray *containerViewConstraints = @[layoutConstraintSizeHeight, layoutConstraintSizeWidth];
    [containerView addConstraints:containerViewConstraints];
    
    
    NSDictionary *viewDictionary = @{@"sv" : scrollView,
                                     @"cv" : containerView,
                                     @"bg" : self.backgroundContainer};
    
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
    
    NSArray *constraints3 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[cv]|" options:NSLayoutFormatAlignAllCenterX metrics:0 views:viewDictionary];
    NSArray *constraints4 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[cv]|" options:NSLayoutFormatAlignAllCenterY metrics:0 views:viewDictionary];
    [constraints addObjectsFromArray:constraints3];
    [constraints addObjectsFromArray:constraints4];
    [scrollView addConstraints:constraints];
    [constraints removeAllObjects];
    
    self.scrollView = scrollView;
    self.contentView = containerView;
    
    UIDynamicAnimator *animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.contentView];
    [animator addBehavior:self.dynamicItemBehavior];
    [animator addBehavior:self.collisionBehavior];
    animator.delegate = self;
    self.dynamicAnimator = animator;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(managedObjectContextWillSave:)
                                                 name: NSManagedObjectContextWillSaveNotification
                                               object: self.document.activeDocumentModel.managedObjectContext];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(managedObjectContextDidSave:)
                                                 name: NSManagedObjectContextDidSaveNotification
                                               object: self.document.activeDocumentModel.managedObjectContext];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self archiveCache];
    [self clearScreen];
    
    NSAssert(self.document != nil, @"We need a document.");
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: NSManagedObjectContextWillSaveNotification
                                                  object: self.document.activeDocumentModel.managedObjectContext];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: NSManagedObjectContextDidSaveNotification
                                                  object: self.document.activeDocumentModel.managedObjectContext];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (animated) {
        [self.scrollView flashScrollIndicators];
    }
    [self reloadDocument:self.document animated:YES];
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.scrollView.contentSize = CGSizeMake(contentViewWidth, contentViewHeight);
    self.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width, self.bottomLayoutGuide.length, CGSizeZero.height);
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender { }

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    for (UIViewController *subviewController in [self childViewControllers]) {
        [self didMoveFieldRect: subviewController animated: YES];
    }
    
    [self.collisionBehavior removeBoundaryWithIdentifier:MTIdentifierCollisionBoundryBottom];
    [self.collisionBehavior removeBoundaryWithIdentifier:MTIdentifierCollisionBoundryTop];
    [self.collisionBehavior removeBoundaryWithIdentifier:MTIdentifierCollisionBoundryLeft];
    [self.collisionBehavior removeBoundaryWithIdentifier:MTIdentifierCollisionBoundryRight];
    
    CGPoint fromPoint = self.contentView.frame.origin;
    CGPoint toPoint = CGPointMake(self.contentView.frame.origin.x + self.contentView.frame.size.width,
                                  self.contentView.frame.origin.y);
    
    [self.collisionBehavior addBoundaryWithIdentifier: MTIdentifierCollisionBoundryTop
                                            fromPoint: fromPoint
                                              toPoint: toPoint];
    
    fromPoint = toPoint;
    toPoint = CGPointMake(toPoint.x,
                          self.contentView.frame.origin.y + self.contentView.frame.size.height);
    [self.collisionBehavior addBoundaryWithIdentifier: MTIdentifierCollisionBoundryRight
                                            fromPoint: fromPoint
                                              toPoint: toPoint];
    
    fromPoint = toPoint;
    toPoint = CGPointMake(self.contentView.frame.origin.x,
                          toPoint.y);
    [self.collisionBehavior addBoundaryWithIdentifier: MTIdentifierCollisionBoundryBottom
                                            fromPoint: fromPoint
                                              toPoint: toPoint];
    
    fromPoint = toPoint;
    toPoint = self.contentView.frame.origin;
    [self.collisionBehavior addBoundaryWithIdentifier: MTIdentifierCollisionBoundryLeft
                                            fromPoint: fromPoint
                                              toPoint: toPoint];
}

#pragma mark Scroll view helper

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController { }

#pragma mark - NSManagedObjectContext observer

- (void)managedObjectContextWillSave:(NSNotification *)notification { }

- (void)managedObjectContextDidSave:(NSNotification *)notification {
    
    NSArray *insertedObjects = notification.userInfo[NSInsertedObjectsKey];
    NSArray *updatedObjects = notification.userInfo[NSUpdatedObjectsKey];
    NSArray *deletedObjects = notification.userInfo[NSDeletedObjectsKey];
    
    RptqQuery *updatedQuery = nil;
    RptqQueryTable *updatedTable = nil;
    
#pragma mark Handle inserted objects
    
    for (id insertedObject in insertedObjects) {
        
        if ([insertedObject isKindOfClass:[RptqQueryLinks class]]) {
            
            //User adding a link starting point...
            RptqQueryLinks *insertedQueryLinks = insertedObject;
            [self insertQueryLink:insertedQueryLinks];
            
        } else if ([insertedObject isKindOfClass:[RptqQueryTable class]]) {
            
            //User adding a table starting point...
            RptqQueryTable *insertedQueryTable = insertedObject;
            [self insertQueryTable:insertedQueryTable];
        }
    }
    
    for (id updatedObject in updatedObjects) {
        if ([updatedObject isKindOfClass:[RptqQueryTable class]]) {
            updatedTable = updatedObject;
        } else if ([updatedObject isKindOfClass:[RptqQuery class]]) {
            updatedQuery = updatedObject;
        }
    }
    
    if (updatedQuery && updatedTable) {
        if ([[updatedTable inQuery] isEqualTo:updatedQuery]) {
            // FIXME: Allow user to edit table.
        } else {
            
            UIViewController *viewController = self.controllersForObjectIds[updatedTable.objectID.URIRepresentation];
            
            if ([viewController isKindOfClass:[MADQueryVisualizationSchemaViewController class]]) {
                
                [self.rootTables removeObject:updatedTable.objectID.URIRepresentation];
                
                // Reposition existing tables
                NSUInteger counter = 0;
                for (NSURL *queryTableUrl in self.rootTables) {
                    CGPoint attachmentPoint = CGPointMake(CGPointZero.x, (self.contentView.bounds.size.height / (self.rootTables.count + 1)) * (counter + 1));
                    UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviorsTables[queryTableUrl];
                    attachmentBehavior.anchorPoint = attachmentPoint;
                    counter++;
                }
                
                // FIXME: Maybe block this and move it off screen.
                UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviorsTables[updatedTable.objectID.URIRepresentation];
                [self.dynamicAnimator removeBehavior:attachmentBehavior];
                [self dynamicsRemoveItem:(MADQueryVisualizationSchemaViewController *)viewController];
                [self.attachmentBehaviorsTables removeObjectForKey:updatedTable.objectID.URIRepresentation];
                
                // FIXME: do give time for animations... Can't imagine this will work.
                [viewController willMoveToParentViewController:nil];
                [viewController.view removeFromSuperview];
                [viewController removeFromParentViewController];
                
                for (RptqQueryLinks *link in [updatedQuery hasQueryLinks]) {
                    if ([link.hasLeftField.inQueryTable.objectID isEqual: updatedTable.objectID] ||
                        [link.hasRightField.inQueryTable.objectID isEqual: updatedTable.objectID]) {
                        
                        UIViewController *linkViewController = self.controllersForObjectIdsLink[link.objectID.URIRepresentation];
                        if (linkViewController != nil) {
                            [self removeViewController:linkViewController];
                        }
                        //Delete the query link view controller here, because it's bogus
                        
                    }
                }
                
                //loop though each link here, and do as above if the link contains the table... but will it be there?... check the updated query
                
            } else if ([viewController.view isKindOfClass:[MTConnectorView class]]) {
                
                UIViewController *viewController = self.controllersForObjectIds[updatedTable.objectID.URIRepresentation];
                CGAffineTransform swingTransform = CGAffineTransformSwing();
                CGPoint center = viewController.view.center;
                CGFloat animationDuration = 0.3000f;
                
                __weak UIViewController *weakViewController = viewController;
                [UIView animateWithDuration:animationDuration delay:0.0000f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    weakViewController.view.bounds = CGRectZero;
                    weakViewController.view.center = center;
                    weakViewController.view.transform = swingTransform;
                } completion:^(BOOL finished) {
                    [weakViewController willMoveToParentViewController:nil];
                    [weakViewController.view removeFromSuperview];
                    [weakViewController removeFromParentViewController];
                }];
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
}

- (void)insertQueryTable:(RptqQueryTable *)insertedQueryTable {
    NSLog(@"%s %d", __PRETTY_FUNCTION__, __LINE__);
    
    CGFloat segHeight = self.contentView.bounds.size.height / (self.rootTables.count + 2);
    
    // Reposition existing tables
    // FIXME: Good place for block iterate?
    NSUInteger counter = 0;
    for (NSURL *queryTableUrl in self.rootTables) {
        CGPoint attachmentPoint = CGPointMake(CGPointZero.x, segHeight * (counter + 1));
        UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviorsTables[queryTableUrl];
        attachmentBehavior.anchorPoint = attachmentPoint;
        counter++;
    }
    
    CGFloat attachmentPointY = segHeight * (self.rootTables.count + 1);
    CGPoint insertTableAnchorPoint = CGPointMake(CGPointZero.x, attachmentPointY);
    
    // Insert new and unlinked query table
    
    //Going to assume that it's a top level table.
    [self.rootTables addObject:insertedQueryTable.objectID.URIRepresentation];
    
    // Insert table
    MADQueryVisualizationSchemaViewController *viewController = [self addSchemaViewControllerForTable:insertedQueryTable root:YES animated:YES];
    
    UIAttachmentBehavior *attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:viewController attachedToAnchor:insertTableAnchorPoint];
    attachmentBehavior.length = 0.0000f;
    [self.dynamicAnimator addBehavior:attachmentBehavior];
    self.attachmentBehaviorsTables[viewController.view.objectIdTag.URIRepresentation] = attachmentBehavior;
}

- (void)insertQueryLink:(RptqQueryLinks *)insertedQueryLinks {
    
    //RptqQuery *query = insertedQueryLinks.inQuery;
    MADQueryVisulizationDefination *queryDef = [[MADQueryVisulizationDefination alloc] initWithQuery:insertedQueryLinks.inQuery];
    
    RptqQueryTable *leftTable = insertedQueryLinks.hasLeftField.inQueryTable;
    MADQueryVisualizationSchemaViewController *leftTableViewController = self.controllersForObjectIds[leftTable.objectID.URIRepresentation];
    
    RptqQueryTable *rightTable = insertedQueryLinks.hasRightField.inQueryTable;
    MADQueryVisualizationSchemaViewController *rightTableViewController = self.controllersForObjectIds[rightTable.objectID.URIRepresentation];
    
    // Remove starting point connection if one of the tables is in the link.
    BOOL startingPointRemoved = NO;
    NSURL *queryTableRemoved = nil;
    NSUInteger startingPointsRemovedCounter = 0;
    for (NSURL *queryTableUrl in self.rootTables) {
        
        NSURL *removeableTable = nil;
        if ([queryDef.startingPoints containsObject: queryTableUrl] == NO) {
            if ([leftTable.objectID.URIRepresentation isEqual:queryTableUrl]) {
                removeableTable = queryTableUrl;
            } else if ([rightTable.objectID.URIRepresentation isEqual:queryTableUrl]) {
                removeableTable = queryTableUrl;
            }
        }
        if (removeableTable) {
            queryTableRemoved = queryTableUrl;
            UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviorsTables[removeableTable];
            [self.dynamicAnimator removeBehavior:attachmentBehavior];
            [self.attachmentBehaviorsTables removeObjectForKey:removeableTable];
            startingPointRemoved = YES;
            startingPointsRemovedCounter++;
            if (startingPointsRemovedCounter == 2) {
                break;
            }
        }
    }
    
    // Reposition existing starting point-tables
    if (startingPointRemoved) {
        [self.rootTables removeObject:queryTableRemoved];
        
        CGFloat segHeight = (self.contentView.bounds.size.height / (self.rootTables.count + 2));
        NSUInteger counter = 0;
        for (NSURL *queryTable in self.rootTables) {
            CGFloat attachmentPointY = segHeight * (counter + 1);
            CGPoint attachmentPoint = CGPointMake(CGPointZero.x, attachmentPointY);
            UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviorsTables[queryTable];
            attachmentBehavior.anchorPoint = attachmentPoint;
            counter++;
        }
    }

    //Add connections between MTQueryBuilderAdvancedSchemaViewController
    if ([leftTableViewController isEqual:rightTableViewController] == NO) {
        UIAttachmentBehavior *attachmentBehavior = [MADQueryVisualizationViewController attachmentBehaviorLinkWithLeftViewController: leftTableViewController
                                                                                                              andRightViewController: rightTableViewController];
        [self.dynamicAnimator addBehavior:attachmentBehavior];
        self.attachmentBehaviorsLinks[insertedQueryLinks.objectID.URIRepresentation] = attachmentBehavior;
        
        //Add animation layer
        [self addLinkViewControllerForQueryLink: insertedQueryLinks animated:YES];
    }
}

#pragma mark View Controller Container Custom Handlers

- (void)viewControllerDidFinish:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{ }];
}

#pragma mark - UIDynamicAnimatorDelegate

- (void)dynamicAnimatorWillResume:(UIDynamicAnimator *)animator { }

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator { }

- (void)updateCache {
    if (self.document != nil) {
        MADQueryVisulizationDefination *queryDef = [[MADQueryVisulizationDefination alloc] initWithQuery:self.document.activeDocumentModel.query];
        MADQueryVisualizationCacheData *cacheData = [[MADQueryVisualizationCacheData alloc] init];
        for (MTPair *pair in queryDef.topologicallySortedTables) {
            MTVertex *tableIdVertext = pair.former;
            if (tableIdVertext.object != nil) {
                
                MADQueryVisualizationSchemaViewController *viewController = self.controllersForObjectIds[((NSManagedObjectID *)tableIdVertext.object).URIRepresentation];
                
                MADQueryVisulizationTableDefination *tableDef = [[MADQueryVisulizationTableDefination alloc] init];
                tableDef.center = viewController.view.center;
                tableDef.root = [queryDef.startingPoints containsObject: ((NSManagedObjectID *)tableIdVertext.object).URIRepresentation];
                [cacheData addTableDefination:tableDef forObjectID:tableIdVertext.object];
            }
        }
        cacheData.scrollViewContentOffset = self.scrollView.contentOffset;
        cacheData.scrollViewZoomScale = self.scrollView.zoomScale;
        self.cacheData = cacheData;
    }
}

- (void)archiveCache {
    NSError *error = nil;
    NSData *d = [NSKeyedArchiver archivedDataWithRootObject:self.cacheData];
    [d writeToURL:self.localCacheFileUrl options:NSDataWritingAtomic error:&error];
}

- (MADQueryVisualizationCacheData *)loadCache {
    MADQueryVisualizationCacheData *result;
    NSError * _Nullable __autoreleasing * _Nullable error = nil;
    NSData *data = [[NSData alloc] initWithContentsOfURL:self.localCacheFileUrl options:NSDataReadingUncached error:error];
    if (error != nil) {
        [[NSFileManager defaultManager] removeItemAtURL:self.localCacheFileUrl error:error];
        result = nil;
    } else {
        id r = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if ([r isKindOfClass:[MADQueryVisualizationCacheData class]]) {
            result = r;
        } else {
            [[NSFileManager defaultManager] removeItemAtURL:self.localCacheFileUrl error:error];
            result = nil;
        }
    }
    return result;
}

#pragma mark - Gesture recognizer actions

- (void)tapPiece:(UITapGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer state] == UIGestureRecognizerStateEnded) {
        UIView *gestureRecognizerView = [gestureRecognizer view];
        [self.contentView bringSubviewToFront:gestureRecognizerView];
        for (UIView *view in self.contentView.subviews) {
            if ([view isKindOfClass:[MTConnectorView class]]) {
                [self.contentView bringSubviewToFront:view];
            }
        }
    }
}

- (void)panPiece:(UIPanGestureRecognizer *)gestureRecognizer {
    UIWindow *window = [[UIApplication sharedApplication] windows][0];
    CGPoint gestureLocation = [gestureRecognizer locationInView:window];
    UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviorsTables[gestureRecognizer.view.objectIdTag.URIRepresentation];
    attachmentBehavior.anchorPoint = [window convertPoint:gestureLocation toView:self.contentView];
     MADQueryVisualizationSchemaViewController *viewController = self.controllersForObjectIds[gestureRecognizer.view.objectIdTag.URIRepresentation];
    viewController.view.center = attachmentBehavior.anchorPoint;
    [self.dynamicAnimator updateItemUsingCurrentState:viewController];
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self updateCache];
    }

}

#pragma mark - Change UI on IR Diagram

- (void)clearScreen {
    for (UIViewController *viewController in self.viewControllersLinks) {
        [self removeViewController:viewController];
    }

    for (MADQueryVisualizationSchemaViewController *  _Nonnull viewController in self.viewControllersTables) {
        [self removeViewController:viewController];
        UIAttachmentBehavior *attachmentBehaviorForObjectId = self.attachmentBehaviorsTables[viewController.view.objectIdTag.URIRepresentation];
        [self.dynamicAnimator removeBehavior:attachmentBehaviorForObjectId];
        [self.attachmentBehaviorsTables removeObjectForKey:viewController.view.objectIdTag.URIRepresentation];
        [self dynamicsRemoveItem:viewController];
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
        [self.viewControllersTables removeAllObjects];
        [self.viewControllersLinks removeAllObjects];
        [self.tableIds removeAllObjects];
        [self.controllersForObjectIds removeAllObjects];     //Tables and links
        [self.controllersForObjectIdsLink removeAllObjects];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.localCacheFileUrl.path]) {
            MADQueryVisualizationCacheData *schemaLocations = [self loadCache];
            self.cacheData = schemaLocations;
            [self displayQuery:documentReport.activeDocumentModel.query withSchemaHints:schemaLocations animated:animated];
        } else {
            [self displayQuery:documentReport.activeDocumentModel.query animated:animated];
        }
    }
}

- (void)displayQuery:(RptqQuery *)query withSchemaHints:(MADQueryVisualizationCacheData *)cacheData animated:(BOOL)animated {
    if (cacheData != nil) {
        MADQueryVisulizationDefination *queryDef = [[MADQueryVisulizationDefination alloc] initWithQuery:query];
        for (MTPair *pair in queryDef.topologicallySortedTables) {
            MTVertex *tableIdVertext = pair.former;
            if (tableIdVertext.object != nil) {
                RptqQueryTable *table = (RptqQueryTable *)[self.document.managedObjectContext objectWithID:tableIdVertext.object];
                BOOL topLevel = [queryDef.startingPoints containsObject: table.objectID.URIRepresentation];
                MADQueryVisualizationSchemaViewController *viewController = [self addSchemaViewControllerForTable:table root:topLevel animated:animated];
                MADQueryVisulizationTableDefination *tableDef = [cacheData tableDefinationForObjectID:table.objectID];
                viewController.view.center = tableDef.center;
                UIAttachmentBehavior *attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:viewController attachedToAnchor:tableDef.center];
                attachmentBehavior.length = 0.0000f;
                [self.dynamicAnimator addBehavior:attachmentBehavior];
                self.attachmentBehaviorsTables[viewController.view.objectIdTag.URIRepresentation] = attachmentBehavior;
                if (topLevel) {
                    [self.rootTables addObject:table.objectID.URIRepresentation];
                }
            }
        }
        
        for (RptqQueryLinks *queryLink in query.hasQueryLinks) {
            [self addLinkViewControllerForQueryLink:queryLink animated:animated];
        }
        
        self.scrollView.contentOffset = cacheData.scrollViewContentOffset;
        self.scrollView.zoomScale = cacheData.scrollViewZoomScale;
        
    } else {
        [self displayQuery:query animated:animated];
    }
}

- (void)displayQuery:(RptqQuery *)query animated:(BOOL)animated {
    
    MADQueryVisulizationDefination *queryDef = [[MADQueryVisulizationDefination alloc] initWithQuery:query];
    NSInteger tableCounter = 0;
    for (MTPair *pair in queryDef.topologicallySortedTables) {
        MTVertex *tableIdVertext = pair.former;
        if (tableIdVertext.object != nil) {
            RptqQueryTable *table = (RptqQueryTable *)[self.document.managedObjectContext objectWithID:tableIdVertext.object];
            BOOL topLevel = [queryDef.startingPoints containsObject: table.objectID.URIRepresentation];
            MADQueryVisualizationSchemaViewController *viewController = [self addSchemaViewControllerForTable:table root:topLevel animated:animated];
            viewController.view.center = self.contentView.center;
            UIAttachmentBehavior *attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:viewController attachedToAnchor:self.contentView.center];
            attachmentBehavior.length = 0.0000f;
            [self.dynamicAnimator addBehavior:attachmentBehavior];
            self.attachmentBehaviorsTables[viewController.view.objectIdTag.URIRepresentation] = attachmentBehavior;
            if (topLevel) {
                [self.rootTables addObject:table.objectID.URIRepresentation];
            }
            tableCounter++;
        }
    }
    
    // Display links
    for (RptqQueryLinks *queryLink in query.hasQueryLinks) {
        [self addLinkViewControllerForQueryLink:queryLink animated:animated];
    }
}

- (void)deleteQueryTable:(RptqQueryTable *)deletedQueryTable {
    
    BOOL startingPointTable = [self.rootTables containsObject:deletedQueryTable.objectID.URIRepresentation];
    if (startingPointTable) {
        CGPoint offScreen = CGPointMakeRandomOffscreen(400.0000f);
        UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviorsTables[deletedQueryTable.objectID.URIRepresentation];
        attachmentBehavior.anchorPoint = offScreen;
    }
    
    if (deletedQueryTable.inQuery != nil &&
        [self.tableIds containsObject: deletedQueryTable.objectID.URIRepresentation]) {
        MADQueryVisualizationSchemaViewController *viewController = self.controllersForObjectIds[deletedQueryTable.objectID.URIRepresentation];
        [viewController willMoveToParentViewController:nil];
        [viewController.view removeFromSuperview];
        [viewController removeFromParentViewController];
    }
}

- (void)deleteQueryLink:(RptqQueryLinks *)deletedQueryLinks {
    NSMutableSet *orphanedQueryTables = [[NSMutableSet alloc] init];
    
    RptqDatabase *database = self.document.activeDocumentModel.hasDatabaseSchemas.anyObject;
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
    
    NSSet *startingPoints = [NSSet setWithArray:self.rootTables];   //FIXME: This uses URLS, and the rest of this code expects tables.
    [orphanedQueryTables minusSet:startingPoints];  // Should only be one newly orphaned table.
    
    RptqQueryLinks *deletedLink = (RptqQueryLinks *)[self.document.managedObjectContext objectWithID:deletedQueryLinks.objectID];
    UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviorsLinks[deletedQueryLinks.objectID.URIRepresentation];
    
    for (RptqQueryTable *table in orphanedQueryTables) {
        
        RptqQueryTable *tableRightDeletedLink = table;
        MADQueryVisualizationSchemaViewController *viewController = self.controllersForObjectIds[tableRightDeletedLink.objectID.URIRepresentation];
        
        // Is there a link still pointing to the view controller after the delete, or
        //   do we need to make it top level?
        
        CGPoint attachmentPoint = CGPointMake(CGPointZero.x + self.contentView.frame.size.width,
                                              CGPointZero.y + self.contentView.frame.size.height / 2.0000f);
        
        UIAttachmentBehavior *anchorBehaviorNew = [[UIAttachmentBehavior alloc] initWithItem:viewController attachedToAnchor:attachmentPoint];
        anchorBehaviorNew.length = 0.0000f;
        [self.dynamicAnimator addBehavior:anchorBehaviorNew];
        self.attachmentBehaviorsTables[tableRightDeletedLink.objectID.URIRepresentation] = anchorBehaviorNew;
        [self.rootTables addObject: tableRightDeletedLink];
        
        // Disable collision behaviors before reposition
        // Reposition existing tables
        CGFloat segHeight = (self.contentView.bounds.size.height / (self.rootTables.count + 1));
        NSUInteger counter = 0;
        for (NSURL *queryTable in self.rootTables) {
            UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviorsTables[queryTable];
            attachmentBehavior.anchorPoint = CGPointMake(CGPointZero.x, segHeight * (counter + 1) - 22.0000f);
            counter++;
        }
    }
    
    [self.dynamicAnimator removeBehavior:attachmentBehavior];
    [self.attachmentBehaviorsLinks removeObjectForKey:deletedQueryLinks.objectID];
    
    UIViewController *linkViewController = self.controllersForObjectIdsLink[deletedLink.objectID.URIRepresentation];
    if (linkViewController != nil) {
        [self removeViewController:linkViewController];
    }
}

#pragma mark - UI Items

+ (UIAttachmentBehavior *)attachmentBehaviorLinkWithLeftViewController:(MADQueryVisualizationSchemaViewController *)viewControllerLeft
                                                andRightViewController:(MADQueryVisualizationSchemaViewController *)viewControllerRight {
    UIAttachmentBehavior *behavior = [[UIAttachmentBehavior alloc] initWithItem:viewControllerLeft attachedToItem:viewControllerRight];
    behavior.frequency = 0.0000f;
    behavior.damping = 1.0000f;
    behavior.length = 200.0000f;
    return behavior;
}

#pragma mark - Helper functions

- (void)addGesturesToViewController:(UIViewController *)viewController {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPiece:)];
    tapGesture .delegate = self;
    tapGesture.numberOfTapsRequired = 1;
    [viewController.view addGestureRecognizer:tapGesture];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panPiece:)];
    panGesture.delegate = self;
    [self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:panGesture];
    [tapGesture requireGestureRecognizerToFail:panGesture];
    [viewController.view addGestureRecognizer:panGesture];
}

#pragma mark - View Controller Container Data

- (void)removeViewController:(UIViewController *)viewController {
    CGFloat animationDuration = 0.3000f;
    CGAffineTransform swingTransform = CGAffineTransformSwing();
    
    if ([viewController isKindOfClass:[MADQueryVisualizationSchemaViewController class]]) {
        
        // FIXME: do give time for animations... Can't imagine this will work.
        [viewController willMoveToParentViewController:nil];
        [viewController.view removeFromSuperview];
        [viewController removeFromParentViewController];
        
    } else if ([viewController.view isKindOfClass:[MTConnectorView class]]) {
        
        CGPoint center = viewController.view.center;
        __weak UIViewController *weakViewController = viewController;
        [UIView animateWithDuration:animationDuration delay:0.0000f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [weakViewController.view setBounds:CGRectZero];
            [weakViewController.view setCenter:center];
            [weakViewController.view setTransform:swingTransform];
        } completion:^(BOOL finished) {
            [weakViewController willMoveToParentViewController:nil];
            [weakViewController.view removeFromSuperview];
            [weakViewController removeFromParentViewController];
        }];
    }
}

- (MADQueryVisualizationSchemaViewController *)addSchemaViewControllerForTable:(RptqQueryTable *)table
                                                                          root:(BOOL)root
                                                                      animated:(BOOL)animated {
    MADQueryVisualizationSchemaViewController *viewController = [MADQueryVisualizationSchemaViewController advancedSchemaViewController];
    viewController.document = self.document;
    viewController.delegate = self;
    viewController.tableObjectId = table.objectID;
    
    if (root) viewController.toolbar.backgroundColor = [UIColor blueColor];
    
    [self.tableIds addObject:table.objectID.URIRepresentation];
    self.controllersForObjectIds[table.objectID.URIRepresentation] = viewController;
    viewController.view.frame = CGRectMake(CGPointZero.x, CGPointZero.y, schemaViewWidth, schemaViewHeight);
    viewController.center = self.contentView.center;
    
    [self addGesturesToViewController:viewController];
    
    NSLayoutConstraint *width = [NSLayoutConstraint schemaViewWidthForView:viewController.view andWidth:viewController.view.frame.size.width];
    NSLayoutConstraint *height = [NSLayoutConstraint schemaViewHeightForView:viewController.view andHeight:viewController.view.frame.size.height];
    viewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *constraints = @[width, height];
    
    [self addChildViewController:viewController];
    if ([self.viewControllersTables containsObject:viewController] == NO) {
        [self.viewControllersTables addObject:viewController];
    }
    [self.contentView addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
    [self.contentView addConstraints:constraints];
    [self dynamicsAddItem:viewController];

    return viewController;
    
}

- (void)dynamicsAddItem:(id<UIDynamicItem>)item {
    [self.collisionBehavior addItem:item];
    [self.dynamicItemBehavior addItem:item];
}

- (void)dynamicsRemoveItem:(id<UIDynamicItem>)item {
    [self.collisionBehavior removeItem:item];
    [self.dynamicItemBehavior removeItem:item];
}

- (void)addLinkViewControllerForQueryLink:(RptqQueryLinks *)link animated:(BOOL)animated {
    MTConnectorView *connectorView = [[MTConnectorView alloc] initWithFrame:CGRectZero];
    connectorView.userInteractionEnabled = NO;
    connectorView.objectIdTag = link.objectID;
    
    UIViewController *connectorViewController = [[UIViewController alloc] init];
    connectorViewController.view = connectorView;
    
    self.controllersForObjectIds[link.objectID.URIRepresentation] = connectorViewController;
    self.controllersForObjectIdsLink[link.objectID.URIRepresentation] = connectorViewController;
    
    if (animated == NO) {
        [self layoutQueryLinkViewController:link animated:animated];
    }
    
    CGRect desiredFrame = connectorViewController.view.frame;
    CGPoint desiredCenter = connectorViewController.view.center;
    CGAffineTransform desiredTransform = connectorViewController.view.transform;
    
    connectorViewController.view.bounds = CGRectZero;
    connectorViewController.view.center = desiredCenter;
    if (animated) {
        connectorViewController.view.transform = animated ? CGAffineTransformIdentity : CGAffineTransformSwing();
    }
    
    
    [self addChildViewController:connectorViewController];
    if ([self.viewControllersLinks containsObject:connectorViewController] == NO) {
        [self.viewControllersLinks addObject:connectorViewController];
    }
    
    [self.contentView addSubview:connectorViewController.view];
    [connectorViewController didMoveToParentViewController:self];
    
    
    MTBlockResultVoid animateTwo = ^() {
        connectorViewController.view.frame = desiredFrame;
        connectorViewController.view.transform = desiredTransform;
    };
    
    if (animated) {
        
        CGFloat animationDuration = 0.3000f;
        [UIView animateWithDuration: animationDuration
                              delay: 0.0000f
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations: animateTwo
                         completion: NULL];
    } else {
        animateTwo();
    }
    
    if (animated) {
        [self layoutQueryLinkViewController:link animated:animated];
    }
    
}

- (void)didMoveFieldRect:(id)sender animated:(BOOL)animated {
    if ([sender isKindOfClass:[MADQueryVisualizationSchemaViewController class]]) {
        MADQueryVisualizationSchemaViewController *controller = (MADQueryVisualizationSchemaViewController *)sender;
        
        RptqQueryTable *queryTable = [RptqQueryTable queryTableWithObjectID:controller.tableObjectId
                                                       managedObjectContext:self.document.managedObjectContext];
        for (RptqQueryLinks *queryLink in queryTable.inQuery.hasQueryLinks) {
            if ([queryLink.hasLeftField.inQueryTable isEqualTo:queryTable] ||
                [queryLink.hasRightField.inQueryTable isEqualTo:queryTable]) {
                [self layoutQueryLinkViewController:queryLink animated:animated];
            }
        }
    }
}

- (void)layoutQueryLinkViewController:(RptqQueryLinks *)queryLink animated:(BOOL)animated {
    UIViewController *controller = self.controllersForObjectIdsLink[queryLink.objectID.URIRepresentation];
    MTConnectorView *connectorView = (MTConnectorView *)controller.view;
    const CGFloat paddingLeft = 44.0000f;
    
    MADQueryVisualizationSchemaViewController *leftTableViewController = self.controllersForObjectIds[queryLink.hasLeftField.inQueryTable.objectID.URIRepresentation];
    MADQueryVisualizationSchemaViewController *rightTableViewController = self.controllersForObjectIds[queryLink.hasRightField.inQueryTable.objectID.URIRepresentation];
    
    CGRect leftCellFrameInTable = [leftTableViewController rectForFieldWithObjectId:queryLink.hasLeftField.objectID
                                                                             inView:leftTableViewController.view];
    CGRect leftTableFrame = leftTableViewController.schemaTableViewController.frame;
    CGFloat leftTableBottomY = leftTableFrame.origin.y + leftTableFrame.size.height;
    if (leftCellFrameInTable.origin.y + leftCellFrameInTable.size.height > leftTableBottomY) {
        leftCellFrameInTable = CGRectMake(leftCellFrameInTable.origin.x, leftTableBottomY - leftCellFrameInTable.size.height, leftCellFrameInTable.size.width, leftCellFrameInTable.size.height);
    } else if (leftCellFrameInTable.origin.y < leftTableFrame.origin.y) {
        leftCellFrameInTable = CGRectMake(leftCellFrameInTable.origin.x, leftTableFrame.origin.y, leftCellFrameInTable.size.width, leftCellFrameInTable.size.height);
    }
    CGRect leftCellFrameInView = [self.contentView convertRect:leftCellFrameInTable fromView:leftTableViewController.view];
    CGPoint leftCellAnchorPoint = CGCenterOfRect(leftCellFrameInView);
    
    
    CGRect rightCellFrameInTable = [rightTableViewController rectForFieldWithObjectId:queryLink.hasRightField.objectID
                                                                               inView:rightTableViewController.view];
    CGRect rightTableFrame = rightTableViewController.schemaTableViewController.frame;
    CGFloat rightTableBottomY = rightTableFrame.origin.y + rightTableFrame.size.height;
    if (rightCellFrameInTable.origin.y + rightCellFrameInTable.size.height > rightTableBottomY) {
        rightCellFrameInTable = CGRectMake(rightCellFrameInTable.origin.x, rightTableBottomY - rightCellFrameInTable.size.height, rightCellFrameInTable.size.width, rightCellFrameInTable.size.height);
    } else if (rightCellFrameInTable.origin.y < rightTableFrame.origin.y) {
        rightCellFrameInTable = CGRectMake(rightCellFrameInTable.origin.x, rightTableFrame.origin.y, rightCellFrameInTable.size.width, rightCellFrameInTable.size.height);
    }
    CGRect rightCellFrameInView = [self.contentView convertRect:rightCellFrameInTable fromView:[rightTableViewController view]];
    CGPoint rightCellAnchorPoint = CGCenterOfRect(rightCellFrameInView);
    
    CGRect connectorFrame;
    
    CGFloat extraInset = 0.0000f;
    
    if (leftCellFrameInView.origin.x < rightCellFrameInView.origin.x &&
        leftCellFrameInView.origin.x + leftCellFrameInView.size.width < rightCellFrameInView.origin.x) {
        [connectorView setConnectorPositionB:MNSConnectorPositionA];
        leftCellAnchorPoint.x += paddingLeft;
        rightCellAnchorPoint.x -= paddingLeft;
    } else if (leftCellFrameInView.origin.x < rightCellFrameInView.origin.x &&
               leftCellFrameInView.origin.x + leftCellFrameInView.size.width > rightCellFrameInView.origin.x) {
        [connectorView setConnectorPositionB:MNSConnectorPositionB];
        leftCellAnchorPoint.x -= paddingLeft;
        rightCellAnchorPoint.x -= paddingLeft;
    } else if (leftCellFrameInView.origin.x > rightCellFrameInView.origin.x &&
               leftCellFrameInView.origin.x < rightCellFrameInView.origin.x + rightCellFrameInView.size.width) {
        [connectorView setConnectorPositionB:MNSConnectorPositionC];
        leftCellAnchorPoint.x += paddingLeft;
        rightCellAnchorPoint.x += paddingLeft;
    } else {
        [connectorView setConnectorPositionB:MNSConnectorPositionD];
        leftCellAnchorPoint.x -= paddingLeft;
        rightCellAnchorPoint.x += paddingLeft;
    }
    
    NSNumber *topLeftToBottomRight;
    if (leftCellAnchorPoint.x < rightCellAnchorPoint.x) {
        if (leftCellAnchorPoint.y < rightCellAnchorPoint.y) {
            topLeftToBottomRight = @(YES);
            connectorView.connectorPosition = MNSConnectorPositionA;
        } else {
            topLeftToBottomRight = @(NO);
            leftCellAnchorPoint.y += leftCellFrameInTable.size.height;
            rightCellAnchorPoint.y -= rightCellFrameInTable.size.height;
            connectorView.connectorPosition = MNSConnectorPositionB;
        }
        [connectorView setLeftViewIsInital:YES];
    } else {
        extraInset = -20.0000f;
        if (leftCellAnchorPoint.y < rightCellAnchorPoint.y) {
            topLeftToBottomRight = @(NO);
            connectorView.connectorPosition = MNSConnectorPositionC;
        } else {
            topLeftToBottomRight = @(YES);
            leftCellAnchorPoint.y += leftCellFrameInTable.size.height;
            rightCellAnchorPoint.y -= rightCellFrameInTable.size.height;
            connectorView.connectorPosition = MNSConnectorPositionD;
        }
        connectorView.leftViewIsInital = NO;
    }
    connectorView.topLeftToBottomRight = topLeftToBottomRight;
    
    connectorFrame = CGRectMake(leftCellAnchorPoint.x - 10.0000f - extraInset,
                                leftCellAnchorPoint.y - 10.0000f,
                                rightCellAnchorPoint.x - leftCellAnchorPoint.x + 20.0000f + (extraInset * 2.0000f),
                                rightCellAnchorPoint.y - leftCellAnchorPoint.y + 20.0000f);
    connectorView.frame = connectorFrame;
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

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView { return self.contentView; }

@end
