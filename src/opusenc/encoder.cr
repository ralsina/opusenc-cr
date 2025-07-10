require "io"
require "./lib_opusenc"

class Opusenc::Encoder
  @filename : String?
  @io : IO?

  # For file-based encoding
  def initialize(@filename : String, @rate : Int32, @channels : Int32, @family : Int32 = 0)
    @io = nil
    error = LibC::Int.new(0)
    comments = LibOpusenc.ope_comments_create
    @encoder = LibOpusenc.ope_encoder_create_file(@filename.not_nil!, comments, @rate, @channels, @family, pointerof(error))
    LibOpusenc.ope_comments_destroy(comments) # Destroy comments after use
    raise Error.new(error) if @encoder.null?
  end

  # For IO-based encoding
  def initialize(@io : IO, @rate : Int32, @channels : Int32, @family : Int32 = 0)
    @filename = nil
    error = LibC::Int.new(0)
    comments = LibOpusenc.ope_comments_create

    # Allocate memory for a pointer to the IO object and store the IO object there.
    # This pointer will be passed as user_data to the C callbacks.
    io_ptr = Pointer(IO).malloc
    io_ptr.value = @io.not_nil!

    # Define callbacks
    read_callback = ->(user_data : LibOpusenc::Pointer, buf : LibOpusenc::Pointer, nbytes : LibC::SizeT) do
      # This callback is for reading from the output stream, which is not typically needed for an encoder.
      # Return 0 bytes read.
      0_u64
    end

    seek_callback = ->(user_data : LibOpusenc::Pointer, offset : LibC::Long, whence : LibC::Int) do
      io_obj = user_data.as(Pointer(IO)).value
      begin
        seek_mode = case whence
                    when 0 then IO::Seek::Set
                    when 1 then IO::Seek::Current
                    when 2 then IO::Seek::End
                    else raise ArgumentError.new("Invalid seek whence value")
                    end
        io_obj.seek(offset, seek_mode)
        io_obj.pos.to_i64
      rescue ex
        -1_i64 # Return -1 on error
      end
    end

    tell_callback = ->(user_data : LibOpusenc::Pointer) do
      io_obj = user_data.as(Pointer(IO)).value
      io_obj.pos.to_i64
    end

    write_callback = ->(user_data : LibOpusenc::Pointer, buf : LibOpusenc::Pointer, nbytes : LibC::SizeT) do
      io_obj = user_data.as(Pointer(IO)).value
      slice = Slice.new(buf.as(UInt8*), nbytes.to_i)
      io_obj.write(slice)
      nbytes
    end

    close_callback = ->(user_data : LibOpusenc::Pointer, flags : LibC::Int) do
      # The IO object is managed by the caller, so we don't close it here.
      # Free the allocated memory for the IO pointer.
      LibC.free(user_data)
      0 # Return 0 on success
    end

    callbacks = LibOpusenc::OggOpusEncCallbacks.new(
      read:  read_callback,
      seek:  seek_callback,
      tell:  tell_callback,
      write: write_callback,
      close: close_callback
    )

    @encoder = LibOpusenc.ope_encoder_create_callbacks(
      pointerof(callbacks),
      io_ptr.as(LibOpusenc::Pointer), # Pass the pointer to the IO object as user_data
      comments,
      @rate,
      @channels,
      @family,
      pointerof(error)
    )
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
