import Charts
import SwiftUI

struct ContentView: View {
    var input: [Int] {
        var array = [Int]()
        for i in 1...30 {
            array.append(i)
        }
        
        return array.shuffled()
    }
    
    @State var data = [Int]()
    @State var activeValue = 0
    @State var previousValue = 0
    @State var checkValue: Int?
    
    var body: some View {
        VStack {
            Chart {
                ForEach(Array(zip(data.indices, data)), id: \.0) { index, item in
                    BarMark(x: .value("Position", index), y: .value("Value", item))
                        .foregroundStyle(getColor(value: item).gradient)
                }
            }
            .frame(width: 280, height: 250)
            
            Button {
                Task {
                    try await quicksort(&data, low: 0, high: data.count - 1)
                    
                    activeValue = 0
                    previousValue = 0
                    
                    for index in 0..<data.count {
                        beep(data[index])
                        checkValue = data[index]
                        try await Task.sleep(until: .now.advanced(by: .milliseconds(20)), clock: .continuous)
                    }
                }
            } label: {
                Text("Sort it!")
            }
        }
        .onAppear {
            data = input
        }
    }
    
    @MainActor
    func quicksort(_ array: inout [Int], low: Int, high: Int) async throws {
        if low < high {
            let pivot = try await pivot(&array, low: low, high: high)
            try await quicksort(&array, low: low, high: pivot - 1)
            try await quicksort(&array, low: pivot + 1, high: high)
        }
    }
    
    @MainActor
    func pivot(_ array: inout [Int], low: Int, high: Int) async throws -> Int {
        let pivot = array[high]
        
        var i = low
        for j in low..<high {
            if array[j] <= pivot {
                activeValue = array[i]
                previousValue = array[j]
                beep(data[i])
                try await Task.sleep(until: .now.advanced(by: .milliseconds(20)), clock: .continuous)
                data.swapAt(i, j)
                array.swapAt(i, j)
                i += 1
            }
            activeValue = 0
            previousValue = 0
        }
        activeValue = array[i]
        previousValue = array[high]
        beep(data[i])
        try await Task.sleep(until: .now.advanced(by: .milliseconds(20)), clock: .continuous)
        
        data.swapAt(i, high)
        array.swapAt(i, high)
        
        return i
    }
    
    @MainActor
    func selectionSort() async throws {
        guard data.count > 1 else {
            return
        }

        for i in 0..<data.count - 1 {
            var smallest = i
            previousValue = data[i]
            
            for j in i + 1..<data.count {
                if data[smallest] > data[j] {
                    activeValue = data[j]
                    beep(data[j])
                    smallest = j
                    try await Task.sleep(until: .now.advanced(by: .milliseconds(20)), clock: .continuous)
                }
            }

            if smallest != i {
                activeValue = data[i]
                previousValue = data[smallest]
                beep(data[smallest])
                data.swapAt(smallest, i)
                try await Task.sleep(until: .now.advanced(by: .milliseconds(20)), clock: .continuous)
            }
        }
    }
    
    @MainActor
    func insertionSort() async throws {
        guard data.count >= 2 else {
            return
        }

        for i in 1..<data.count {
            for j in (1...i).reversed() {
                if data[j] < data[j - 1] {
                    activeValue = data[j - 1]
                    previousValue = data[j]
                    beep(data[j - 1])
                    data.swapAt(j, j - 1)
                    try await Task.sleep(until: .now.advanced(by: .milliseconds(20)), clock: .continuous)
                } else {
                    break
                }
            }
        }
    }
    
    @MainActor
    func bubbleSort() async throws {
        guard data.count >= 2 else {
            return
        }

        for i in 0..<data.count {
            for j in 0..<data.count - i - 1 {
                activeValue = data[j + 1]
                previousValue = data[j]

                if data[j] > data[j + 1] {
                    beep(data[j + 1])
                    data.swapAt(j + 1, j)
                    try await Task.sleep(until: .now.advanced(by: .milliseconds(20)), clock: .continuous)
                }
            }
        }
    }
    
    func getColor(value: Int) -> Color {
        if let checkValue, value <= checkValue {
            return .green
        }
        
        if value == activeValue {
            return .green
        } else if value == previousValue {
            return .yellow
        }
        
        return .blue
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
