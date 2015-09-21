//
//  MTToolboxViewControllerProtocol.h
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTToolboxViewControllerProtocol_h
#define Reports_MTToolboxViewControllerProtocol_h

#import <Foundation/Foundation.h>

@class MADocument;

@protocol MTToolboxViewControllerProtocol <NSObject>

@required

- (void)setSelectedDocumentObjects:(NSSet *)objectIds;
- (void)setDocument:(MADocument *)document;

@end

#endif
