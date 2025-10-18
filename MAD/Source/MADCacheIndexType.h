//
//  MADQueryCacheIndexCreateTypes.h
//  MAD
//
//  Created by Michael Thomason on 5/25/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADQueryCacheIndexCreateTypes_h
#define MAD_MADQueryCacheIndexCreateTypes_h

#import <sys/types.h>

typedef enum MADCacheIndexType : short {
    MADCacheIndexTypeGroupCount,
    MADCacheIndexTypeName,
    MADCacheIndexTypeTableName,
    MADCacheIndexTypeSortDescriptors,
    MADCacheIndexTypeColumns,
} MADCacheIndexType;

#endif

