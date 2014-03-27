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
#import "MTDatabaseField.h"

@interface MTTableController ()
    <UICollectionViewDataSource, MTTableLayoutDelegate>

@property (nonatomic, strong) MTQuery *query;
@property (nonatomic, strong, readwrite) MTDataFormatter *tableFormatter;
@property (nonatomic, copy, readwrite) NSArray *fieldKeys;
@property (nonatomic, copy, readwrite) NSArray *fieldSizes;

@end

@implementation MTTableController

- (id)initWithQuery:(MTQuery *)query {
    NSUInteger rowCount = 0;
    NSUInteger columnCount = 0;
    MTTableLayout *tableLayout = [[MTTableLayout alloc] initWithColumnCount:columnCount andRowCount:rowCount];
    self = [super initWithCollectionViewLayout:tableLayout];
    if (self) {
        [tableLayout setDelegate:self];
        MTDataFormatter *tableFormatter = [[MTDataFormatter alloc] initWithQuery:query];
        [self setTableFormatter:tableFormatter];
        [self setQuery:query];
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
        NSUInteger numberOfFields = [rowDataSample count];
        NSMutableArray *a = [[NSMutableArray alloc] initWithCapacity:numberOfFields];
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
    NSArray *components = [fieldKey componentsSeparatedByString:@"."];
    NSString *safeFieldName = [components lastObject];
    NSString *fieldName = [safeFieldName stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    
    MTTableCellHeader *view = [collectionView dequeueReusableSupplementaryViewOfKind:@"MTTableCellHeader" withReuseIdentifier:reuseId forIndexPath:indexPath];
    [[view label] setText:fieldName];
    return view;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger column =  [(MTTableLayout *)[self collectionViewLayout] columnForIndexPath:indexPath];
    NSString *fieldKey = [self fieldKeyForIndex:column];
    MTDatabaseField *field = [[[self query] fields] objectForKey:fieldKey];
    [UIFont systemFontOfSize:[UIFont systemFontSize]];
    
    UIFontDescriptor *fontDescriptorHeadline = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleHeadline];
    UIFontDescriptor *fontDescriptorBody = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
    CGFloat sizeHeadline = [fontDescriptorHeadline.fontAttributes[UIFontDescriptorSizeAttribute] floatValue];
    CGFloat sizeBody = [fontDescriptorBody.fontAttributes[UIFontDescriptorSizeAttribute] floatValue];

    UIFont *headlineFont = [UIFont fontWithDescriptor:fontDescriptorHeadline size:sizeHeadline];
    UIFont *bodyFont = [UIFont fontWithDescriptor:fontDescriptorBody size:sizeBody];

    NSString *s = [@"" stringByPaddingToLength:[field width] withString:@"X" startingAtIndex:0];
    CGSize size = [s sizeWithAttributes:@{NSFontAttributeName: bodyFont}];
   
    NSArray *fields = [[[self query] fields] objectForKey:fieldKey];
    return CGSizeMake(75.0000f, 22.0000f);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(CGSizeZero.height + 22.0000f, CGSizeZero.width, CGSizeZero.height, CGSizeZero.width);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout widthRequiredColumn:(NSInteger)section {
    return 75.0000f;
}

@end
