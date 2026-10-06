# The MADCocoaExtensions subset the Linux build compiles (MAD_LINUX.md §9):
# the 7 layout/style implementation files of the Xcode target's 14.  The
# framework splits cleanly: everything that stores geometry, numbers and
# styles is Foundation plus CoreGraphics struct math, and everything that
# draws or presents is UIKit and stays on Apple.
#
# Excluded, with reasons:
#   MADColor.m         holds a UIColor and reads its RGB components
#   MADColorSocial.m   brand UIColors
#   UIColor+EverydayApps.m   a UIColor category
#   MADAlertController.m     UIAlertController subclass
#   MADLabelTitle.m          UILabel subclass
#   MADTextField.m           UITextField subclass
#   MADViewHelpers.m         UIView/UIEdgeInsets helpers for the views
#   NSError+Constructors.m   presents errors through UIAlertController
#   UIApplication+Helpers.m  walks the UIViewController stack
#   MFMailComposeViewController+MADExtensions.m   MessageUI
#
# The geometry they need is Compat/CoreGraphics/ (see CGGeometry.h); the
# excluded files' UIKit imports have no equivalent there by design.  Keep this
# list in step with MAD_LINUX.md §4 and §5.2.

set(MADCOCOAEXTENSIONS_SOURCES
	"${SOURCE_DIR}/CGGeometry+Extras.m"
	"${SOURCE_DIR}/MADBorderStyle.m"
	"${SOURCE_DIR}/MADMargin.m"
	"${SOURCE_DIR}/MADPadding.m"
	"${SOURCE_DIR}/MADTextStyle.m"
	"${SOURCE_DIR}/MTMath.m"
	"${SOURCE_DIR}/NSNumberFormatter+MADExtensions.m"
)
