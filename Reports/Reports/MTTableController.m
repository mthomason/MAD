//
//  MTTableController.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTTableController.h"
#import "MTTableLayout.h"

@interface MTTableController ()

@end

@implementation MTTableController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initalize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initalize];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    //MTTableLayout *tableLayout = [[MTTableLayout alloc] initWithColumnCount: andRowCount:];
    //[[self collectionView] setCollectionViewLayout:tableLayout];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Helpers

- (void)initalize { }

@end
