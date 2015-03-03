//
//  DZNSegmentedControl.m
//  DZNSegmentedControl
//  https://github.com/dzenbot/DZNSegmentedControl
//
//  Created by Ignacio Romero Zurbuchen on 3/4/14.
//  Copyright (c) 2014 DZN Labs. All rights reserved.
//  Licence: MIT-Licence
//

#import "DZNSegmentedControl.h"

@interface DZNSegmentedControl ()

@property (nonatomic) BOOL initializing;
@property (nonatomic, strong) UIView *selectionIndicator;
@property (nonatomic, strong) UIView *hairline;
@property (nonatomic, strong) NSMutableDictionary *titleColors;
@property (nonatomic, strong) NSMutableDictionary *countColors;
@property (nonatomic, strong) NSMutableArray *counts; // of NSNumber
@property (nonatomic, getter = isTransitioning) BOOL transitioning;

@end

@implementation DZNSegmentedControl

@synthesize barPosition = _barPosition;

#pragma mark - Initialize Methods

- (void)commonInit
{
    _initializing = YES;
    
    _showsCount = YES;
    _selectedSegmentIndex = -1;
    _font = [UIFont systemFontOfSize:15.0f];
    _selectionIndicatorHeight = 2.0f;
    _animationDuration = 0.2;
    _autoAdjustSelectionIndicatorWidth = YES;
    
    _selectionIndicator = [UIView new];
    _selectionIndicator.backgroundColor = self.tintColor;
    [self addSubview:_selectionIndicator];
    
    _hairline = [UIView new];
    _hairline.backgroundColor = [UIColor lightGrayColor];
    [self addSubview:_hairline];
    
    _titleColors = [NSMutableDictionary new];
    _countColors = [NSMutableDictionary new];
    _counts = [NSMutableArray array];

    _initializing = NO;
}

- (id)init
{
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithItems:(NSArray *)items
{
    self = [super init];
    if (self) {
        [self commonInit];
        self.items = items;
    }
    return self;
}

#pragma mark - UIView Methods

- (CGSize)sizeThatFits:(CGSize)size
{
    return CGSizeMake((self.width ? self.width : self.superview.bounds.size.width), self.height);
}

- (void)sizeToFit
{
    CGRect rect = self.frame;
    rect.size = [self sizeThatFits:rect.size];
    self.frame = rect;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self sizeToFit];
    
    if ([self buttons].count == 0) {
        _selectedSegmentIndex = -1;
    }
    else if (self.selectedSegmentIndex < 0) {
        _selectedSegmentIndex = 0;
    }
    
    [[self buttons] enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {

        CGRect rect = CGRectMake(roundf(self.bounds.size.width/self.numberOfSegments)*idx, 0.0f, roundf(self.bounds.size.width/self.numberOfSegments),
                                 self.bounds.size.height);
        [button setFrame:rect];

        CGFloat topInset = (self.barPosition > UIBarPositionBottom) ? -4.0f : 4.0f;
        [button setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, topInset, 0.0f)];

        if (idx == self.selectedSegmentIndex) {
            button.selected = YES;
        }
    }];
    
    self.selectionIndicator.frame = [self selectionIndicatorRect];
    _hairline.frame = [self hairlineRect];
    
    [self sendSubviewToBack:self.selectionIndicator];
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];

    if (newSuperview) {
        [self layoutIfNeeded];
    }
}

- (void)didMoveToWindow
{
    if (!self.backgroundColor) {
        self.backgroundColor = [UIColor whiteColor];
    }
    
    [self configureSegments];
    [self layoutIfNeeded];
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(self.width, self.height);
}

#pragma mark - Getter Methods

- (CGFloat)height
{
    return (_height ? : self.showsCount ? 56.0f : 30.0f);
}

- (CGFloat)width
{
    return (_width ? : self.superview.bounds.size.width);
}

- (NSUInteger)numberOfSegments
{
    return self.items.count;
}

- (NSArray *)buttons
{
    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:self.items.count];
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            [buttons addObject:view];
        }
    }
    return buttons;
}

- (UIButton *)buttonAtIndex:(NSUInteger)segment
{
    if (self.items.count > 0 && segment < [self buttons].count) {
        return (UIButton *)[self buttons][segment];
    }
    return nil;
}

- (UIButton *)selectedButton
{
    if (self.selectedSegmentIndex >= 0) {
        return [self buttonAtIndex:(NSUInteger)self.selectedSegmentIndex];
    }
    return nil;
}

- (NSString *)stringForSegmentAtIndex:(NSUInteger)segment
{
    UIButton *button = [self buttonAtIndex:segment];
    return [[button attributedTitleForState:UIControlStateNormal] string];
}

- (NSString *)titleForSegmentAtIndex:(NSUInteger)segment
{
    if (self.showsCount) {
        NSString *title = [self stringForSegmentAtIndex:segment];
        NSArray *components = [title componentsSeparatedByString:@"\n"];
        
        if (components.count == 2) {
            return components[self.inverseTitles ? 0 : 1];
        }
        else {
            return nil;
        }
    }
    return self.items[segment];
}

- (NSNumber *)countForSegmentAtIndex:(NSUInteger)segment
{
    return segment < self.counts.count ? self.counts[segment] : @(0);
}

- (UIColor *)titleColorForState:(UIControlState)state
{
    UIColor *color = self.titleColors[@(state)];
    if (!color) {
        switch (state) {
            case UIControlStateNormal:              return [UIColor darkGrayColor];
            case UIControlStateHighlighted:         return self.tintColor;
            case UIControlStateDisabled:            return [UIColor lightGrayColor];
            case UIControlStateSelected:            return self.tintColor;
            default:                                return self.tintColor;
        }
    }
    
    return color;
}

- (CGRect)selectionIndicatorRect
{
    CGRect frame = CGRectZero;
    UIButton *button = [self selectedButton];
    NSString *title = [self titleForSegmentAtIndex:(NSUInteger)button.tag];
    
    if (title.length == 0) {
        return frame;
    }
    
    frame.origin.y = (_barPosition > UIBarPositionBottom) ? 0.0f : (button.frame.size.height-self.selectionIndicatorHeight);
    
    if (self.autoAdjustSelectionIndicatorWidth) {
        id attributes = nil;
        
        if (!self.showsCount) {
            NSAttributedString *attributedString = [button attributedTitleForState:UIControlStateSelected];
            if (attributedString.string.length == 0) {
                return CGRectZero;
            }
            
            NSRangePointer range = nil;
            attributes = [attributedString attributesAtIndex:0 effectiveRange:range];
        }
        
        frame.size = CGSizeMake([title sizeWithAttributes:attributes].width, self.selectionIndicatorHeight);
        frame.origin.x = (button.frame.size.width*(self.selectedSegmentIndex))+(button.frame.size.width-frame.size.width)/2;
    }
    else {
        frame.size = CGSizeMake(button.frame.size.width, self.selectionIndicatorHeight);
        frame.origin.x = (button.frame.size.width*(self.selectedSegmentIndex));
    }
    
    return frame;
}

- (UIColor *)hairlineColor
{
    return self.hairline.backgroundColor;
}

- (CGRect)hairlineRect
{
    CGRect frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, 0.5f);
    frame.origin.y = (self.barPosition > UIBarPositionBottom) ? 0.0f : self.frame.size.height;
    
    return frame;
}

// Calculate the most appropriate font size for a button title
- (CGFloat)appropriateFontSizeForTitle:(NSString *)title
{
    CGFloat fontSize = 12.0f;
    CGFloat minFontSize = 8.0f;
    
    if (!self.adjustsFontSizeToFitWidth) {
        return fontSize;
    }
    
    CGFloat buttonWidth = roundf(self.bounds.size.width/self.numberOfSegments);
    CGSize constraintSize = CGSizeMake(buttonWidth, MAXFLOAT);
    
    do {
        // Creates a new font instance with the current font size
        UIFont *font = [UIFont fontWithName:self.font.fontName size:fontSize];
        CGRect textRect = [title boundingRectWithSize:constraintSize options:0 attributes:@{NSFontAttributeName:font} context:nil];
        
        // If the new text rect's width matches the constraint width, return the font size
        if (textRect.size.width <= constraintSize.width) {
            return fontSize;
        }
        
        // Decreases the font size and tries again
        fontSize -= 1.0f;
        
    } while (fontSize > minFontSize);
    
    return fontSize;
}


#pragma mark - Setter Methods

- (void)setTintColor:(UIColor *)color
{
    if (!color || !self.items || self.initializing) {
        return;
    }
    
    [super setTintColor:color];

    [self setTitleColor:color forState:UIControlStateHighlighted];
    [self setTitleColor:color forState:UIControlStateSelected];
}

- (void)setItems:(NSArray *)items
{
    if (self.items) {
        [self removeAllSegments];
    }

    if (items) {
        _items = [NSArray arrayWithArray:items];
        _counts = [NSMutableArray arrayWithCapacity:items.count];
        
        for (int i = 0; i < items.count; i++) {
            [self.counts addObject:@0];
        }
        
        [self insertAllSegments];
    }
}

- (void)setDelegate:(id<DZNSegmentedControlDelegate>)delegate
{
    _delegate = delegate;
    _barPosition = [delegate positionForBar:self];
}

- (void)setSelectedSegmentIndex:(NSInteger)segment
{
    [self setSelectedIndex:segment animated:YES];
}

- (void)setSelectedIndex:(NSInteger)segment animated:(BOOL)animated
{
    if (segment > self.numberOfSegments - 1) {
        segment = 0;
    }
    [self private_selectSegmentAtIndex:(NSUInteger)segment animated:animated];
}

- (void)private_selectSegmentAtIndex:(NSUInteger)segment animated:(BOOL)animated
{
    if (self.selectedSegmentIndex == segment || self.isTransitioning) {
        return;
    }

    [self disableAllButtonsSelection];
    [self enableAllButtonsInteraction:NO];

    _selectedSegmentIndex = segment;
//    _transitioning = YES;

    void (^selectionIndicatorUpdateBlock)() = ^{
        self.selectionIndicator.frame = [self selectionIndicatorRect];
    };
    if (animated) {
        UIButton *button = [self buttonAtIndex:segment];
        CGFloat damping = !self.bouncySelectionIndicator ? : 0.65f;
        CGFloat velocity = !self.bouncySelectionIndicator ? : 0.5f;
        CGFloat duration = (self.selectedSegmentIndex < 0.0f) ? 0.0f : self.animationDuration;
        [UIView animateWithDuration:duration
                              delay:0.0f
             usingSpringWithDamping:damping
              initialSpringVelocity:velocity
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                         animations:selectionIndicatorUpdateBlock
                         completion:^(BOOL finished) {
                             [self enableAllButtonsInteraction:YES];
                             button.userInteractionEnabled = NO;
                             _transitioning = NO;
                         }];
    }
    else {
        selectionIndicatorUpdateBlock();
    }
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)setTitle:(NSString *)title forSegmentAtIndex:(NSUInteger)segment
{
    if (!title) {
        return;
    }
    
    NSAssert(segment <= self.numberOfSegments, @"Cannot assign a title to non-existing segment.");
    NSAssert(segment >= 0, @"Cannot assign a title to a negative segment.");
    
    NSMutableArray *items = [NSMutableArray arrayWithArray:self.items];
    
    if (segment >= self.numberOfSegments) {
        [items insertObject:title atIndex:self.numberOfSegments];
        [self addButtonForSegment:segment];
    }
    else {
        [items replaceObjectAtIndex:segment withObject:title];
        [self setCount:[self countForSegmentAtIndex:segment] forSegmentAtIndex:segment];
    }
    
    _items = items;
}

- (void)setCount:(NSNumber *)count forSegmentAtIndex:(NSUInteger)segment
{
    if (!count || !self.items) {
        return;
    }
    
    NSAssert(segment < self.numberOfSegments, @"Cannot assign a count to non-existing segment.");
    NSAssert(segment >= 0, @"Cannot assign a title to a negative segment.");
    
    self.counts[segment] = count;

    [self configureSegments];
}

- (void)setAttributedTitle:(NSAttributedString *)attributedString forSegmentAtIndex:(NSUInteger)segment
{
    UIButton *button = [self buttonAtIndex:segment];
    button.titleLabel.numberOfLines = (self.showsCount) ? 2 : 1;
    
    [button setAttributedTitle:attributedString forState:UIControlStateNormal];
    [button setAttributedTitle:attributedString forState:UIControlStateHighlighted];
    [button setAttributedTitle:attributedString forState:UIControlStateSelected];
    [button setAttributedTitle:attributedString forState:UIControlStateDisabled];
    
    [self setTitleColor:[self titleColorForState:UIControlStateNormal] forState:UIControlStateNormal];
    [self setTitleColor:[self titleColorForState:UIControlStateHighlighted] forState:UIControlStateHighlighted];
    [self setTitleColor:[self titleColorForState:UIControlStateDisabled] forState:UIControlStateDisabled];
    [self setTitleColor:[self titleColorForState:UIControlStateSelected] forState:UIControlStateSelected];
    
    self.selectionIndicator.frame = [self selectionIndicatorRect];
}

- (void)setTintColor:(UIColor *)tintColor forSegmentAtIndex:(NSUInteger)segment
{
    if (!tintColor) {
        return;
    }
    
    NSAssert(segment < self.numberOfSegments, @"Cannot assign a tint color to non-existing segment.");
    NSAssert(segment >= 0, @"Cannot assign a tint color to a negative segment.");
    NSAssert([tintColor isKindOfClass:[UIColor class]], @"Cannot assign a tint color with an unvalid color object.");
    
    UIButton *button = [self buttonAtIndex:segment];
    button.backgroundColor = tintColor;
}

- (void)setTitleColor:(UIColor *)color forState:(UIControlState)state
{
    NSAssert([color isKindOfClass:[UIColor class]], @"Cannot assign a title color with an unvalid color object.");
    self.titleColors[@(state)] = color;
    [self private_updateButtonTitlesForState:state];
}

- (void)setCountColor:(UIColor *)color forState:(UIControlState)state
{
    NSAssert([color isKindOfClass:[UIColor class]], @"Cannot assign a count color with an unvalid color object.");
    self.countColors[@(state)] = color;
    [self private_updateButtonTitlesForState:state];
}

- (void)private_updateButtonTitlesForState:(UIControlState)state
{
    for (UIButton *button in [self buttons]) {
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[button attributedTitleForState:state]];
        NSString *string = attributedString.string;

        NSMutableParagraphStyle *style  = [[NSMutableParagraphStyle alloc] init];
        style.alignment = NSTextAlignmentCenter;
        style.lineBreakMode = (self.showsCount) ? NSLineBreakByWordWrapping : NSLineBreakByTruncatingTail;
        style.lineBreakMode = NSLineBreakByWordWrapping;
        style.minimumLineHeight = 10.0f;

        [attributedString addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, string.length)];

        UIColor *titleColor = self.titleColors[@(state)] ?: self.tintColor;
        UIColor *countColor = self.countColors[@(state)] ?: [titleColor colorWithAlphaComponent:0.5f];

        if (self.showsCount) {
            NSArray *components = [attributedString.string componentsSeparatedByString:@"\n"];
            if (components.count < 2) {
                return;
            }

            NSString *count = components[self.inverseTitles ? 1 : 0];
            NSString *title = components[self.inverseTitles ? 0 : 1];
            CGFloat fontSizeForTitle = [self appropriateFontSizeForTitle:title];

            [attributedString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:20.0f] range:[string rangeOfString:count]];
            [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:self.font.fontName size:fontSizeForTitle] range:[string rangeOfString:title]];

            if (state == UIControlStateNormal) {
                UIColor *topColor = self.inverseTitles ? countColor : titleColor;
                UIColor *bottomColor = self.inverseTitles ? titleColor : countColor;
                NSUInteger topLength = self.inverseTitles ? title.length : count.length;
                NSUInteger bottomLength = self.inverseTitles ? count.length : title.length;

                [attributedString addAttribute:NSForegroundColorAttributeName value:topColor range:NSMakeRange(0, topLength)];
                [attributedString addAttribute:NSForegroundColorAttributeName value:bottomColor range:NSMakeRange(topLength, bottomLength+1)];
            }
            else {
                [attributedString addAttribute:NSForegroundColorAttributeName value:self.tintColor range:NSMakeRange(0, string.length)];
                if (state == UIControlStateSelected) {
                    self.selectionIndicator.backgroundColor = self.tintColor;
                }
            }
        }
        else {
            [attributedString addAttribute:NSFontAttributeName value:self.font range:NSMakeRange(0, attributedString.string.length)];
            [attributedString addAttribute:NSForegroundColorAttributeName value:titleColor range:NSMakeRange(0, attributedString.string.length)];
        }

        [button setAttributedTitle:attributedString forState:state];
    }
}

- (void)setDisplayCount:(BOOL)count
{
    if (self.showsCount == count) {
        return;
    }
    
    _showsCount = count;
    
    for (NSUInteger i = 0; i < [self buttons].count; i++) {
        [self configureButtonForSegment:i];
    }
    
    self.selectionIndicator.frame = [self selectionIndicatorRect];
}

- (void)setFont:(UIFont *)font
{
    if ([self.font.fontName isEqualToString:font.fontName]) {
        return;
    }
    
    _font = font;
    
    for (NSUInteger i = 0; i < [self buttons].count; i++) {
        [self configureButtonForSegment:i];
    }
    
    self.selectionIndicator.frame = [self selectionIndicatorRect];
}

- (void)setShowsGroupingSeparators:(BOOL)showsGroupingSeparators
{
    if (self.showsGroupingSeparators == showsGroupingSeparators) {
        return;
    }
    
    _showsGroupingSeparators = showsGroupingSeparators;
    
    for (NSUInteger i = 0; i < [self buttons].count; i++) {
        [self configureButtonForSegment:i];
    }
    
    self.selectionIndicator.frame = [self selectionIndicatorRect];
}

- (void)setNumberFormatter:(NSNumberFormatter *)numberFormatter
{
    if ([self.numberFormatter isEqual:numberFormatter]) {
        return;
    }
    
    _numberFormatter = numberFormatter;
    
    for (NSUInteger i = 0; i < [self buttons].count; i++) {
        [self configureButtonForSegment:i];
    }
    
    self.selectionIndicator.frame = [self selectionIndicatorRect];
}

- (void)setEnabled:(BOOL)enabled forSegmentAtIndex:(NSUInteger)segment
{
    UIButton *button = [self buttonAtIndex:segment];
    button.enabled = enabled;
}

- (void)setHairlineColor:(UIColor *)color
{
    if (self.initializing) {
        return;
    }
    
    self.hairline.backgroundColor = color;
}


#pragma mark - DZNSegmentedControl Methods

- (void)insertAllSegments
{
    for (NSUInteger i = 0; i < self.numberOfSegments; i++) {
        [self addButtonForSegment:i];
    }
}

- (void)addButtonForSegment:(NSUInteger)segment
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [button addTarget:self action:@selector(willSelectedButton:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(didSelectButton:) forControlEvents:UIControlEventTouchDragOutside|UIControlEventTouchDragInside|UIControlEventTouchDragEnter|UIControlEventTouchDragExit|UIControlEventTouchCancel|UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
    
    button.backgroundColor = nil;
    button.opaque = YES;
    button.clipsToBounds = YES;
    button.adjustsImageWhenHighlighted = NO;
    button.adjustsImageWhenDisabled = NO;
    button.exclusiveTouch = YES;
    button.tag = segment;

    [self addSubview:button];
}

- (void)configureSegments
{
    for (UIButton *button in [self buttons]) {
        [self configureButtonForSegment:(NSUInteger)button.tag];
    }
    
    self.selectionIndicator.frame = [self selectionIndicatorRect];
    self.selectionIndicator.backgroundColor = self.tintColor;
}

- (void)configureButtonForSegment:(NSUInteger)segment
{
    NSAssert(segment < self.numberOfSegments, @"Cannot configure a button for a non-existing segment.");
    NSAssert(segment >= 0, @"Cannot configure a button for a negative segment.");
    
    NSMutableString *title = [NSMutableString stringWithFormat:@"%@", self.items[segment]];
    
    if (self.showsCount) {
        NSNumber *count = [self countForSegmentAtIndex:segment];
        
        NSString *breakString = @"\n";
        NSString *countString;
        
        if (self.numberFormatter) {
            countString = [self.numberFormatter stringFromNumber:count];
        }
        else if (!self.numberFormatter && _showsGroupingSeparators) {
            countString = [[[self class] defaultFormatter] stringFromNumber:count];
        }
        else {
            countString = [NSString stringWithFormat:@"%@", count];
        }
        
        NSString *resultString = self.inverseTitles ? [breakString stringByAppendingString:countString] : [countString stringByAppendingString:breakString];
        
        [title insertString:resultString atIndex:self.inverseTitles ? title.length : 0];
    }
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:title];
    [self setAttributedTitle:attributedString forSegmentAtIndex:segment];
}

- (void)willSelectedButton:(id)sender
{
    UIButton *button = (UIButton *)sender;
    if (!self.isTransitioning) {
        self.selectedSegmentIndex = button.tag;
    }
}

- (void)didSelectButton:(id)sender
{
    UIButton *button = (UIButton *)sender;
    
    button.highlighted = NO;
    button.selected = YES;
}

- (void)disableAllButtonsSelection
{
    for (UIButton *button in [self buttons]) {
        button.highlighted = NO;
        button.selected = NO;
    }
}

- (void)enableAllButtonsInteraction:(BOOL)enable
{
    for (UIButton *button in [self buttons]) {
        button.userInteractionEnabled = enable;
    }
}

- (void)removeAllSegments
{
    if (self.isTransitioning) {
        return;
    }
    
    // Removes all the buttons
    [[self buttons] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    _items = nil;
    _counts = nil;
}

#pragma mark - Class Methods

+ (NSNumberFormatter *)defaultFormatter
{
    static NSNumberFormatter *defaultFormatter;

    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        defaultFormatter = [[NSNumberFormatter alloc] init];
        defaultFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        [defaultFormatter setGroupingSeparator:[[NSLocale currentLocale] objectForKey:NSLocaleGroupingSeparator]];
    });

    return defaultFormatter;
}

@end
