//
//  MADFileCoordinatorProtocol.h
//  MADFileManager
//
//  Created by Michael Thomason on 5/24/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADFileCoordinatorProtocol_h
#define MADFileCoordinatorProtocol_h

@protocol MADFileCoordinatorDelegate;

@class MADFile;

@protocol MADFileCoordinatorProtocol <NSObject>

    @property (nonatomic, weak) id <MADFileCoordinatorDelegate> delegate;
    @property (nonatomic, strong, readwrite) NSURL *documentsDirectory;

    - (void)startQuery;
    - (void)stopQuery;
    - (void)removeFileAtURL:(NSURL *)URL;
    - (void)duplicateFileAtURL:(NSURL *)URL;
    - (void)renameFileAtURL:(NSURL *)URL toName:(NSString *)name;
    - (void)createURLForFile:(MADFile *)list withName:(NSString *)name
                   extention:(NSString *)extention fileGroup:(NSString *)fileGroup;
    - (BOOL)canCreateFileWithName:(NSString *)name extention:(NSString *)extention
                        fileGroup:(NSString *)fileGroup;

@end

#endif /* MADFileControllerProtocol_h */
