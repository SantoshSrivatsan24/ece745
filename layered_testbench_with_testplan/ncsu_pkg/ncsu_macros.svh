`define ncsu_register_object(T) \
  typedef ncsu_object_registry #(T,`"T`") type_id; 

