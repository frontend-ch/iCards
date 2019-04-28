//
//  iCards.m
//  iCards
//
//  Created by admin on 16/4/6.
//  Copyright © 2016年 Ding. All rights reserved.
//

#import "iCards.h"

// distance from center where the action applies. Higher = swipe further in order for the action to be called
static const CGFloat kLeftActionMargin = 120;
static const CGFloat kRightActionMargin = 100;
// how quickly the card shrinks. Higher = slower shrinking
static const CGFloat kScaleStrength = 4;
// upper bar for how much the card shrinks. Higher = shrinks less
static const CGFloat kScaleMax = 1;
// the maximum rotation allowed in radians.  Higher = card can keep rotating longer
static const CGFloat kRotationMax = 1.0;
// strength of rotation. Higher = weaker rotation
static const CGFloat kRotationStrength = 320;
// Higher = stronger rotation angle
static const CGFloat kRotationAngle = 0;

@interface iCards ()<UIGestureRecognizerDelegate>

@property (strong, nonatomic) NSMutableArray<UIView *> *visibleViews;
@property (strong, nonatomic) UIView *reusingView;
@property (strong, nonatomic) UIView *lastResuingView;
@property (strong, nonatomic) UIView *lastCard;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, assign) CGPoint originalPoint;
@property (nonatomic, assign) CGPoint originalLastPoint;
@property (nonatomic, assign) CGFloat xFromCenter;
@property (nonatomic, assign) CGFloat yFromCenter;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) NSInteger previousIndex;
@property (nonatomic, assign) BOOL swipeEnded;

@end

@implementation iCards

- (void)setUp {
    _showedCyclically = YES;
    _numberOfVisibleItems = 5;
    _offset = CGSizeMake(5, 5);
    _swipeEnded = YES;
    [self addGestureRecognizer:self.panGestureRecognizer];
    self.panGestureRecognizer.delegate = self;
    
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setUp];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}

#pragma mark - setters and getters

- (void)setShowedCyclically:(BOOL)showedCyclically {
    _showedCyclically = showedCyclically;
    [self reloadData];
}
- (void)setOffset:(CGSize)offset {
    _offset = offset;
    [self reloadData];
}

- (void)setCurrentIndex:(NSInteger)currentIndex
{
    _currentIndex = currentIndex;
    _previousIndex = _currentIndex - 1;
    if (_previousIndex < 0) {
        _previousIndex += [self.dataSource numberOfItemsInCards:self];
    }
}

- (void)setNumberOfVisibleItems:(NSInteger)numberOfVisibleItems {
    NSInteger cardsNumber = numberOfVisibleItems;
    if ([self.dataSource respondsToSelector:@selector(numberOfItemsInCards:)]) {
        cardsNumber = [self.dataSource numberOfItemsInCards:self];
    }
    if (cardsNumber >= numberOfVisibleItems) {
        _numberOfVisibleItems = numberOfVisibleItems;
    } else {
        _numberOfVisibleItems = cardsNumber;
    }
    [self reloadData];
}
- (void)setDataSource:(id<iCardsDataSource>)dataSource {
    _dataSource = dataSource;
    [self reloadData];
}
- (void)setSwipeEnabled:(BOOL)swipeEnabled {
    _swipeEnabled = swipeEnabled;
    self.panGestureRecognizer.enabled = swipeEnabled;
}
- (NSMutableArray *)visibleViews {
    if (_visibleViews == nil) {
        _visibleViews = [[NSMutableArray alloc] initWithCapacity:_numberOfVisibleItems];
    }
    return _visibleViews;
}

- (UIPanGestureRecognizer *)panGestureRecognizer {
    if (_panGestureRecognizer == nil) {
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(dragAction:)];
    }
    return _panGestureRecognizer;
}
- (UIView *)topCard {
   return [self.visibleViews firstObject];
}

#pragma mark - main methods

- (void)reloadData {
    self.currentIndex = 0;
    _reusingView = nil;
    _lastResuingView = nil;
    _lastCard = nil;
    [self.visibleViews removeAllObjects];
    if ([self.dataSource respondsToSelector:@selector(numberOfItemsInCards:)]) {
        NSInteger totalNumber = [self.dataSource numberOfItemsInCards:self];
        if (totalNumber > 0) {
            if (totalNumber < _numberOfVisibleItems) {
                _numberOfVisibleItems = totalNumber;
            }
            if ([self.dataSource respondsToSelector:@selector(cards:viewForItemAtIndex:reusingView:)]) {
                for (NSInteger i=0; i<_numberOfVisibleItems; i++) {
                    UIView *view = [self.dataSource cards:self viewForItemAtIndex:i reusingView:_reusingView];
                    [self.visibleViews addObject:view];
                }
            }
        }
    }
    [self layoutCards];
}

- (void)layoutCards {
    NSInteger count = self.visibleViews.count;
    if (count <= 0) {
        return;
    }
    
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    
    [self layoutIfNeeded];
    
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    CGFloat horizonOffset = _offset.width;
    CGFloat verticalOffset = _offset.height;
    UIView *lastVisibalCard = [self.visibleViews lastObject];
    CGFloat cardWidth = lastVisibalCard.frame.size.width;
    CGFloat cardHeight  = lastVisibalCard.frame.size.height;
    CGFloat firstCardX = (width - cardWidth - (_numberOfVisibleItems - 1) * fabs(horizonOffset));
    if (horizonOffset < 0) {
        firstCardX += (_numberOfVisibleItems - 1) * fabs(horizonOffset);
    }
    CGFloat firstCardY = (height - cardHeight  - (_numberOfVisibleItems - 1) * fabs(verticalOffset));
    if (verticalOffset < 0) {
        firstCardY += (_numberOfVisibleItems - 1) * fabs(verticalOffset);
    }
    [UIView animateWithDuration:0.08 animations:^{
        for (NSInteger i=0; i<count; i++) {
            NSInteger index = count - 1 - i;    //add cards from back to front
            UIView *card = self.visibleViews[index];
            CGSize size = card.frame.size;
            card.frame =CGRectMake(firstCardX + index * horizonOffset, firstCardY + index * verticalOffset, size.width, size.height);
            [self addSubview:card];
        }
    }];
}

- (void)dragAction:(UIPanGestureRecognizer *)gestureRecognizer {
    if (self.visibleViews.count <= 0) {
        return;
    }
    NSInteger totalNumber = [self.dataSource numberOfItemsInCards:self];
    if (_currentIndex > totalNumber - 1) {
        self.currentIndex = 0;
    }
    if (self.swipeEnded) {
        self.swipeEnded = NO;
        if ([self.delegate respondsToSelector:@selector(cards:beforeSwipingItemAtIndex:)]) {
            [self.delegate cards:self beforeSwipingItemAtIndex:_currentIndex];
        }
    }
    UIView *firstCard = [self.visibleViews firstObject];
    UIView *lastVisibalCard = [self.visibleViews lastObject];
    NSInteger lastVisibalIndex = _currentIndex + _numberOfVisibleItems - 1;
    if (lastVisibalIndex < totalNumber) {
        
    } else {
        if (totalNumber == 1) {
            lastVisibalIndex = 0;
        } else {
            lastVisibalIndex %= totalNumber;
        }
    }
    
    if (lastVisibalIndex != _previousIndex && _lastCard == nil) {
        _lastCard = [self.dataSource cards:self viewForItemAtIndex:_previousIndex reusingView:_lastResuingView];
    }
    
    self.xFromCenter = [gestureRecognizer translationInView:firstCard].x; // positive for right swipe, negative for left
    self.yFromCenter = [gestureRecognizer translationInView:firstCard].y; // positive for up, negative for down
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            self.originalPoint = firstCard.center;
            self.originalLastPoint = lastVisibalCard.center;
            break;
        };
        case UIGestureRecognizerStateChanged:{
            CGFloat rotationStrength = MIN(self.xFromCenter / kRotationStrength, kRotationMax);
            CGFloat rotationAngel = (CGFloat) (kRotationAngle * rotationStrength);
            CGFloat scale = MAX(1 - fabs(rotationStrength) / kScaleStrength, kScaleMax);
            if (self.xFromCenter < 0) {
                firstCard.center = CGPointMake(self.originalPoint.x + self.xFromCenter, self.originalPoint.y);
                lastVisibalCard.center = self.originalLastPoint;
                [self sendSubviewToBack:lastVisibalCard];
                _lastCard = nil;
            }
            else {
                firstCard.center = self.originalPoint;
                if (_lastCard) {
                    [self addSubview:_lastCard];
                    _lastCard.center = CGPointMake(-self.originalPoint.x + self.xFromCenter, self.originalPoint.y);
                } else {
                    lastVisibalCard.center = CGPointMake(-self.originalPoint.x + self.xFromCenter, self.originalPoint.y);
                    [self bringSubviewToFront:lastVisibalCard];
                }
            }
            CGAffineTransform transform = CGAffineTransformMakeRotation(rotationAngel);
            CGAffineTransform scaleTransform = CGAffineTransformScale(transform, scale, scale);
            firstCard.transform = scaleTransform;
            lastVisibalCard.transform = scaleTransform;
            _lastCard.transform = scaleTransform;
            break;
        };
        case UIGestureRecognizerStateEnded: {
            [self afterSwipedCard:firstCard lastCard:_lastCard lastVisibalCard:lastVisibalCard];
            break;
        };
        default:
            break;
    }
}
- (void)afterSwipedCard:(UIView *)firstCard lastCard:(UIView *)lastCard lastVisibalCard:(UIView *)lastVisibalCard {
    if (self.xFromCenter > kRightActionMargin) {
        [self rightActionForFirstCard:firstCard lastCard:lastCard lastVisibalCard:lastVisibalCard];
    } else if (self.xFromCenter < -kLeftActionMargin) {
        [self leftActionForCard:firstCard];
    }
    else {
        self.swipeEnded = YES;
        CGPoint finishPoint = CGPointMake(-500, self.originalPoint.y);
        [UIView animateWithDuration:0.3
                         animations: ^{
                             firstCard.center = self.originalPoint;
                             firstCard.transform = CGAffineTransformMakeRotation(0);
                             lastVisibalCard.center = self.originalLastPoint;
                             lastVisibalCard.transform = CGAffineTransformMakeRotation(0);
                             lastCard.center = finishPoint;
                             lastCard.transform = CGAffineTransformMakeRotation(0);
                         }];
        [self sendSubviewToBack:lastVisibalCard];
        [lastCard removeFromSuperview];
        _lastCard = nil;
    }
}

-(void)rightActionForFirstCard:(UIView *)firstCard lastCard:(UIView *)lastCard lastVisibalCard:(UIView *)lastVisibalCard {
    CGPoint finishPoint = CGPointMake(self.originalPoint.x + 30, self.originalPoint.y);
    [UIView animateWithDuration:0.3
                     animations:^{
                         if (lastCard) {
                             lastCard.center = finishPoint;
                         }
                         else {
                             lastVisibalCard.center = finishPoint;
                         }
                     } completion:^(BOOL complete) {
                         if ([self.delegate respondsToSelector:@selector(cards:didLeftRemovedItemAtIndex:)]) {
                             [self.delegate cards:self didLeftRemovedItemAtIndex:_currentIndex];
                         }
                         [self rightCardSwipedAction:lastCard lastVisibalCard:lastVisibalCard];
                         _lastCard = nil;
                     }];
}

- (void)rightCardSwipedAction:(UIView *)lastcard  lastVisibalCard:(UIView *)lastVisibalCard{
    self.swipeEnded = YES;
    NSMutableArray *newArray = [NSMutableArray array];
    if (lastcard) {
        lastcard.transform = CGAffineTransformMakeRotation(0);
        lastcard.center = self.originalPoint;
        [self.visibleViews removeObject:lastVisibalCard];
        [newArray addObject:lastcard];
        [newArray addObjectsFromArray:self.visibleViews];
        self.visibleViews = newArray;
    } else {
        lastVisibalCard.transform = CGAffineTransformMakeRotation(0);
        lastVisibalCard.center = self.originalPoint;
        [self.visibleViews removeObject:lastVisibalCard];
        newArray = [NSMutableArray arrayWithObjects:lastVisibalCard, nil];
        [newArray addObjectsFromArray:self.visibleViews];
        self.visibleViews = newArray;
    }
    
    if ([self.delegate respondsToSelector:@selector(cards:didRemovedItemAtIndex:)]) {
        [self.delegate cards:self didRemovedItemAtIndex:_currentIndex];
    }
    self.currentIndex = _previousIndex;
    [self layoutCards];
}

-(void)leftActionForCard:(UIView *)card {
    CGPoint finishPoint = CGPointMake(-500, self.originalPoint.y);
    [UIView animateWithDuration:0.3
                     animations:^{
                         card.center = finishPoint;
                     } completion:^(BOOL complete) {
                         if ([self.delegate respondsToSelector:@selector(cards:didLeftRemovedItemAtIndex:)]) {
                             [self.delegate cards:self didLeftRemovedItemAtIndex:_currentIndex];
                         }
                         [self leftCardSwipedAction:card];
                     }];
}

- (void)leftCardSwipedAction:(UIView *)card {
    self.swipeEnded = YES;
    card.transform = CGAffineTransformMakeRotation(0);
    card.center = self.originalPoint;
    CGRect cardFrame = card.frame;
    _reusingView = card;
    [self.visibleViews removeObject:card];
    [card removeFromSuperview];
    
    _lastCard = nil;
    NSInteger totalNumber = [self.dataSource numberOfItemsInCards:self];
    UIView *newCard;
    NSInteger newIndex = _currentIndex + _numberOfVisibleItems;
    if (newIndex < totalNumber) {
        newCard = [self.dataSource cards:self viewForItemAtIndex:newIndex reusingView:_reusingView];
    } else {        
        if (_showedCyclically) {
            if (totalNumber == 1) {
                newIndex = 0;
            } else {
                newIndex %= totalNumber;
            }            
            newCard = [self.dataSource cards:self viewForItemAtIndex:newIndex reusingView:_reusingView];
        }
    }
    if (newCard) {
        newCard.frame = cardFrame;
        [self.visibleViews addObject:newCard];
    }
    
    if ([self.delegate respondsToSelector:@selector(cards:didRemovedItemAtIndex:)]) {
        [self.delegate cards:self didRemovedItemAtIndex:_currentIndex];
    }
    self.currentIndex ++;
    [self layoutCards];
}

#pragma mark resolve UITableView and UIPageViewController panGesture Conflict
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([otherGestureRecognizer.view isKindOfClass:[UITableView class]]) {
    }
    return NO;
}
@end
