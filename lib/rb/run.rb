require "shellwords"

def run(*cmd, exec: false)
	puts " $ #{cmd.shelljoin}"

	if exec then
		Kernel.exec(*cmd)
	else
		system(*cmd)
	end
	exit $?.exitstatus unless $?.exitstatus == 0
end
