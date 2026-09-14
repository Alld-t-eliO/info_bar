#import "AppDelegate.h"
#import "OverlayView.h"
#import "cpu.h"
#import "ram.h"
#import "gpu.h"

static NSString *const kColorRKey = @"MonitorBarColorR";
static NSString *const kColorGKey = @"MonitorBarColorG";
static NSString *const kColorBKey = @"MonitorBarColorB";
static NSString *const kShowBackgroundKey = @"MonitorBarShowBackground";
static NSString *const kWindowFrameAutosaveName = @"MonitorBarWindowFrame";

@interface AppDelegate ()

@property (nonatomic, strong) NSWindow *window;
@property (nonatomic, strong) OverlayView *overlayView;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation AppDelegate

#pragma mark - Cycle de vie

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [self setupWindow];
    [self setupMenu];

    /* get_cpu_usage() a besoin de deux relevés pour calculer un delta. */
    get_cpu_usage();

    [self refreshStats];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                    target:self
                                                  selector:@selector(refreshStats)
                                                  userInfo:nil
                                                   repeats:YES];
}

#pragma mark - Fenêtre

- (void)setupWindow
{
    NSRect defaultFrame = NSMakeRect(100, 100, 280, 30);

    self.window = [[NSWindow alloc] initWithContentRect:defaultFrame
                                               styleMask:NSWindowStyleMaskBorderless
                                                 backing:NSBackingStoreBuffered
                                                   defer:NO];

    self.window.opaque = NO;
    self.window.backgroundColor = [NSColor clearColor];
    self.window.hasShadow = NO;
    self.window.level = NSStatusWindowLevel;
    self.window.movableByWindowBackground = YES;
    self.window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces
                                    | NSWindowCollectionBehaviorStationary
                                    | NSWindowCollectionBehaviorFullScreenAuxiliary;

    self.overlayView = [[OverlayView alloc] initWithFrame:defaultFrame];
    self.overlayView.textColor = [self loadSavedColor];
    self.overlayView.showBackground = [[NSUserDefaults standardUserDefaults] boolForKey:kShowBackgroundKey];

    self.window.contentView = self.overlayView;

    /* Restaure la position sauvegardée, sinon utilise la position par défaut. */
    if (![self.window setFrameUsingName:kWindowFrameAutosaveName])
    {
        [self.window setFrame:defaultFrame display:YES];
    }
    self.window.frameAutosaveName = kWindowFrameAutosaveName;

    [self.window orderFrontRegardless];
}

#pragma mark - Menu contextuel (clic droit sur la barre)

- (void)setupMenu
{
    NSMenu *menu = [[NSMenu alloc] init];

    [menu addItemWithTitle:@"Choisir une couleur..."
                     action:@selector(chooseColor)
              keyEquivalent:@""];

    NSMenuItem *bgItem = [menu addItemWithTitle:@"Fond semi-transparent"
                                          action:@selector(toggleBackground:)
                                   keyEquivalent:@""];
    bgItem.state = self.overlayView.showBackground ? NSControlStateValueOn : NSControlStateValueOff;

    [menu addItem:[NSMenuItem separatorItem]];

    [menu addItemWithTitle:@"Quitter"
                     action:@selector(quit)
              keyEquivalent:@"q"];

    for (NSMenuItem *item in menu.itemArray)
    {
        item.target = self;
    }

    self.overlayView.menu = menu;
}

- (void)toggleBackground:(NSMenuItem *)sender
{
    self.overlayView.showBackground = !self.overlayView.showBackground;
    sender.state = self.overlayView.showBackground ? NSControlStateValueOn : NSControlStateValueOff;

    [[NSUserDefaults standardUserDefaults] setBool:self.overlayView.showBackground
                                              forKey:kShowBackgroundKey];

    [self.overlayView setNeedsDisplay:YES];
}

- (void)quit
{
    [NSApp terminate:nil];
}

#pragma mark - Couleur

- (void)chooseColor
{
    NSColorPanel *panel = [NSColorPanel sharedColorPanel];
    panel.color = self.overlayView.textColor;
    panel.target = self;
    panel.action = @selector(colorChanged:);
    panel.showsAlpha = NO;

    [panel makeKeyAndOrderFront:nil];
}

- (void)colorChanged:(NSColorPanel *)panel
{
    self.overlayView.textColor = panel.color;
    [self.overlayView setNeedsDisplay:YES];
    [self saveColor:panel.color];
}

- (void)saveColor:(NSColor *)color
{
    NSColor *rgb = [color colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setDouble:rgb.redComponent forKey:kColorRKey];
    [defaults setDouble:rgb.greenComponent forKey:kColorGKey];
    [defaults setDouble:rgb.blueComponent forKey:kColorBKey];
}

- (NSColor *)loadSavedColor
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([defaults objectForKey:kColorRKey] == nil)
    {
        return [NSColor systemGreenColor];
    }

    double r = [defaults doubleForKey:kColorRKey];
    double g = [defaults doubleForKey:kColorGKey];
    double b = [defaults doubleForKey:kColorBKey];

    return [NSColor colorWithDeviceRed:r green:g blue:b alpha:1.0];
}

#pragma mark - Rafraîchissement des stats

- (void)refreshStats
{
    double cpu = get_cpu_usage();
    RAMInfo ram = get_ram_info();
    GPUInfo gpu = get_gpu_info();

    double gpuPercent = 0.0;
    if (gpu.memory > 0)
    {
        gpuPercent = (double)gpu.usedMemory / (double)gpu.memory * 100.0;
    }

    if (cpu < 0)
    {
        cpu = 0;
    }

    NSString *text = [NSString stringWithFormat:@"GPU: %.0f%%   RAM: %.0f%%   CPU: %.0f%%",
                       gpuPercent, ram.percent_used, cpu];

    [self.overlayView updateStatsText:text];
}

@end
