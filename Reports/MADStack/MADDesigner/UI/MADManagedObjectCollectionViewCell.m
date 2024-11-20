//
//  MADManagedObjectCollectionViewCell.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADManagedObjectCollectionViewCell.h"

@implementation MADManagedObjectCollectionViewCell

@synthesize identifier = _identifier;

- (id <NSCopying>)key {
    return @(self.identifier);
}

@end
