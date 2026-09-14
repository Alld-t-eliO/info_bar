#import <Cocoa/Cocoa.h>

@interface OverlayView : NSView

@property (nonatomic, strong) NSColor *textColor;
@property (nonatomic, assign) BOOL showBackground;
@property (nonatomic, copy) NSString *statsText;

- (void)updateStatsText:(NSString *)text;

@end
