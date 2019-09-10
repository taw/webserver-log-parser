describe LogParser do
  let(:parser) { LogParser.new }

  describe "#parse_line" do
    let(:line) { "/help_page/1 126.318.035.038\n" }
    subject { parser.parse_line(line) }

    it "returns url and ip address as array" do
      is_expected.to eq(["/help_page/1", "126.318.035.038"])
    end
  end

  describe "#parse_file" do
    let(:path) { "#{__dir__}/sample1.log" }
    subject { parser.parse_file(path) }

    it "returns array with url and ip per entry" do
      is_expected.to eq([
        ["/help_page/1", "126.318.035.038"],
        ["/contact", "184.123.665.067"],
        ["/home", "184.123.665.067"],
      ])
    end
  end

  describe "#ordered_counts" do
    let(:data) { [["a"] * 100, ["b"] * 20, ["c"] * 30, ["d"] * 20].flatten.shuffle }
    subject{ parser.ordered_counts(data) }
    # Ruby Hash is ordered, but its == check ignores order,
    # so we need to do something weird here
    # (and in a few other tests)
    let(:expected) {
      {
        "a" => 100,
        "c" => 30,
        "b" => 20,
        "d" => 20,
      }
    }

    it "returns counts for items in collection" do
      is_expected.to eq(expected)
    end

    it "returns them ordered by most frequent first, then by value" do
      expect(subject.to_a).to eq(expected.to_a)
    end
  end

  describe "#visits_statistics" do
    let(:path) { "#{__dir__}/sample2.log" }
    subject { parser.visits_statistics(path) }
    let(:expected) {
      {
        "/about" => 3,
        "/home" => 3,
        "/contact" => 2,
        "/index" => 1,
      }
    }

    it "returns totals of all visits including duplicates from same IP" do
      is_expected.to eq(expected)
    end

    it "is ordered by count then by URL" do
      expect(subject.to_a).to eq(expected.to_a)
    end
  end

  describe "#unique_views_statistics" do
    let(:path) { "#{__dir__}/sample2.log" }
    subject { parser.unique_views_statistics(path) }
    let(:expected) {
      {
        "/about" => 3,
        "/home" => 2,
        "/contact" => 1,
        "/index" => 1,
      }
    }

    it "returns totals of all visits including duplicates from same IP" do
      is_expected.to eq(expected)
    end

    it "is ordered by count then by URL" do
      expect(subject.to_a).to eq(expected.to_a)
    end
  end

  describe "#format_visits_report" do
    let(:path) { "#{__dir__}/sample2.log" }
    let(:data) { parser.visits_statistics(path) }
    subject{ parser.format_visits_report(data) }
    let(:expected) { Pathname("#{__dir__}/visits_report.txt").read }

    it "prints data in friendly format" do
      is_expected.to eq(expected)
    end
  end

  describe "#format_unique_views_report" do
    let(:path) { "#{__dir__}/sample2.log" }
    let(:data) { parser.unique_views_statistics(path) }
    subject{ parser.format_unique_views_report(data) }
    let(:expected) { Pathname("#{__dir__}/unique_views_report.txt").read }

    it "prints data in friendly format" do
      is_expected.to eq(expected)
    end
  end

  describe "Running the script" do
    let(:script) { "#{__dir__}/../bin/log_parser" }
    let(:path) { "#{__dir__}/sample2.log" }
    let(:usage) { Pathname("#{__dir__}/usage.txt").read }
    let(:output) { Open3.capture3(script, *args) }
    let(:stdout) { output[0] }
    let(:stderr) { output[1] }
    let(:status) { output[2] }

    describe "When it's called without any arguments" do
      let(:args) { [] }

      it "prints usage message to stderr and exits with failure" do
        expect(stdout).to be_empty
        expect(stderr).to eq(usage)
        expect(status).to_not be_success
      end
    end

    describe "When it's called with unrecognized arguments" do
      let(:args) { ["--color", path] }

      it "prints usage message to stderr and exits with failure" do
        expect(stdout).to be_empty
        expect(stderr).to eq(usage)
        expect(status).to_not be_success
      end
    end

    describe "When it's called with file argument" do
      let(:args) { [path] }
      let(:expected) { Pathname("#{__dir__}/visits_report.txt").read }

      it "prints visits report and exists with success" do
        expect(stdout).to eq(expected)
        expect(stderr).to be_empty
        expect(status).to be_success
      end
    end

    describe "When it's called with --unique flag" do
      let(:args) { ["--unique", path] }
      let(:expected) { Pathname("#{__dir__}/unique_views_report.txt").read }

      it "prints unique views report and exists with success" do
        expect(stdout).to eq(expected)
        expect(stderr).to be_empty
        expect(status).to be_success
      end
    end
  end
end
