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


@property (nonatomic, assign) UIModalTransitionStyle segmentedControlActionStyle;

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

        self.segmentedControlActionStyle = UIModalTransitionStyleCoverVertical;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UINavigationController *styleNavigationController = self.childViewControllers.firstObject;
    self.styleNavigationController = styleNavigationController;
    
    self.modalPresentationStyle = UIModalPresentationPopover;
    self.modalTransitionStyle = self.segmentedControlActionStyle;
    
//    self.navigationController.navigationBar.barTintColor = [UIColor tintColorBlue];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
//    [self.navigationController.navigationBar.backIndicatorImage
//    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBar.opaque = NO;
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

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
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
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)valueChanged:(id)sender {
    
    UIViewController *viewControllerToShow = nil;
    UIViewController <MTToolboxViewControllerProtocol> *viewControllerToUpdate = nil;
    UIViewAnimationOptions options;
    switch (((UISegmentedControl *)sender).selectedSegmentIndex) {
        case 0:
            viewControllerToShow = self.styleNavigationController;
            viewControllerToUpdate = (UITableViewController <MTToolboxViewControllerProtocol> *)self.styleNavigationController.viewControllers.firstObject;
            options = UIViewAnimationOptionTransitionFlipFromRight;
            break;
            
        case 1:
            options = UIViewAnimationOptionTransitionFlipFromBottom;
            viewControllerToShow = self.layout;
            viewControllerToUpdate = self.layout;
            break;
            
        case 2:
            options = UIViewAnimationOptionTransitionFlipFromLeft;
            viewControllerToShow = self.format;
            viewControllerToUpdate = self.format;
            break;
            
        default:
            break;
    }
    options = UIViewAnimationOptionTransitionCrossDissolve;
    [viewControllerToUpdate setSelectedDocumentObjects: self.selectedObjectIds];
    viewControllerToUpdate.document = self.document;
    viewControllerToShow.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    viewControllerToShow.modalTransitionStyle = self.segmentedControlActionStyle;
  
    UIViewController *viewControllerToHide = self.childViewControllers.firstObject;

    viewControllerToShow.view.frame = self.view.bounds;
    [viewControllerToShow.view layoutIfNeeded];
    
    [self addChildViewController:viewControllerToShow];
    [viewControllerToHide willMoveToParentViewController:nil];
    
    __weak MADToolboxViewController *weakself = self;

    //UIImage *snapshotToHide = [self snapshot2: self.view.window];
    
    //CGRect cropSpot = [self.view convertRect:self.view.bounds toView:self.view.window];

    //UIImage *img3 = [self cropImage:snapshotToHide toRect:cropSpot];
    
    //UIImageView *maskingView = [[UIImageView alloc] initWithImage:img3];
    //maskingView.frame = viewControllerToHide.view.bounds;
    //[viewControllerToHide.view addSubview:maskingView];
    
    [viewControllerToShow beginAppearanceTransition:YES animated:YES];
    [self transitionFromViewController: viewControllerToHide
                      toViewController: viewControllerToShow
                              duration: 0.23232323f
                               options: options
                            animations:^{
                                [viewControllerToHide removeFromParentViewController];
                                [viewControllerToShow didMoveToParentViewController:weakself];
                                [viewControllerToShow endAppearanceTransition];
                            }
                            completion:^(BOOL finished) {
                                
                                if (finished) {
      //                              [maskingView removeFromSuperview];
                                }
                                
                            }];
}

- (UIImage *)cropImage:(UIImage *)image toRect:(CGRect)rect {
    if (self.traitCollection.displayScale > 1.0f) {
        rect = CGRectMake(rect.origin.x * self.traitCollection.displayScale,
                          rect.origin.y * self.traitCollection.displayScale,
                          rect.size.width * self.traitCollection.displayScale,
                          rect.size.height * self.traitCollection.displayScale);
    }
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, rect);
    UIImage *result = [UIImage imageWithCGImage: imageRef
                                          scale: self.traitCollection.displayScale
                                    orientation: image.imageOrientation];
    CGImageRelease(imageRef);
    return result;
}

- (UIImage *)snapshot2:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, view.traitCollection.displayScale);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];   // FIXME:  .. should be able to say YES, but it distorts the screen.. radar 17851775
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)setOptionsForViewController:(UIViewController <MTToolboxViewControllerProtocol> *)viewController {
    [viewController setSelectedDocumentObjects: self.selectedObjectIds];
    viewController.document = self.document;
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
