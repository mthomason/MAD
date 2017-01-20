//
//  MADQueryParameters.h
//  MAD
//
//  Created by Michael on 1/19/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADQueryParameters_h
#define MAD_MADQueryParameters_h

#import <Foundation/NSObject.h>

@protocol MADQueryParametersStandardProtocol <NSObject>
    - (NSString *)queryTableName;
@end

@protocol MADQueryParametersColumnKeysProtocol <NSObject>
    - (NSArray <NSString *> *)queryColumnKeys;
@end

@protocol MADQueryParametersColumnMetaProtocol <NSObject>
    - (NSDictionary *)queryColumns;
@end

@protocol MADQueryParametersColumnDataProtocol <NSObject>
    - (NSArray *)queryRowData;
@end

@interface MADQueryParameters : NSObject

@end
/*
@interface MADQueryParametersCacheAddRow : MADQueryParameters
    <MADQueryParametersStandardProtocol,
        MADQueryParametersColumnKeysProtocol,
        MADQueryParametersColumnMetaProtocol,
        MADQueryParametersColumnDataProtocol>

@end
*/
#endif
