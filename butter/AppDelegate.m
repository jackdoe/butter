#import "AppDelegate.h"
#import <AppKit/NSAccessibility.h>

@implementation AppDelegate
@synthesize item,menu;

#define LEFT 123
#define RIGHT 124
#define DOWN 125
#define UP 126
- (void) move:(NSRect)to {
    AXUIElementRef axu;
    AXUIElementRef app;
    CFTypeRef win;
    axu = AXUIElementCreateSystemWide();
    CFTypeRef _position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&to.origin));
    CFTypeRef _size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&to.size));
    
    AXUIElementCopyAttributeValue(axu,(CFStringRef)kAXFocusedApplicationAttribute,(CFTypeRef*)&app);
    if(AXUIElementCopyAttributeValue(app,(CFStringRef)NSAccessibilityFocusedWindowAttribute,&win) == kAXErrorSuccess) {
        if(CFGetTypeID(win) == AXUIElementGetTypeID()) {
            AXUIElementSetAttributeValue(win, (CFStringRef)NSAccessibilityPositionAttribute,_position);
            AXUIElementSetAttributeValue(win,(CFStringRef)NSAccessibilitySizeAttribute, _size);
        }
    }
}
- (void) quit:(id) sender {
    [NSApp terminate:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    unsigned int mask = (NSCommandKeyMask|NSAlternateKeyMask);
    NSRect full = [[NSScreen mainScreen] frame];
    NSRect up,down,left,right;
    up = down = left = right = full;
    up.size.height /= 2;
    down.size.height /= 2;
    down.origin.y = down.size.height;
    
    left.size.width /= 2;
    right.size.width /= 2;
    right.origin.x = right.size.width;
    menu = [[NSMenu alloc] init];
    item = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [menu addItemWithTitle:@"quit" action:@selector(quit:) keyEquivalent:@""];
    [item setMenu:menu];
    [item setImage:[NSImage imageNamed:@"status-icon"]];
    
    [NSEvent addGlobalMonitorForEventsMatchingMask:NSKeyDownMask handler:^(NSEvent *event){
        if (([event modifierFlags] & mask) == mask) {
            switch ([event keyCode]) {
                case LEFT:
                    [self move:left];
                    break;
                case RIGHT:
                    [self move:right];
                    break;
                case UP:
                    [self move:up];
                    break;
                case DOWN:
                    [self move:down];
                    break;
            }
        }
    }];
}

@end
