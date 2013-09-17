lib ABI
  struct UnwindException
    exception_class : UInt64
    exception_cleanup : UInt64
    private1 : UInt64
    private2 : UInt64
    exception_object : UInt64
    exception_type_id : Int32
  end

  UA_SEARCH_PHASE = 1
  UA_CLEANUP_PHASE = 2
  UA_HANDLER_FRAME = 4
  UA_FORCE_UNWIND = 8

  URC_NO_REASON = 0
  URC_FOREIGN_EXCEPTION_CAUGHT = 1
  URC_FATAL_PHASE2_ERROR = 2
  URC_FATAL_PHASE1_ERROR = 3
  URC_NORMAL_STOP = 4
  URC_END_OF_STACK = 5
  URC_HANDLER_FOUND = 6
  URC_INSTALL_CONTEXT = 7
  URC_CONTINUE_UNWIND = 8

  fun unwind_raise_exception = _Unwind_RaiseException(ex : UnwindException*) : Int32
  fun unwind_get_region_start = _Unwind_GetRegionStart(context : Void*) : UInt64
  fun unwind_get_ip = _Unwind_GetIP(context : Void*) : UInt64
  fun unwind_set_ip = _Unwind_SetIP(context : Void*, ip : UInt64) : UInt64
  fun unwind_set_gr = _Unwind_SetGR(context : Void*, index : Int32, value : UInt64)
  fun unwind_get_language_specific_data = _Unwind_GetLanguageSpecificData(context : Void*) : UInt8*
end

struct LEBReader
  def initialize(@data)
  end

  def data
    @data
  end

  def read_uint8
    value = @data.as(UInt8).value
    @data += 1
    value
  end

  def read_uint32
    value = @data.as(UInt32).value
    @data += 4
    value
  end

  def read_uleb128
    result = 0_u64
    shift = 0
    while true
      byte = read_uint8
      result |= ((0x7f_u64 & byte) << shift);
      break if (byte & 0x80_u8) == 0
      shift += 7
    end
    result
  end
end

fun __crystal_personality(version : Int32, actions : Int32, exception_class : UInt64, exception_object : ABI::UnwindException*, context : Void*) : Int32
  start = ABI.unwind_get_region_start(context)
  ip = ABI.unwind_get_ip(context)
  throw_offset = ip - 1 - start
  lsd = ABI.unwind_get_language_specific_data(context)
  # puts "Personality - actions : #{actions}, start: #{start}, ip: #{ip}, throw_offset: #{throw_offset}"

  reader = LEBReader.new(lsd)
  reader.read_uint8 # @LPStart encoding
  if reader.read_uint8 != 0xff_u8 # @TType encoding
    reader.read_uleb128 # @TType base offset
  end
  reader.read_uint8 # CS Encoding

  cs_table_length = reader.read_uleb128 # CS table length
  cs_table_end = reader.data + cs_table_length

  while reader.data < cs_table_end
    cs_offset = reader.read_uint32
    cs_length = reader.read_uint32
    cs_addr = reader.read_uint32
    action = reader.read_uleb128
    # puts "cs_offset: #{cs_offset}, cs_length: #{cs_length}, cs_addr: #{cs_addr}, action: #{action}"

    if cs_addr != 0
      if cs_offset <= throw_offset && throw_offset <= cs_offset + cs_length
        if (actions & ABI::UA_SEARCH_PHASE) > 0
          # puts "found"
          return ABI::URC_HANDLER_FOUND
        end

        if (actions & ABI::UA_HANDLER_FRAME) > 0
          ABI.unwind_set_gr(context, 0, 0_u64 + exception_object.address)
          ABI.unwind_set_gr(context, 1, 0_u64 + exception_object.value.exception_type_id)
          ABI.unwind_set_ip(context, start + cs_addr)
          # puts "install"
          return ABI::URC_INSTALL_CONTEXT
        end
      end
    end
  end

  # puts "continue"
  return ABI::URC_CONTINUE_UNWIND
end

fun __crystal_raise(unwind_ex : ABI::UnwindException) : NoReturn
  ret = ABI.unwind_raise_exception(unwind_ex.ptr)
  puts "Could not raise"
  C.exit(ret)
end

fun __crystal_get_exception(unwind_ex : ABI::UnwindException) : UInt64
  unwind_ex.exception_object
end

def raise(ex : Exception)
  unwind_ex = ABI::UnwindException.new
  unwind_ex.exception_class = 0_u64
  unwind_ex.exception_cleanup = 0_u64
  unwind_ex.exception_object = ex.object_id
  unwind_ex.exception_type_id = ex.crystal_type_id
  __crystal_raise(unwind_ex)
end

def raise(message : String)
  raise Exception.new(message)
end
