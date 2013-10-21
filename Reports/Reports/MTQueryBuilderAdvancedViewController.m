//
//  MTQueryBuilderAdvancedViewController.m
//  Reports
//
//  Created by Michael Thomason on 2/14/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0000f * M_PI)
#define RADIANS_TO_DEGREES(radians) ((radians) * (180.00000f / M_PI))

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

@property (nonatomic, retain) IBOutlet NSLayoutConstraint *containerViewHeightConstraint;
@property (nonatomic, retain) IBOutlet NSLayoutConstraint *containerViewWidthConstraint;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemShowSQL;

@property (nonatomic, assign) BOOL didRemoveViewControllers;

@property (nonatomic, retain) MAReportDocument *reportDocument;

@property (nonatomic, retain) UIPopoverController *showSqlPopoverController;
@property (nonatomic, assign) BOOL showSqlIsVisable;

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
    [_barButtonItemShowSQL release];
    [_tableIds release];
    [_reportDocument release];
    [_showSqlPopoverController release];
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

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [[self scrollView] setBounds:[[self backgroundContainer] bounds]];
    [[self scrollView] setCenter:[[self backgroundContainer] center]];
    [[self contentView] setBounds:[[self backgroundContainer] bounds]];
    [[self contentView] setCenter:[[self backgroundContainer] center]];
    NSArray *childViewControlleres = [self childViewControllers];
    for (id viewController in childViewControlleres) {
        Class desiredClass = [MTQueryBuilderAdvancedSchemaViewController class];
        if ([viewController isKindOfClass:desiredClass]) {
            __block UIView *view = [viewController view];
            CGRect desiredFrame = [self rectForDesiredRect:[view frame]];
            [UIView animateWithDuration:0.20000f animations:^{
                [view setFrame:desiredFrame];
            }];
            
            RptqQueryTable *table = [RptqQueryTable getQueryTableForObjectID:[view objectIdTag] fromObjectContext:[self managedObjectContext]];
            for (RptqQueryLinks *queryLink in [[table inQuery] hasQueryLinks]) {
                RptqQueryTable *leftTable = [[queryLink hasLeftField] inQueryTable];
                RptqQueryTable *rightTable = [[queryLink hasRightField] inQueryTable];
                if ([leftTable isEqualTo:table] ||
                    [rightTable isEqualTo:table]) {
                    [self layoutQueryLinkViewController:queryLink];
                }
            }
        }
    }
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
    UIView *containerView = [[UIView alloc] initWithFrame:[[self view] bounds]];
    [self setContentView:containerView];
    [containerView release];

    MTScrollViewCenter *scrollView = [[MTScrollViewCenter alloc] initWithFrame:[[self view] bounds]];
    [scrollView setShowsHorizontalScrollIndicator:YES];
    [scrollView setShowsVerticalScrollIndicator:YES];
    [scrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [scrollView setContentOffset:CGPointZero];
    [scrollView setMaximumZoomScale:1.0000f];
    [scrollView setMinimumZoomScale:1.0000f];
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

    NSMutableArray *toolbarButtons = [[[self toolbarBottom] items] mutableCopy];
    [toolbarButtons removeObject:[self barButtonItemShowSQL]];
    [[self toolbarBottom] setItems:toolbarButtons animated:NO];
    [toolbarButtons release];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[self scrollView] flashScrollIndicators];
    if ([UIDevice isPad] == NO) {   //Pad displays this in container
        [self reloadDocument:[[MTActiveDocument sharedDocument] activeDocument]];
    } else {
        if ([self didRemoveViewControllers]) {
            [self reloadDocument:[self reportDocument]];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([[self viewControllers] count] > 0) {
        [self removeViewControllers:[NSSet setWithArray:[self viewControllers]]];
        [[self viewControllers] removeAllObjects];
        [self setDidRemoveViewControllers:YES];
    }
    //NSLog(@"View Controller Count %d", [[self viewControllers] count]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self setShowSqlIsVisable:NO];
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

#pragma mark - NSManagedObjectContext observer

- (void)managedObjectContextDidSave:(NSNotification *)notification {
    
    NSArray *insertedObjects = [[notification userInfo] objectForKey: NSInsertedObjectsKey];
    
    for (id insertedObject in insertedObjects) {

        if ([insertedObject isKindOfClass:[RptqQueryLinks class]]) {
        
            RptqQueryLinks *insertedQueryLinks = [insertedObject retain];
            [self addLinkViewControllerForQueryLink: insertedQueryLinks];
            [insertedQueryLinks release];

        } else if ([insertedObject isKindOfClass:[RptqQueryTable class]]) {

            RptqQueryTable *insertedQueryTable = [insertedObject retain];
            [self addSchemaViewControllerForTable: insertedQueryTable];
            [insertedQueryTable release];

        }
    }
    
    NSArray *updatedObjects = [[notification userInfo] objectForKey: NSUpdatedObjectsKey];
    
    RptqQuery *updatedQuery = nil;
    RptqQueryTable *updatedTable = nil;
    
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
            [self addSchemaViewControllerForTable:updatedTable];
        } else {
            [self removeSchemaViewControllerForTable:updatedTable];
        }
    }
    
    [updatedTable release];
    [updatedQuery release];
    
    
    
    NSArray *deletedObjects = [[notification userInfo] objectForKey: NSDeletedObjectsKey];
    for (id deletedObject in deletedObjects) {
        //NSLog(@"Deleted %@", deletedObject);
        
        if ([deletedObject isKindOfClass:[RptqQueryTable class]]) {
            RptqQueryTable *deletedTable = deletedObject;
            if ([deletedTable inQuery] != nil &&
                [[self tableIds] containsObject: [deletedTable objectID]]) {
                [self removeSchemaViewControllerForTable:deletedTable];
            }
        } else if ([deletedObject isKindOfClass:[RptqQueryLinks class]]) {
            RptqQueryLinks *deletedLink = deletedObject;
            UIViewController *linkViewController = [[self controllersForObjectIdsLink] objectForKey: [deletedLink objectID]];
            if (linkViewController != nil) {
                [self removeLinkViewControllerForQueryLink:deletedLink];
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

- (CGRect)rectForDesiredRect:(CGRect)desiredFrame {
    CGRect viewControllerBounds = [[self contentView] bounds];
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

- (void)addViewController:(UIViewController *)viewController {

    [viewController retain];
    CGFloat animationDuration = 0.6000f;
    CGRect desiredFrame = [[viewController view] frame];
    CGPoint desiredCenter = [[viewController view] center];
    CGAffineTransform desiredTransform = [[viewController view] transform];
    NSUInteger animationType = 0;
    CGAffineTransform swingTransform = CGAffineTransformIdentity;
    swingTransform = CGAffineTransformRotate(swingTransform, DEGREES_TO_RADIANS(180.0000f));

    if ([viewController isKindOfClass:[MTQueryBuilderAdvancedSchemaViewController class]]) {
        
        NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
        RptqQueryTable *table = [RptqQueryTable getQueryTableForObjectID:[(MTQueryBuilderAdvancedSchemaViewController *)viewController tableObjectId] fromObjectContext:managedObjectContext];
        desiredFrame = CGRectMake(table.designerOriginX.floatValue, table.designerOriginY.floatValue, table.designerSizeWidth.floatValue, table.designerSizeHeight.floatValue);
        animationType = 1;
        [[viewController view] setCenter:CGPointMakeRandomOffscreen()];

        desiredFrame = [self rectForDesiredRect:desiredFrame];

    } else if ([[viewController view] isKindOfClass:[MTConnectorView class]]) {
        
        [[viewController view] setBounds:CGRectZero];
        [[viewController view] setCenter:desiredCenter];
        [[viewController view] setTransform:swingTransform];

        animationType = 2;
    }

    
    [self addChildViewController:viewController];
    if ([[self viewControllers] containsObject:viewController] == NO) {
        [[self viewControllers] addObject:viewController];
    }
    [[self contentView] addSubview:[viewController view]];
    [viewController didMoveToParentViewController:self];

    switch (animationType) {
        case 1:

            [UIView animateWithDuration:animationDuration delay:0.0000f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                [[viewController view] setFrame:desiredFrame];
                //[[viewController view] setTransform:desiredTransform];
            } completion:^(BOOL finished) {}];

            break;
        case 2:
            
            [UIView animateWithDuration:animationDuration delay:0.0000f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                [[viewController view] setFrame:desiredFrame];
                [[viewController view] setTransform:desiredTransform];
            } completion:^(BOOL finished) {}];
            
            break;
            
        default:
            break;
    }

    [viewController release];
}

- (void)removeViewControllers:(NSSet *)viewControllers {
    for (UIViewController *viewController in viewControllers) {
        [self removeViewController:viewController];
    }
}

- (void)removeViewController:(UIViewController *)viewController {
    //NSLog(@"%@", [viewController view]);
    CGFloat animationDuration = 0.6000f;
    CGAffineTransform swingTransform = CGAffineTransformIdentity;
    swingTransform = CGAffineTransformRotate(swingTransform, DEGREES_TO_RADIANS(180.0000f));

    if ([viewController isKindOfClass:[MTQueryBuilderAdvancedSchemaViewController class]]) {

        CGPoint center = CGPointMakeRandomOffscreen();
        [UIView animateWithDuration:animationDuration delay:0.0000f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [[viewController view] setCenter:center];
            //[[viewController view] setTransform:swingTransform];
        } completion:^(BOOL finished) {
            [viewController willMoveToParentViewController:nil];
            [[viewController view] removeFromSuperview];
            [viewController removeFromParentViewController];
        }];
        
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

#pragma mark View Controller Container Custom Handlers

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
- (void)viewControllerDidFinish:(id)sender {
    if ([UIDevice isPad] && [self showSqlIsVisable]) {
        [[self showSqlPopoverController] dismissPopoverAnimated:YES];
        [self setShowSqlIsVisable:NO];
    } else {
        [self dismissViewControllerAnimated:YES completion:^{ }];
    }
}

- (void)addSchemaViewController:(UIViewController *)viewController {
    [viewController retain];
    CGRect subviewRect = CGRectZero;
    NSManagedObjectID *objectId = [[(MTQueryBuilderAdvancedSchemaViewController *)viewController tableObjectId] retain];
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    RptqQueryTable *table = [RptqQueryTable getQueryTableForObjectID:objectId fromObjectContext:managedObjectContext];
    [[self tableIds] addObject:objectId];
    [[self controllersForObjectIds] setObject:viewController forKey:objectId];
    [objectId release];
    if ([[table designerInitalLayout] boolValue]) {
        CGFloat originX = 50.0000f * ((([self tableDisplayCounter] + 1) - 9) % 9) + CGPointZero.x;
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
    
    if (CGRectContainsRect([[self view] frame], subviewRect) == NO) {
        //CGFloat originX = 50.0000f + CGPointZero.x;
        //CGFloat originY = originX;
        CGRect contentViewBounds = [[self view] bounds];
        CGPoint p = [self randomPointInRect:CGRectInset(contentViewBounds, 50.0000f, 50.0000f)];
        subviewRect = CGRectMake(p.x, p.y, 180.0000f, 200.0000f);
        [table setDesignerSizeHeight:@(subviewRect.size.height)];
        [table setDesignerSizeWidth:@(subviewRect.size.width)];
        [table setDesignerOriginY:@(subviewRect.origin.x)];
        [table setDesignerOriginX:@(subviewRect.origin.y)];
        [table setDesignerInitalLayout:@(NO)];
        [managedObjectContext save:nil];
    }
    [[viewController view] setFrame: subviewRect];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panPiece:)];
    [panGesture setMaximumNumberOfTouches:1];
    [panGesture setDelegate:self];
    [[viewController view] addGestureRecognizer:panGesture];
    [panGesture release];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPiece:)];
    [tapGesture setDelegate:self];
    [tapGesture setNumberOfTapsRequired:1];
    [[viewController view] addGestureRecognizer:tapGesture];
    [tapGesture release];
    
    [self addViewController:viewController];
    
    self.tableDisplayCounter++;
    [viewController release];
}
- (CGPoint)randomPointInRect:(CGRect)rect {
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

- (void)removeSchemaViewControllerForTable:(RptqQueryTable *)table {
    UIViewController *viewController = [[[self controllersForObjectIds] objectForKey:[table objectID]] retain];
    [self removeViewController:viewController];
    [viewController release];
}

- (void)addSchemaViewControllerForTable:(RptqQueryTable *)table {
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
    CGFloat paddingLeft = 75.0000f;
    RptqQueryField *leftField = [insertedQueryLinks hasLeftField];
    RptqQueryTable *leftTable = [leftField inQueryTable];
    
    MTQueryBuilderAdvancedSchemaViewController *leftTableViewController = [[[self controllersForObjectIds] objectForKey:[leftTable objectID]] retain];

    NSLog(@"rect ltvc %@", NSStringFromCGRect([[leftTableViewController view] frame]));
    
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
        [UIView animateWithDuration:0.5000f delay:0.0000f options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [connectorView setFrame: connectorFrame];
                         } completion:^(BOOL finished) {
                             
                         }];
    }
    
    [leftTableViewController release];
    [rightTableViewController release];
    [connectorView release];
    [insertedQueryLinks release];
    [controller release];
}

#pragma mark Reload document view controllers

- (void)reloadDocument:(MAReportDocument *)documentReport {
    
    MAReportDocument *reportDocument = [documentReport retain];
    [self setReportDocument:reportDocument];
    [reportDocument release];

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

    __block MTQueryBuilderAdvancedViewController *viewController = self;
    
    dispatch_queue_t queuePriorityMain = dispatch_get_main_queue();
    dispatch_queue_t queuePriorityNormal = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_async(queuePriorityNormal, ^{
        dispatch_async(queuePriorityMain, ^{
            
            RptqQuery *query = [RptqDocument queryForActiveDocument];
            for (RptqQueryTable *table in [query hasQueryTables]) {
                [self addSchemaViewControllerForTable:table];
            }
            
            dispatch_async(queuePriorityNormal, ^{
                dispatch_async(queuePriorityMain, ^{

                    NSArray *queryLinks = [[RptqDocument queryLinksForActiveDocument] retain];
                    for (RptqQueryLinks *queryLink in queryLinks) {
                        [viewController addLinkViewControllerForQueryLink:queryLink];
                    }
                    [queryLinks release];

                });
            });
        });
    });

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

    [UIGestureRecognizer adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    
    switch ([gestureRecognizer state]) {
            
        case UIGestureRecognizerStateBegan: {   // MARK: UIPanGestureRecognizer UIGestureRecognizerStateBegan
            UIView *gestureRecognizerView = [gestureRecognizer view];
            CGPoint gestureLocation = [gestureRecognizer locationInView:[self view]];
            [gestureRecognizerView setCenter: gestureLocation];
            [[self contentView] bringSubviewToFront:gestureRecognizerView];
            for (UIView *view in [[self contentView] subviews]) {
                if ([view isKindOfClass:[MTConnectorView class]]) {
                    [[self contentView] bringSubviewToFront:view];
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {     // MARK: UIPanGestureRecognizer UIGestureRecognizerStateChanged
            CGPoint newCenter = [gestureRecognizer locationInView:[self contentView]];
            [[gestureRecognizer view] setCenter: newCenter];
            
            RptqQueryTable *table = [RptqQueryTable getQueryTableForObjectID:[[gestureRecognizer view] objectIdTag] fromObjectContext:[self managedObjectContext]];
            for (RptqQueryLinks *queryLink in [[table inQuery] hasQueryLinks]) {
                RptqQueryTable *leftTable = [[queryLink hasLeftField] inQueryTable];
                RptqQueryTable *rightTable = [[queryLink hasRightField] inQueryTable];
                if ([leftTable isEqualTo:table] ||
                    [rightTable isEqualTo:table]) {
                    [self layoutQueryLinkViewController:queryLink];
                }
            }
            break;
        }
        case UIGestureRecognizerStatePossible:      // MARK: UIPanGestureRecognizer UIGestureRecognizerStatePossible
            break;
        case UIGestureRecognizerStateCancelled:     // MARK: UIPanGestureRecognizer UIGestureRecognizerStateCancelled
        case UIGestureRecognizerStateFailed:        // MARK: UIPanGestureRecognizer UIGestureRecognizerStateFailed
        case UIGestureRecognizerStateEnded: {       // MARK: UIPanGestureRecognizer UIGestureRecognizerStateEnded
            
            
            CGPoint gestureLocation = [gestureRecognizer locationInView:[self contentView]];
            [[gestureRecognizer view] setCenter: gestureLocation];
            
            NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
            RptqQueryTable *queryTable = [RptqQueryTable getQueryTableForObjectID:[[gestureRecognizer view] objectIdTag] fromObjectContext:managedObjectContext];
            [queryTable setDesignerSizeHeight:@([[gestureRecognizer view] frame].size.height)];
            [queryTable setDesignerSizeWidth:@([[gestureRecognizer view] frame].size.width)];
            [queryTable setDesignerOriginY:@([[gestureRecognizer view] frame].origin.y)];
            [queryTable setDesignerOriginX:@([[gestureRecognizer view] frame].origin.x)];
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
        RptqQueryTable *queryTable = [RptqQueryTable getQueryTableForObjectID:[controller tableObjectId] fromObjectContext:[self managedObjectContext]];
        for (RptqQueryLinks *queryLink in [[queryTable inQuery] hasQueryLinks]) {
            RptqQueryTable *leftTable = [[queryLink hasLeftField] inQueryTable];
            RptqQueryTable *rightTable = [[queryLink hasRightField] inQueryTable];
            if ([leftTable isEqualTo:queryTable] ||
                [rightTable isEqualTo:queryTable]) {
                [self layoutQueryLinkViewController:queryLink];
            }
        }

    }
}

@end
