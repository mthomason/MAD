//
//  UINavigationController+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UINavigationController+Designer.h"
#import "UIStoryboard+Designer.h"

static NSString * const FontPicker      = @"MADIdentifierStoryboardFontPicker";
static NSString * const AggregateAdd    = @"MTDocumentObjectNewAggregateNavigationControllerIdentifier";
static NSString * const ElementPicker   = @"MADIdentifierNavigationControllerDocumentObjectSelector";
static NSString * const NewDocument     = @"MADIdentifierOpenDocumentStart";
static NSString * const AppInformation  = @"MADIdentifierInformationNavigationController";
static NSString * const Licensing       = @"MTNavigationControllerLicensing";

@implementation UINavigationController (Designer)

+ (instancetype)AppInformation {
    UIStoryboard *storyboard = [UIStoryboard InformationTable];
    UINavigationController * appInfo = [storyboard instantiateViewControllerWithIdentifier: AppInformation];
    appInfo.modalPresentationStyle = UIModalPresentationPopover;
    appInfo.preferredContentSize = CGSizeMake(420.0000f, 480.0000f);
    return appInfo;
}

+ (instancetype)Licensing {
    UIStoryboard *storyboard = [UIStoryboard Licensing];
    return [storyboard instantiateViewControllerWithIdentifier:Licensing];
}

+ (instancetype)NewDocument {
    UIStoryboard *storyboard = [UIStoryboard NewDocument];
    return [storyboard instantiateViewControllerWithIdentifier:NewDocument];
}

+ (instancetype)navigationControllerToolbox {
    UIStoryboard *storyboardToolbox = [UIStoryboard Toolbox];
    UINavigationController *navigationControllerToolbox = [storyboardToolbox instantiateInitialViewController];
    return navigationControllerToolbox;
}

+ (instancetype)navigationControllerFontPicker {
    UIStoryboard *storyboard = [UIStoryboard Toolbox];
    return [storyboard instantiateViewControllerWithIdentifier:FontPicker];
}

+ (instancetype)aggregateAdd {
    UIStoryboard *storyboard = [UIStoryboard ObjectSelector];
    return [storyboard instantiateViewControllerWithIdentifier:AggregateAdd];
}

+ (instancetype)elementPicker {
    UIStoryboard *storyboard = [UIStoryboard ObjectSelector];
    return [storyboard instantiateViewControllerWithIdentifier:ElementPicker];
}

@end
