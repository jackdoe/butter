#import "AppDelegate.h"
#import <AppKit/NSAccessibility.h>
#import <Carbon/Carbon.h>

@implementation AppDelegate
@synthesize item,menu;
#define LEFT 123
#define RIGHT 124
#define DOWN 125
#define DOWN_LEFT (DOWN * LEFT)
#define DOWN_RIGHT (DOWN * RIGHT)
#define UP 126
#define UP_LEFT (UP * LEFT)
#define UP_RIGHT (UP * RIGHT)
#define APPROX 50
static AXUIElementRef _axui;
static unsigned int processed_key = 0;
static NSTimeInterval processed_stamp = 0;

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
        case DOWN_LEFT:
            return split(split(f, DOWN),LEFT);
            break;
        case DOWN_RIGHT:
            return split(split(f, DOWN),RIGHT);
            break;
        case UP_LEFT:
            return split(split(f, UP),LEFT);
            break;
        case UP_RIGHT:
            return split(split(f, UP),RIGHT);
            break;
    }
    return NSZeroRect;
}

CFTypeRef current_window(void) {
    AXUIElementRef app;
    CFTypeRef win;
    AXUIElementCopyAttributeValue(_axui,(CFStringRef)kAXFocusedApplicationAttribute,(CFTypeRef*)&app);
    if(AXUIElementCopyAttributeValue(app,(CFStringRef)NSAccessibilityFocusedWindowAttribute,&win) == kAXErrorSuccess) {
        if(CFGetTypeID(win) == AXUIElementGetTypeID()) {
            return win;
        }
    }
    return NULL;
}
NSRect get_window_frame(CFTypeRef win) {
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
    return current;
}
void set_window_frame(CFTypeRef win,NSRect frame) {
    CFTypeRef _position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&frame.origin));
    CFTypeRef _size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&frame.size));
    AXUIElementSetAttributeValue(win,(CFStringRef)NSAccessibilityPositionAttribute,_position);
    AXUIElementSetAttributeValue(win,(CFStringRef)NSAccessibilitySizeAttribute, _size);
}
NSRect screen_frame_for_window(CFTypeRef win) {
    NSRect frame = get_window_frame(win);
    for (NSScreen *s in [NSScreen screens]) {
        if (NSPointInRect(frame.origin,[s visibleFrame])) {
            return [s visibleFrame];
        }
    }
    return [[NSScreen mainScreen] visibleFrame];
}
void move(int direction) {
    CFTypeRef win = current_window();
    if (!win) {
        NSLog(@"e: couldn't get the current window");
        return;
    }
    NSRect screen_frame = screen_frame_for_window(win);
    NSRect splitted = split(screen_frame,direction);
    if (direction == UP) {
        NSRect current = get_window_frame(win);    
        if (abs(current.origin.x - splitted.origin.x) < APPROX &&
            abs(current.origin.y - splitted.origin.y) < APPROX &&
            abs(current.size.width - splitted.size.width) < APPROX &&
            abs(current.size.height - splitted.size.height) < APPROX) {
                set_window_frame(win, screen_frame);
                return;
        }
    }
    set_window_frame(win, splitted);
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
    
    if (processed_key == LEFT || processed_key == RIGHT ||
        processed_key == UP || processed_key == DOWN ||
        processed_key == UP_RIGHT || processed_key == UP_LEFT ||
        processed_key == DOWN_LEFT || processed_key == DOWN_RIGHT) {
            move(processed_key);
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
- (void) quit:(id) sender {
    [NSApp terminate:nil];
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
    menu = [[NSMenu alloc] init];
    item = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [menu addItemWithTitle:@"Quit" action:@selector(quit:) keyEquivalent:@""];
    [item setMenu:menu];
    [item setImage:[NSImage imageNamed:@"status-icon"]];
    [self registerHotKeys];
}

@end
