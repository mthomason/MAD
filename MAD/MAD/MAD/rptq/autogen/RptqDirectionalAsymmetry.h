//
//  RptqDirectionalAsymmetry+CoreDataClass.h
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDirectionalAsymmetry_h
#define MAD_RptqDirectionalAsymmetry_h

#import <CoreData/NSManagedObject.h>
#import <CoreData/NSFetchRequest.h>

NS_ASSUME_NONNULL_BEGIN

@interface RptqDirectionalAsymmetry : NSManagedObject

@end

@interface RptqDirectionalAsymmetry (CoreDataProperties)

+ (NSFetchRequest<RptqDirectionalAsymmetry *> *)fetchRequest;

@property (nonatomic) float top;
@property (nonatomic) float bottom;
@property (nonatomic) float left;
@property (nonatomic) float right;

@end

NS_ASSUME_NONNULL_END

#endif
