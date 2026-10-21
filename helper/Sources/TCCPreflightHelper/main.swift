import Foundation
#if os(macOS)
import AVFoundation
import ApplicationServices
import CoreGraphics
import IOKit.hid
import AppKit

func settings(_ anchor: String) {
  if let u = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") { NSWorkspace.shared.open(u) }
}

func avStatus(_ t: AVMediaType) -> Status {
  switch AVCaptureDevice.authorizationStatus(for: t) {
  case .authorized: return .granted
  case .denied, .restricted: return .denied
  default: return .missing
  }
}
func avRequest(_ t: AVMediaType) -> Status {
  let s = avStatus(t); if s != .missing { return s }
  let sem = DispatchSemaphore(value: 0); var ok = false
  AVCaptureDevice.requestAccess(for: t) { ok = $0; sem.signal() }
  _ = sem.wait(timeout: .now() + 120)
  return ok ? .granted : .denied
}

// Automation: AEDeterminePermissionToAutomateTarget against System Events.
func automation(prompt: Bool) -> Status {
  let bid = "com.apple.systemevents"
  if NSRunningApplication.runningApplications(withBundleIdentifier: bid).isEmpty {
    if !prompt { return .unknown }  // --check never launches apps
    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid) {
      let sem = DispatchSemaphore(value: 0)
      NSWorkspace.shared.openApplication(at: url, configuration: .init()) { _, _ in sem.signal() }
      _ = sem.wait(timeout: .now() + 10)
    }
  }
  var desc = AEAddressDesc()
  let data = Array(bid.utf8)
  guard AECreateDesc(DescType(typeApplicationBundleID), data, data.count, &desc) == noErr else { return .unknown }
  defer { AEDisposeDesc(&desc) }
  let err = AEDeterminePermissionToAutomateTarget(&desc, AEEventClass(typeWildCard), AEEventID(typeWildCard), prompt)
  switch Int(err) {
  case Int(noErr): return .granted
  case Int(errAEEventNotPermitted): return .denied
  case -1744 /* errAEEventWouldRequireUserConsent */: return .missing
  case Int(procNotFound): return .unknown
  default: return .unknown
  }
}

func hid(_ prompt: Bool) -> Status {
  if prompt { return IOHIDRequestAccess(kIOHIDRequestTypeListenEvent) ? .granted : .missing }
  switch IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) {
  case kIOHIDAccessTypeGranted: return .granted
  case kIOHIDAccessTypeDenied: return .denied
  default: return .missing
  }
}

// Full Disk Access has no API: probe a TCC-protected path read-only (never opens the TCC database).
func fullDisk(_ prompt: Bool) -> Status {
  let home = FileManager.default.homeDirectoryForCurrentUser.path
  let probes = ["\(home)/Library/Safari/Bookmarks.plist", "\(home)/Library/Mail", "\(home)/Library/Messages"]
  for p in probes where FileManager.default.fileExists(atPath: p) {
    if (try? FileManager.default.contentsOfDirectory(atPath: p)) != nil || FileManager.default.isReadableFile(atPath: p) && FileHandle(forReadingAtPath: p) != nil {
      return .granted
    }
    if prompt { settings("Privacy_AllFiles") }
    return .missing
  }
  if prompt { settings("Privacy_AllFiles") }
  return .unknown
}

func run(_ v: Verb, _ p: Perm) -> Status {
  let prompt = v == .request
  switch p {
  case .camera: return prompt ? avRequest(.video) : avStatus(.video)
  case .microphone: return prompt ? avRequest(.audio) : avStatus(.audio)
  case .screen:
    if CGPreflightScreenCaptureAccess() { return .granted }
    if prompt { _ = CGRequestScreenCaptureAccess(); settings("Privacy_ScreenCapture") }
    return CGPreflightScreenCaptureAccess() ? .granted : .missing
  case .accessibility:
    let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
    return AXIsProcessTrustedWithOptions(opts) ? .granted : .missing
  case .automation: return automation(prompt: prompt)
  case .input: return hid(prompt)
  case .fulldisk: return fullDisk(prompt)
  }
}
#endif

let argv = Array(CommandLine.arguments.dropFirst())
guard let (verb, perm) = parseArgs(argv) else {
  FileHandle.standardError.write("usage: tcc-preflight-helper <check|request> <\(Perm.allCases.map(\.rawValue).joined(separator: "|"))>\n".data(using: .utf8)!)
  exit(2)
}
#if os(macOS)
print(run(verb, perm).rawValue)
#else
print(Status.unknown.rawValue)  // non-macOS build: typecheck only
#endif
