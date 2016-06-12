//
//  MADQuerySections.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/11/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADQuerySections_h
#define MADQuerySections_h

typedef NS_ENUM(short, MTQuerySections) {
    MTQuerySectionsDocumentGroups = 0,
    MTQuerySectionsDatasource = 1,
    MTQuerySectionsTables = 2,
    MTQuerySectionsLinks = 3,
    MTQuerySectionsGroups = 4,
    MTQuerySectionsPredicate = 5,
    MTQuerySectionsSql = 6,
    MTQuerySectionsNumberOfQueryResults = 7
};

#endif /* MADQuerySections_h */
