//
//  SudoboysWidgetsLiveActivity.swift
//  SudoboysWidgets
//
//  Created by Anahi Carbajal Montiel on 25/11/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SudoboysWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SudoboysWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SudoboysWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension SudoboysWidgetsAttributes {
    fileprivate static var preview: SudoboysWidgetsAttributes {
        SudoboysWidgetsAttributes(name: "World")
    }
}

extension SudoboysWidgetsAttributes.ContentState {
    fileprivate static var smiley: SudoboysWidgetsAttributes.ContentState {
        SudoboysWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SudoboysWidgetsAttributes.ContentState {
         SudoboysWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: SudoboysWidgetsAttributes.preview) {
   SudoboysWidgetsLiveActivity()
} contentStates: {
    SudoboysWidgetsAttributes.ContentState.smiley
    SudoboysWidgetsAttributes.ContentState.starEyes
}
