//
//  MADOpenDocumentManager.h
//  Reports
//
//  Created by Michael Thomason on 9/11/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADFileManager_h
#define Reports_MADFileManager_h

#import <Foundation/NSObject.h>

@class UIDocument, NSURL;

@interface MADOpenDocumentManager : NSObject

	@property (nonatomic, copy, readonly) NSURL *openUrl;

	- (__kindof UIDocument *)openDocument;
	- (void)setOpenDocument:(__kindof UIDocument *)document;
	- (void)unload;
	- (void)removeDocumentWithUrl:(NSURL *)url;

@end

#endif
