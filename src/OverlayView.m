#import "OverlayView.h"

@implementation OverlayView

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self)
    {
        _textColor = [NSColor systemGreenColor];
        _showBackground = NO;
        _statsText = @"GPU: --%   RAM: --%   CPU: --%";
    }
    return self;
}

- (void)updateStatsText:(NSString *)text
{
    self.statsText = text;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    /* Fond totalement transparent par défaut. */
    [[NSColor clearColor] set];
    NSRectFillUsingOperation(self.bounds, NSCompositingOperationCopy);

    if (self.showBackground)
    {
        NSBezierPath *pill = [NSBezierPath bezierPathWithRoundedRect:self.bounds
                                                               xRadius:self.bounds.size.height / 2.0
                                                               yRadius:self.bounds.size.height / 2.0];
        [[NSColor colorWithWhite:0.0 alpha:0.35] set];
        [pill fill];
    }

    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [NSColor colorWithWhite:0.0 alpha:0.8];
    shadow.shadowBlurRadius = 3.0;
    shadow.shadowOffset = NSMakeSize(0, -1);

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentCenter;

    NSDictionary *attrs = @{
        NSFontAttributeName: [NSFont monospacedDigitSystemFontOfSize:13 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: self.textColor,
        NSParagraphStyleAttributeName: style,
        NSShadowAttributeName: shadow
    };

    NSSize textSize = [self.statsText sizeWithAttributes:attrs];
    NSRect textRect = NSMakeRect(0,
                                  (self.bounds.size.height - textSize.height) / 2.0,
                                  self.bounds.size.width,
                                  textSize.height);

    [self.statsText drawInRect:textRect withAttributes:attrs];
}

@end
