//
//  ImageViewGridLayer.m
//  VertexHelper
//
//  Created by Johannes Fahrenkrug on 20.02.10.
//  Copyright 2010 Springenwerk. All rights reserved.
//

#import "ImageViewGridLayer.h"
#import "MyDocument.h"

// Thanks to Bill Dudney (http://bill.dudney.net/roller/objc/entry/nscolor_cgcolorref)
@implementation NSColor(CGColor)
- (CGColorRef)CGColor {
    CGColorSpaceRef colorSpace = [[self colorSpace] CGColorSpace];
    NSInteger componentCount = [self numberOfComponents];
    CGFloat *components = (CGFloat *)calloc(componentCount, sizeof(CGFloat));
    [self getComponents:components];
    CGColorRef color = CGColorCreate(colorSpace, components);
    free((void*)components);
    return color;
}

@end


@implementation ImageViewGridLayer


@synthesize owner, document, rows, cols;

// -------------------------------------------------------------------------
//	init
// -------------------------------------------------------------------------
- (id) init
{
	if((self = [super init])){
		//needs to redraw when bounds change
		[self setNeedsDisplayOnBoundsChange:YES];
	}
	
	return self;
}

// -------------------------------------------------------------------------
//	actionForKey:
//
// always return nil, to never animate
// -------------------------------------------------------------------------
- (id<CAAction>)actionForKey:(NSString *)event
{
	return nil;
}

// -------------------------------------------------------------------------
//	drawInContext:
//
// draw a metal background that scrolls when the image browser scroll
// -------------------------------------------------------------------------
- (void)drawInContext:(CGContextRef)context
{
	//retreive bounds and visible rect
	NSSize imageSize = [owner imageSize];
	
	
	int i = 0;
	float colWidth = (imageSize.width / cols);
	float rowHeight = (imageSize.height / rows);
	
	CGContextSetLineWidth(context, 1.0);
	
	for (i = 0; i <= cols; i++) {
		CGContextMoveToPoint(context, (imageSize.width / cols) * i, 0);
		CGContextAddLineToPoint(context, (imageSize.width / cols) * i, imageSize.height);
	}
	
	for (i = 0; i <= rows; i++) {
		CGContextMoveToPoint(context, 0, (imageSize.height / rows) * i);
		CGContextAddLineToPoint(context, imageSize.width, (imageSize.height / rows) * i);
	}
	
	CGContextStrokePath(context);
	
	// now we stroke the points...
	for (int r = 0; r < [document.pointMatrix count]; r++) {
		for (int c = 0; c < [[document.pointMatrix objectAtIndex:r] count]; c++) {
			NSMutableArray *points = [[document.pointMatrix objectAtIndex:r] objectAtIndex:c];
			float originX = (imageSize.width / cols) * c;
			float originY = (imageSize.height / rows) * r;
			float firstX = 0;
			float firstY = 0;
			float lastX = 0;
			float lastY = 0;
			
			// at the beginning of a different sprite...
			
			if ([points count] > 1) {
				for (int p = 0; p < [points count]; p++) {
					float x = [[points objectAtIndex:p] pointValue].x + (colWidth / 2) + originX;
					float y = [[points objectAtIndex:p] pointValue].y + (rowHeight / 2) + originY;
					
					
					if (p == 0) {
						CGContextMoveToPoint(context, x, y);
						firstX = x;
						firstY = y;
					} else {
						CGContextAddLineToPoint(context, x, y);
						lastX = x;
						lastY = y;
					}

				}
				CGContextSetStrokeColorWithColor(context, [[NSColor greenColor] CGColor]);
				CGContextStrokePath(context);
				
				// the last "auto-connected" line will have a different color...
				CGContextSetStrokeColorWithColor(context, [[NSColor grayColor] CGColor]);
				CGContextMoveToPoint(context, lastX, lastY);
				CGContextAddLineToPoint(context, firstX, firstY);
				CGContextStrokePath(context);
			}
		}
	}
	
	CGContextStrokePath(context);
}

-(CALayer *)hitTest:(NSPoint)aPoint {
	//NSLog(@"hittest x: %.f, y: %.f", aPoint.x, aPoint.y);
	// don't allow any mouse clicks for subviews in this view
	
	if (owner.currentToolMode == IKToolModeAnnotate) {
		NSPoint p = [owner convertViewPointToImagePoint:aPoint];
		//NSLog(@"hittest x: %.f, y: %.f", p.x, p.y);
		NSSize imageSize = [owner imageSize];
		NSPoint relativePoint = NSMakePoint(0, 0);
		float colWidth = (imageSize.width / cols);
		float rowHeight = (imageSize.height / rows);
		
		float yExtra = (int)(p.y) %  (int)rowHeight;
		float xExtra = (int)p.x % (int)colWidth;
		int currentRow = p.y / rowHeight + (yExtra > 0 ? 1 : 0); 
		int currentCol = p.x / colWidth + (xExtra > 0 ? 1 : 0);
		
		NSLog(@"row: %i, col: %i", currentRow, currentCol);
		
		if (currentRow > 0 && currentCol > 0 && currentCol <= cols && currentRow <= rows) {
			relativePoint.x = (p.x - ((currentCol - 1) * colWidth)) - (colWidth / 2);
			relativePoint.y = (p.y - ((currentRow - 1) * rowHeight)) - (rowHeight / 2);
			
			NSLog(@"x: %.f, y: %.f", relativePoint.x, relativePoint.y);
			
			[document addPoint:relativePoint forRow:currentRow col:currentCol];
		}
		
	}
	
	if(NSPointInRect(aPoint,[self bounds])) {
		return self;
	} else {
		return nil;    
	}
}


@end