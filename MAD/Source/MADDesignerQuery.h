//
//  MADDesignerQuery.h
//  MAD
//
//  Created by Michael on 8/21/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADocumentQuery_h
#define Reports_MADocumentQuery_h

#import <Foundation/NSObject.h>

@protocol MADocumentDesignerProtocol;

@interface MADDesignerQuery : NSObject

	@property (nonatomic, weak) id <MADocumentDesignerProtocol> delegate;

@end

#endif
