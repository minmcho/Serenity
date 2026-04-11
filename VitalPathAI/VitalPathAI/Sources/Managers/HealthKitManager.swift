//
//  HealthKitManager.swift
//  VitalPathAI
//
//  Apple HealthKit Integration for Wearable Data
//  Handles step count, heart rate, and activity rings
//

import Foundation
import HealthKit

@Observable
final class HealthKitManager {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    var isAuthorized = false
    var dailySteps = 0
    var averageHeartRate: Double?
    var activeCalories = 0.0
    var standingHours = 0
    
    enum HealthKitError: Error {
        case notAvailable
        case authorizationDenied
        case dataNotAvailable
    }
    
    /// Check if HealthKit is available on this device
    var isHealthKitAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    /// Request authorization for required health data types
    func requestAuthorization() async throws -> Bool {
        guard isHealthKitAvailable else {
            throw HealthKitError.notAvailable
        }
        
        // Define health data types to read
        let stepsToRead = Set([HKQuantityType.quantityType(forIdentifier: .stepCount)!])
        let heartRateToRead = Set([HKQuantityType.quantityType(forIdentifier: .heartRate)!])
        let caloriesToRead = Set([HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!])
        let standingToRead = Set([HKQuantityType.quantityType(forIdentifier: .standingHour)!])
        
        let typesToRead = stepsToRead.union(heartRateToRead).union(caloriesToRead).union(standingToRead)
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            isAuthorized = true
            
            // Start observing health data changes
            setupObservers()
            
            return true
        } catch {
            print("HealthKit authorization failed: \(error)")
            isAuthorized = false
            throw error
        }
    }
    
    /// Setup observers for health data changes
    private func setupObservers() {
        // Observe step count changes
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            healthStore.observe(query: HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, _ in
                Task { @MainActor in
                    await self?.fetchTodaySteps()
                }
            })
        }
        
        // Observe heart rate changes
        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            healthStore.observe(query: HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] _, _, _ in
                Task { @MainActor in
                    await self?.fetchAverageHeartRate()
                }
            })
        }
    }
    
    /// Fetch today's step count
    func fetchTodaySteps() async {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            Task { @MainActor in
                let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                self.dailySteps = Int(steps)
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Fetch average heart rate for today
    func fetchAverageHeartRate() async {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
            Task { @MainActor in
                let avgHeartRate = result?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                self.averageHeartRate = avgHeartRate
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Fetch active calories burned today
    func fetchActiveCalories() async {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            Task { @MainActor in
                let calories = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                self.activeCalories = calories
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Fetch standing hours today
    func fetchStandingHours() async {
        guard let standingType = HKQuantityType.quantityType(forIdentifier: .standingHour) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: standingType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            Task { @MainActor in
                let hours = result?.sumQuantity()?.doubleValue(for: HKUnit.hour()) ?? 0
                self.standingHours = Int(hours)
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Fetch all health metrics at once
    func fetchAllMetrics() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchTodaySteps() }
            group.addTask { await self.fetchAverageHeartRate() }
            group.addTask { await self.fetchActiveCalories() }
            group.addTask { await self.fetchStandingHours() }
        }
    }
    
    /// Sync health data to backend (optional)
    func syncToBackend(userId: String) async {
        // TODO: Implement secure sync to Supabase
        // Ensure PHI is encrypted before transmission
        print("Syncing health data for user: \(userId)")
    }
}
