//
//  UIAlertController+Constructors.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/24/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIAlertController+Constructors.h"

@implementation UIAlertController (Constructors)

+ (UIAlertController *)alertControllerPromotCloudSignOut:(void (^)(UIAlertAction *action))handler {
    NSString *title = NSLocalizedString(@"iCloud Sign Out", nil);
    NSString *message = NSLocalizedString(@"You have signed out of the iCloud account previously used to store documents. Sign back in to access those documents.", nil);
    NSString *ok = NSLocalizedString(@"Dismiss", @"Dismiss");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle: title
                                                                             message: message
                                                                      preferredStyle: UIAlertControllerStyleAlert];
    UIAlertAction *actionKk = [UIAlertAction actionWithTitle: ok
                                                       style: UIAlertActionStyleDefault
                                                     handler: handler];
    [alertController addAction:actionKk];
    return alertController;
}

+ (UIAlertController *)alertControllerPromotStorageOption:(void (^)(UIAlertAction *action))handlerLocal
                                             handlerCloud:(void (^)(UIAlertAction *action))handlerCloud {

    NSString *title = NSLocalizedString(@"Choose Storage Option", nil);
    NSString *message = NSLocalizedString(@"Do you want to store documents in iCloud or only on this device?", nil);
    NSString *localOnlyActionTitle = NSLocalizedString(@"Local Only", nil);
    NSString *cloudActionTitle = NSLocalizedString(@"iCloud", nil);
    
    UIAlertController *storageController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *localOption = [UIAlertAction actionWithTitle:localOnlyActionTitle style:UIAlertActionStyleDefault handler:handlerLocal];
    [storageController addAction:localOption];
    
    UIAlertAction *cloudOption = [UIAlertAction actionWithTitle:cloudActionTitle style:UIAlertActionStyleDefault handler:handlerCloud];
    [storageController addAction:cloudOption];

    return storageController;
}

+ (UIAlertController *)alertControllerAddedDocument {
    NSString *title = NSLocalizedString(@"New Document", @"New Document");
    NSString *message = NSLocalizedString(@"Added document.", @"Added document.");
    NSString *ok = NSLocalizedString(@"Continue", @"Continue");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle: title
                                                                             message: message
                                                                      preferredStyle: UIAlertControllerStyleAlert];
    UIAlertAction *actionKk = [UIAlertAction actionWithTitle: ok
                                                       style: UIAlertActionStyleDefault
                                                     handler: nil];
    [alertController addAction:actionKk];
    return alertController;
}


@end
