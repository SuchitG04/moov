//
//  StatsView.swift
//  Moov
//
//  Statistics dashboard (placeholder for MVP)
//

import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var sessions: [BreakSession]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Statistics")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()

            if sessions.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)

                    Text("No data yet")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Take some breaks to see your statistics here")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Stats
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Today's summary
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Today")
                                .font(.headline)

                            HStack(spacing: 40) {
                                StatCard(
                                    title: "Breaks Taken",
                                    value: "\(todaysTakenCount)",
                                    icon: "checkmark.circle.fill",
                                    color: .green
                                )

                                StatCard(
                                    title: "Snoozed",
                                    value: "\(todaysSnoozedCount)",
                                    icon: "clock.fill",
                                    color: .orange
                                )

                                StatCard(
                                    title: "Total",
                                    value: "\(todaysTotalCount)",
                                    icon: "list.bullet",
                                    color: .blue
                                )
                            }
                        }

                        Divider()

                        // All time
                        VStack(alignment: .leading, spacing: 12) {
                            Text("All Time")
                                .font(.headline)

                            HStack(spacing: 40) {
                                StatCard(
                                    title: "Total Breaks",
                                    value: "\(sessions.count)",
                                    icon: "chart.bar.fill",
                                    color: .purple
                                )

                                StatCard(
                                    title: "Compliance",
                                    value: "\(complianceRate)%",
                                    icon: "star.fill",
                                    color: .yellow
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(width: 600, height: 500)
    }

    // MARK: - Computed Properties

    private var todaysTakenCount: Int {
        todaysSessions.filter { $0.wasTaken }.count
    }

    private var todaysSnoozedCount: Int {
        todaysSessions.filter { $0.wasSnoozed }.count
    }

    private var todaysTotalCount: Int {
        todaysSessions.count
    }

    private var todaysSessions: [BreakSession] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return sessions.filter { session in
            calendar.isDate(session.timestamp, inSameDayAs: today)
        }
    }

    private var complianceRate: Int {
        guard !sessions.isEmpty else { return 0 }
        let takenCount = sessions.filter { $0.wasTaken }.count
        return Int((Double(takenCount) / Double(sessions.count)) * 100)
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .frame(minWidth: 140)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

#Preview {
    StatsView()
        .modelContainer(for: BreakSession.self, inMemory: true)
}
