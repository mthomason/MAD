//
//  MTViewControllerBarcodeType.m
//  MAD
//
//  Created by Michael Thomason on 11/8/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTViewControllerBarcodeType.h"

#import <UIKit/NSAttributedString.h>

#import <MADBarcodes/MTBarcode.h>

@interface MTViewControllerBarcodeType ()

    @property (nonatomic, weak) IBOutlet UIPickerView *pickerView;

    @property (nonatomic, strong) NSDictionary *barcodeNamesByType;
    @property (nonatomic, strong) NSArray *barcodeNamesOrdered;

@end

@implementation MTViewControllerBarcodeType

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self customInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self customInit];
    }
    return self;
}

- (void)customInit {
    NSDictionary *namesByType = [MTBarcode newDictionaryNames];
    self.barcodeNamesByType = namesByType;
    
    NSArray *allNames = (self.barcodeNamesByType).allValues;
    NSArray *allNamesSorted = [allNames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    self.barcodeNamesOrdered = allNamesSorted;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSNumber *initalKey = @(self.initalKey);
    NSString *barcodeName = self.barcodeNamesByType[initalKey];
    NSUInteger index = [self.barcodeNamesOrdered indexOfObject:barcodeName];
    [self.pickerView selectRow:(NSInteger)index
                   inComponent:0 animated:animated];
}

#pragma mark - UIPickerView Data Source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return (NSInteger)self.barcodeNamesOrdered.count;
}

#pragma mark - UIPickerView Delegate

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView
             attributedTitleForRow:(NSInteger)row
                      forComponent:(NSInteger)component {
    
    NSArray *names = self.barcodeNamesOrdered;
    NSString *tableName = names[(NSUInteger)row];
    UIColor *strokeColor = [UIColor whiteColor];
    UIColor *forgroundColor = [UIColor blackColor];
    NSParagraphStyle *defaultParagraph = [[NSParagraphStyle alloc] init];
    NSMutableParagraphStyle *paragraph = defaultParagraph.mutableCopy;
    paragraph.alignment = NSTextAlignmentCenter;
    NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    strokeColor,    NSStrokeColorAttributeName,
                                    forgroundColor, NSForegroundColorAttributeName,
                                    paragraph,      NSParagraphStyleAttributeName, nil];

    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:tableName attributes:attributes];
    return  attributedString;
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component {
    
    NSString *barcodeName = self.barcodeNamesOrdered[(NSUInteger)row];
    NSArray *keys = [self.barcodeNamesByType allKeysForObject:barcodeName];
    if (keys.count > 0) {
        NSNumber *key = keys[0];
        MTBarcodeType resultType = key.shortValue;
        [self.delegate didChangeBarcodeType:resultType];
    }
}

@end
