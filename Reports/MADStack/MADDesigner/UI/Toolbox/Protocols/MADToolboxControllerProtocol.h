//
//  MADToolboxControllerProtocol.h
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADToolboxControllerProtocol_h
#define Reports_MADToolboxControllerProtocol_h

#import <Foundation/NSObject.h>

@class NSSet<__covariant ObjectType>;

@protocol MADToolboxControllerProtocol <NSObject>
@required
- (void)setSelectedDocumentObjects:(NSSet <NSNumber *> *)objectIds;
@end

#endif
