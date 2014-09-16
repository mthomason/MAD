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

@class MADocument;

@interface MADFileManager : NSObject

@property (nonatomic, strong, readonly) NSURL *openUrl;
@property (nonatomic, strong) UIManagedDocument *openDocument;

- (void)removeDocumentWithUrl:(NSURL *)url;

@end

#endif
