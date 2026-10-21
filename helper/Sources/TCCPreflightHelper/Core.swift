// Platform-independent core (typechecks on Linux).
public enum Perm: String, CaseIterable {
  case camera, microphone, screen, accessibility, automation, input, fulldisk
}
public enum Verb: String { case check, request }
public enum Status: String { case granted, missing, denied, unknown }

public func parseArgs(_ args: [String]) -> (Verb, Perm)? {
  guard args.count == 2, let v = Verb(rawValue: args[0]), let p = Perm(rawValue: args[1]) else { return nil }
  return (v, p)
}
