/*
 File: APLDocument.m
 Abstract: n/a
 Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "APLDocument.h"
#import "APLCoreTextArcView.h"

#import <Foundation/NSObjCRuntime.h>
#import <objc/runtime.h>


@interface NSFont (FontStyleAdditions)
- (BOOL)isBold;
- (BOOL)isItalic;
- (BOOL)canToggleTrait:(NSFontTraitMask)trait;
@end


@interface APLDocument () <NSControlTextEditingDelegate, NSFontChanging>

@property (weak) IBOutlet APLCoreTextArcView *arcView;
@property (weak) IBOutlet NSButton *boldButton;
@property (weak) IBOutlet NSButton *italicButton;

@end


@implementation APLDocument

- (IBAction)setString:(id)sender {
    self.arcView.string = [sender stringValue];
    [self updateDisplay];
}


- (IBAction)setShowsGlyphOutlines:(id)sender {
    self.arcView.showsGlyphBounds = ([sender state] == NSControlStateValueOn);
    [self updateDisplay];
}


- (IBAction)setShowsLineMetrics:(id)sender {
    self.arcView.showsLineMetrics = ([sender state] == NSControlStateValueOn);
    [self updateDisplay];
}


- (IBAction)setDimsSubstitutedGlyphs:(id)sender {
    self.arcView.dimsSubstitutedGlyphs = ([sender state] == NSControlStateValueOn);
    [self updateDisplay];
}


#pragma mark - Managing font

- (void)setArcViewFont:(NSFont *)newFont {
    if (newFont != nil) {
        self.arcView.font = newFont;
        [self updateDisplay];
        [[NSFontPanel sharedFontPanel] setPanelFont:self.arcView.font isMultiple:NO];
    }
}

/*
 The logic of toggling state from a button is the opposite of that from a menu item.
 */
- (IBAction)takeBoldSettingFromButton:(NSButton *)sender {
    [self changeArcViewFontTrait:NSFontBoldTrait to:[sender state] == NSControlStateValueOn];
}


- (IBAction)takeBoldSettingFrom:(id)sender {
    [self changeArcViewFontTrait:NSFontBoldTrait to:[sender state] == NSControlStateValueOff];
}


- (IBAction)takeItalicSettingFromButton:(NSButton *)sender {
    [self changeArcViewFontTrait:NSFontItalicTrait to:[sender state] == NSControlStateValueOn];
}


- (IBAction)takeItalicSettingFrom:(id)sender {
    [self changeArcViewFontTrait:NSFontItalicTrait to:[sender state] == NSControlStateValueOff];
}


- (void)changeArcViewFontTrait:(NSInteger)fontTrait to:(BOOL)yn {
    
    NSFont *const newFont =
    yn
    ? [[NSFontManager sharedFontManager] convertFont:self.arcView.font toHaveTrait:fontTrait]
    : [[NSFontManager sharedFontManager] convertFont:self.arcView.font toNotHaveTrait:fontTrait];
    
    [self setArcViewFont:newFont];
}

#pragma mark - NSFontChanging

- (void)changeFont:(id)sender {
    self.arcView.font = [sender convertFont:self.arcView.font];
    [self updateDisplay];
}

#pragma mark - NSControlTextEditingDelegate

- (void)controlTextDidChange:(NSNotification *)notification {
    [self setString:[notification object]];
}

#pragma mark - Managing UI

- (void)updateDisplay {
    [self.arcView setNeedsDisplay:YES];
    
    // Update the bold button.
    [self.boldButton setState:[self.arcView.font isBold]];
    
    [self.boldButton setEnabled:[self.arcView.font canToggleTrait:NSFontBoldTrait]];
    
    // Update the italic button.
    [self.italicButton setState:[self.arcView.font isItalic]];
    
    [self.italicButton setEnabled:[self.arcView.font canToggleTrait:NSFontItalicTrait]];
    
    // Update the window title.
    for (NSWindowController *controller in [self windowControllers]) {
        [[controller window] setTitle:[self displayName]];
    }
}


- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
    SEL action = [item action];
    
    if (sel_isEqual(action, @selector(takeBoldSettingFrom:))) {
        // Set the state based on the presence of the trait.
        if ([(id)item respondsToSelector:@selector(setState:)]) {
            [(id)item setState:[self.arcView.font isBold]];
        }
        // Test whether we can convert the traits to enable or disable the control.
        return [self.arcView.font canToggleTrait:NSFontBoldTrait];
    }
    else if (sel_isEqual(action, @selector(takeItalicSettingFrom:))) {
        // Set the state based on the presence of the trait.
        if ([(id)item respondsToSelector:@selector(setState:)]) {
            [(id)item setState:[self.arcView.font isItalic]];
        }
        // Test whether we can convert the traits to enable or disable the control.
        return [self.arcView.font canToggleTrait:NSFontItalicTrait];
    }
    return YES;
}


- (void)windowDidBecomeKey:(NSNotification *)notification {
    [[NSFontManager sharedFontManager] setTarget:self];
    [[NSFontPanel sharedFontPanel] setPanelFont:self.arcView.font isMultiple:NO];
}


#pragma - NSDocument overrides

- (NSString *)displayName {
    return self.arcView.string;
}


- (NSString *)windowNibName {
    return @"APLDocument";
}

@end


#pragma mark - NSFont (FontStyleAdditions

/*
 NSFont category for convenience methods to return information about the font in a format that's more easly used in this particular application.
 */
@implementation NSFont (FontStyleAdditions)

- (BOOL)isBold {
    return ([[self fontDescriptor] symbolicTraits] & NSFontBoldTrait);
}


- (BOOL)isItalic {
    return ([[self fontDescriptor] symbolicTraits] & NSFontItalicTrait);
}


- (BOOL)canToggleTrait:(NSFontTraitMask)trait {
    NSFont *const testFont =
    ([[self fontDescriptor] symbolicTraits] & trait)
    ? [[NSFontManager sharedFontManager] convertFont:self toNotHaveTrait:trait]
    : [[NSFontManager sharedFontManager] convertFont:self toHaveTrait:trait];
    
    if (testFont != nil) {
        if (([[testFont fontDescriptor] symbolicTraits] ^ [[self fontDescriptor] symbolicTraits]) == trait) {
            return YES;
        }
    }
    return NO;
}

@end

