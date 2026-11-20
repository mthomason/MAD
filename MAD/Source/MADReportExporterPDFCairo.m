//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADReportExporterPDFCairo.m
//  MAD
//
//  See MADReportExporterPDFCairo.h.  The page walk is MADReportPageBuilder's, the
//  same one json-report serializes and the HTML facsimile prints; each line is drawn
//  where the walk placed it -- text through FreeType at the line's font, size,
//  weight, slant and alignment, a picture (an image element's PNG or a barcode's
//  symbol) aspect-fitted into its frame, and the text's decorations as filled
//  rectangles.
//
//  Fonts: the documents name the Apple fonts (Helvetica Neue, Verdana, Courier,
//  Times New Roman, Arial, Georgia); the bundled substitutes are Liberation Sans,
//  Serif and Mono (SIL OFL 1.1).  The faces are not metric-identical to the Apple
//  fonts -- Verdana is the widest gap, since Liberation Sans is Arial's metric twin
//  -- so a line can be a little wider or narrower than Core Graphics drew it.  What
//  cannot differ is where the line is, what it says, and how it is styled: those are
//  the walk's, and this file only draws them.
//
//  Kerning is FreeType's: the face's own `kern` table, read at the line's size
//  (UNFITTED, so unhinted like the advances).  No advance is invented here; the
//  only arithmetic is the conversion from the face's 26.6 metrics to points.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADReportExporterPDFCairo.h"

#import "MADReportFormatter.h"
#import "MADReportLineRepresentation.h"
#import "MADReportPageBuilder.h"
#import "MADReportPageRepresentation.h"
#import "MADReportSectionRepresentation.h"
#import "MADReportSectionRowsRepresentation.h"

#import <MAD/MADAlignment.h>
#import <MAD/MADDocumentRenderProtocol.h>
#import <MAD/MADReportLineStyle.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSFileHandle.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

#import <MADFoundation/madlog.h>

#include <cairo.h>
#include <cairo-pdf.h>
#include <cairo-ft.h>

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_GLYPH_H
#include FT_TRUETYPE_TABLES_H

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(__linux__)
#include <unistd.h>
#endif

// The one date the deterministic mode pins, the same instant the Apple body pins in
// the trailer ("20010112000000", the PDF epoch).
static NSString * const MADReportPDFPinnedDate = @"2001-01-12T00:00:00Z";

// The PDF's own spelling of the document's producer, as the Apple body's
// kCGPDFContextCreator is.
static NSString * const MADReportPDFCreator = @"MAD® Designer";

// The faces the bundle carries, by family and trait.  Liberation Sans is Arial's
// metric twin; Serif is Times New Roman's; Mono is Courier New's.
typedef NS_ENUM(NSUInteger, MADReportPDFFamily) {
	MADReportPDFFamilySans = 0,
	MADReportPDFFamilySerif = 1,
	MADReportPDFFamilyMono = 2,
};

static NSString *MADReportPDFFaceFile(MADReportPDFFamily family, BOOL bold, BOOL italic) {
	NSString *stem = @"LiberationSans";
	if (family == MADReportPDFFamilySerif) stem = @"LiberationSerif";
	if (family == MADReportPDFFamilyMono) stem = @"LiberationMono";

	NSString *trait = @"Regular";
	if (bold && italic) trait = @"BoldItalic";
	else if (bold) trait = @"Bold";
	else if (italic) trait = @"Italic";
	return [stem stringByAppendingString: [@"-" stringByAppendingString: trait]];
}

// A font name is a family, a PostScript name or a designer's label ("Helvetica
// Neue", "HelveticaNeue-Bold", "TimesNewRomanPSMT").  Normalise it to lower case
// without spaces, then read the family and the two traits out of the words it
// carries.  The element's own bold/italic flags are OR-ed in by the caller: on Apple
// they are descriptor traits on top of the family, and a "-Bold" face name makes the
// same statement.
static MADReportPDFFamily MADReportPDFFamilyForName(NSString *name, BOOL *bold, BOOL *italic) {
	if (bold != NULL) *bold = NO;
	if (italic != NULL) *italic = NO;

	NSString *normalised = [name lowercaseString];
	normalised = [normalised stringByReplacingOccurrencesOfString: @" " withString: @""];
	normalised = [normalised stringByReplacingOccurrencesOfString: @"_" withString: @""];

	if ([normalised rangeOfString: @"bold"].location != NSNotFound && bold != NULL) *bold = YES;
	if (([normalised rangeOfString: @"italic"].location != NSNotFound ||
		 [normalised rangeOfString: @"oblique"].location != NSNotFound) && italic != NULL) *italic = YES;

	// The monospace test comes first so "Courier New" cannot fall through to the
	// sans default; "serif" is only reached by names that say so.
	if ([normalised rangeOfString: @"courier"].location != NSNotFound ||
		[normalised rangeOfString: @"mono"].location != NSNotFound ||
		[normalised rangeOfString: @"consol"].location != NSNotFound ||
		[normalised rangeOfString: @"menlo"].location != NSNotFound) {
		return MADReportPDFFamilyMono;
	}
	if ([normalised rangeOfString: @"times"].location != NSNotFound ||
		[normalised rangeOfString: @"georgia"].location != NSNotFound ||
		[normalised rangeOfString: @"serif"].location != NSNotFound ||
		[normalised rangeOfString: @"palatino"].location != NSNotFound ||
		[normalised rangeOfString: @"baskerville"].location != NSNotFound ||
		[normalised rangeOfString: @"garamond"].location != NSNotFound) {
		return MADReportPDFFamilySerif;
	}
	return MADReportPDFFamilySans;
}

#pragma mark - Where the fonts are

// The executable's directory, or nil.  /proc/self/exe is the exact answer on
// Linux; elsewhere argv[0] is, and a relative one is resolved against the working
// directory (which is how a build tree's test binaries are invoked).
static NSString *MADReportPDFExecutableDirectory(void) {
#if defined(__linux__)
	char buffer[4096];
	ssize_t length = readlink("/proc/self/exe", buffer, sizeof(buffer) - 1);
	if (length > 0 && length < (ssize_t)(sizeof(buffer) - 1)) {
		buffer[length] = '\0';
		return [NSString stringWithUTF8String: buffer].stringByDeletingLastPathComponent;
	}
#endif
	NSArray <NSString *> *arguments = [NSProcessInfo processInfo].arguments;
	if (arguments.count == 0) return nil;
	NSString *executable = arguments[0];
	// -isAbsolutePath is not reliable for a Windows drive path in every
	// Foundation, so the drive and UNC forms are recognised here too.
	BOOL absolute = [executable hasPrefix: @"/"] || [executable hasPrefix: @"\\\\"];
#if defined(_WIN32)
	if (!absolute && executable.length >= 3) {
		unichar drive = [executable characterAtIndex: 0];
		unichar colon = [executable characterAtIndex: 1];
		unichar slash = [executable characterAtIndex: 2];
		absolute = ((drive >= 'A' && drive <= 'Z') || (drive >= 'a' && drive <= 'z')) &&
				   colon == ':' && (slash == '\\' || slash == '/');
	}
#endif
	if (!absolute) {
		executable = [[[NSFileManager defaultManager] currentDirectoryPath]
					  stringByAppendingPathComponent: executable];
	}
	return executable.stringByDeletingLastPathComponent;
}

#pragma mark - Shaping

// One shaped line: the glyphs in the face's own order, their positions in points
// from the line's own left edge, and the line's measured width.  The positions
// include the face's `kern` values -- FreeType's, unscaled from font units.
typedef struct {
	cairo_glyph_t *glyphs;
	size_t count;
	double width;
} MADReportPDFShapedText;

static MADReportPDFShapedText MADReportPDFShapedTextEmpty(void) {
	MADReportPDFShapedText shaped;
	shaped.glyphs = NULL;
	shaped.count = 0;
	shaped.width = 0.0;
	return shaped;
}

static void MADReportPDFShapedTextFree(MADReportPDFShapedText shaped) {
	if (shaped.glyphs != NULL) free(shaped.glyphs);
}

static double MADReportPDFScale(FT_Face face, double size) {
	double units = (double)(face->units_per_EM > 0 ? face->units_per_EM : 2048);
	return size / units;
}

// The UTF-16 string as Unicode scalars, without control characters (a line break
// has no glyph; Core Text breaks the line there, and the walk's frames are one line
// apiece, so the PDF keeps the text on that line with a space where the break was).
static NSUInteger MADReportPDFScalars(NSString *text, uint32_t *scalars, NSUInteger capacity) {
	NSUInteger count = 0;
	NSUInteger index = 0;
	NSUInteger length = text.length;
	while (index < length && count < capacity) {
		unichar unit = [text characterAtIndex: index++];
		uint32_t scalar = unit;
		if (unit >= 0xD800 && unit <= 0xDBFF && index < length) {
			unichar low = [text characterAtIndex: index];
			if (low >= 0xDC00 && low <= 0xDFFF) {
				index++;
				scalar = 0x10000 + (((uint32_t)(unit - 0xD800)) << 10) + (uint32_t)(low - 0xDC00);
			}
		}
		if (scalar < 0x20 || scalar == 0x7F) {
			if (scalar == 0x09) {	// a tab is a space's advance, as the renderer draws it
				scalar = 0x20;
			} else {
				continue;
			}
		}
		scalars[count++] = scalar;
	}
	return count;
}

static MADReportPDFShapedText MADReportPDFShapeScalars(const uint32_t *scalars,
													   NSUInteger count,
													   FT_Face face) {

	MADReportPDFShapedText shaped = MADReportPDFShapedTextEmpty();
	if (count == 0) return shaped;

	shaped.glyphs = calloc(count, sizeof(cairo_glyph_t));
	if (shaped.glyphs == NULL) return shaped;

	// The face's size is the caller's (the line's size): an unhinted glyph's
	// advance in 26.6 device units at the PDF surface's 1-point device scale, and
	// the face's `kern` table at the same size.  Both depend only on (face, size),
	// so two exports shape the same text identically.
	double pen = 0.0;
	FT_UInt previous = 0;

	for (NSUInteger index = 0; index < count; index++) {
		FT_UInt glyphIndex = FT_Get_Char_Index(face, scalars[index]);

		if (index > 0 && previous != 0 && glyphIndex != 0) {
			FT_Vector kerning;
			if (FT_Get_Kerning(face, previous, glyphIndex, FT_KERNING_UNFITTED, &kerning) == 0) {
				pen += (double)kerning.x / 64.0;
			}
		}

		shaped.glyphs[index].index = glyphIndex;
		shaped.glyphs[index].x = pen;
		shaped.glyphs[index].y = 0.0;

		if (FT_Load_Glyph(face, glyphIndex, FT_LOAD_NO_HINTING) == 0) {
			pen += (double)face->glyph->advance.x / 64.0;
		}
		previous = glyphIndex;
	}

	shaped.count = count;
	shaped.width = pen;
	return shaped;
}

// NSLineBreakByTruncatingTail, which MADElementStylizedText sets: the line is one
// line, and what does not fit is cut and ends with an ellipsis.
static MADReportPDFShapedText MADReportPDFShapeText(NSString *text,
													FT_Face face,
													double maxWidth) {

	if (text.length == 0) return MADReportPDFShapedTextEmpty();

	uint32_t *scalars = calloc(text.length + 1, sizeof(uint32_t));
	if (scalars == NULL) return MADReportPDFShapedTextEmpty();
	NSUInteger count = MADReportPDFScalars(text, scalars, text.length + 1);
	MADReportPDFShapedText shaped = MADReportPDFShapeScalars(scalars, count, face);

	if (shaped.glyphs == NULL || shaped.width <= maxWidth || maxWidth <= 0.0) {
		free(scalars);
		return shaped;
	}

	uint32_t ellipsisScalar = 0x2026;
	MADReportPDFShapedText ellipsis = MADReportPDFShapeScalars(&ellipsisScalar, 1, face);
	double ellipsisWidth = ellipsis.width;
	MADReportPDFShapedTextFree(ellipsis);

	if (ellipsisWidth > maxWidth) {
		MADReportPDFShapedTextFree(shaped);
		free(scalars);
		return MADReportPDFShapedTextEmpty();
	}

	// The longest scalar prefix whose width, with the ellipsis, fits the frame.
	// Width is monotonic in the prefix length, so the search is a bisection; the
	// kerning at the cut is recomputed for each candidate.
	NSUInteger low = 0;
	NSUInteger high = count;
	MADReportPDFShapedText best = MADReportPDFShapedTextEmpty();
	while (low < high) {
		NSUInteger middle = (low + high + 1) / 2;
		MADReportPDFShapedText candidate = MADReportPDFShapeScalars(scalars, middle, face);
		if (candidate.glyphs != NULL && candidate.width + ellipsisWidth <= maxWidth) {
			MADReportPDFShapedTextFree(best);
			best = candidate;
			low = middle;
		} else {
			MADReportPDFShapedTextFree(candidate);
			high = middle - 1;
		}
	}
	free(scalars);
	MADReportPDFShapedTextFree(shaped);

	if (best.glyphs == NULL) {
		best = MADReportPDFShapeScalars(&ellipsisScalar, 1, face);
		return best;
	}

	cairo_glyph_t *glyphs = realloc(best.glyphs, (best.count + 1) * sizeof(cairo_glyph_t));
	if (glyphs != NULL) {
		best.glyphs = glyphs;
		best.glyphs[best.count].index = FT_Get_Char_Index(face, ellipsisScalar);
		best.glyphs[best.count].x = best.width;
		best.glyphs[best.count].y = 0.0;
		best.count += 1;
		best.width += ellipsisWidth;
	}
	return best;
}

#pragma mark - Image decoding

typedef struct {
	const uint8_t *bytes;
	NSUInteger length;
	NSUInteger offset;
} MADReportPDFPNGReader;

static cairo_status_t MADReportPDFReadPNG(void *closure, unsigned char *buffer, unsigned int length) {
	MADReportPDFPNGReader *reader = (MADReportPDFPNGReader *)closure;
	NSUInteger remaining = reader->length - reader->offset;
	NSUInteger take = (NSUInteger)length < remaining ? (NSUInteger)length : remaining;
	if (take > 0) {
		memcpy(buffer, reader->bytes + reader->offset, take);
		reader->offset += take;
	}
	return CAIRO_STATUS_SUCCESS;
}

#pragma mark - The stream a PDF is written to

typedef struct {
	__unsafe_unretained NSFileHandle *handle;
	BOOL failed;
} MADReportPDFFileTarget;

static cairo_status_t MADReportPDFWrite(void *closure, const unsigned char *data, unsigned int length) {
	MADReportPDFFileTarget *target = (MADReportPDFFileTarget *)closure;
	@autoreleasepool {
		NSData *chunk = [NSData dataWithBytes: data length: length];
		@try {
			[target->handle writeData: chunk];
		} @catch (NSException *exception) {
			target->failed = YES;
			return CAIRO_STATUS_WRITE_ERROR;
		}
	}
	return CAIRO_STATUS_SUCCESS;
}

#pragma mark - The writer

@implementation MADReportExporterPDFCairo {
	FT_Library _library;
	FT_Face _faces[3][2][2];	// family, bold, italic
	NSMutableDictionary <NSString *, NSValue *> *_scaledFonts;
	NSMutableArray <NSValue *> *_fontFaces;
	NSMutableArray <NSData *> *_fontData;
	NSString *_fontsDirectory;
}

+ (NSString *)fontsDirectory {
	static NSString *directory = nil;
	static BOOL resolved = NO;
	@synchronized (self) {
		if (resolved) return directory;
		resolved = YES;

		NSMutableArray <NSString *> *candidates = [NSMutableArray array];
		const char *override = NULL;
#if defined(_WIN32)
		char *windowsOverride = NULL;
		size_t windowsOverrideLength = 0;
		if (_dupenv_s(&windowsOverride, &windowsOverrideLength, "MAD_FONTS_DIR") == 0) {
			override = windowsOverride;
		}
#else
		override = getenv("MAD_FONTS_DIR");
#endif
		if (override != NULL && override[0] != '\0') {
			[candidates addObject: [NSString stringWithUTF8String: override]];
		}
#if defined(_WIN32)
		free(windowsOverride);
#endif
		NSString *executableDirectory = MADReportPDFExecutableDirectory();
		if (executableDirectory.length > 0) {
			[candidates addObject: [executableDirectory stringByAppendingPathComponent: @"fonts"]];
			// The build trees keep the fonts one level above the test binaries.
			[candidates addObject: [[executableDirectory stringByDeletingLastPathComponent]
									stringByAppendingPathComponent: @"fonts"]];
			[candidates addObject: [[executableDirectory stringByDeletingLastPathComponent]
									stringByAppendingPathComponent: @"share/mad/fonts"]];
		}
		[candidates addObject: @"/usr/local/share/mad/fonts"];
		[candidates addObject: @"/usr/share/mad/fonts"];
		[candidates addObject: @"/usr/local/share/fonts/liberation"];
		[candidates addObject: @"/usr/share/fonts/truetype/liberation"];

		NSFileManager *fileManager = [NSFileManager defaultManager];
		for (NSString *candidate in candidates) {
			NSString *probe = [[candidate stringByAppendingPathComponent:
								MADReportPDFFaceFile(MADReportPDFFamilySans, NO, NO)]
							   stringByAppendingPathExtension: @"ttf"];
			if ([fileManager fileExistsAtPath: probe]) {
				directory = [candidate copy];
				break;
			}
		}
		return directory;
	}
}

+ (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description {
	return [NSError errorWithDomain: @"MADReportExport"
							   code: code
						   userInfo: @{ NSLocalizedDescriptionKey: description }];
}

- (instancetype)init {
	if (self = [super init]) {
		_scaledFonts = [[NSMutableDictionary alloc] init];
		_fontFaces = [[NSMutableArray alloc] init];
		_fontData = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc {
	for (NSValue *value in _scaledFonts.allValues) {
		cairo_scaled_font_destroy((cairo_scaled_font_t *)value.pointerValue);
	}
	for (NSValue *value in _fontFaces) {
		cairo_font_face_destroy((cairo_font_face_t *)value.pointerValue);
	}
	for (NSUInteger family = 0; family < 3; family++) {
		for (NSUInteger bold = 0; bold < 2; bold++) {
			for (NSUInteger italic = 0; italic < 2; italic++) {
				if (_faces[family][bold][italic] != NULL) {
					FT_Done_Face(_faces[family][bold][italic]);
					_faces[family][bold][italic] = NULL;
				}
			}
		}
	}
	if (_library != NULL) {
		FT_Done_FreeType(_library);
		_library = NULL;
	}
}

#pragma mark - Fonts

- (BOOL)loadFontsWithError:(NSError * _Nullable __autoreleasing *)error {
	_fontsDirectory = [MADReportExporterPDFCairo fontsDirectory];
	if (_fontsDirectory.length == 0) {
		if (error) {
			*error = [MADReportExporterPDFCairo errorWithCode: 6 description:
					  NSLocalizedString(@"The PDF export needs the bundled Liberation fonts, and they were not found. "
										@"Set MAD_FONTS_DIR to the directory holding LiberationSans-Regular.ttf "
										@"(the Linux image installs them in /usr/local/share/mad/fonts).",
										@"Error when the PDF writer cannot find its bundled fonts.")];
		}
		return NO;
	}

	if (FT_Init_FreeType(&_library) != 0) {
		if (error) {
			*error = [MADReportExporterPDFCairo errorWithCode: 7 description:
					  NSLocalizedString(@"The PDF export could not start FreeType.",
										@"Error when the PDF writer cannot initialize FreeType.")];
		}
		return NO;
	}

	for (NSUInteger family = 0; family < 3; family++) {
		for (NSUInteger bold = 0; bold < 2; bold++) {
			for (NSUInteger italic = 0; italic < 2; italic++) {
				NSString *file = MADReportPDFFaceFile((MADReportPDFFamily)family, bold == 1, italic == 1);
				NSString *path = [[_fontsDirectory stringByAppendingPathComponent: file]
								  stringByAppendingPathExtension: @"ttf"];
				// Loaded from memory rather than by path: GNUstep's Windows
				// -fileSystemRepresentation is UTF-16, and FreeType's path API takes
				// char.  The bytes stay alive with the face for the export's lifetime.
				NSData *data = [NSData dataWithContentsOfFile: path];
				FT_Face face = NULL;
				if (data.length == 0 ||
					FT_New_Memory_Face(_library, data.bytes, (FT_Long)data.length, 0, &face) != 0) {
					if (error) {
						*error = [MADReportExporterPDFCairo errorWithCode: 8 description:
								  [NSString stringWithFormat:
								   NSLocalizedString(@"The PDF export could not open the bundled font %@.",
													 @"Error when one bundled PDF font is unreadable; %@ is the file name."),
								   path]];
					}
					return NO;
				}
				[_fontData addObject: data];
				// A face has no size until one is set, and FT_Load_Glyph refuses a
				// sizeless face even with FT_LOAD_NO_SCALE.  The metrics are read
				// unscaled from the font's units; the size is only the placeholder
				// cairo replaces when it scales the face for the surface.
				FT_Set_Char_Size(face, 0, 12 * 64, 72, 72);
				_faces[family][bold][italic] = face;
			}
		}
	}
	return YES;
}

// The style's face: the family its font name maps to, with the element's bold and
// italic flags -- and any the name itself states -- choosing the face.
- (FT_Face)faceForStyle:(MADReportLineStyle *)style {
	BOOL bold = NO;
	BOOL italic = NO;
	NSString *name = style.fontName.length > 0 ? style.fontName : @"Helvetica Neue";
	MADReportPDFFamily family = MADReportPDFFamilyForName(name, &bold, &italic);
	bold = bold || style.bold;
	italic = italic || style.italic;
	return _faces[family][bold ? 1 : 0][italic ? 1 : 0];
}

// The scaled font for one face at one size: cairo's glyph positions and the PDF
// font resource are keyed by it, so one per (face, size) per export.
- (cairo_scaled_font_t *)scaledFontForFace:(FT_Face)face size:(double)size {
	NSString *key = [NSString stringWithFormat: @"%p/%.4f", (void *)face, size];
	NSValue *cached = _scaledFonts[key];
	if (cached != nil) {
		return (cairo_scaled_font_t *)cached.pointerValue;
	}

	cairo_font_face_t *fontFace = cairo_ft_font_face_create_for_ft_face(face, 0);
	if (cairo_font_face_status(fontFace) != CAIRO_STATUS_SUCCESS) {
		cairo_font_face_destroy(fontFace);
		return NULL;
	}
	[_fontFaces addObject: [NSValue valueWithPointer: fontFace]];

	cairo_matrix_t fontMatrix, identity;
	cairo_matrix_init_scale(&fontMatrix, size, size);
	cairo_matrix_init_identity(&identity);
	cairo_font_options_t *options = cairo_font_options_create();
	// The PDF's glyph outlines are vector; hinting would only change the widths
	// cairo records, and a report should not depend on a pixel grid's idea of an
	// advance.
	cairo_font_options_set_hint_style(options, CAIRO_HINT_STYLE_NONE);
	cairo_font_options_set_hint_metrics(options, CAIRO_HINT_METRICS_OFF);

	cairo_scaled_font_t *scaled = cairo_scaled_font_create(fontFace, &fontMatrix, &identity, options);
	cairo_font_options_destroy(options);
	if (cairo_scaled_font_status(scaled) != CAIRO_STATUS_SUCCESS) {
		cairo_scaled_font_destroy(scaled);
		return NULL;
	}
	_scaledFonts[key] = [NSValue valueWithPointer: scaled];
	return scaled;
}

#pragma mark - Drawing

// A filled rectangle in the walk's coordinates.  Cairo's PDF surface uses the same
// y-down space as the walk (its page content carries the flip that turns it into
// PDF's y-up device space), so the frame is passed through unchanged.
static void MADReportPDFFillRect(cairo_t *cr, CGRect rect) {
	cairo_rectangle(cr, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
	cairo_fill(cr);
}

- (void)drawDecorations:(MADReportLineStyle *)style
				  width:(double)width
				   face:(FT_Face)face
			   fontSize:(double)size
			   baseline:(double)baseline
				   left:(double)left
					 cr:(cairo_t *)cr {

	if (!style.underline && !style.strikethrough) return;

	double scale = MADReportPDFScale(face, size);
	TT_Postscript *postscript = (TT_Postscript *)FT_Get_Sfnt_Table(face, FT_SFNT_POST);

	cairo_set_source_rgb(cr, 0.0, 0.0, 0.0);
	if (style.underline) {
		// The PostScript underline position is negative below the baseline; the
		// walk's y axis grows downward, so subtracting it puts the rule below.
		double offset = postscript != NULL ? (double)postscript->underlinePosition * scale : -(0.10 * size);
		double thickness = postscript != NULL ? (double)postscript->underlineThickness * scale : 0.05 * size;
		if (thickness < 0.5) thickness = 0.5;
		CGRect rule = CGRectMake(left, baseline - offset, width, thickness);
		MADReportPDFFillRect(cr, rule);
	}
	if (style.strikethrough) {
		double offset = 0.30 * size;
		double thickness = 0.05 * size;
		if (thickness < 0.5) thickness = 0.5;
		CGRect rule = CGRectMake(left, baseline - offset, width, thickness);
		MADReportPDFFillRect(cr, rule);
	}
}

- (void)drawText:(NSString *)text
		   style:(MADReportLineStyle *)style
		   frame:(CGRect)frame
			  cr:(cairo_t *)cr {

	if (text.length == 0) return;

	FT_Face face = [self faceForStyle: style];
	if (face == NULL) return;
	double size = style.fontSize > 0.0 ? style.fontSize : 12.0;
	cairo_scaled_font_t *scaled = [self scaledFontForFace: face size: size];
	if (scaled == NULL) return;

	// The face's size is set here, per line, rather than read from cairo's lock:
	// cairo leaves the face in whatever state its last scaled font chose, and two
	// exports of one report must shape identically (the deterministic mode's
	// guarantee).  The advances, kerning and ascent below are then a pure
	// function of (face, size).
	FT_Set_Char_Size(face, 0, (FT_F26Dot6)(size * 64.0), 72, 72);
	MADReportPDFShapedText shaped = MADReportPDFShapeText(text, face, frame.size.width);
	double ascent = face->size != NULL
		? (double)face->size->metrics.ascender / 64.0
		: (double)face->ascender * MADReportPDFScale(face, size);

	if (shaped.glyphs == NULL || shaped.count == 0) {
		MADReportPDFShapedTextFree(shaped);
		return;
	}

	double left = frame.origin.x;
	switch (style.horizontalAlignment) {
		case MADHorizontalAlignmentCenter:
			left += (frame.size.width - shaped.width) / 2.0;
			break;
		case MADHorizontalAlignmentRight:
			left += frame.size.width - shaped.width;
			break;
		default:
			break;
	}
	double baseline = frame.origin.y + ascent;

	for (size_t index = 0; index < shaped.count; index++) {
		shaped.glyphs[index].x += left;
		shaped.glyphs[index].y = baseline;
	}

	cairo_set_scaled_font(cr, scaled);
	cairo_set_source_rgb(cr, 0.0, 0.0, 0.0);
	cairo_show_glyphs(cr, shaped.glyphs, (int)shaped.count);

	[self drawDecorations: style width: shaped.width face: face fontSize: size
				 baseline: baseline left: left cr: cr];

	MADReportPDFShapedTextFree(shaped);
}

// A picture -- an image element's stored PNG or a barcode's symbol -- fitted into
// the line's frame the way the HTML facsimile fits it (object-fit: contain).
- (void)drawImageData:(NSData *)data
				frame:(CGRect)frame
				   cr:(cairo_t *)cr {

	if (data.length == 0) return;

	MADReportPDFPNGReader reader;
	reader.bytes = data.bytes;
	reader.length = data.length;
	reader.offset = 0;

	cairo_surface_t *image = cairo_image_surface_create_from_png_stream(MADReportPDFReadPNG, &reader);
	if (cairo_surface_status(image) != CAIRO_STATUS_SUCCESS) {
		cairo_surface_destroy(image);
		return;
	}

	double imageWidth = (double)cairo_image_surface_get_width(image);
	double imageHeight = (double)cairo_image_surface_get_height(image);
	if (imageWidth <= 0.0 || imageHeight <= 0.0 || frame.size.width <= 0.0 || frame.size.height <= 0.0) {
		cairo_surface_destroy(image);
		return;
	}

	double scale = fmin(frame.size.width / imageWidth, frame.size.height / imageHeight);
	double drawnWidth = imageWidth * scale;
	double drawnHeight = imageHeight * scale;
	double left = frame.origin.x + (frame.size.width - drawnWidth) / 2.0;
	double top = frame.origin.y + (frame.size.height - drawnHeight) / 2.0;

	// Both the image surface and the PDF user space are y-down, so the unit
	// square maps the picture upright with a positive scale.
	cairo_save(cr);
	cairo_translate(cr, left, top);
	cairo_scale(cr, drawnWidth, drawnHeight);
	cairo_set_source_surface(cr, image, 0.0, 0.0);
	cairo_pattern_set_filter(cairo_get_source(cr), CAIRO_FILTER_BILINEAR);
	cairo_paint(cr);
	cairo_restore(cr);

	cairo_surface_destroy(image);
}

- (void)drawPage:(MADReportPageRepresentation *)page
		   trim:(CGRect)trim
			 cr:(cairo_t *)cr {

	// The renderer's white canvas, on the trim box (MADPrintPageRenderer
	// drawPageAtIndex: passes the trim box and paints it white).
	cairo_set_source_rgb(cr, 1.0, 1.0, 1.0);
	MADReportPDFFillRect(cr, trim);

	for (MADReportSectionRepresentation *section in [page allSections]) {
		for (MADReportSectionRowsRepresentation *row in [section allRows]) {
			for (MADReportLineRepresentation *line in [row allLines]) {
				NSData *image = [line imageData];
				if (image != nil) {
					[self drawImageData: image frame: line.frame cr: cr];
				} else {
					NSString *text = [line text];
					if (text != nil) {
						[self drawText: text style: line.style frame: line.frame cr: cr];
					}
				}
			}
		}
	}
}

#pragma mark - The export

+ (BOOL)writeDocument:(id <MADDocumentDataProtocol>)document
				toURL:(NSURL *)url
			  options:(MADReportExportOptions)options
				error:(NSError * _Nullable __autoreleasing *)error {

	if (![document conformsToProtocol: @protocol(MADDocumentRenderProtocol)]) {
		if (error) {
			*error = [self errorWithCode: 3 description:
					  NSLocalizedString(@"PDF needs a document that renders (MADDocumentRenderProtocol).",
										@"Error when the PDF export has no renderable document.")];
		}
		return NO;
	}
	if (url == nil) {
		if (error) {
			*error = [self errorWithCode: 4 description:
					  NSLocalizedString(@"PDF needs a file to write to.", @"Error when the PDF export has no output file.")];
		}
		return NO;
	}

	MADReportExporterPDFCairo *writer = [[MADReportExporterPDFCairo alloc] init];
	return [writer writeDocument: document toURL: url options: options error: error];
}

- (BOOL)writeDocument:(id <MADDocumentDataProtocol>)document
				toURL:(NSURL *)url
			  options:(MADReportExportOptions)options
				error:(NSError * _Nullable __autoreleasing *)error {

	id <MADDocumentRenderProtocol> renderDocument = (id <MADDocumentRenderProtocol>)document;

	// The reload the viewer runs after a refresh, then the page's letter-and-1pt-trim
	// geometry: the same preparation MADReportExporterPDF's Apple body runs.
	[MADReportPageBuilder prepareDocumentForRender: renderDocument];
	MADReportFormatter *reportFormatter = renderDocument.reportFormatter;

	CGRect letterRect = [MADReportPageBuilder pageBoundsForDocument: renderDocument];
	CGRect trimBox = [MADReportPageBuilder pageTrimBoxForDocument: renderDocument];

	if (![self loadFontsWithError: error]) return NO;

	NSString *path = url.path;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager removeItemAtPath: path error: NULL];
	if (![fileManager createFileAtPath: path contents: nil attributes: nil]) {
		if (error) {
			*error = [MADReportExporterPDFCairo errorWithCode: 9 description:
					  [NSString stringWithFormat:
					   NSLocalizedString(@"The PDF could not be written to %@.", @"Error when the PDF output file cannot be created; %@ is the path."),
					   path]];
		}
		return NO;
	}
	NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath: path];
	if (handle == nil) {
		if (error) {
			*error = [MADReportExporterPDFCairo errorWithCode: 9 description:
					  [NSString stringWithFormat:
					   NSLocalizedString(@"The PDF could not be written to %@.", @"Error when the PDF output file cannot be opened; %@ is the path."),
					   path]];
		}
		return NO;
	}

	MADReportPDFFileTarget target;
	target.handle = handle;
	target.failed = NO;

	// PDF 1.4: a classic cross-reference table and plain objects.  Cairo defaults to
	// 1.7 (object and cross-reference streams), which is no simpler to draw and
	// harder to read back in a test.
	cairo_surface_t *surface = cairo_pdf_surface_create_for_stream(MADReportPDFWrite, &target,
																  letterRect.size.width,
																  letterRect.size.height);
	cairo_status_t surfaceStatus = cairo_surface_status(surface);
	if (surfaceStatus != CAIRO_STATUS_SUCCESS) {
		cairo_surface_destroy(surface);
		[handle closeFile];
		[fileManager removeItemAtPath: path error: NULL];
		if (error) {
			*error = [MADReportExporterPDFCairo errorWithCode: 10 description:
					  [NSString stringWithFormat:
					   NSLocalizedString(@"The PDF surface could not be created: %s.", @"Error when the Cairo PDF surface cannot start; %s is Cairo's status."),
					   cairo_status_to_string(surfaceStatus)]];
		}
		return NO;
	}

	cairo_pdf_surface_restrict_to_version(surface, CAIRO_PDF_VERSION_1_4);
	cairo_pdf_surface_set_metadata(surface, CAIRO_PDF_METADATA_CREATOR, MADReportPDFCreator.UTF8String);

	if (options & MADReportExportOptionsDeterministic) {
		// Cairo takes the creation date from the clock and writes no trailer /ID.
		// Pinning the two dates is therefore enough for two runs over an unchanged
		// report to be the same bytes, the guarantee the Apple body gives by
		// rewriting its trailer.
		cairo_pdf_surface_set_metadata(surface, CAIRO_PDF_METADATA_CREATE_DATE,
									   MADReportPDFPinnedDate.UTF8String);
		cairo_pdf_surface_set_metadata(surface, CAIRO_PDF_METADATA_MOD_DATE,
									   MADReportPDFPinnedDate.UTF8String);
	}

	cairo_t *cr = cairo_create(surface);
	MADReportPageBuilder *builder = [[MADReportPageBuilder alloc] initWithDataSource: renderDocument];

	NSUInteger pages = reportFormatter.numberOfPages;
	for (NSUInteger pageIndex = 0; pageIndex < pages; pageIndex++) {
		@autoreleasepool {
			MADReportPageRepresentation *page = [builder buildPageAtIndex: pageIndex
															   inPageRect: trimBox
																	 draw: NULL];
			if (page != nil) {
				[self drawPage: page trim: trimBox cr: cr];
			}
			cairo_show_page(cr);
		}
	}

	cairo_status_t contextStatus = cairo_status(cr);
	cairo_destroy(cr);
	cairo_surface_finish(surface);
	cairo_status_t finishedStatus = cairo_surface_status(surface);
	cairo_surface_destroy(surface);
	[handle closeFile];

	if (contextStatus != CAIRO_STATUS_SUCCESS || finishedStatus != CAIRO_STATUS_SUCCESS || target.failed) {
		[fileManager removeItemAtPath: path error: NULL];
		if (error) {
			cairo_status_t status = contextStatus != CAIRO_STATUS_SUCCESS ? contextStatus : finishedStatus;
			*error = [MADReportExporterPDFCairo errorWithCode: 10 description:
					  [NSString stringWithFormat:
					   NSLocalizedString(@"The PDF could not be written: %s.", @"Error when Cairo fails while writing the PDF; %s is Cairo's status."),
					   cairo_status_to_string(status)]];
		}
		return NO;
	}

	if (![fileManager fileExistsAtPath: path]) {
		if (error) {
			*error = [MADReportExporterPDFCairo errorWithCode: 5 description:
					  NSLocalizedString(@"No PDF was written.", @"Error when the PDF export produced no file.")];
		}
		return NO;
	}

	return YES;
}

@end
