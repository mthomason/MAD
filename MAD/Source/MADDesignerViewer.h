//
//  MADDesignerViewer.h
//  MAD
//
//  Created by Michael on 8/21/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADocumentViewer_h
#define Reports_MADocumentViewer_h

#import <Foundation/NSObject.h>

@protocol MADocumentDesignerProtocol;

@interface MADDesignerViewer : NSObject

@property (nonatomic, weak) id <MADocumentDesignerProtocol> delegate;

@end

#endif
