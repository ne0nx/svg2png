//
//  ViewController.m
//  AppColor
//
//  Created by Дмитрий Караченцов on 08.01.15.
//  Copyright (c) 2015 WEBOM. All rights reserved.
//

#import "ViewController.h"
#import "DragDropImageView.h"

@interface ViewController () <DragDropDelegate, NSTextFieldDelegate>
@property (weak) IBOutlet NSTextField *width;
@property (weak) IBOutlet NSTextField *height;
@property (weak) IBOutlet NSColorWell *colorWell;

@property (copy) NSString *fileContent;
@property (copy) NSString *fileName;
@property (copy) NSString *fileDirectory;
@property (assign) CGSize size;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.size = CGSizeMake(512, 512);
    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)runBatik:(NSString *)filePath size:(CGSize)size {
    if (filePath.length == 0 || size.height == 0 || size.width == 0) {
        return;
    }
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/java";
    
    NSString *batikResterizer = [self batikResterizer];
    
    task.arguments = @[@"-jar", batikResterizer, filePath, @"-m", @"image/png", @"-w", [@(size.width) stringValue], @"-h", [@(size.height) stringValue]];
    
    [task launch];
    
    [task waitUntilExit];
}

- (NSString *)batikResterizer {
    return [[NSBundle mainBundle] pathForResource:@"batik-rasterizer" ofType:@"jar" inDirectory:@"batik-1.7"];
}

#pragma mark - IBActions

- (IBAction)createPressed:(id)sender {
    if (self.fileContent.length == 0) {
        return;
    }
    
    [[self.width window] makeFirstResponder:nil];
    [[self.height window] makeFirstResponder:nil];
    
    NSString *str = [self createTempSVGFile:self.fileContent];
    [self runBatik:str size:self.size];
    NSString *pngInTemp = [[str stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
    
    NSString *fileName = [self.fileName stringByDeletingPathExtension];
    fileName = [fileName stringByAppendingFormat:@"_%@x%@.png",
                @(self.size.width),
                @(self.size.height)];
    
    NSString *newFileName = [self.fileDirectory stringByAppendingPathComponent:fileName];
    
    NSFileManager *fl = [NSFileManager defaultManager];
    if ([fl fileExistsAtPath:newFileName]) {
        [fl removeItemAtPath:newFileName error:nil];
    }
    
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:pngInTemp];
    NSImage *newImage = [self cdsMaskedWithColor:self.colorWell.color image:image];
    
    NSData *data = [newImage TIFFRepresentation];
    [data writeToFile:newFileName atomically:YES];
    
    [fl removeItemAtPath:self.tempDir error:nil];
}

- (NSImage *)cdsMaskedWithColor:(NSColor *)color image:(NSImage *)image
{
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    
    NSImage *result = [[NSImage alloc] initWithSize:self.size];
    [result lockFocus];
    
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    CGContextRef c = (CGContextRef)[context graphicsPort];
    
    [image drawInRect:NSRectFromCGRect(rect)];
    
    CGContextSetFillColorWithColor(c, [color CGColor]);
    CGContextSetBlendMode(c, kCGBlendModeSourceAtop);
    CGContextFillRect(c, rect);
    
    [result unlockFocus];
    
    return result;
}

#pragma mark -

- (NSString *)createTempSVGFile:(NSString *)content {
    NSString *tempDir = [self.tempDir stringByAppendingPathComponent:self.fileName];
    [content writeToFile:tempDir
              atomically:YES
                encoding:NSUTF8StringEncoding
                   error:nil];
    return tempDir;
}

- (NSString *)tempDir {
    NSString *temp = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ae2d80"];
    [[NSFileManager defaultManager] createDirectoryAtPath:temp withIntermediateDirectories:YES attributes:nil error:nil];
    return temp;
}

#pragma mark - <NSTextFieldDelegate>

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
    if (self.width == control) {
        self.size = CGSizeMake([fieldEditor.string floatValue], self.size.height);
    } else if (self.height == control) {
        self.size = CGSizeMake(self.size.width, [fieldEditor.string floatValue]);
    }
    return YES;
}

#pragma mark - <DragDropDelegate>

- (void)dragDropImageView:(DragDropImageView *)imageView
               svgContent:(NSString *)fileContent
                 nameFile:(NSString *)fileName
                     path:(NSString *)path{
    self.fileContent = fileContent;
    self.fileName = fileName;
    self.fileDirectory = path;
}


@end
