//
//  NSError+Document.h
//  MAD
//
//  Created by Michael Thomason on 6/8/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_NSError__Document_h
#define Reports_NSError__Document_h

#import <Foundation/NSError.h>

@interface NSError (Document)

    + (instancetype)newErrorConnectionProblem;
    + (instancetype)newErrorFailedToOpenDocument;

@end

#endif
