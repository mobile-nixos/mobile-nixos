class String
  def self.try_convert(s)
    return s if s.is_a? String
    begin
      s.to_s
    rescue
      nil
    end
  end
end
