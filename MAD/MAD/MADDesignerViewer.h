//
//  MADDesignerViewer.h
//  MAD
//
//  Created by Michael on 8/21/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADocumentViewer_h
#define Reports_MADocumentViewer_h

#import <Foundation/NSObject.h>

@class NSManagedObjectContext;
@protocol MADocumentDesignerProtocol;

@interface MADDesignerViewer : NSObject

	@property (nonatomic, weak) id <MADocumentDesignerProtocol> delegate;

@end

#endif
