//
//  MADOperationUniqueUrlForFilename.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/27/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADDesigner_MADOperationUniqueUrlForFilename_h
#define MADDesigner_MADOperationUniqueUrlForFilename_h

#import <MADFoundation/MADOperation.h>

@protocol MADOperationUniqueUrlForFilenameProtocol <NSObject>
	- (NSURL *)uniqueUrl;
@end

@interface MADOperationUniqueUrlForFilename : MADOperation
	<MADOperationUniqueUrlForFilenameProtocol>

@property (nonatomic, copy, readonly) NSURL *uniqueUrl;

- (instancetype)initWithDesiredFilename:(NSString *)filename pathExtension:(NSString *)pathExtension
				  andDocumentsDirectory:(NSURL *)documentsDirectory;

@end

#endif
