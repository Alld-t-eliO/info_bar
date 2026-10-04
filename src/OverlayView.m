#import "OverlayView.h"
#import <math.h>
@interface OverlayView ()
@property (strong) NSDictionary *values;
@property (strong) NSMutableDictionary<NSString *, NSMutableArray<NSNumber *> *> *history;
@property (strong) NSTrackingArea *hoverArea;
@property BOOL hovering;
@property BOOL resizing;
@property NSPoint dragStart;
@property NSRect initialFrame;
@property CGFloat initialScale;
@end
@implementation OverlayView
- (instancetype)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _indicatorSpacing = 16; _scale = 1; _backgroundOpacity = .35; _snapToEdges = YES;
        _indicators = @[@"CPU", @"RAM", @"Metal"];
        _graphs = [NSSet set];
        _colors = [@{@"CPU":NSColor.systemGreenColor, @"RAM":NSColor.systemGreenColor, @"Metal":NSColor.systemGreenColor} mutableCopy];
        _history = [NSMutableDictionary dictionary];
    }
    return self;
}
- (BOOL)isFlipped { return YES; }
- (BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }
- (NSSize)preferredSize {
    CGFloat cell = self.layout == 1 ? 132 : 116+self.indicatorSpacing, gap = self.layout == 2 ? 8 : 0;
    return self.layout == 1 ? NSMakeSize(cell*self.scale+24, 34*self.indicators.count*self.scale)
        : NSMakeSize((cell*self.indicators.count + gap*(self.indicators.count-1))*self.scale+24, 34*self.scale);
}
- (void)updateValues:(NSDictionary<NSString *,NSNumber *> *)values {
    self.values = values;
    for (NSString *key in values) {
        if (!self.history[key]) self.history[key] = [NSMutableArray array];
        [self.history[key] addObject:values[key]];
        if (self.history[key].count > 60) [self.history[key] removeObjectAtIndex:0];
    }
    self.needsDisplay = YES;
}
- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    if (self.hoverArea) [self removeTrackingArea:self.hoverArea];
    self.hoverArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingMouseEnteredAndExited|NSTrackingActiveAlways|NSTrackingInVisibleRect owner:self userInfo:nil];
    [self addTrackingArea:self.hoverArea];
}
- (void)mouseEntered:(NSEvent *)event { self.hovering = YES; self.needsDisplay = YES; }
- (void)mouseExited:(NSEvent *)event { self.hovering = NO; self.needsDisplay = YES; }
- (NSRect)handleRect { return NSMakeRect(MAX(0,self.bounds.size.width-24), 0, MIN(24,self.bounds.size.width), self.bounds.size.height); }
- (NSMenu *)menuForEvent:(NSEvent *)event {
    [self.menu update];
    return self.menu;
}
- (void)rightMouseDown:(NSEvent *)event {
    [NSMenu popUpContextMenu:[self menuForEvent:event] withEvent:event forView:self];
}
- (void)resetCursorRects {
    if (!self.locked) {
        NSRect body = self.bounds; body.size.width = MAX(0,body.size.width-24);
        [self addCursorRect:body cursor:NSCursor.openHandCursor];
        [self addCursorRect:self.handleRect cursor:NSCursor.resizeLeftRightCursor];
    }
}
- (void)mouseDown:(NSEvent *)event {
    if (event.modifierFlags & NSEventModifierFlagControl) {
        [self rightMouseDown:event];
        return;
    }
    if (self.locked) return;
    self.dragStart = NSEvent.mouseLocation;
    self.initialFrame = self.window.frame;
    self.initialScale = self.scale;
    self.resizing = NSPointInRect([self convertPoint:event.locationInWindow fromView:nil], self.handleRect);
}
- (void)mouseDragged:(NSEvent *)event {
    if (self.locked) return;
    NSPoint p = NSEvent.mouseLocation;
    CGFloat dx = p.x-self.dragStart.x, dy = p.y-self.dragStart.y;
    if (self.resizing) {
        CGFloat w = self.initialFrame.size.width, h = self.initialFrame.size.height;
        CGFloat ratio = 1+(dx*w-dy*h)/(w*w+h*h);
        self.scale = fmin(2.5, fmax(.6, self.initialScale*ratio));
        NSSize size = self.preferredSize;
        [self.window setFrame:NSMakeRect(self.initialFrame.origin.x, NSMaxY(self.initialFrame)-size.height, size.width, size.height) display:YES];
    } else {
        [self.window setFrameOrigin:NSMakePoint(self.initialFrame.origin.x+dx,self.initialFrame.origin.y+dy)];
    }
    self.needsDisplay = YES;
}
- (void)mouseUp:(NSEvent *)event {
    if (self.locked) return;
    NSRect f = self.window.frame;
    NSScreen *screen = self.window.screen ?: NSScreen.mainScreen;
    if (self.snapToEdges && screen) {
        NSRect area = NSInsetRect(screen.visibleFrame, 10, 10);
        if (fabs(NSMinX(f)-NSMinX(area)) < 20) f.origin.x = NSMinX(area);
        if (fabs(NSMaxX(f)-NSMaxX(area)) < 20) f.origin.x = NSMaxX(area)-f.size.width;
        if (fabs(NSMinY(f)-NSMinY(area)) < 20) f.origin.y = NSMinY(area);
        if (fabs(NSMaxY(f)-NSMaxY(area)) < 20) f.origin.y = NSMaxY(area)-f.size.height;
        [self.window setFrame:f display:YES];
    }
    [self.window invalidateCursorRectsForView:self];
    if (self.geometryChanged) self.geometryChanged();
}
- (void)drawRect:(NSRect)dirtyRect {
    [NSColor.clearColor set]; NSRectFillUsingOperation(self.bounds, NSCompositingOperationCopy);
    CGFloat s = self.scale;
    if (self.showBackground && self.layout != 2) {
        [[NSColor colorWithWhite:0 alpha:self.backgroundOpacity] setFill];
        [[NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:17*s yRadius:17*s] fill];
    }
    [self.indicators enumerateObjectsUsingBlock:^(NSString *key, NSUInteger i, BOOL *stop) {
        (void)stop;
        CGFloat width = 116+self.indicatorSpacing;
        NSRect cell = self.layout == 1 ? NSMakeRect(0,i*34*s,132*s,34*s) : NSMakeRect(i*(width+(self.layout==2?8:0))*s,0,width*s,34*s);
        if (self.showBackground && self.layout == 2) {
            [[NSColor colorWithWhite:0 alpha:self.backgroundOpacity] setFill];
            [[NSBezierPath bezierPathWithRoundedRect:cell xRadius:17*s yRadius:17*s] fill];
        }
        NSNumber *number = self.values[key];
        double value = number.doubleValue;
        NSColor *color = self.colors[key] ?: NSColor.whiteColor;
        if (self.colorByLoad && number && value >= 0) color = value >= 85 ? NSColor.systemRedColor : value >= 60 ? NSColor.systemOrangeColor : NSColor.systemGreenColor;
        BOOL graph = [self.graphs containsObject:key];
        NSString *label = key;
        if (self.useIcons) label = [@{@"CPU":@"⚙",@"RAM":@"▤",@"Metal":@"◇"} objectForKey:key];
        NSString *text = number && value >= 0 ? [NSString stringWithFormat:@"%@: %.0f%%",label,value] : [NSString stringWithFormat:@"%@: —",label];
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowColor = self.neon ? color : NSColor.blackColor;
        shadow.shadowBlurRadius = self.neon ? 7*s : 2*s;
        NSDictionary *attrs = @{NSFontAttributeName:[NSFont monospacedDigitSystemFontOfSize:13*s weight:NSFontWeightSemibold],NSForegroundColorAttributeName:color,NSShadowAttributeName:shadow};
        NSSize size = [text sizeWithAttributes:attrs];
        [text drawAtPoint:NSMakePoint(NSMidX(cell)-size.width/2, cell.origin.y+(graph?3*s:(34*s-size.height)/2)) withAttributes:attrs];
        if (graph) {
            NSArray<NSNumber *> *points = self.history[key];
            NSBezierPath *path = [NSBezierPath bezierPath];
            BOOL started = NO;
            for (NSUInteger j=0; j<points.count; j++) {
                double v = points[j].doubleValue;
                if (v < 0) { started = NO; continue; }
                NSPoint p = NSMakePoint(cell.origin.x+14*s+(j/59.0)*(cell.size.width-28*s),cell.origin.y+30*s-fmin(100,fmax(0,v))*.09*s);
                if (started) [path lineToPoint:p]; else [path moveToPoint:p];
                started = YES;
            }
            [color setStroke]; path.lineWidth = s; [path stroke];
        }
    }];
    if (self.hovering && !self.locked) {
        [[NSColor colorWithWhite:1 alpha:.45] setStroke];
        NSBezierPath *outline = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds,1,1) xRadius:12*s yRadius:12*s];
        [outline stroke];

    }
}
@end
