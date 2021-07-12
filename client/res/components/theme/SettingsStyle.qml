// Copyright (c) 2021 Private Internet Access, Inc.
//
// This file is part of the Private Internet Access Desktop Client.
//
// The Private Internet Access Desktop Client is free software: you can
// redistribute it and/or modify it under the terms of the GNU General Public
// License as published by the Free Software Foundation, either version 3 of
// the License, or (at your option) any later version.
//
// The Private Internet Access Desktop Client is distributed in the hope that
// it will be useful, but WITHOUT ANY WARRANTY; without even the implied
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with the Private Internet Access Desktop Client.  If not, see
// <https://www.gnu.org/licenses/>.

import QtQuick 2.0
QtObject {
    readonly property bool horizontal: Qt.platform.os !== 'windows'

    readonly property int contentWidth: 520
    readonly property int contentHeight: Theme.settings.horizontal ? 410 : 430

    readonly property color backgroundColor: Theme.dark ? "#323642" : "#eeeeee"

    readonly property int hbarHeight: 67
    readonly property int hbarItemWidth: 68
    // Minimum spacing between the items (sized at hbarItemWidth), relevant if
    // the text labels are short.
    readonly property int hbarItemSpacing: 5
    // Minimum gap between adjacent labels.  If the text strings are long, the
    // spacing is increased to maintain this minimum gap.
    readonly property int hbarItemMinLabelGap: 8
    readonly property color hbarBackgroundColor: Theme.dark ? "#22252e" : "#d7d8d9"
    readonly property color hbarBottomBorderColor: Theme.dark ? "#5c6370" : "#eeeeee"
    readonly property color hbarHiglightBarColor: Theme.dark ? "#5ddf5a" : "#4cb649"
    readonly property color hbarTextColor: Theme.dark ? "#ffffff" : "#22252e"
    readonly property int hbarTextPx: 12
    readonly property int hbarContentTopMargin: 40
    readonly property int hbarContentLeftMargin: 60
    readonly property int hbarContentRightMargin: 60
    readonly property int hbarContentBottomMargin: 30

    readonly property var pageImages: ({
      'general': [ Theme.imagePathCommon + "/settings/general-active.png", Theme.imagePath + "/settings/general-inactive.png" ],
      'account': [ Theme.imagePathCommon + "/settings/account-active.png", Theme.imagePath + "/settings/account-inactive.png" ],
      'privacy': [ Theme.imagePathCommon + "/settings/privacy-active.png", Theme.imagePath + "/settings/privacy-inactive.png" ],
      'network': [ Theme.imagePathCommon + "/settings/network-active.png", Theme.imagePath + "/settings/network-inactive.png" ],
      'connection': [ Theme.imagePathCommon + "/settings/connection-active.png", Theme.imagePath + "/settings/connection-inactive.png" ],
      'automation': [ Theme.imagePathCommon + "/settings/automation-active.png", Theme.imagePath + "/settings/automation-inactive.png" ],
      'dedicatedip': [ Theme.imagePathCommon + "/settings/dedicatedip-active.png", Theme.imagePath + "/settings/dedicatedip-inactive.png" ],
      'help': [ Theme.imagePathCommon + "/settings/help-active.png", Theme.imagePath + "/settings/help-inactive.png" ],
    })
    readonly property var buttonIcons: ({
      'configure': Theme.imagePath + "/icons/configure.png"
    })

    readonly property var ruleTypeImages: ({
      'wired': Theme.imagePath + "/settings/automation-rule-types/wired.png",
      'openWifi': Theme.imagePath + "/settings/automation-rule-types/openWifi.png",
      'protectedWifi': Theme.imagePath + "/settings/automation-rule-types/protectedWifi.png",
      'ssid': Theme.imagePath + "/settings/automation-rule-types/ssid.png",
    })
    readonly property color pageIconBgInactiveColor: Theme.dark ? "#323642" : "#9a9da5"
    readonly property color pageIconBgActiveColor: "#4cb649"

    readonly property int vbarWidth: 200
    readonly property int vbarItemHeight: 48
    readonly property color vbarBackgroundColor: Theme.dark ? "#22252e" : "#d7d8d9"
    readonly property color vbarActiveBackgroundColor: Theme.dark ? "#171920" : "#c2c5c8"
    readonly property color vbarHiglightBarColor: Theme.dark ? "#5ddf5a" : "#4cb649"
    readonly property color vbarTextColor: Theme.dark ? "#ffffff" : "#22252e"
    readonly property int vbarTextPx: 12
    readonly property string vbarHeaderImage: Theme.imagePath + "/logo-78.png"
    readonly property int vbarContentTopMargin: 20
    readonly property int vbarContentLeftMargin: 60
    readonly property int vbarContentRightMargin: 60
    readonly property int vbarContentBottomMargin: 30

    // Extra left margin for pages with relatively narrow content
    readonly property int narrowPageLeftMargin: horizontal ? 80 : 0

    readonly property int headingHeight: 90
    readonly property color headingLineColor: Theme.dark ? "#484a55" : "#d7d8d9"
    readonly property color headingTextColor: Theme.dark ? "#ffffff" : "#22252e"
    readonly property int headingTextPx: 24

    readonly property color inputLabelColor: Theme.dark ? "#ffffff" : "#323642"
    readonly property color inputLabelDisabledColor: "#889099"
    readonly property int inputLabelTextPx: 13
    readonly property color inputDescriptionColor: "#889099"

    readonly property string inputCheckboxOnImage: Theme.imagePath + "/settings/checkbox-on.png"
    readonly property string inputCheckboxOffImage: Theme.imagePath + "/settings/checkbox-off.png"
    readonly property string inputCheckboxDisabledImage: Theme.imagePath + "/settings/checkbox-disabled.png"

    readonly property string inputRadioOnImage: Theme.imagePathCommon + "/settings/radio-on.png"
    readonly property string inputRadioOffImage: Theme.imagePath + "/settings/radio-off.png"

    readonly property color inputTextboxBackgroundColor: Theme.dark ? "#22252e" : "#ffffff"
    readonly property color inputTextboxBorderColor: Theme.dark ? "#5c6370" : "#d7d8d9"
    readonly property color inputTextboxInvalidBorderColor: '#f24458'
    readonly property color inputTextboxWarningBorderColor: '#e6b400'
    readonly property color inputTextboxTextColor: Theme.dark ? "#ffffff" : "#323642"
    readonly property color inputTextboxTextDisabledColor: inputLabelDisabledColor

    readonly property color inputDropdownBackgroundColor: inputTextboxBackgroundColor
    readonly property color inputDropdownBorderColor: inputTextboxBorderColor
    readonly property color inputDropdownSelectedColor: Theme.dark ? "#4cb649" : "#5ddf5a"
    readonly property color inputDropdownTextColor: inputTextboxTextColor
    readonly property color inputDropdownTextDisabledColor: inputTextboxTextDisabledColor
    readonly property color inputDropdownArrowColor: "#ffffff"
    readonly property color inputDropdownArrowBackgroundColor: "#5ddf5a"
    readonly property color inputDropdownArrowBorderColor: "#4cb649"
    readonly property color inputDropdownArrowDisabledBackgroundColor: Theme.dark ? "#889098" : "#c2c5c8"
    readonly property color inputDropdownArrowDisabledBorderColor: "#889099"
    readonly property color inputDropdownIconBackdropColor: Theme.dark ? "#5a6371" : "#aaaaaa";
    readonly property string inputDropdownArrowImage: Theme.imagePathCommon + "/settings/dropdown-arrow.png"
    readonly property string inputDropdownArrowDisabledImage: Theme.imagePathCommon + "/settings/dropdown-arrow-disabled.png"
    readonly property string inputDropdownShadowImage: Theme.imagePathCommon + "/settings/shadow-dropdown.png"

    readonly property color inputListItemPrimaryTextColor: Theme.dark ? "#ffffff" : "#22252e"
    readonly property color inputListItemSecondaryTextColor: "#889099"

    readonly property color inputPrivacyBackgroundColor: Theme.dark ? "#22252e" : "#d7d8d9"
    readonly property color inputPrivacyTextColor: Theme.dark ? "#ffffff" : "#323642"
    readonly property color inputPrivacySelectedTextColor: "#ffffff"
    readonly property color inputPrivacySelectedBackgroundColor: "#5ddf5a"
    readonly property color inputPrivacySelectedBorderColor: "#4cb649"
    readonly property color inputPrivacyDisabledBackgroundColor: "#889099"
    readonly property color inputPrivacyDisabledBorderColor: "#889099"

    // Action buttons in overlay dialogs
    readonly property color inputButtonBackgroundColor: Theme.dark ? "#2b2e39" : "#d7d8d9"
    readonly property color inputButtonDisabledBackgroundColor: Theme.dark ? "#323642" : "#eeeeee"
    readonly property color inputButtonPressedBackgroundColor: Theme.dark ? "#22252e" : "#c2c5c8"
    readonly property color inputButtonTextColor: inputLabelColor
    readonly property color inputButtonDisabledTextColor: inputLabelDisabledColor
    readonly property color inputButtonDisabledBorderColor: Theme.dark ? "#2b2e39" : "#d7d8d9"
    readonly property color inputButtonFocusBorderColor: Theme.dark ? "#22252e" : "#c2c5c8"

    // Push buttons on settings pages
    readonly property color inputPushButtonHoverBackgroundColor: "#4cb649"
    readonly property color inputPushButtonTextColor: Theme.dark ? "#ffffff" : "#323642"
    readonly property color inputPushButtonHoverTextColor: "#ffffff"

    readonly property string tipInfoImg: Theme.imagePathCommon + "/settings/info.png"
    readonly property string tipWarningImg: Theme.imagePathCommon + "/settings/warning.png"

    readonly property string inputBetaFeature: Theme.imagePathCommon + "/settings/beta-feature.png"
    readonly property string inputPreviewFeature: Theme.imagePathCommon + "/settings/preview-feature.png"

    readonly property color inputDescLinkColor: Theme.dark ? '#5ddf5a' : '#4cb649'
    readonly property color inputDescLinkHoverColor: Theme.dark ? '#7afa78' : '#5ddf5a'

    readonly property color splitTunnelInputBackgroundColor: hbarBackgroundColor
    readonly property color splitTunnelInputBorderColor: hbarBottomBorderColor
    readonly property color splitTunnelInputTextColor: hbarTextColor

    readonly property string splitTunnelAddApplicationButton: Theme.imagePath + "/settings/app-add.png"
    readonly property string splitTunnelAddApplicationButtonHover: Theme.imagePath + "/settings/app-add-hover.png"
    readonly property string splitTunnelRemoveApplicationButton: Theme.imagePath + "/settings/app-delete.png"
    readonly property string splitTunnelRemoveApplicationButtonHover: Theme.imagePath + "/settings/app-delete-hover.png"


    readonly property color splitTunnelItemSeparatorColor: Theme.dark ? hbarBottomBorderColor : "#999da6"

    readonly property string spinnerImage: Theme.imagePath + "/settings/spinner.png"

    readonly property color connectionPageSeparatorColor: "#889099"

    readonly property string reconnectShadowImage: Theme.imagePathCommon + "/settings/shadow-reconnect.png"

    readonly property string dedicatedIpPageImage: Theme.imagePath + "/settings/dedicatedip-page.png"

    readonly property string connEventAttemptImage: Theme.imagePath + "/settings/conn-event-attempt.png"
    readonly property string connEventEstablishedImage: Theme.imagePath + "/settings/conn-event-established.png"
    readonly property string connEventCanceledImage: Theme.imagePath + "/settings/conn-event-canceled.png"
    readonly property string connEventExpandButton: Theme.imagePath + "/settings/conn-event-expand.png"
    readonly property string connEventExpandButtonHover: Theme.imagePath + "/settings/conn-event-expand-hover.png"
}
