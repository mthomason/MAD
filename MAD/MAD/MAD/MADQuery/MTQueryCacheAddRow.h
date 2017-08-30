//
//  MTQueryCacheAddRow.h
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryCacheAddRow_h
#define Reports_MTQueryCacheAddRow_h

#import "MTQuery.h"
#import "MADQueryParameters.h"

@interface MTQueryCacheAddRow : MTQuery
    <MADQueryDataBindingProtocol, MADQueryUpdatableProtocol>

    @property (nonatomic, weak) id <MADQueryParametersStandardProtocol,
                                    MADQueryParametersColumnKeysProtocol,
                                    MADQueryParametersColumnMetaProtocol,
                                    MADQueryParametersColumnDataProtocol> delegate;

@end

#endif
