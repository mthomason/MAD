//
//  MADFileLocationManagerDelegate.h
//  MADFileManager
//
//  Created by Michael Thomason on 6/13/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADFileLocationManagerDelegate_h
#define MADFileLocationManagerDelegate_h

@class UIViewController, MADFilesController;

@protocol MADFileLocationManagerDelegate <NSObject>

	@required
		- (void)didConfigureFilesController:(MADFilesController *)filesController;
		- (void)didDisconnectFromCloud:(id)sender;

		+ (NSString *)groupIdentifier;
		+ (NSString *)ubiquityIdentifier;
		- (NSString *)fileExtention;

		@property (nonatomic, weak, readonly) UIViewController *presentingController;

	@optional
		- (void)startLongRunningActivity;
		- (void)completedLongRunningActivity;

@end

#endif /* MADFileLocationManagerDelegate_h */
