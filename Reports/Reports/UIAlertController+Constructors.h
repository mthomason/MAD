//
//  UIAlertController+Constructors.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/24/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertController (Constructors)

+ (UIAlertController *)alertControllerPromotCloudSignOut:(void (^)(UIAlertAction *action))handler;
+ (UIAlertController *)alertControllerPromotStorageOption:(void (^)(UIAlertAction *action))handlerLocal
                                             handlerCloud:(void (^)(UIAlertAction *action))handlerCloud;
+ (UIAlertController *)alertControllerAddedDocument;

@end
