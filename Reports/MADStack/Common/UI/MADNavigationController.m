//
//  UINavigationControllerModelControllers.m
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationController.h"

#import <UIKit/UIStoryboard.h>
#import <UIKit/UIViewController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UITabBarController.h>
#import <UIKit/UIToolbar.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/UIViewController.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import "MADViewerController.h"

#import "MADTransparentPresentationController.h"

static NSString * const MADStoryboardInformationTable   = @"MADStoryboardInformationTable";
static NSString * const MADStoryboardLicensing          = @"MADStoryboardLicensing";
static NSString * const MADStoryboardNewDocument        = @"MADStoryboardNewDocument";
static NSString * const MADStoryboardToolbox            = @"MADStoryboardToolbox";
static NSString * const MADStoryboardObjectSelector     = @"MADStoryboardObjectSelector";

static NSString * const MADIdentifierNavigationControllerInformation                = @"MADIdentifierNavigationControllerInformation";
static NSString * const MADIdentifierNavigationControllerLicensing                  = @"MADIdentifierNavigationControllerLicensing";
static NSString * const MADIdentifierNavigationControllerDocumentNew                = @"MADIdentifierNavigationControllerDocumentNew";
static NSString * const MADIdentifierNavigationControllerFontPicker                 = @"MADIdentifierNavigationControllerFontPicker";
static NSString * const MADIdentifierNavigationControllerDocumentObjectNewAggregate = @"MADIdentifierNavigationControllerDocumentObjectNewAggregate";
static NSString * const MADIdentifierNavigationControllerDocumentObjectSelector     = @"MADIdentifierNavigationControllerDocumentObjectSelector";

@interface MADNavigationController ()
    @property (readwrite, nonatomic, assign) MADNavigationControllerType controllerType;
@end

@interface MADNavigationControllerViewer : MADNavigationController

@end

@interface MADNavigationControllerViewer ()
    @property (nonatomic, strong) MADViewerController *viewerController;
@end

@implementation MADNavigationController

@synthesize document = _document;

+ (void)initialize {
    [super initialize];
    if (self != [MADNavigationController self]) return;
        
    NSArray<Class <UIAppearanceContainer>> * classes;
    UINavigationBar *appearanceProxy;
    
    classes = [[NSArray alloc] initWithObjects: self, nil];
    appearanceProxy = [UINavigationBar appearanceWhenContainedInInstancesOfClasses:classes];
    appearanceProxy.barTintColor = [UIColor clearColor];
    
}

+ (instancetype)newNavigationController:(MADNavigationControllerType)type {

    id controller = nil, controllerID = nil,
        storyboardID = nil, bundle = nil, storyboard = nil;
    
    switch (type) {

        case MADNavigationControllerTypeInformation:
            storyboardID = MADStoryboardInformationTable;
            controllerID = MADIdentifierNavigationControllerInformation;
            bundle = [NSBundle mainBundle];
            break;
            
        case MADNavigationControllerTypeLicensing:
            storyboardID = MADStoryboardLicensing;
            controllerID = MADIdentifierNavigationControllerLicensing;
            bundle = [NSBundle mainBundle];
            break;
            
        case MADNavigationControllerTypeNewDocument:
            storyboardID = MADStoryboardNewDocument;
            controllerID = MADIdentifierNavigationControllerDocumentNew;
            bundle = [NSBundle mainBundle];
            break;
            
        case MADNavigationControllerTypeToolbox:
            storyboardID = MADStoryboardToolbox;
            bundle = [NSBundle mainBundle];
            break;
            
        case MADNavigationControllerTypeFontPicker:
            storyboardID = MADStoryboardToolbox;
            controllerID = MADIdentifierNavigationControllerFontPicker;
            bundle = [NSBundle mainBundle];
            break;

        case MADNavigationControllerTypeAggregateAdd:
            storyboardID = MADStoryboardObjectSelector;
            controllerID = MADIdentifierNavigationControllerDocumentObjectNewAggregate;
            bundle = [NSBundle mainBundle];
            break;
            
        case MADNavigationControllerTypeElementPicker:
            storyboardID = MADStoryboardObjectSelector;
            controllerID = MADIdentifierNavigationControllerDocumentObjectSelector;
            bundle = [NSBundle mainBundle];
            break;
            
        case MADNavigationControllerTypeViewer:
            controller = [[MADNavigationControllerViewer alloc] init];
            break;
            
        default:
            break;
            
    }
    
    if (controller == nil) {
        if (storyboardID != nil) {
            
            storyboard = [UIStoryboard storyboardWithName: storyboardID bundle: bundle];
            controller = controllerID != nil ?
                [storyboard instantiateViewControllerWithIdentifier: controllerID] :
                [storyboard instantiateInitialViewController];
            
        } else {
            controller = [[self alloc] initWithNavigationBarClass: nil
                                                     toolbarClass: nil];
        }
    }

    [controller setControllerType: type];
    
    return controller;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    UIColor *white, *blue;
    white = [MADColorEverydayApps newColorWhite];
    blue = [MADColorEverydayApps newColorBlue];
    self.toolbar.tintColor = white;
    self.toolbar.barTintColor = blue;
    self.toolbar.barStyle = UIBarStyleBlack;
    self.toolbar.translucent = YES;
    self.navigationBar.translucent = YES;

    NSMutableDictionary *titleTextAttributes = self.navigationBar.titleTextAttributes.mutableCopy;
    titleTextAttributes[NSForegroundColorAttributeName] = [UIColor whiteColor];
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)showViewController:(UIViewController *)vc sender:(id)sender {
    if ([vc conformsToProtocol:@protocol(MADViewControllerDocumentProtocol)]) {
        ((id <MADViewControllerDocumentProtocol>)vc).document = _document;
    }
    [super showViewController:vc sender:sender];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.isBeingDismissed) {
        NSArray *viewControllers = [[NSArray alloc] init];
        [self setViewControllers:viewControllers animated:animated];
    }
}

- (UITabBarItem *)tabBarItem {
    UITabBarItem *tabBarItems;
    UITabBarController *tabBarController = (UITabBarController *)self.topViewController;
    tabBarItems = tabBarController.tabBarItem;
    return tabBarItems;
}

- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
                                      fromViewController:(UIViewController *)fromViewController
                                              withSender:(id)sender {
    
    UIViewController *foundViewController;
    
    for (UIViewController *childViewController in self.viewControllers) {
        foundViewController = [childViewController viewControllerForUnwindSegueAction: action
                                                                   fromViewController: fromViewController
                                                                           withSender: sender];
        
        if (foundViewController) {
            break;
        }
    }
    
    if (!foundViewController) {
        foundViewController = [super viewControllerForUnwindSegueAction: action
                                                     fromViewController: self
                                                             withSender: sender];
    }
    
    return [super viewControllerForUnwindSegueAction: action
                                  fromViewController: self
                                          withSender: sender];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented
                                                      presentingViewController:(UIViewController *)presenting
                                                          sourceViewController:(UIViewController *)source {
    UIPresentationController *result = nil;
    if (presented == self || presenting == self) {
        result = [[MADTransparentPresentationController alloc] initWithPresentedViewController:presented
                                                                      presentingViewController:presenting];
    }
    return result;
}

- (IBAction)done:(id)sender {
    for (UIViewController *viewController in self.childViewControllers) {
        if ([viewController respondsToSelector:@selector(done:)]) {
            [viewController performSelectorOnMainThread: @selector(done:)
                                             withObject: self
                                          waitUntilDone: NO];
        }
    }
}

- (void)setDocument:(MADocument *)document {
    if (_document != document) {
        _document = document;
    }
}

@end

@implementation MADNavigationControllerViewer : MADNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    id rootViewController = [MADViewerController newViewerController: self.document];
    self.viewerController = rootViewController;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self pushViewController:self.viewerController animated:animated];
    
}

@end
