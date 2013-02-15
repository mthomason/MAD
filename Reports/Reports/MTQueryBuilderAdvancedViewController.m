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
@property (retain, nonatomic) IBOutlet UIToolbar *toolbarTop;
@property (retain, nonatomic) IBOutlet UIToolbar *toolbarBottom;

@property (nonatomic, assign) NSUInteger tableDisplayCounter;

@end

@implementation MTQueryBuilderAdvancedViewController

- (void)dealloc {
    [self removeViewControllers:[NSSet setWithArray:_viewControllers]];
    [_viewControllers release];
    [_toolbarTop release];
    [_toolbarBottom release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}


- (void)awakeFromNib {
    [super awakeFromNib];
    NSMutableArray *viewControllers = [[NSMutableArray alloc] initWithCapacity:2];
    [self setViewControllers:viewControllers];
    [viewControllers release];
    [self setTableDisplayCounter:0];
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
    CGFloat originX = 50.0000f * ([self tableDisplayCounter] + 1) + CGPointZero.x;
    CGFloat originY = originX;
    [[viewController view] setFrame: CGRectMake(originX,
                                                originY,
                                                180.0000f, 200.0000f)];
    [[viewController view] setBackgroundColor:[UIColor blueColor]];
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
    [self removeViewControllers:[NSSet setWithArray:[self viewControllers]]];
    [self setTableDisplayCounter:0];
    UIStoryboard *sb = [[UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil] retain];
    NSArray *tables = [[RptqDocument tablesForActiveDocument] retain];
    for (RptqTable *table in tables) {
        NSLog(@"Table: %@", table);
        
        MTQueryBuilderAdvancedSchemaViewController *viewController = [[sb instantiateViewControllerWithIdentifier:@"MTQueryBuilderAdvancedSchemaViewControllerIdentifier"] retain];
        [viewController setTableObjectId:[table objectID]];
        [self addViewController:viewController];
        [viewController release];
    }
    [tables release];
    [sb release];
}

- (void)viewDidUnload {
    [self setToolbarTop:nil];
    [self setToolbarBottom:nil];
    [super viewDidUnload];
}
@end
