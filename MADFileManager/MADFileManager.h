//
//  MADFileManager.h
//  MADFileManager
//
//  Created by Michael Thomason on 9/10/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import <Foundation/NSObjCRuntime.h>

//! Project version number for MADFileManager.
FOUNDATION_EXPORT double MADFileManagerVersionNumber;

//! Project version string for MADFileManager.
FOUNDATION_EXPORT const unsigned char MADFileManagerVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <MADFileManager/PublicHeader.h>
#import <MADFileManager/MADFileUtilities.h>
#import <MADFileManager/MADCloudFileCoordinator.h>
#import <MADFileManager/MADLocalFileCoordinator.h>
#import <MADFileManager/MADFilesController.h>
#import <MADFileManager/MADMetaData.h>
#import <MADFileManager/MADFileInfo.h>
#import <MADFileManager/MADFileLocationManagerDelegate.h>
#import <MADFileManager/MADFilesControllerDelegate.h>
#import <MADFileManager/MADStorageState.h>

// Remaining public headers, so the module umbrella is complete.
// (-Wincomplete-umbrella; keep in sync with the Public headers phase.)
#import <MADFileManager/MADAppStorageOption.h>
#import <MADFileManager/MADFileCoordinator.h>
#import <MADFileManager/MADFileCoordinatorProtocol.h>
