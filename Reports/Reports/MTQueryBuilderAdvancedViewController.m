//
//  MTQueryBuilderAdvancedViewController.m
//  Reports
//
//  Created by Michael Thomason on 2/14/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderAdvancedViewController.h"

@interface MTQueryBuilderAdvancedViewController ()

@property (nonatomic, retain) IBOutlet UIToolbar *toolbarBottom;
@property (nonatomic, retain) IBOutlet UIView *backgroundContainer;
@property (nonatomic, retain) MTScrollViewCenter *scrollView;
@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, retain) NSMutableArray *viewControllers;
@property (nonatomic, retain) NSMutableSet *tableIds;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSMutableDictionary *controllersForObjectIds;     //Tables and links
@property (nonatomic, retain) NSMutableDictionary *controllersForObjectIdsLink; //Only query links
@property (nonatomic, assign) NSUInteger tableDisplayCounter;

@property (retain, nonatomic) IBOutlet NSLayoutConstraint *containerViewHeightConstraint;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *containerViewWidthConstraint;

@end

@implementation MTQueryBuilderAdvancedViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextDidSaveNotification
                                                  object:[self managedObjectContext]];
    [self removeViewControllers:[NSSet setWithArray:_viewControllers]];
    [_managedObjectContext release];
    [_viewControllers release];
    [_controllersForObjectIds release];
    [_controllersForObjectIdsLink release];
    [_scrollView release];
    [_contentView release];
    [_containerViewHeightConstraint release];
    [_containerViewWidthConstraint release];
    [_backgroundContainer release];
    [_toolbarBottom release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
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
        
        [self setTableDisplayCounter:0];

    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLayoutSubviews {
    [[self scrollView] setBounds:[[self backgroundContainer] bounds]];
    [[self scrollView] setCenter:[[self backgroundContainer] center]];
    [[self contentView] setBounds:[[self backgroundContainer] bounds]];
    [[self contentView] setCenter:[[self backgroundContainer] center]];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIView *containerView = [[UIView alloc] initWithFrame:[[self view] bounds]];
    [containerView setBackgroundColor:[UIColor paperGraphPaper]];
    [self setContentView:containerView];
    [containerView release];

    MTScrollViewCenter *scrollView = [[MTScrollViewCenter alloc] initWithFrame:[[self view] bounds]];
    [scrollView setShowsHorizontalScrollIndicator:YES];
    [scrollView setShowsVerticalScrollIndicator:YES];
    [scrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [scrollView setContentOffset:CGPointZero];
    [scrollView setMaximumZoomScale:10.0000f];
    [scrollView setMinimumZoomScale:0.010000f];
    [scrollView setZoomScale:1.0000f];
    [scrollView setScrollEnabled:YES];
    [scrollView setBounces:YES];
    [scrollView setAlwaysBounceHorizontal:YES];
    [scrollView setAlwaysBounceVertical:YES];
    [scrollView setBouncesZoom:YES];
    [scrollView setDelegate:self];
    [scrollView setBackgroundColor:[UIColor clearColor]];
    [scrollView addSubview:[self contentView]];
    [self setScrollView:scrollView];
    [scrollView release];
    
    [[self backgroundContainer] addSubview:[self scrollView]];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[self toolbarBottom] setTintColor:[UIColor edaBlueDark]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[self scrollView] flashScrollIndicators];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - NSManagedObjectContext observer

- (void)managedObjectContextDidSave:(NSNotification *)notification {
    
    NSArray *insertedObjects = [[notification userInfo] objectForKey: NSInsertedObjectsKey];
    
    for (id insertedObject in insertedObjects) {
        if ([insertedObject isKindOfClass:[RptqQueryLinks class]]) {
            RptqQueryLinks *insertedQueryLinks = [insertedObject retain];
            [self addLinkViewControllerForQueryLink: insertedQueryLinks];
            [insertedQueryLinks release];
        }
    }
    
    NSArray *updatedObjects = [[notification userInfo] objectForKey: NSUpdatedObjectsKey];
    
    RptqQuery *updatedQuery = nil;
    RptqTable *updatedTable = nil;
    
    for (id updatedObject in updatedObjects) {
        //NSLog(@"Updated %@", updatedObject);
        //NSLog(@"Changed values %@", [updatedObject changedValues]);
        //NSLog(@"Committed values %@", [updatedObject committedValuesForKeys:@[@"inQuery", @"hasTables"]]);
        if ([updatedObject isKindOfClass:[RptqTable class]]) {
            updatedTable = [updatedObject retain];
        } else if ([updatedObject isKindOfClass:[RptqQuery class]]) {
            updatedQuery = [updatedObject retain];
        }
    }
    
    if (updatedQuery && updatedTable) {
        if ([[updatedTable inQuery] containsObject:updatedQuery]) {
            [self addSchemaViewControllerForTable:updatedTable];
            //NSLog(@"Add table");
        } else {
            [self removeSchemaViewControllerForTable:updatedTable];
            //NSLog(@"Remove table");
        }
    }
    
    [updatedTable release];
    [updatedQuery release];
    
    
    
    NSArray *deletedObjects = [[notification userInfo] objectForKey: NSDeletedObjectsKey];
    for (id deletedObject in deletedObjects) {
        //NSLog(@"Deleted %@", deletedObject);
        
        if ([deletedObject isKindOfClass:[RptqTable class]]) {
            RptqTable *deletedTable = deletedObject;
            if ([deletedTable inQuery] != nil &&
                [[self tableIds] containsObject: [deletedTable objectID]] == YES) {
                [self removeSchemaViewControllerForTable:deletedTable];
            }
        }
    }
}

#pragma mark - View Controller Container Data

- (void)addViewControllers:(NSSet *)viewControllers {
    for (UIViewController *viewController in viewControllers) {
        [self addViewController:viewController];
    }
}

- (void)addViewController:(UIViewController *)viewController {
    [viewController retain];
    [self addChildViewController:viewController];
    [[self viewControllers] addObject:viewController];
    [[self contentView] addSubview:[viewController view]];
    [viewController didMoveToParentViewController:self];
    [viewController release];
}

- (void)removeViewControllers:(NSSet *)viewControllers {
    for (UIViewController *viewController in viewControllers) {
        [self removeViewController:viewController];
    }
}

- (void)removeViewController:(UIViewController *)viewController {
    [viewController willMoveToParentViewController:nil];
    [[viewController view] removeFromSuperview];
    [viewController removeFromParentViewController];
}

#pragma mark View Controller Container Custom Handlers

- (void)addSchemaViewController:(UIViewController *)viewController {
    [viewController retain];
    [self addChildViewController:viewController];
    [[self viewControllers] addObject:viewController];
    CGRect subviewRect = CGRectZero;
    NSManagedObjectID *objectId = [[(MTQueryBuilderAdvancedSchemaViewController *)viewController tableObjectId] retain];
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    RptqTable *table = [RptqTable getTableForObjectID:objectId fromObjectContext:managedObjectContext];
    [[self tableIds] addObject:objectId];
    [[self controllersForObjectIds] setObject:viewController forKey:objectId];
    [objectId release];
    if ([[table designerInitalLayout] boolValue] == YES) {
        CGFloat originX = 50.0000f * ([self tableDisplayCounter] + 1) + CGPointZero.x;
        CGFloat originY = originX;
        subviewRect = CGRectMake(originX, originY, 180.0000f, 200.0000f);
        [table setDesignerSizeHeight:@(subviewRect.size.height)];
        [table setDesignerSizeWidth:@(subviewRect.size.width)];
        [table setDesignerOriginY:@(subviewRect.origin.x)];
        [table setDesignerOriginX:@(subviewRect.origin.y)];
        [table setDesignerInitalLayout:@(NO)];
        [managedObjectContext save:nil];
    } else {
        subviewRect = CGRectMake(table.designerOriginX.floatValue, table.designerOriginY.floatValue, table.designerSizeWidth.floatValue, table.designerSizeHeight.floatValue);
    }
    [[viewController view] setFrame: subviewRect];
    [[viewController view] setBackgroundColor:[UIColor blueColor]];
    
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panPiece:)];
    [panGesture setMaximumNumberOfTouches:1];
    [panGesture setDelegate:self];
    [[viewController view] addGestureRecognizer:panGesture];
    [panGesture release];
    
    
    [[self contentView] addSubview:[viewController view]];
    [viewController didMoveToParentViewController:self];
    self.tableDisplayCounter++;
    [viewController release];
}

- (void)removeSchemaViewControllerForTable:(RptqTable *)table {
    UIViewController *viewController = [[[self controllersForObjectIds] objectForKey:[table objectID]] retain];
    [self removeViewController:viewController];
    [viewController release];
}

- (void)addSchemaViewControllerForTable:(RptqTable *)table {
    UIStoryboard *sb = [[UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil] retain];
    MTQueryBuilderAdvancedSchemaViewController *viewController = [[sb instantiateViewControllerWithIdentifier:@"MTQueryBuilderAdvancedSchemaViewControllerIdentifier"] retain];
    [viewController setDelegate:self];
    [viewController setTableObjectId:[table objectID]];
    [self addSchemaViewController:viewController];
    [sb release];
    [viewController release];
}

- (void)addLinkViewControllerForQueryLink:(RptqQueryLinks *)link {
    NSManagedObjectID *objectId = [[link objectID] retain];
    MTConnectorView *connectorView = [[MTConnectorView alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, 100.0000f, 100.0000f)];
    [connectorView setUserInteractionEnabled:NO];
    [connectorView setObjectIdTag:objectId];
    RptqField *leftField = [link hasLeftField];
    RptqTable *leftTable = [leftField inTable];
    MTQueryBuilderAdvancedSchemaViewController *leftTableViewController = [[[self controllersForObjectIds] objectForKey:[leftTable objectID]] retain];
    UIView *leftTableView = [[leftTableViewController view] retain];
    
    RptqField *rightField = [link hasRightField];
    RptqTable *rightTable = [rightField inTable];
    MTQueryBuilderAdvancedSchemaViewController *rightTableViewController = [[[self controllersForObjectIds] objectForKey:[rightTable objectID]] retain];
    UIView *rightTableView = [[rightTableViewController view] retain];
    
    UIViewController *connectorViewController = [[UIViewController alloc] init];
    [connectorViewController setView:connectorView];
    
    [self addViewController:connectorViewController];
    [[self controllersForObjectIds] setObject:connectorViewController forKey:objectId];
    [[self controllersForObjectIdsLink] setObject:connectorViewController forKey:objectId];
    
    [self layoutQueryLinkViewController:link];
    
    [leftTableView release];
    [leftTableViewController release];
    [rightTableView release];
    [rightTableViewController release];
    [connectorViewController release];
    [connectorView release];
    [objectId release];
}

- (void)removeLinkViewControllerForQueryLink:(RptqQueryLinks *)link {
    UIViewController *viewController = [[[self controllersForObjectIds] objectForKey:[link objectID]] retain];
    [self removeViewController:viewController];
    [viewController release];
}

- (void)layoutQueryLinkViewController:(RptqQueryLinks *)queryLink {
    RptqQueryLinks *insertedQueryLinks = [queryLink retain];
    UIViewController *controller = [[[self controllersForObjectIdsLink] objectForKey:[queryLink objectID]] retain];
    MTConnectorView *connectorView = [(MTConnectorView *)[controller view] retain];
    RptqField *leftField = [insertedQueryLinks hasLeftField];
    RptqTable *leftTable = [leftField inTable];
    MTQueryBuilderAdvancedSchemaViewController *leftTableViewController = [[[self controllersForObjectIds] objectForKey:[leftTable objectID]] retain];

    CGRect leftCellFrameInTable = [leftTableViewController rectForFieldWithObjectId:[leftField objectID] inView:[leftTableViewController view]];
    CGRect leftTableFrame = [[leftTableViewController schemaTableViewController] frame];
    CGFloat leftTableBottomY = leftTableFrame.origin.y + leftTableFrame.size.height;
    if (leftCellFrameInTable.origin.y + leftCellFrameInTable.size.height > leftTableBottomY) {
        leftCellFrameInTable = CGRectMake(leftCellFrameInTable.origin.x, leftTableBottomY - leftCellFrameInTable.size.height, leftCellFrameInTable.size.width, leftCellFrameInTable.size.height);
    } else if (leftCellFrameInTable.origin.y < leftTableFrame.origin.y) {
        leftCellFrameInTable = CGRectMake(leftCellFrameInTable.origin.x, leftTableFrame.origin.y, leftCellFrameInTable.size.width, leftCellFrameInTable.size.height);
    }
    CGRect leftCellFrameInView = [[self view] convertRect:leftCellFrameInTable fromView:[leftTableViewController view]];
    CGPoint leftCellCenterPoint = CGCenterOfRect(leftCellFrameInView);

    RptqField *rightField = [insertedQueryLinks hasRightField];
    RptqTable *rightTable = [rightField inTable];
    MTQueryBuilderAdvancedSchemaViewController *rightTableViewController = [[[self controllersForObjectIds] objectForKey:[rightTable objectID]] retain];

    CGRect rightCellFrameInTable = [rightTableViewController rectForFieldWithObjectId:[rightField objectID] inView:[rightTableViewController view]];
    CGRect rightTableFrame = [[rightTableViewController schemaTableViewController] frame];
    CGFloat rightTableBottomY = rightTableFrame.origin.y + rightTableFrame.size.height;
    if (rightCellFrameInTable.origin.y + rightCellFrameInTable.size.height > rightTableBottomY) {
        rightCellFrameInTable = CGRectMake(rightCellFrameInTable.origin.x, rightTableBottomY - rightCellFrameInTable.size.height, rightCellFrameInTable.size.width, rightCellFrameInTable.size.height);
    } else if (rightCellFrameInTable.origin.y < rightTableFrame.origin.y) {
        rightCellFrameInTable = CGRectMake(rightCellFrameInTable.origin.x, rightTableFrame.origin.y, rightCellFrameInTable.size.width, rightCellFrameInTable.size.height);
    }
    CGRect rightCellFrameInView = [[self view] convertRect:rightCellFrameInTable fromView:[rightTableViewController view]];
    CGPoint rightCellCenterPoint = CGCenterOfRect(rightCellFrameInView);
    
    
    if (leftCellCenterPoint.x < rightCellCenterPoint.x) {
        if (leftCellCenterPoint.y < rightCellCenterPoint.y) {
            [connectorView setTopLeftToBottomRight:@(YES)];
        } else {
            [connectorView setTopLeftToBottomRight:@(NO)];
        }
    } else {
        if (leftCellCenterPoint.y < rightCellCenterPoint.y) {
            [connectorView setTopLeftToBottomRight:@(NO)];
        } else {
            [connectorView setTopLeftToBottomRight:@(YES)];
        }
    }
    
    CGRect connectorFrame = CGRectMake(leftCellCenterPoint.x,
                                       leftCellCenterPoint.y,
                                       rightCellCenterPoint.x - leftCellCenterPoint.x,
                                       rightCellCenterPoint.y - leftCellCenterPoint.y);
    
    [connectorView setFrame: connectorFrame];
    
    
    [leftTableViewController release];
    [rightTableViewController release];
    [connectorView release];
    [insertedQueryLinks release];
    [controller release];
}

#pragma mark Reload document view controllers

- (void)reloadDocument:(MNSDocumentReport *)documentReport {
    
    NSManagedObjectContext *managedObjectContext = [[documentReport managedObjectContext] retain];
    [self setManagedObjectContext:managedObjectContext];
    [managedObjectContext release];
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver:self
                             name:NSManagedObjectContextDidSaveNotification
                           object:[self managedObjectContext]];
    [defaultCenter addObserver:self
                      selector:@selector(managedObjectContextDidSave:)
                          name:NSManagedObjectContextDidSaveNotification
                        object:[self managedObjectContext]];
    
    [self removeViewControllers:[NSSet setWithArray:[self viewControllers]]];

    [self setTableDisplayCounter:0];

    dispatch_queue_t queuePriorityMain = dispatch_get_main_queue();
    dispatch_queue_t queuePriorityNormal = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_async(queuePriorityNormal, ^{
        dispatch_async(queuePriorityMain, ^{
            
            NSArray *tables = [[RptqDocument tablesForActiveDocument] retain];
            for (RptqTable *table in tables) {
                [self addSchemaViewControllerForTable:table];
            }
            [tables release];
            
            dispatch_async(queuePriorityNormal, ^{
                dispatch_async(queuePriorityMain, ^{

                    NSArray *queryLinks = [[RptqDocument queryLinksForActiveDocument] retain];
                    for (RptqQueryLinks *queryLink in queryLinks) {
                        [self addLinkViewControllerForQueryLink:queryLink];
                    }
                    [queryLinks release];

                });
            });
        });
    });

}

#pragma mark - Gesture recognizer actions

- (void)panPiece:(UIPanGestureRecognizer *)gestureRecognizer {

    [UIGestureRecognizer adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    
    switch ([gestureRecognizer state]) {
            
        case UIGestureRecognizerStateBegan: {   // MARK: UIPanGestureRecognizer UIGestureRecognizerStateBegan
            
            CGPoint newCenter = [gestureRecognizer locationInView:[self view]];
            [[gestureRecognizer view] setCenter: newCenter];
            
            break;
        }
        case UIGestureRecognizerStateChanged: {     // MARK: UIPanGestureRecognizer UIGestureRecognizerStateChanged
            CGPoint newCenter = [gestureRecognizer locationInView:[self view]];
            [[gestureRecognizer view] setCenter: newCenter];
            
            RptqTable *table = [RptqTable getTableForObjectID:[[gestureRecognizer view] objectIdTag] fromObjectContext:[self managedObjectContext]];
            for (RptqQueryLinks *queryLink in [[[table inQuery] anyObject] hasQueryLinks]) {
                RptqTable *leftTable = [[queryLink hasLeftField] inTable];
                RptqTable *rightTable = [[queryLink hasRightField] inTable];
                if ([leftTable isEqualTo:table] ||
                    [rightTable isEqualTo:table]) {
                    [self layoutQueryLinkViewController:queryLink];
                }
            }
            break;
        }
        case UIGestureRecognizerStatePossible: {    // MARK: UIPanGestureRecognizer UIGestureRecognizerStatePossible
            
            break;
        }
        case UIGestureRecognizerStateCancelled:     // MARK: UIPanGestureRecognizer UIGestureRecognizerStateCancelled
        case UIGestureRecognizerStateFailed:        // MARK: UIPanGestureRecognizer UIGestureRecognizerStateFailed
        case UIGestureRecognizerStateEnded: {       // MARK: UIPanGestureRecognizer UIGestureRecognizerStateEnded
            
            
            CGPoint newCenter = [gestureRecognizer locationInView:[self view]];
            [[gestureRecognizer view] setCenter: newCenter];
            
            NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
            RptqTable *table = [RptqTable getTableForObjectID:[[gestureRecognizer view] objectIdTag] fromObjectContext:managedObjectContext];
            [table setDesignerSizeHeight:@([[gestureRecognizer view] frame].size.height)];
            [table setDesignerSizeWidth:@([[gestureRecognizer view] frame].size.width)];
            [table setDesignerOriginY:@([[gestureRecognizer view] frame].origin.y)];
            [table setDesignerOriginX:@([[gestureRecognizer view] frame].origin.x)];
            NSError *error;
            [managedObjectContext save:&error];
            break;
        }
        default:
            break;
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {

}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    return YES;
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return [[[self contentView] retain] autorelease];
}

#pragma mark - MTQueryBuilderAdvancedSchemaViewControllerDelegate

- (void)didMoveFieldRect:(id)sender {
    if ([sender isKindOfClass:[MTQueryBuilderAdvancedSchemaViewController class]]) {
        MTQueryBuilderAdvancedSchemaViewController *controller = (MTQueryBuilderAdvancedSchemaViewController *)sender;
        RptqTable *table = [RptqTable getTableForObjectID:[controller tableObjectId] fromObjectContext:[self managedObjectContext]];
        for (RptqQueryLinks *queryLink in [[[table inQuery] anyObject] hasQueryLinks]) {
            RptqTable *leftTable = [[queryLink hasLeftField] inTable];
            RptqTable *rightTable = [[queryLink hasRightField] inTable];
            if ([leftTable isEqualTo:table] ||
                [rightTable isEqualTo:table]) {
                [self layoutQueryLinkViewController:queryLink];
            }
        }

    }
}

@end
