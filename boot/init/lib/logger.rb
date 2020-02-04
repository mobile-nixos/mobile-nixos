LOG_LEVEL = Logger::INFO
if Configuration["log"]
  level = Configuration["log"]["level"]
  if level
    LOG_LEVEL = Logger.const_get(level.to_sym)
  end
end
$logger = Logger.new(STDOUT, level: LOG_LEVEL)
$logger.debug("Logger initialized... (#{LOG_LEVEL})")

def log(*args, level: :info)
  $logger.send(level, *args)
end
