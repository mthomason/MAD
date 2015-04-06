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
#import "AppDelegate.h"
#import "MADocument.h"
#import "MTApplicationInstance.h"
#import "MTShowSqlViewController.h"

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

#import "MTQueryTest.h"
#import "NSError+Constructors.h"

NSString * const MTKeyIsTopLevel = @"MTKeyIsTopLevel";

NSString * const MTIdentifierCollisionBoundryTop = @"MTIdentifierCollisionBoundryLandscapeTop";
NSString * const MTIdentifierCollisionBoundryRight = @"MTIdentifierCollisionBoundryLandscapeRight";
NSString * const MTIdentifierCollisionBoundryBottom = @"MTIdentifierCollisionBoundryLandscapeBottom";
NSString * const MTIdentifierCollisionBoundryLeft = @"MTIdentifierCollisionBoundryLandscapeLeft";
NSString * const MTQueryBuilderAdvancedSchemaViewControllerIdentifier = @"MTQueryBuilderAdvancedSchemaViewControllerIdentifier";

typedef void(^MTBlockResultVoid)(void);

@interface MADQueryVisualizationViewController ()
    <UIGestureRecognizerDelegate,
        UIScrollViewDelegate,
        UIPopoverControllerDelegate,
        UICollisionBehaviorDelegate,
        MADQueryVisualizationSchemaDelegate,
        MTViewControllerProtocol>

    @property (nonatomic, strong) IBOutlet UIToolbar *toolbarBottom;
    @property (nonatomic, strong) IBOutlet UIView *backgroundContainer;

    @property (nonatomic, strong) MADWatermarkScrollView *scrollView;
    @property (nonatomic, strong) UIView *contentView;

    @property (nonatomic, strong) NSMutableArray *viewControllers;  //May track child view controllers since iOS 7.
    @property (nonatomic, strong) NSMutableSet *tableIds;

    @property (nonatomic, strong) NSMutableDictionary *controllersForObjectIds;     //Tables and links
    @property (nonatomic, strong) NSMutableDictionary *controllersForObjectIdsLink; //Only query links

    @property (nonatomic, strong) NSMutableArray *tableStartingPoints;

    @property (nonatomic, strong) UIDynamicAnimator *dynamicAnimator;
    @property (nonatomic, strong) UICollisionBehavior *collisionBehavior;
    @property (nonatomic, strong) UIGravityBehavior *gravityBeahvior;
    @property (nonatomic, strong) UIDynamicItemBehavior *dynamicItemBehavior;
    @property (nonatomic, strong) NSMutableDictionary *attachmentBehaviors;
    @property (nonatomic, strong) NSMutableDictionary *pushBehaviors;

    @property (nonatomic, strong) NSLayoutConstraint *layoutConstraintSizeWidth;
    @property (nonatomic, strong) NSLayoutConstraint *layoutConstraintSizeHeight;

    @property (nonatomic, assign) NSUInteger tableDisplayCounter;

    @property (nonatomic, strong) UIStoryboard *storyboardDefault;

@end

@implementation MADQueryVisualizationViewController

- (void)dealloc {
    RptqDocument *document = [self.document activeDocumentModel];
    [MADQueryVisualizationViewController removeNotificationsFromObserver:self forObjectContext:[document managedObjectContext]];
    NSSet *setToRemove = [NSSet setWithArray:_viewControllers];
    [self removeViewControllers:setToRemove];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    NSMutableArray *viewControllers = [[NSMutableArray alloc] init];
    self.viewControllers = viewControllers;
    
    NSMutableSet *tableObjectIds = [[NSMutableSet alloc] init];
    self.tableIds = tableObjectIds;
    
    NSMutableDictionary *controllersForTableIds = [[NSMutableDictionary alloc] init];
    self.controllersForObjectIds = controllersForTableIds;
    
    NSMutableDictionary *controllersForObjectIdsLink = [[NSMutableDictionary alloc] init];
    self.controllersForObjectIdsLink = controllersForObjectIdsLink;
    
    NSMutableDictionary *attachmentBehaviors = [[NSMutableDictionary alloc] init];
    self.attachmentBehaviors = attachmentBehaviors;
    
    NSMutableArray *tableStartingPoints = [[NSMutableArray alloc] init];
    self.tableStartingPoints = tableStartingPoints;
    
    NSMutableDictionary *pushBehaviors = [[NSMutableDictionary alloc] init];
    self.pushBehaviors = pushBehaviors;
    
    self.tableDisplayCounter = 0;
    
    NSString *storyboardName = [MTApplicationInstance storyboardName];
    UIStoryboard *sb = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
    self.storyboardDefault = sb;

    CGFloat borderWidth = [UIDevice isRetnaDisplay] ? 0.5000f : 1.0000f;
    UIColor *borderColor = [UIColor lightGrayColor];
    self.backgroundContainer.layer.borderWidth = borderWidth;
    self.backgroundContainer.layer.borderColor = [borderColor CGColor];

    UIView *containerView = [[UIView alloc] initWithFrame:self.backgroundContainer.bounds];
    
    containerView.contentMode = UIViewContentModeScaleAspectFit;
    containerView.autoresizesSubviews = NO;
    containerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    MADWatermarkScrollView *scrollView = [[MADWatermarkScrollView alloc] initWithFrame:self.backgroundContainer.bounds];
    scrollView.showsHorizontalScrollIndicator = YES;
    scrollView.showsVerticalScrollIndicator = YES;
    scrollView.contentOffset = CGPointZero;
    scrollView.maximumZoomScale = 1.0000f;
    scrollView.minimumZoomScale = 1.0000f;
    scrollView.zoomScale = 1.0000f;
    scrollView.scrollEnabled = YES;
    scrollView.bounces = YES;
    scrollView.alwaysBounceHorizontal = YES;
    scrollView.alwaysBounceVertical = YES;
    scrollView.bouncesZoom = NO;
    scrollView.delegate = self;
    scrollView.delaysContentTouches = YES;
    scrollView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:containerView];

    [self.backgroundContainer addSubview:scrollView];
    
    NSLayoutConstraint *layoutConstraintSizeHeight = [NSLayoutConstraint constraintWithItem:containerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0000f constant:self.backgroundContainer.frame.size.height];
    NSLayoutConstraint *layoutConstraintSizeWidth = [NSLayoutConstraint constraintWithItem:containerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0000f constant:self.backgroundContainer.frame.size.width];
    [containerView addConstraint:layoutConstraintSizeHeight];
    [containerView addConstraint:layoutConstraintSizeWidth];
    
    self.layoutConstraintSizeHeight = layoutConstraintSizeHeight;
    self.layoutConstraintSizeWidth = layoutConstraintSizeWidth;
    
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
    
    NSMutableArray *toolbarButtons = [self.toolbarBottom.items mutableCopy];
    [self.toolbarBottom setItems:toolbarButtons animated:NO];
    UIDynamicAnimator *animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.contentView];
    NSArray *emptyArray = @[];
    UICollisionBehavior *collisionBehavior = [[UICollisionBehavior alloc] initWithItems:emptyArray];
    [collisionBehavior setTranslatesReferenceBoundsIntoBoundary:YES];
    [collisionBehavior setCollisionMode:UICollisionBehaviorModeItems];
    [collisionBehavior setCollisionDelegate:self];
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:emptyArray];
    gravity.magnitude = 0.3000f;
    gravity.gravityDirection = CGVectorMake(1.0000f, 0.0000f);

    UIDynamicItemBehavior *dynamicItemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:emptyArray];
    dynamicItemBehavior.allowsRotation = NO;
    dynamicItemBehavior.elasticity = 0.4000f;
    dynamicItemBehavior.resistance = 0.1000f;
    
    [animator addBehavior:dynamicItemBehavior];
    [animator addBehavior:collisionBehavior];
    [animator addBehavior:gravity];
    
    self.dynamicItemBehavior = dynamicItemBehavior;
    self.dynamicAnimator = animator;
    self.gravityBeahvior = gravity;
    self.collisionBehavior = collisionBehavior;
    
    [self reloadDocument:self.document animated:YES];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (animated) {
        [self.scrollView flashScrollIndicators];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    if (self.scrollView.contentSize.height < self.contentView.bounds.size.height) {
        self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, self.contentView.bounds.size.height);
    }
    
    if ([self.scrollView contentSize].width < self.contentView.bounds.size.width) {
        self.scrollView.contentSize = CGSizeMake(self.contentView.bounds.size.width, self.scrollView.contentSize.height);
    }
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender { }

/*
 
 // TEMPLATE METHOD
 
 - (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    if (shouldAutorotateToInterfaceOrientation) {

        [self localWillRotate];
        __weak UIViewController *weakself = self;
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [weakself localWillAnimateRotation];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [weakself localDidRotate];
        }];
 
    }
}
 
 */

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    
    for (UIViewController *subviewController in [self childViewControllers]) {
        [self didMoveFieldRect: subviewController
                          animated: YES];
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

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController { }

#pragma mark - Setup Notifications

+ (void)removeNotificationsFromObserver:(id<MADQueryVisualizationSchemaDelegate>)observer forObjectContext:(NSManagedObjectContext *)objectContext {
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    [defaultCenter removeObserver: observer
                             name: NSManagedObjectContextWillSaveNotification
                           object: objectContext];
    
    [defaultCenter removeObserver: observer
                             name: NSManagedObjectContextDidSaveNotification
                           object: objectContext];
    
}

+ (void)addNotificationsToObserver:(id<MADQueryVisualizationSchemaDelegate>)observer forObjectContext:(NSManagedObjectContext *)objectContext {
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    [MADQueryVisualizationViewController removeNotificationsFromObserver:observer forObjectContext:objectContext];
    
    [defaultCenter addObserver: observer
                      selector: @selector(managedObjectContextWillSave:)
                          name: NSManagedObjectContextWillSaveNotification
                        object: objectContext];

    [defaultCenter addObserver: observer
                      selector: @selector(managedObjectContextDidSave:)
                          name: NSManagedObjectContextDidSaveNotification
                        object: objectContext];
    
}

#pragma mark - NSManagedObjectContext observer

- (void)managedObjectContextWillSave:(NSNotification *)notification {

}

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

            UIViewController *viewController = self.controllersForObjectIds[[updatedTable objectID]];
            
            if ([viewController isKindOfClass:[MADQueryVisualizationSchemaViewController class]]) {

                [self.tableStartingPoints removeObject:updatedTable];
                
                // Reposition existing tables
                CGFloat segHeight = (self.contentView.bounds.size.height / ([self.tableStartingPoints count] + 1));
                NSUInteger counter = 0;
                for (RptqQueryTable *queryTable in self.tableStartingPoints) {
                    CGFloat attachmentPointY = segHeight * (counter + 1);
                    CGPoint attachmentPoint = CGPointMake(CGPointZero.x, attachmentPointY - 22.0000f);
                    UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviors[[queryTable objectID]];
                    [attachmentBehavior setAnchorPoint:attachmentPoint];
                    counter++;
                }
                
                // FIXME: Maybe block this and move it off screen.
                UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviors[updatedTable.objectID];
                [self.dynamicAnimator removeBehavior:attachmentBehavior];
                [self.gravityBeahvior removeItem:(MADQueryVisualizationSchemaViewController *)viewController];
                [self.collisionBehavior removeItem:(MADQueryVisualizationSchemaViewController *)viewController];
                [self.dynamicItemBehavior removeItem:(MADQueryVisualizationSchemaViewController *)viewController];
                [self.attachmentBehaviors removeObjectForKey:updatedTable.objectID];
                
                // FIXME: do give time for animations... Can't imagine this will work.
                [viewController willMoveToParentViewController:nil];
                [viewController.view removeFromSuperview];
                [viewController removeFromParentViewController];
                
                for (RptqQueryLinks *link in [updatedQuery hasQueryLinks]) {
                    if (link.hasLeftField.inQueryTable.objectID == updatedTable.objectID ||
                        link.hasRightField.inQueryTable.objectID == updatedTable.objectID) {
                        
                        UIViewController *linkViewController = self.controllersForObjectIdsLink[link.objectID];
                        if (linkViewController != nil) {
                            [self removeViewController:linkViewController];
                        }
                        //Delete the query link view controller here, because it's bogus
                        
                    }
                }
                
                //loop though each link here, and do as above if the link contains the table... but will it be there?... check the updated query

            } else if ([viewController.view isKindOfClass:[MTConnectorView class]]) {
                
                UIViewController *viewController = self.controllersForObjectIds[[updatedTable objectID]];
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
            
            RptqQueryTable *deletedTable = deletedObject;
            [self deleteQueryTable:deletedTable];
            
        } else if ([deletedObject isKindOfClass:[RptqQueryLinks class]]) {
            
            RptqQueryLinks *deletedLink = deletedObject;
            [self deleteQueryLink:deletedLink];
            
        }
    }
}

#pragma mark View Controller Container Custom Handlers

- (void)viewControllerDidFinish:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{ }];
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
    NSManagedObjectID *tableId = [[gestureRecognizer view] objectIdTag];

    MADQueryVisualizationSchemaViewController *viewController = self.controllersForObjectIds[tableId];
    
    CGPoint location = [window convertPoint:gestureLocation toView:self.contentView];
    
    CGPoint newOrigin = location; // [gestureRecognizer locationInView:self.contentView];
    UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviors[tableId];
    
    RptqQueryTable *table = (RptqQueryTable *)[self.document.managedObjectContext objectWithID:tableId];
    if ([self.tableStartingPoints containsObject:table]) {
        [attachmentBehavior setAnchorPoint:newOrigin];
    }
    [viewController.view setCenter:newOrigin];

        switch ([gestureRecognizer state]) {
                
            case UIGestureRecognizerStateBegan: {   // MARK: UIPanGestureRecognizer UIGestureRecognizerStateBegan
                [self.dynamicAnimator updateItemUsingCurrentState:viewController];
            }
            case UIGestureRecognizerStateChanged: {     // MARK: UIPanGestureRecognizer UIGestureRecognizerStateChanged
                [self.dynamicAnimator updateItemUsingCurrentState:viewController];
                break;
            }
            case UIGestureRecognizerStatePossible:      // MARK: UIPanGestureRecognizer UIGestureRecognizerStatePossible
                break;
            case UIGestureRecognizerStateCancelled:     // MARK: UIPanGestureRecognizer UIGestureRecognizerStateCancelled
            case UIGestureRecognizerStateFailed:        // MARK: UIPanGestureRecognizer UIGestureRecognizerStateFailed
            case UIGestureRecognizerStateEnded: {       // MARK: UIPanGestureRecognizer UIGestureRecognizerStateEnded
                [self.dynamicAnimator updateItemUsingCurrentState:viewController];
                break;
            }
            default:
                break;
        }
}

- (void)pushPiece:(UIPanGestureRecognizer *)gestureRecognizer {

    UIPushBehavior *pushBehavior = [self pushBehaviorForItem:[gestureRecognizer view]];
    [pushBehavior setActive:YES];
    
    // If we're starting the gesture then create a drag force
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) { }
    
    // Set the force to be proportional to distance the gesture has moved
    CGPoint velocity = [gestureRecognizer velocityInView:self.contentView];
    pushBehavior.pushDirection = CGVectorMake(velocity.x/100, velocity.y/100);
    
    // If we're finishing then cancel the behavior to 'let-go' of the ball
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) { }
    
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self resizeScrollViewContentArea];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self resizeScrollViewContentArea];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self resizeScrollViewContentArea];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    [self resizeScrollViewContentArea];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self resizeScrollViewContentArea];
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [self resizeScrollViewContentArea];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView { }

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    return NO;
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView { }

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self resizeScrollViewContentArea];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    [self resizeScrollViewContentArea];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset { }

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.contentView;
}

#pragma mark - UICollisionBehaviorDelegate

//- (void)collisionBehavior:(UICollisionBehavior *)behavior endedContactForItem:(id<UIDynamicItem>)item withBoundaryIdentifier:(id<NSCopying>)identifier {

//}

#pragma mark - MTQueryBuilderAdvancedSchemaViewControllerDelegate

- (void)didMoveFieldRect:(id)sender animated:(BOOL)animated {
    if ([sender isKindOfClass:[MADQueryVisualizationSchemaViewController class]]) {
        MADQueryVisualizationSchemaViewController *controller = (MADQueryVisualizationSchemaViewController *)sender;

        RptqQueryTable *queryTable = [RptqQueryTable queryTableWithObjectID:controller.tableObjectId
                                                       managedObjectContext:self.document.managedObjectContext];
        for (RptqQueryLinks *queryLink in [[queryTable inQuery] hasQueryLinks]) {
            RptqQueryTable *leftTable = [queryLink.hasLeftField inQueryTable];
            RptqQueryTable *rightTable = [queryLink.hasRightField inQueryTable];
            if ([leftTable isEqualTo:queryTable] ||
                [rightTable isEqualTo:queryTable]) {
                [self layoutQueryLinkViewController:queryLink animated:animated];
            }
        }
    }
}
    
#pragma mark - Change UI on IR Diagram

- (void)clearScreen {
    
    for (UIViewController *viewController in self.viewControllers) {
        Class schemaTableClass = [MADQueryVisualizationSchemaViewController class];
        if ([viewController isKindOfClass:schemaTableClass]) {
            UIAttachmentBehavior *attachmentBehaviorForObjectId = self.attachmentBehaviors[[viewController.view objectIdTag]];
            [self.dynamicAnimator removeBehavior:attachmentBehaviorForObjectId];
            [self.attachmentBehaviors removeObjectForKey:[viewController.view objectIdTag]];
            MADQueryVisualizationSchemaViewController *controller = (MADQueryVisualizationSchemaViewController *)viewController;
            [self.collisionBehavior removeItem:controller];
            [self.gravityBeahvior removeItem:controller];
        }
    }

    NSSet *viewControllers = [NSSet setWithArray:self.viewControllers];
    [self removeViewControllers:viewControllers];
    [self setTableDisplayCounter:0];
    
}

- (MTLinkedList *)tableObjectIDsSortedTopologicallyForQuery:(RptqQuery *)query {

    MTGraph *graph = [[MTGraph alloc] init];
    NSSet *hasTables = [query hasQueryTables];
    
    //Add a vertex to the graph for each table.
    for (RptqDatabaseSchemaTable *table in hasTables) {
        [graph addVertexWithObject:table.objectID];
    }
    
    //Create an edge in the graph for each query link.
    NSSet *hasQueryLinks = [query hasQueryLinks];
    for (RptqQueryLinks *queryLink in hasQueryLinks) {
        
        RptqQueryTable *tableOrigin =        queryLink.hasLeftField.inQueryTable;
        RptqQueryTable *tableDestination =   queryLink.hasRightField.inQueryTable;
        
        MTVertex *vertexOrigin =        [graph vertexForObject:(MTObject *)tableOrigin.objectID];
        MTVertex *vertexDestination =   [graph vertexForObject:(MTObject *)tableDestination.objectID];
        
        NSNumber *weight = @(1);
        [graph addEdgeWithOrigin: vertexOrigin
                     destination: vertexDestination
                          object: queryLink.objectID
                       andWeight: weight];
        
    }
    
    NSError *error = nil;
    MTLinkedList *tableIds = [graph topologicalSortWithError:&error];
    
    return tableIds;

}

#pragma mark Reload document view controllers

- (void)redraw {
    [self reloadDocument:self.document animated:YES];
}

- (void)reloadDocument:(MADocument *)documentReport animated:(BOOL)animated {
    if (documentReport) {
        
        NSManagedObjectContext *objectContext = [documentReport managedObjectContext];
        [MADQueryVisualizationViewController addNotificationsToObserver:self forObjectContext:objectContext];
        
        [self clearScreen];
        
        [self.tableStartingPoints removeAllObjects];
        [self.pushBehaviors removeAllObjects];
        [self.viewControllers removeAllObjects];  //May track child view controllers since iOS 7.
        [self.tableIds removeAllObjects];
        [self.controllersForObjectIds removeAllObjects];     //Tables and links
        [self.controllersForObjectIdsLink removeAllObjects];
        
        RptqDocument *document = [documentReport activeDocumentModel];
        RptqDatabase *database = [document.hasDatabaseSchemas anyObject];
        RptqQuery *query = [database.hasQueries anyObject];
        [self displayQuery:query animated:animated];
    }
    
}

- (void)displayQuery:(RptqQuery *)query animated:(BOOL)animated {
    
    NSInteger numberOfStartingPoints = 0;
    
    MTLinkedList *tableIds = [self tableObjectIDsSortedTopologicallyForQuery:query];
    NSMutableDictionary *layoutDetails = [[NSMutableDictionary alloc] initWithCapacity:[tableIds count]];
    
    for (MTPair *tableObjectIdContainer in tableIds) {
        MTVertex *tableIdVertext = [tableObjectIdContainer former];
        NSManagedObjectID *objectId = [tableIdVertext object];
        if (objectId != nil) {
            
            RptqQueryTable *table = (RptqQueryTable *)[self.document.managedObjectContext objectWithID:objectId];
            
            //Is the table joined to another table from the left?
            BOOL topLevel = YES;
            
            for (RptqQueryLinks *link in [query hasQueryLinks]) {
                RptqQueryField *rightField = [link hasRightField];
                RptqQueryTable *rightQueryTable = [rightField inQueryTable];
                if ([rightQueryTable isEqualTo:table]) {
                    topLevel = NO;
                    break;
                }
            }
            
            NSDictionary *layout = @{
                                     MTKeyIsTopLevel : @(topLevel)
                                     };
            
            layoutDetails[[tableIdVertext object]] = layout;
            
            if (topLevel) {
                numberOfStartingPoints++;
            }
        }
    }
    
    NSInteger tableCounter = 0;
    NSInteger topLevelTableCounter = 0;
    CGFloat segHeight = (self.contentView.bounds.size.height / (numberOfStartingPoints + 1));

    // Display tables
    for (MTPair *pair in tableIds) {
        
        MTVertex *tableIdVertext = [pair former];
        NSManagedObjectID *objectId = [tableIdVertext object];

        if (objectId != nil) {
            
            RptqQueryTable *table = (RptqQueryTable *)[self.document.managedObjectContext objectWithID:objectId];
            
            NSDictionary *layout = layoutDetails[[tableIdVertext object]];
            BOOL topLevel = [layout[MTKeyIsTopLevel] boolValue];
            
            MADQueryVisualizationSchemaViewController *viewController = [self addSchemaViewControllerForTable:table animated:animated];
            
            if (animated) {
                
                NSManagedObjectID *objectIDView = [viewController.view objectIdTag];
                if (topLevel) {
                    
                    CGFloat attachmentPointY = segHeight * (topLevelTableCounter + 1);
                    
                    CGPoint attachmentPoint = CGPointMake(CGPointZero.x, attachmentPointY);
                    UIAttachmentBehavior *attachmentBehavior = [MADQueryVisualizationViewController attachmentBehaviorAnchorWithItem:viewController attachedToPoint:attachmentPoint];
                    [self.dynamicAnimator addBehavior:attachmentBehavior];
                    self.attachmentBehaviors[objectIDView] = attachmentBehavior;
                    [self.tableStartingPoints addObject:table];
                    topLevelTableCounter++;
                    
                } else {
                    
                    for (RptqQueryLinks *link in [query hasQueryLinks]) {
                        RptqQueryField *rightField = [link hasRightField];
                        RptqQueryTable *rightTable = [rightField inQueryTable];
                        RptqQueryField *leftField = [link hasLeftField];
                        RptqQueryTable *leftTable = [leftField inQueryTable];
                        if (rightTable.objectID == table.objectID) {
                            
                            MADQueryVisualizationSchemaViewController *leftTableViewController = self.controllersForObjectIds[leftTable.objectID];
                            if (leftTableViewController != viewController) {
                                
                                UIAttachmentBehavior *attachmentBehaviorLeft = [MADQueryVisualizationViewController attachmentBehaviorLinkWithLeftViewController: leftTableViewController
                                                                                                                                          andRightViewController: viewController];
                                [self.dynamicAnimator addBehavior:attachmentBehaviorLeft];
                                self.attachmentBehaviors[link.objectID] = attachmentBehaviorLeft;
                            }
                            
                        }
                    }
                    
                }
                tableCounter++;
            }
            self.tableDisplayCounter++;
        }
    }
    
    // Display links
    for (RptqQueryLinks *queryLink in [query hasQueryLinks]) {
        [self addLinkViewControllerForQueryLink:queryLink animated:YES];
    }
}

- (void)deleteQueryTable:(RptqQueryTable *)deletedQueryTable {

    NSManagedObjectID *objectId = [deletedQueryTable objectID];
    
    //If top level table, then move it off screen, and move the others in place.
    
    BOOL startingPointTable = [self.tableStartingPoints containsObject:objectId];
    if (startingPointTable) {
        CGPoint offScreen = CGPointMakeRandomOffscreen();
        UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviors[objectId];
        [attachmentBehavior setAnchorPoint:offScreen];
    }
    
    if ([deletedQueryTable inQuery] != nil &&
        [self.tableIds containsObject: objectId]) {
        
        MADQueryVisualizationSchemaViewController *viewController = self.controllersForObjectIds[objectId];
        // FIXME: do give time for animations... Can't imagine this will work.
        [viewController willMoveToParentViewController:nil];
        [viewController.view removeFromSuperview];
        [viewController removeFromParentViewController];
        
    }
}

- (void)deleteQueryLink:(RptqQueryLinks *)deletedQueryLinks {

    NSMutableSet *orphanedQueryTables = [[NSMutableSet alloc] init];
    
    RptqDocument *document = [self.document activeDocumentModel];
    RptqDatabase *database = [document.hasDatabaseSchemas anyObject];
    RptqQuery *query = [database.hasQueries anyObject];
    
    for (RptqQueryTable *table in [query hasQueryTables]) {
        BOOL orphaned = YES;
        for (RptqQueryLinks *link in [query hasQueryLinks]) {
            RptqQueryTable *rightQueryTable = [[link hasRightField] inQueryTable];
            if ([table isEqualTo:rightQueryTable]) {
                orphaned = NO;
                break;
            }
        }
        if (orphaned) {
            [orphanedQueryTables addObject:table];
        }
    }
    
    NSSet *startingPoints = [NSSet setWithArray:self.tableStartingPoints];
    [orphanedQueryTables minusSet:startingPoints];  // Should only be one newly orphaned table.
    
    NSManagedObjectID *deletedLinkObjectId = [deletedQueryLinks objectID];
    RptqQueryLinks *deletedLink = (RptqQueryLinks *)[self.document.managedObjectContext objectWithID:deletedLinkObjectId];
    UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviors[deletedLinkObjectId];
    
    for (RptqQueryTable *table in orphanedQueryTables) {
        
        RptqQueryTable *tableRightDeletedLink = table;
        MADQueryVisualizationSchemaViewController *viewController = self.controllersForObjectIds[[tableRightDeletedLink objectID]];
        
        // Is there a link still pointing to the view controller after the delete, or
        //   do we need to make it top level?
        
        CGFloat x = CGPointZero.x + self.contentView.frame.size.width;
        CGFloat y = CGPointZero.y + self.contentView.frame.size.height / 2.0000f;
        CGPoint attachmentPoint = CGPointMake(x, y);
 
        UIAttachmentBehavior *anchorBehaviorNew = [MADQueryVisualizationViewController attachmentBehaviorAnchorWithItem:viewController attachedToPoint:attachmentPoint];
        [self.dynamicAnimator addBehavior:anchorBehaviorNew];
        self.attachmentBehaviors[[tableRightDeletedLink objectID]] = anchorBehaviorNew;
        [self.tableStartingPoints addObject: tableRightDeletedLink];
        
        // Disable collision behaviors before reposition
        // Reposition existing tables
        CGFloat segHeight = (self.contentView.bounds.size.height / ([self.tableStartingPoints count] + 1));
        NSUInteger counter = 0;
        for (RptqQueryTable *queryTable in self.tableStartingPoints) {
            CGFloat attachmentPointY = segHeight * (counter + 1);
            CGPoint attachmentPoint = CGPointMake(CGPointZero.x, attachmentPointY - 22.0000f);
            UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviors[[queryTable objectID]];
            [attachmentBehavior setAnchorPoint:attachmentPoint];
            counter++;
        }
    }
    
    [self.dynamicAnimator removeBehavior:attachmentBehavior];
    [self.attachmentBehaviors removeObjectForKey:deletedLinkObjectId];
    
    UIViewController *linkViewController = self.controllersForObjectIdsLink[[deletedLink objectID]];
    if (linkViewController != nil) {
        [self removeViewController:linkViewController];
    }
}

- (void)insertQueryTable:(RptqQueryTable *)insertedQueryTable {
    
    CGFloat segHeight = (self.contentView.bounds.size.height / ([self.tableStartingPoints count] + 2));
    
    // Reposition existing tables
    // FIXME: Good place for block iterate?
    NSUInteger counter = 0;
    for (RptqQueryTable *queryTable in self.tableStartingPoints) {
        CGFloat attachmentPointY = segHeight * (counter + 1);
        CGPoint attachmentPoint = CGPointMake(CGPointZero.x, attachmentPointY - 22.0000f);
        UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviors[[queryTable objectID]];
        [attachmentBehavior setAnchorPoint:attachmentPoint];
        counter++;
    }
    
    CGFloat attachmentPointY = segHeight * ([self.tableStartingPoints count] + 1);
    CGPoint insertTableAnchorPoint = CGPointMake(CGPointZero.x, attachmentPointY - 22.0000f);
    
    // Insert new and unlinked query table
    
    //Going to assume that it's a top level table.
    [self.tableStartingPoints addObject:insertedQueryTable];
    
    // Insert table
    MADQueryVisualizationSchemaViewController *viewController = [self addSchemaViewControllerForTable:insertedQueryTable animated:YES];

    NSManagedObjectID *objectIDView = [viewController.view objectIdTag];
    UIAttachmentBehavior *attachmentBehavior = [MADQueryVisualizationViewController attachmentBehaviorAnchorWithItem:viewController attachedToPoint:insertTableAnchorPoint];

    [self.dynamicAnimator addBehavior:attachmentBehavior];
    self.attachmentBehaviors[objectIDView] = attachmentBehavior;
    
    self.tableDisplayCounter++;
    
}

- (void)insertQueryLink:(RptqQueryLinks *)insertedQueryLinks {

    RptqQuery *query = [insertedQueryLinks inQuery];
 
    RptqQueryField *leftField = [insertedQueryLinks hasLeftField];
    RptqQueryTable *leftTable = [leftField inQueryTable];
    MADQueryVisualizationSchemaViewController *leftTableViewController = self.controllersForObjectIds[leftTable.objectID];
    
    RptqQueryField *rightField = [insertedQueryLinks hasRightField];
    RptqQueryTable *rightTable = [rightField inQueryTable];
    MADQueryVisualizationSchemaViewController *rightTableViewController = self.controllersForObjectIds[rightTable.objectID];
    
    MTLinkedList *tableIds = [self tableObjectIDsSortedTopologicallyForQuery:query];
    
    NSInteger numberOfStartingPoints = 0;
    
    NSMutableDictionary *layoutDetails = [[NSMutableDictionary alloc] initWithCapacity:[tableIds count]];
    
    for (MTPair *pair in tableIds) {
        MTVertex *tableIdVertext = [pair former];
        NSManagedObjectID *objectId = [tableIdVertext object];
        if (objectId != nil) {
            
            RptqQueryTable *table = (RptqQueryTable *)[self.document.managedObjectContext objectWithID:objectId];
            //Is the table joined to another table from the left?
            BOOL topLevel = YES;
            
            for (RptqQueryLinks *link in [query hasQueryLinks]) {
                RptqQueryField *rightField = [link hasRightField];
                RptqQueryTable *rightQueryTable = [rightField inQueryTable];
                if ([rightQueryTable isEqualTo:table]) {
                    topLevel = NO;
                    break;
                }
            }
            
            NSNumber *topLevelWrapper = @(topLevel);
            NSDictionary *layout = @{ MTKeyIsTopLevel : topLevelWrapper };
            
            layoutDetails[table.objectID] = layout;
            
            if (topLevel) {
                numberOfStartingPoints++;
            }
        }
    }
    
    // Remove starting point connection if one of the tables is in the link.
    BOOL startingPointRemoved = NO;
    RptqQueryTable *queryTableRemoved = nil;
    NSUInteger startingPointsRemovedCounter = 0;
    for (RptqQueryTable *queryTable in self.tableStartingPoints) {

        RptqQueryTable *removeableTable = nil;

        NSDictionary *layout = layoutDetails[[queryTable objectID]];
        NSNumber *isTopLevel = layout[MTKeyIsTopLevel];
        if ([isTopLevel boolValue] == NO) {
            if ([[leftTable objectID] isEqual:[queryTable objectID]]) {
                removeableTable = queryTable;
            } else if ([[rightTable objectID] isEqual:[queryTable objectID]]) {
                removeableTable = queryTable;
            }
        }
        if (removeableTable) {
            queryTableRemoved = queryTable;
            UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviors[[removeableTable objectID]];
            [self.dynamicAnimator removeBehavior:attachmentBehavior];
            [self.attachmentBehaviors removeObjectForKey:[removeableTable objectID]];
            startingPointRemoved = YES;
            startingPointsRemovedCounter++;
            if (startingPointsRemovedCounter == 2) {
                break;
            }
        }
    }
    
    // Reposition existing starting point-tables
    if (startingPointRemoved) {
        [self.tableStartingPoints removeObject:queryTableRemoved];
        
        CGFloat segHeight = (self.contentView.bounds.size.height / ([self.tableStartingPoints count] + 2));
        NSUInteger counter = 0;
        for (RptqQueryTable *queryTable in self.tableStartingPoints) {
            CGFloat attachmentPointY = segHeight * (counter + 1);
            CGPoint attachmentPoint = CGPointMake(CGPointZero.x, attachmentPointY - 22.0000f);
            UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviors[[queryTable objectID]];
            [attachmentBehavior setAnchorPoint:attachmentPoint];
            counter++;
        }
    }
    
    //Add connections between MTQueryBuilderAdvancedSchemaViewController
    if ([leftTableViewController isEqual:rightTableViewController] == NO) {
        UIAttachmentBehavior *attachmentBehavior = [MADQueryVisualizationViewController attachmentBehaviorLinkWithLeftViewController: leftTableViewController
                                                                                                              andRightViewController: rightTableViewController];
        [self.dynamicAnimator addBehavior:attachmentBehavior];
        self.attachmentBehaviors[insertedQueryLinks.objectID] = attachmentBehavior;
        
        //Add animation layer
        [self addLinkViewControllerForQueryLink: insertedQueryLinks animated:YES];
    }
}

#pragma mark - UI Items

+ (UIAttachmentBehavior *)attachmentBehaviorAnchorWithItem:(id<UIDynamicItem>)item attachedToPoint:(CGPoint)anchorPoint {
    CGPoint attachmentPoint = CGPointMake(CGPointZero.x, anchorPoint.y - 22.0000f);
    UIAttachmentBehavior *behavior = [[UIAttachmentBehavior alloc] initWithItem:item attachedToAnchor:attachmentPoint];
    [behavior setLength:100.0000f];
    return behavior;

}

+ (UIAttachmentBehavior *)attachmentBehaviorLinkWithLeftViewController:(MADQueryVisualizationSchemaViewController *)viewControllerLeft
                                                andRightViewController:(MADQueryVisualizationSchemaViewController *)viewControllerRight {
    
    // FIXME: Make sure they are not the same, or crash, lolz

    UIAttachmentBehavior *behavior = [[UIAttachmentBehavior alloc] initWithItem:viewControllerRight attachedToItem:viewControllerLeft];
    [behavior setFrequency:1.000f];
    [behavior setDamping:1.200f];
    [behavior setLength:7.0000f];
    
    return behavior;
}

//Pass the view controller to create an push behavior... can be recovered with multiple types
- (UIPushBehavior *)pushBehaviorForItem:(id<UIDynamicItem>)item {
    UIPushBehavior *pushBehavior = nil;
    if ([item isKindOfClass:[UIViewController class]]) {
        
         //Creating it
        NSManagedObjectID *objectId = [[(UIViewController *)item view] objectIdTag];
        UIPushBehavior *behavior = [self pushBehaviors][objectId];
        if (behavior == nil) {
            pushBehavior = [[UIPushBehavior alloc] initWithItems:@[item] mode:UIPushBehaviorModeInstantaneous];
            [self.dynamicAnimator addBehavior:pushBehavior];
            [self pushBehaviors][objectId] = pushBehavior;
        } else {
            pushBehavior = behavior;
        }

    } else if ([item isKindOfClass:[UIView class]]) {
        
        NSManagedObjectID *objectId = [(UIView *)item objectIdTag];
        pushBehavior = [self pushBehaviors][objectId];
        
    } else if ([item isKindOfClass:[NSManagedObjectID class]]) {

        pushBehavior = [self pushBehaviors][item];
    
    }
    return pushBehavior;
}

#pragma mark - Helper functions

+ (CGPoint)randomPointInRect:(CGRect)rect {
    CGFloat maxWidth = rect.origin.x + rect.size.width;
    CGFloat maxHeight = rect.origin.y + rect.size.height;
    if (maxWidth == 0) {
        maxWidth = 1.0000f;
    }
    if (maxHeight == 0) {
        maxHeight = 1.0000f;
    }
    CGFloat x = (random() % (int)maxWidth) + (int)rect.origin.x;
    CGFloat y = (random() % (int)maxHeight) + (int)rect.origin.y;
    return CGPointMake(x, y);
}

+ (CGRect)rectForDesiredRect:(CGRect)desiredFrame inBounds:(CGRect)viewControllerBounds {
    BOOL goodSpot = CGRectContainsRect(viewControllerBounds, desiredFrame);
    if (goodSpot == NO) {
        
        //Is it to the left?
        if (desiredFrame.origin.x < viewControllerBounds.origin.x) {
            desiredFrame.origin.x = viewControllerBounds.origin.x + 20.0000f;
        }
        
        //Is it to the right?
        CGFloat desiredRightFrame = desiredFrame.origin.x + desiredFrame.size.width;
        CGFloat boundsRightFrame = viewControllerBounds.origin.x + viewControllerBounds.size.width;
        if (desiredRightFrame > boundsRightFrame) {
            desiredFrame.origin.x = boundsRightFrame - desiredFrame.size.width - 20.0000f;
        }
        
        //Are you too high?
        if (desiredFrame.origin.y < viewControllerBounds.origin.y) {
            desiredFrame.origin.y = viewControllerBounds.origin.y + 20.0000f;
        }
        
        //Is it too low?
        CGFloat desiredBottomFrame = desiredFrame.origin.y + desiredFrame.size.height;
        CGFloat boundsBottomFrame = viewControllerBounds.origin.y + viewControllerBounds.size.height;
        if (desiredBottomFrame > boundsBottomFrame) {
            desiredFrame.origin.y = boundsBottomFrame - desiredFrame.size.height - 20.0000f;
        }
        
    }
    return desiredFrame;
}

- (void)addGesturesToViewController:(UIViewController *)viewController {
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPiece:)];
    [tapGesture setDelegate:self];
    [tapGesture setNumberOfTapsRequired:1];
    [viewController.view addGestureRecognizer:tapGesture];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pushPiece:)];
    [panGesture setDelegate:self];
    [[self.scrollView panGestureRecognizer] requireGestureRecognizerToFail:panGesture];
    [tapGesture requireGestureRecognizerToFail:panGesture];
    [viewController.view addGestureRecognizer:panGesture];
}

#pragma mark Scroll view helper

- (void)resizeScrollViewContentArea {
    if (self.scrollView.isZooming == NO) {
        CGFloat maxX = CGPointZero.x;
        CGFloat maxY = CGPointZero.y;
        
        for (UIViewController *viewController in [self childViewControllers]) {
            Class schemaClass = [MADQueryVisualizationSchemaViewController class];
            if ([viewController isKindOfClass:schemaClass]) {
                UIView *view = viewController.view;
                CGRect frame = view.frame;//[self.contentView convertRect:view.frame fromView:view];
                CGFloat tmaxX = frame.origin.x + frame.size.width;
                CGFloat tminX = frame.origin.x < CGPointZero.x ? fabs(frame.origin.x) : CGSizeZero.width;
                CGFloat tmaxY = frame.origin.y + frame.size.height;
                CGFloat tminY = frame.origin.y < CGPointZero.y ? fabs(frame.origin.y) : CGSizeZero.height;
                tmaxX += tminX;
                tmaxX += tminY;
                maxX = MAX(maxX, tmaxX);
                maxY = MAX(maxY, tmaxY);
            }
        }
        
        self.layoutConstraintSizeHeight.constant = MAX(maxY, self.view.bounds.size.height);
        self.layoutConstraintSizeWidth.constant = MAX(maxX, self.view.bounds.size.width);
    }
}

#pragma mark - View Controller Container Data

- (void)removeViewControllers:(NSSet *)viewControllers {
    for (UIViewController *viewController in viewControllers) {
        [self removeViewController:viewController];
        
        Class schemaTableClass = [MADQueryVisualizationSchemaViewController class];
        if ([viewController isKindOfClass:schemaTableClass]) {
            MADQueryVisualizationSchemaViewController *controller = (MADQueryVisualizationSchemaViewController *)viewController;
            UIAttachmentBehavior *attachmentBehaviorForObjectId = self.attachmentBehaviors[[viewController.view objectIdTag]];
            [self.dynamicAnimator removeBehavior:attachmentBehaviorForObjectId];

            [self.attachmentBehaviors removeObjectForKey:[viewController.view objectIdTag]];
            [self.collisionBehavior removeItem:controller];
            [self.gravityBeahvior removeItem:controller];
        }
    }
}

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

- (MADQueryVisualizationSchemaViewController *)addSchemaViewControllerForTable:(RptqQueryTable *)table animated:(BOOL)animated {
    
    NSString *storyboardName = [MTApplicationInstance storyboardName];
    UIStoryboard *sb = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
    MADQueryVisualizationSchemaViewController *viewController = [sb instantiateViewControllerWithIdentifier:MTQueryBuilderAdvancedSchemaViewControllerIdentifier];
    viewController.document = self.document;
    viewController.delegate = self;
    viewController.tableObjectId = table.objectID;
    
    CGRect subviewRect = CGRectZero;
    
    [self.tableIds addObject:table.objectID];
    self.controllersForObjectIds[table.objectID] = viewController;
    CGFloat originX = 10.0000f + CGPointZero.x;
    BOOL ud = table.identifier.integerValue % 2;
    CGFloat originY = CGPointZero.y + self.scrollView.frame.size.height - (ud ? 200.0000f : - 600.0000f) - 20.0000f;
    subviewRect = CGRectMake(originX, originY, 180.0000f, 200.0000f);

    NSNumber *sizeHeight = @(subviewRect.size.height);
    NSNumber *sizeWidth = @(subviewRect.size.width);
    NSNumber *originXs = @(subviewRect.origin.x);
    NSNumber *originYs = @(subviewRect.origin.y);
    NSNumber *designerInitalLayout = @(NO);
    table.designerSizeHeight = sizeHeight;
    table.designerSizeWidth = sizeWidth;
    table.designerOriginY = originYs;
    table.designerOriginX = originXs;
    table.designerInitalLayout = designerInitalLayout;
    
    [self.document.managedObjectContext save:nil];

    viewController.view.frame = subviewRect;
    
    [self addGesturesToViewController:viewController];
    
    NSArray *constraints = nil;
    CGRect desiredFrame;
    CGRect viewControllerBounds = self.contentView.bounds;
    desiredFrame = [MADQueryVisualizationViewController rectForDesiredRect:subviewRect inBounds:viewControllerBounds];
    
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:viewController.view
                                                             attribute:NSLayoutAttributeWidth
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:nil
                                                             attribute:NSLayoutAttributeNotAnAttribute
                                                            multiplier:1.0000f
                                                              constant:desiredFrame.size.width];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:viewController.view
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:nil
                                                              attribute:NSLayoutAttributeNotAnAttribute
                                                             multiplier:1.0000f
                                                               constant:desiredFrame.size.height];
    width.priority = UILayoutPriorityDefaultHigh;
    height.priority = UILayoutPriorityDefaultHigh;
    
    viewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    constraints = @[width, height];
    
    [self addChildViewController:viewController];
    if ([self.viewControllers containsObject:viewController] == NO) {
        [self.viewControllers addObject:viewController];
    }
    
    [self.contentView addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
    
    [self.contentView addConstraints:constraints];
    
    [self pushBehaviorForItem: viewController];
    [self.collisionBehavior addItem:viewController];
    [self.gravityBeahvior addItem:viewController];
    [self.dynamicItemBehavior addItem:viewController];
    
    return viewController;
    
}

- (void)addLinkViewControllerForQueryLink:(RptqQueryLinks *)link animated:(BOOL)animated {
    NSManagedObjectID *objectId = [link objectID];
    MTConnectorView *connectorView = [[MTConnectorView alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, 100.0000f, 100.0000f)];
    connectorView.userInteractionEnabled = NO;
    connectorView.objectIdTag = objectId;
    
    UIViewController *connectorViewController = [[UIViewController alloc] init];
    connectorViewController.view = connectorView;
    
    self.controllersForObjectIds[objectId] = connectorViewController;
    self.controllersForObjectIdsLink[objectId] = connectorViewController;
    
    if (animated == NO) {
        [self layoutQueryLinkViewController:link animated:animated];
    }
    
    CGRect desiredFrame = [connectorViewController.view frame];
    CGPoint desiredCenter = [connectorViewController.view center];
    CGAffineTransform desiredTransform = [connectorViewController.view transform];
    CGAffineTransform swingTransform = CGAffineTransformIdentity;
    if (animated) {
        swingTransform = CGAffineTransformSwing();
    }
    
    NSArray *constraints = nil;
    NSMutableArray *bufferConstraints = [[NSMutableArray alloc] init];
    
    connectorViewController.view.bounds = CGRectZero;
    connectorViewController.view.center = desiredCenter;
    if (animated) {
        connectorViewController.view.transform = swingTransform;
    }
    
    constraints = @[];
    
    [self addChildViewController:connectorViewController];
    if ([self.viewControllers containsObject:connectorViewController] == NO) {
        [self.viewControllers addObject:connectorViewController];
    }
    
    [self.contentView addSubview:connectorViewController.view];
    [connectorViewController didMoveToParentViewController:self];
    
    [bufferConstraints addObjectsFromArray:constraints];
    [self.contentView addConstraints:bufferConstraints];
    
    MTBlockResultVoid animateTwo = ^() {
        [connectorViewController.view setFrame:desiredFrame];
        [connectorViewController.view setTransform:desiredTransform];
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

- (void)layoutQueryLinkViewController:(RptqQueryLinks *)queryLink animated:(BOOL)animated {

    UIViewController *controller = self.controllersForObjectIdsLink[queryLink.objectID];
    MTConnectorView *connectorView = (MTConnectorView *)controller.view;
    const CGFloat paddingLeft = 75.0000f;
    
    MADQueryVisualizationSchemaViewController *leftTableViewController = self.controllersForObjectIds[queryLink.hasLeftField.inQueryTable.objectID];
    MADQueryVisualizationSchemaViewController *rightTableViewController = self.controllersForObjectIds[queryLink.hasRightField.inQueryTable.objectID];
    
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

@end
