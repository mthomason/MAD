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

NSString * const MTKeyIsTopLevel = @"MTKeyIsTopLevel";

NSString * const MTIdentifierCollisionBoundryTop = @"MTIdentifierCollisionBoundryLandscapeTop";
NSString * const MTIdentifierCollisionBoundryRight = @"MTIdentifierCollisionBoundryLandscapeRight";
NSString * const MTIdentifierCollisionBoundryBottom = @"MTIdentifierCollisionBoundryLandscapeBottom";
NSString * const MTIdentifierCollisionBoundryLeft = @"MTIdentifierCollisionBoundryLandscapeLeft";

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

    @property (nonatomic, strong) NSMutableArray *rootTables;

    @property (nonatomic, strong) NSMutableArray *viewControllers;  //May track child view controllers since iOS 7.
    @property (nonatomic, strong) NSMutableSet *tableIds;

    @property (nonatomic, strong) NSMutableDictionary *controllersForObjectIds;     //Tables and links
    @property (nonatomic, strong) NSMutableDictionary *controllersForObjectIdsLink; //Only query links

    @property (nonatomic, strong) UIDynamicAnimator *dynamicAnimator;
    @property (nonatomic, strong) UICollisionBehavior *collisionBehavior;
    @property (nonatomic, strong) UIDynamicItemBehavior *dynamicItemBehavior;
    @property (nonatomic, strong) NSMutableDictionary *attachmentBehaviors;
    @property (nonatomic, strong) NSMutableDictionary *attachmentLinks;

    @property (nonatomic, strong) NSLayoutConstraint *layoutConstraintSizeWidth;
    @property (nonatomic, strong) NSLayoutConstraint *layoutConstraintSizeHeight;

    @property (nonatomic, strong) NSMutableSet *linksThatNeedLayout;

@end

@implementation MADQueryVisualizationViewController

- (void)dealloc {
    RptqDocument *document = [self.document activeDocumentModel];
    [MADQueryVisualizationViewController removeNotificationsFromObserver:self forObjectContext:[document managedObjectContext]];
    NSSet *setToRemove = [NSSet setWithArray:_viewControllers];
    [self removeViewControllers:setToRemove];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    NSMutableArray *viewControllers = [[NSMutableArray alloc] init];
    self.viewControllers = viewControllers;
    
    NSMutableSet *tableObjectIds = [[NSMutableSet alloc] init];
    self.tableIds = tableObjectIds;
    
    NSMutableDictionary *controllersForObjectIds = [[NSMutableDictionary alloc] init];
    self.controllersForObjectIds = controllersForObjectIds;
    
    NSMutableDictionary *controllersForObjectIdsLink = [[NSMutableDictionary alloc] init];
    self.controllersForObjectIdsLink = controllersForObjectIdsLink;
    
    NSMutableDictionary *attachmentBehaviors = [[NSMutableDictionary alloc] init];
    self.attachmentBehaviors = attachmentBehaviors;
    
    NSMutableDictionary *attachmentLinks = [[NSMutableDictionary alloc] init];
    self.attachmentLinks = attachmentLinks;
    
    NSMutableArray *rootTables = [[NSMutableArray alloc] init];
    self.rootTables = rootTables;
    
    NSArray *dynamicItems = @[];
    UIDynamicItemBehavior *dynamicItemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:dynamicItems];
    dynamicItemBehavior.allowsRotation = NO;
    dynamicItemBehavior.elasticity = 0.6000f;
    dynamicItemBehavior.resistance = 1.0000f;
    self.dynamicItemBehavior = dynamicItemBehavior;

    NSArray *collisionItems = @[];
    UICollisionBehavior *collisionBehavior = [[UICollisionBehavior alloc] initWithItems:collisionItems];
    collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    collisionBehavior.collisionMode = UICollisionBehaviorModeItems;
    collisionBehavior.collisionDelegate = self;
    self.collisionBehavior = collisionBehavior;
    
    NSMutableSet *linksThatNeedLayout = [[NSMutableSet alloc] init];
    self.linksThatNeedLayout = linksThatNeedLayout;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.document = [MTApplicationInstance mainInstance].openDocument;
    
    CGFloat borderWidth = [UIDevice isRetnaDisplay] ? 0.5000f : 1.0000f;
    UIColor *borderColor = [UIColor lightGrayColor];
    self.backgroundContainer.layer.borderWidth = borderWidth;
    self.backgroundContainer.layer.borderColor = borderColor.CGColor;
    
    UIView *containerView = [[UIView alloc] initWithFrame:self.backgroundContainer.bounds];
    containerView.contentMode = UIViewContentModeScaleAspectFit;
    containerView.autoresizesSubviews = NO;
    containerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    MADWatermarkScrollView *scrollView = [[MADWatermarkScrollView alloc] initWithFrame:self.backgroundContainer.bounds];
    scrollView.delegate = self;
    [scrollView addSubview:containerView];
    
    
    [self.backgroundContainer addSubview:scrollView];
    
    NSLayoutConstraint *layoutConstraintSizeHeight = [NSLayoutConstraint heightForView:containerView
                                                                             andHeight:2400.0000f];
    NSLayoutConstraint *layoutConstraintSizeWidth = [NSLayoutConstraint widthForView:containerView
                                                                            andWidth:2400.0000f];
    
    NSArray *containerViewConstraints = @[layoutConstraintSizeHeight, layoutConstraintSizeWidth];
    [containerView addConstraints:containerViewConstraints];
    
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
    
    UIDynamicAnimator *animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.contentView];
    [animator addBehavior:self.dynamicItemBehavior];
    [animator addBehavior:self.collisionBehavior];
    self.dynamicAnimator = animator;
    
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    [super viewDidAppear:animated];
    if (animated) {
        [self.scrollView flashScrollIndicators];
    }
    [self reloadDocument:self.document animated:YES];

}

- (void)viewWillLayoutSubviews {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    [super viewWillLayoutSubviews];
    self.scrollView.contentSize = CGSizeMake(2400.0000f, 2400.0000f);
    self.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width, self.bottomLayoutGuide.length, CGSizeZero.height);
    
    if (self.linksThatNeedLayout.count > 0) {
        for (NSURL *url in self.linksThatNeedLayout) {
            NSManagedObjectID *objectID = [self.document.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:url];
            RptqQueryTable *queryTable = [RptqQueryTable queryTableWithObjectID:objectID managedObjectContext:self.document.managedObjectContext];
            for (RptqQueryLinks *queryLink in queryTable.inQuery.hasQueryLinks) {
                if ([queryLink.hasLeftField.inQueryTable isEqualTo:queryTable] ||
                    [queryLink.hasRightField.inQueryTable isEqualTo:queryTable]) {
                    [self layoutQueryLinkViewController:queryLink animated:NO];
                }
            }
        }
    }

}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender { }

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
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

- (void)resizeScrollViewContentArea {
    /*NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
     if (self.scrollView.isZooming == NO) {
     CGFloat maxX = CGPointZero.x, maxY = CGPointZero.y;
     
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
     
     CGSize s = CGSizeMake(MAX(maxX, self.view.bounds.size.width) , MAX(maxY, self.view.bounds.size.height));
     
     self.layoutConstraintSizeHeight.constant = s.height;
     self.layoutConstraintSizeWidth.constant = s.width;
     self.scrollView.contentSize = s;
     
     }
     //[self.contentView layoutIfNeeded];
     */
    
    /*
     if (self.scrollView.contentSize.height < self.contentView.bounds.size.height) {
     self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, self.contentView.bounds.size.height);
     }
     
     if (self.scrollView.contentSize.width < self.contentView.bounds.size.width) {
     self.scrollView.contentSize = CGSizeMake(self.contentView.bounds.size.width, self.scrollView.contentSize.height);
     }*/
}


- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
}

#pragma mark - Setup Notifications

+ (void)removeNotificationsFromObserver:(id<MADQueryVisualizationSchemaDelegate>)observer forObjectContext:(NSManagedObjectContext *)objectContext {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
 
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    [defaultCenter removeObserver: observer
                             name: NSManagedObjectContextWillSaveNotification
                           object: objectContext];
    
    [defaultCenter removeObserver: observer
                             name: NSManagedObjectContextDidSaveNotification
                           object: objectContext];
    
}

+ (void)addNotificationsToObserver:(id<MADQueryVisualizationSchemaDelegate>)observer forObjectContext:(NSManagedObjectContext *)objectContext {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
   
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
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);

}

- (void)managedObjectContextDidSave:(NSNotification *)notification {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);

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

                [self.rootTables removeObject:updatedTable];
                
                // Reposition existing tables
                CGFloat segHeight = (self.contentView.bounds.size.height / (self.rootTables.count + 1));
                NSUInteger counter = 0;
                for (RptqQueryTable *queryTable in self.rootTables) {
                    CGFloat attachmentPointY = segHeight * (counter + 1);
                    CGPoint attachmentPoint = CGPointMake(CGPointZero.x, attachmentPointY - 22.0000f);
                    UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviors[queryTable.objectID.URIRepresentation];
                    [attachmentBehavior setAnchorPoint:attachmentPoint];
                    counter++;
                }
                
                // FIXME: Maybe block this and move it off screen.
                UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviors[updatedTable.objectID.URIRepresentation];
                [self.dynamicAnimator removeBehavior:attachmentBehavior];
                [self.collisionBehavior removeItem:(MADQueryVisualizationSchemaViewController *)viewController];
                [self.dynamicItemBehavior removeItem:(MADQueryVisualizationSchemaViewController *)viewController];
                [self.attachmentBehaviors removeObjectForKey:updatedTable.objectID.URIRepresentation];
                
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

#pragma mark View Controller Container Custom Handlers

- (void)viewControllerDidFinish:(id)sender {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    [self dismissViewControllerAnimated:YES completion:^{ }];
}

#pragma mark - UIDynamicAnimatorDelegate

- (void)dynamicAnimatorWillResume:(UIDynamicAnimator *)animator {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);

}

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
}

#pragma mark - Gesture recognizer actions

- (void)tapPiece:(UITapGestureRecognizer *)gestureRecognizer {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
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
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    UIWindow *window = [[UIApplication sharedApplication] windows][0];
    CGPoint gestureLocation = [gestureRecognizer locationInView:window];
    UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviors[gestureRecognizer.view.objectIdTag.URIRepresentation];
    attachmentBehavior.anchorPoint = [window convertPoint:gestureLocation toView:self.contentView];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    [self resizeScrollViewContentArea];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    //[self resizeScrollViewContentArea];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    //[self resizeScrollViewContentArea];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    //[self resizeScrollViewContentArea];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    [self resizeScrollViewContentArea];
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    //[self resizeScrollViewContentArea];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    return NO;
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    //[self resizeScrollViewContentArea];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    //[self resizeScrollViewContentArea];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    return self.contentView;
}

#pragma mark - UICollisionBehaviorDelegate

//- (void)collisionBehavior:(UICollisionBehavior *)behavior endedContactForItem:(id<UIDynamicItem>)item withBoundaryIdentifier:(id<NSCopying>)identifier {

//}
    
#pragma mark - Change UI on IR Diagram

- (void)clearScreen {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    
    for (UIViewController *viewController in self.viewControllers) {
        Class schemaTableClass = [MADQueryVisualizationSchemaViewController class];
        if ([viewController isKindOfClass:schemaTableClass]) {
            UIAttachmentBehavior *attachmentBehaviorForObjectId = self.attachmentBehaviors[viewController.view.objectIdTag.URIRepresentation];
            [self.dynamicAnimator removeBehavior:attachmentBehaviorForObjectId];
            [self.attachmentBehaviors removeObjectForKey:viewController.view.objectIdTag.URIRepresentation];
            MADQueryVisualizationSchemaViewController *controller = (MADQueryVisualizationSchemaViewController *)viewController;
            [self.collisionBehavior removeItem:controller];
        }
    }

    NSSet *viewControllers = [NSSet setWithArray:self.viewControllers];
    [self removeViewControllers:viewControllers];
    
}

- (MTLinkedList *)tableObjectIDsSortedTopologicallyForQuery:(RptqQuery *)query {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);

    MTGraph *graph = [[MTGraph alloc] init];
    NSSet *hasTables = query.hasQueryTables;
    
    //Add a vertex to the graph for each table.
    for (RptqDatabaseSchemaTable *table in hasTables) {
        [graph addVertexWithObject:table.objectID];
    }
    
    //Create an edge in the graph for each query link.
    NSNumber *weight = @(1);
    for (RptqQueryLinks *queryLink in query.hasQueryLinks) {
        
        MTVertex *vertexOrigin =        [graph vertexForObject:(MTObject *)queryLink.hasLeftField.inQueryTable.objectID];
        MTVertex *vertexDestination =   [graph vertexForObject:(MTObject *)queryLink.hasRightField.inQueryTable.objectID];
        
        [graph addEdgeWithOrigin: vertexOrigin
                     destination: vertexDestination
                          object: queryLink.objectID
                       andWeight: weight];
        
    }
    
    NSError *error = nil;
    BOOL isDirectedAcyclicGraph;
    MTLinkedList *tableIds = [graph topologicalSortWithError:&error isDirectedAcyclicGraph:&isDirectedAcyclicGraph];
    return tableIds;

}

#pragma mark Reload document view controllers

- (void)redraw {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    [self reloadDocument:self.document animated:NO];
}

- (void)reloadDocument:(MADocument *)documentReport animated:(BOOL)animated {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    if (documentReport) {
        
        [self clearScreen];
        
        [self.rootTables removeAllObjects];
        [self.viewControllers removeAllObjects];  //May track child view controllers since iOS 7.
        [self.tableIds removeAllObjects];
        [self.controllersForObjectIds removeAllObjects];     //Tables and links
        [self.controllersForObjectIdsLink removeAllObjects];
        
        RptqQuery *query = documentReport.activeDocumentModel.query;
        
        [self displayQuery:query animated:animated];
    }
    
}

- (void)insertQueryLink:(RptqQueryLinks *)insertedQueryLinks {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    
    //RptqQuery *query = insertedQueryLinks.inQuery;
    MADQueryVisulizationDefination *queryDef = [[MADQueryVisulizationDefination alloc] initWithQuery:insertedQueryLinks.inQuery];
    
    RptqQueryTable *leftTable = insertedQueryLinks.hasLeftField.inQueryTable;
    MADQueryVisualizationSchemaViewController *leftTableViewController = self.controllersForObjectIds[leftTable.objectID.URIRepresentation];
    
    RptqQueryTable *rightTable = insertedQueryLinks.hasRightField.inQueryTable;
    MADQueryVisualizationSchemaViewController *rightTableViewController = self.controllersForObjectIds[rightTable.objectID.URIRepresentation];
    
    // Remove starting point connection if one of the tables is in the link.
    BOOL startingPointRemoved = NO;
    RptqQueryTable *queryTableRemoved = nil;
    NSUInteger startingPointsRemovedCounter = 0;
    for (RptqQueryTable *queryTable in self.rootTables) {
        
        RptqQueryTable *removeableTable = nil;
        
        //NSDictionary *layout = layoutDetails[queryTable.objectID];
        //NSNumber *isTopLevel = layout[MTKeyIsTopLevel];
        if ([queryDef.startingPoints containsObject: queryTable.objectID.URIRepresentation] == NO) {
            if ([leftTable.objectID isEqual:queryTable.objectID]) {
                removeableTable = queryTable;
            } else if ([rightTable.objectID isEqual:queryTable.objectID]) {
                removeableTable = queryTable;
            }
        }
        if (removeableTable) {
            queryTableRemoved = queryTable;
            UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviors[removeableTable.objectID.URIRepresentation];
            [self.dynamicAnimator removeBehavior:attachmentBehavior];
            [self.attachmentBehaviors removeObjectForKey:removeableTable.objectID.URIRepresentation];
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
        for (RptqQueryTable *queryTable in self.rootTables) {
            CGFloat attachmentPointY = segHeight * (counter + 1);
            CGPoint attachmentPoint = CGPointMake(CGPointZero.x, attachmentPointY - 22.0000f);
            UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviors[queryTable.objectID.URIRepresentation];
            [attachmentBehavior setAnchorPoint:attachmentPoint];
            counter++;
        }
    }
    
    //Add connections between MTQueryBuilderAdvancedSchemaViewController
    if ([leftTableViewController isEqual:rightTableViewController] == NO) {
        UIAttachmentBehavior *attachmentBehavior = [MADQueryVisualizationViewController attachmentBehaviorLinkWithLeftViewController: leftTableViewController
                                                                                                              andRightViewController: rightTableViewController];
        [self.dynamicAnimator addBehavior:attachmentBehavior];
        self.attachmentBehaviors[insertedQueryLinks.objectID.URIRepresentation] = attachmentBehavior;
        
        //Add animation layer
        [self addLinkViewControllerForQueryLink: insertedQueryLinks animated:YES];
    }
}


- (void)displayQuery:(RptqQuery *)query animated:(BOOL)animated {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    
    MADQueryVisulizationDefination *queryDef = [[MADQueryVisulizationDefination alloc] initWithQuery:query];
    
    NSInteger tableCounter = 0;
    NSInteger topLevelTableCounter = 0;

    for (MTPair *pair in queryDef.topologicallySortedTables) {
        
        MTVertex *tableIdVertext = pair.former;

        if (tableIdVertext.object != nil) {
            
            RptqQueryTable *table = (RptqQueryTable *)[self.document.managedObjectContext objectWithID:tableIdVertext.object];
            
            BOOL topLevel = [queryDef.startingPoints containsObject: table.objectID.URIRepresentation];
            MADQueryVisualizationSchemaViewController *viewController = [self addSchemaViewControllerForTable:table root:topLevel animated:animated];
            
            if (animated) {
                UIAttachmentBehavior *attachmentBehavior = [MADQueryVisualizationViewController attachmentBehaviorAnchorWithItem:viewController attachedToPoint:viewController.center];
                [self.dynamicAnimator addBehavior:attachmentBehavior];
                self.attachmentBehaviors[viewController.view.objectIdTag.URIRepresentation] = attachmentBehavior;
                if (topLevel) {
                    [self.rootTables addObject:table];
                    topLevelTableCounter++;
                }
                tableCounter++;
            }
        }
    }
    
    // Display links
    for (RptqQueryLinks *queryLink in query.hasQueryLinks) {
        [self addLinkViewControllerForQueryLink:queryLink animated:animated];
    }
}

- (void)deleteQueryTable:(RptqQueryTable *)deletedQueryTable {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);

    BOOL startingPointTable = [self.rootTables containsObject:deletedQueryTable.objectID];
    if (startingPointTable) {
        CGPoint offScreen = CGPointMakeRandomOffscreen();
        UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviors[deletedQueryTable.objectID.URIRepresentation];
        [attachmentBehavior setAnchorPoint:offScreen];
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
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);

    NSMutableSet *orphanedQueryTables = [[NSMutableSet alloc] init];
    
    RptqDocument *document = [self.document activeDocumentModel];
    RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
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
    
    NSSet *startingPoints = [NSSet setWithArray:self.rootTables];
    [orphanedQueryTables minusSet:startingPoints];  // Should only be one newly orphaned table.
    
    NSManagedObjectID *deletedLinkObjectId = [deletedQueryLinks objectID];
    RptqQueryLinks *deletedLink = (RptqQueryLinks *)[self.document.managedObjectContext objectWithID:deletedLinkObjectId];
    UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviors[deletedLinkObjectId.URIRepresentation];
    
    for (RptqQueryTable *table in orphanedQueryTables) {
        
        RptqQueryTable *tableRightDeletedLink = table;
        MADQueryVisualizationSchemaViewController *viewController = self.controllersForObjectIds[tableRightDeletedLink.objectID.URIRepresentation];
        
        // Is there a link still pointing to the view controller after the delete, or
        //   do we need to make it top level?
        
        CGPoint attachmentPoint = CGPointMake(CGPointZero.x + self.contentView.frame.size.width,
                                              CGPointZero.y + self.contentView.frame.size.height / 2.0000f);
 
        UIAttachmentBehavior *anchorBehaviorNew = [MADQueryVisualizationViewController attachmentBehaviorAnchorWithItem:viewController attachedToPoint:attachmentPoint];
        [self.dynamicAnimator addBehavior:anchorBehaviorNew];
        self.attachmentBehaviors[tableRightDeletedLink.objectID.URIRepresentation] = anchorBehaviorNew;
        [self.rootTables addObject: tableRightDeletedLink];
        
        // Disable collision behaviors before reposition
        // Reposition existing tables
        CGFloat segHeight = (self.contentView.bounds.size.height / (self.rootTables.count + 1));
        NSUInteger counter = 0;
        for (RptqQueryTable *queryTable in self.rootTables) {
            UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviors[queryTable.objectID.URIRepresentation];
            attachmentBehavior.anchorPoint = CGPointMake(CGPointZero.x, segHeight * (counter + 1) - 22.0000f);
            counter++;
        }
    }
    
    [self.dynamicAnimator removeBehavior:attachmentBehavior];
    [self.attachmentBehaviors removeObjectForKey:deletedLinkObjectId];
    
    UIViewController *linkViewController = self.controllersForObjectIdsLink[deletedLink.objectID.URIRepresentation];
    if (linkViewController != nil) {
        [self removeViewController:linkViewController];
    }
}

- (void)insertQueryTable:(RptqQueryTable *)insertedQueryTable {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    
    CGFloat segHeight = self.contentView.bounds.size.height / (self.rootTables.count + 2);
    
    // Reposition existing tables
    // FIXME: Good place for block iterate?
    NSUInteger counter = 0;
    for (RptqQueryTable *queryTable in self.rootTables) {
        CGPoint attachmentPoint = CGPointMake(CGPointZero.x, segHeight * (counter + 1) - 22.0000f);
        UIAttachmentBehavior *attachmentBehavior = self.attachmentBehaviors[queryTable.objectID.URIRepresentation];
        [attachmentBehavior setAnchorPoint:attachmentPoint];
        counter++;
    }
    
    CGFloat attachmentPointY = segHeight * (self.rootTables.count + 1);
    CGPoint insertTableAnchorPoint = CGPointMake(CGPointZero.x, attachmentPointY - 22.0000f);
    
    // Insert new and unlinked query table
    
    //Going to assume that it's a top level table.
    [self.rootTables addObject:insertedQueryTable];
    
    // Insert table
    MADQueryVisualizationSchemaViewController *viewController = [self addSchemaViewControllerForTable:insertedQueryTable root:YES animated:YES];

    NSManagedObjectID *objectIDView = [viewController.view objectIdTag];
    UIAttachmentBehavior *attachmentBehavior = [MADQueryVisualizationViewController attachmentBehaviorAnchorWithItem:viewController attachedToPoint:insertTableAnchorPoint];
    [self.dynamicAnimator addBehavior:attachmentBehavior];
    self.attachmentBehaviors[objectIDView.URIRepresentation] = attachmentBehavior;
}

#pragma mark - UI Items

+ (UIAttachmentBehavior *)attachmentBehaviorAnchorWithItem:(id<UIDynamicItem>)item attachedToPoint:(CGPoint)anchorPoint {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    CGPoint attachmentPoint = CGPointMake(CGPointZero.x, anchorPoint.y - 22.0000f);
    UIAttachmentBehavior *behavior = [[UIAttachmentBehavior alloc] initWithItem:item attachedToAnchor:attachmentPoint];
    behavior.length = 0.0000f;
    return behavior;

}

+ (UIAttachmentBehavior *)attachmentBehaviorLinkWithLeftViewController:(MADQueryVisualizationSchemaViewController *)viewControllerLeft
                                                andRightViewController:(MADQueryVisualizationSchemaViewController *)viewControllerRight {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    
    // FIXME: Make sure they are not the same, or crash, lolz

    UIAttachmentBehavior *behavior = [[UIAttachmentBehavior alloc] initWithItem:viewControllerRight attachedToItem:viewControllerLeft];
    behavior.frequency = 0.0000f;
    behavior.damping = 1.000f;
    behavior.length = 175.0000f;
    
    return behavior;
}

#pragma mark - Helper functions

+ (CGPoint)randomPointInRect:(CGRect)rect {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
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
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
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
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
   
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

- (void)removeViewControllers:(NSSet *)viewControllers {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    for (UIViewController *viewController in viewControllers) {
        [self removeViewController:viewController];
        
        Class schemaTableClass = [MADQueryVisualizationSchemaViewController class];
        if ([viewController isKindOfClass:schemaTableClass]) {
            MADQueryVisualizationSchemaViewController *controller = (MADQueryVisualizationSchemaViewController *)viewController;
            UIAttachmentBehavior *attachmentBehaviorForObjectId = self.attachmentBehaviors[viewController.view.objectIdTag.URIRepresentation];
            [self.dynamicAnimator removeBehavior:attachmentBehaviorForObjectId];

            [self.attachmentBehaviors removeObjectForKey:viewController.view.objectIdTag.URIRepresentation];
            [self.collisionBehavior removeItem:controller];
        }
    }
}

- (void)removeViewController:(UIViewController *)viewController {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
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

- (MADQueryVisualizationSchemaViewController *)addSchemaViewControllerForTable:(RptqQueryTable *)table root:(BOOL)root animated:(BOOL)animated {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    
    MADQueryVisualizationSchemaViewController *viewController = [MADQueryVisualizationSchemaViewController advancedSchemaViewController];
    viewController.document = self.document;
    viewController.delegate = self;
    viewController.tableObjectId = table.objectID;
    if (root) viewController.toolbar.backgroundColor = [UIColor blueColor];
    
    CGRect subviewRect = CGRectZero;
    
    [self.tableIds addObject:table.objectID.URIRepresentation];
    self.controllersForObjectIds[table.objectID.URIRepresentation] = viewController;
    CGFloat originX = 10.0000f + CGPointZero.x;
    BOOL ud = table.identifier.integerValue % 2;
    CGFloat originY = CGPointZero.y + self.scrollView.frame.size.height - (ud ? 200.0000f : - 600.0000f) - 20.0000f;
    subviewRect = CGRectMake(originX, originY, 120.0000f, 140.0000f);
    viewController.view.frame = subviewRect;
    
    [self addGesturesToViewController:viewController];
    
    NSArray *constraints = nil;
    CGRect desiredFrame;
    CGRect viewControllerBounds = self.contentView.bounds;
    desiredFrame = [MADQueryVisualizationViewController rectForDesiredRect:subviewRect inBounds:viewControllerBounds];
    
    NSLayoutConstraint *width = [NSLayoutConstraint schemaViewWidthForView:viewController.view
                                                                  andWidth:desiredFrame.size.width];
    
    NSLayoutConstraint *height = [NSLayoutConstraint schemaViewHeightForView:viewController.view
                                                                   andHeight:desiredFrame.size.height];
    viewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    constraints = @[width, height];
    
    [self addChildViewController:viewController];
    if ([self.viewControllers containsObject:viewController] == NO) {
        [self.viewControllers addObject:viewController];
    }
    
    [self.contentView addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
    
    [self.contentView addConstraints:constraints];
    
    [self.collisionBehavior addItem:viewController];
    [self.dynamicItemBehavior addItem:viewController];
    
    return viewController;
    
}


- (void)addLinkViewControllerForQueryLink:(RptqQueryLinks *)link animated:(BOOL)animated {
    NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);
    NSManagedObjectID *objectId = [link objectID];
    
    
    MTConnectorView *connectorView = [[MTConnectorView alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, 100.0000f, 100.0000f)];
    connectorView.userInteractionEnabled = NO;
    connectorView.objectIdTag = objectId;
    
    UIViewController *connectorViewController = [[UIViewController alloc] init];
    connectorViewController.view = connectorView;
    
    self.controllersForObjectIds[objectId.URIRepresentation] = connectorViewController;
    self.controllersForObjectIdsLink[objectId.URIRepresentation] = connectorViewController;
    
    if (animated == NO) {
        [self layoutQueryLinkViewController:link animated:animated];
    }
    
    CGRect desiredFrame = connectorViewController.view.frame;
    CGPoint desiredCenter = connectorViewController.view.center;
    CGAffineTransform desiredTransform = connectorViewController.view.transform;
    CGAffineTransform swingTransform = animated ? CGAffineTransformSwing() : CGAffineTransformIdentity;
    
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
        [self.linksThatNeedLayout addObject:((MADQueryVisualizationSchemaViewController *)sender).tableObjectId.URIRepresentation];
        [self.view setNeedsLayout];
    }
}

- (void)layoutQueryLinkViewController:(RptqQueryLinks *)queryLink animated:(BOOL)animated {
    //NSLog(@"%s %s %d", __FILE__, __PRETTY_FUNCTION__, __LINE__);

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
    CGRect rightCellFrameInView = [self.contentView convertRect:rightCellFrameInTable fromView:rightTableViewController.view];
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
