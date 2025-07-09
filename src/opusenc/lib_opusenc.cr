@[Link("opusenc")]
lib LibOpusenc
  alias Pointer = Void*

  fun ope_comments_create : Pointer
  fun ope_comments_add(comments : Pointer, tag : UInt8*, value : UInt8*) : LibC::Int
  fun ope_comments_destroy(comments : Pointer)

  fun ope_encoder_create_file(path : UInt8*, comments : Pointer, rate : LibC::Int, channels : LibC::Int, family : LibC::Int, error : LibC::Int*) : Pointer
  fun ope_encoder_destroy(encoder : Pointer)
  fun ope_encoder_write(encoder : Pointer, pcm : LibC::Short*, len : LibC::Int) : LibC::Int
  fun ope_encoder_drain(encoder : Pointer) : LibC::Int
  fun ope_strerror(error : LibC::Int) : UInt8*
end
