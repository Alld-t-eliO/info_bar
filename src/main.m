#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char *argv[])
{
    @autoreleasepool
    {
        NSApplication *app = [NSApplication sharedApplication];
        AppDelegate *delegate = [[AppDelegate alloc] init];

        app.delegate = delegate;

        /*
         * Pas d'icône dans le Dock, pas d'item dans la barre de menu :
         * c'est une fenêtre flottante custom, pas une app classique.
         */
        [app setActivationPolicy:NSApplicationActivationPolicyAccessory];

        [app run];
    }
    return 0;
}
