#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSMenu *menu;
    NSStatusItem *item;
}
@property (retain) NSMenu *menu;
@property (retain) NSStatusItem * item;
@end
