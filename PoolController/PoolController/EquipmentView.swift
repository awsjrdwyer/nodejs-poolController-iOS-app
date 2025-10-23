import SwiftUI

struct EquipmentView: View {
    @EnvironmentObject var poolService: PoolService
    @State private var selectedSegment = 0
    
    private let segments = ["Circuits", "Pumps", "Heaters", "Schedules"]
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Equipment Type", selection: $selectedSegment) {
                    ForEach(0..<segments.count, id: \.self) { index in
                        Text(segments[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                ScrollView {
                    switch selectedSegment {
                    case 0:
                        CircuitsListView()
                    case 1:
                        PumpsListView()
                    case 2:
                        HeatersListView()
                    case 3:
                        SchedulesListView()
                    default:
                        EmptyView()
                    }
                }
            }
            .navigationTitle("Equipment")
        }
    }
}

// MARK: - Circuits List
struct CircuitsListView: View {
    @EnvironmentObject var poolService: PoolService
    
    var body: some View {
        LazyVStack(spacing: 12) {
            if let circuits = poolService.poolState?.circuits {
                let visibleCircuits = circuits.filter { $0.showInFeatures ?? true }
                
                if visibleCircuits.isEmpty {
                    Text("No circuits available")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(visibleCircuits) { circuit in
                        CircuitDetailCard(circuit: circuit)
                    }
                }
            } else {
                Text("No circuits available")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
    }
}

struct CircuitDetailCard: View {
    let circuit: Circuit
    @EnvironmentObject var poolService: PoolService
    @State private var isToggling = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(circuit.name ?? "Unknown")
                    .font(.headline)
                
                Text("Type: " + (circuit.type?.desc ?? circuit.type?.name ?? "Unknown"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                guard !isToggling else { return }
                isToggling = true
                Task {
                    await poolService.toggleCircuit(circuit.id)
                    isToggling = false
                }
            } label: {
                HStack {
                    if isToggling {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Circle()
                            .fill((circuit.isOn ?? false) ? Color.green : Color.gray)
                            .frame(width: 20, height: 20)
                        
                        Text((circuit.isOn ?? false) ? "ON" : "OFF")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor((circuit.isOn ?? false) ? .green : .secondary)
                    }
                }
            }
            .disabled(isToggling)
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Pumps List
struct PumpsListView: View {
    @EnvironmentObject var poolService: PoolService
    
    var body: some View {
        LazyVStack(spacing: 12) {
            if let pumps = poolService.poolState?.pumps {
                ForEach(pumps) { pump in
                    PumpDetailCard(pump: pump)
                }
            } else {
                Text("No pumps available")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
    }
}

struct PumpDetailCard: View {
    let pump: Pump
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(pump.name ?? "Unknown")
                        .font(.headline)
                    
                    Text("Type: " + (pump.type?.desc ?? pump.type?.name ?? "Unknown"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(pump.status?.desc ?? pump.status?.name ?? "Off")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background((pump.status?.name == "off" || pump.status?.name == nil) ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            HStack {
                if let rpm = pump.rpm {
                    VStack {
                        Text("RPM")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(String(rpm))
                            .font(.headline)
                    }
                }
                
                if let flow = pump.flow {
                    VStack {
                        Text("GPM")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(String(flow))
                            .font(.headline)
                    }
                }
                
                if let watts = pump.watts {
                    VStack {
                        Text("Watts")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(String(watts))
                            .font(.headline)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Heaters List
struct HeatersListView: View {
    @EnvironmentObject var poolService: PoolService
    
    var body: some View {
        LazyVStack(spacing: 12) {
            if let bodies = poolService.poolState?.temps?.bodies ?? poolService.poolState?.bodies {
                ForEach(bodies) { body in
                    HeaterDetailCard(poolBody: body)
                }
            } else {
                Text("No heaters available")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
    }
}

struct HeaterDetailCard: View {
    let poolBody: Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text((poolBody.name ?? "Unknown") + " Heater")
                        .font(.headline)
                    
                    Text("Mode: " + (poolBody.heatMode?.desc ?? poolBody.heatMode?.name ?? "Unknown"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(poolBody.heatStatus?.desc ?? poolBody.heatStatus?.name ?? "Off")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background((poolBody.heatStatus?.name == "off" || poolBody.heatStatus?.name == nil) ? Color.gray : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Current: " + (poolBody.temp?.formatTemperature() ?? "--°F"))
                        .font(.caption)
                    
                    if let setPoint = poolBody.setPoint {
                        Text("Target: " + setPoint.formatTemperature())
                            .font(.caption)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Schedules List
struct SchedulesListView: View {
    @EnvironmentObject var poolService: PoolService
    
    var body: some View {
        LazyVStack(spacing: 12) {
            if let schedules = poolService.poolState?.schedules {
                if schedules.isEmpty {
                    VStack {
                        Text("No schedules configured")
                            .foregroundColor(.secondary)
                            .padding()
                        
                        Text("Pool state exists: " + String(poolService.poolState != nil))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // Show all schedules, including disabled ones (like the web dashboard)
                    ForEach(schedules) { schedule in
                        ScheduleDetailCard(schedule: schedule)
                    }
                }
            } else {
                Text("Loading schedules...")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .onAppear {
            print("📅 SchedulesListView appeared")
            print("📅 Pool service connected: " + String(poolService.isConnected))
            print("📅 Pool state exists: " + String(poolService.poolState != nil))
            
            // Debug: Print detailed schedule information
            if let schedules = poolService.poolState?.schedules {
                print("📅 Schedules found in UI: " + String(schedules.count))
                if schedules.isEmpty {
                    print("📅 Schedules array is empty")
                } else {
                    for schedule in schedules {
                        print("   - Schedule " + String(schedule.id) + ": " + (schedule.name ?? "Unknown"))
                        print("     * Active: " + String(schedule.isActive ?? false))
                        print("     * Disabled: " + String(schedule.disabled ?? false))
                        print("     * Circuit ID: " + String(schedule.circuitId ?? 0))
                    print("     * Circuit Name: " + (schedule.circuitName ?? "None"))
                        print("     * Type: " + (schedule.scheduleTypeName ?? "Unknown"))
                        print("     * Time: " + schedule.startTimeFormatted + " - " + schedule.endTimeFormatted)
                        print("     * Days: " + schedule.scheduleDaysFormatted)
                    }
                }
            } else {
                print("📅 No schedules in pool state when UI appeared")
            }
        }
    }
}

struct ScheduleDetailCard: View {
    let schedule: Schedule
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(schedule.circuitName ?? schedule.name ?? ("Schedule " + String(schedule.id)))
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    // Show disabled status if applicable
                    if schedule.disabled == true {
                        Text("Disabled")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    } else {
                        Text((schedule.isActive ?? false) ? "Active" : "Inactive")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background((schedule.isActive ?? false) ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            
            HStack {
                Text("Time: " + schedule.startTimeFormatted + " - " + schedule.endTimeFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Type: " + (schedule.scheduleTypeName ?? "Unknown"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Days: " + schedule.scheduleDaysFormatted)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if schedule.changeHeatSetpoint == true {
                Text("Heat Setpoint: " + String(schedule.heatSetpoint ?? 0) + "°F")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .opacity((schedule.disabled == true) ? 0.6 : 1.0)
    }
}

#Preview {
    EquipmentView()
        .environmentObject(PoolService())
}