class DiscoveredServer {
  final String ip;
  final int port;
  final String hostname;
  final bool running;

  DiscoveredServer({
    required this.ip,
    required this.port,
    required this.hostname,
    required this.running,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredServer &&
          runtimeType == other.runtimeType &&
          ip == other.ip &&
          port == other.port;

  @override
  int get hashCode => ip.hashCode ^ port.hashCode;
}
