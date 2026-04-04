import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entries: [SimpleEntry] = [SimpleEntry(date: Date())]
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct TodayWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Image("logo")
                .resizable()
                .frame(width: 40, height: 40)
            Text("ALERIX")
                .font(.headline)
                .foregroundColor(.red)
            Link(destination: URL(string: "alerix://sos")!) {
                Text("SOS")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

@main
struct TodayWidget: Widget {
    let kind: String = "TodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("ALERIX SOS")
        .description("Botón de emergencia rápido")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}