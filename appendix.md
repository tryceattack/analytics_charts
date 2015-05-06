        if small_slice_index[0] == 1 and small_slice_index[1] == 1
          label_offset_degrees[0] = -15
          label_offset_degrees[1] = 15
          label_offset_degrees[2] = 15
          label_offset_degrees[3] = -15
        elsif small_slice_index[1] == 1 and small_slice_index[2] == 1
          label_offset_degrees[0] = -15
          label_offset_degrees[1] = -15
          label_offset_degrees[2] = 15
          label_offset_degrees[3] = 15
        elsif small_slice_index[2] == 1 and small_slice_index[3] == 1
          label_offset_degrees[0] = 15
          label_offset_degrees[1] = -15
          label_offset_degrees[2] = -15
          label_offset_degrees[3] = 15
        elsif small_slice_index[3] == 1 and small_slice_index[0] == 1
          label_offset_degrees[0] = 15
          label_offset_degrees[1] = 15
          label_offset_degrees[2] = -15
          label_offset_degrees[3] = -15
