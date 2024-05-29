import Foundation

// Output for n = 30

// Using memoization
// Execution time: 0.07 seconds
// Maximum memory usage: 0.00 MB
//

// Not using memoization
// Execution time: 108.40 seconds
// Maximum memory usage: 1075.52 MB


// Function to get current memory usage
func reportMemory() -> UInt64 {
	var info = mach_task_basic_info()
	var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
	
	let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
		$0.withMemoryRebound(to: integer_t.self, capacity: 1) {
			task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
		}
	}
	
	if kerr == KERN_SUCCESS {
		return info.resident_size
	} else {
		print("Error with task_info(): " +
			  (String(cString: mach_error_string(kerr), encoding: .ascii) ?? "unknown error"))
		return 0
	}
}

// Function to track maximum memory usage
func measureMaxMemoryUsage(operation: () -> Void) -> UInt64 {
	var maxMemoryUsage: UInt64 = 0
	let interval: TimeInterval = 0.01 // Memory check interval in seconds
	let queue = DispatchQueue(label: "MemoryMonitorQueue")
	let group = DispatchGroup()
	
	// Start background task for memory monitoring
	group.enter()
	queue.async {
		while group.wait(timeout: .now() + interval) == .timedOut {
			let currentMemoryUsage = reportMemory()
			if currentMemoryUsage > maxMemoryUsage {
				maxMemoryUsage = currentMemoryUsage
			}
		}
	}
	
	// Execute the operation
	operation()
	
	// Finish memory monitoring
	group.leave()
	group.wait()
	
	return maxMemoryUsage
}


//  Switch function
// -----------------------------

// Function without memoization

//func fibonacci(_ n: Int) -> Int {
//	if n <= 1 {
//		return n
//	}
//	return fibonacci(n - 1) + fibonacci(n - 2)
//}


// Function with memoization

var memo: [Int: Int] = [:]

func fibonacci(_ n: Int) -> Int {
	if let result = memo[n] {
		return result
	}
	if n <= 1 {
		return n
	}
	let result = fibonacci(n - 1) + fibonacci(n - 2)
	memo[n] = result
	return result
}

// -----------------------------



// Measure time before the operation
let startTime = Date()

// Measure maximum memory usage during the operation
let maxMemoryUsed = measureMaxMemoryUsage {
	fibonacci(30)
}

// Measure time after the operation
let endTime = Date()

// Calculate the time interval
let timeInterval = endTime.timeIntervalSince(startTime)


// Print results in a readable format
print(String(format: "Execution time: %.2f seconds", timeInterval))
print(String(format: "Maximum memory usage: %.2f MB", Double(maxMemoryUsed) / 1024.0 / 1024.0))


