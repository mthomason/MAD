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

@implementation UINavigationController (Designer)

+ (instancetype)AppInformation {
    UIStoryboard *storyboard = [UIStoryboard InformationTable];
    UINavigationController * appInfo = [storyboard instantiateViewControllerWithIdentifier: AppInformation];
    appInfo.modalPresentationStyle = UIModalPresentationPageSheet;
    appInfo.preferredContentSize = CGSizeMake(320.0000f, 480.0000f);
    return appInfo;
}

+ (instancetype)NewDocument {
    UIStoryboard *storyboard = [UIStoryboard NewDocument];
    return [storyboard instantiateViewControllerWithIdentifier:NewDocument];
}

+ (instancetype)navigationControllerToolbox {
    UIStoryboard *storyboardToolbox = [UIStoryboard toolbox];
    UINavigationController *navigationControllerToolbox = [storyboardToolbox instantiateInitialViewController];
    return navigationControllerToolbox;
}

+ (instancetype)navigationControllerFontPicker {
    UIStoryboard *storyboard = [UIStoryboard toolbox];
    return [storyboard instantiateViewControllerWithIdentifier:FontPicker];
}

+ (instancetype)aggregateAdd {
    UIStoryboard *storyboard = [UIStoryboard objectSelector];
    return [storyboard instantiateViewControllerWithIdentifier:AggregateAdd];
}

+ (instancetype)elementPicker {
    UIStoryboard *storyboard = [UIStoryboard objectSelector];
    return [storyboard instantiateViewControllerWithIdentifier:ElementPicker];
}

@end
