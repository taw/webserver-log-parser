require "pathname"

class LogParser
  # There's little reason to represent these as anything more complicated
  # for a script this simple.
  # For more complex formats, some kind of LogEntry might be useful
  def parse_line(line)
    line
      .chomp
      .split(" ", 2)
  end

  def parse_file(path)
    Pathname(path)
      .readlines
      .map{ |line| parse_line(line) }
  end

  def visits_statistics(path)
    ordered_counts(
      parse_file(path)
        .map(&:first)
    )
  end

  def unique_views_statistics(path)
    ordered_counts(
      parse_file(path)
        .uniq
        .map(&:first)
    )
  end

  def ordered_counts(collection)
    collection
      .group_by(&:itself)
      .transform_values(&:size)
      .sort_by{ |value, count| [-count, value] }
      .to_h
  end

  def format_visits_report(data)
    data.map do |url, count|
      if count == 1
        "#{url} #{count} visit\n"
      else
        "#{url} #{count} visits\n"
      end
    end.join
  end

  def format_unique_views_report(data)
    data.map do |url, count|
      if count == 1
        "#{url} #{count} unique view\n"
      else
        "#{url} #{count} unique views\n"
      end
    end.join
  end

  def call(args)
    if args.size == 1
      data = visits_statistics(args[0])
      puts format_visits_report(data)
    elsif args.size == 2 and args[0] == "--unique"
      data = unique_views_statistics(args[1])
      puts format_unique_views_report(data)
    else
      STDERR.puts "To get all visits:"
      STDERR.puts "  log_parser log_file.log"
      STDERR.puts "To get unique views:"
      STDERR.puts "  log_parser --unique log_file.log"
      exit 1
    end
  end
end
