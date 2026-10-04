#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(void)
{
    @autoreleasepool
    {
        NSApplication *app = [NSApplication sharedApplication];
        __attribute__((objc_precise_lifetime)) AppDelegate *delegate = [[AppDelegate alloc] init];

        app.delegate = delegate;

        /*
         * Pas d’icône dans le Dock ; accès de secours dans la barre de menus :
         * c'est une fenêtre flottante custom, pas une app classique.
         */
        [app setActivationPolicy:NSApplicationActivationPolicyAccessory];

        [app run];
    }
    return 0;
}
