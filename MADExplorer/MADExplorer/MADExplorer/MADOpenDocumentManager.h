//
//  MADOpenDocumentManager.h
//  Reports
//
//  Created by Michael Thomason on 9/11/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADFileManager_h
#define Reports_MADFileManager_h

#import <Foundation/NSObject.h>

@class UIManagedDocument, NSURL;

@interface MADOpenDocumentManager : NSObject

    @property (nonatomic, copy, readonly) NSURL *openUrl;

    - (__kindof UIManagedDocument *)openDocument;
    - (void)setOpenDocument:(__kindof UIManagedDocument *)document;
    - (void)unload;
    - (void)removeDocumentWithUrl:(NSURL *)url;

@end

#endif
