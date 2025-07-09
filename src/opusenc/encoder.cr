require "./lib_opusenc"

class Opusenc::Encoder
  def initialize(@filename : String, @rate : Int32, @channels : Int32, @family : Int32 = 0)
    error = LibC::Int.new(0)
    comments = LibOpusenc.ope_comments_create
    @encoder = LibOpusenc.ope_encoder_create_file(@filename, comments, @rate, @channels, @family, pointerof(error))
    LibOpusenc.ope_comments_destroy(comments) # Destroy comments after use
    raise Error.new(error) if @encoder.null?
  end

  def write(p_c_m)
    p_c_m.is_a?(Slice(Int16)) || raise ArgumentError.new("Slice must be Int16")
    ret = LibOpusenc.ope_encoder_write(@encoder, p_c_m.to_unsafe, p_c_m.size)
    raise Error.new(ret) if ret != 0
  end

  def close
    LibOpusenc.ope_encoder_drain(@encoder)
    LibOpusenc.ope_encoder_destroy(@encoder)
  end
end

class Opusenc::Error < Exception
  def initialize(error_code : LibC::Int)
    super(String.new(LibOpusenc.ope_strerror(error_code)))
  end
end
