//===----------------------------------------------------------------------===//
//
// Part of libcu++, the C++ Standard Library for your entire system,
// under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//


#include <cassert>
#include <cuda/memory_resource>
#include <cuda/std/cstddef>
#include <cuda/std/type_traits>
#include <memory>
#include <tuple>
#include <vector>


class resource : public cuda::memory_resource<cuda::memory_kind::pinned> {
public:
  int value = 0;
private:
  void *do_allocate(size_t, size_t) override {
    return nullptr;
  }

  void do_deallocate(void *, size_t, size_t) {
  }


#endif
};

int main(int argc, char **argv) {
  resource::basic_resource_view<resource<tag1>, cuda::is_kind<cuda::memory_kind::device>> v1_null;
  resource_view<cuda::memory_access::host> v2_null;
  v1_null == v2_null;
  return 0;
}
