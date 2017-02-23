//
//  MADAlertControllerPromptStorage.m
//  MADExplorer
//
//  Created by Michael on 2/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADAlertControllerPromptStorage.h"

@implementation MADAlertControllerPromptStorage

+ (instancetype)newAlertControllerPromptStorage:(void (^)())handlerLocal
                                          cloud:(void (^)())handlerCloud {

    NSString *MADTitleButtonLocalOnly        = @"Local Only";
    NSString *MADTitleButtonCloud            = @"iCloud";
    NSString *MADTitleChooseStorageOptions   = @"Choose Storage Option";
    NSString *MADMessageChooseStorageOptions = @"Do you want to store documents "
                                                    @"in iCloud or "
                                                    @"only on this device?";
    NSString *title, *message, *localOnlyActionTitle, *cloudActionTitle;
    id storageController;
    UIAlertAction *option;
    title = NSLocalizedString(MADTitleChooseStorageOptions, MADTitleChooseStorageOptions),
    message = NSLocalizedString(MADMessageChooseStorageOptions, MADMessageChooseStorageOptions),
    localOnlyActionTitle = NSLocalizedString(MADTitleButtonLocalOnly, MADTitleButtonLocalOnly),
    cloudActionTitle = NSLocalizedString(MADTitleButtonCloud, MADTitleButtonCloud);
    
    storageController = [UIAlertController alertControllerWithTitle: title
                                                            message: message
                                                     preferredStyle: UIAlertControllerStyleAlert];
    
    option = [UIAlertAction actionWithTitle: localOnlyActionTitle
                                      style: UIAlertActionStyleDefault
                                    handler: handlerLocal];
    [storageController addAction:option];
    
    option = [UIAlertAction actionWithTitle: cloudActionTitle
                                      style: UIAlertActionStyleDefault
                                    handler: handlerCloud];
    [storageController addAction:option];

    return storageController;
}

@end
