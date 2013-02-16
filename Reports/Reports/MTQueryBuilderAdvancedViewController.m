//
//  MTQueryBuilderAdvancedViewController.m
//  Reports
//
//  Created by Michael Thomason on 2/14/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderAdvancedViewController.h"

@interface MTQueryBuilderAdvancedViewController ()

@property (nonatomic, retain) NSMutableArray *viewControllers;
@property (nonatomic, retain) NSMutableSet *tableIds;
@property (retain, nonatomic) IBOutlet UIToolbar *toolbarTop;
@property (retain, nonatomic) IBOutlet UIToolbar *toolbarBottom;
@property (nonatomic, assign) NSUInteger tableDisplayCounter;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSMutableDictionary *controllersForTableIds;

@end

@implementation MTQueryBuilderAdvancedViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextDidSaveNotification
                                                  object:[self managedObjectContext]];
    [self removeViewControllers:[NSSet setWithArray:_viewControllers]];
    [_managedObjectContext release];
    [_viewControllers release];
    [_toolbarTop release];
    [_toolbarBottom release];
    [super dealloc];
}

- (void)managedObjectContextDidSave:(NSNotification *)notification {

    NSArray *insertedObjects = [[notification userInfo] objectForKey: NSInsertedObjectsKey];
    
    for (id insertedObject in insertedObjects) {
        if ([insertedObject isKindOfClass:[RptqTable class]]) {
            NSLog(@"Inserted %@", insertedObject);
        }
    }

    NSArray *updatedObjects = [[notification userInfo] objectForKey: NSUpdatedObjectsKey];
    for (id updatedObject in updatedObjects) {
        NSLog(@"Updated %@", updatedObject);

        if ([updatedObject isKindOfClass:[RptqTable class]]) {
            RptqTable *updatedTable = updatedObject;
            if ([updatedTable inQuery] != nil &&
                [[self tableIds] containsObject: [updatedTable objectID]] == NO) {
                
                [self addSchemaViewControllerForTable:updatedTable];

            }
        }
    }

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
        [self setControllersForTableIds:controllersForTableIds];
        [controllersForTableIds release];
        
        [self setTableDisplayCounter:0];

    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[self toolbarTop] setTintColor: [UIColor edaBlueDark]];
    [[self toolbarBottom] setTintColor: [UIColor edaBlueDark]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)addViewControllers:(NSSet *)viewControllers {
    for (UIViewController *viewController in viewControllers) {
        [self addViewController:viewController];
    }
}

- (void)addViewController:(UIViewController *)viewController {
    [self addChildViewController:viewController];
    [[self viewControllers] addObject:viewController];
    CGRect subviewRect = CGRectZero;
    NSManagedObjectID *objectId = [[(MTQueryBuilderAdvancedSchemaViewController *)viewController tableObjectId] retain];
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    RptqTable *table = [RptqTable getTableForObjectID:objectId fromObjectContext:managedObjectContext];
    [[self tableIds] addObject:objectId];
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

    
    [[self view] addSubview:[viewController view]];
    [viewController didMoveToParentViewController:self];
    self.tableDisplayCounter++;
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
    NSArray *tables = [[RptqDocument tablesForActiveDocument] retain];
    for (RptqTable *table in tables) {
        NSLog(@"Table: %@", table);
        [self addSchemaViewControllerForTable:table];
    }
    [tables release];
}

- (void)addSchemaViewControllerForTable:(RptqTable *)table {
    UIStoryboard *sb = [[UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil] retain];
    MTQueryBuilderAdvancedSchemaViewController *viewController = [[sb instantiateViewControllerWithIdentifier:@"MTQueryBuilderAdvancedSchemaViewControllerIdentifier"] retain];
    [viewController setTableObjectId:[table objectID]];
    [self addViewController:viewController];
    [sb release];
    [viewController release];
}

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

@end
