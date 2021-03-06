import QtQuick                      2.11
import QtQuick.Controls             2.4
import QtQuick.Controls.Styles      1.4
import QtQuick.Layouts              1.11

import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0
import QGroundControl.Controls      1.0
import QGroundControl.FactControls  1.0
import QGroundControl.Palette       1.0

// Editor for Simple mission items
Rectangle {
    width:  availableWidth
    height: editorColumn.height + (_margin * 2)
    color:  qgcPal.windowShadeDark
    radius: _radius

    property bool _specifiesAltitude:       missionItem.specifiesAltitude
    property real _margin:                  ScreenTools.defaultFontPixelHeight / 2
    property bool _supportsTerrainFrame:    missionItem

    property string _altModeRelativeHelpText:       qsTr("시작위치 기준 고도")
    property string _altModeAbsoluteHelpText:       qsTr("평균 해수면 기준 고도")
    property string _altModeAboveTerrainHelpText:   qsTr("지형 기준 고도\n 실제 AMSL 고도: %1 %2").arg(missionItem.amslAltAboveTerrain.valueString).arg(missionItem.amslAltAboveTerrain.units)
    property string _altModeTerrainFrameHelpText:   qsTr("Using terrain reference frame")

    function updateAltitudeModeText() {
        if (missionItem.altitudeMode === QGroundControl.AltitudeModeRelative) {
            altModeLabel.text = qsTr("고도")
            altModeHelp.text = _altModeRelativeHelpText
        } else if (missionItem.altitudeMode === QGroundControl.AltitudeModeAbsolute) {
            altModeLabel.text = qsTr("해발 고도")
            altModeHelp.text = _altModeAbsoluteHelpText
        } else if (missionItem.altitudeMode === QGroundControl.AltitudeModeAboveTerrain) {
            altModeLabel.text = qsTr("지상 고도")
            altModeHelp.text = Qt.binding(function() { return _altModeAboveTerrainHelpText })
        } else if (missionItem.altitudeMode === QGroundControl.AltitudeModeTerrainFrame) {
            altModeLabel.text = qsTr("Terrain Frame")
            altModeHelp.text = _altModeTerrainFrameHelpText
        } else {
            altModeLabel.text = qsTr("Internal Error")
            altModeHelp.text = ""
        }
    }

    Component.onCompleted: updateAltitudeModeText()

    Connections {
        target:                 missionItem
        onAltitudeModeChanged:  updateAltitudeModeText()
    }

    Column {
        id:                 editorColumn
        anchors.margins:    _margin
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.top:        parent.top

        ColumnLayout {
            anchors.left:       parent.left
            anchors.right:      parent.right
            spacing:            _margin
            visible:            missionItem.isTakeoffItem && missionItem.wizardMode // Hack special case for takeoff item

            QGCLabel {
                text:               qsTr("'T' 를 옮겨 이륙 위치를 지정하세요.")
                Layout.fillWidth:   true
                wrapMode:           Text.WordWrap
                visible:            !initialClickLabel.visible
            }

            QGCLabel {
                text:               qsTr("장애물과 바람 여부를 확인하세요.")
                Layout.fillWidth:   true
                wrapMode:           Text.WordWrap
                visible:            !initialClickLabel.visible
            }

            QGCButton {
                text:               qsTr("조정 완료")
                Layout.fillWidth:   true
                visible:            !initialClickLabel.visible
                onClicked: {
                    missionItem.wizardMode = false
                    editorRoot.selectNextNotReadyItem()
                }
            }

            QGCLabel {
                id:                 initialClickLabel
                text:               missionItem.launchTakeoffAtSameLocation ?
                                        qsTr("이륙 위치를 지정하려면 맵을 클릭하세요.") :
                                        qsTr("Launch 위치를 지정하려면 맵을 클릭하세요.")
                Layout.fillWidth:   true
                wrapMode:           Text.WordWrap
                visible:            missionItem.isTakeoffItem && !missionItem.launchCoordinate.isValid
            }
        }

        Column {
            anchors.left:       parent.left
            anchors.right:      parent.right
            spacing:            _margin
            visible:            !missionItem.wizardMode

            QGCLabel {
                width:          parent.width
                wrapMode:       Text.WordWrap
                font.pointSize: ScreenTools.smallFontPointSize
                text:           missionItem.rawEdit ?
                                    qsTr("Provides advanced access to all commands/parameters. Be very careful!") :
                                    missionItem.commandDescription
            }

            GridLayout {
                anchors.left:   parent.left
                anchors.right:  parent.right
                columns:        2

                Repeater {
                    model: missionItem.comboboxFacts

                    QGCLabel {
                        text:           object.name
                        visible:        object.name !== ""
                        Layout.column:  0
                        Layout.row:     index
                    }
                }

                Repeater {
                    model: missionItem.comboboxFacts

                    FactComboBox {
                        indexModel:         false
                        model:              object.enumStrings
                        fact:               object
                        font.pointSize:     ScreenTools.smallFontPointSize
                        Layout.column:      1
                        Layout.row:         index
                        Layout.fillWidth:   true
                    }
                }
            }

            Rectangle {
                anchors.left:   parent.left
                anchors.right:  parent.right
                height:         altColumn.y + altColumn.height + _margin
                color:          qgcPal.windowShade
                visible:        _specifiesAltitude

                Column {
                    id:                 altColumn
                    anchors.margins:    _margin
                    anchors.top:        parent.top
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    spacing:            _margin

                    Item {
                        width:  altHamburger.x + altHamburger.width
                        height: altModeLabel.height

                        QGCLabel { id: altModeLabel }

                        QGCColoredImage {
                            id:                     altHamburger
                            anchors.leftMargin:     ScreenTools.defaultFontPixelWidth / 4
                            anchors.left:           altModeLabel.right
                            anchors.verticalCenter: altModeLabel.verticalCenter
                            width:                  ScreenTools.defaultFontPixelHeight / 2
                            height:                 width
                            sourceSize.height:      height
                            source:                 "/res/DropArrow.svg"
                            color:                  qgcPal.text
                        }

                        QGCMouseArea {
                            anchors.fill:   parent
                            onClicked:      altHamburgerMenu.popup()
                        }

                        QGCMenu {
                            id: altHamburgerMenu

                            QGCMenuItem {
                                text:           qsTr("고도")
                                checkable:      true
                                checked:        missionItem.altitudeMode === QGroundControl.AltitudeModeRelative
                                onTriggered:    missionItem.altitudeMode = QGroundControl.AltitudeModeRelative
                            }

                            QGCMenuItem {
                                text:           qsTr("해발 고도")
                                checkable:      true
                                checked:        missionItem.altitudeMode === QGroundControl.AltitudeModeAbsolute
                                visible:        QGroundControl.corePlugin.options.showMissionAbsoluteAltitude
                                onTriggered:    missionItem.altitudeMode = QGroundControl.AltitudeModeAbsolute
                            }

                            QGCMenuItem {
                                text:           qsTr("지상 고도")
                                checkable:      true
                                checked:        missionItem.altitudeMode === QGroundControl.AltitudeModeAboveTerrain
                                onTriggered:    missionItem.altitudeMode = QGroundControl.AltitudeModeAboveTerrain
                                visible:        missionItem.specifiesCoordinate
                            }

                            QGCMenuItem {
                                text:           qsTr("Terrain Frame")
                                checkable:      true
                                checked:        missionItem.altitudeMode === QGroundControl.AltitudeModeTerrainFrame
                                visible:        missionItem.altitudeMode === QGroundControl.AltitudeModeTerrainFrame
                                onTriggered:    missionItem.altitudeMode = QGroundControl.AltitudeModeTerrainFrame
                            }
                        }
                    }

                    AltitudeFactTextField {
                        id:                 altField
                        fact:               missionItem.altitude
                        altitudeMode:       missionItem.altitudeMode
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                    }

                    QGCLabel {
                        id:                 altModeHelp
                        wrapMode:           Text.WordWrap
                        font.pointSize:     ScreenTools.smallFontPointSize
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                    }
                }
            }

            GridLayout {
                anchors.left:   parent.left
                anchors.right:  parent.right
                flow:           GridLayout.TopToBottom
                rows:           missionItem.textFieldFacts.count +
                                missionItem.nanFacts.count +
                                (missionItem.speedSection.available ? 1 : 0)
                columns:        2

                Repeater {
                    model: missionItem.textFieldFacts

                    QGCLabel { text: object.name }
                }

                Repeater {
                    model: missionItem.nanFacts

                    QGCCheckBox {
                        text:           object.name
                        checked:        !isNaN(object.rawValue)
                        onClicked:      object.rawValue = checked ? 0 : NaN
                    }
                }

                QGCCheckBox {
                    id:         flightSpeedCheckbox
                    text:       qsTr("비행 속도")
                    checked:    missionItem.speedSection.specifyFlightSpeed
                    onClicked:  missionItem.speedSection.specifyFlightSpeed = checked
                    visible:    missionItem.speedSection.available
                }


                Repeater {
                    model: missionItem.textFieldFacts

                    FactTextField {
                        showUnits:          true
                        fact:               object
                        Layout.fillWidth:   true
                        enabled:            !object.readOnly
                    }
                }

                Repeater {
                    model: missionItem.nanFacts

                    FactTextField {
                        showUnits:          true
                        fact:               object
                        Layout.fillWidth:   true
                        enabled:            !isNaN(object.rawValue)
                    }
                }

                FactTextField {
                    fact:               missionItem.speedSection.flightSpeed
                    Layout.fillWidth:   true
                    enabled:            flightSpeedCheckbox.checked
                    visible:            missionItem.speedSection.available
                }
            }

            CameraSection {
                checked:    missionItem.cameraSection.settingsSpecified
                visible:    missionItem.cameraSection.available
            }
        }
    }
}
