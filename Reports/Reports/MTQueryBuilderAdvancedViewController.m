//
//  MTQueryBuilderAdvancedViewController.m
//  Reports
//
//  Created by Michael Thomason on 2/14/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderAdvancedViewController.h"
#import "MTViewControllerDynamicItem.h"
#import "MAReportDocument.h"
#import "CGAffineTransform+Common.h"
#import "UIDevice+Hack.h"
#import "MTShowSqlViewController.h"

NSString * const MTKeyIsTopLevel = @"MTKeyIsTopLevel";

NSString * const MTIdentifierCollisionBoundryTop = @"MTIdentifierCollisionBoundryLandscapeTop";
NSString * const MTIdentifierCollisionBoundryRight = @"MTIdentifierCollisionBoundryLandscapeRight";
NSString * const MTIdentifierCollisionBoundryBottom = @"MTIdentifierCollisionBoundryLandscapeBottom";
NSString * const MTIdentifierCollisionBoundryLeft = @"MTIdentifierCollisionBoundryLandscapeLeft";
NSString * const MTQueryBuilderAdvancedSchemaViewControllerIdentifier = @"MTQueryBuilderAdvancedSchemaViewControllerIdentifier";

typedef void(^MTBlockResultVoid)(void);

@interface MTQueryBuilderAdvancedViewController ()

    @property (nonatomic, assign) BOOL uidynamicsSetup;

    @property (nonatomic, retain) IBOutlet UIToolbar *toolbarBottom;
    @property (nonatomic, retain) IBOutlet UIView *backgroundContainer;

    @property (nonatomic, retain) MTScrollViewCenter *scrollView;
    @property (nonatomic, retain) UIView *contentView;

    @property (nonatomic, retain) NSMutableArray *viewControllers;  //May track child view controllers since iOS 7.
    @property (nonatomic, retain) NSMutableSet *tableIds;

    //@property (nonatomic, retain) MAReportDocument *reportDocument;

    @property (nonatomic, retain) NSMutableDictionary *controllersForObjectIds;     //Tables and links
    @property (nonatomic, retain) NSMutableDictionary *controllersForObjectIdsLink; //Only query links

    @property (nonatomic, retain) NSMutableArray *tableStartingPoints;

    @property (nonatomic, retain) UIDynamicAnimator *dynamicAnimator;
    @property (nonatomic, retain) UICollisionBehavior *collisionBehavior;
    @property (nonatomic, retain) UIGravityBehavior *gravityBeahvior;
    @property (nonatomic, retain) UIDynamicItemBehavior *dynamicItemBehavior;
    @property (nonatomic, retain) NSMutableDictionary *attachmentBehaviors;
    @property (nonatomic, retain) NSMutableDictionary *pushBehaviors;

    @property (nonatomic, assign) NSUInteger tableDisplayCounter;

    @property (nonatomic, retain) IBOutlet NSLayoutConstraint *containerViewHeightConstraint;
    @property (nonatomic, retain) IBOutlet NSLayoutConstraint *containerViewWidthConstraint;
    @property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemShowSQL;

    @property (nonatomic, retain) UIPopoverController *showSqlPopoverController;
    @property (nonatomic, assign) BOOL showSqlIsVisable;    //May be redundent with [showSqlPopoverController isVisable];

    @property (nonatomic, retain) UIStoryboard *storyboardDefault;

@end

@implementation MTQueryBuilderAdvancedViewController

- (void)dealloc {
    MTApplicaitonInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    RptqDocument *document = [reportDocument activeDocument];
    [MTQueryBuilderAdvancedViewController removeNotificationsFromObserver:self forObjectContext:[document managedObjectContext]];
    NSSet *setToRemove = [NSSet setWithArray:_viewControllers];
    [self removeViewControllers:setToRemove];
    [_storyboardDefault release];
    [_dynamicItemBehavior release];
    [_tableStartingPoints release];
    [_gravityBeahvior release];
    [_collisionBehavior release];
    [_attachmentBehaviors release];
    [_dynamicAnimator release];
    [_pushBehaviors release];
    [_viewControllers release];
    [_controllersForObjectIds release];
    [_controllersForObjectIdsLink release];
    [_scrollView release];
    [_contentView release];
    [_containerViewHeightConstraint release];
    [_containerViewWidthConstraint release];
    [_backgroundContainer release];
    [_toolbarBottom release];
    [_barButtonItemShowSQL release];
    [_tableIds release];
    [_showSqlPopoverController release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        [self setUidynamicsSetup:NO];
        
        NSMutableArray *viewControllers = [[NSMutableArray alloc] init];
        [self setViewControllers:viewControllers];
        [viewControllers release];

        NSMutableSet *tableObjectIds = [[NSMutableSet alloc] init];
        [self setTableIds:tableObjectIds];
        [tableObjectIds release];
        
        NSMutableDictionary *controllersForTableIds = [[NSMutableDictionary alloc] init];
        [self setControllersForObjectIds:controllersForTableIds];
        [controllersForTableIds release];
        
        NSMutableDictionary *controllersForObjectIdsLink = [[NSMutableDictionary alloc] init];
        [self setControllersForObjectIdsLink:controllersForObjectIdsLink];
        [controllersForObjectIdsLink release];
        
        NSMutableDictionary *attachmentBehaviors = [[NSMutableDictionary alloc] init];
        [self setAttachmentBehaviors:attachmentBehaviors];
        [attachmentBehaviors release];
        
        NSMutableArray *tableStartingPoints = [[NSMutableArray alloc] init];
        [self setTableStartingPoints:tableStartingPoints];
        [tableStartingPoints release];
        
        NSMutableDictionary *pushBehaviors = [[NSMutableDictionary alloc] init];
        [self setPushBehaviors:pushBehaviors];
        [pushBehaviors release];
        
        [self setTableDisplayCounter:0];

        UIStoryboard *sb = [[MTApplicaitonInstance storyboard] retain];
        [self setStoryboardDefault:sb];
        [sb release];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([UIDevice isPad]) {
        CGFloat borderWidth = [UIDevice isRetnaDisplay] ? 0.5000f : 1.0000f;
        UIColor *borderColor = [UIColor lightGrayColor];
        [[[self backgroundContainer] layer] setBorderWidth:borderWidth];
        [[[self backgroundContainer] layer] setBorderColor:[borderColor CGColor]];
    }
    [self setShowSqlIsVisable:NO];
    UIView *containerView = [[UIView alloc] initWithFrame:[[self backgroundContainer] bounds]];
    
    UIViewAutoresizing autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [containerView setAutoresizingMask:autoresizingMask];
    [containerView setContentMode:UIViewContentModeScaleAspectFit];
    [containerView setAutoresizesSubviews:NO];
    [[self contentView] setTranslatesAutoresizingMaskIntoConstraints:NO];
    MTScrollViewCenter *scrollView = [[MTScrollViewCenter alloc] initWithFrame:[[self backgroundContainer] bounds]];
    [scrollView setShowsHorizontalScrollIndicator:YES];
    [scrollView setShowsVerticalScrollIndicator:YES];
    [scrollView setAutoresizingMask:autoresizingMask];
    [scrollView setContentOffset:CGPointZero];
    [scrollView setMaximumZoomScale:4.0000f];
    [scrollView setMinimumZoomScale:0.2000f];
    [scrollView setZoomScale:1.0000f];
    [scrollView setScrollEnabled:YES];
    [scrollView setBounces:YES];
    [scrollView setAlwaysBounceHorizontal:YES];
    [scrollView setAlwaysBounceVertical:YES];
    [scrollView setBouncesZoom:NO];
    [scrollView setDelegate:self];
    [scrollView setDelaysContentTouches:YES];
    [scrollView setBackgroundColor:[UIColor clearColor]];
    [scrollView addSubview:containerView];
    [scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self setScrollView:scrollView];
    [scrollView release];
    [[self backgroundContainer] addSubview:[self scrollView]];
    
    NSLayoutConstraint *leftBorder = [NSLayoutConstraint constraintWithItem:scrollView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:[self backgroundContainer] attribute:NSLayoutAttributeLeft multiplier:1.0000f constant:0.0000f];
    NSLayoutConstraint *rightBorder = [NSLayoutConstraint constraintWithItem:scrollView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:[self backgroundContainer] attribute:NSLayoutAttributeRight multiplier:1.0000f constant:0.0000f];
    NSLayoutConstraint *topBorder = [NSLayoutConstraint constraintWithItem:scrollView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:[self backgroundContainer] attribute:NSLayoutAttributeTop multiplier:1.0000f constant:0.0000f];
    NSLayoutConstraint *bottomBorder = [NSLayoutConstraint constraintWithItem:scrollView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:[self backgroundContainer] attribute:NSLayoutAttributeBottom multiplier:1.0000f constant:0.0000f];
    NSArray *constraints = @[leftBorder, rightBorder, topBorder, bottomBorder];
    [[self backgroundContainer] addConstraints:constraints];
    
    [self setContentView:containerView];
    [containerView release];
    
    NSMutableArray *toolbarButtons = [[[self toolbarBottom] items] mutableCopy];
    [toolbarButtons removeObject:[self barButtonItemShowSQL]];
    [[self toolbarBottom] setItems:toolbarButtons animated:NO];
    [toolbarButtons release];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self uidynamicsSetup] == NO) {
        
        [self setUidynamicsSetup:YES];

        UIDynamicAnimator *animator = [[UIDynamicAnimator alloc] initWithReferenceView:[self contentView]];
        
        UICollisionBehavior *collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[]];
        [collisionBehavior setTranslatesReferenceBoundsIntoBoundary:YES];
        [collisionBehavior setCollisionMode:UICollisionBehaviorModeItems];
        [collisionBehavior setCollisionDelegate:self];
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[]];
        [gravity setMagnitude:1.0000f];
        CGVector gravityDirection = CGVectorMake(1, 0);
        [gravity setGravityDirection:gravityDirection];
        UIDynamicItemBehavior *dynamicItemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[]];
        [dynamicItemBehavior setAllowsRotation:NO];
        [dynamicItemBehavior setElasticity:0.0000f];
        [dynamicItemBehavior setResistance:1.0000f];
        [self setDynamicItemBehavior: dynamicItemBehavior];
        [animator addBehavior:dynamicItemBehavior];
        
        
        
        [animator addBehavior:collisionBehavior];
        [animator addBehavior:gravity];
        [self setDynamicAnimator:animator];
        [self setGravityBeahvior:gravity];
        [self setCollisionBehavior:collisionBehavior];
        [collisionBehavior release];
        [dynamicItemBehavior release];
        [gravity release];
        [animator release];

    }
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (animated) {
        [[self scrollView] flashScrollIndicators];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    if ([self scrollView].contentSize.height < [[self contentView] bounds].size.height) {
        CGSize contentSize = CGSizeMake([[self scrollView] contentSize].width, [[self contentView] bounds].size.height);
        [[self scrollView] setContentSize:contentSize];
    }
    
    if ([[self scrollView] contentSize].width < [[self contentView] bounds].size.width) {
        CGSize contentSize = CGSizeMake([[self contentView] bounds].size.width, [[self scrollView] contentSize].height);
        [[self scrollView] setContentSize:contentSize];
    }
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    BOOL shouldPerformSegueWithIdentifier = YES;
    if ([identifier isEqualToString:MNSSegueShowSql]) {
        if ([UIDevice isPad] && [self showSqlIsVisable]) {
            shouldPerformSegueWithIdentifier = NO;
            [[self showSqlPopoverController] dismissPopoverAnimated:YES];
            [self setShowSqlIsVisable:NO];
        }
    }
    return shouldPerformSegueWithIdentifier;
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:MNSSegueShowSql]) {
        MTViewController *viewController;
        if ([UIDevice isPad]) {
            [self setShowSqlIsVisable:YES];
            UIPopoverController *popoverController = [[(UIStoryboardPopoverSegue *)segue popoverController] retain];
            [popoverController setDelegate:self];
            [self setShowSqlPopoverController:popoverController];
            [popoverController release];
            [[segue destinationViewController] setDelegate: self];
        } else {
            [[segue destinationViewController] setDelegate: self];
        }
        
        if ([[segue destinationViewController] isKindOfClass:[UINavigationController class]]) {
            viewController = (MTViewController *)[[segue destinationViewController] topViewController];
        } else {
            viewController = [segue destinationViewController];
        }
        [viewController setDelegate:self];
    }
    
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    for (UIViewController *subviewController in [self childViewControllers]) {
        [self didMoveFieldRect:subviewController animated:YES];
    }
    
    [[self collisionBehavior] removeBoundaryWithIdentifier:MTIdentifierCollisionBoundryBottom];
    [[self collisionBehavior] removeBoundaryWithIdentifier:MTIdentifierCollisionBoundryTop];
    [[self collisionBehavior] removeBoundaryWithIdentifier:MTIdentifierCollisionBoundryLeft];
    [[self collisionBehavior] removeBoundaryWithIdentifier:MTIdentifierCollisionBoundryRight];
    
    CGPoint fromPoint = [self contentView].frame.origin;
    CGPoint toPoint = CGPointMake([self contentView].frame.origin.x + [self contentView].frame.size.width, [self contentView].frame.origin.y);
    [[self collisionBehavior] addBoundaryWithIdentifier:MTIdentifierCollisionBoundryTop fromPoint:fromPoint toPoint:toPoint];
    
    fromPoint = toPoint;
    toPoint = CGPointMake(toPoint.x, [self contentView].frame.origin.y + self.contentView.frame.size.height);
    [[self collisionBehavior] addBoundaryWithIdentifier:MTIdentifierCollisionBoundryRight fromPoint:fromPoint toPoint:toPoint];
    
    fromPoint = toPoint;
    toPoint = CGPointMake([self contentView].frame.origin.x, toPoint.y);
    [[self collisionBehavior] addBoundaryWithIdentifier:MTIdentifierCollisionBoundryBottom fromPoint:fromPoint toPoint:toPoint];
    
    fromPoint = toPoint;
    toPoint = [self contentView].frame.origin;
    [[self collisionBehavior] addBoundaryWithIdentifier:MTIdentifierCollisionBoundryLeft fromPoint:fromPoint toPoint:toPoint];
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self setShowSqlIsVisable:NO];
}

#pragma mark - Setup Notifications

+ (void)removeNotificationsFromObserver:(id<MTQueryBuilderAdvancedSchemaDelegate>)observer forObjectContext:(NSManagedObjectContext *)objectContext {
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    [defaultCenter removeObserver:observer name:NSManagedObjectContextWillSaveNotification object:objectContext];
    [defaultCenter removeObserver:observer name:NSManagedObjectContextDidSaveNotification object:objectContext];
    
}

+ (void)addNotificationsToObserver:(id<MTQueryBuilderAdvancedSchemaDelegate>)observer forObjectContext:(NSManagedObjectContext *)objectContext {
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    [MTQueryBuilderAdvancedViewController removeNotificationsFromObserver:observer forObjectContext:objectContext];
    
    [defaultCenter addObserver:observer selector:@selector(managedObjectContextWillSave:) name:NSManagedObjectContextWillSaveNotification object:objectContext];
    [defaultCenter addObserver:observer selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:objectContext];
    
}

#pragma mark - NSManagedObjectContext observer

- (void)managedObjectContextWillSave:(NSNotification *)notification {

}

- (void)managedObjectContextDidSave:(NSNotification *)notification {
    
    NSArray *insertedObjects = [[[notification userInfo] objectForKey: NSInsertedObjectsKey] retain];
    NSArray *updatedObjects = [[[notification userInfo] objectForKey: NSUpdatedObjectsKey] retain];
    NSArray *deletedObjects = [[[notification userInfo] objectForKey: NSDeletedObjectsKey] retain];

    RptqQuery *updatedQuery = nil;
    RptqQueryTable *updatedTable = nil;

#pragma mark Handle inserted objects
    
    for (id insertedObject in insertedObjects) {

        if ([insertedObject isKindOfClass:[RptqQueryLinks class]]) {
            
            //User adding a link starting point...
            RptqQueryLinks *insertedQueryLinks = [insertedObject retain];
            [self insertQueryLink:insertedQueryLinks];
            [insertedQueryLinks release];
            
            
        } else if ([insertedObject isKindOfClass:[RptqQueryTable class]]) {

            //User adding a table starting point...
            RptqQueryTable *insertedQueryTable = [insertedObject retain];
            [self insertQueryTable:insertedQueryTable];
            [insertedQueryTable release];

        }
    }
    
    for (id updatedObject in updatedObjects) {
        //NSLog(@"Updated %@", updatedObject);
        //NSLog(@"Changed values %@", [updatedObject changedValues]);
        //NSLog(@"Committed values %@", [updatedObject committedValuesForKeys:@[@"inQuery", @"hasTables"]]);
        if ([updatedObject isKindOfClass:[RptqQueryTable class]]) {
            updatedTable = [updatedObject retain];
        } else if ([updatedObject isKindOfClass:[RptqQuery class]]) {
            updatedQuery = [updatedObject retain];
        }
    }
    
    if (updatedQuery && updatedTable) {
        if ([[updatedTable inQuery] isEqualTo:updatedQuery]) {
            // FIXME: Allow user to edit table.
        } else {

            UIViewController *viewController = [[[self controllersForObjectIds] objectForKey:[updatedTable objectID]] retain];
            
            if ([viewController isKindOfClass:[MTQueryBuilderAdvancedSchemaViewController class]]) {

                [[self tableStartingPoints] removeObject:updatedTable];
                
                // Reposition existing tables
                CGFloat segHeight = (self.contentView.bounds.size.height / ([[self tableStartingPoints] count] + 1));
                NSUInteger counter = 0;
                for (RptqQueryTable *queryTable in [self tableStartingPoints]) {
                    CGFloat attachmentPointY = segHeight * (counter + 1);
                    CGPoint attachmentPoint = CGPointMake(CGPointZero.x, attachmentPointY - 22.0000f);
                    UIAttachmentBehavior *attachmentBehavior = [[self attachmentBehaviors] objectForKey:[queryTable objectID]];
                    [attachmentBehavior setAnchorPoint:attachmentPoint];
                    counter++;
                }
                
                // FIXME: Maybe block this and move it off screen.
                //UIAttachmentBehavior *attachmentBehaviorForObjectId = [[[self attachmentBehaviors] objectForKey:[[viewController view] objectIdTag]] retain];
                //[attachmentBehaviorForObjectId release];
                UIAttachmentBehavior *attachmentBehavior = [[self attachmentBehaviors] objectForKey:[updatedTable objectID]];
                [[self dynamicAnimator] removeBehavior:attachmentBehavior];
                [[self gravityBeahvior] removeItem:(MTQueryBuilderAdvancedSchemaViewController *)viewController];
                [[self collisionBehavior] removeItem:(MTQueryBuilderAdvancedSchemaViewController *)viewController];
                [[self dynamicItemBehavior] removeItem:(MTQueryBuilderAdvancedSchemaViewController *)viewController];
                [[self attachmentBehaviors] removeObjectForKey:[updatedTable objectID]];
                
                // FIXME: do give time for animations... Can't imagine this will work.
                [viewController willMoveToParentViewController:nil];
                [[viewController view] removeFromSuperview];
                [viewController removeFromParentViewController];
                
                for (RptqQueryLinks *link in [updatedQuery hasQueryLinks]) {
                    RptqQueryField *leftField = [link hasLeftField];
                    RptqQueryField *rightField = [link hasRightField];
                    RptqQueryTable *leftTable = [leftField inQueryTable];
                    RptqQueryTable *rightTable = [rightField inQueryTable];
                    if ([leftTable objectID] == [updatedTable objectID] ||
                        [rightTable objectID] == [updatedTable objectID]) {
                        
                        UIViewController *linkViewController = [[[self controllersForObjectIdsLink] objectForKey: [link objectID]] retain];
                        if (linkViewController != nil) {
                            [self removeViewController:linkViewController];
                        }
                        [linkViewController release];
                        //Delete the query link view controller here, because it's bogus
                        
                    }
                }
                
                //loop though each link here, and do as above if the link contains the table... but will it be there?... check the updated query

            } else if ([[viewController view] isKindOfClass:[MTConnectorView class]]) {
                
                UIViewController *viewController = [[[self controllersForObjectIds] objectForKey:[updatedTable objectID]] retain];
                CGAffineTransform swingTransform = CGAffineTransformSwing();
                CGPoint center = [viewController view].center;
                CGFloat animationDuration = 0.3000f;
                [UIView animateWithDuration:animationDuration delay:0.0000f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    [[viewController view] setBounds:CGRectZero];
                    [[viewController view] setCenter:center];
                    [[viewController view] setTransform:swingTransform];
                } completion:^(BOOL finished) {
                    [viewController willMoveToParentViewController:nil];
                    [[viewController view] removeFromSuperview];
                    [viewController removeFromParentViewController];
                }];
            }
            
            [viewController release];
        }
    }

#pragma mark Handle deleted objects

    for (id deletedObject in deletedObjects) {
        
        if ([deletedObject isKindOfClass:[RptqQueryTable class]]) {
            
            RptqQueryTable *deletedTable = [deletedObject retain];
            [self deleteQueryTable:deletedTable];
            [deletedTable release];
                        
        } else if ([deletedObject isKindOfClass:[RptqQueryLinks class]]) {
            
            RptqQueryLinks *deletedLink = [deletedObject retain];
            [self deleteQueryLink:deletedLink];
            [deletedLink release];
            
        }
    }

    [deletedObjects release];
    [insertedObjects release];
    [updatedObjects release];
    [updatedTable release];
    [updatedQuery release];

}

#pragma mark View Controller Container Custom Handlers

- (void)viewControllerDidFinish:(id)sender {
    if ([UIDevice isPad] && [self showSqlIsVisable]) {
        [[self showSqlPopoverController] dismissPopoverAnimated:YES];
        [self setShowSqlIsVisable:NO];
    } else {
        [self dismissViewControllerAnimated:YES completion:^{ }];
    }
}

#pragma mark - Gesture recognizer actions

- (void)tapPiece:(UITapGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer state] == UIGestureRecognizerStateEnded) {
        UIView *gestureRecognizerView = [gestureRecognizer view];
        [[self contentView] bringSubviewToFront:gestureRecognizerView];
        for (UIView *view in [[self contentView] subviews]) {
            if ([view isKindOfClass:[MTConnectorView class]]) {
                [[self contentView] bringSubviewToFront:view];
            }
        }
    }
}

- (void)panPiece:(UIPanGestureRecognizer *)gestureRecognizer {
    UIWindow *window = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
    CGPoint gestureLocation = [gestureRecognizer locationInView:window];
    NSManagedObjectID *tableId = [[gestureRecognizer view] objectIdTag];

    MTQueryBuilderAdvancedSchemaViewController *viewController = [[self controllersForObjectIds] objectForKey:tableId];
    
    CGPoint location = [window convertPoint:gestureLocation toView:[self contentView]];
    
    CGPoint newOrigin = location; // [gestureRecognizer locationInView:[self contentView]];
    UIAttachmentBehavior *attachmentBehavior = [[self attachmentBehaviors] objectForKey:tableId];
    
    MTApplicaitonInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    RptqQueryTable *table = (RptqQueryTable *)[[reportDocument managedObjectContext] objectWithID:tableId];
    if ([[self tableStartingPoints] containsObject:table]) {
        [attachmentBehavior setAnchorPoint:newOrigin];
    }
    [[viewController view] setCenter:newOrigin];

        switch ([gestureRecognizer state]) {
                
            case UIGestureRecognizerStateBegan: {   // MARK: UIPanGestureRecognizer UIGestureRecognizerStateBegan
                [[self dynamicAnimator] updateItemUsingCurrentState:viewController];
            }
            case UIGestureRecognizerStateChanged: {     // MARK: UIPanGestureRecognizer UIGestureRecognizerStateChanged
                [[self dynamicAnimator] updateItemUsingCurrentState:viewController];
                break;
            }
            case UIGestureRecognizerStatePossible:      // MARK: UIPanGestureRecognizer UIGestureRecognizerStatePossible
                break;
            case UIGestureRecognizerStateCancelled:     // MARK: UIPanGestureRecognizer UIGestureRecognizerStateCancelled
            case UIGestureRecognizerStateFailed:        // MARK: UIPanGestureRecognizer UIGestureRecognizerStateFailed
            case UIGestureRecognizerStateEnded: {       // MARK: UIPanGestureRecognizer UIGestureRecognizerStateEnded
                [[self dynamicAnimator] updateItemUsingCurrentState:viewController];
                break;
            }
            default:
                break;
        }
}

- (void)pushPiece:(UIPanGestureRecognizer *)gestureRecognizer {

    UIPushBehavior *pushBehavior = [[self pushBehaviorForItem:[gestureRecognizer view]] retain];
    NSLog(@"Push Behavior %@", pushBehavior);
    [pushBehavior setActive:YES];
    
    // If we're starting the gesture then create a drag force
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) { }
    
    // Set the force to be proportional to distance the gesture has moved
    CGPoint velocity = [gestureRecognizer velocityInView:[self contentView]];
    pushBehavior.pushDirection = CGVectorMake(velocity.x/100, velocity.y/100);
    
    // If we're finishing then cancel the behavior to 'let-go' of the ball
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) { }
    
    [pushBehavior release];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView { }

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self resizeScrollViewContentArea];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView { }

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
    [self resizeScrollViewContentArea];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView { }

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView { }

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
    return [[[self contentView] retain] autorelease];
}

#pragma mark - UICollisionBehaviorDelegate

- (void)collisionBehavior:(UICollisionBehavior *)behavior endedContactForItem:(id<UIDynamicItem>)item withBoundaryIdentifier:(id<NSCopying>)identifier {

}

#pragma mark - MTQueryBuilderAdvancedSchemaViewControllerDelegate

- (void)didMoveFieldRect:(id)sender animated:(BOOL)animated {
    if ([sender isKindOfClass:[MTQueryBuilderAdvancedSchemaViewController class]]) {
        MTQueryBuilderAdvancedSchemaViewController *controller = (MTQueryBuilderAdvancedSchemaViewController *)sender;
        MTApplicaitonInstance *applicationInstance = [AppDelegate applicationInstance];
        MAReportDocument *reportDocument = [applicationInstance activeDocument];
        RptqQueryTable *queryTable = [RptqQueryTable getQueryTableForObjectID:[controller tableObjectId] fromObjectContext:[reportDocument managedObjectContext]];
        for (RptqQueryLinks *queryLink in [[queryTable inQuery] hasQueryLinks]) {
            RptqQueryTable *leftTable = [[queryLink hasLeftField] inQueryTable];
            RptqQueryTable *rightTable = [[queryLink hasRightField] inQueryTable];
            if ([leftTable isEqualTo:queryTable] ||
                [rightTable isEqualTo:queryTable]) {
                [self layoutQueryLinkViewController:queryLink animated:animated];
            }
        }
    }
}
    
#pragma mark - Change UI on IR Diagram

- (void)clearScreen {
    
    for (UIViewController *viewController in [self viewControllers]) {
        Class schemaTableClass = [MTQueryBuilderAdvancedSchemaViewController class];
        if ([viewController isKindOfClass:schemaTableClass]) {
            UIAttachmentBehavior *attachmentBehaviorForObjectId = [[[self attachmentBehaviors] objectForKey:[[viewController view] objectIdTag]] retain];
            [[self dynamicAnimator] removeBehavior:attachmentBehaviorForObjectId];
            [attachmentBehaviorForObjectId release];
            [[self attachmentBehaviors] removeObjectForKey:[[viewController view] objectIdTag]];
            MTQueryBuilderAdvancedSchemaViewController *controller = (MTQueryBuilderAdvancedSchemaViewController *)viewController;
            [[self collisionBehavior] removeItem:controller];
            [[self gravityBeahvior] removeItem:controller];
        }
    }
    [self removeViewControllers:[NSSet setWithArray:[self viewControllers]]];
    
    [self setTableDisplayCounter:0];
    
}

- (MTLinkedList *)tableObjectIDsSortedTopologicallyForQuery:(RptqQuery *)query {

    MTGraph *graph = [[MTGraph alloc] init];
    NSSet *hasTables = [query hasQueryTables];
    
    //Add a vertex to the graph for each table.
    for (RptqDatabaseSchemaTable *table in hasTables) {
        [graph addVertexWithObject:[table objectID]];
    }
    
    //Create an edge in the graph for each query link.
    NSSet *hasQueryLinks = [[query hasQueryLinks] retain];
    for (RptqQueryLinks *queryLink in hasQueryLinks) {
        
        RptqQueryTable *tableOrigin =        [[queryLink  hasLeftField] inQueryTable];
        RptqQueryTable *tableDestination =   [[queryLink hasRightField] inQueryTable];
        
        id objectOrigin =               [tableOrigin objectID];
        id objectDestination =          [tableDestination objectID];
        id objectQueryLink =            [queryLink objectID];
        
        MTVertex *vertexOrigin =        [[graph vertexForObject:objectOrigin] retain];
        MTVertex *vertexDestination =   [[graph vertexForObject:objectDestination] retain];
        
        NSNumber *weight = @(1);
        [graph addEdgeWithOrigin:vertexOrigin destination:vertexDestination object:objectQueryLink andWeight:weight];
        
        [vertexOrigin release];
        [vertexDestination release];
    }
    
    NSError *error = nil;
    MTLinkedList *tableIds = [[graph topologicalSortWithError:&error] retain];
    
    [hasQueryLinks release];
    [graph release];
    return [tableIds autorelease];

}

#pragma mark Reload document view controllers

- (void)redraw {
    MTApplicaitonInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    [self reloadDocument:reportDocument animated:YES];
}

- (void)reloadDocument:(MAReportDocument *)documentReport animated:(BOOL)animated {
    
    MTApplicaitonInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    if (reportDocument) {

        NSManagedObjectContext *objectContext = [[reportDocument managedObjectContext] retain];
        [MTQueryBuilderAdvancedViewController addNotificationsToObserver:self forObjectContext:objectContext];
        
        [self clearScreen];
        
        [[self tableStartingPoints] removeAllObjects];
        [[self pushBehaviors] removeAllObjects];
        [[self viewControllers] removeAllObjects];  //May track child view controllers since iOS 7.
        [[self tableIds] removeAllObjects];
        [[self controllersForObjectIds] removeAllObjects];     //Tables and links
        [[self controllersForObjectIdsLink] removeAllObjects];
        
        RptqDocument *document = [reportDocument activeDocument];
        
        RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
        RptqQuery *query = [[database hasQueries] anyObject];
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
            
            MTApplicaitonInstance *applicationInstance = [AppDelegate applicationInstance];
            MAReportDocument *reportDocument = [applicationInstance activeDocument];

            RptqQueryTable *table = (RptqQueryTable *)[[reportDocument managedObjectContext] objectWithID:objectId];
            
            //Is the table joined to another table from the left?
            BOOL topLevel = YES;
            
            for (RptqQueryLinks *link in [query hasQueryLinks]) {
                NSLog(@"%@", link);
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
            
            [layoutDetails setObject:layout forKey:[tableIdVertext object]];
            
            if (topLevel) {
                numberOfStartingPoints++;
            }
        }
    }
    
    NSInteger tableCounter = 0;
    NSInteger topLevelTableCounter = 0;
    CGFloat segHeight = (self.contentView.bounds.size.height / (numberOfStartingPoints + 1));

    MTApplicaitonInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    // Display tables
    for (MTPair *pair in tableIds) {
        
        MTVertex *tableIdVertext = [pair former];
        NSManagedObjectID *objectId = [tableIdVertext object];

        if (objectId != nil) {
            
            RptqQueryTable *table = (RptqQueryTable *)[[reportDocument managedObjectContext] objectWithID:objectId];
            
            NSDictionary *layout = [layoutDetails objectForKey:[tableIdVertext object]];
            BOOL topLevel = [[layout objectForKey:MTKeyIsTopLevel] boolValue];
            
            MTQueryBuilderAdvancedSchemaViewController *viewController = [[self addSchemaViewControllerForTable:table animated:animated] retain];
            
            if (animated) {
                
                NSManagedObjectID *objectIDView = [[[viewController view] objectIdTag] retain];
                if (topLevel) {
                    
                    CGFloat attachmentPointY = segHeight * (topLevelTableCounter + 1);
                    
                    CGPoint attachmentPoint = CGPointMake(CGPointZero.x, attachmentPointY);
                    UIAttachmentBehavior *attachmentBehavior = [[MTQueryBuilderAdvancedViewController attachmentBehaviorAnchorWithItem:viewController attachedToPoint:attachmentPoint] retain];
                    [[self dynamicAnimator] addBehavior:attachmentBehavior];
                    [[self attachmentBehaviors] setObject:attachmentBehavior forKey:objectIDView];
                    [[self tableStartingPoints] addObject:table];
                    [attachmentBehavior release];
                    topLevelTableCounter++;
                    
                } else {
                    
                    for (RptqQueryLinks *link in [query hasQueryLinks]) {
                        RptqQueryField *rightField = [link hasRightField];
                        RptqQueryTable *rightTable = [rightField inQueryTable];
                        RptqQueryField *leftField = [link hasLeftField];
                        RptqQueryTable *leftTable = [leftField inQueryTable];
                        if ([rightTable objectID] == [table objectID]) {
                            
                            MTQueryBuilderAdvancedSchemaViewController *leftTableViewController = [[[self controllersForObjectIds] objectForKey:[leftTable objectID]] retain];
                            NSManagedObjectID *objectIDLink = [[link objectID] retain];
                            
                            UIAttachmentBehavior *attachmentBehaviorLeft = [[MTQueryBuilderAdvancedViewController attachmentBehaviorLinkWithLeftViewController:leftTableViewController andRightViewController:viewController] retain];
                            [[self dynamicAnimator] addBehavior:attachmentBehaviorLeft];
                            [[self attachmentBehaviors] setObject:attachmentBehaviorLeft forKey:objectIDLink];
                            [leftTableViewController release];
                            [objectIDLink release];
                            [attachmentBehaviorLeft release];
                            
                        }
                    }
                    
                }
                
                

                [objectIDView release];
                
                tableCounter++;
            }
            
            self.tableDisplayCounter++;
            
            [viewController autorelease];
            
        }
    }
    
    // Display links
    for (RptqQueryLinks *queryLink in [query hasQueryLinks]) {
        [self addLinkViewControllerForQueryLink:queryLink animated:YES];
    }
    
    [layoutDetails release];
}

- (void)deleteQueryTable:(RptqQueryTable *)deletedQueryTable {

    NSManagedObjectID *objectId = [deletedQueryTable objectID];
    
    //If top level table, then move it off screen, and move the others in place.
    
    BOOL startingPointTable = [[self tableStartingPoints] containsObject:objectId];
    if (startingPointTable) {
        CGPoint offScreen = CGPointMakeRandomOffscreen();
        UIAttachmentBehavior *attachmentBehavior = [[self attachmentBehaviors] objectForKey:objectId];
        [attachmentBehavior setAnchorPoint:offScreen];
    }
    
    // FIXME:
    
    
    if ([deletedQueryTable inQuery] != nil &&
        [[self tableIds] containsObject: objectId]) {
        
        MTQueryBuilderAdvancedSchemaViewController *viewController = [[[self controllersForObjectIds] objectForKey:objectId] retain];
        
        UIAttachmentBehavior *attachmentBehaviorForObjectId = [[[self attachmentBehaviors] objectForKey:[[viewController view] objectIdTag]] retain];

        [attachmentBehaviorForObjectId release];
        
        // FIXME: do give time for animations... Can't imagine this will work.
        [viewController willMoveToParentViewController:nil];
        [[viewController view] removeFromSuperview];
        [viewController removeFromParentViewController];
        
        [viewController release];
    }
}

- (void)deleteQueryLink:(RptqQueryLinks *)deletedQueryLinks {

    MTApplicaitonInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
    NSMutableSet *orphanedQueryTables = [[NSMutableSet alloc] init];
    
    RptqDocument *document = [reportDocument activeDocument];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    
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
    
    NSSet *startingPoints = [NSSet setWithArray:[self tableStartingPoints]];
    [orphanedQueryTables minusSet:startingPoints];  // Should only be one newly orphaned table.
    
    NSManagedObjectID *deletedLinkObjectId = [deletedQueryLinks objectID];
    RptqQueryLinks *deletedLink = (RptqQueryLinks *)[managedObjectContext objectWithID:deletedLinkObjectId];
    UIAttachmentBehavior *attachmentBehavior = [[self attachmentBehaviors] objectForKey:deletedLinkObjectId];
    
    for (RptqQueryTable *table in orphanedQueryTables) {
        
        RptqQueryTable *tableRightDeletedLink = table;
        MTQueryBuilderAdvancedSchemaViewController *viewController = [[self controllersForObjectIds] objectForKey:[tableRightDeletedLink objectID]];
        
        // Is there a link still pointing to the view controller after the delete, or
        //   do we need to make it top level?
        
        CGFloat x = CGPointZero.x + [[self contentView] frame].size.width;
        CGFloat y = CGPointZero.y + [[self contentView] frame].size.height / 2.0000f;
        CGPoint attachmentPoint = CGPointMake(x, y);
 
        UIAttachmentBehavior *anchorBehaviorNew = [[MTQueryBuilderAdvancedViewController attachmentBehaviorAnchorWithItem:viewController attachedToPoint:attachmentPoint] retain];
        [[self dynamicAnimator] addBehavior:anchorBehaviorNew];
        [[self attachmentBehaviors] setObject:anchorBehaviorNew forKey: [tableRightDeletedLink objectID]];
        [[self tableStartingPoints] addObject: tableRightDeletedLink];
        
        // Disable collision behaviors before reposition
        // Reposition existing tables
        CGFloat segHeight = (self.contentView.bounds.size.height / ([[self tableStartingPoints] count] + 1));
        NSUInteger counter = 0;
        for (RptqQueryTable *queryTable in [self tableStartingPoints]) {
            CGFloat attachmentPointY = segHeight * (counter + 1);
            CGPoint attachmentPoint = CGPointMake(CGPointZero.x, attachmentPointY - 22.0000f);
            UIAttachmentBehavior *attachmentBehavior = [[self attachmentBehaviors] objectForKey:[queryTable objectID]];
            [attachmentBehavior setAnchorPoint:attachmentPoint];
            counter++;
        }
        
        [tableRightDeletedLink release];
        [anchorBehaviorNew release];
        // Enable collision behaviors before reposition
        
    }
    
    [[self dynamicAnimator] removeBehavior:attachmentBehavior];
    [[self attachmentBehaviors] removeObjectForKey:deletedLinkObjectId];
    
    UIViewController *linkViewController = [[[self controllersForObjectIdsLink] objectForKey: [deletedLink objectID]] retain];
    if (linkViewController != nil) {
        [self removeViewController:linkViewController];
    }
    [linkViewController release];
    
    [orphanedQueryTables release];

}

- (void)insertQueryTable:(RptqQueryTable *)insertedQueryTable {
    
    CGFloat segHeight = (self.contentView.bounds.size.height / ([[self tableStartingPoints] count] + 2));
    
    // Reposition existing tables
    // FIXME: Good place for block iterate?
    NSUInteger counter = 0;
    for (RptqQueryTable *queryTable in [self tableStartingPoints]) {
        CGFloat attachmentPointY = segHeight * (counter + 1);
        CGPoint attachmentPoint = CGPointMake(CGPointZero.x, attachmentPointY - 22.0000f);
        UIAttachmentBehavior *attachmentBehavior = [[self attachmentBehaviors] objectForKey:[queryTable objectID]];
        [attachmentBehavior setAnchorPoint:attachmentPoint];
        counter++;
    }
    
    CGFloat attachmentPointY = segHeight * ([[self tableStartingPoints] count] + 1);
    CGPoint insertTableAnchorPoint = CGPointMake(CGPointZero.x, attachmentPointY - 22.0000f);
    
    // Insert new and unlinked query table
    
    //Going to assume that it's a top level table.
    [[self tableStartingPoints] addObject:insertedQueryTable];
    
    // Insert table
    MTQueryBuilderAdvancedSchemaViewController *viewController = [[self addSchemaViewControllerForTable:insertedQueryTable animated:YES] retain];

    NSManagedObjectID *objectIDView = [[[viewController view] objectIdTag] retain];
    UIAttachmentBehavior *attachmentBehavior = [[MTQueryBuilderAdvancedViewController attachmentBehaviorAnchorWithItem:viewController attachedToPoint:insertTableAnchorPoint] retain];

    [[self dynamicAnimator] addBehavior:attachmentBehavior];
    [[self attachmentBehaviors] setObject:attachmentBehavior forKey:objectIDView];
    
    self.tableDisplayCounter++;
    
    [attachmentBehavior release];
    [objectIDView release];
    [viewController autorelease];
}

- (void)insertQueryLink:(RptqQueryLinks *)insertedQueryLinks {

    RptqQuery *query = [insertedQueryLinks inQuery];
 
    RptqQueryField *leftField = [insertedQueryLinks hasLeftField];
    RptqQueryTable *leftTable = [leftField inQueryTable];
    MTQueryBuilderAdvancedSchemaViewController *leftTableViewController = [[[self controllersForObjectIds] objectForKey:[leftTable objectID]] retain];
    
    RptqQueryField *rightField = [insertedQueryLinks hasRightField];
    RptqQueryTable *rightTable = [rightField inQueryTable];
    MTQueryBuilderAdvancedSchemaViewController *rightTableViewController = [[[self controllersForObjectIds] objectForKey:[rightTable objectID]] retain];
    
    MTLinkedList *tableIds = [self tableObjectIDsSortedTopologicallyForQuery:query];
    
    NSInteger numberOfStartingPoints = 0;
    
    NSMutableDictionary *layoutDetails = [[NSMutableDictionary alloc] initWithCapacity:[tableIds count]];
    
    for (MTPair *pair in tableIds) {
        MTVertex *tableIdVertext = [pair former];
        NSManagedObjectID *objectId = [tableIdVertext object];
        if (objectId != nil) {
            
            MTApplicaitonInstance *applicationInstance = [AppDelegate applicationInstance];
            MAReportDocument *reportDocument = [applicationInstance activeDocument];

            RptqQueryTable *table = (RptqQueryTable *)[[reportDocument managedObjectContext] objectWithID:objectId];
            
            //Is the table joined to another table from the left?
            BOOL topLevel = YES;
            
            for (RptqQueryLinks *link in [query hasQueryLinks]) {
                NSLog(@"%@", link);
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
            
            [layoutDetails setObject:layout forKey:[table objectID]];
            
            if (topLevel) {
                numberOfStartingPoints++;
            }
        }
    }
    
    // Remove starting point connection if one of the tables is in the link.
    BOOL startingPointRemoved = NO;
    RptqQueryTable *queryTableRemoved = nil;
    NSUInteger startingPointsRemovedCounter = 0;
    for (RptqQueryTable *queryTable in [self tableStartingPoints]) {

        RptqQueryTable *removeableTable = nil;

        NSDictionary *layout = [layoutDetails objectForKey:[queryTable objectID]];
        NSNumber *isTopLevel = [layout objectForKey:MTKeyIsTopLevel];
        if ([isTopLevel boolValue] == NO) {
            if ([[leftTable objectID] isEqual:[queryTable objectID]]) {
                removeableTable = queryTable;
            } else if ([[rightTable objectID] isEqual:[queryTable objectID]]) {
                removeableTable = queryTable;
            }
        }
        if (removeableTable) {
            queryTableRemoved = [[queryTable retain] autorelease];
            UIAttachmentBehavior *attachmentBehavior = [[[self attachmentBehaviors] objectForKey:[removeableTable objectID]] retain];
            [[self dynamicAnimator] removeBehavior:attachmentBehavior];
            [attachmentBehavior release];
            [[self attachmentBehaviors] removeObjectForKey:[removeableTable objectID]];
            startingPointRemoved = YES;
            startingPointsRemovedCounter++;
            if (startingPointsRemovedCounter == 2) {
                break;
            }
        }
    }
    
    [layoutDetails release];
    
    // Reposition existing starting point-tables
    if (startingPointRemoved) {
        [[self tableStartingPoints] removeObject:queryTableRemoved];
        
        CGFloat segHeight = (self.contentView.bounds.size.height / ([[self tableStartingPoints] count] + 2));
        NSUInteger counter = 0;
        for (RptqQueryTable *queryTable in [self tableStartingPoints]) {
            CGFloat attachmentPointY = segHeight * (counter + 1);
            CGPoint attachmentPoint = CGPointMake(CGPointZero.x, attachmentPointY - 22.0000f);
            UIAttachmentBehavior *attachmentBehavior = [[self attachmentBehaviors] objectForKey:[queryTable objectID]];
            [attachmentBehavior setAnchorPoint:attachmentPoint];
            counter++;
        }
    }
    
    //Add connections between MTQueryBuilderAdvancedSchemaViewController
    UIAttachmentBehavior *attachmentBehavior = [[MTQueryBuilderAdvancedViewController attachmentBehaviorLinkWithLeftViewController:leftTableViewController andRightViewController:rightTableViewController] retain];
    [[self dynamicAnimator] addBehavior:attachmentBehavior];
    [[self attachmentBehaviors] setObject:attachmentBehavior forKey:[insertedQueryLinks objectID]];
    [attachmentBehavior release];
    
    [leftTableViewController release]; [rightTableViewController release];
    
    //Add animation layer
    [self addLinkViewControllerForQueryLink: insertedQueryLinks animated:YES];
}

#pragma mark - UI Items

+ (UIAttachmentBehavior *)attachmentBehaviorAnchorWithItem:(id<UIDynamicItem>)item attachedToPoint:(CGPoint)anchorPoint {
    CGPoint attachmentPoint = CGPointMake(CGPointZero.x, anchorPoint.y - 22.0000f);
    UIAttachmentBehavior *behavior = [[UIAttachmentBehavior alloc] initWithItem:item attachedToAnchor:attachmentPoint];
    [behavior setLength:100.0000f];
    return [behavior autorelease];

}

+ (UIAttachmentBehavior *)attachmentBehaviorLinkWithLeftViewController:(MTQueryBuilderAdvancedSchemaViewController *)viewControllerLeft andRightViewController:(MTQueryBuilderAdvancedSchemaViewController *)viewControllerRight {
    
    // FIXME: Make sure they are not the same, or crash, lolz

    UIAttachmentBehavior *behavior = [[UIAttachmentBehavior alloc] initWithItem:viewControllerRight attachedToItem:viewControllerLeft];
    [behavior setFrequency:1.0000f];
    [behavior setDamping:0.9000f];
    [behavior setLength:166.0000f];
    return [behavior autorelease];
}

//Pass the view controller to create an push behavior... can be recovered with multiple types
- (UIPushBehavior *)pushBehaviorForItem:(id<UIDynamicItem>)item {
    UIPushBehavior *pushBehavior = nil;
    if ([item isKindOfClass:[UIViewController class]]) {
        
         //Creating it
        NSManagedObjectID *objectId = [[(UIViewController *)item view] objectIdTag];
        UIPushBehavior *behavior = [[[self pushBehaviors] objectForKey:objectId] retain];
        if (behavior == nil) {
            pushBehavior = [[UIPushBehavior alloc] initWithItems:@[item] mode:UIPushBehaviorModeInstantaneous];
            [[self dynamicAnimator] addBehavior:pushBehavior];
            [[self pushBehaviors] setObject:pushBehavior forKey:objectId];
        } else {
            pushBehavior = behavior;
        }

    } else if ([item isKindOfClass:[UIView class]]) {
        
        NSManagedObjectID *objectId = [(UIView *)item objectIdTag];
        pushBehavior = [[[self pushBehaviors] objectForKey:objectId] retain];
        
    } else if ([item isKindOfClass:[NSManagedObjectID class]]) {

        pushBehavior = [[[self pushBehaviors] objectForKey:item] retain];
    
    }
    return [pushBehavior autorelease];
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
    [[viewController view] addGestureRecognizer:tapGesture];
    [tapGesture release];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pushPiece:)];
    [panGesture setDelegate:self];
    [[[self scrollView] panGestureRecognizer] requireGestureRecognizerToFail:panGesture];
    [tapGesture requireGestureRecognizerToFail:panGesture];
    [[viewController view] addGestureRecognizer:panGesture];
    [panGesture release];
}

#pragma mark Scroll view helper

- (void)resizeScrollViewContentArea {
    if ([[self scrollView] isZooming] == NO) {
        CGFloat maxX = CGPointZero.x;
        CGFloat maxY = CGPointZero.y;
        
        for (UIViewController *viewController in [self childViewControllers]) {
            Class schemaClass = [MTQueryBuilderAdvancedSchemaViewController class];
            if ([viewController isKindOfClass:schemaClass]) {
                UIView *view = [viewController view];
                CGRect frame = view.frame;//[[self contentView] convertRect:view.frame fromView:view];
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
        CGRect bounds = self.view.bounds;
        maxX = MAX(maxX, bounds.size.width);
        maxY = MAX(maxY, bounds.size.height);
        CGSize contentSize = CGSizeMake(maxX, maxY);
        CGRect frame = CGRectMake(CGPointZero.x, CGPointZero.y, contentSize.width, contentSize.height);
        [[self contentView] setFrame: frame];
        [[self scrollView] setContentSize: contentSize];
    }
}

#pragma mark - View Controller Container Data

- (void)removeViewControllers:(NSSet *)viewControllers {
    for (UIViewController *viewController in viewControllers) {
        [self removeViewController:viewController];
        
        Class schemaTableClass = [MTQueryBuilderAdvancedSchemaViewController class];
        if ([viewController isKindOfClass:schemaTableClass]) {
            MTQueryBuilderAdvancedSchemaViewController *controller = (MTQueryBuilderAdvancedSchemaViewController *)viewController;
            UIAttachmentBehavior *attachmentBehaviorForObjectId = [[[self attachmentBehaviors] objectForKey:[[viewController view] objectIdTag]] retain];
            [[self dynamicAnimator] removeBehavior:attachmentBehaviorForObjectId];
            [attachmentBehaviorForObjectId release];
            [[self attachmentBehaviors] removeObjectForKey:[[viewController view] objectIdTag]];
            [[self collisionBehavior] removeItem:controller];
            [[self gravityBeahvior] removeItem:controller];
        }
    }
}

- (void)removeViewController:(UIViewController *)viewController {
    CGFloat animationDuration = 0.3000f;
    CGAffineTransform swingTransform = CGAffineTransformSwing();
    
    if ([viewController isKindOfClass:[MTQueryBuilderAdvancedSchemaViewController class]]) {
        
        UIAttachmentBehavior *attachmentBehaviorForObjectId = [[[self attachmentBehaviors] objectForKey:[[viewController view] objectIdTag]] retain];
        [attachmentBehaviorForObjectId release];
        
        // FIXME: do give time for animations... Can't imagine this will work.
        [viewController willMoveToParentViewController:nil];
        [[viewController view] removeFromSuperview];
        [viewController removeFromParentViewController];
        
    } else if ([[viewController view] isKindOfClass:[MTConnectorView class]]) {
        
        CGPoint center = [viewController view].center;
        [UIView animateWithDuration:animationDuration delay:0.0000f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [[viewController view] setBounds:CGRectZero];
            [[viewController view] setCenter:center];
            [[viewController view] setTransform:swingTransform];
        } completion:^(BOOL finished) {
            [viewController willMoveToParentViewController:nil];
            [[viewController view] removeFromSuperview];
            [viewController removeFromParentViewController];
        }];
    }
}

- (MTQueryBuilderAdvancedSchemaViewController *)addSchemaViewControllerForTable:(RptqQueryTable *)table animated:(BOOL)animated {
    
    UIStoryboard *sb = [[MTApplicaitonInstance storyboard] retain];
    MTQueryBuilderAdvancedSchemaViewController *viewController = [[sb instantiateViewControllerWithIdentifier:MTQueryBuilderAdvancedSchemaViewControllerIdentifier] retain];
    [viewController setDelegate:self];
    [viewController setTableObjectId:[table objectID]];
    
    CGRect subviewRect = CGRectZero;
    
    [[self tableIds] addObject:[table objectID]];
    [[self controllersForObjectIds] setObject:viewController forKey:[table objectID]];
    CGFloat originX = 10.0000f + CGPointZero.x;
    CGFloat originY = CGPointZero.y + [[self scrollView] frame].size.height - 200.0000f - 20.0000f;
    subviewRect = CGRectMake(originX, originY, 180.0000f, 200.0000f);
    [table setDesignerSizeHeight:@(subviewRect.size.height)];
    [table setDesignerSizeWidth:@(subviewRect.size.width)];
    [table setDesignerOriginY:@(subviewRect.origin.x)];
    [table setDesignerOriginX:@(subviewRect.origin.y)];
    [table setDesignerInitalLayout:@(NO)];
    
    MTApplicaitonInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    [[reportDocument managedObjectContext] save:nil];
    
    [[viewController view] setFrame: subviewRect];
    
    [self addGesturesToViewController:viewController];
    
    [viewController retain];

    NSArray *constraints = nil;
    CGRect desiredFrame = CGRectMake(table.designerOriginX.floatValue, table.designerOriginY.floatValue, table.designerSizeWidth.floatValue, table.designerSizeHeight.floatValue);
    CGRect viewControllerBounds = [[self contentView] bounds];
    desiredFrame = [MTQueryBuilderAdvancedViewController rectForDesiredRect:desiredFrame inBounds:viewControllerBounds];
    
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:[viewController view] attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0000f constant:desiredFrame.size.width];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:[viewController view] attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0000f constant:desiredFrame.size.height];
    [width setPriority:1000];
    [height setPriority:1000];
    
    [[viewController view] setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    constraints = @[width, height];
    
    [self addChildViewController:viewController];
    if ([[self viewControllers] containsObject:viewController] == NO) {
        [[self viewControllers] addObject:viewController];
    }
    
    [[self contentView] addSubview:[viewController view]];
    [viewController didMoveToParentViewController:self];
    
    [[self contentView] addConstraints:constraints];
    
    [self pushBehaviorForItem: viewController];
    [[self collisionBehavior] addItem:viewController];
    [[self gravityBeahvior] addItem:viewController];
    [[self dynamicItemBehavior] addItem:viewController];
    
    [sb release];
    
    return [viewController autorelease];
    
}

- (void)addLinkViewControllerForQueryLink:(RptqQueryLinks *)link animated:(BOOL)animated {
    NSManagedObjectID *objectId = [[link objectID] retain];
    MTConnectorView *connectorView = [[MTConnectorView alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, 100.0000f, 100.0000f)];
    [connectorView setUserInteractionEnabled:NO];
    [connectorView setObjectIdTag:objectId];
    
    RptqQueryField *leftField = [link hasLeftField];
    RptqQueryTable *leftTable = [leftField inQueryTable];
    MTQueryBuilderAdvancedSchemaViewController *leftTableViewController = [[[self controllersForObjectIds] objectForKey:[leftTable objectID]] retain];
    UIView *leftTableView = [[leftTableViewController view] retain];
    
    RptqQueryField *rightField = [link hasRightField];
    RptqQueryTable *rightTable = [rightField inQueryTable];
    MTQueryBuilderAdvancedSchemaViewController *rightTableViewController = [[[self controllersForObjectIds] objectForKey:[rightTable objectID]] retain];
    UIView *rightTableView = [[rightTableViewController view] retain];
    
    UIViewController *connectorViewController = [[UIViewController alloc] init];
    [connectorViewController setView:connectorView];
    
    [[self controllersForObjectIds] setObject:connectorViewController forKey:objectId];
    [[self controllersForObjectIdsLink] setObject:connectorViewController forKey:objectId];
    
    if (animated == NO) {
        [self layoutQueryLinkViewController:link animated:animated];
    }
    
    CGRect desiredFrame = [[connectorViewController view] frame];
    CGPoint desiredCenter = [[connectorViewController view] center];
    CGAffineTransform desiredTransform = [[connectorViewController view] transform];
    CGAffineTransform swingTransform = CGAffineTransformIdentity;
    if (animated) {
        swingTransform = CGAffineTransformSwing();
    }
    
    NSArray *constraints = nil;
    NSMutableArray *bufferConstraints = [[NSMutableArray alloc] init];
    
    [[connectorViewController view] setBounds:CGRectZero];
    [[connectorViewController view] setCenter:desiredCenter];
    if (animated) {
        [[connectorViewController view] setTransform:swingTransform];
    }
    
    constraints = @[];
    
    
    [self addChildViewController:connectorViewController];
    if ([[self viewControllers] containsObject:connectorViewController] == NO) {
        [[self viewControllers] addObject:connectorViewController];
    }
    
    [[self contentView] addSubview:[connectorViewController view]];
    [connectorViewController didMoveToParentViewController:self];
    
    [bufferConstraints addObjectsFromArray:constraints];
    [[self contentView] addConstraints:bufferConstraints];
    
    MTBlockResultVoid animateTwo = ^() {
        [[connectorViewController view] setFrame:desiredFrame];
        [[connectorViewController view] setTransform:desiredTransform];
    };
    
    if (animated) {
        
        CGFloat animationDuration = 0.3000f;
        [UIView animateWithDuration:animationDuration
                              delay:0.0000f
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:animateTwo
                         completion:NULL];
    } else {
        animateTwo();
    }
    
    [bufferConstraints release];
    
    if (animated) {
        [self layoutQueryLinkViewController:link animated:animated];
    }
    
    [leftTableView release];
    [leftTableViewController release];
    [rightTableView release];
    [rightTableViewController release];
    [connectorViewController release];
    [connectorView release];
    [objectId release];
}

- (void)layoutQueryLinkViewController:(RptqQueryLinks *)queryLink animated:(BOOL)animated {
    RptqQueryLinks *insertedQueryLinks = [queryLink retain];
    UIViewController *controller = [[[self controllersForObjectIdsLink] objectForKey:[queryLink objectID]] retain];
    MTConnectorView *connectorView = [(MTConnectorView *)[controller view] retain];
    CGFloat paddingLeft = 75.0000f;
    RptqQueryField *leftField = [insertedQueryLinks hasLeftField];
    RptqQueryTable *leftTable = [leftField inQueryTable];
    
    MTQueryBuilderAdvancedSchemaViewController *leftTableViewController = [[[self controllersForObjectIds] objectForKey:[leftTable objectID]] retain];
    
    CGRect leftCellFrameInTable = [leftTableViewController rectForFieldWithObjectId:[leftField objectID] inView:[leftTableViewController view]];
    CGRect leftTableFrame = [[leftTableViewController schemaTableViewController] frame];
    CGFloat leftTableBottomY = leftTableFrame.origin.y + leftTableFrame.size.height;
    if (leftCellFrameInTable.origin.y + leftCellFrameInTable.size.height > leftTableBottomY) {
        leftCellFrameInTable = CGRectMake(leftCellFrameInTable.origin.x, leftTableBottomY - leftCellFrameInTable.size.height, leftCellFrameInTable.size.width, leftCellFrameInTable.size.height);
    } else if (leftCellFrameInTable.origin.y < leftTableFrame.origin.y) {
        leftCellFrameInTable = CGRectMake(leftCellFrameInTable.origin.x, leftTableFrame.origin.y, leftCellFrameInTable.size.width, leftCellFrameInTable.size.height);
    }
    CGRect leftCellFrameInView = [[self contentView] convertRect:leftCellFrameInTable fromView:[leftTableViewController view]];
    CGPoint leftCellCenterPoint = CGCenterOfRect(leftCellFrameInView);
    
    RptqQueryField *rightField = [insertedQueryLinks hasRightField];
    RptqQueryTable *rightTable = [rightField inQueryTable];
    MTQueryBuilderAdvancedSchemaViewController *rightTableViewController = [[[self controllersForObjectIds] objectForKey:[rightTable objectID]] retain];
    
    CGRect rightCellFrameInTable = [rightTableViewController rectForFieldWithObjectId:[rightField objectID] inView:[rightTableViewController view]];
    CGRect rightTableFrame = [[rightTableViewController schemaTableViewController] frame];
    CGFloat rightTableBottomY = rightTableFrame.origin.y + rightTableFrame.size.height;
    if (rightCellFrameInTable.origin.y + rightCellFrameInTable.size.height > rightTableBottomY) {
        rightCellFrameInTable = CGRectMake(rightCellFrameInTable.origin.x, rightTableBottomY - rightCellFrameInTable.size.height, rightCellFrameInTable.size.width, rightCellFrameInTable.size.height);
    } else if (rightCellFrameInTable.origin.y < rightTableFrame.origin.y) {
        rightCellFrameInTable = CGRectMake(rightCellFrameInTable.origin.x, rightTableFrame.origin.y, rightCellFrameInTable.size.width, rightCellFrameInTable.size.height);
    }
    CGRect rightCellFrameInView = [[self contentView] convertRect:rightCellFrameInTable fromView:[rightTableViewController view]];
    CGPoint rightCellCenterPoint = CGCenterOfRect(rightCellFrameInView);
    
    CGRect connectorFrame;
    
    CGFloat extraInset = 0.0000f;
    
    CGPoint leftCellAnchorPoint = leftCellCenterPoint;
    CGPoint rightCellAnchorPoint = rightCellCenterPoint;
    
    MNSConnectorPosition lastConnectorPositionB = [connectorView connectorPositionB];
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
    
    MNSConnectorPosition lastConnectorPosition = [connectorView connectorPosition];
    if (leftCellAnchorPoint.x < rightCellAnchorPoint.x) {
        if (leftCellAnchorPoint.y < rightCellAnchorPoint.y) {
            [connectorView setTopLeftToBottomRight:@(YES)];
            [connectorView setConnectorPosition:MNSConnectorPositionA];
        } else {
            [connectorView setTopLeftToBottomRight:@(NO)];
            leftCellAnchorPoint.y += leftCellFrameInTable.size.height;
            rightCellAnchorPoint.y -= rightCellFrameInTable.size.height;
            [connectorView setConnectorPosition:MNSConnectorPositionB];
        }
        [connectorView setLeftViewIsInital:YES];
    } else {
        extraInset = -20.0000f;
        if (leftCellAnchorPoint.y < rightCellAnchorPoint.y) {
            [connectorView setTopLeftToBottomRight:@(NO)];
            [connectorView setConnectorPosition:MNSConnectorPositionC];
        } else {
            [connectorView setTopLeftToBottomRight:@(YES)];
            leftCellAnchorPoint.y += leftCellFrameInTable.size.height;
            rightCellAnchorPoint.y -= rightCellFrameInTable.size.height;
            [connectorView setConnectorPosition:MNSConnectorPositionD];
        }
        [connectorView setLeftViewIsInital:NO];
    }
    connectorFrame = CGRectMake(leftCellAnchorPoint.x - 10.0000f - extraInset,
                                leftCellAnchorPoint.y - 10.0000f,
                                rightCellAnchorPoint.x - leftCellAnchorPoint.x + 20.0000f + (extraInset * 2.0000f),
                                rightCellAnchorPoint.y - leftCellAnchorPoint.y + 20.0000f);
    if (lastConnectorPosition == [connectorView connectorPosition] &&
        lastConnectorPositionB == [connectorView connectorPositionB]) {
        [connectorView setFrame: connectorFrame];
    } else {
        
        __block UIView *blockConnectorView = connectorView;
        MTBlockResultVoid setFrame = ^() {
            [blockConnectorView setFrame: connectorFrame];
        };
        
        if (animated == NO) {
            setFrame();
        } else {
            UIViewAnimationOptions options = UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut;
            [UIView animateWithDuration:0.3000f
                                  delay:0.0000f
                                options:options
                             animations:setFrame completion:NULL];
        }
    }
    
    [leftTableViewController release];
    [rightTableViewController release];
    [connectorView release];
    [insertedQueryLinks release];
    [controller release];
}

@end
