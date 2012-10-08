#import "AppDelegate.h"
#import <AppKit/NSAccessibility.h>
#import <Carbon/Carbon.h>

@implementation AppDelegate
@synthesize item,menu;
#define LEFT 123
#define RIGHT 124
#define DOWN 125
#define UP 126
#define APPROX 50
static NSRect up,down,left,right,full,up_left,up_right,down_left,down_right;
static AXUIElementRef _axui;
static unsigned int processed_key = 0;
static NSTimeInterval processed_stamp = 0;
void move(NSRect *to, NSRect *second) {
    AXUIElementRef app;
    CFTypeRef win;
    AXUIElementCopyAttributeValue(_axui,(CFStringRef)kAXFocusedApplicationAttribute,(CFTypeRef*)&app);
    if(AXUIElementCopyAttributeValue(app,(CFStringRef)NSAccessibilityFocusedWindowAttribute,&win) == kAXErrorSuccess) {
        if(CFGetTypeID(win) == AXUIElementGetTypeID()) {
            if (second) {
                CFTypeRef _current;
                NSRect current = NSZeroRect;

                if (AXUIElementCopyAttributeValue(win,(CFStringRef)NSAccessibilitySizeAttribute, (CFTypeRef*)&_current) == kAXErrorSuccess &&
                    AXValueGetType(_current) == kAXValueCGSizeType){
                      AXValueGetValue(_current, kAXValueCGSizeType, (void*)&current.size);
                }

                if (AXUIElementCopyAttributeValue(win,(CFStringRef)NSAccessibilityPositionAttribute, (CFTypeRef*)&_current) == kAXErrorSuccess &&
                    AXValueGetType(_current) == kAXValueCGPointType) {
                      AXValueGetValue(_current, kAXValueCGPointType, (void*)&current.origin);
                }
                if (abs(current.origin.x - to->origin.x) < APPROX &&
                    abs(current.origin.y - to->origin.y) < APPROX &&
                    abs(current.size.width - to->size.width) < APPROX &&
                    abs(current.size.height - to->size.height) < APPROX) {
                      to = second;
                }
            }
            CFTypeRef _position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&to->origin));
            CFTypeRef _size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&to->size));
            AXUIElementSetAttributeValue(win,(CFStringRef)NSAccessibilityPositionAttribute,_position);
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
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if ((now - processed_stamp) < 0.1f)
        processed_key *= key.id;
    else
        processed_key = key.id;

    switch (processed_key) {
        case LEFT:
            move(&left,NULL);
            break;
        case RIGHT:
            move(&right,NULL);
            break;
        case UP:
            move(&up,&full);
            break;
        case DOWN:
            move(&down,NULL);
            break;
        case UP*LEFT:
            move(&up_left,NULL);
            break;
        case UP*RIGHT:
            move(&up_right,NULL);
            break;
        case DOWN*LEFT:
            move(&down_left,NULL);
            break;
        case DOWN*RIGHT:
            move(&down_right,NULL);
            break;
            
    }
    processed_stamp = now;
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
 	int keys[] = {LEFT,RIGHT,UP,DOWN};
    for (int i = 0; i < sizeof(keys)/sizeof(keys[0]); i++) {
        kid.signature = 'htk1';
        kid.id=keys[i];
        RegisterEventHotKey(keys[i], cmdKey+optionKey, kid, GetApplicationEventTarget(), 0, &keyref);
    }
}
NSRect split(NSRect f,int position) {
    switch(position) {
        case UP:
            return NSMakeRect(f.origin.x, f.origin.y, f.size.width, f.size.height/2.0f);
            break;
        case DOWN:
            return NSMakeRect(f.origin.x, f.size.height/2.0f, f.size.width, f.size.height/2.0f);
            break;
        case LEFT:
            return NSMakeRect(f.origin.x, f.origin.y, f.size.width/2.0f, f.size.height);
            break;
        case RIGHT:
            return NSMakeRect(f.size.width/2.0f, f.origin.y, f.size.width/2.0f, f.size.height);
            break;
            
    }
    return NSZeroRect;
}
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    if(!AXAPIEnabled()){
        [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/UniversalAccessPref.prefPane"];
        NSAlert *alert = [NSAlert alertWithMessageText:@"Settings modification required(bang! unexpected eh?)"
                                         defaultButton:@"Quit"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"Sorry but, in order to use Butter,\nyou will have to enable \"Enable access for assistive devices\" at the bottom left corner of Accessibility Settings\n"];
        [alert runModal];
    }
    _axui = AXUIElementCreateSystemWide();
    full = [[NSScreen mainScreen] frame];
    up = split(full,UP);
    down = split(full,DOWN);
    left = split(full,LEFT);
    right = split(full,RIGHT);
    up_left = split(up,LEFT);
    up_right = split(up,RIGHT);
    down_left = split(down,LEFT);
    down_right = split(down,RIGHT);

    menu = [[NSMenu alloc] init];
    item = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [menu addItemWithTitle:@"quit" action:@selector(quit:) keyEquivalent:@""];
    [item setMenu:menu];
    [item setImage:[NSImage imageNamed:@"status-icon"]];
    [self registerHotKeys];
}

@end
