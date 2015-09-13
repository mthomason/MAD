//
//  MADFileManagerViewController.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/12/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, MTReportState) {
    MTReportStateOpen = 0,
    MTReportStateClosed
};

@class MADFilesController;

@protocol MADFileManagerViewControllerDelegate <NSObject>

    @required
        - (NSString *)groupIdentifier;
        - (NSString *)ubiquityIdentifier;
        - (NSString *)fileExtention;

        - (void)didConfigureFilesController:(MADFilesController *)filesController;

        - (UIAlertController *)promotStorageOptionLocal:(void (^)())handlerLocal
                                                  cloud:(void (^)())handlerCloud;
        - (UIAlertController *)promotCloudSignOut:(void (^)(UIAlertAction *action))handler;

    @optional
        - (void)startLongRunningActivity;
        - (void)completedLongRunningActivity;

@end

@interface MADFileManager : NSObject

    @property (nonatomic, weak) UIViewController <MADFileManagerViewControllerDelegate> *delegate;
    @property (nonatomic, strong, readonly) MADFilesController *filesController;

    - (void)getUserCloudPrefs;

@end
