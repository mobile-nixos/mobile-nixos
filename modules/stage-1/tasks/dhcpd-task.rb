class Tasks::DHCPD < SingletonTask
  INTERFACES = ["rndis0", "usb0", "eth0"]

  def initialize()
    interfaces = INTERFACES.map do |name|
      Dependencies::NetworkInterface.new(name)
    end
    add_dependency(:Any, *interfaces)
    Targets[:Networking].add_dependency(:Task, self)
  end

  def run()
    @ip = Configuration["boot"]["networking"]["IP"]
    @hostIP = Configuration["boot"]["networking"]["hostIP"]

    # Pick the first interface available.
    @interface = INTERFACES.find do |name|
      File.exist?(File.join("/sys/class/net", name))
    end

    log("Setting-up networking for #{@interface}")
    System.run("ifconfig", @interface, @ip)

    # Config file for udhcpd
    File.write("/etc/udhcpd.conf", [
      "start #{@hostIP}",
      "end #{@hostIP}",
      "auto_time 0",
      "decline_time 0",
      "conflict_time 0",
      "lease_file /var/udhcpd.leases",
      "interface #{@interface}",
      "option subnet 255.255.255.0",
    ].join("\n"))

    System.spawn("udhcpd")
  end
end
