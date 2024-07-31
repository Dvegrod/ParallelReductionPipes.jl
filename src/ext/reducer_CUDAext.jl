module reducer_CUDAExt

using reducer
import CUDA

@init_parallel_stencil(CUDA, Float64, 3)


end
