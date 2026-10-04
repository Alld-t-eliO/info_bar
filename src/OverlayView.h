#import <Cocoa/Cocoa.h>
@interface OverlayView : NSView
@property CGFloat scale;
@property CGFloat indicatorSpacing;
@property CGFloat backgroundOpacity;
@property BOOL showBackground;
@property BOOL locked;
@property BOOL snapToEdges;
@property BOOL colorByLoad;
@property BOOL useIcons;
@property BOOL neon;
@property NSInteger layout;
@property (copy) NSArray<NSString *> *indicators;
@property (copy) NSSet<NSString *> *graphs;
@property (strong) NSMutableDictionary<NSString *, NSColor *> *colors;
@property (copy) void (^geometryChanged)(void);
- (NSSize)preferredSize;
- (void)updateValues:(NSDictionary<NSString *, NSNumber *> *)values;
@end
