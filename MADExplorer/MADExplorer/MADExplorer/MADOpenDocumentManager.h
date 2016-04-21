//
//  MADOpenFileViewController.h
//  Reports
//
//  Created by Michael Thomason on 9/11/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADFileManager_h
#define Reports_MADFileManager_h

#import <UIKit/UIKit.h>

@interface MADOpenDocumentManager : NSObject

    @property (nonatomic, copy, readonly) NSURL *openUrl;
    @property (readonly) UIManagedDocument *openDocument;

    - (void)setOpenDocument:(UIManagedDocument *)document;
    - (void)removeDocumentWithUrl:(NSURL *)url;

@end

#endif
