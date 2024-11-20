//
//  MADQueryCacheAddRow.h
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTQueryCacheAddRow_h
#define Reports_MTQueryCacheAddRow_h

#import <MADAPI/MADQuery.h>
#import "MADQueryParameters.h"

@interface MADQueryCacheAddRow : MADQuery
    <MADQueryDataBindingProtocol, MADQueryUpdatableProtocol>

    @property (nonatomic, weak) id <MADQueryParametersStandardProtocol,
                                    MADQueryParametersColumnKeysProtocol,
                                    MADQueryParametersColumnMetaProtocol,
                                    MADQueryParametersColumnDataProtocol> delegate;

@end

#endif
