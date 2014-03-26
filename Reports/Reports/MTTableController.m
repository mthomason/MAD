//
//  MTTableController.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTTableController.h"
#import "MTTableLayout.h"
#import "MTDataFormatter.h"
#import "MTQuery.h"
#import "MTTableCell.h"
#import "MTTableCellHeader.h"

@interface MTTableController ()
    <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong, readwrite) MTDataFormatter *tableFormatter;
@property (nonatomic, copy, readwrite) NSArray *fieldKeys;

@end

@implementation MTTableController

- (id)initWithQuery:(MTQuery *)query {
    NSUInteger rowCount = 0;
    NSUInteger columnCount = 0;
    MTTableLayout *tableLayout = [[MTTableLayout alloc] initWithColumnCount:columnCount andRowCount:rowCount];
    self = [super initWithCollectionViewLayout:tableLayout];
    if (self) {
        MTDataFormatter *tableFormatter = [[MTDataFormatter alloc] initWithQuery:query];
        [self setTableFormatter:tableFormatter];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initalize];
    [[self collectionView] setBackgroundColor:[UIColor whiteColor]];
    [[[self tableFormatter] query] performQuery:^(BOOL success, NSError *error, id results) {
        [self performSelectorOnMainThread:@selector(invalidateLayout) withObject:self waitUntilDone:NO];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[self collectionView] flashScrollIndicators];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Helpers

- (void)invalidateLayout {
    [[self tableFormatter] format];
    UICollectionView *collectionView = [self collectionView];
    [collectionView reloadData];
    [(MTTableLayout *)[self collectionViewLayout] setColumnCount:self.columnCount
                                                     andRowCount:self.rowCount];
}

- (void)initalize {
    [[self collectionView] setDelegate:self];
    [[self collectionView] setDataSource:self];
    __unsafe_unretained Class classCollectionViewCell = [MTTableCell class];
    [[self collectionView] registerClass:classCollectionViewCell forCellWithReuseIdentifier:[self reuseId]];
    __unsafe_unretained Class classCollectionViewCellHeader = [MTTableCellHeader class];
    [[self collectionView] registerClass:classCollectionViewCellHeader forSupplementaryViewOfKind:@"MTTableCellHeader" withReuseIdentifier:[self reuseIdSupplement]];
}

#pragma mark - Methods

- (NSString *)reuseId {
    static NSString * reuseId;
    if (reuseId == nil) {
        __unsafe_unretained Class class = [self class];
        reuseId = NSStringFromClass(class);
    }
    return reuseId;
}

- (NSString *)reuseIdSupplement {
    static NSString * reuseIdSupplement;
    if (reuseIdSupplement == nil) {
        __unsafe_unretained Class class = [self class];
        reuseIdSupplement = [NSStringFromClass(class) stringByAppendingString:@"Sup"];
    }
    return reuseIdSupplement;
}

- (NSUInteger)rowCount {
    return [[[self tableFormatter] records] count];
}

- (NSUInteger)columnCount {
    return [[[self tableFormatter] records] count] > 0 ? [[[[self tableFormatter] records] lastObject] count] : 0;
}
#pragma mark - Delegates

#pragma mark - Collection View Datasource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger numberOfItems = [self rowCount] * [self columnCount];
    return numberOfItems;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reuseId = [self reuseId];
    MTTableCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseId
                                                                           forIndexPath:indexPath];
    NSUInteger row = [(MTTableLayout *)[self collectionViewLayout] rowForIndexPath:indexPath];
    NSUInteger column = [(MTTableLayout *)[self collectionViewLayout] columnForIndexPath:indexPath];
    NSDictionary *rowData = [[self tableFormatter] dataForRow:row];
    NSString *fieldKey = [self fieldKeyForIndex:column];
    id fieldValue = [rowData objectForKey:fieldKey];
    NSString *fieldString = [NSString stringWithFormat:@"%@", fieldValue];
    [[cell label] setText:fieldString];
    return cell;
}

- (NSString *)fieldKeyForIndex:(NSUInteger)index {
    if ([self fieldKeys] == nil) {
        NSDictionary *rowDataSample = [[self tableFormatter] dataForRow:0];
        NSMutableArray *a = [[NSMutableArray alloc] initWithCapacity:[rowDataSample count]];
        [rowDataSample enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [a addObject:key];
        }];
        [self setFieldKeys:a];
    }
    return [[self fieldKeys] objectAtIndex:index];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    NSString *reuseId = [self reuseIdSupplement];
    NSString *fieldKey = [self fieldKeyForIndex:[indexPath row]];
    MTTableCellHeader *view = [collectionView dequeueReusableSupplementaryViewOfKind:@"MTTableCellHeader" withReuseIdentifier:reuseId forIndexPath:indexPath];
    [[view label] setText:fieldKey];
    return view;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(75.0000f, 22.0000f);
}

@end
