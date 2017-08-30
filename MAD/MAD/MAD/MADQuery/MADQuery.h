//
//  MADQuery.h
//  MAD
//
//  Created by Michael on 1/12/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADQuery_h
#define Reports_MADQuery_h

#import <Foundation/NSObject.h>
#import <MADAPI/MADQueryType.h>

@interface MADQuery : NSObject

    - (instancetype)initWithQueryType:(MADQueryType)type object:(id)object;

    @property (nonatomic, copy) NSString *sql;

@end

#endif
