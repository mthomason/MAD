//
//  MADFileLocationManager.h
//  MAD Explorer
//
//  Created by Michael Thomason on 9/12/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADExplorer_MADFileLocationManager_h
#define MADExplorer_MADFileLocationManager_h

#import <Foundation/NSObject.h>
#import <MADFileManager/MADFileManager.h>
#import <MADExplorer/MADDocumentState.h>

@class MADFilesController;

@protocol MADFileLocationManagerDelegate <NSObject>

    @required
        - (void)didConfigureFilesController:(MADFilesController *)filesController;
        - (void)didDisconnectFromCloud:(id)sender;
        - (void)setupFileStorageLocationsForLocal:(id)sender;

        - (NSString *)groupIdentifier;
        - (NSString *)ubiquityIdentifier;
        - (NSString *)fileExtention;


        - (UIAlertController *)promotStorageOptionLocal:(void (^)())handlerLocal
                                                  cloud:(void (^)())handlerCloud;
        - (UIAlertController *)promotCloudSignOut:(void (^)(UIAlertAction *action))handler;


    @optional
        - (void)startLongRunningActivity;
        - (void)completedLongRunningActivity;

@end

@interface MADFileLocationManager : NSObject

    @property (nonatomic, weak) UIViewController <MADFileLocationManagerDelegate> *delegate;
    @property (nonatomic, strong, readonly) MADFilesController *filesController;

    - (void)getUserCloudPrefs;

@end

#endif
