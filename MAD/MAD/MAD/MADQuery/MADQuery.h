//
//  MADQuery.h
//  MAD
//
//  Created by Michael on 1/12/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADQuery_h
#define Reports_MADQuery_h

#import <Foundation/Foundation.h>
#import "MADQueryType.h"

@interface MADQuery : NSObject

    + (instancetype)newQuery:(MADQueryType)type object:(id)object;

@end

#endif
