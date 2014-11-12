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

CGFloat const MADNavigationBarSizeHeightNormal = 44.0000f;
CGFloat const MADNavigationBarSizeHeightConstrained = 32.0000f;


@interface MADToolboxViewController ()

@property (nonatomic, strong) UIViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *layout;
@property (nonatomic, strong) UIViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *format;
@property (nonatomic, strong) UINavigationController *styleNavigationController;

@property (nonatomic, weak) IBOutlet UISegmentedControl *sceneSelector;
@property (nonatomic, weak) IBOutlet UINavigationItem *navigationItemSceneSelector;

@property (nonatomic, assign) UIModalTransitionStyle segmentedControlActionStyle;

@property (nonatomic, assign) BOOL firstTimeViewWillAppear;

@end

@implementation MADToolboxViewController

- (void)dealloc {

    [self removeObserver: self
              forKeyPath: [MADToolboxViewController keyPathDocument]];

    [self removeObserver: self
              forKeyPath: [MADToolboxViewController keyPathSelectedObjectIds]];
    
}

+ (NSString *)keyPathSelectedObjectIds {
    NSString *selectedObjectIds = NSStringFromSelector(@selector(selectedObjectIds));
    return selectedObjectIds;
}

+ (NSString *)keyPathDocument {
    NSString *document = NSStringFromSelector(@selector(document));
    return document;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {

    if (self = [super initWithCoder:aDecoder]) {
        
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName: @"MADToolbox"
                                                             bundle: [NSBundle mainBundle]];

        UIViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *layout = [storyboard instantiateViewControllerWithIdentifier:MADIdentifierStoryboardLayout];
        self.layout = layout;
        
        UIViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *format = [storyboard instantiateViewControllerWithIdentifier:MADIdentifierStoryboardFormat];
        self.format = format;
        
        UINavigationController *styleNavigationController = [storyboard instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardFontPicker"];
        self.styleNavigationController = styleNavigationController;

        self.segmentedControlActionStyle = UIModalTransitionStyleCoverVertical;
        
        [self addObserver: self
               forKeyPath: [MADToolboxViewController keyPathSelectedObjectIds]
                  options: 0
                  context: NULL];
        
        [self addObserver: self
               forKeyPath: [MADToolboxViewController keyPathDocument]
                  options: 0
                  context: NULL];
        
        self.preferredContentSize = CGSizeMake(320.0000f, 400.0000f);

    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.firstTimeViewWillAppear = YES;
    
    self.modalPresentationStyle = UIModalPresentationPopover;
    self.modalTransitionStyle = self.segmentedControlActionStyle;
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBar.opaque = NO;
    self.sceneSelector.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = [UIColor tintColorBlue];
    [self valueChanged: self.sceneSelector];

}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

//    [self.navigationController.navigationBar sizeToFit];
    //[self.navigationItemSceneSelector.titleView sizeToFit];
    //[self.sceneSelector setNeedsLayout];
    //[self.navigationController.navigationBar sizeToFit];
    //CGFloat height = self.navigationController.navigationBar.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact ? MADNavigationBarSizeHeightConstrained : MADNavigationBarSizeHeightConstrained;
    //self.navigationController.navigationBar.frame = CGRectMake(self.navigationController.navigationBar.frame.origin.x, self.navigationController.navigationBar.frame.origin.y, self.navigationController.navigationBar.frame.size.width, height);
//    [self.navigationController.navigationItem.titleView sizeToFit];
    //[self.navigationController.view layoutSubviews];
    //[self.navigationController.navigationBar sizeToFit];
}

//- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
//    [coordinator animateAlongsideTransitionInView:self.view animation:^(id<UIViewControllerTransitionCoordinatorContext> context) {
//        [self.navigationController.navigationBar setNeedsLayout];
//    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
//
//    }];
//}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    //[self.navigationItemSceneSelector.titleView sizeToFit];
    //[self.sceneSelector setNeedsLayout];
}

- (void)setClearsBackground:(BOOL)clearsBackground {
    _clearsBackground = clearsBackground;
    self.layout.clearsBackground = clearsBackground;
    self.format.clearsBackground = clearsBackground;
    for (UIViewController <MADToolboxDisplayProtocol> *viewController in self.styleNavigationController.viewControllers) {
        viewController.clearsBackground = clearsBackground;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if ([keyPath isEqualToString:[MADToolboxViewController keyPathDocument]]) {
    
        id <MTToolboxViewControllerProtocol> delegate = [self delegateForController:self.childViewControllers.firstObject];
        [delegate setDocument:self.document];

    } else if ([keyPath isEqualToString:[MADToolboxViewController keyPathSelectedObjectIds]]) {
        
        id <MTToolboxViewControllerProtocol> delegate = [self delegateForController:self.childViewControllers.firstObject];
        [delegate setSelectedDocumentObjects:self.selectedObjectIds];
    
    }
}

- (UIViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *)delegateForController:(UIViewController *)controller {
    UIViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *delegate;
    if ([controller isKindOfClass:[UINavigationController class]]) {
        delegate = (UIViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *)((UINavigationController *)controller).viewControllers.firstObject;
    } else {
        delegate = (UIViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *)controller;
    }
    return delegate;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setClearsBackground: self.clearsBackground];
    UITableViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *style = (UITableViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *)self.styleNavigationController.viewControllers.firstObject;
    [style setDocument:self.document];
    [style setSelectedDocumentObjects:self.selectedObjectIds];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)valueChanged:(id)sender {

    id cvc = self.childViewControllers.firstObject;
    if ([cvc isEqual:self.styleNavigationController]) {
        id vvc = self.styleNavigationController.visibleViewController;
        if ([vvc isEqual:self.styleNavigationController.viewControllers.firstObject] == NO) {
            [self.styleNavigationController popToViewController:self.styleNavigationController.viewControllers.firstObject
                                                       animated:YES];
        }

    }
    
    UIViewController *viewControllerToShow = nil;
    UIViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *viewControllerToUpdate = nil;
    UIViewAnimationOptions options;

    switch (((UISegmentedControl *)sender).selectedSegmentIndex) {
    
        case 0:
        
            viewControllerToUpdate = (UITableViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *)self.styleNavigationController.viewControllers.firstObject;
            viewControllerToShow = self.styleNavigationController;
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
    
    if (viewControllerToHide != nil) {
        [self addChildViewController:viewControllerToShow];
        [viewControllerToHide willMoveToParentViewController:nil];
        
        __weak MADToolboxViewController *weakself = self;
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
                                    
                                }];
    } else {
        [self addChildViewController:viewControllerToShow];
        __weak MADToolboxViewController *weakself = self;
        [viewControllerToShow beginAppearanceTransition:YES animated:NO];
        [self.view addSubview:viewControllerToShow.view];
        [viewControllerToShow didMoveToParentViewController:weakself];
        [viewControllerToShow endAppearanceTransition];
    }
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
