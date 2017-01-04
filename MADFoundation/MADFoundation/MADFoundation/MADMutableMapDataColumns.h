//
//  MADMutableMapDataColumns.h
//  MADFoundation
//
//  Created by Michael Thomason on 5/29/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADFoundation_MADMutableMapDataColumns_h
#define MADFoundation_MADMutableMapDataColumns_h

@class NSMutableDictionary<KeyType, ObjectType>;
@class NSString;
@class MADDataColumn;

typedef NSMutableDictionary <NSString *, MADDataColumn *> MADMutableMapDataColumns;

#endif /* MADMutableMapDataColumns_h */
