//
//  MADFileController.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/4/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MADFileManagerSection) {
    MADFileManagerSectionLocal = 0,
    MADFileManagerSectionCloud = 1,
};

@protocol MADFileControllerProtocol <NSObject>

@optional

- (void)cloudLookupBegan;
- (void)cloudLookupEnded;

@required

- (void)didUpdateFileLocations;

- (void)fileControllerDidUpdateContentsWithInsertedItems:(NSArray *)insertedItems   //Array of index paths
                                            removedItems:(NSArray *)removedItems    //Array of index paths
                                            updatedItems:(NSArray *)updatedItems;   //Array of index paths
- (void)fileControllerDidFailRemovingFileAtURL:(NSURL *)URL withError:(NSError *)error;
- (void)fileControllerDidFailCreatingFileAtURL:(NSURL *)URL withError:(NSError *)error;

@end

@interface MADFileController : NSObject

@property (nonatomic, weak) id <MADFileControllerProtocol> fileControllerDelegate;

@property (nonatomic, strong, readwrite) NSString *searchQuery;

+ (MADFileController *)sharedManager;

- (void)activateWithGroupID:(NSString *)groupId
              ubiquityToken:(NSString *)ubiquityToken
              fileExtention:(NSString *)fileExtention;


// Actions
- (void)duplicateItems:(NSArray *)items;    // Array of index paths.
- (void)deleteItems:(NSArray *)items;       // Array of index paths.

// Data objects
- (NSUInteger)numberOfSections;
- (NSUInteger)numberOfObjectsInSection:(NSUInteger)section;
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

@end
