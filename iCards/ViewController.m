//
//  ViewController.m
//  iCards
//
//  Created by admin on 16/4/6.
//  Copyright © 2016年 Ding. All rights reserved.
//


#import "ViewController.h"
#import "Color.h"
#import "iCards.h"

@interface ViewController () <iCardsDataSource, iCardsDelegate>



@property (weak, nonatomic) IBOutlet iCards *cards;
@property (nonatomic, strong) NSMutableArray *cardsData;
@property (nonatomic, strong) NSMutableArray *cardsColor;

@end

@implementation ViewController

- (NSMutableArray *)cardsData {
    if (_cardsData == nil) {
        _cardsData = [NSMutableArray array];
        _cardsColor = [NSMutableArray array];
    }
    return _cardsData;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self makeCardsData];
    self.cards.dataSource = self;
    self.cards.delegate = self;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)makeCardsData {
    for (int i=0; i<4; i++) {
        [self.cardsData addObject:@(i)];
        [self.cardsColor addObject:[Color randomColor].CGColor];
    }
}

- (IBAction)changeOffset:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.cards.offset = CGSizeMake(5, 5);
            break;
        case 1:
            self.cards.offset = CGSizeMake(0, 5);
            break;
        case 2:
            self.cards.offset = CGSizeMake(-5, 5);
            break;
        default:
            self.cards.offset = CGSizeMake(-5, -5);
            break;
    }
}
- (IBAction)changeVisibleNumbers:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.cards.numberOfVisibleItems = 3;
            break;
        case 1:
            self.cards.numberOfVisibleItems = 2;
            break;
        default:
            self.cards.numberOfVisibleItems = 5;
            break;
    }
}
- (IBAction)changeShowCyclicallyState:(UISwitch *)sender {
    self.cards.showedCyclically = sender.isOn;
}

#pragma mark - iCardsDataSource methods

- (NSInteger)numberOfItemsInCards:(iCards *)cards {
    return self.cardsData.count;
}

- (UIView *)cards:(iCards *)cards viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view {
    UILabel *label = (UILabel *)view;
    if (label == nil) {
        CGSize size = cards.frame.size;
        CGRect labelFrame = CGRectMake(0, 0, size.width - 30, size.height - 20);
        label = [[UILabel alloc] initWithFrame:labelFrame];
        label.textAlignment = NSTextAlignmentCenter;
        label.layer.cornerRadius = 5;
    }
    label.text = [self.cardsData[index] stringValue];
    label.layer.backgroundColor = (__bridge CGColorRef _Nullable)(self.cardsColor[index]);
    return label;
}

#pragma mark - iCardsDelegate methods

- (void)cards:(iCards *)cards beforeSwipingItemAtIndex:(NSInteger)index {
    NSLog(@"Begin swiping card %ld!", (long)index);
}

- (void)cards:(iCards *)cards didLeftRemovedItemAtIndex:(NSInteger)index {
    NSLog(@"<--%ld", (long)index);
}

- (void)cards:(iCards *)cards didRightRemovedItemAtIndex:(NSInteger)index {
    NSLog(@"%ld-->", (long)index);
}

- (void)cards:(iCards *)cards didRemovedItemAtIndex:(NSInteger)index {
    NSLog(@"index of removed card: %ld", (long)index);
}

@end
