#import "AppDelegate.h"
#import "OverlayView.h"
#import "cpu.h"
#import "ram.h"
#import "gpu.h"
#import <math.h>
@interface AppDelegate () <NSMenuDelegate, NSWindowDelegate>
@property (strong) NSWindow *window;
@property (strong) OverlayView *overlayView;
@property (strong) NSTimer *timer;
@property (strong) NSStatusItem *statusItem;
@property (copy) NSString *colorTarget;
@end
@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100,100,396,34) styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
    self.window.opaque = NO;
    self.window.backgroundColor = NSColor.clearColor;
    self.window.hasShadow = NO;
    self.window.movableByWindowBackground = NO;
    self.window.level = NSStatusWindowLevel;
    self.window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces|NSWindowCollectionBehaviorStationary|NSWindowCollectionBehaviorFullScreenAuxiliary;
    self.overlayView = [[OverlayView alloc] initWithFrame:NSMakeRect(0,0,396,34)];
    self.window.contentView = self.overlayView;
    [self loadSettings];
    [self.window setFrameUsingName:@"MonitorBarWindowFrame"];
    self.window.frameAutosaveName = @"MonitorBarWindowFrame";
    self.window.delegate = self;
    __weak AppDelegate *weakSelf = self;
    self.overlayView.geometryChanged = ^{ [weakSelf saveSettings]; };
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"MonitorBar"];
    menu.delegate = self;
    self.overlayView.menu = menu;
    [self menuNeedsUpdate:menu];
    [self resize];
    [self.window orderFrontRegardless];
    self.statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.title = @"▥";
    self.statusItem.button.toolTip = @"MonitorBar — afficher la barre et personnaliser";
    NSMenu *statusMenu = [[NSMenu alloc] initWithTitle:@"MonitorBar"];
    statusMenu.delegate = self;
    self.statusItem.menu = statusMenu;
    [self menuNeedsUpdate:statusMenu];
    get_cpu_usage();
    [self refreshStats];
    if ([NSProcessInfo.processInfo.arguments containsObject:@"--show-bar"]) [self showBar];
    self.timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(refreshStats) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}
- (void)showBar {
    self.overlayView.showBackground = YES;
    self.overlayView.backgroundOpacity = MAX(.65,self.overlayView.backgroundOpacity);
    self.overlayView.scale = MAX(1.0,self.overlayView.scale);
    [self resize];
    NSScreen *screen = NSScreen.mainScreen;
    NSRect area = screen.visibleFrame;
    NSSize size = self.window.frame.size;
    [self.window setFrameOrigin:NSMakePoint(NSMidX(area)-size.width/2,NSMidY(area)-size.height/2)];
    [NSApp activateIgnoringOtherApps:YES];
    [self.window orderFrontRegardless];
    [self.overlayView setNeedsDisplay:YES];
    [self.window displayIfNeeded];
    [self saveSettings];
}
- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    [self showBar];
    return YES;
}
- (void)refreshStats {
    RAMInfo ram = get_ram_info(); GPUInfo gpu = get_gpu_info();
    [self.overlayView updateValues:@{@"CPU":@(get_cpu_usage()), @"RAM":@(ram.total ? ram.percent_used : -1), @"Metal":@(gpu.memory ? (double)gpu.usedMemory/gpu.memory*100 : -1)}];
}
- (void)resize {
    NSRect f = self.window.frame;
    CGFloat top = NSMaxY(f);
    f.size = self.overlayView.preferredSize; f.origin.y = top-f.size.height;
    NSRect visible = (self.window.screen ?: NSScreen.mainScreen).visibleFrame;
    f.origin.x = fmax(NSMinX(visible),fmin(f.origin.x,NSMaxX(visible)-f.size.width));
    f.origin.y = fmax(NSMinY(visible),fmin(f.origin.y,NSMaxY(visible)-f.size.height));
    [self.window setFrame:f display:YES];
    [self.window invalidateCursorRectsForView:self.overlayView];
    self.overlayView.needsDisplay = YES;
}
- (NSMenuItem *)add:(NSString *)title to:(NSMenu *)menu action:(SEL)action value:(id)value checked:(BOOL)checked {
    NSMenuItem *item = [menu addItemWithTitle:title action:action keyEquivalent:@""];
    item.target = self; item.representedObject = value;
    item.state = checked ? NSControlStateValueOn : NSControlStateValueOff;
    return item;
}
- (NSMenu *)submenu:(NSString *)title to:(NSMenu *)parent {
    NSMenuItem *item = [parent addItemWithTitle:title action:nil keyEquivalent:@""];
    item.submenu = [[NSMenu alloc] initWithTitle:title];
    return item.submenu;
}
- (void)menuNeedsUpdate:(NSMenu *)menu {
    [menu removeAllItems];
    OverlayView *v = self.overlayView;
    menu.autoenablesItems = NO;
    [self add:@"Afficher la barre au centre" to:menu action:@selector(showBar) value:nil checked:NO];
    [menu addItem:NSMenuItem.separatorItem];
    [self add:@"Agrandir la barre" to:menu action:@selector(scale:) value:@(.15) checked:NO].enabled = !v.locked && v.scale < 2.5;
    [self add:@"Réduire la barre" to:menu action:@selector(scale:) value:@(-.15) checked:NO].enabled = !v.locked && v.scale > .6;
    [self add:@"Taille normale" to:menu action:@selector(scale:) value:@0 checked:NO].enabled = !v.locked;
    [menu addItem:NSMenuItem.separatorItem];
    [self add:@"Lueur néon" to:menu action:@selector(toggle:) value:@"neon" checked:v.neon];
    [self add:@"Couleur de tous les indicateurs…" to:menu action:@selector(chooseColor:) value:@"all" checked:NO];
    NSMenu *themes = [self submenu:@"Thèmes" to:menu];
    for (NSString *theme in @[@"Terminal",@"Discret",@"Néon"]) [self add:theme to:themes action:@selector(theme:) value:theme checked:NO];
    [self add:@"Fond semi-transparent" to:menu action:@selector(toggle:) value:@"showBackground" checked:v.showBackground];
    NSMenu *opacity = [self submenu:[NSString stringWithFormat:@"Opacité du fond : %.0f %%",v.backgroundOpacity*100] to:menu];
    NSMenuItem *sliderItem = [[NSMenuItem alloc] initWithTitle:@"Opacité" action:nil keyEquivalent:@""];
    NSView *container = [[NSView alloc] initWithFrame:NSMakeRect(0,0,220,36)];
    NSSlider *slider = [[NSSlider alloc] initWithFrame:NSMakeRect(12,6,196,24)];
    slider.minValue = 0; slider.maxValue = 1; slider.doubleValue = v.backgroundOpacity;
    slider.continuous = YES; slider.target = self; slider.action = @selector(opacity:);
    [slider setAccessibilityLabel:@"Opacité du fond"];
    [container addSubview:slider]; sliderItem.view = container; [opacity addItem:sliderItem];
    [self add:@"Couleurs selon la charge" to:menu action:@selector(toggle:) value:@"colorByLoad" checked:v.colorByLoad];
    [self add:@"Icônes à la place des libellés" to:menu action:@selector(toggle:) value:@"useIcons" checked:v.useIcons];
    NSMenu *layout = [self submenu:@"Disposition" to:menu];
    NSArray *names = @[@"Barre horizontale",@"Colonne verticale",@"Capsules séparées"];
    for (NSUInteger i=0;i<names.count;i++) [self add:names[i] to:layout action:@selector(layout:) value:@(i) checked:v.layout==(NSInteger)i];
    NSMenu *spacing = [self submenu:@"Espacement des indicateurs" to:menu];
    NSMenuItem *spacingItem = [[NSMenuItem alloc] initWithTitle:@"Espacement horizontal" action:nil keyEquivalent:@""];
    NSView *spacingContainer = [[NSView alloc] initWithFrame:NSMakeRect(0,0,220,36)];
    NSSlider *spacingSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(12,6,196,24)];
    spacingSlider.minValue = 0; spacingSlider.maxValue = 80;
    spacingSlider.doubleValue = v.indicatorSpacing;
    spacingSlider.continuous = YES; spacingSlider.target = self;
    spacingSlider.action = @selector(spacing:);
    spacingSlider.enabled = v.layout != 1;
    [spacingSlider setAccessibilityLabel:@"Espacement horizontal des indicateurs"];
    [spacingContainer addSubview:spacingSlider]; spacingItem.view = spacingContainer;
    [spacing addItem:spacingItem];
    [self add:@"Espacement normal" to:spacing action:@selector(resetSpacing) value:nil checked:NO];
    NSMenu *indicators = [self submenu:@"Indicateurs" to:menu];
    NSArray *all = @[@"CPU",@"RAM",@"Metal"];
    for (NSString *key in all) {
        NSMenu *sub = [self submenu:key to:indicators];
        BOOL shown = [v.indicators containsObject:key];
        NSMenuItem *visible = [self add:@"Afficher" to:sub action:@selector(visibility:) value:key checked:shown];
        visible.enabled = !shown || v.indicators.count>1;
        sub.autoenablesItems = NO;
        [self add:@"Couleur…" to:sub action:@selector(chooseColor:) value:key checked:NO];
        [self add:@"Courbe des 60 dernières secondes" to:sub action:@selector(graph:) value:key checked:[v.graphs containsObject:key]];
        NSMenuItem *first = [self add:@"Placer en premier" to:sub action:@selector(first:) value:key checked:NO];
        first.enabled = shown && ![v.indicators.firstObject isEqual:key];
        NSMenuItem *last = [self add:@"Placer en dernier" to:sub action:@selector(last:) value:key checked:NO];
        last.enabled = shown && ![v.indicators.lastObject isEqual:key];
    }
    [menu addItem:NSMenuItem.separatorItem];
    [self add:@"Aligner aux bords de l’écran" to:menu action:@selector(toggle:) value:@"snapToEdges" checked:v.snapToEdges];
    [self add:@"Verrouiller position et taille" to:menu action:@selector(toggle:) value:@"locked" checked:v.locked];
    NSMenu *size = [self submenu:@"Taille" to:menu];
    size.autoenablesItems = NO;
    [self add:@"Agrandir" to:size action:@selector(scale:) value:@(.15) checked:NO].enabled = !v.locked && v.scale<2.5;
    [self add:@"Réduire" to:size action:@selector(scale:) value:@(-.15) checked:NO].enabled = !v.locked && v.scale>.6;
    [self add:@"Taille normale" to:size action:@selector(scale:) value:@0 checked:NO].enabled = !v.locked;
    [menu addItem:NSMenuItem.separatorItem];
    NSMenuItem *hint = [menu addItemWithTitle:@"Metal : mémoire de cette app / budget conseillé" action:nil keyEquivalent:@""];
    hint.enabled = NO;
    hint.toolTip = @"Ce ratio Metal ne représente ni la charge GPU ni la mémoire GPU totale du système.";
    [self add:@"Quitter" to:menu action:@selector(quit) value:nil checked:NO];
}
- (void)changed { [self resize]; [self saveSettings]; }
- (void)toggle:(NSMenuItem *)item {
    NSString *key = item.representedObject;
    [self.overlayView setValue:@(![[self.overlayView valueForKey:key] boolValue]) forKey:key];
    [self changed];
}
- (void)opacity:(NSSlider *)slider {
    self.overlayView.backgroundOpacity = slider.doubleValue;
    self.overlayView.showBackground = YES;
    self.overlayView.needsDisplay = YES;
    [self saveSettings];
}
- (void)spacing:(NSSlider *)slider {
    self.overlayView.indicatorSpacing = slider.doubleValue;
    [self changed];
}
- (void)resetSpacing {
    self.overlayView.indicatorSpacing = 16;
    [self changed];
}
- (void)layout:(NSMenuItem *)item { self.overlayView.layout = [item.representedObject integerValue]; [self changed]; }
- (void)scale:(NSMenuItem *)item {
    if (self.overlayView.locked) return;
    double delta = [item.representedObject doubleValue];
    self.overlayView.scale = delta ? fmin(2.5,fmax(.6,self.overlayView.scale+delta)) : 1;
    [self changed];
}
- (void)visibility:(NSMenuItem *)item {
    NSMutableArray *keys = [self.overlayView.indicators mutableCopy];
    NSString *key = item.representedObject;
    if ([keys containsObject:key]) { if (keys.count==1) return; [keys removeObject:key]; }
    else [keys addObject:key];
    self.overlayView.indicators = keys; [self changed];
}
- (void)first:(NSMenuItem *)item {
    NSMutableArray *keys = [self.overlayView.indicators mutableCopy];
    [keys removeObject:item.representedObject]; [keys insertObject:item.representedObject atIndex:0];
    self.overlayView.indicators = keys; [self changed];
}
- (void)last:(NSMenuItem *)item {
    NSMutableArray *keys = [self.overlayView.indicators mutableCopy];
    [keys removeObject:item.representedObject]; [keys addObject:item.representedObject];
    self.overlayView.indicators = keys; [self changed];
}
- (void)graph:(NSMenuItem *)item {
    NSMutableSet *graphs = [self.overlayView.graphs mutableCopy];
    if ([graphs containsObject:item.representedObject]) [graphs removeObject:item.representedObject]; else [graphs addObject:item.representedObject];
    self.overlayView.graphs = graphs; [self changed];
}
- (void)chooseColor:(NSMenuItem *)item {
    self.colorTarget = item.representedObject;
    NSColorPanel *panel = NSColorPanel.sharedColorPanel;
    panel.color = self.overlayView.colors[self.colorTarget] ?: self.overlayView.colors[@"CPU"];
    panel.target = self; panel.action = @selector(colorChanged:); panel.showsAlpha = NO;
    [NSApp activateIgnoringOtherApps:YES]; [panel makeKeyAndOrderFront:nil];
}
- (void)colorChanged:(NSColorPanel *)panel {
    NSArray *keys = [self.colorTarget isEqual:@"all"] ? @[@"CPU",@"RAM",@"Metal"] : @[self.colorTarget];
    for (NSString *key in keys) self.overlayView.colors[key] = panel.color;
    self.overlayView.colorByLoad = NO;
    self.overlayView.needsDisplay = YES; [self saveSettings];
}
- (void)theme:(NSMenuItem *)item {
    NSString *name = item.representedObject;
    BOOL neon = [name isEqual:@"Néon"], terminal = [name isEqual:@"Terminal"];
    self.overlayView.neon = neon;
    self.overlayView.colorByLoad = NO;
    self.overlayView.showBackground = YES;
    self.overlayView.backgroundOpacity = terminal ? .75 : neon ? .55 : .25;
    NSArray *palette = neon ? @[NSColor.systemCyanColor,NSColor.systemPurpleColor,NSColor.systemOrangeColor] : terminal ? @[NSColor.systemGreenColor,NSColor.systemGreenColor,NSColor.systemGreenColor] : @[NSColor.whiteColor,NSColor.whiteColor,NSColor.whiteColor];
    NSArray *keys = @[@"CPU",@"RAM",@"Metal"];
    for (NSUInteger i=0;i<keys.count;i++) self.overlayView.colors[keys[i]] = palette[i];
    [self changed];
}
- (void)saveSettings {
    OverlayView *v = self.overlayView;
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    for (NSString *key in @[@"scale",@"indicatorSpacing",@"backgroundOpacity",@"showBackground",@"locked",@"snapToEdges",@"colorByLoad",@"useIcons",@"neon",@"layout",@"indicators"]) settings[key] = [v valueForKey:key];
    settings[@"graphs"] = v.graphs.allObjects;
    NSMutableDictionary *colors = [NSMutableDictionary dictionary];
    for (NSString *key in v.colors) {
        NSColor *c = [v.colors[key] colorUsingColorSpace:NSColorSpace.deviceRGBColorSpace];
        if (c) colors[key] = @[@(c.redComponent),@(c.greenComponent),@(c.blueComponent)];
    }
    settings[@"colors"] = colors;
    [NSUserDefaults.standardUserDefaults setObject:settings forKey:@"MonitorBarAppearanceV2"];
    [self.window saveFrameUsingName:@"MonitorBarWindowFrame"];
}
- (void)loadSettings {
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    NSDictionary *settings = [d dictionaryForKey:@"MonitorBarAppearanceV2"];
    OverlayView *v = self.overlayView;
    if (!settings) {
        double scale = [d doubleForKey:@"MonitorBarScale"];
        v.scale = scale >= .6 && scale <= 2.5 ? scale : 1;
        v.showBackground = [d boolForKey:@"MonitorBarShowBackground"];
        if ([d objectForKey:@"MonitorBarColorR"]) {
            NSColor *c = [NSColor colorWithDeviceRed:[d doubleForKey:@"MonitorBarColorR"] green:[d doubleForKey:@"MonitorBarColorG"] blue:[d doubleForKey:@"MonitorBarColorB"] alpha:1];
            for (NSString *key in v.colors.allKeys) v.colors[key] = c;
        }
        return;
    }
    for (NSString *key in @[@"showBackground",@"locked",@"snapToEdges",@"colorByLoad",@"useIcons",@"neon"]) if ([settings[key] isKindOfClass:NSNumber.class]) [v setValue:settings[key] forKey:key];
    double scale = [settings[@"scale"] doubleValue], opacity = [settings[@"backgroundOpacity"] doubleValue];
    v.scale = isfinite(scale) && scale>=.6 && scale<=2.5 ? scale : 1;
    v.backgroundOpacity = isfinite(opacity) ? fmin(1,fmax(0,opacity)) : .35;
    NSNumber *spacing = settings[@"indicatorSpacing"];
    if ([spacing isKindOfClass:NSNumber.class] && isfinite(spacing.doubleValue)) v.indicatorSpacing = fmin(80,fmax(0,spacing.doubleValue));
    v.layout = MAX(0,MIN(2,[settings[@"layout"] integerValue]));
    NSArray *allowed = @[@"CPU",@"RAM",@"Metal"];
    NSMutableOrderedSet *visible = [NSMutableOrderedSet orderedSet];
    if ([settings[@"indicators"] isKindOfClass:NSArray.class]) for (NSString *key in settings[@"indicators"]) if ([allowed containsObject:key]) [visible addObject:key];
    if (visible.count) v.indicators = visible.array;
    if ([settings[@"graphs"] isKindOfClass:NSArray.class]) {
        NSMutableSet *graphs = [NSMutableSet setWithArray:settings[@"graphs"]];
        [graphs intersectSet:[NSSet setWithArray:allowed]]; v.graphs = graphs;
    }
    NSDictionary *colors = settings[@"colors"];
    if ([colors isKindOfClass:NSDictionary.class]) for (NSString *key in allowed) {
        NSArray *rgb = colors[key];
        if ([rgb isKindOfClass:NSArray.class] && rgb.count == 3 && [rgb[0] isKindOfClass:NSNumber.class] && [rgb[1] isKindOfClass:NSNumber.class] && [rgb[2] isKindOfClass:NSNumber.class]) v.colors[key] = [NSColor colorWithDeviceRed:[rgb[0] doubleValue] green:[rgb[1] doubleValue] blue:[rgb[2] doubleValue] alpha:1];
    }
}
- (void)applicationDidChangeScreenParameters:(NSNotification *)notification { [self resize]; }
- (void)applicationWillTerminate:(NSNotification *)notification { [self saveSettings]; [self.timer invalidate]; }
- (void)quit { [NSApp terminate:nil]; }
@end
