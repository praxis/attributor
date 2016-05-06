module Attributor
  module Dumpable
    # Interface denoting that instances of such type respond to .dump as a way to properly
    # serialize its contents into primitive ruby objects.
    # This typically corresponds to non-trivial types that have some sort of substructure
    def dump
      raise NotImplementedError, 'Dumpable requires the implementation of #dump'
    end
  end
end
