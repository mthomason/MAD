//
//  MADToolboxViewController.m
//  MAD
//
//  Created by Michael Thomason on 10/28/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADToolboxViewController.h"

#import <UIKit/UIAccessibility.h>
#import <UIKit/UIPresentationController.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UISegmentedControl.h>
#import <UIKit/UITableViewController.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIGraphics.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import "MTToolboxViewControllerProtocol.h"
#import "MADStoryboard.h"
#import "UINavigationController+Designer.h"


NSString * const MADIdentifierStoryboardLayout      = @"MADIdentifierStoryboardLayout";
NSString * const MADIdentifierStoryboardFormat      = @"MADIdentifierStoryboardFormat";
NSString * const MADIdentifierStoryboardStyle       = @"MADIdentifierStoryboardStyle";

const CGFloat MADNavigationBarSizeHeightNormal = 44.0000f;
const CGFloat MADNavigationBarSizeHeightConstrained = 32.0000f;


@interface MADToolboxViewController ()

    @property (nonatomic, strong) UIViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *layout;
    @property (nonatomic, strong) UIViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *format;
    @property (nonatomic, strong) UINavigationController *styleNavigationController;

    @property (nonatomic, weak) IBOutlet UISegmentedControl *sceneSelector;
    @property (nonatomic, weak) IBOutlet UINavigationItem *navigationItemSceneSelector;

    @property (nonatomic, assign) UIModalTransitionStyle segmentedControlActionStyle;

    @property (nonatomic, weak) UIViewController *currentViewController;

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
        
        
        UIStoryboard *storyboard = [MADStoryboard newToolbox];
        UIViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *layout = [storyboard instantiateViewControllerWithIdentifier:MADIdentifierStoryboardLayout];
        UIViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *format = [storyboard instantiateViewControllerWithIdentifier:MADIdentifierStoryboardFormat];
        UINavigationController *styleNavigationController = [UINavigationController navigationControllerFontPicker];
        
        self.layout = layout;
        self.format = format;
        
        self.styleNavigationController = styleNavigationController;
        self.currentViewController = self.styleNavigationController;

        self.segmentedControlActionStyle = UIModalTransitionStyleCoverVertical;
        
        [self addObserver: self
               forKeyPath: [MADToolboxViewController keyPathSelectedObjectIds]
                  options: (NSKeyValueObservingOptions)0        //Can pass zero according to docs
                  context: NULL];
        
        [self addObserver: self
               forKeyPath: [MADToolboxViewController keyPathDocument]
                  options: (NSKeyValueObservingOptions)0        //Can pass zero according to docs
                  context: NULL];
        

    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.modalPresentationStyle = UIModalPresentationPopover;
    self.modalTransitionStyle = self.segmentedControlActionStyle;
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = YES;
    self.sceneSelector.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = [MADColorEverydayApps newColorBlue];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.styleNavigationController popToRootViewControllerAnimated:animated];

    self.clearsBackground = self.clearsBackground;
    UITableViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *style = (UITableViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *)self.styleNavigationController.viewControllers.firstObject;
    [style setDocument:self.document];
    [style setSelectedDocumentObjects:self.selectedObjectIds];

}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if (self.firstTimeViewWillLayoutSubviews) {
        [self showInitalChildViewController];
    }
}

- (void)showInitalChildViewController {
    
    UIViewController *viewControllerToShow = self.styleNavigationController;
    self.currentViewController = viewControllerToShow;

    UIViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *viewControllerToUpdate = nil;    
    viewControllerToUpdate = (UITableViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *)self.styleNavigationController.viewControllers.firstObject;
    
    [viewControllerToUpdate setSelectedDocumentObjects: self.selectedObjectIds];
    viewControllerToUpdate.document = self.document;
    viewControllerToShow.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    viewControllerToShow.modalTransitionStyle = self.segmentedControlActionStyle;
    
    viewControllerToShow.view.frame = self.view.bounds;
    [self addChildViewController:viewControllerToShow];
    
    [viewControllerToShow beginAppearanceTransition:YES animated:NO];
    [self.view addSubview:viewControllerToShow.view];
    [viewControllerToShow didMoveToParentViewController:self];
    [viewControllerToShow endAppearanceTransition];

}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
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

- (void)showStyle {
    
    UIViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *viewControllerToUpdate = (UITableViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *)self.styleNavigationController.viewControllers.firstObject;

    UIViewController *viewControllerToShow = self.styleNavigationController;
    self.currentViewController = viewControllerToShow;

    UIViewAnimationOptions options = UIViewAnimationOptionTransitionFlipFromRight;
    options = UIViewAnimationOptionTransitionCrossDissolve;
    [viewControllerToUpdate setSelectedDocumentObjects: self.selectedObjectIds];
    viewControllerToUpdate.document = self.document;
    viewControllerToShow.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    viewControllerToShow.modalTransitionStyle = self.segmentedControlActionStyle;
    
    UIViewController *viewControllerToHide = self.childViewControllers.firstObject;
    viewControllerToShow.view.frame = self.view.bounds;
    
    [self addChildViewController:viewControllerToShow];
    [viewControllerToHide willMoveToParentViewController:nil];
    [viewControllerToShow beginAppearanceTransition:YES animated:YES];
    [self.styleNavigationController.topViewController beginAppearanceTransition:YES animated:YES];
    
    [self transitionFromViewController: viewControllerToHide
                      toViewController: viewControllerToShow
                              duration: 0.23232323f
                               options: options
                            animations:^{ } completion:^(BOOL finished) {
                                if (finished) {
                                    [viewControllerToHide removeFromParentViewController];
                                    [viewControllerToShow didMoveToParentViewController:self];
                                    [((UINavigationController *)viewControllerToShow).topViewController didMoveToParentViewController:self];

                                }
                                
                            }];

}

- (IBAction)valueChanged:(id)sender {

    UIViewController *viewControllerToShow = nil;
    UIViewController <MTToolboxViewControllerProtocol, MADToolboxDisplayProtocol> *viewControllerToUpdate = nil;
    UIViewAnimationOptions options;

    switch (((UISegmentedControl *)sender).selectedSegmentIndex) {
    
        case 0:
            
            [self showStyle];   //Handles this case alone...
            return;
            
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
            viewControllerToShow = self.layout;
            viewControllerToUpdate = self.layout;
            break;
    }

    self.currentViewController = viewControllerToShow;
    
    options = UIViewAnimationOptionTransitionCrossDissolve;
    [viewControllerToUpdate setSelectedDocumentObjects: self.selectedObjectIds];
    viewControllerToUpdate.document = self.document;
    viewControllerToShow.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    viewControllerToShow.modalTransitionStyle = self.segmentedControlActionStyle;
    
    UIViewController *viewControllerToHide = self.childViewControllers.firstObject;

    viewControllerToShow.view.frame = self.view.bounds;
    
    MADToolboxViewController * __weak weakself = self;
    [self addChildViewController:viewControllerToShow];
    [viewControllerToHide willMoveToParentViewController:nil];
    [viewControllerToShow beginAppearanceTransition:YES animated:YES];
    
    
    [self transitionFromViewController: viewControllerToHide
                      toViewController: viewControllerToShow
                              duration: 0.23232323f
                               options: options
                            animations:^{
                                
                            }
                            completion:^(BOOL finished) {
                                if (finished) {
                                    [viewControllerToHide removeFromParentViewController];
                                    [viewControllerToShow didMoveToParentViewController:weakself];
                                    [viewControllerToShow endAppearanceTransition];
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

- (BOOL)accessibilityPerformEscape {
    return [self.navigationController.presentationController accessibilityPerformEscape];
}

@end
