# FIXME: Allow overriding $logger.level = Logger::DEBUG at build-time
#LOG_LEVEL = Logger::INFO
LOG_LEVEL = Logger::DEBUG
$logger = Logger.new(STDOUT, level: LOG_LEVEL)
$logger.debug("Logger initialized... (#{LOG_LEVEL})")

def log(*args, level: :info)
  $logger.send(level, *args)
end
