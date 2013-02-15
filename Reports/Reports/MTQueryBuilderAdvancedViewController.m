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
    [[viewController view] setFrame: CGRectMake(CGPointZero.x, CGPointZero.y, 320.0000f, 200.0000f)];
    [[viewController view] setBackgroundColor:[UIColor blueColor]];
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

- (void)reloadDocument:(MNSDocumentReport *)documentReport {
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

@end
