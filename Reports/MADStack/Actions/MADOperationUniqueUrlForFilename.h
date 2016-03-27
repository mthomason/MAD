//
//  MADOperationUniqueUrlForFilename.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/27/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDesigner_MADOperationUniqueUrlForFilename_h
#define MADDesigner_MADOperationUniqueUrlForFilename_h

#import "MADOperation.h"

@protocol MADOperationUniqueUrlForFilenameProtocol <NSObject>
    - (NSURL *)uniqueUrl;
@end

@interface MADOperationUniqueUrlForFilename : MADOperation
    <MADOperationUniqueUrlForFilenameProtocol>
    
    - (instancetype)initWithDesiredFilename:(NSString *)filename pathExtension:(NSString *)pathExtension
                      andDocumentsDirectory:(NSURL *)documentsDirectory;

    @property (nonatomic, copy, readonly) NSURL *uniqueUrl;

@end

#endif
