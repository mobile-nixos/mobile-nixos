$logger = Logger.new(STDOUT, level: Logger::INFO)

def log(*args, level: :info)
  $logger.send(level, *args)
end
