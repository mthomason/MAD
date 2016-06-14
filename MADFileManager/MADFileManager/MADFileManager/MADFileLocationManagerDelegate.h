//
//  MADFileLocationManagerDelegate.h
//  MADFileManager
//
//  Created by Michael Thomason on 6/13/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADFileLocationManagerDelegate_h
#define MADFileLocationManagerDelegate_h

@class UIAlertController;
@class UIAlertAction;
@class NSString;
@class MADFilesController;

@protocol MADFileLocationManagerDelegate <NSObject>

    @required
        - (void)didConfigureFilesController:(MADFilesController *)filesController;
        - (void)didDisconnectFromCloud:(id)sender;

        - (NSString *)groupIdentifier;
        - (NSString *)ubiquityIdentifier;
        - (NSString *)fileExtention;


        - (UIAlertController *)promotCloudSignOut:(void (^)(UIAlertAction *action))handler;


    @optional
        - (void)startLongRunningActivity;
        - (void)completedLongRunningActivity;

@end

#endif /* MADFileLocationManagerDelegate_h */
