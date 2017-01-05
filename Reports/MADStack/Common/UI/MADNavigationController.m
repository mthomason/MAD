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

//#import "MADViewerController.h"
#import "MADNavigationControllerViewer.h"

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
    @property (readwrite, nonatomic, assign) BOOL _completedFirstLayout;
    @property (readwrite, nonatomic, assign) UIStatusBarStyle statusBarStyleDefault;
@end

@implementation MADNavigationController

@synthesize document = _document;

+ (void)initialize {
    [super initialize];

    if (self == [MADNavigationController self]) {
        @autoreleasepool {
            NSArray<Class <UIAppearanceContainer>> * classes;
            UINavigationBar *navigationBar;
            UIToolbar *toolbar;
            
            classes = [[NSArray alloc] initWithObjects: self, nil];
            navigationBar = [UINavigationBar appearanceWhenContainedInInstancesOfClasses:classes];
            navigationBar.barTintColor = [UIColor clearColor];
            navigationBar.translucent = YES;

            toolbar = [UIToolbar appearanceWhenContainedInInstancesOfClasses:classes];
            UIColor *white, *blue;
            white = [MADColorEverydayApps newColorWhite];
            blue = [MADColorEverydayApps newColorBlue];
            toolbar.tintColor = white;
            toolbar.barTintColor = blue;
            toolbar.barStyle = UIBarStyleBlack;
            toolbar.translucent = YES;
        }
    }
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

    if ([controller respondsToSelector:@selector(setControllerType:)]) {
        [controller setControllerType: type];
    }
    
    return controller;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        __completedFirstLayout = NO;
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

#pragma mark -
#pragma mark UIViewController handle storyboard segue

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

#pragma mark -
#pragma mark UIViewControllerTransitioningDelegate

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

#pragma mark -
#pragma mark MADViewControllerDocumentProtocol

- (void)setDocument:(MADocument *)document {
    if (_document != document) {
        _document = document;
    }
}

#pragma mark -
#pragma mark IBActions

- (IBAction)done:(id)sender {
    for (UIViewController *viewController in self.childViewControllers) {
        if ([viewController respondsToSelector:@selector(done:)]) {
            [viewController performSelectorOnMainThread: @selector(done:)
                                             withObject: self
                                          waitUntilDone: NO];
        }
    }
}

@end
