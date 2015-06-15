//
//  UIViewController+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIViewController+Designer.h"
#import "UIStoryboard+Designer.h"

static NSString * const MADIdentifierLayoutSettingsViewController = @"MTReportDesignerSectionLayoutSettingsViewControllerIdentifier";

@implementation UIViewController (Designer)

+ (instancetype)layoutSettingsViewController {
    UIStoryboard *designer = [UIStoryboard designer];
    return [designer instantiateViewControllerWithIdentifier:MADIdentifierLayoutSettingsViewController];
}

+ (instancetype)fileManager {
    UIStoryboard *designer = [UIStoryboard designer];
    return [designer instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardOpenFileViewController"];
}

+ (instancetype)queryNavigationController {
    UIStoryboard *designer = [UIStoryboard designer];
    return [designer instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardQueryNavigationController"];
}

+ (instancetype)queryViewController {
    UIStoryboard *designer = [UIStoryboard designer];
    return [designer instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardQueryViewController"];
}

+ (instancetype)queryContainerController {
    UIStoryboard *designer = [UIStoryboard designer];
    return [designer instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardQueryContainerController"];
}

+ (instancetype)viewerNavigationController {
    UIStoryboard *designer = [UIStoryboard designer];
    return [designer instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardViewerNavigationController"];
}

+ (instancetype)designerViewController {
    UIStoryboard *designer = [UIStoryboard designer];
    return [designer instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardDesignerViewController"];
}

+ (instancetype)designerNavigationController {
    UIStoryboard *designer = [UIStoryboard designer];
    return [designer instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardDesignerNavigationController"];
}

+ (instancetype)viewerViewController {
    UIStoryboard *designer = [UIStoryboard designer];
    return [designer instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardViewerViewController"];
}

+ (instancetype)initalViewController {
    UIStoryboard *designer = [UIStoryboard designer];
    return [designer instantiateInitialViewController];
}

@end
