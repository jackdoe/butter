#import "AppDelegate.h"
#import <AppKit/NSAccessibility.h>
#import <Carbon/Carbon.h>

@implementation AppDelegate
@synthesize item,menu;
#define LEFT 123
#define RIGHT 124
#define DOWN 125
#define UP 126
#define FULL 3
static NSRect up,down,left,right,full;
static AXUIElementRef _axui;
void move(NSRect to) {
    AXUIElementRef app;
    CFTypeRef win;
    CFTypeRef _position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&to.origin));
    CFTypeRef _size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&to.size));
    
    AXUIElementCopyAttributeValue(_axui,(CFStringRef)kAXFocusedApplicationAttribute,(CFTypeRef*)&app);
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

OSStatus key_down_event(EventHandlerCallRef nextHandler,EventRef event,void *unused)
{
    EventHotKeyID key;
    GetEventParameter(event, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(key), NULL, &key);
    switch (key.id) {
        case LEFT:
            move(left);
            break;
        case RIGHT:
            move(right);
            break;
        case UP:
            move(up);
            break;
        case DOWN:
            move(down);
            break;
        case FULL:
            move(full);
            break;
    }
    return noErr;
}

-(void)registerHotKeys
{
    EventHotKeyRef keyref;
    EventHotKeyID kid;
    EventTypeSpec eventType;
    eventType.eventClass=kEventClassKeyboard;
    eventType.eventKind=kEventHotKeyPressed;
 	
    InstallApplicationEventHandler(&key_down_event, 1, &eventType, (void *)CFBridgingRetain(self), NULL);
 	int keys[] = {LEFT,RIGHT,UP,DOWN,FULL};
    for (int i = 0; i < sizeof(keys)/sizeof(keys[0]); i++) {
        kid.signature = 'htk1';
        kid.id=keys[i];
        RegisterEventHotKey(keys[i], cmdKey+optionKey, kid, GetApplicationEventTarget(), 0, &keyref);
    }
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    _axui = AXUIElementCreateSystemWide();
    full = [[NSScreen mainScreen] frame];
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
    [self registerHotKeys];
}

@end
