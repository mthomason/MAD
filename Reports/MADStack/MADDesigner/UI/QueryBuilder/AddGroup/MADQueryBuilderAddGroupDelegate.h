//
//  MADQueryBuilderAddGroupDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/1/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADQueryBuilderAddGroupDelegate_h
#define MAD_Designer_MADQueryBuilderAddGroupDelegate_h

@protocol MADQueryBuilderAddGroupDelegate
    - (void)addQueryGroupWithQueryField:(NSManagedObjectID *)queryField
                           andSortOrder:(MADSortOrder)sortOrder;
    - (void)viewControllerDidCancel:(id)sender;
@end

#endif /* Header_h */
