//
//  MADURL.h
//  MADFileManager
//
//  Created by Michael Thomason on 5/31/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADDesigner_MADFoundation_MADURL_h
#define MADDesigner_MADFoundation_MADURL_h

#import <Foundation/NSURL.h>

@interface MADURLFactory : NSObject

	+ (NSURL *)newURLLocalDocumentWithName:(NSString *)name
									  extention:(NSString *)extention
									  fileGroup:(NSString *)fileGroup;
	+ (NSURL *)newURLCacheFilesDirectoryForFilename:(NSString *)filename;
	+ (NSURL *)newURLDocumentArchiveForFileURL:(NSURL *)madUrl
										  extension:(NSString *)extension;

	+ (NSURL *)newURLThumbnailForURL:(NSURL *)madUrl;

	+ (NSURL *)newURLThumbnailForHandle:(NSString *)handle
							andRetinaDisplay:(BOOL)retinaDisplay;

	+ (NSURL *)newURLWithUniqueFilenameForURL:(NSURL *)origionalURL;

	+ (NSURL *)newURLUniqueUrlInDirectory:(NSURL *)directory
							 withDesiredHandle:(NSString *)desiredFileHandle
								  andExtension:(NSString *)extension;

	+ (NSURL *)newURLForLocalDirectoryForGroupIdentifier:(NSString *)groupIdentifier
												pathComponent:(NSString *)pathComponent
										  alternativeSelector:(SEL)alternativeSelector;
									  
	+ (NSURL *)newURLForURLSelector:(SEL)selector;
	+ (NSURL *)newURLForLocalCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier
														   fileURL:(NSURL *)fileURL;
	+ (NSURL *)newURLForLocalCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier
															handle:(NSString *)handle;
	+ (NSURL *)newURLForLocalDocumentsDirectory;
	+ (NSURL *)newURLLocalTemporaryDirectory;
	+ (NSURL *)newURLForLocalCacheDirectory;
	+ (NSURL *)newURLForLocalDataDirectory;
	+ (NSURL *)newURLForLocalApplicationSupportDirectory;

	+ (NSURL *)newURLForCloudDocumentsDirectoryForUbiquityID:(NSString *)ubiquityID;
	+ (NSURL *)newURLLocalDocumentsDirectoryForGroupIdentifier:(NSString *)groupIdentifier;

	+ (NSURL *)newURLForLocalDataDirectoryForGroupIdentifier:(NSString *)groupIdentifier;
	+ (NSURL *)newURLForLocalCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier;
	+ (NSURL *)newURLLocalApplicationSupportDirectoryForGroupID:(NSString *)groupIdentifier;
	+ (NSURL *)newURLForLocalCacheDirectoryNamed:(NSString *)handle;
	+ (NSURL *)newURLUniqueURLForURL:(NSURL *)url;
	+ (NSURL *)newURLForLocalCachedDirectoryForFileUrl:(NSURL *)fileUrl;
	+ (NSURL *)newURLApplicationSupportFile:(NSString *)filename
									   extension:(NSString *)extension;

@end

#endif
