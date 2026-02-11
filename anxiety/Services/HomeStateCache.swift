//
//  HomeStateCache.swift
//  anxiety
//
//  Smart caching for home view state to prevent flickering on tab switches
//

import Foundation
import SwiftUI

@MainActor
class HomeStateCache: ObservableObject {
    static let shared = HomeStateCache()

    // Cached state (in-memory only for current session)
    @Published private(set) var cachedEnergyState: EnergyState?
    @Published private(set) var cachedRhythmData: [Double]?
    @Published private(set) var cachedReflectionCount: Int?

    // Track if data has been loaded this session
    @Published private(set) var hasLoadedThisSession: Bool = false

    private init() {}

    // MARK: - Cache Validity

    var shouldRefresh: Bool {
        // Only refresh if we haven't loaded yet this session
        !hasLoadedThisSession
    }

    // MARK: - Update Cache

    func updateEnergyState(_ state: EnergyState) {
        cachedEnergyState = state
        hasLoadedThisSession = true
    }

    func updateRhythmData(_ data: [Double]) {
        cachedRhythmData = data
    }

    func updateReflectionCount(_ count: Int) {
        cachedReflectionCount = count
    }

    // MARK: - Force Refresh (for new entries/evaluations)

    func markNeedsRefresh() {
        hasLoadedThisSession = false
    }

    // MARK: - Clear (for user changes)

    func clearCache() {
        cachedEnergyState = nil
        cachedRhythmData = nil
        cachedReflectionCount = nil
        hasLoadedThisSession = false
    }
}
