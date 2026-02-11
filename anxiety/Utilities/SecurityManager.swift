import Foundation
import UIKit
import MachO

class SecurityManager {
    static let shared = SecurityManager()
    
    private init() {}
    
    var isJailbroken: Bool {
        return checkJailbreak()
    }
    
    var isRunningInSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    var isDebuggerAttached: Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        
        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        
        if result != 0 {
            return false
        }
        
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
    
    private func checkJailbreak() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        
        if isDebuggerAttached {
            secureLog("Debugger detected", level: .warning)
        }
        
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/private/var/tmp/cydia.log",
            "/private/var/stash",
            "/usr/libexec/sftp-server",
            "/usr/bin/sshd",
            "/usr/libexec/ssh-keysign",
            "/bin/sh",
            "/etc/ssh/sshd_config",
            "/Applications/FakeCarrier.app",
            "/Applications/Icy.app",
            "/Applications/IntelliScreen.app",
            "/Applications/MxTube.app",
            "/Applications/RockApp.app",
            "/Applications/SBSettings.app",
            "/Applications/WinterBoard.app",
            "/Applications/blackra1n.app",
            "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
            "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
            "/var/cache/apt",
            "/var/lib/apt",
            "/var/lib/cydia"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                #if DEBUG
                secureLog("Jailbreak detected: \(path) exists", level: .warning)
                #endif
                return true
            }
        }
        
        if canEditSystemFiles() {
            #if DEBUG
            secureLog("Jailbreak detected: Can write to system files", level: .warning)
            #endif
            return true
        }
        
        if canOpenCydia() {
            #if DEBUG
            secureLog("Jailbreak detected: Can open Cydia URL", level: .warning)
            #endif
            return true
        }
        
        if hasSuspiciousDylibs() {
            #if DEBUG
            secureLog("Jailbreak detected: Suspicious dylibs loaded", level: .warning)
            #endif
            return true
        }
        
        return false
        #endif
    }
    
    private func canEditSystemFiles() -> Bool {
        let testPath = "/private/jailbreak_test.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
    }
    
    private func canOpenCydia() -> Bool {
        if let url = URL(string: "cydia://package/com.example.package") {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
    }
    
    private func hasSuspiciousDylibs() -> Bool {
        let suspiciousLibraries = [
            "MobileSubstrate",
            "SubstrateLoader",
            "SSLKillSwitch",
            "Flex"
        ]
        
        for i in 0..<_dyld_image_count() {
            if let imageName = _dyld_get_image_name(i) {
                let name = String(cString: imageName)
                for lib in suspiciousLibraries {
                    if name.contains(lib) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    func performSecurityChecks() -> SecurityCheckResult {
        var warnings: [String] = []
        var isSecure = true
        
        if isJailbroken {
            warnings.append("Device appears to be jailbroken")
            isSecure = false
        }
        
        if isDebuggerAttached && !isRunningInSimulator {
            warnings.append("Debugger is attached")
        }
        
        return SecurityCheckResult(isSecure: isSecure, warnings: warnings)
    }
    
    func shouldAllowPremiumFeatures() -> Bool {
        #if DEBUG
        return true
        #else
        return !isJailbroken
        #endif
    }
}

struct SecurityCheckResult {
    let isSecure: Bool
    let warnings: [String]
}
