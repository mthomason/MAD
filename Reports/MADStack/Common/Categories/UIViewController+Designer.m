//
//  UIViewController+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIViewController+Designer.h"
#import "MADStoryboard.h"

static NSString * const MADIdentifierLayoutSettingsViewController = @"MTReportDesignerSectionLayoutSettingsViewControllerIdentifier";

@implementation UIViewController (Designer)

+ (instancetype)layoutSettingsViewController {
    UIStoryboard *designer = [MADStoryboard newStoryboardDesigner];
    return [designer instantiateViewControllerWithIdentifier:MADIdentifierLayoutSettingsViewController];
}

+ (instancetype)fileManager {
    UIStoryboard *designer = [MADStoryboard newStoryboardDesigner];
    return [designer instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardOpenFileViewController"];
}

/*+ (instancetype)queryNavigationController {
    UIStoryboard *designer = [UIStoryboard Designer];
    return [designer instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardQueryNavigationController"];
}*/

+ (instancetype)queryViewController {
    UIStoryboard *designer = [MADStoryboard newStoryboardDesigner];
    return [designer instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardQueryViewController"];
}

+ (instancetype)queryContainerController {
    UIStoryboard *designer = [MADStoryboard newStoryboardDesigner];
    return [designer instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardQueryContainerController"];
}

+ (instancetype)viewerNavigationController {
    UIStoryboard *designer = [MADStoryboard newStoryboardDesigner];
    return [designer instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardViewerNavigationController"];
}

+ (instancetype)designerViewController {
    UIStoryboard *designer = [MADStoryboard newStoryboardDesigner];
    return [designer instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardDesignerViewController"];
}

+ (instancetype)designerNavigationController {
    UIStoryboard *designer = [MADStoryboard newStoryboardDesigner];
    return [designer instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardDesignerNavigationController"];
}

+ (instancetype)viewerViewController {
    UIStoryboard *designer = [MADStoryboard newStoryboardDesigner];
    return [designer instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardViewerViewController"];
}

+ (instancetype)initalViewController {
    UIStoryboard *designer = [MADStoryboard newStoryboardDesigner];
    return [designer instantiateInitialViewController];
}

@end
