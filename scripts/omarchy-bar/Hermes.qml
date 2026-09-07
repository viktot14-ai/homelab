import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Hermes usage widget: bar icon + popup panel.
// Left click opens the usage panel (tokens today / week / by model / prompts),
// right click launches Hermes (ollama launch hermes) or focuses the running one.
//
// Data comes from Hermes' own session store (~/.hermes/state.db, SQLite):
//   session_model_usage — tokens per session/model/day (input, output, cache)
//   messages            — user prompts per day
// Read read-only via the sqlite3 CLI through Quickshell Process objects.

Item {
  id: root

  property var bar
  property string moduleName
  property var settings

  readonly property color foreground: bar ? bar.barForeground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  // ------------------------------------------------------------------ state
  property bool panelOpen: false
  property var usage: null        // parsed JSON from the collector script (Hermes tokens)
  property var ollamaUsage: null  // parsed JSON from ollama-usage.py (cloud credits)
  property bool collecting: false

  // Today at midnight (local), for "week" grouping.
  readonly property string homeDir: Quickshell.env("HOME")

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    if (!collectProc.running) {
      collecting = true
      collectProc.running = true
    }
  }

  // ------------------------------------------------------------- collector
  // One bash+python probe prints the display-ready JSON record. Kept inline
  // so the module is a single self-contained file.
  Process {
    id: collectProc
    command: ["bash", "-c", "python3 " + root.homeDir + "/.config/omarchy/bar/modules/hermes-usage.py; echo ---; " + root.homeDir + "/.venvs/brave-cookies/bin/python " + root.homeDir + "/.config/omarchy/bar/modules/ollama-usage.py 2>/dev/null || python3 " + root.homeDir + "/.config/omarchy/bar/modules/ollama-usage.py"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.collecting = false
        var parts = String(text || "").split("---")
        function tryParse(s) {
          try {
            var p = JSON.parse(String(s || "").trim())
            return p && typeof p === "object" ? p : null
          } catch (e) { return null }
        }
        var hermes = tryParse(parts[0])
        var ollama = parts.length > 1 ? tryParse(parts.slice(1).join("---")) : null
        root.usage = hermes
        root.ollamaUsage = ollama && !ollama.error ? ollama : (ollama || null)
        if (!hermes) console.warn("hermes widget: bad usage json")
      }
    }
    onExited: root.collecting = false
  }

  Timer {
    interval: 120000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  IpcHandler {
    target: "hermes.widget"

    function refresh(): string {
      root.refresh()
      return "ok"
    }
    function toggle(): string {
      root.panelOpen = !root.panelOpen
      return "ok"
    }
    function launch(): string {
      if (root.bar) root.bar.run("omarchy-launch-or-focus-tui --app-id=org.omarchy.hermes ollama launch hermes")
      return "ok"
    }
  }

  // ------------------------------------------------------------------ button
  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\ue907"              // Ollama mark from the omarchy font (matches the agents widget family)
    active: root.panelOpen
    tooltipText: "Hermes Agent — left: usage, right: launch"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) {
        if (root.bar) root.bar.run("omarchy-launch-or-focus-tui --app-id=org.omarchy.hermes ollama launch hermes")
        root.panelOpen = false
      } else if (buttonCode === Qt.MiddleButton) {
        root.refresh()
      } else {
        root.refresh()
        root.panelOpen = !root.panelOpen
      }
    }
  }

  // ------------------------------------------------------------------- panel
  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.panelOpen
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      onMoveRequested: function(dx, dy) {
        if (dy !== 0)
          panelFlick.contentY = root.clamp(panelFlick.contentY + dy * Style.space(40), 0,
                                           Math.max(0, panelFlick.contentHeight - panelFlick.height))
      }
      onCloseRequested: root.panelOpen = false
      onTextKey: function(t) { if (t === "r" || t === "R") root.refresh() }
    }

    Flickable {
      id: panelFlick
      anchors.fill: parent
      contentWidth: width
      contentHeight: contentColumn.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      flickableDirection: Flickable.VerticalFlick
      interactive: contentHeight > height
      ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

      Column {
        id: contentColumn
        width: panelFlick.width
        spacing: Style.space(10)

        // Hero
        Row {
          width: parent.width
          spacing: Style.space(8)

          Text {
            text: "\ue907"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.display
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            spacing: Style.space(1)

            Text {
              text: "Hermes Agent"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.weight: Font.DemiBold
            }

            Text {
              text: root.usage && root.usage.model ? String(root.usage.model) : "no data yet"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }

          Item { width: 1; height: 1 }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.collecting ? "…" : ""
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }

        // Ollama Cloud credits
        Repeater {
            model: root.ollamaUsage && root.ollamaUsage.used !== undefined ? [root.ollamaUsage] : []

            Column {
                required property var modelData
                width: parent.width
                spacing: Style.space(6)

                Rectangle {
                    width: parent.width
                    height: 1
                    color: root.dim
                    opacity: 0.3
                }

                Row {
                    width: parent.width
                    spacing: Style.space(8)

                    Text {
                        text: "Ollama Cloud"
                        color: root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.weight: Font.DemiBold
                    }

                    Item { width: 1; height: 1 }

                    Text {
                        id: creditsValue
                        text: "$" + (Number(modelData.used) || 0).toFixed(2) + " · " + Math.round(Number(modelData.pct) || 0) + "%"
                        color: {
                            var pct = Number(modelData.pct) || 0
                            if (pct >= 90) return Color.urgent
                            if (pct >= 70) return Qt.rgba(Color.urgent.r, Color.urgent.g, Color.urgent.b, 0.75)
                            return root.foreground
                        }
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.weight: Font.DemiBold
                    }
                }

                Rectangle {
                    width: parent.width
                    height: Style.space(8)
                    radius: height / 2
                    color: root.dim
                    opacity: 0.15

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * Math.min(1.0, (Number(modelData.pct) || 0) / 100)
                        height: parent.height
                        radius: height / 2
                        color: (Number(modelData.pct) || 0) >= 70 ? Color.urgent : Color.accent
                    }
                }

                Text {
                    width: parent.width
                    text: {
                        var models = modelData.models || []
                        if (!models.length) return "—"
                        var parts = []
                        for (var i = 0; i < models.length; i++)
                            parts.push(models[i].model + " " + models[i].requests)
                        return parts.join(" · ")
                    }
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: "left $" + (Number(modelData.remaining) || 0).toFixed(2) + " · resets " + (modelData.resets_at ? String(modelData.resets_at).slice(0, 10) : "—")
                    color: root.dim
                    opacity: 0.8
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                }
            }
        }

        // Separator
        Rectangle {
          width: parent.width
          height: 1
          color: root.dim
          opacity: 0.3
        }

        // Today
        Row {
          width: parent.width
          spacing: Style.space(8)

          Text {
            width: parent.width - todayTokensLabel.width
            text: "Today"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }

          Text {
            id: todayTokensLabel
            text: root.fmtTokens(root.usage ? root.usage.todayTokens : 0)
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.weight: Font.DemiBold
          }
        }

        Text {
          width: parent.width
          text: root.usage && root.usage.todayPrompts !== undefined
                ? root.usage.todayPrompts + " prompts · " + root.usage.todaySessions + " sessions"
                : "—"
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        // Separator
        Rectangle {
          width: parent.width
          height: 1
          color: root.dim
          opacity: 0.3
        }

        // Last 7 days
        Text {
          text: "Last 7 days"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.weight: Font.DemiBold
        }

        Repeater {
          model: root.usage && root.usage.week ? root.usage.week : []

          Row {
            required property var modelData
            width: parent.width
            spacing: Style.space(8)

            Text {
              width: 34
              text: modelData.label
              color: modelData.isToday ? root.foreground : root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.weight: modelData.isToday ? Font.DemiBold : Font.Normal
            }

            Rectangle {
              id: barTrack
              width: parent.width - 34 - 64 - 2 * parent.spacing
              height: Style.space(10)
              anchors.verticalCenter: parent.verticalCenter
              radius: height / 2
              color: root.dim
              opacity: 0.15

              Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: root.maxWeek > 0
                       ? Math.max(modelData.tokens > 0 ? 2 : 0, parent.width * modelData.tokens / root.maxWeek)
                       : 0
                height: parent.height
                radius: height / 2
                color: Color.accent
              }
            }

            Text {
              width: 64
              text: root.fmtTokens(modelData.tokens)
              horizontalAlignment: Text.AlignRight
              color: modelData.isToday ? root.foreground : root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.weight: modelData.isToday ? Font.DemiBold : Font.Normal
            }
          }
        }

        // Separator
        Rectangle {
          width: parent.width
          height: 1
          color: root.dim
          opacity: 0.3
        }

        // By model (all-time)
        Text {
          text: "Tokens by model"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.weight: Font.DemiBold
        }

        Repeater {
          model: root.usage && root.usage.models ? root.usage.models : []

          Row {
            required property var modelData
            width: parent.width
            spacing: Style.space(8)

            Text {
              width: parent.width - 64 - parent.spacing
              text: modelData.name
              elide: Text.ElideRight
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }

            Text {
              width: 64
              text: root.fmtTokens(modelData.tokens)
              horizontalAlignment: Text.AlignRight
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }
        }

        // Footer
        Text {
          width: parent.width
          text: "R refresh · Esc close · right-click icon launches Hermes"
          color: root.dim
          opacity: 0.7
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }

  // ----------------------------------------------------------------- helpers
  readonly property real maxWeek: {
    var m = 0
    var week = usage && usage.week ? usage.week : []
    for (var i = 0; i < week.length; i++) m = Math.max(m, Number(week[i].tokens) || 0)
    return m
  }

  function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }

  function fmtTokens(n) {
    var v = Number(n) || 0
    if (v >= 1000000) return (v / 1000000).toFixed(1) + "M"
    if (v >= 1000) return (v / 1000).toFixed(1) + "k"
    return String(v)
  }

  readonly property color dim: Qt.darker(foreground, 1.55)
}