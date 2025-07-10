require "option_parser"
require "../src/opusenc"

class WavConverter
  def run
    input_file = ""
    output_target : String | IO = ""
    sample_rate = 48000
    channels = 1
    use_stdout = false

    OptionParser.parse(ARGV) do |parser|
      parser.banner = "Usage: crystal run src/cli.cr [arguments]"
      parser.on("-i INPUT", "Input WAV file") do |value|
        input_file = value
      end
      parser.on("-o OUTPUT", "Output Opus file (ignored if --stdout is used)") do |value|
        output_target = value
      end
      parser.on("--stdout", "Output to standard output") do
        use_stdout = true
      end
      parser.on("-s SAMPLE_RATE", "Sample rate (default: 48000)") do |value|
        sample_rate = value.to_i
      end
      parser.on("-c CHANNELS", "Number of channels (default: 1)") do |value|
        channels = value.to_i
      end
      parser.on("-h", "--help", "Show this help") do
        puts parser
        exit
      end
    end

    unless File.exists?(input_file)
      puts "Error: Input file '#{input_file}' not found."
      exit 1
    end

    if !use_stdout && output_target.to_s.empty?
      puts "Error: Output file not specified. Use -o or --stdout."
      exit 1
    end

    if use_stdout
      puts "Converting '#{input_file}' to standard output..."
      output_io = STDOUT
    else
      puts "Converting '#{input_file}' to '#{output_target}'..."
      output_io = File.open(output_target.to_s, "wb")
    end

    begin
      pcm_data = read_wav_file(input_file, sample_rate, channels)
      encoder = Opusenc::Encoder.new(output_io, sample_rate, channels)
      encoder.write(pcm_data)
      encoder.close
      puts "Conversion complete."
    rescue ex : Exception
      puts "Error during conversion: #{ex.message}"
      exit 1
    ensure
      output_io.close unless use_stdout # Close file if not STDOUT
    end
  end

  private def read_wav_file(filename : String, expected_sample_rate : Int32, expected_channels : Int32) : Slice(Int16)
    File.open(filename, "rb") do |file|
      # Read RIFF header
      riff_id = file.read_bytes(UInt32, IO::ByteFormat::LittleEndian)
      raise "Not a RIFF file" unless riff_id == 0x46464952 # "RIFF"

      file.read_bytes(UInt32, IO::ByteFormat::LittleEndian) # file_size
      wave_id = file.read_bytes(UInt32, IO::ByteFormat::LittleEndian)
      raise "Not a WAVE file" unless wave_id == 0x45564157 # "WAVE"

      # Read fmt chunk
      fmt_id = file.read_bytes(UInt32, IO::ByteFormat::LittleEndian)
      raise "Missing fmt chunk" unless fmt_id == 0x20746d66 # "fmt "

      fmt_size = file.read_bytes(UInt32, IO::ByteFormat::LittleEndian)
      audio_format = file.read_bytes(UInt16, IO::ByteFormat::LittleEndian)
      raise "Unsupported audio format: #{audio_format}" unless audio_format == 1 # PCM

      channels = file.read_bytes(UInt16, IO::ByteFormat::LittleEndian)
      sample_rate = file.read_bytes(UInt32, IO::ByteFormat::LittleEndian)
      file.read_bytes(UInt32, IO::ByteFormat::LittleEndian) # byte_rate
      file.read_bytes(UInt16, IO::ByteFormat::LittleEndian) # block_align
      bits_per_sample = file.read_bytes(UInt16, IO::ByteFormat::LittleEndian)

      raise "Unsupported bits per sample: #{bits_per_sample}" unless bits_per_sample == 16
      raise "Mismatched sample rate: expected #{expected_sample_rate}, got #{sample_rate}" unless sample_rate == expected_sample_rate
      raise "Mismatched channels: expected #{expected_channels}, got #{channels}" unless channels == expected_channels

      # Skip extra fmt bytes if any
      file.skip(fmt_size - 16) if fmt_size > 16

      # Read data chunk
      data_id = file.read_bytes(UInt32, IO::ByteFormat::LittleEndian)
      raise "Missing data chunk" unless data_id == 0x61746164 # "data"

      data_size = file.read_bytes(UInt32, IO::ByteFormat::LittleEndian)

      # Read PCM data
      num_samples = data_size // (bits_per_sample // 8)
      pcm_data = Slice(Int16).new(num_samples)
      file.read_fully(Slice(UInt8).new(pcm_data.to_unsafe.as(Pointer(UInt8)), pcm_data.bytesize))
      pcm_data
    end
  end
end

WavConverter.new.run
