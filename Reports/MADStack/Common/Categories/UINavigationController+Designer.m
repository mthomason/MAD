//
//  UINavigationController+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UINavigationController+Designer.h"
#import "MADStoryboard.h"
#import "UIStoryboard+Licensing.h"
#import "UIStoryboard+InformationTable.h"
#import "UIStoryboard+NewDocument.h"
#import "UIStoryboard+ObjectSelector.h"

static NSString * const FontPicker      = @"MADIdentifierStoryboardFontPicker";
static NSString * const NewDocument     = @"MADIdentifierOpenDocumentStart";
static NSString * const AppInformation  = @"MADIdentifierInformationNavigationController";
static NSString * const Licensing       = @"MTNavigationControllerLicensing";
static NSString * const AggregateAdd        = @"MADIdentifierDocumentObjectNewAggregateNavigationController";
static NSString * const ElementPicker       = @"MADIdentifierNavigationControllerDocumentObjectSelector";

@implementation UINavigationController (Designer)

+ (instancetype)newNavigationControllerAppInformation {
    UIStoryboard *storyboard = [UIStoryboard newStorybaordInformationTable];
    UINavigationController *appInfo;
    appInfo = [storyboard instantiateViewControllerWithIdentifier: AppInformation];
    appInfo.modalPresentationStyle = UIModalPresentationPopover;
    appInfo.preferredContentSize = CGSizeMake(420.0000f, 480.0000f);
    return appInfo;
}

+ (instancetype)newNavigationControllerLicensing {
    UIStoryboard *storyboard = [MADStoryboard newStoryboardLicensing];
    return [storyboard instantiateViewControllerWithIdentifier:Licensing];
}

+ (instancetype)newNavigationControllerNewDocument {
    UIStoryboard *storyboard = [UIStoryboard newStoryboardNewDocument];
    UINavigationController *r = [storyboard instantiateViewControllerWithIdentifier:NewDocument];
    return r;
}

+ (instancetype)newNavigationControllerToolbox {
    UIStoryboard *storyboardToolbox = [MADStoryboard newStoryboardToolbox];
    UINavigationController *navigationControllerToolbox = [storyboardToolbox instantiateInitialViewController];
    return navigationControllerToolbox;
}

+ (instancetype)newNavigationControllerFontPicker {
    UIStoryboard *storyboard = [MADStoryboard newStoryboardToolbox];
    return [storyboard instantiateViewControllerWithIdentifier:FontPicker];
}

+ (instancetype)newNavigationControllerAggregateAdd {
    UIStoryboard *storyboard = [UIStoryboard ObjectSelector];
    return [storyboard instantiateViewControllerWithIdentifier:AggregateAdd];
}

+ (instancetype)newNavigationControllerElementPicker {
    UIStoryboard *storyboard = [UIStoryboard ObjectSelector];
    id navigationController = [storyboard instantiateViewControllerWithIdentifier:ElementPicker];
    return navigationController;
}

@end
