//
//  MADToolboxControllerProtocol.h
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADToolboxControllerProtocol_h
#define Reports_MADToolboxControllerProtocol_h

@class MADocument;

@protocol MADToolboxControllerProtocol <NSObject>

@required

    - (void)setSelectedDocumentObjects:(NSSet <NSNumber *> *)objectIds;

@end

#endif
