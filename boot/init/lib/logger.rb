class TimeOffsetLogger < Logger::Formatter
  # Time at which the program was started.
  # Ideally we'd prefer kernel uptime, but it seems we're slightly off with it
  # when running the app and getting it through clock_gettime
  #
  # D, [2020-10-22T02:47:21.591014//1.0889 #1] DEBUG -- : Tasks::Proc created...                                                                         
  # [    1.179064] random: fast init done                                                                                                                
  # D, [2020-10-22T02:47:21.591048//1.0889 #1] DEBUG -- : Tasks::Splash created...                                                                       
  #
  # So rather than having *weird* time comparatively to the kernel, we're
  # doing our own time-keeping.
  OFFSET = Time.now

  private

  # Formats using the parent's format, with the offset since boot.
  def format_datetime(t)
    "#{super(t)}//#{"%.4f" % (t-OFFSET)}"
  end
end

LOG_LEVEL =
  if Configuration["log"]
    level = Configuration["log"]["level"]
    if level
      LOG_LEVEL = Logger.const_get(level.to_sym)
    end
  else
    Logger::INFO
  end

$logger = Logger.new(STDOUT, level: LOG_LEVEL, formatter: TimeOffsetLogger.new)
$logger.debug("Logger initialized... (#{LOG_LEVEL})")

def log(*args, level: :info)
  $logger.send(level, *args)
end
