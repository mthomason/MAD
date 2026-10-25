//
//  MADViewControllerDocumentProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/8/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADViewControllerDocumentProtocol_h
#define MAD_MADViewControllerDocumentProtocol_h

#import <Foundation/NSObject.h>

@class MADocument;

@protocol MADViewControllerDocumentProtocol <NSObject>
@property (nonatomic, weak) MADocument *document;
@end

#endif
