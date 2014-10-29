//
//  MADToolboxViewController.m
//  MAD
//
//  Created by Michael Thomason on 10/28/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADToolboxViewController.h"
#import "MTToolboxViewControllerProtocol.h"

#import "UIColor+EverydayApps.h"

NSString * const MADIdentifierStoryboardLayout  = @"MADIdentifierStoryboardLayout";
NSString * const MADIdentifierStoryboardFormat  = @"MADIdentifierStoryboardFormat";
NSString * const MADIdentifierStoryboardStyle   = @"MADIdentifierStoryboardStyle";

@interface MADToolboxViewController ()

@property (nonatomic, strong) UIViewController <MTToolboxViewControllerProtocol> *layout;
@property (nonatomic, strong) UIViewController <MTToolboxViewControllerProtocol> *format;
@property (nonatomic, strong) UINavigationController *styleNavigationController;

@property (nonatomic, weak) IBOutlet UISegmentedControl *sceneSelector;

@property (nonatomic, strong) NSString *keyPathDocument;
@property (nonatomic, strong) NSString *keyPathSelectedObjectIds;

@end

@implementation MADToolboxViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {

    if (self = [super initWithCoder:aDecoder]) {
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName: @"MADToolbox"
                                                             bundle: [NSBundle mainBundle]];

        UIViewController <MTToolboxViewControllerProtocol> *layout = [storyboard instantiateViewControllerWithIdentifier:MADIdentifierStoryboardLayout];
        self.layout = layout;
        
        UIViewController <MTToolboxViewControllerProtocol> *format = [storyboard instantiateViewControllerWithIdentifier:MADIdentifierStoryboardFormat];
        self.format = format;

    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UINavigationController *styleNavigationController = self.childViewControllers.firstObject;
    self.styleNavigationController = styleNavigationController;
    
    //self.view.backgroundColor = [UIColor purpleColor];
    //self.view.opaque = NO;

//    self.style.tableView.backgroundColor = [UIColor redColor];
    
    //self.navigationController.view.backgroundColor = [UIColor clearColor];
    //self.navigationController.view.opaque = NO;

    self.modalPresentationStyle = UIModalPresentationPopover;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    self.navigationController.navigationBar.barTintColor = [UIColor tintColorBlue];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.sceneSelector.tintColor = [UIColor whiteColor];
    
    NSString *selectedObjectIds = NSStringFromSelector(@selector(selectedObjectIds));
    NSString *document = NSStringFromSelector(@selector(document));

    [self addObserver: self
           forKeyPath: selectedObjectIds
              options: 0
              context: NULL];

    [self addObserver: self
           forKeyPath: document
              options: 0
              context: NULL];

    self.keyPathSelectedObjectIds = selectedObjectIds;
    self.keyPathDocument = document;
    
        UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView *visualEffectsView = [[UIVisualEffectView alloc] initWithEffect:effect];
        visualEffectsView.frame = self.view.bounds;
        [self.view insertSubview:visualEffectsView atIndex:0];
//        self.view.backgroundColor = [UIColor clearColor];
//        self.view.backgroundColor = [UIColor clearColor];
//        self.view.opaque = NO;

    
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if ([keyPath isEqualToString:self.keyPathDocument]) {
    
        id <MTToolboxViewControllerProtocol> delegate = [self delegateForController:self.childViewControllers.firstObject];
        [delegate setDocument:self.document];

    } else if ([keyPath isEqualToString:self.keyPathSelectedObjectIds]) {
        
        id <MTToolboxViewControllerProtocol> delegate = [self delegateForController:self.childViewControllers.firstObject];
        [delegate setSelectedDocumentObjects:self.selectedObjectIds];
    
    }
}

- (UIViewController <MTToolboxViewControllerProtocol> *)delegateForController:(UIViewController *)controller {
    UIViewController <MTToolboxViewControllerProtocol> *delegate;
    if ([controller isKindOfClass:[UINavigationController class]]) {
        delegate = (UIViewController <MTToolboxViewControllerProtocol> *)((UINavigationController *)controller).viewControllers.firstObject;
    } else {
        delegate = (UIViewController <MTToolboxViewControllerProtocol> *)controller;
    }
    return delegate;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UITableViewController <MTToolboxViewControllerProtocol> *style = (UITableViewController <MTToolboxViewControllerProtocol> *)self.styleNavigationController.viewControllers.firstObject;
    [style setDocument:self.document];
    [style setSelectedDocumentObjects:self.selectedObjectIds];
    
    //UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    //UIVisualEffectView *visualEffectsView = [[UIVisualEffectView alloc] initWithEffect:effect];
    //BOOL isl = style.isViewLoaded;
    //visualEffectsView.frame = self.style.tableView.bounds;
    //self.style.tableView.backgroundView = visualEffectsView;
//    self.style.tableView.backgroundColor = [UIColor clearColor];
//    self.style.tableView.opaque = YES;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)valueChanged:(id)sender {
    
    UIViewController *viewControllerToShow = nil;
    UIViewController <MTToolboxViewControllerProtocol> *viewControllerToUpdate = nil;
    switch (((UISegmentedControl *)sender).selectedSegmentIndex) {
        case 0:
            viewControllerToShow = self.styleNavigationController;
            viewControllerToUpdate = (UITableViewController <MTToolboxViewControllerProtocol> *)self.styleNavigationController.viewControllers.firstObject;
            break;
            
        case 1:
            viewControllerToShow = self.layout;
            viewControllerToUpdate = self.layout;
            break;
            
        case 2:
            viewControllerToShow = self.format;
            viewControllerToUpdate = self.format;
            break;
            
        default:
            break;
    }
    [viewControllerToUpdate setSelectedDocumentObjects: self.selectedObjectIds];
    viewControllerToUpdate.document = self.document;
    viewControllerToShow.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    //viewControllerToShow.modalPresentationStyle = UIModalPresentationCurrentContext;
    viewControllerToShow.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  
    UIViewController *viewControllerToHide = self.childViewControllers.firstObject;

    viewControllerToShow.view.frame = self.view.bounds;
    [viewControllerToShow.view layoutIfNeeded];
    
    [self addChildViewController:viewControllerToShow];
    [viewControllerToHide willMoveToParentViewController:nil];
    
    __weak MADToolboxViewController *weakself = self;
    [self transitionFromViewController: viewControllerToHide
                      toViewController: viewControllerToShow
                              duration: 0.23232323f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                                [viewControllerToHide removeFromParentViewController];
                                [viewControllerToShow didMoveToParentViewController:weakself];
                            }
                            completion:^(BOOL finished) {
                                
                            }];
}

- (void)setOptionsForViewController:(UIViewController <MTToolboxViewControllerProtocol> *)viewController {
    [viewController setSelectedDocumentObjects: self.selectedObjectIds];
    viewController.document = self.document;
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
