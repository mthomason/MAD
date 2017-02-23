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

#import "MADNavigationControllerViewer.h"
#import "MADNavigationControllerDesigner.h"
#import "MADNavigationControllerQuery.h"

#import "MADDesignerNavigationBar.h"
#import "MADViewerNavigationBar.h"

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
    //@property (readwrite, nonatomic, assign) UIStatusBarStyle statusBarStyleDefault;
@end

@implementation MADNavigationController

@dynamic document;

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
            controller = [[MADNavigationControllerViewer alloc] initWithNavigationBarClass: [MADViewerNavigationBar class]
                                                                              toolbarClass: nil];
            break;
            
        case MADNavigationControllerTypeDesigner:
            controller = [[MADNavigationControllerDesigner alloc] initWithNavigationBarClass: [MADDesignerNavigationBar class]
                                                                                toolbarClass: nil];
            break;

        case MADNavigationControllerTypeQuery:
            controller = [[MADNavigationControllerQuery alloc] init];
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
