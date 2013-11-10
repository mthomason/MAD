//
//  MTViewControllerBarcodeType.m
//  MAD
//
//  Created by Michael Thomason on 11/8/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTViewControllerBarcodeType.h"

@interface MTViewControllerBarcodeType ()

@property (retain, nonatomic) IBOutlet UIPickerView *pickerView;

@property (nonatomic, retain) NSDictionary *barcodeNamesByType;
@property (nonatomic, retain) NSArray *barcodeNamesOrdered;

@end

@implementation MTViewControllerBarcodeType

- (void)dealloc {
    [_barcodeNamesByType release];
    [_barcodeNamesOrdered release];
    [_pickerView release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self customInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit {
    NSDictionary *namesByType = [[MTBarcode names] retain];
    [self setBarcodeNamesByType:namesByType];
    [namesByType release];
    
    NSArray *allNames = [[self barcodeNamesByType] allValues];
    NSArray *allNamesSorted = [[allNames sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] retain];
    [self setBarcodeNamesOrdered: allNamesSorted];
    [allNamesSorted release];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSString *barcodeName = [[self barcodeNamesByType] objectForKey:@([self initalKey])];
    NSInteger index = [[self barcodeNamesOrdered] indexOfObject:barcodeName];
    [[self pickerView] selectRow:index inComponent:0 animated:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UIPickerView Data Source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [[self barcodeNamesOrdered] count];
}

#pragma mark - UIPickerView Delegate

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSArray *names = [self barcodeNamesOrdered];
    NSString *tableName = [names objectAtIndex:row];
    UIColor *strokeColor = [UIColor whiteColor];
    UIColor *forgroundColor = [UIColor blackColor];
    NSMutableParagraphStyle *paragraph = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraph setAlignment:NSTextAlignmentCenter];
    NSDictionary *attributes = @{
                                 NSStrokeColorAttributeName : strokeColor,
                                 NSForegroundColorAttributeName : forgroundColor,
                                 NSParagraphStyleAttributeName : paragraph,
                                 };
    [paragraph release];
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:tableName attributes:attributes];
    return  [attributedString autorelease];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSString *barcodeName = [[self barcodeNamesOrdered] objectAtIndex:row];
    NSArray *keys = [[self barcodeNamesByType] allKeysForObject:barcodeName];
    if ([keys count] > 0) {
        NSNumber *key = [keys objectAtIndex:0];
        MTBarcodeType resultType = [key integerValue];
        [[self delegate] didChangeBarcodeType:resultType];
    }
}

@end
