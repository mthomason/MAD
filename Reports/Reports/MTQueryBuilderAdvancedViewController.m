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

@end

@implementation MTQueryBuilderAdvancedViewController

- (void)dealloc {
    [_viewControllers release];
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
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSArray *tables = [[RptqDocument tablesForActiveDocument] retain];
    for (RptqTable *table in tables) {
        NSLog(@"Table: %@", table);
        UIViewController *viewController = [[UIViewController alloc] init];
        [self addViewController:viewController];
        [viewController release];
    }
    [tables release];
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
    [[viewController view] setFrame: CGRectMake(CGPointZero.x, CGPointZero.y, 50.0000f, 50.0000f)];
    [[self view] addSubview:[viewController view]];
    [viewController didMoveToParentViewController:self];
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

@end
