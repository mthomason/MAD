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
@property (nonatomic, strong) UIViewController <MTToolboxViewControllerProtocol> *style;

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

     UIViewController <MTToolboxViewControllerProtocol> *style = self.childViewControllers.firstObject;
    self.style = style;

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
    
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if ([keyPath isEqualToString:self.keyPathDocument]) {
    
        id <MTToolboxViewControllerProtocol> delegate = (id <MTToolboxViewControllerProtocol>)self.childViewControllers.firstObject;
        [delegate setDocument:self.document];

    } else if ([keyPath isEqualToString:self.keyPathSelectedObjectIds]) {
        
        id <MTToolboxViewControllerProtocol> delegate = (id <MTToolboxViewControllerProtocol>)self.childViewControllers.firstObject;
        [delegate setSelectedDocumentObjects:self.selectedObjectIds];
    
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.style setDocument:self.document];
    [self.style setSelectedDocumentObjects:self.selectedObjectIds];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)valueChanged:(id)sender {
    
    UIViewController <MTToolboxViewControllerProtocol> *viewControllerToShow = nil;
    switch (((UISegmentedControl *)sender).selectedSegmentIndex) {
        case 0:
            viewControllerToShow = self.style;
            break;
            
        case 1:
            viewControllerToShow = self.layout;
            break;
            
        case 2:
            viewControllerToShow = self.format;
            break;
            
        default:
            break;
    }
    [viewControllerToShow setSelectedDocumentObjects: self.selectedObjectIds];
    viewControllerToShow.document = self.document;
    viewControllerToShow.modalPresentationStyle = UIModalPresentationOverCurrentContext;
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

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
