//
//  MTApplicaitonInstance.h
//  MAD
//
//  Created by Michael Thomason on 2/16/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTApplicationInstance_h
#define Reports_MTApplicationInstance_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MTReportState) {
	MTReportStateOpen = 0,
	MTReportStateClosed
};

typedef NS_ENUM(NSUInteger, MADAppStorage) {
    MADAppStorageNotSet = 0,
    MADAppStorageCloud,
    MADAppStorageLocal
};

typedef struct MADAppStorageState {
    MADAppStorage storageOption;
    BOOL accountDidChange;
    BOOL cloudAvailable;
} MADAppStorageState;

extern NSString * const MTBundleIdMadDesigner;
extern NSString * const MTBundleIdMadViewer;

extern NSString * const MTGlobalBundleVersion;
extern NSString * const MTGlobalBundleShortVersion;
extern NSString * const MTGlobalBundleRev;

@class MADocument, MTReportDesigner, MTReportViewer, MTQueryDesigner, MTUser, MADFileManager;

#if TARGET_OS_IPHONE
@protocol MADListCoordinator;
@class MADFilesController;
#endif

@interface MTApplicationInstance : NSObject

@property (nonatomic, assign) MTReportState reportState;

@property (nonatomic, strong, readonly) MTUser *user;

@property (nonatomic, strong, readonly) MTReportDesigner *reportDesigner;
@property (nonatomic, strong, readonly) MTReportViewer *reportViewer;
@property (nonatomic, strong, readonly) MTQueryDesigner *queryDesigner;

@property (nonatomic, strong, readonly) MADFileManager *fileManager;

@property (nonatomic, readonly) MADAppStorageState storageState;
@property (nonatomic) MADAppStorage storageOption;

+ (MTApplicationInstance *)mainInstance;

- (void)initalizeAppearance;
- (void)registerDefaultsFromSettingsBundle;

+ (NSString *)applicationName;
+ (NSAttributedString *)localizedAttributedApplicationNameMadDesigner;
+ (NSAttributedString *)localizedAttributedApplicationNameMadViewer;
+ (NSAttributedString *)localizedAttributedApplicationNameMadQuery;

+ (NSString *)applicationNamePrefixPartFormat;
+ (NSString *)applicationNameSufixPart;

+ (BOOL)isMadViewer;
+ (BOOL)isMadDesigner;
+ (NSString *)bundleId;
+ (NSString *)bundleVersion;

+ (NSString *)storyboardName;
//+ (UIStoryboard *)storyboard;

+ (NSString *)madDesigner;
+ (NSString *)madViewer;
+ (NSString *)madQuery;

+ (NSString *)bundleDisplayName;

- (void)closeReportWithCompletionHandler:(void (^)(BOOL))completionHandler;
- (MADocument *)openDocument;

#if TARGET_OS_IPHONE

/*!
 * Returns an \c AAPLListCoordinator based on the current configuration that queries based on \c pathExtension.
 * For example, if the user has chosen local storage, a local \c AAPLListCoordinator object will be returned.
 */
- (id<MADListCoordinator>)listsCoordinatorForCurrentConfigurationWithPathExtension:(NSString *)pathExtension
                                                                 firstQueryHandler:(void (^)(void))firstQueryHandler;

/*!
 * Returns an \c AAPLListCoordinator based on the current configuration that queries based on \c lastPathComponent.
 * For example, if the user has chosen local storage, a local \c AAPLListCoordinator object will be returned.
 */
- (id<MADListCoordinator>)listsCoordinatorForCurrentConfigurationWithLastPathComponent:(NSString *)lastPathComponent
                                                                     firstQueryHandler:(void (^)(void))firstQueryHandler;

/*!
 * Returns an \c AAPLListsController instance based on the current configuration. For example, if the user has
 * chosen local storage, an \c AAPLListsController object will be returned that uses a local list coordinator.
 * \c pathExtension is passed down to the list coordinator to filter results.
 */
- (MADFilesController *)listsControllerForCurrentConfigurationWithPathExtension:(NSString *)pathExtension
                                                              firstQueryHandler:(void (^)(void))firstQueryHandler;

/*!
 * Returns an \c AAPLListsController instance based on the current configuration. For example, if the user has
 * chosen local storage, an \c AAPLListsController object will be returned that uses a local list coordinator.
 * \c lastPathComponent is passed down to the list coordinator to filter results.
 */
- (MADFilesController *)listsControllerForCurrentConfigurationWithLastPathComponent:(NSString *)lastPathComponent
                                                                  firstQueryHandler:(void (^)(void))firstQueryHandler;

#endif

@end

#endif
